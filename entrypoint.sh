#!/bin/sh
set -e

CONFIG_PATH="/run/telemt/config.toml"
SECRETS_PATH="/run/telemt/secrets.json"
TLSFRONT_DIR="/run/telemt/tlsfront"

# Логирование
echo "|=====================================================|"
echo "|===Starting telemt proxy from $(pwd)==="
echo "|RUST_LOG: $RUST_LOG"

SERVER_IP=$(jq -r '.server_ip' "$SECRETS_PATH")
MASK_DOMAIN=$(jq -r '.mask_domain' "$SECRETS_PATH")

echo "|Server IP: $SERVER_IP"
echo "|Mask domain: $MASK_DOMAIN"
echo "|=====================================================|"

cp "$CONFIG_PATH" /tmp/config.toml
sed -i "/^\[censorship\]/,/^\[/s/^tls_domain *= *\".*\"/tls_domain = \"$MASK_DOMAIN\"/" /tmp/config.toml

# Проверка config
if [ ! -f "$CONFIG_PATH" ]; then
  echo "ERROR: $CONFIG_PATH not found"
  exit 1
fi

# Создание tlsfront если tls_emulation=true
if grep -q 'tls_emulation.*true' "$CONFIG_PATH" && [ ! -d "$TLSFRONT_DIR" ]; then
  mkdir -p "$TLSFRONT_DIR"
  chmod 755 "$TLSFRONT_DIR"
fi

# Генерация секрета если не задан или плейсхолдер
if grep -q '00000000000000000000000000000000' /tmp/config.toml; then
  SECRET=$(openssl rand -hex 16)
  sed -i "s/00000000000000000000000000000000/$SECRET/" /tmp/config.toml
else
  SECRET=$(grep -o '[0-9a-f]\{32\}' /tmp/config.toml | head -1)
fi

echo "|=====================================================|"
echo "|tg://proxy?server=$SERVER_IP&port=443&secret=$SECRET"
echo "|Share link: https://t.me/proxy?server=$SERVER_IP&port=443&secret=$SECRET"
echo "|=====================================================|"

# Запуск
exec /app/telemt /tmp/config.toml