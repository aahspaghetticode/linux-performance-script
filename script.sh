#!/bin/bash
set -e

# Check if zenity is installed, if not, install it (only for apt)
if ! command -v zenity &> /dev/null; then
    echo "Zenity not found. Installing zenity..."
    if command -v apt &> /dev/null; then
        sudo apt update
        sudo apt install -y zenity
    else
        echo "Please install zenity then run the script again."
        exit 1
    fi
fi

# Ask user if they use any Wayland-specific features
if zenity --question --title="Wayland Features" \
    --text="Do you use any Wayland-specific features or applications? Selecting YES will keep Wayland enabled; NO will force X11 /(faster/)." ; then
    USE_WAYLAND=true
else
    USE_WAYLAND=false
fi

echo "[INFO] User selected: USE_WAYLAND=$USE_WAYLAND"

# Detect package manager and set install command and package names
if command -v apt &> /dev/null; then
    PM_INSTALL="sudo apt install -y"
    PKG_GAMEMODE="gamemode"
    PKG_MESA="mesa-utils"
elif command -v dnf &> /dev/null; then
    PM_INSTALL="sudo dnf install -y"
    PKG_GAMEMODE="gamemode"
    PKG_MESA="mesa-demos"
elif command -v pacman &> /dev/null; then
    PM_INSTALL="sudo pacman -S --noconfirm"
    PKG_GAMEMODE="gamemode"
    PKG_MESA="mesa-demos"
else
    echo "Unsupported package manager. Please install gamemode and mesa-utils manually."
    exit 1
fi

echo "[INFO] Installing gamemode and mesa utilities..."
sudo $PM_INSTALL $PKG_GAMEMODE $PKG_MESA

# Edit Steam desktop entry to prepend gamemoderun
STEAM_DESKTOP="/usr/share/applications/steam.desktop"
if [ -f "$STEAM_DESKTOP" ]; then
    echo "[INFO] Editing Steam desktop entry to use gamemoderun..."
    sudo sed -i 's|^Exec=|Exec=gamemoderun |' "$STEAM_DESKTOP"
fi

# Force X11 only if user selected NO for Wayland
if [ "$USE_WAYLAND" = false ]; then
    if [ -f "/etc/gdm3/custom.conf" ]; then
        echo "[INFO] Forcing X11 by disabling Wayland..."
        sudo sed -i 's/^#WaylandEnable=.*/WaylandEnable=false/' /etc/gdm3/custom.conf
        sudo sed -i 's/^WaylandEnable=.*/WaylandEnable=false/' /etc/gdm3/custom.conf
    fi
else
    echo "[INFO] Keeping Wayland enabled."
fi

# Create CPU performance service as before
cat <<EOF | sudo tee /etc/systemd/system/cpu-performance.service
[Unit]
Description=Set CPU governor to performance at startup
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/usr/bin/bash -c "for c in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do echo performance | sudo tee \$c; done"

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable cpu-performance.service

# Notify user and prompt to restart
notify-send "Optimization Complete" "Performance tweaks applied. Press Enter in the terminal to restart."

read -p "Press Enter to restart..."
sudo systemctl reboot


# 5. Show notification and wait for user to confirm restart
echo "[INFO] All done! Sending desktop notification..."
notify-send "Optimization Complete" "All performance tweaks applied. Press Enter to restart."

read -p "Press Enter to restart..."
sudo systemctl reboot
