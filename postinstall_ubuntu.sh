#!/bin/bash
# postinstall.sh created from Mitchell's official lucid32/64 baseboxes

# Make sure root is running this script.
if [ $UID -ne 0 ]; then
    echo "This script must be run as root!"
    exit 1
fi

# Read in target VirtualBox version to build for.
if [ -z "$1" ]; then
    echo "Usage: ${0} <target_vbox_version> # i.e ${0} 4.2.4"
    exit 1
fi
VBOX_VERSION=$1

# Source lsb release to be able to determine os version.
.  /etc/lsb-release

# Save the build date
date > /etc/vagrant_box_build
echo -e $DISTRIB_DESCRIPTION >> /etc/vagrant_box_build
echo -e "VirtualBox "$VBOX_VERSION >> /etc/vagrant_box_build

# Apt-install various things necessary for Ruby, guest additions,
# etc.
apt-get -y update
apt-get -y dist-upgrade
apt-get -y install linux-headers-$(uname -r) build-essential

# Getting rid of vim-tiny
apt-get -y install vim
update-alternatives --set editor /usr/bin/vim.basic
apt-get -y --purge remove vim-tiny

# Installing the virtualbox guest additions
apt-get -y install dkms
cd /tmp
wget http://download.virtualbox.org/virtualbox/$VBOX_VERSION/VBoxGuestAdditions_$VBOX_VERSION.iso
if [ $? != 0 ]; then
    echo "Unable to get the VboxGuestAdditions version "$VBOX_VERSION
    exit 1
fi
mount -o loop VBoxGuestAdditions_$VBOX_VERSION.iso /mnt
sh /mnt/VBoxLinuxAdditions.run
umount /mnt
rm VBoxGuestAdditions_$VBOX_VERSION.iso

# Setup sudo to allow no-password sudo for "admin" or "sudo" depending on os version.
cp /etc/sudoers /etc/sudoers.orig
if [ $DISTRIB_CODENAME == "lucid"  ]; then
    SUDOERS_GROUP="admin"
    sed -i -e 's/%admin.*/%admin ALL=(ALL) NOPASSWD: ALL/g' /etc/sudoers
else
    SUDOERS_GROUP="sudo"
    sed -i -e 's/%sudo.*/%sudo ALL=(ALL) NOPASSWD: ALL/g' /etc/sudoers
fi
usermod -a -G $SUDOERS_GROUP ladmin

# Fix reboot troubles in unattended headless environments after reboots
grep GRUB_RECORDFAIL /etc/default/grub
if [ $DISTRIB_CODENAME == "precise" -a $? -ne 0 ]; then
    sed -i -e "s/GRUB_TIMEOUT=2/GRUB_TIMEOUT=0\nGRUB_RECORDFAIL_TIMEOUT=0/" /etc/default/grub
    update-grub
fi

# Install NFS client
apt-get -y install nfs-common

# Install puppet from puppetlabs' apt repository and pin release to 3.0.x
wget http://apt.puppetlabs.com/puppetlabs-release-$DISTRIB_CODENAME.deb
dpkg -i puppetlabs-release-$DISTRIB_CODENAME.deb
apt-get update
rm puppetlabs-release-$DISTRIB_CODENAME.deb
echo -e "# Pin puppet to a specific version to avoid unintentional upgrades\nPackage: puppet puppet-common\nPin: version 3.0*\nPin-Priority: 501" > /etc/apt/preferences.d/00-puppet.pref
apt-get -y install puppet

# Installing vagrant keys
mkdir /home/ladmin/.ssh
chmod 700 /home/ladmin/.ssh
cd /home/ladmin/.ssh
wget --no-check-certificate 'https://raw.github.com/mitchellh/vagrant/master/keys/vagrant.pub' -O authorized_keys
chmod 600 /home/ladmin/.ssh/authorized_keys
chown -R ladmin /home/ladmin/.ssh

# Cleanup diskspace
apt-get -y --purge autoremove
apt-get clean
rm -rf /tmp/*

# Removing leftover leases and persistent rules
echo "cleaning up dhcp leases"
rm -rf /var/lib/dhcp3/*

# Make sure Udev doesn't block our network
# http://6.ptmc.org/?p=164
echo "cleaning up udev rules"
rm -rf /etc/udev/rules.d/70-persistent-net.rules
mkdir /etc/udev/rules.d/70-persistent-net.rules
rm -rf /dev/.udev/
rm -f /lib/udev/rules.d/75-persistent-net-generator.rules

# Avoid network interface troubles when booting.
grep pre-up /etc/network/interfaces > /dev/null
if [ $? -ne 0 ]; then
    echo "Adding a 2 sec delay to the interface up, to make the dhclient happy"
    echo "pre-up sleep 2" >> /etc/network/interfaces
fi

# Zero out the free space to save space in the final image:
cat - << EOWARNING
WARNING: The next step will fill up your left over disk space.

DO NOT RUN THIS WHEN YOUR VIRTUAL HD IS RAW!!!!!!

You should NOT do this on a running system.
This is purely for making vagrant boxes damn small.

Press Ctrl+C within the next 10 seconds if you want to abort!!

EOWARNING
sleep 10

echo 'Cleanup bash history'
unset HISTFILE
[ -f /root/.bash_history ] && rm /root/.bash_history
[ -f /home/ladmin/.bash_history ] && rm /home/ladmin/.bash_history

echo 'Cleanup log files'
find /var/log -type f | while read f; do echo -ne '' > $f; done

echo 'Whiteout root'
dd if=/dev/zero of=/EMPTY bs=1M
rm -f /EMPTY

echo 'Whiteout /boot'
dd if=/dev/zero of=/boot/EMPTY bs=1M
rm -f /boot/EMPTY

echo 'Whiteout swap space'
swappart=`cat /proc/swaps | tail -n1 | awk -F ' ' '{print $1}'`
swapoff $swappart
mkswap -f $swappart

# Finally remove this script.
rm -f /home/ladmin/postinstall.sh

exit 0
