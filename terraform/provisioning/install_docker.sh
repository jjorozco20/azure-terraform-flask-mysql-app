#!/bin/bash

# Assign variables from passed arguments
MYSQL_USER=$1
MYSQL_PASSWORD=$2
MYSQL_HOST=$3
MYSQL_DB=$4

sleep 60
sudo apt-get update
sudo apt-get install -y docker.io
sudo systemctl start docker
sudo systemctl enable docker

# Pull and run the Flask app container with environment variables
sudo docker pull jjorozco20/flask-mysql-app:1.0.0
sudo docker run -d -p 5001:5001 --name flask-app \
    -e MYSQL_USER="${MYSQL_USER}" \
    -e MYSQL_PASSWORD="${MYSQL_PASSWORD}" \
    -e MYSQL_HOST="${MYSQL_HOST}" \
    -e MYSQL_DB="${MYSQL_DB}" \
    jjorozco20/flask-mysql-app:1.0.0
