#!/usr/bin/env bash
set -uo pipefail

CAP_HOME="${AGENT_CAPABILITY_HOME:-${XDG_DATA_HOME:-$HOME/.local/share}/agent-capabilities}"
CLAUDE_SKILLS="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skills"
CODEX_SKILLS="$HOME/.agents/skills"
BIN="$CAP_HOME/bin"
failures=0
warnings=0

pass() { printf 'PASS  %s\n' "$*"; }
warn() { printf 'WARN  %s\n' "$*"; warnings=$((warnings+1)); }
fail() { printf 'FAIL  %s\n' "$*"; failures=$((failures+1)); }

check_skill() {
  local name="$1"
  [[ -f "$CLAUDE_SKILLS/$name/SKILL.md" ]] && pass "Claude skill: $name" || fail "Claude skill missing: $name"
  [[ -f "$CODEX_SKILLS/$name/SKILL.md" ]] && pass "Codex skill: $name" || fail "Codex skill missing: $name"
}

check_skills() {
  check_skill design-capability-router
  check_skill scrollytelling-video
  check_skill refero-design
  check_skill 21st-cli-use
  check_skill 21st-ai
  check_skill 21st-registry
  check_skill 21st-design-sync
}

check_claude() {
  if ! command -v claude >/dev/null 2>&1; then
    warn "Claude Code CLI not present on this host"
    return
  fi
  for name in refero 21st collectui; do
    if claude mcp get "$name" >/tmp/validate-claude-$name.$$ 2>&1; then
      pass "Claude MCP registered: $name"
    else
      fail "Claude MCP missing: $name"
    fi
    rm -f /tmp/validate-claude-$name.$$
  done
  timeout 30s claude mcp list || warn "Claude MCP health list timed out or returned non-zero"
}

check_codex() {
  if ! command -v codex >/dev/null 2>&1; then
    warn "Codex CLI not present on this host"
    return
  fi
  for name in refero 21st collectui; do
    if codex mcp get "$name" >/tmp/validate-codex-$name.$$ 2>&1; then
      pass "Codex MCP registered: $name"
    else
      fail "Codex MCP missing: $name"
    fi
    rm -f /tmp/validate-codex-$name.$$
  done
  timeout 30s codex mcp list || warn "Codex MCP health list timed out or returned non-zero"
}

check_collectui() {
  if [[ ! -x "$BIN/collectui-mcp-sandbox" ]]; then
    fail "CollectUI sandbox wrapper is not installed"
    return
  fi
  if ! command -v docker >/dev/null 2>&1 && ! command -v podman >/dev/null 2>&1; then
    warn "No Docker/Podman; CollectUI intentionally unavailable"
    return
  fi
  if command -v npx >/dev/null 2>&1; then
    if timeout 90s npx -y @modelcontextprotocol/inspector@2.3.0 --cli \
      "$BIN/collectui-mcp-sandbox" --method tools/list >/tmp/collectui-tools.$$ 2>&1; then
      if grep -Eq 'tools|name' /tmp/collectui-tools.$$; then
        pass "CollectUI MCP sandbox responded to tools/list"
      else
        fail "CollectUI MCP responded but no tools were detected"
      fi
    else
      fail "CollectUI MCP tools/list smoke test failed"
      sed -n '1,80p' /tmp/collectui-tools.$$ >&2 || true
    fi
    rm -f /tmp/collectui-tools.$$
  else
    warn "npx unavailable; skipped MCP Inspector smoke test"
  fi
}

check_21st_auth() {
  if [[ -z "${API_KEY_21ST:-}" ]]; then
    warn "API_KEY_21ST is not set; 21st authentication requires owner credential or existing environment injection"
    return
  fi
  if command -v npx >/dev/null 2>&1; then
    if timeout 90s npx -y @modelcontextprotocol/inspector@2.3.0 --cli \
      https://21st.dev/api/mcp --transport http --method tools/list \
      --header "x-api-key: ${API_KEY_21ST}" >/tmp/21st-tools.$$ 2>&1; then
      pass "21st MCP authenticated tools/list"
    else
      fail "21st MCP authentication/tools-list failed"
      sed -n '1,80p' /tmp/21st-tools.$$ >&2 || true
    fi
    rm -f /tmp/21st-tools.$$
  fi
}

check_refero_auth() {
  # OAuth state is client-managed. The authoritative operational check is the
  # client MCP status; actual design search is performed in an authenticated
  # agent session because tokens are intentionally not exported to this script.
  if command -v claude >/dev/null 2>&1; then
    if timeout 30s claude mcp list 2>/dev/null | grep -E 'refero.*Connected' >/dev/null; then
      pass "Refero connected in Claude Code"
      return
    fi
  fi
  if command -v codex >/dev/null 2>&1; then
    if timeout 30s codex mcp list 2>/dev/null | grep -Ei 'refero.*(authenticated|enabled|connected)' >/dev/null; then
      pass "Refero appears enabled/authenticated in Codex"
      return
    fi
  fi
  warn "Refero MCP is registered but OAuth/live research still needs an authenticated client session"
}

check_scrolly_boundary() {
  if [[ -d "$HOME/node_modules/scrolly-video" || -d /usr/local/lib/node_modules/scrolly-video ]]; then
    warn "ScrollyVideo appears globally/user-home installed; operating standard expects project-local on-demand installation"
  else
    pass "ScrollyVideo not globally installed (correct boundary)"
  fi
}

main() {
  check_skills
  check_claude
  check_codex
  check_collectui
  check_21st_auth
  check_refero_auth
  check_scrolly_boundary
  printf '\nSummary: %d failure(s), %d warning(s)\n' "$failures" "$warnings"
  (( failures == 0 ))
}

main "$@"
