#!/usr/bin/env bash
set -euo pipefail

WP_PATH="${WORDPRESS_PATH:-/var/www/html}"
AUTO_INSTALL="${MAINWP_AUTO_INSTALL:-true}"
EXTRA_PLUGINS="${MAINWP_EXTRA_PLUGINS:-}"
MAX_RETRIES="${MAINWP_MAX_RETRIES:-30}"
SLEEP_SECONDS="${MAINWP_RETRY_INTERVAL:-10}"

shopt -s nocasematch
if [[ "${AUTO_INSTALL}" != "true" ]]; then
  echo "[MainWP] Auto-install disabled via MAINWP_AUTO_INSTALL. Skipping bootstrap." >&2
  exit 0
fi
shopt -u nocasematch

wait_for_wp() {
  for attempt in $(seq 1 "${MAX_RETRIES}"); do
    if wp --path="${WP_PATH}" --allow-root core is-installed >/dev/null 2>&1; then
      return 0
    fi
    echo "[MainWP] Waiting for WordPress installation (${attempt}/${MAX_RETRIES})..." >&2
    sleep "${SLEEP_SECONDS}"
  done
  return 1
}

install_plugin_if_missing() {
  local slug="$1"
  if wp --path="${WP_PATH}" --allow-root plugin is-installed "${slug}" >/dev/null 2>&1; then
    return 0
  fi
  echo "[MainWP] Installing plugin ${slug}..." >&2
  wp --path="${WP_PATH}" --allow-root plugin install "${slug}" --activate
}

if ! wait_for_wp; then
  echo "[MainWP] WordPress was not fully installed before timeout. MainWP will not be installed automatically." >&2
  exit 0
fi

echo "[MainWP] WordPress detected. Ensuring MainWP Dashboard is installed..." >&2
install_plugin_if_missing "mainwp"

if [[ -n "${EXTRA_PLUGINS}" ]]; then
  echo "[MainWP] Installing extra plugins: ${EXTRA_PLUGINS}" >&2
  for slug in ${EXTRA_PLUGINS}; do
    install_plugin_if_missing "${slug}"
  done
fi

echo "[MainWP] Bootstrap complete." >&2
