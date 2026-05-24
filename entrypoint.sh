#!/usr/bin/env bash
set -euo pipefail

IRONIC_CONFIG=${IRONIC_CONFIG:-/etc/ironic/ironic.conf}
IRONIC_ROLE=${IRONIC_ROLE:-api}

if [[ ! -r "$IRONIC_CONFIG" ]]; then
  echo "[ironic-entrypoint] ERROR: Config file '$IRONIC_CONFIG' is not readable or missing."
  echo "Mount ironic.conf into the container at $IRONIC_CONFIG."
  exit 1
fi

CONFIG_ARGS=("--config-file" "$IRONIC_CONFIG")

if [[ -r /etc/ironic/conductor-override.conf ]]; then
  CONFIG_ARGS+=("--config-file" "/etc/ironic/conductor-override.conf")
fi

case "$IRONIC_ROLE" in
  api)
    echo "[ironic-entrypoint] Starting ironic-api ..."
    exec ironic-api "${CONFIG_ARGS[@]}"
    ;;
  conductor)
    echo "[ironic-entrypoint] Starting ironic-conductor ..."
    exec ironic-conductor "${CONFIG_ARGS[@]}"
    ;;
  dbsync)
    DBSYNC_CMD=${DBSYNC_CMD:-upgrade}
    echo "[ironic-entrypoint] Running ironic-dbsync $DBSYNC_CMD ..."
    exec ironic-dbsync "${CONFIG_ARGS[@]}" "$DBSYNC_CMD"
    ;;
  *)
    echo "[ironic-entrypoint] ERROR: Unknown IRONIC_ROLE '$IRONIC_ROLE'."
    echo "Valid roles: api, conductor, dbsync"
    exit 1
    ;;
esac
