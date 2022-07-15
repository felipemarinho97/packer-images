#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Ideas heavily borrowed from:
# https://github.com/irvingpop/packer-chef-highperf-centos-ami/tree/centos8/create_base_ami
# https://github.com/plus3it/AMIgen7
# https://gist.github.com/alanivey/68712e6172b793037fbd77ebb3112c3f


################################################################################

ROOTFS=/rootfs
DEVICE="/dev/xvdf"

arch="$( uname --machine )"

################################################################################

echo "Update builder system"
dnf -y update

echo "Install missing packages for building"
dnf -y install parted

echo "Wait for udev to create symlink for secondary disk"
while [[ ! -e "$DEVICE" ]]; do sleep 1; done

################################################################################

echo "Create an primary partition"

parted --script "$DEVICE" -- \
mklabel msdos \
mkpart primary xfs 1 -1 \
set 1 boot on

PARTITION="${DEVICE}1"

echo "Wait for device partition creation"
while [[ ! -e "$PARTITION" ]]; do sleep 1; done

mkfs.xfs -f "$PARTITION"

echo "Read-only/print commands"
parted "$DEVICE" print
fdisk -l "$DEVICE"

################################################################################

echo "Chroot Mount /"
mkdir -p "$ROOTFS"
mount "$PARTITION" "$ROOTFS"

echo "Mount/bind special filesystems"
mkdir -p "$ROOTFS/dev" "$ROOTFS/proc" "$ROOTFS/sys" "$ROOTFS/etc"
mount -o bind          /dev     "$ROOTFS/dev"
mount -t devpts        devpts   "$ROOTFS/dev/pts"
mount --types tmpfs    tmpfs    "$ROOTFS/dev/shm"
mount --types proc     proc     "$ROOTFS/proc"
mount --types sysfs    sysfs    "$ROOTFS/sys"
mount --types selinuxfs selinuxfs "$ROOTFS/sys/fs/selinux"

################################################################################

echo "Grab the latest release and repos packages."

dnf --installroot="$ROOTFS" --releasever=2022.0.20220531 -y update

echo "Create fstab entry"
cat > "${ROOTFS}/etc/fstab" <<EOF
#
# /etc/fstab
#
# Accessible filesystems, by reference, are maintained under '/dev/disk/'.
# See man pages fstab(5), findfs(8), mount(8) and/or blkid(8) for more info.
#
# After editing this file, run 'systemctl daemon-reload' to update systemd
# units generated from this file.
#
UUID=$( lsblk "$PARTITION" --noheadings --output uuid ) /                       xfs     defaults        0 0
EOF


echo "Copy GRUB from AL2022"
mkdir "${ROOTFS}/etc/default"
cp -av /etc/default/grub "${ROOTFS}/etc/default/grub"

set +u

echo "Bootstrap system"
dnf --installroot="$ROOTFS" --releasever=2022.0.20220531 -y group install ami-minimal
dnf --installroot="$ROOTFS" --releasever=2022.0.20220531 -y install cloud-init systemd-container systemd-resolved systemd-networkd openssh-server grub2

set -u

################################################################################

echo "Run to complete bootloader setup and create /boot/grub2/grubenv"
chroot "$ROOTFS" grub2-install "$DEVICE"
chroot "$ROOTFS" grub2-mkconfig -o /etc/grub2.cfg


echo "Read-only/print command"
chroot "$ROOTFS" grubby --default-kernel

################################################################################

echo "Enable system units"
chroot "$ROOTFS" systemctl enable sshd.service
chroot "$ROOTFS" systemctl enable systemd-networkd.service
chroot "$ROOTFS" systemctl enable systemd-resolved.service
chroot "$ROOTFS" systemctl enable cloud-init.service
chroot "$ROOTFS" systemctl enable chronyd.service
chroot "$ROOTFS" systemctl mask tmp.mount
chroot "$ROOTFS" systemctl set-default multi-user.target

echo "Update /etc/hosts"
cat > "$ROOTFS/etc/hosts" <<'EOF'
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
EOF

touch "$ROOTFS/etc/resolv.conf"

echo 'RUN_FIRSTBOOT=NO' > "$ROOTFS/etc/sysconfig/firstboot"

cat > "$ROOTFS/etc/sysconfig/network" <<'EOF'
NETWORKING=yes
NOZEROCONF=yes
EOF


echo "Cleanup before creating AMI."

echo "SELinux, also cleans up /tmp"
if ! getenforce | grep --quiet --extended-regexp '^Disabled$' ; then
  echo "Prevent relabel on boot (b/c next command will do it manually)"
  rm --verbose --force "$ROOTFS"/.autorelabel

  echo "Manually \"restore\" SELinux contexts (\"relabel\" clears /tmp and then runs \"restore\")."
  echo "Requires '/sys/fs/selinux' to be mounted in the chroot."
  chroot "$ROOTFS" /sbin/fixfiles -f -F relabel

  echo "Packages from https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html-single/using_selinux/index that contain RPM scripts. Reinstall for the postinstall scriptlets."
  dnf --installroot="$ROOTFS" --releasever=2022.0.20220531 -y reinstall selinux-policy-targeted policycoreutils
fi

echo "Repo cleanup"
dnf --installroot="$ROOTFS" --releasever=2022.0.20220531 --cacheonly --assumeyes clean all
rm --recursive --verbose "$ROOTFS"/var/cache/dnf/*

echo "Clean up systemd machine ID file"
truncate --size=0 "$ROOTFS"/etc/machine-id
chmod --changes 0444 "$ROOTFS"/etc/machine-id

echo "Clean up /etc/resolv.conf"
truncate --size=0 "$ROOTFS"/etc/resolv.conf

echo "Delete any logs"
find "$ROOTFS"/var/log -type f -print -delete

echo "Cleanup cloud-init (https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html)"
rm --recursive --verbose "$ROOTFS"/var/lib/cloud/

echo "Clean up temporary directories"
find "$ROOTFS"/run \! -type d -print -delete
find "$ROOTFS"/run -mindepth 1 -type d -empty -print -delete
find "$ROOTFS"/tmp \! -type d -print -delete
find "$ROOTFS"/tmp -mindepth 1 -type d -empty -print -delete
find "$ROOTFS"/var/tmp \! -type d -print -delete
find "$ROOTFS"/var/tmp -mindepth 1 -type d -empty -print -delete

################################################################################

# Don't /need/ this for packer because the instance is shut down before the volume is snapshotted, but it doesn't hurt...

umount --all-targets --recursive "$ROOTFS"

################################################################################

exit 0