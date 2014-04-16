#!/bin/bash
set -e

TARGET=/mnt

## Partitioning
DISK="/dev/sda"
BOOT_PART="${DISK}1"
SWAP_PART="${DISK}2"
ROOT_PART="${DISK}3"

sfdisk ${DISK} << EOF
unit: sectors

${BOOT_PART}: start=     2048, size=   262144, Id=83
${SWAP_PART}: start=   264192, size=  2097152, Id=82
${ROOT_PART}: start=  2361344, size= 18610176, Id=83
EOF
# Root partition creation and initialization
mkfs.ext4 -jvF -m 0 ${ROOT_PART}
mount -o noatime,errors=remount-ro ${ROOT_PART} ${TARGET}

# Boot partition creation and initialization
mkdir ${TARGET}/boot
mkfs.ext2 -v ${BOOT_PART}
mount -o noexec,noatime ${BOOT_PART} ${TARGET}/boot

# Create swap and swap on
mkswap ${SWAP_PART}
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
