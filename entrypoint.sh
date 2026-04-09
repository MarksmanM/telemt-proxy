#!/bin/sh
set -e

# Логирование запуска
echo "Starting telemt proxy from $(pwd) with config: /run/telemt/config.toml"
echo "RUST_LOG: $RUST_LOG"

# Проверка config
if [ ! -f /run/telemt/config.toml ]; then
  echo "ERROR: config.toml not found at /run/telemt/config.toml"
  exit 1
fi

# Создание tlsfront если нужно (для tls_emulation)
if grep -q 'tls_emulation.*true' /run/telemt/config.toml && [ ! -d /run/telemt/tlsfront ]; then
  mkdir -p /run/telemt/tlsfront
  chmod 755 /run/telemt/tlsfront
fi

# Запуск telemt (аргумент CMD из Dockerfile)
exec /app/telemt "$@"