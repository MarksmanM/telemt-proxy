#!/bin/sh
set -e

LOCAL_IP="0.0.0.0"
CONFIG_PATH="/run/telemt/config.toml"
TLSFRONT_DIR="/run/telemt/tlsfront"

# Логирование
echo "Starting telemt proxy from $(pwd)"
echo "RUST_LOG: $RUST_LOG"

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
if ! grep -q '^[[:space:]]*[a-zA-Z0-9_]\+.*[0-9a-f]\{32\}$' "$CONFIG_PATH" 2>/dev/null || grep -q '00000000000000000000000000000000' "$CONFIG_PATH"; then
  SECRET=$(openssl rand -hex 16)
  echo "Generated new secret: $SECRET"
  
  # Обновляем config.toml (заменяем первую строку users)
  sed -i "s/^\([[:space:]]*[a-zA-Z0-9_]\+ *= *\).*/\\1\"$SECRET\"/" "$CONFIG_PATH"
  
  echo "Updated $CONFIG_PATH with user1 = \"$SECRET\""
else
  SECRET=$(grep '^\[access\.users\]' -A 10 "$CONFIG_PATH" | grep -o '[0-9a-f]\{32\}' | head -1)
  echo "Using existing secret: $SECRET"
fi

echo "|=====================================================|"
echo "|tg://proxy?server=$LOCAL_IP&port=443&secret=$SECRET"
echo "|Share link: https://t.me/proxy?server=$LOCAL_IP&port=443&secret=$SECRET"
echo "|=====================================================|"

# Запуск
exec /app/telemt "$@"