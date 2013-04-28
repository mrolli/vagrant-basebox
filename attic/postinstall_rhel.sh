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

# Base install

sed -i "s/^.*requiretty/#Defaults requiretty/" /etc/sudoers
sed -i "s/^ONBOOT=no/ONBOOT=yes/" /etc/sysconfig/network-scripts/ifcfg-eth0

cat > /etc/yum.repos.d/epel.repo << EOM
[epel]
name=epel
baseurl=http://download.fedoraproject.org/pub/epel/6/\$basearch
enabled=1
gpgcheck=0
EOM

yum -y install gcc make gcc-c++ kernel-devel-`uname -r` zlib-devel openssl-devel readline-devel sqlite-devel perl wget dkms nfs-utils


# Installing the virtualbox guest additions
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

# Vagrant specific
date > /etc/vagrant_box_build_time

# Add ladmin user
/usr/sbin/groupadd ladmin
/usr/sbin/useradd ladmin -g ladmin -G wheel
echo "ladmin"|passwd --stdin 123456
echo "ladmin        ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers.d/ladmin
chmod 0440 /etc/sudoers.d/ladmin

# Installing vagrant keys
mkdir -pm 700 /home/ladmin/.ssh
wget --no-check-certificate 'https://raw.github.com/mitchellh/vagrant/master/keys/vagrant.pub' -O /home/ladmin/.ssh/authorized_keys
chmod 0600 /home/ladmin/.ssh/authorized_keys
chown -R ladmin /home/ladmin/.ssh

# Customize the message of the day
echo 'Welcome to your Vagrant-built virtual machine.' > /etc/motd




# Install Puppet

cat > /etc/yum.repos.d/puppetlabs.repo << EOM
[puppetlabs]
name=puppetlabs
baseurl=http://yum.puppetlabs.com/el/6/products/\$basearch
enabled=1
gpgcheck=0
EOM

yum -y install puppet facter


# Clean up
yum -y erase gtk2 libX11 hicolor-icon-theme avahi freetype bitstream-vera-fonts
yum -y clean all
rm -rf /etc/yum.repos.d/{puppetlabs,epel}.repo

# Zero out the free space to save space in the final image:
dd if=/dev/zero of=/EMPTY bs=1M
rm -f /EMPTY
