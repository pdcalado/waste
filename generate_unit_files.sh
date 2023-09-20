#!/usr/bin/env bash

set -euf -o pipefail

# these are exported within this script
export $(cat .env | xargs)

BIN_PYTHON=$(which python3)
WASTE_SERVE_PY="$(pwd)/serve.py"
WASTE_SOCKET="$(pwd)/sock"
export BIN_PYTHON
export WASTE_SERVE_PY
export WASTE_SOCKET

envsubst < tpl_waste.service > ./output/waste.service
envsubst < tpl_waste.socket > ./output/waste.socket
envsubst < tpl_waste-proxy.service > ./output/waste-proxy.service

