#!/bin/bash

kubectl delete -f mariadb-ss.yaml
kubectl delete -f mariadb-ss-no-init.yaml
kubectl delete -f mariadb-svc.yaml
kubectl delete -f mariadb-pv-pvc.yaml
kubectl delete -f mariadb-cm.yaml
kubectl delete -f mariadb-secret.yaml
#rm -rf ./mariadb-data
#rm -rf ./mariadb-dump-data
