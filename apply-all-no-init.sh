#!/bin/bash

sudo rm -rf ./mariadb-data
mkdir mariadb-data

sudo kubectl apply -f mariadb-pv-pvc.yaml
sudo kubectl apply -f mariadb-cm.yaml
sudo kubectl apply -f mariadb-svc.yaml
sudo kubectl apply -f mariadb-secret.yaml
sudo kubectl apply -f mariadb-ss-no-init.yaml
