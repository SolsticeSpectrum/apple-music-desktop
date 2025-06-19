#!/bin/bash
# Script to add Widevine CDM to ARM64 Flatpak (for users who want to add it themselves)
# This is NOT included in the official build due to legal reasons

set -e

if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root (needed for flatpak system modifications)"
    exit 1
fi

FLATPAK_APP_ID="com.alex313031.AppleMusic"
FLATPAK_INSTALL_DIR="/var/lib/flatpak/app/${FLATPAK_APP_ID}/current/active/files"

if [ ! -d "$FLATPAK_INSTALL_DIR" ]; then
    echo "Flatpak app not found. Please install it first."
    exit 1
fi

echo "Downloading Asahi Linux Widevine installer..."
git clone https://github.com/AsahiLinux/widevine-installer /tmp/widevine-installer

echo "Downloading ChromeOS Lacros image..."
cd /tmp
LACROS_VERSION="120.0.6098.0"
curl -O "https://commondatastorage.googleapis.com/chromeos-localmirror/distfiles/chromeos-lacros-arm64-squash-zstd-${LACROS_VERSION}"

echo "Extracting Widevine..."
unsquashfs -q chromeos-lacros-arm64-squash-zstd-${LACROS_VERSION} 'WidevineCdm/*'

echo "Fixing up Widevine binary..."
python3 /tmp/widevine-installer/widevine_fixup.py \
    squashfs-root/WidevineCdm/_platform_specific/cros_arm64/libwidevinecdm.so \
    /tmp/libwidevinecdm.so

echo "Installing Widevine to Flatpak..."
mkdir -p "${FLATPAK_INSTALL_DIR}/chrome-sandbox/WidevineCdm/_platform_specific/linux_arm64"
cp /tmp/libwidevinecdm.so "${FLATPAK_INSTALL_DIR}/chrome-sandbox/WidevineCdm/_platform_specific/linux_arm64/"
cp squashfs-root/WidevineCdm/manifest.json "${FLATPAK_INSTALL_DIR}/chrome-sandbox/WidevineCdm/"

# Hack for Chromium hardcoded check
mkdir -p "${FLATPAK_INSTALL_DIR}/chrome-sandbox/WidevineCdm/_platform_specific/linux_x64"
touch "${FLATPAK_INSTALL_DIR}/chrome-sandbox/WidevineCdm/_platform_specific/linux_x64/libwidevinecdm.so"

echo "Cleaning up..."
rm -rf /tmp/widevine-installer /tmp/squashfs-root /tmp/chromeos-lacros-arm64-squash-zstd-${LACROS_VERSION} /tmp/libwidevinecdm.so

echo "Done! Widevine has been added to the ARM64 Flatpak."
echo "Note: This is unofficial and may have legal implications. Use at your own risk."