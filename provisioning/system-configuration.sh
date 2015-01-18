#!/usr/bin/env bash

set -e

echo ${PACKER_BUILD_NAME} > /etc/hostname
/usr/bin/ln -s /usr/share/zoneinfo/${TIMEZONE} /etc/localtime
echo "KEYMAP=${KEYMAP}" > /etc/vconsole.conf
/usr/bin/sed -i "/#${LANGUAGE}/ s/# *//" /etc/locale.gen
/usr/bin/locale-gen
/usr/bin/mkinitcpio -p linux

/usr/bin/passwd -d root

echo "==> configuring network"
/usr/bin/systemctl enable dhcpcd@enp0s3.service

echo "==> configuring ssh"
/usr/bin/sed -i '/#PermitRootLogin/ s/#//' /etc/ssh/sshd_config
/usr/bin/sed -i 's/#PermitEmptyPasswords no/PermitEmptyPasswords yes/' /etc/ssh/sshd_config

/usr/bin/sed -i '/^auth.*pam_unix.so/ s/$/ nullok/' /etc/pam.d/su-l
/usr/bin/systemctl enable sshd.service

echo "==> cleaning up installation"
/usr/bin/pacman -Rcns --noconfirm gptfdisk
/usr/bin/pacman -Scc --noconfirm
