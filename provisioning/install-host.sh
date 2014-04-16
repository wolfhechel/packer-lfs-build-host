#!/bin/bash
set -e

TARGET=/mnt

## Partitioning
DISK="/dev/sda"
ROOT_PART="${DISK}1"
SWAP_PART="${DISK}2"

sfdisk ${DISK} << EOF
unit: sectors

${ROOT_PART} : start=     2048, size= 18874368, Id=83
${SWAP_PART} : start= 18876416, size=  2095104, Id=82
/dev/sda3    : start=        0, size=        0, Id= 0
/dev/sda4    : start=        0, size=        0, Id= 0
EOF

mkfs.ext4 -jvF -m 0 ${ROOT_PART}
mkswap ${SWAP_PART}

mount -o noatime,errors=remount-ro ${ROOT_PART} ${TARGET}
swapon ${SWAP_PART}

## Bootstrapping
pacstrap ${TARGET} openssh syslinux vim base base-devel

genfstab -p ${TARGET} >> ${TARGET}/etc/fstab

/usr/bin/arch-chroot ${TARGET} syslinux-install_update -i -a -m

## Configure the system

HOSTNAME=${PACKER_BUILD_NAME}
TIMEZONE="UTC"
KEYMAP="sv-latin1"
LANGUAGE="en_US.UTF-8"

CONFIG_SCRIPT=/root/arch-config.sh

cat > ${TARGET}${CONFIG_SCRIPT} << EOF
	echo '${HOSTNAME}' > /etc/hostname
	/usr/bin/ln -s /usr/share/zoneinfo/${TIMEZONE} /etc/localtime
	echo 'KEYMAP=${KEYMAP}' > /etc/vconsole.conf

  /usr/bin/sed -i '/#${LANGUAGE}/ s/# *//' /etc/locale.gen
	/usr/bin/locale-gen

  /usr/bin/mkinitcpio -p linux

  /usr/bin/passwd -d root

	/usr/bin/sed -i '/UseDNS/ s/# *//;s/yes/no/' /etc/ssh/sshd_config
  /usr/bin/sed -i '/PermitRootLogin/ s/#//' /etc/ssh/sshd_config
  /usr/bin/sed -i '/PermitEmptyPasswords/ s/#//;s/no/yes/' /etc/ssh/sshd_config

  /usr/bin/sed -i '/^auth.*pam_unix.so/ s/$/ nullok/' /etc/pam.d/su-l

	/usr/bin/systemctl enable sshd.service

	/usr/bin/pacman -Scc --noconfirm

  # Builder setup
	useradd -s /bin/bash -g users -m -k /dev/null bob
	passwd -d bob
EOF

/usr/bin/arch-chroot ${TARGET} /bin/bash ${CONFIG_SCRIPT}

rm ${TARGET}${CONFIG_SCRIPT}
