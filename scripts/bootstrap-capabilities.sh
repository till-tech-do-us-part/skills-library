#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CAP_HOME="${AGENT_CAPABILITY_HOME:-${XDG_DATA_HOME:-$HOME/.local/share}/agent-capabilities}"
VENDOR="$CAP_HOME/vendor"
LOCAL_SKILLS="$CAP_HOME/local-skills"
BIN="$CAP_HOME/bin"
STATE="$CAP_HOME/state"
CLAUDE_SKILLS="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skills"
CODEX_SKILLS="$HOME/.agents/skills"
COLLECTUI_IMAGE="${COLLECTUI_MCP_IMAGE:-agent-capability/collectui-mcp:1.0.0}"

mkdir -p "$VENDOR" "$LOCAL_SKILLS" "$BIN" "$STATE" "$CLAUDE_SKILLS" "$CODEX_SKILLS"

log() { printf '[capabilities] %s\n' "$*"; }
warn() { printf '[capabilities] WARN: %s\n' "$*" >&2; }

require() {
  command -v "$1" >/dev/null 2>&1 || { warn "missing required command: $1"; return 1; }
}

backup_if_present() {
  local src="$1"
  if [[ -f "$src" ]]; then
    cp -p "$src" "$STATE/$(basename "$src").$(date +%Y%m%d%H%M%S).bak"
  fi
}

sync_repo_at_ref() {
  local url="$1" ref="$2" dest="$3"
  if [[ ! -d "$dest/.git" ]]; then
    git clone --filter=blob:none "$url" "$dest"
  fi
  git -C "$dest" fetch --quiet --tags origin
  git -C "$dest" checkout --quiet --detach "$ref"
}

link_skill() {
  local source="$1" name="$2"
  [[ -f "$source/SKILL.md" ]] || { warn "skill missing SKILL.md: $source"; return 1; }
  ln -sfn "$source" "$CLAUDE_SKILLS/$name"
  ln -sfn "$source" "$CODEX_SKILLS/$name"
}

copy_local_assets() {
  rm -rf "$LOCAL_SKILLS/design-capability-router" "$LOCAL_SKILLS/scrollytelling-video"
  cp -a "$ROOT/skills/design-capability-router" "$LOCAL_SKILLS/"
  cp -a "$ROOT/skills/scrollytelling-video" "$LOCAL_SKILLS/"
  cp "$ROOT/scripts/21st-claude-headers.sh" "$BIN/21st-mcp-headers"
  cp "$ROOT/scripts/run-collectui-mcp.sh" "$BIN/collectui-mcp-sandbox"
  chmod 0700 "$BIN/21st-mcp-headers" "$BIN/collectui-mcp-sandbox"
}

install_skills() {
  require git || return 1
  log "syncing pinned vendor skills"
  sync_repo_at_ref \
    "https://github.com/21st-dev/skill.git" \
    "a0059e9f3a8ed0310dee8e37bab9fb32ecbf1fa7" \
    "$VENDOR/21st-skill"
  sync_repo_at_ref \
    "https://github.com/referodesign/refero_skill.git" \
    "1d324d5be0492352e2c8702f70a4f9c386c2345f" \
    "$VENDOR/refero-skill"

  for dir in "$VENDOR/21st-skill"/skills/*; do
    [[ -d "$dir" ]] && link_skill "$dir" "$(basename "$dir")"
  done
  link_skill "$VENDOR/refero-skill/skills/refero-design" "refero-design"
  link_skill "$LOCAL_SKILLS/design-capability-router" "design-capability-router"
  link_skill "$LOCAL_SKILLS/scrollytelling-video" "scrollytelling-video"
}

build_collectui_sandbox() {
  log "building sandboxed CollectUI MCP"
  if command -v docker >/dev/null 2>&1; then
    docker build --pull -t "$COLLECTUI_IMAGE" "$ROOT/collectui"
  elif command -v podman >/dev/null 2>&1; then
    podman build --pull -t "$COLLECTUI_IMAGE" "$ROOT/collectui"
  else
    warn "Docker/Podman not present; CollectUI remains safely unavailable rather than running unsandboxed."
    return 0
  fi
}

claude_ensure_http() {
  local name="$1" url="$2"
  if claude mcp get "$name" >/tmp/claude-mcp-get.$$ 2>/dev/null && grep -Fq "$url" /tmp/claude-mcp-get.$$; then
    rm -f /tmp/claude-mcp-get.$$
    return 0
  fi
  rm -f /tmp/claude-mcp-get.$$
  claude mcp remove "$name" >/dev/null 2>&1 || true
  claude mcp add --transport http --scope user "$name" "$url"
}

configure_claude() {
  if ! command -v claude >/dev/null 2>&1; then
    warn "Claude Code CLI not installed; skills are staged but Claude MCP registration was skipped."
    return 0
  fi

  log "configuring Claude Code MCPs"
  backup_if_present "$HOME/.claude.json"

  # Refero: registration is non-interactive in Claude Code; OAuth occurs when the user authenticates/uses the server.
  claude_ensure_http "refero" "https://api.refero.design/mcp"

  # 21st: custom x-api-key header generated from API_KEY_21ST at connection time.
  if ! claude mcp get 21st >/tmp/claude-21st.$$ 2>/dev/null || \
     ! grep -Fq "https://21st.dev/api/mcp" /tmp/claude-21st.$$; then
    claude mcp remove 21st >/dev/null 2>&1 || true
    local json
    json="$(node -e 'const p=process.argv[1]; process.stdout.write(JSON.stringify({type:"http",url:"https://21st.dev/api/mcp",headersHelper:p}))' "$BIN/21st-mcp-headers")"
    claude mcp add-json 21st "$json" --scope user
  fi
  rm -f /tmp/claude-21st.$$

  # Community CollectUI package is launched only through the no-mount sandbox wrapper.
  if ! claude mcp get collectui >/tmp/claude-collectui.$$ 2>/dev/null || \
     ! grep -Fq "collectui-mcp-sandbox" /tmp/claude-collectui.$$; then
    claude mcp remove collectui >/dev/null 2>&1 || true
    claude mcp add --transport stdio --scope user collectui -- "$BIN/collectui-mcp-sandbox"
  fi
  rm -f /tmp/claude-collectui.$$
}

codex_write_refero_config_noninteractive() {
  local config="$HOME/.codex/config.toml"
  mkdir -p "$HOME/.codex"

  # Codex 0.149.0 starts OAuth immediately when `codex mcp add` discovers an
  # OAuth-capable server. Bootstrap must never open an owner-auth flow, so write
  # only this MCP table deterministically and leave authentication to
  # `codex mcp login refero`.
  node - "$config" <<'NODE'
const fs = require('fs');
const path = process.argv[2];
let text = fs.existsSync(path) ? fs.readFileSync(path, 'utf8') : '';
const lines = text.split(/\r?\n/);
const kept = [];
let skipping = false;

for (const line of lines) {
  const match = line.match(/^\s*\[([^\]]+)\]\s*$/);
  if (match) {
    const table = match[1].trim();
    const isRefero = table === 'mcp_servers.refero' || table.startsWith('mcp_servers.refero.');
    if (isRefero) {
      skipping = true;
      continue;
    }
    if (skipping) skipping = false;
  }
  if (!skipping) kept.push(line);
}

while (kept.length && kept[kept.length - 1].trim() === '') kept.pop();
if (kept.length) kept.push('');
kept.push('[mcp_servers.refero]');
kept.push('url = "https://api.refero.design/mcp"');
kept.push('');
fs.writeFileSync(path, kept.join('\n'), { mode: 0o600 });
NODE
}

configure_codex() {
  if ! command -v codex >/dev/null 2>&1; then
    warn "Codex CLI not installed; skills are staged but Codex MCP registration was skipped."
    return 0
  fi

  log "configuring Codex MCPs"
  backup_if_present "$HOME/.codex/config.toml"

  if ! codex mcp get refero >/tmp/codex-refero.$$ 2>/dev/null || \
     ! grep -Fq "https://api.refero.design/mcp" /tmp/codex-refero.$$; then
    codex_write_refero_config_noninteractive
  fi
  rm -f /tmp/codex-refero.$$

  if ! codex mcp get 21st >/tmp/codex-21st.$$ 2>/dev/null || \
     ! grep -Fq "https://21st.dev/api/mcp" /tmp/codex-21st.$$; then
    codex mcp remove 21st >/dev/null 2>&1 || true
    codex mcp add 21st --url https://21st.dev/api/mcp --bearer-token-env-var API_KEY_21ST
  fi
  rm -f /tmp/codex-21st.$$

  if ! codex mcp get collectui >/tmp/codex-collectui.$$ 2>/dev/null || \
     ! grep -Fq "collectui-mcp-sandbox" /tmp/codex-collectui.$$; then
    codex mcp remove collectui >/dev/null 2>&1 || true
    codex mcp add collectui -- "$BIN/collectui-mcp-sandbox"
  fi
  rm -f /tmp/codex-collectui.$$
}

main() {
  require node
  copy_local_assets
  install_skills
  build_collectui_sandbox
  configure_claude
  configure_codex

  cat > "$STATE/installed.txt" <<EOF
installed_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)
21st_skill_ref=a0059e9f3a8ed0310dee8e37bab9fb32ecbf1fa7
refero_skill_ref=1d324d5be0492352e2c8702f70a4f9c386c2345f
collectui_mcp=1.0.0
scrolly_video_recommended=0.0.24
EOF

  log "bootstrap complete; run: bash scripts/validate-capabilities.sh"
  if [[ -z "${API_KEY_21ST:-}" ]]; then
    warn "21st is configured but API_KEY_21ST is not present in this shell."
  fi
  log "Refero OAuth may still require Claude /mcp authentication or: codex mcp login refero"
}

main "$@"
