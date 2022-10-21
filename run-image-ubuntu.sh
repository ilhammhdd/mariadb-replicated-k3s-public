#!/bin/bash
podman run \
  --detach \
  --rm \
  --name mariadb_ubuntu \
  -e MARIADB_ROOT_PASSWORD=asdasd \
  -v {{HOST_MARIADB_DATA_DIR}}:/var/lib/mysql \
  {{REGISTRY_IMAGE}}
