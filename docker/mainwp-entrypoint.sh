#!/usr/bin/env bash
set -euo pipefail

ORIGINAL_ENTRYPOINT="/usr/local/bin/docker-entrypoint.sh"
BOOTSTRAP_SCRIPT="/usr/local/bin/mainwp-bootstrap.sh"

if [[ ! -x "${ORIGINAL_ENTRYPOINT}" ]]; then
  echo "[MainWP] Original WordPress entrypoint missing at ${ORIGINAL_ENTRYPOINT}" >&2
  exit 1
fi

if [[ "$#" -eq 0 ]]; then
  set -- apache2-foreground
fi

if [[ "$1" == "apache2-foreground" || "$1" == "php-fpm" ]]; then
  echo "[MainWP] Starting background bootstrap helper..." >&2
  ( "${BOOTSTRAP_SCRIPT}" ) &
fi

exec "${ORIGINAL_ENTRYPOINT}" "$@"
