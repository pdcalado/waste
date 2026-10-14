#!/usr/bin/env bash

set -euf -o pipefail

# these are exported within this script
export $(cat .env | xargs)

# The server listens on WASTE_ENDPOINT; unset, it serves this host only.
# Docker publishes on an IP, so a hostname such as localhost is refused here.
WASTE_ENDPOINT="${WASTE_ENDPOINT:-127.0.0.1:29999}"
case "${WASTE_ENDPOINT%:*}" in
    *[!0-9.]*) echo "WASTE_ENDPOINT must be <ip>:<port>, got $WASTE_ENDPOINT" >&2; exit 1 ;;
esac
export WASTE_ENDPOINT
export WHISPER_MODEL

envsubst < tpl_waste.service > ./output/waste.service

