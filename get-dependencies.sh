#!/bin/sh

set -eu

ARCH=$(uname -m)

echo "Installing package dependencies..."
echo "---------------------------------------------------------------"
pacman -Syu --noconfirm pipewire-audio pipewire-jack vulkan-mesa-layers

if [ "$ARCH" = 'x86_64' ]; then
		pacman -Syu --noconfirm libva-intel-driver
fi

echo "Installing debloated packages..."
echo "---------------------------------------------------------------"
get-debloated-pkgs --add-common --prefer-nano intel-media-driver-mini ffmpeg-mini

echo "Getting app..."
echo "---------------------------------------------------------------"
case "$ARCH" in # they use ARM64 for the tar links
	x86_64)  tar_arch=x86_64;;
	aarch64) tar_arch=arm64;;
esac
TAR_LINK=$(wget https://api.github.com/repos/ungoogled-software/ungoogled-chromium-portablelinux/releases -O - \
      | sed 's/[()",{} ]/\n/g' | grep -o -m 1 "https.*${tar_arch}_linux.tar.xz")
echo "$TAR_LINK" | awk -F'/' '{gsub(/^v/, "", $(NF-1)); print $(NF-1); exit}' > ~/version
if ! wget --retry-connrefused --tries=30 "$TAR_LINK" -O /tmp/app.tar.xz 2>/tmp/download.log; then
	cat /tmp/download.log
	exit 1
fi

mkdir -p ./AppDir/bin
tar -xvf /tmp/app.tar.xz --strip-components=1 -C ./AppDir/bin

# we need to remove this because chrome otherwise dlopen libQt5Core on the host
# when present, we can only bunle libqt6 or libqt5 but not both
rm -f ./AppDir/bin/libqt5_shim.so
