#!/bin/bash

if [[ ! -d ./mariadb-data ]]; then
  mkdir mariadb-data
  if [[ ! -d ./mariadb-data/primary ]]; then
    mkdir mariadb-data/primary
  fi
fi

for i in {1..14}
do
  if [[ ! -d ./mariadb-data/replica-${i} ]]; then
    mkdir mariadb-data/replica-$i
  fi
done

if [[ ! -d ./mariadb-dump-data ]]; then
  mkdir mariadb-dump-data
fi

kubectl apply -f mariadb-pv-pvc.yaml
kubectl apply -f mariadb-cm.yaml
kubectl apply -f mariadb-svc.yaml
kubectl apply -f mariadb-secret.yaml
kubectl apply -f mariadb-ss.yaml
