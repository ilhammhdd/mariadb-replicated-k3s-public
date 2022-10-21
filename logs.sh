#!/bin/bash
kubectl logs --follow mariadb-ss-"$@"
