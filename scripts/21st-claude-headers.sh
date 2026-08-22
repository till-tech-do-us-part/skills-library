#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${API_KEY_21ST:-}" ]]; then
  echo "API_KEY_21ST is not set" >&2
  exit 1
fi

node -e 'process.stdout.write(JSON.stringify({"x-api-key": process.env.API_KEY_21ST}))'
