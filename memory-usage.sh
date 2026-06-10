#!/bin/bash
# Memory usage summary with process list

# Process list sorted smallest to largest
echo "Process Memory Usage (smallest to largest)"
echo "==========================================="
ps aux | awk 'NR>1 {printf "%8.1f MB  %s\n", $6/1024, $11}' | sort -n | tail -50
echo ""

# Memory totals
echo "Memory Summary"
echo "=============="

# Get total RAM in GB
total_bytes=$(sysctl -n hw.memsize)
total_gb=$(echo "scale=2; $total_bytes / 1073741824" | bc)

vm_stat | awk -v total_gb="$total_gb" '
/Pages free/ { free = $3+0 }
/Pages active/ { active = $3+0 }
/Pages inactive/ { inactive = $3+0 }
/Pages wired/ { wired = $4+0 }
/Pages compressed/ { compressed = $3+0 }
END {
    page=16384
    free_gb = (free * page) / 1073741824
    active_gb = (active * page) / 1073741824
    inactive_gb = (inactive * page) / 1073741824
    wired_gb = (wired * page) / 1073741824
    compressed_gb = (compressed * page) / 1073741824
    used_gb = total_gb - free_gb

    printf "Total:        %6.2f GB\n", total_gb
    printf "Used:         %6.2f GB\n", used_gb
    printf "Free:         %6.2f GB\n", free_gb
    printf "  Active:     %6.2f GB\n", active_gb
    printf "  Inactive:   %6.2f GB\n", inactive_gb
    printf "  Wired:      %6.2f GB\n", wired_gb
    printf "  Compressed: %6.2f GB\n", compressed_gb
}'
