#!/bin/bash
podman build -f Containerfile.ubuntu -t {{IMAGE}}
podman image rm {{REGISTRY_IMAGE}}
podman tag {{LOCAL_IMAGE}} {{REGISTRY_IMAGE}}
podman push {{REGISTRY_IMAGE}}
