#!/bin/bash

VERSION="${1}"

# Set failures
set -eo pipefail

# Build specs
CD=`pwd`

# Download reqs
pacman -Sy --noconfirm
pacman -S archiso git tree --noconfirm

# Make dirs
mkdir output
mkdir work

# Copy profile
cp -r /usr/share/archiso/configs/releng/ ./archlive

# Add Archian packages
echo "git" >> ./archlive/packages.x86_64
echo "dialog" >> ./archlive/packages.x86_64
echo "jq" >> ./archlive/packages.x86_64

# Download Archian
git clone https://github.com/eb3095/archian.git

# Format Archian
rm -f archian/.gitignore
rm -f archian/web.sh
rm -f archian/install.sh
cp archian/iso/iso-install.sh archian/install.sh
chmod + archian/install.sh

# Add Archian
tree  ./archlive
cp -rf ./archian/* ./archlive/airootfs/root

# Change .automated_script.sh
cp -f ./automated_script.sh ./archlive/airootfs/root/.automated_script.sh
chmod +x ./archlive/airootfs/root/.automated_script.sh

# Build
mkarchiso -v -w ./work -o ./output ./archlive

if [ ! -z "${VERSION}" ]; then
    # Add version
    echo "${VERSION}" >> ./output/version

    # Rename
    mv ./output/*.iso ./output/archian-${VERSION}-x86_64.iso
else
    pushd ./output/
    ORIG_NAME=$(ls *.iso)
    NAME=$(echo "${ORIG_NAME}" | sed "s/archlinux/archian/")
    mv "${ORIG_NAME}" "${NAME}"
    popd
fi

# Make hashes
pushd ./output
sha256sum *.iso > SHA256_CHECKSUM
sha512sum *.iso > SHA512_CHECKSUM
