#!/bin/bash

# volume setup
vgchange -ay

DEVICE_FS=`blkid -o value -s TYPE ${DEVICE}`
if [ "`echo -n $DEVICE_FS`" == "" ] ; then
  # wait for the device to be attached
  DEVICENAME=`echo "${DEVICE}" | awk -F '/' '{print $3}'`
  DEVICEEXISTS=''
  while [[ -z $DEVICEEXISTS ]]; do
    echo "checking $DEVICENAME"
    DEVICEEXISTS=`lsblk |grep "$DEVICENAME" |wc -l`
    if [[ $DEVICEEXISTS != "1" ]]; then
      sleep 15
    fi
  done
  pvcreate ${DEVICE}
  vgcreate data ${DEVICE}
  lvcreate --name volume1 -l 100%FREE data
  mkfs.ext4 /dev/data/volume1
fi
mkdir -p /var/lib/jenkins
echo '/dev/data/volume1 /var/lib/jenkins ext4 defaults 0 0' >> /etc/fstab
mount /var/lib/jenkins

# jenkins repository
wget -q -O - https://pkg.jenkins.io/debian/jenkins.io.key | sudo apt-key add -
echo "deb http://pkg.jenkins.io/debian binary/" >> /etc/apt/sources.list
apt-get update
apt install ca-certificates

# install dependencies
apt-get update
apt-get install -y python3.8 openjdk-8-jre
update-java-alternatives --set java-1.8.0-openjdk-arm64
# install jenkins
apt-get install -y jenkins unzip

# install pip
wget -q https://bootstrap.pypa.io/get-pip.py
python3.8 get-pip.py

# install awscli
pip install awscli

# install terraform
wget -q https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_arm.zip \
&& unzip -o terraform_${TERRAFORM_VERSION}_linux_arm.zip -d /usr/local/bin \
&& rm terraform_${TERRAFORM_VERSION}_linux_arm.zip

# install packer
cd /usr/local/bin
wget -q https://releases.hashicorp.com/packer/1.7.0/packer_1.7.0_linux_arm.zip
unzip packer_1.7.0_linux_arm.zip

# clean up
apt-get clean
rm terraform_0.7.7_linux_arm.zip
rm packer_1.7.0_linux_arm.zip
