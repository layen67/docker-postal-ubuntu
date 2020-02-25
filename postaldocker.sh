#!/bin/bash
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common

curl -fsSL https://yum.dockerproject.org/gpg | sudo apt-key add -

sudo add-apt-repository \
    "deb https://apt.dockerproject.org/repo/ \
    ubuntu-$(lsb_release -cs) \
    main"

sudo apt-get update
sudo apt-get -y install docker-engine docker-compose

# add current user to docker group so there is no need to use sudo when running docker
sudo usermod -aG docker $(whoami)
mkdir /var/lib/docker/wordpress;

echo "
version: '2'
services:
  https-portal:
    container_name: https-portal
    image: steveltn/https-portal:latest
    ports:
      - '80:80'
      - '443:443'
    networks:
      static-network:
        ipv4_address: 172.20.128.2
    restart: always
    environment:
#      STAGE: 'production'
      NUMBITS: '4096'
#        FORCE_RENEW: 'true'
      WORKER_PROCESSES: '4'
      WORKER_CONNECTIONS: '1024'
      KEEPALIVE_TIMEOUT: '65'
      GZIP: 'on'
      SERVER_NAMES_HASH_BUCKET_SIZE: '64'
      PROXY_CONNECT_TIMEOUT: '900'
      PROXY_SEND_TIMEOUT: '900'
      PROXY_READ_TIMEOUT: '900'
      CLIENT_MAX_BODY_SIZE: 300M
      DOMAINS: >-
          oups.xyz -> http://172.20.128.4,
    volumes:
      - ./conf.d:/etc/nginx/conf.d/:rw
      - ./ssl_certs:/var/lib/https-portal:rw
      - /var/run/docker.sock:/var/run/docker.sock:ro
      
  db:
    container_name: mysql57
    image: mysql:5.7
    volumes:
      - ./db_data:/var/lib/mysql
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: wproot
      MYSQL_DATABASE: wordpress
      MYSQL_USER: wordpress
      MYSQL_PASSWORD: wordpress
    networks:
      static-network:
        ipv4_address: 172.20.128.3

  wordpress:
    depends_on:
      - db
    image: wordpress:latest
    ports:
      - "8000:80"
    volumes:
      - ./wp_data:/var/www/html
      - ./wp-content:/var/www/html/wp-content
    restart: unless-stopped
    environment:
      WORDPRESS_DB_HOST: db:3306
      WORDPRESS_DB_USER: wordpress
      WORDPRESS_DB_PASSWORD: wordpress
      WORDPRESS_CONFIG_EXTRA: |
        /* Site URL */
        define('WP_HOME', 'https://oups.xyz');     # <-- CHANGEME
        define('WP_SITEURL', 'https://oups.xyz');  # <-- CHANGEME
        /* Developer friendly settings */
        # define('SCRIPT_DEBUG', true);
        # define('CONCATENATE_SCRIPTS', false);
        # define('WP_DEBUG', true);
        # define('WP_DEBUG_LOG', true);
        # define('SAVEQUERIES', true);
        /* Multisite */
        # define('WP_ALLOW_MULTISITE', true );
        # define('MULTISITE', true);
        # define('SUBDOMAIN_INSTALL', false);
        # define('DOMAIN_CURRENT_SITE', 'oups.xyz');  # <-- CHANGEME
        # define('PATH_CURRENT_SITE', '/');
        # define('SITE_ID_CURRENT_SITE', 1);
        # define('BLOG_ID_CURRENT_SITE', 1);
    networks:
      static-network:
        ipv4_address: 172.20.128.4

networks:
  static-network:
    ipam:
      config:
        - subnet: 172.20.0.0/16
          #docker-compose v3+ do not use ip_range
          ip_range: 172.28.5.0/24
"> /var/lib/docker/wordpress/docker-compose.yml;

cd /var/lib/docker/wordpress
docker-compose up -d;
