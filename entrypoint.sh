#!/bin/bash
set -e

[[ `hostname` =~ -([0-9]+)$ ]]
ordinal=${BASH_REMATCH[1]}
echo "the ordinal is $ordinal"

if [[ $ordinal -eq 0 ]]; then
  cp /var/lib/mariadb-conf/70-primary.cnf /etc/mysql/mariadb.conf.d/
  echo datadir=/var/lib/mariadb/primary >> /etc/mysql/mariadb.conf.d/70-primary.cnf
  echo server-id=100 >> /etc/mysql/mariadb.conf.d/70-primary.cnf
  if [ -z "$(ls -A /var/lib/mariadb/primary)" ]; then
    mariadb-install-db
  fi
else
  cp /var/lib/mariadb-conf/70-replica.cnf /etc/mysql/mariadb.conf.d/
  echo datadir=/var/lib/mariadb/replica-$ordinal >> /etc/mysql/mariadb.conf.d/70-replica.cnf
  echo server-id=$((100 + $ordinal)) >> /etc/mysql/mariadb.conf.d/70-replica.cnf
  if [ -z "$(ls -A /var/lib/mariadb/replica-${ordinal})" ]; then
    mariadb-install-db
  fi
fi

service mariadb start

echo "Waiting for MariaDB to be ready (accepting connections)"
until mariadb -e "SELECT 1"; do sleep 1; done
echo "MariaDB ready for accepting connection"

ROOT_PASSWORD=
if [[ $ordinal -eq 0 ]]; then
  ROOT_PASSWORD=$MARIADB_PRIMARY_ROOT_PASSWORD
else
  ROOT_PASSWORD=$MARIADB_REPLICA_ROOT_PASSWORD
fi

mariadb -e "UPDATE mysql.global_priv SET \
  priv=json_set(priv, \
    '$.plugin', \
    'mysql_native_password', \
    '$.authentication_string', \
    PASSWORD('${ROOT_PASSWORD}')) \
  WHERE User='root'; \
  DELETE FROM mysql.global_priv WHERE User=''; \
  DELETE FROM mysql.global_priv WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1'); \
  DROP DATABASE IF EXISTS test; \
  DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%'; \
  FLUSH PRIVILEGES;"

service mariadb restart

echo "Waiting for MariaDB to be ready (accepting connections)"
until mariadb -e "SELECT 1"; do sleep 1; done
echo "MariaDB ready for accepting connection"

if [[ $ordinal -eq 0 ]]; then
  mariadb --user=root --password=$ROOT_PASSWORD -e "CREATE USER IF NOT EXISTS \
    'replica'@'%' IDENTIFIED BY '${MARIADB_REPLICA_PASSWORD}'; \
    GRANT REPLICATION SLAVE ON *.* TO 'replica'@'%'; \
    FLUSH PRIVILEGES;"

  mariadb-dump --user=root --password=$ROOT_PASSWORD \
    --all-databases \
    --allow-keywords \
    --flush-logs \
    --master-data=2 \
    --result-file=/var/lib/mariadb-dump/master_dump.sql \
    --single-transaction

  mariadb --user=root --password=$ROOT_PASSWORD -e "CREATE USER IF NOT EXISTS \
    'primary_client'@'%' IDENTIFIED BY '${MARIADB_PRIMARY_CLIENT_PASSWORD}';"

  MASTER_STATUS_FILE=/var/lib/mariadb-dump/master_status.txt

  if [ -f "$MASTER_STATUS_FILE" ]; then
    rm -f $MASTER_STATUS_FILE
  fi

  touch $MASTER_STATUS_FILE
  mariadb --user=root --password=$ROOT_PASSWORD \
    -e "SHOW MASTER STATUS\G;" | grep File >> /var/lib/mariadb-dump/master_status.txt
  mariadb --user=root --password=$ROOT_PASSWORD \
    -e "SHOW MASTER STATUS\G;" | grep Position >> /var/lib/mariadb-dump/master_status.txt
else
  cat /var/lib/mariadb-dump/master_dump.sql | mariadb --user=root --password=$ROOT_PASSWORD

  mariadb --user=root --password=$ROOT_PASSWORD -e "CREATE USER IF NOT EXISTS \
    'replica_client'@'%' IDENTIFIED BY '${MARIADB_REPLICA_CLIENT_PASSWORD}';"

  mariadb --user=root --password=$ROOT_PASSWORD -e "STOP SLAVE;"

  mariadb --user=root --password=$ROOT_PASSWORD -e "CHANGE MASTER TO \
    master_host='mariadb-ss-0.mariadb-svc', \
    master_port=3306, \
    master_user='replica', \
    master_password='${MARIADB_REPLICA_PASSWORD}', \
    master_log_file='$(cat /var/lib/mariadb-dump/master_status.txt | grep File | awk '{print $2}')', \
    master_log_pos=$(cat /var/lib/mariadb-dump/master_status.txt | grep Position | awk '{print $2}'); \
    START SLAVE;"
fi

service mariadb stop

exec "$@"
