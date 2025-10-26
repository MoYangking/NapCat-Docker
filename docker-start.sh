#!/usr/bin/env bash
set -e

# Clean stale Xvfb lock if present
rm -f /tmp/.X1-lock || true

# Adjust UID/GID for napcat if provided
: "${NAPCAT_UID:=0}"
: "${NAPCAT_GID:=0}"
usermod -o -u "${NAPCAT_UID}" napcat || true
groupmod -o -g "${NAPCAT_GID}" napcat || true
usermod -g "${NAPCAT_GID}" napcat || true
chown -R "${NAPCAT_UID}:${NAPCAT_GID}" /app || true

# Configure WebUI token if provided and not already set
CONFIG_PATH=/app/napcat/config/webui.json
if [ ! -f "${CONFIG_PATH}" ] && [ -n "${WEBUI_TOKEN}" ]; then
  echo "Configuring WebUI token..."
  : "${WEBUI_PREFIX:=}"
  cat > "${CONFIG_PATH}" <<EOF
{
  "host": "0.0.0.0",
  "prefix": "${WEBUI_PREFIX}",
  "port": 6099,
  "token": "${WEBUI_TOKEN}",
  "loginRate": 3
}
EOF
fi

# Apply MODE template if provided
if [ -n "${MODE}" ]; then
  if [ -f "/app/templates/${MODE}.json" ]; then
    cp "/app/templates/${MODE}.json" "/app/napcat/config/onebot11.json"
  else
    echo "Warning: /app/templates/${MODE}.json not found; skipping MODE apply" >&2
  fi
fi

exec /usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf

