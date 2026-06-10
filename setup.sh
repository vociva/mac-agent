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
SCRIPT_PATH="/opt/mlx/mlx-server.sh"
PLIST_PATH="/Library/LaunchDaemons/com.local.mlx-server.plist"
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

# Install Python if not present
if ! brew list python &>/dev/null; then
    echo "==> Installing Python..."
    sudo -u "$REAL_USER" brew install python
else
    echo "==> Python already installed: $(python3 --version)"
fi

# Create service user if not present
if ! id "$SERVICE_USER" &>/dev/null; then
    echo "==> Creating service user $SERVICE_USER..."
    # Find a free UID under 500 (system user range)
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
echo "==> Creating /opt/mlx..."
mkdir -p /opt/mlx
mkdir -p /opt/mlx/cache
chown -R "$SERVICE_USER":staff /opt/mlx

# Create venv if not present
if [ ! -d "$VENV_PATH" ]; then
    echo "==> Creating venv at $VENV_PATH..."
    python3 -m venv "$VENV_PATH"
    chown -R "$SERVICE_USER":staff "$VENV_PATH"
else
    echo "==> Venv already exists at $VENV_PATH"
fi

# Install/upgrade mlx-lm
echo "==> Installing/upgrading mlx-lm..."
"$VENV_PATH/bin/pip" install --upgrade mlx-lm

# Create server script
echo "==> Writing server script to $SCRIPT_PATH..."
cat > "$SCRIPT_PATH" << SCRIPT
#!/bin/bash
# Edit MODEL to swap models, then restart the service:
#   sudo launchctl stop com.local.mlx-server
#   sudo launchctl start com.local.mlx-server

MODEL="$MODEL"

export HF_HOME=/opt/mlx/cache
export HUGGINGFACE_HUB_CACHE=/opt/mlx/cache

source "$VENV_PATH/bin/activate"

mlx_lm.server \
    --model "\$MODEL" \
    --host 0.0.0.0 \
    --port $PORT \
    --log-level WARNING
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
    <string>com.local.mlx-server</string>
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
    <key>UserName</key>
    <string>$SERVICE_USER</string>
</dict>
</plist>
PLIST

# Load or reload the service
if launchctl list 2>/dev/null | grep -q "com.local.mlx-server"; then
    echo "==> Reloading service..."
    launchctl unload "$PLIST_PATH"
fi

echo "==> Loading service..."
launchctl load "$PLIST_PATH"

echo ""
echo "==> Done!"
echo ""
echo "Hostname:  $HOSTNAME"
echo "Service:   com.local.mlx-server"
echo "User:      $SERVICE_USER"
echo "Model:     $MODEL"
echo "Port:      $PORT"
echo "Logs:      tail -f $LOG_PATH"
echo ""
echo "To swap models:"
echo "  1. Edit $SCRIPT_PATH and change the MODEL variable"
echo "  2. sudo launchctl stop com.local.mlx-server"
echo "  3. sudo launchctl start com.local.mlx-server"
