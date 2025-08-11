#!/bin/bash
set -e

# 1. Install gamemode, mesa, and xfce
echo "[INFO] Installing gamemode, mesa updates, and XFCE..."
sudo apt update
sudo apt install -y gamemode mesa-utils xfce4

# 2. Edit Steam desktop entry
STEAM_DESKTOP="/usr/share/applications/steam.desktop"
if [ -f "$STEAM_DESKTOP" ]; then
    echo "[INFO] Editing Steam desktop entry to use gamemoderun..."
    sudo sed -i 's|^Exec=|Exec=gamemoderun |' "$STEAM_DESKTOP"
fi

# 3. Force X11 for GDM
if [ -f "/etc/gdm3/custom.conf" ]; then
    echo "[INFO] Forcing X11..."
    sudo sed -i 's/^#WaylandEnable=.*/WaylandEnable=false/' /etc/gdm3/custom.conf
    sudo sed -i 's/^WaylandEnable=.*/WaylandEnable=false/' /etc/gdm3/custom.conf
fi

# 4. Create systemd service for performance governor at boot
echo "[INFO] Creating CPU governor service..."
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

sudo systemctl enable cpu-powersave-battery.service

# 6. Show notification and wait for user to confirm restart
echo "[INFO] All done! Sending desktop notification..."
notify-send "Optimization Complete!" "All performance tweaks applied. Press Enter in the shell to restart."

read -p "Press Enter to restart..."
sudo systemctl reboot

