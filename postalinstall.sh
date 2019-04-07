#!/bin/bash
domain=$1;

# This will install everything required to run a basic Postal installation.
# This should be run on a clean Ubuntu 16.04 server.
#
# Once the installation has completed you will be able to access the Postal web
# interface on port 443. It will have a self-signed certificate.
#
# * Change the MySQL & RabbitMQ passwords
# * Create your first admin user with 'postal make-user'
# * Replace the self-signed certificate in /etc/nginx/ssl/postal.cert
# * Make appropriate changes to the configuration in /opt/postal/config/postal.yml
# * Setup your DNS                          [ https://github.com/atech/postal/wiki/Domains-&-DNS-Configuration ]
# * Configure the click & open tracking     [ https://github.com/atech/postal/wiki/Click-&-Open-Tracking ]
# * Configure spam & virus checking         [ https://github.com/atech/postal/wiki/Spam-&-Virus-Checking ]

set -e

#
# Dependencies
#
apt update;
apt-get install apt-transport-https;
apt install -y software-properties-common;
apt-add-repository ppa:brightbox/ruby-ng -y;
apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8;
add-apt-repository 'deb [arch=amd64,i386,ppc64el] http://mirrors.coreix.net/mariadb/repo/10.1/ubuntu xenial main';
curl -sL https://www.rabbitmq.com/rabbitmq-release-signing-key.asc | apt-key add -;
add-apt-repository 'deb http://www.rabbitmq.com/debian/ testing main';
apt update;
export DEBIAN_FRONTEND=noninteractive;
apt install -y ruby2.3 ruby2.3-dev build-essential mariadb-server libmysqlclient-dev rabbitmq-server nodejs git nginx wget nano;
gem install bundler procodile --no-rdoc --no-ri;

#
# MySQL
#
echo 'CREATE DATABASE `postal` CHARSET utf8mb4 COLLATE utf8mb4_unicode_ci;' | mysql -u root;
echo 'GRANT ALL ON `postal`.* TO `postal`@`127.0.0.1` IDENTIFIED BY "p0stalpassw0rd";' | mysql -u root;
echo 'GRANT ALL PRIVILEGES ON `postal-%` . * to `postal`@`127.0.0.1`  IDENTIFIED BY "p0stalpassw0rd";' | mysql -u root;

#
# RabbitMQ
#
rabbitmqctl add_vhost /postal;
rabbitmqctl add_user postal p0stalpassw0rd;
rabbitmqctl set_permissions -p /postal postal ".*" ".*" ".*";

#
# System prep
#
useradd -r -m -d /opt/postal -s /bin/bash postal;
setcap 'cap_net_bind_service=+ep' /usr/bin/ruby2.3;

#
# Application Setup
#
sudo -i -u postal mkdir -p /opt/postal/app;
wget https://postal.atech.media/packages/stable/latest.tgz -O - | sudo -u postal tar zxpv -C /opt/postal/app;
ln -s /opt/postal/app/bin/postal /usr/bin/postal;
postal bundle /opt/postal/vendor/bundle;
postal initialize-config;
sed -i -e "s/example.com/$1/g" /opt/postal/config/postal.yml;
postal initialize;
postal start;

#
# nginx
#
cp /opt/postal/app/resource/nginx.cfg /etc/nginx/sites-available/default;
mkdir /etc/nginx/ssl/;
openssl req -x509 -newkey rsa:4096 -keyout /etc/nginx/ssl/postal.key -out /etc/nginx/ssl/postal.cert -days 365 -nodes -subj "/C=GB/ST=1Example/L=2Example/O=3Example/CN=postal.$1";
service nginx reload;

cd /etc/systemd/system;
curl -O https://raw.githubusercontent.com/layen67/docker-postal-ubuntu/master/postal.service;
systemctl daemon-reload;
systemctl enable postal;
systemctl start postal;

apt-get -y install software-properties-common;
add-apt-repository -y ppa:certbot/certbot;
apt-get -y update;
apt-get -y install certbot;
apt-get -y install python-certbot-nginx;

certbot certonly \
  --nginx \
  --non-interactive \
  --agree-tos \
  --email lkbcontact@gmail.com \
  --domains postal.$1

sed -i -r 's/.*postal.cert.*/    ssl_certificate      \/etc\/letsencrypt\/live\/postal.$1\/fullchain.pem;/g' /etc/nginx/sites-available/default;
sed -i -r 's/.*postal.key.*/    ssl_certificate_key      \/etc\/letsencrypt\/live\/postal.$1\/privkey.pem;/g' /etc/nginx/sites-available/default;
sed -i -e "s/yourdomain.com/$1/g" /etc/nginx/sites-available/default;

service nginx restart;
sleep 10
postal start
postal make-user;
sleep 5
#
# All done
#
echo
echo "Installation complete"
reboot;
