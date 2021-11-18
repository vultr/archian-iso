#!/bin/bash

VERSION="${1}"

if [ -z "${VERSION}" ]; then
    VERSION=$(date +%Y%m)
fi

# Set failures
set -eo pipefail

# Build specs
CD=`pwd`

# Download reqs
pacman -Sy --noconfirm
pacman -S archiso git --noconfirm

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
chmod +x archian/install.sh

# Add Archian
cp -rf ./archian/ ./archlive/airootfs/root

# Change .automated_script.sh
cp -f ./automated_script.sh ./archlive/airootfs/root/.automated_script.sh
chmod +x ./archlive/airootfs/root/.automated_script.sh

# Copy rootfs
if [ -d rootfs ]; then
    cp -rf rootfs/* ./archlive/airootfs/
fi

# Change hostname
sed -i -e 's/archiso/archianiso/g' ./archlive/airootfs/etc/hostname

# Set DNS details
rm ./archlive/airootfs/etc/resolv.conf
echo "nameserver 8.8.8.8" > ./archlive/airootfs/etc/resolv.conf

# Set ISO name
sed -i -e 's/iso_name.*/iso_name="archian"/' ./archlive/profiledef.sh
sed -i -e "s/iso_label.*/iso_label=\"ARCHIAN_${VERSION}\"/" ./archlive/profiledef.sh
sed -i -e 's/iso_publisher.*/iso_publisher="Archian <https:\/\/github.com\/eb3095\/archian>"/' ./archlive/profiledef.sh
sed -i -e 's/iso_application.*/iso_application="Archian Live\/Rescue CD"/' ./archlive/profiledef.sh
sed -i -e "s/iso_version.*/iso_version=\"${VERSION}\"/" ./archlive/profiledef.sh

# Change splash
cp -f ./splash.png ./archlive/syslinux/splash.png

# Change syslinux title
sed -i -e 's/MENU TITLE Arch Linux/MENU TITLE Archian/' ./archlive/syslinux/archiso_head.cfg

# Change the menus
sed -i -e 's/Arch Linux install medium/Archian install medium/g' ./archlive/syslinux/*.cfg

# Fix perms
LINE_COUNT=$(cat ./archlive/profiledef.sh | wc -l)
head -n $(((LINE_COUNT - 1))) ./archlive/profiledef.sh > ./archlive/profiledef.sh.new
echo '  ["/root/archian/install.sh"]="0:0:755"' >> ./archlive/profiledef.sh.new
echo ')' >> ./archlive/profiledef.sh.new
rm -f ./archlive/profiledef.sh
mv ./archlive/profiledef.sh.new ./archlive/profiledef.sh

# Set motd
cat motd > ./archlive/airootfs/etc/motd

# Build
mkarchiso -v -w ./work -o ./output ./archlive

# Add version
echo "${VERSION}" >> ./output/version

# Make hashes
pushd ./output
sha256sum *.iso > SHA256_CHECKSUM
sha512sum *.iso > SHA512_CHECKSUM
popd
