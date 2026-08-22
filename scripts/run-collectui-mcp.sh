#!/usr/bin/env bash
set -euo pipefail

IMAGE="${COLLECTUI_MCP_IMAGE:-agent-capability/collectui-mcp:1.0.0}"

if command -v docker >/dev/null 2>&1; then
  runtime=(docker run)
elif command -v podman >/dev/null 2>&1; then
  runtime=(podman run)
else
  echo "CollectUI MCP requires Docker or Podman; refusing unsafe unsandboxed execution." >&2
  exit 78
fi

exec "${runtime[@]}" \
  --rm \
  -i \
  --read-only \
  --tmpfs /tmp:rw,nosuid,nodev,noexec,size=64m \
  --cap-drop ALL \
  --security-opt no-new-privileges \
  --pids-limit 128 \
  --memory 384m \
  --cpus 1.0 \
  --network bridge \
  "$IMAGE"
