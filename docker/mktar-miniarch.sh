#!/usr/bin/env bash
# Generate a minimal filesystem for archlinux and load it into the local
# arch$(date +%y%m).tar.xz --> docker as "arch:$(date +%y%m)"
# requires root
set -e

hash pacstrap &>/dev/null || {
	echo "Could not find pacstrap. Run pacman -S arch-install-scripts"
	exit 1
}

hash expect &>/dev/null || {
	echo "Could not find expect. Run pacman -S expect"
	exit 1
}

export LANG="C.UTF-8"
export LC_ALL=C
if [[ $EUID != 0 ]]; then
    echo '==> This script must be run with root privileges'
    exit 1
fi

ROOTFS=$(mktemp -d ${TMPDIR:-/var/tmp}/rootfs-archlinux-XXXXXXXXXX)
chmod 755 $ROOTFS

# packages to ignore for space savings
PKGIGNORE=(
    cryptsetup
    device-mapper
    dhcpcd
    iproute2
    jfsutils
    linux
    lvm2
    man-db
    man-pages
    mdadm
    nano
    netctl
    openresolv
    pciutils
    pcmciautils
    reiserfsprogs
    s-nail
    systemd-sysvcompat
    usbutils
    vi
    xfsprogs
)
# packages to add in
PKGADD=(
    haveged
)

IFS=','
PKGIGNORE="${PKGIGNORE[*]}"
unset IFS

expect <<EOF
	set send_slow {1 .1}
	proc send {ignore arg} {
		sleep .1
		exp_send -s -- \$arg
	}
	set timeout 180
	spawn pacstrap -C ./mkimage-arch-pacman.conf -c -d -G -i $ROOTFS base ${PKGADD[@]} --ignore $PKGIGNORE
	expect {
		-exact "anyway? \[Y/n\] " { send -- "n\r"; exp_continue }
		-exact "(default=all): " { send -- "\r"; exp_continue }
		-exact "installation? \[Y/n\]" { send -- "y\r"; exp_continue }
	}
EOF

arch-chroot $ROOTFS /bin/sh -c 'mv /usr/share/locale/zh_CN /zh_CN; mv /usr/share/locale/en_US /en_US'
arch-chroot $ROOTFS /bin/sh -c 'rm -r /usr/share/locale/*; rm -r /usr/share/man/*; rm -r /usr/share/doc/*'
arch-chroot $ROOTFS /bin/sh -c 'mv /{en_US,zh_CN} /usr/share/locale/; touch /usr/share/locale/locale.alias'
arch-chroot $ROOTFS /bin/sh -c "haveged -w 1024; pacman-key --init; pkill haveged; pacman -Rs --noconfirm haveged; pacman-key --populate archlinux; pkill gpg-agent"
arch-chroot $ROOTFS /bin/sh -c "ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime"
echo 'en_US.UTF-8 UTF-8' > $ROOTFS/etc/locale.gen
echo 'zh_CN.UTF-8 UTF-8' >> $ROOTFS/etc/locale.gen
arch-chroot $ROOTFS locale-gen
arch-chroot $ROOTFS /bin/sh -c 'echo "Server = http://mirrors.ustc.edu.cn/archlinux/\$repo/os/\$arch" > /etc/pacman.d/mirrorlist'

# add my repo and key
cat ./mkimage-arch-pacman.conf > $ROOTFS/etc/pacman.conf
# error: gpg: connecting dirmngr at '/root/.gnupg/S.dirmngr' failed: IPC connect call failed
# possible reason tar: ./etc/pacman.d/gnupg/S.gpg-agent: socket ignored
arch-chroot $ROOTFS /bin/sh -c 'dirmngr </dev/null' #or 'mkdir -p /root/.gnupg/'
arch-chroot $ROOTFS /bin/sh -c 'pacman-key -r E2054497 && pacman-key --lsign-key E2054497'

# udev doesn't work in containers, rebuild /dev
DEV=$ROOTFS/dev
rm -rf $DEV
mkdir -p $DEV
mknod -m 666 $DEV/null c 1 3
mknod -m 666 $DEV/zero c 1 5
mknod -m 666 $DEV/random c 1 8
mknod -m 666 $DEV/urandom c 1 9
mkdir -m 755 $DEV/pts
mkdir -m 1777 $DEV/shm
mknod -m 666 $DEV/tty c 5 0
mknod -m 600 $DEV/console c 5 1
mknod -m 666 $DEV/tty0 c 4 0
mknod -m 666 $DEV/full c 1 7
mknod -m 600 $DEV/initctl p
mknod -m 666 $DEV/ptmx c 5 2
ln -sf /proc/self/fd $DEV/fd

tar --numeric-owner --xattrs --acls -C $ROOTFS -Jcf arch$(date +%y%m).tar.xz .
#cat arch$(date +%y%m).tar.xz | docker import - arch:$(date +%y%m)
rm -rf $ROOTFS
