#!/usr/bin/env bash

set -euf -o pipefail

# these are exported within this script
export $(cat .env | xargs)

export WASTE_ENDPOINT
export WHISPER_MODEL

envsubst < tpl_waste.service > ./output/waste.service
envsubst < tpl_waste-proxy.service > ./output/waste-proxy.service

