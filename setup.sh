#!/bin/bash
# Complete setup script for clawburt - macOS MLX inference server
# Run as: sudo bash setup.sh

set -e

if [ "$EUID" -ne 0 ]; then
    echo "Please run as root: sudo bash setup.sh"
    exit 1
fi

REAL_USER=${SUDO_USER:-$(id -un)}
USER_HOME=$(eval echo "~$REAL_USER")
SERVICE_USER="_mlxserver"
VENV_PATH="/opt/mlx/venv"
MODELS_PATH="/opt/mlx/models"
SCRIPT_PATH="/opt/mlx/mlx-server.sh"
PLIST_PATH="/Library/LaunchDaemons/com.local.mlx-openai-server.plist"
LOG_PATH="/var/log/mlx-server.log"
MODEL="mlx-community/Qwen3.6-27B-4bit"
PORT=8080
HOSTNAME="clawburt"

echo "==> Setting hostname to $HOSTNAME..."
scutil --set HostName "$HOSTNAME"
scutil --set LocalHostName "$HOSTNAME"
scutil --set ComputerName "$HOSTNAME"
dscacheutil -flushcache

# Install Homebrew if not present (must run as real user)
if ! sudo -u "$REAL_USER" command -v brew &>/dev/null; then
    echo "==> Installing Homebrew..."
    sudo -u "$REAL_USER" /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    echo >> "$USER_HOME/.zprofile"
    echo 'eval "$(/opt/homebrew/bin/brew shellenv zsh)"' >> "$USER_HOME/.zprofile"
else
    echo "==> Homebrew already installed"
fi

eval "$(/opt/homebrew/bin/brew shellenv)"

# Install pyenv dependencies
echo "==> Installing pyenv build dependencies..."
sudo -u "$REAL_USER" brew install xz

# Install pyenv if not present
if ! sudo -u "$REAL_USER" command -v pyenv &>/dev/null; then
    echo "==> Installing pyenv..."
    sudo -u "$REAL_USER" brew install pyenv
    echo 'export PYENV_ROOT="$HOME/.pyenv"' >> "$USER_HOME/.zprofile"
    echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> "$USER_HOME/.zprofile"
    echo 'eval "$(pyenv init -)"' >> "$USER_HOME/.zprofile"
else
    echo "==> pyenv already installed"
fi

export PYENV_ROOT="$USER_HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

# Ensure pyenv directory is owned by real user
chown -R "$REAL_USER":staff "$PYENV_ROOT" 2>/dev/null || true

# Install Python 3.13 via pyenv if not present
PYTHON_VERSION="3.13"
if ! sudo -u "$REAL_USER" pyenv versions | grep -q "$PYTHON_VERSION"; then
    echo "==> Installing Python $PYTHON_VERSION via pyenv..."
    sudo -u "$REAL_USER" env PYENV_ROOT="$PYENV_ROOT" PATH="$PYENV_ROOT/bin:$PATH" pyenv install "$PYTHON_VERSION"
else
    echo "==> Python $PYTHON_VERSION already installed via pyenv"
fi

PYTHON="$PYENV_ROOT/versions/$(sudo -u "$REAL_USER" env PYENV_ROOT="$PYENV_ROOT" PATH="$PYENV_ROOT/bin:$PATH" pyenv latest $PYTHON_VERSION)/bin/python3"
echo "==> Using Python: $PYTHON ($($PYTHON --version))"

# Create service user if not present
if ! id "$SERVICE_USER" &>/dev/null; then
    echo "==> Creating service user $SERVICE_USER..."
    NEXT_UID=300
    while dscl . -list /Users UniqueID | awk '{print $2}' | grep -q "^${NEXT_UID}$"; do
        NEXT_UID=$((NEXT_UID + 1))
    done
    dscl . -create /Users/$SERVICE_USER
    dscl . -create /Users/$SERVICE_USER UserShell /usr/bin/false
    dscl . -create /Users/$SERVICE_USER RealName "MLX Server"
    dscl . -create /Users/$SERVICE_USER UniqueID "$NEXT_UID"
    dscl . -create /Users/$SERVICE_USER PrimaryGroupID 20
    dscl . -create /Users/$SERVICE_USER NFSHomeDirectory /var/empty
    echo "==> Created service user $SERVICE_USER with UID $NEXT_UID"
else
    echo "==> Service user $SERVICE_USER already exists"
fi

# Create /opt/mlx directories
echo "==> Creating /opt/mlx directories..."
mkdir -p /opt/mlx
mkdir -p /opt/mlx/cache
mkdir -p /opt/mlx/logs
mkdir -p /opt/mlx/cache/outlines
mkdir -p "$MODELS_PATH"
chown -R "$SERVICE_USER":staff /opt/mlx

# Create venv if not present
if [ ! -d "$VENV_PATH" ]; then
    echo "==> Creating venv at $VENV_PATH..."
    "$PYTHON" -m venv "$VENV_PATH"
    chown -R "$SERVICE_USER":staff "$VENV_PATH"
else
    echo "==> Venv already exists at $VENV_PATH"
fi

# Install Rust if not present (needed for outlines-core)
if ! command -v rustc &>/dev/null; then
    echo "==> Installing Rust..."
    sudo -u "$REAL_USER" curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sudo -u "$REAL_USER" sh -s -- -y
    source "$USER_HOME/.cargo/env"
else
    echo "==> Rust already installed: $(rustc --version)"
fi


echo "==> Installing uv into venv..."
"$VENV_PATH/bin/pip" install --cache-dir "/tmp/pip-cache-$$" uv

echo "==> Installing/upgrading mlx-openai-server from GitHub..."
"$VENV_PATH/bin/uv" pip install --python "$VENV_PATH/bin/python" git+https://github.com/cubist38/mlx-openai-server.git
chown -R "$SERVICE_USER":staff "$VENV_PATH"

# Check if model is downloaded, download if not
MODEL_DIR="$MODELS_PATH/$(echo $MODEL | tr '/' '--')"
if [ ! -d "$MODEL_DIR" ]; then
    echo "==> Model not found, downloading $MODEL..."
    export HF_HOME=/opt/mlx/cache
    "$VENV_PATH/bin/hf" download "$MODEL" --local-dir "$MODEL_DIR"
    chown -R "$SERVICE_USER":staff "$MODEL_DIR"
else
    echo "==> Model already downloaded at $MODEL_DIR"
fi

# Create server script
echo "==> Writing server script to $SCRIPT_PATH..."
cat > "$SCRIPT_PATH" << SCRIPT
#!/bin/bash
# Edit MODEL_PATH to swap models, then restart the service:
#   sudo launchctl stop com.local.mlx-server
#   sudo launchctl start com.local.mlx-server

MODEL_PATH="$MODEL_DIR"

export HF_HOME=/opt/mlx/cache
export HUGGINGFACE_HUB_CACHE=/opt/mlx/cache
export OUTLINES_CACHE_DIR=/opt/mlx/cache/outlines

source "$VENV_PATH/bin/activate"

mlx-openai-server launch \
    --model-type lm \
    --model-path "\$MODEL_PATH" \
    --tool-call-parser qwen3 \
    --reasoning-parser qwen3 \
    --enable-auto-tool-choice \
    --host 0.0.0.0 \
    --port $PORT \
    --log-level WARNING \
    --no-log-file
SCRIPT
chmod +x "$SCRIPT_PATH"
chown "$SERVICE_USER":staff "$SCRIPT_PATH"

# Create log file if not present
if [ ! -f "$LOG_PATH" ]; then
    touch "$LOG_PATH"
    chown "$SERVICE_USER":staff "$LOG_PATH"
fi

# Write launchd plist
echo "==> Writing launchd plist to $PLIST_PATH..."
cat > "$PLIST_PATH" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.local.mlx-openai-server</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>$SCRIPT_PATH</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>$LOG_PATH</string>
    <key>StandardErrorPath</key>
    <string>$LOG_PATH</string>
    <key>WorkingDirectory</key>
    <string>/opt/mlx</string>
    <key>UserName</key>
    <string>$SERVICE_USER</string>
</dict>
</plist>
PLIST

# Load or reload the service
if launchctl list 2>/dev/null | grep -q "com.local.mlx-openai-server"; then
    echo "==> Reloading service..."
    launchctl unload "$PLIST_PATH"
fi

echo "==> Loading service..."
launchctl load "$PLIST_PATH"

echo ""
echo "==> Done!"
echo ""
echo "Hostname:  $HOSTNAME"
echo "Service:   com.local.mlx-openai-server"
echo "User:      $SERVICE_USER"
echo "Model:     $MODEL"
echo "Port:      $PORT"
echo "Logs:      tail -f $LOG_PATH"
echo ""
echo "To swap models:"
echo "  1. Edit $SCRIPT_PATH and change the MODEL_PATH variable"
echo "  2. sudo launchctl stop com.local.mlx-openai-server"
echo "  3. sudo launchctl start com.local.mlx-openai-server"
