#!/bin/sh
set -e

CONFIG_SRC="/run/telemt/config.toml"
CONFIG_TMP="/tmp/config.toml"
SECRETS_PATH="/run/telemt/secrets.json"

SERVER_IP=$(jq -r '.server_ip' "$SECRETS_PATH")
MASK_DOMAIN=$(jq -r '.mask_domain' "$SECRETS_PATH")

# Логирование
echo "|=====================================================|"
echo "|===Starting telemt proxy from $(pwd)==="
echo "|RUST_LOG: $RUST_LOG"
echo "|Server IP: $SERVER_IP"
echo "|Mask domain: $MASK_DOMAIN"
echo "|=====================================================|"

cp "$CONFIG_SRC" "$CONFIG_TMP"
sed -i "s|tls_domain = \".*\"|tls_domain = \"$MASK_DOMAIN\"|" "$CONFIG_TMP"
# ...и дальше запускай telemt с /tmp/config.toml
#exec /app/telemt /tmp/config.toml

# Проверка config
if [ ! -f "$CONFIG_SRC" ]; then
  echo "ERROR: $CONFIG_SRC not found"
  exit 1
fi


# Генерация секрета если не задан или плейсхолдер
SECRET=$(grep -o '[0-9a-f]\{32\}' "$CONFIG_TMP" | head -1)
if [ -z "$SECRET" ] || [ "$SECRET" = "00000000000000000000000000000000" ]; then
  SECRET=$(openssl rand -hex 16)
  sed -i "s|user1 = \".*\"|user1 = \"$SECRET\"|" "$CONFIG_TMP"
else
  echo "Using existing secret: $SECRET"
fi

echo "|=====================================================|"
echo "|tg://proxy?server=$SERVER_IP&port=443&secret=$SECRET"
echo "|Share link: https://t.me/proxy?server=$SERVER_IP&port=443&secret=$SECRET"
echo "|=====================================================|"

# Запуск
exec /app/telemt "$CONFIG_TMP"