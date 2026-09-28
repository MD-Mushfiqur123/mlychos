#!/usr/bin/env bash
# ==============================================================================
#  MlychOS — The Sovereign Minimalist Monochromatic Linux Masterpiece (<300MB)
#  Lead Developer : Md Mushfiqur Rahim
#  Engine Partner : L
#  Base           : Debian 12 (Bookworm) Minbase + Modern Wayland (Labwc)
#  UI Theme       : Pure Monochromatic Obsidian (#090A0F) & Crisp White (#FFFFFF)
# ==============================================================================

set -euo pipefail

WORKDIR="$(pwd)/mlychos_build"
CHROOT_DIR="${WORKDIR}/chroot"
ISO_DIR="${WORKDIR}/iso"
OUTPUT_ISO="$(pwd)/mlychos-1.0-amd64.iso"

echo "=================================================================="
echo "🚀 INITIALIZING MlychOS MASTERPIECE BUILD PIPELINE (SUB-300MB)"
echo "=================================================================="

# 1. Clean workspace
rm -rf "${WORKDIR}"
mkdir -p "${CHROOT_DIR}" "${ISO_DIR}/live" "${ISO_DIR}/boot/grub"

# 2. Bootstrap ultra-lean Debian 12 Bookworm Core
echo "📦 Step 1: Bootstrapping Debian 12 Minbase..."
debootstrap --variant=minbase --arch=amd64 bookworm "${CHROOT_DIR}" http://deb.debian.org/debian/

# 3. Aggressive Stripping Policy (Drop docs, man pages, unused locales)
cat << 'EOF' > "${CHROOT_DIR}/etc/dpkg/dpkg.cfg.d/01_nodoc"
path-exclude /usr/share/doc/*
path-exclude /usr/share/man/*
path-exclude /usr/share/groff/*
path-exclude /usr/share/info/*
path-exclude /usr/share/lintian/*
path-exclude /usr/share/linda/*
path-include /usr/share/doc/*/copyright
EOF

# 4. Install Core Packages inside Chroot
echo "⚙️ Step 2: Installing Wayland Core, Labwc, Foot & Kernel..."
cat << 'EOF' | chroot "${CHROOT_DIR}" /bin/bash
export DEBIAN_FRONTEND=noninteractive

# Configure APT
apt-get update
apt-get install -y --no-install-recommends \
    linux-image-amd64 \
    live-boot \
    systemd-sysv \
    seatd \
    libgl1-mesa-dri \
    labwc \
    waybar \
    fuzzel \
    foot \
    neovim \
    curl \
    git \
    htop \
    tree \
    jq \
    ca-certificates \
    fonts-jetbrains-mono

# Create user 'mushfiqur'
useradd -m -s /bin/bash -G sudo,video,input,render mushfiqur
echo "mushfiqur:mlych" | chpasswd
echo "root:mlych" | chpasswd
echo "mlychos" > /etc/hostname

# Setup autologin
mkdir -p /etc/systemd/system/getty@tty1.service.d/
cat << 'AUTOLOGIN' > /etc/systemd/system/getty@tty1.service.d/autologin.conf
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin mushfiqur --noclear %I $TERM
AUTOLOGIN

# Clean apt cache
apt-get clean
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
EOF

# 5. Inject Pure Monochromatic Aesthetic Configs (Labwc + Waybar + Foot)
echo "🎨 Step 3: Injecting Pure Monochromatic TokyoNight/Obsidian UI..."

USER_HOME="${CHROOT_DIR}/home/mushfiqur"
mkdir -p "${USER_HOME}/.config/labwc"
mkdir -p "${USER_HOME}/.config/waybar"
mkdir -p "${USER_HOME}/.config/foot"

# Labwc Autostart
cat << 'EOF' > "${USER_HOME}/.config/labwc/autostart"
waybar &
foot &
EOF

# Monochromatic Waybar Configuration (Pure Minimalist Pill UI)
cat << 'EOF' > "${USER_HOME}/.config/waybar/config"
{
    "layer": "top",
    "position": "top",
    "margin-top": 8,
    "margin-left": 16,
    "margin-right": 16,
    "modules-left": ["custom/logo", "wlr/taskbar"],
    "modules-center": ["clock"],
    "modules-right": ["cpu", "memory", "network", "custom/power"],
    "custom/logo": {
        "format": " ⚡ MlychOS ",
        "tooltip": false
    },
    "clock": {
        "format": "{:%I:%M %p  •  %d %b %Y}"
    },
    "cpu": {
        "format": "CPU {usage}%"
    },
    "memory": {
        "format": "RAM {used:0.1f}G/{total:0.1f}G"
    },
    "network": {
        "format-wifi": "WIFI {signalStrength}%",
        "format-ethernet": "ETH 1Gbps",
        "format-disconnected": "OFFLINE"
    },
    "custom/power": {
        "format": " ⏻ ",
        "tooltip": false
    }
}
EOF

# Monochromatic Waybar CSS (Obsidian Black & Crisp White)
cat << 'EOF' > "${USER_HOME}/.config/waybar/style.css"
* {
    border: none;
    font-family: "JetBrains Mono", monospace;
    font-size: 12px;
    font-weight: 700;
}

window#waybar {
    background: transparent;
}

#custom-logo, #clock, #cpu, #memory, #network, #custom-power {
    background: #090a0f;
    color: #f8fafc;
    border: 1px solid #222734;
    border-radius: 8px;
    padding: 4px 12px;
    margin: 0 4px;
}

#custom-logo {
    background: #f8fafc;
    color: #090a0f;
    font-weight: 900;
}

#clock {
    color: #38bdf8;
}

#cpu, #memory {
    color: #94a3b8;
}
EOF

# Foot Minimalist Terminal Configuration
cat << 'EOF' > "${USER_HOME}/.config/foot/foot.ini"
[main]
font=JetBrains Mono:size=11
pad=16x16

[colors]
alpha=0.92
background=090a0f
foreground=f8fafc

## Monochromatic Palette
regular0=161821
regular1=e27878
regular2=b4be82
regular3=e2a478
regular4=84a0c6
regular5=a093c7
regular6=89b8c2
regular7=c6c8d1

bright0=6b7089
bright1=e98989
bright2=c0ca8e
bright3=e9b189
bright4=91acd1
bright5=ada0d3
bright6=95c4ce
bright7=d2d4de
EOF

# Set ownership
chroot "${CHROOT_DIR}" chown -R mushfiqur:mushfiqur /home/mushfiqur

# 6. Copy Kernel and Initrd to ISO directory
echo "📦 Step 4: Extracting Kernel & Initramfs..."
cp "${CHROOT_DIR}"/boot/vmlinuz-* "${ISO_DIR}/live/vmlinuz"
cp "${CHROOT_DIR}"/boot/initrd.img-* "${ISO_DIR}/live/initrd"

# 7. Compress with High-Ratio SquashFS (XZ + 1MB block + BCJ filter)
echo "🗜️ Step 5: Compressing RootFS into High-Ratio SquashFS (<200MB)..."
mksquashfs "${CHROOT_DIR}" "${ISO_DIR}/live/filesystem.squashfs" \
    -comp xz -b 1048576 -Xbcj x86 -Xdict-size 100% -noappend

# 8. Create Minimalist GRUB Configuration
cat << 'EOF' > "${ISO_DIR}/boot/grub/grub.cfg"
set default=0
set timeout=3

set menu_color_normal=white/black
set menu_color_highlight=black/white

menuentry "MlychOS 1.0 (Sovereign Minimalist Debian - 64-bit)" {
    linux /live/vmlinuz boot=live quiet splash
    initrd /live/initrd
}

menuentry "MlychOS 1.0 (Safe Mode / RAM Disk)" {
    linux /live/vmlinuz boot=live toram
    initrd /live/initrd
}
EOF

# 9. Build Hybrid ISO
echo "💿 Step 6: Generating Hybrid Bootable ISO with grub-mkrescue & xorriso..."
grub-mkrescue -o "${OUTPUT_ISO}" "${ISO_DIR}"

echo "=================================================================="
echo "🎉 SUCCESS! MlychOS ISO GENERATED AT: ${OUTPUT_ISO}"
echo "📊 Final Size: $(du -sh "${OUTPUT_ISO}" | cut -f1)"
echo "=================================================================="
