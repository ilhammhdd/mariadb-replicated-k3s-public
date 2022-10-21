#!/bin/bash
sudo rm -rf ./mariadb-data
mkdir mariadb-data
mkdir mariadb-data/primary
for i in {0..9}
do
  mkdir mariadb-data/replica-i
