#!/bin/bash

[ $# != 2 ] && echo "Usage: "`basename $0`" base_precise64 6" && exit 1

name=$1
revision=$2

VBoxManage modifyvdi ~/VirtualBox\ VMs/$name/$name.vdi compact
vagrant package --base $name --output $name.$revision.box --vagrantfile Vagrantfile.pkg
