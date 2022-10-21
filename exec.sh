#!/bin/bash
kubectl exec -it mariadb-ss-"$@" -- /bin/bash
