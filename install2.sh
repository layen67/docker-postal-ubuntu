#!/bin/sh
domain=$1;
# exit on error
set -e

# install dependance
yum install -y curl git zip unzip nano wget;
wget -qO- https://get.docker.com/ | sh;
systemctl enable docker;
systemctl start docker.service;
curl -L https://github.com/docker/compose/releases/download/1.23.2/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose;
chmod +x /usr/local/bin/docker-compose;

yum -y remove postfix;

chmod +x /etc/rc.d/rc.local;
#echo "/var/lib/docker/docker-postal-ubuntu/boot.sh" >> /etc/rc.d/rc.local;
systemctl enable rc-local;
