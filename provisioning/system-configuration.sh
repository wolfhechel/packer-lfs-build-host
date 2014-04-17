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

echo "==> creating build user ${BUILD_USER}"

_tmp_skel=$(/usr/bin/mktemp -d)

/usr/bin/cat > $_tmp_skel/.bash_profile << "EOF"
exec env -i HOME=$HOME TERM=$TERM PS1='\u:\w\$ ' /bin/bash
EOF

/usr/bin/cat > $_tmp_skel/.bashrc << EOF
set +h
umask 022
LFS="${BUILD_DIR}"
LC_ALL=POSIX
LFS_TGT=\$(uname -m)-lfs-linux-gnu
PATH=/tools/bin:/bin:/usr/bin
export LFS LC_ALL LFS_TGT PATH
EOF

/usr/bin/useradd -s /bin/bash -g users -m -k $_tmp_skel -N -p '' ${BUILD_USER}

echo "==> setting up build environment in ${BUILD_DIR}"
/usr/bin/install -d -m 1777 -o ${BUILD_USER} ${BUILD_DIR}/sources

/usr/bin/install -d -o ${BUILD_USER} ${BUILD_DIR}/tools
/usr/bin/ln -sv ${BUILD_DIR}/tools /

echo "==> cleaning up installation"
/usr/bin/pacman -Rcns --noconfirm gptfdisk
/usr/bin/pacman -Scc --noconfirm
