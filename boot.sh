#!/bin/sh
cd /var/lib/docker/docker-postal-ubuntu/ubuntu
docker-compose up -d
sleep 10
docker-compose run postal start
