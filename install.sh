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
echo "/var/lib/docker/postallastix/boot.sh" >> /etc/rc.d/rc.local;
systemctl enable rc-local;

cd /var/lib/docker;
git clone https://github.com/layen67/docker-postal-ubuntu.git;
cd docker-postal-ubuntu/ubuntu;
chmod +x /var/lib/docker/postallastix/boot.sh;
docker-compose up -d;
sleep 15
sed -i -e "s/example.com/$1/g" /var/lib/docker/postallastix/data/postal/config/postal.yml;
docker-compose run postal initialize-config;
docker-compose run postal initialize;
docker-compose run postal make-user;
docker-compose run postal start;

sed -i -e "s/example.com/$1/g" /var/lib/docker/postallastix/data/postal/config/postal.yml;
docker-compose run postal initialize-config;

docker-compose run postal initialize;
docker-compose run postal make-user;
docker-compose run postal start;
