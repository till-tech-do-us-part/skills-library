# Agent Capability Library

This repository is the source of truth for durable, cross-project agent capabilities shared by Claude Code and Codex.

## Operating model

Capabilities are selected by task conditions, not by the user naming a tool:

1. **Refero** — research-first product/design evidence. Use when a UI/UX decision benefits from studying real products, screens, flows, or visual styles.
2. **21st.dev** — implementation-oriented component/theme discovery and UI generation. Use after the desired direction is understood, or when a reusable React/shadcn component can accelerate implementation.
3. **CollectUI** — secondary design-inspiration fallback. It is a community MCP integration, not an official CollectUI integration, so it stays read-only, pinned, isolated, and out of the critical path.
4. **ScrollyVideo.js** — project-local runtime dependency for scroll-position-controlled video. Never install globally and never add it to a repository unless the active task actually requires scroll-synchronized video.

The routing rules live in `skills/design-capability-router/SKILL.md`. ScrollyVideo implementation and fallback rules live in `skills/scrollytelling-video/SKILL.md`.

## Bootstrap

On each development host:

```bash
./scripts/bootstrap-capabilities.sh
```

The bootstrap is idempotent. It installs or refreshes vendor-maintained skills, links this repository's portable skills into both agent skill directories, installs the pinned CollectUI MCP in an isolated user tool directory, and registers MCP servers with Claude Code and Codex without writing credentials to Git.

Authentication-dependent capabilities remain disabled or unauthenticated until their owner credentials are available. Run:

```bash
./scripts/validate-capabilities.sh
```

for a deterministic health report.

## Security principles

- Credentials belong in environment variables or provider OAuth stores, never in this repository.
- Prefer official vendor plugins/skills and remote MCP endpoints over copied guidance.
- Pin community packages and install them with lifecycle scripts disabled unless an explicit audit authorizes scripts.
- Runtime libraries are project-local and are installed only when the active architecture calls for them.
- Research/inspiration tools do not override the repository's design system, accessibility rules, framework constraints, or existing components.

See `docs/AUTONOMOUS-UI-CAPABILITIES.md` for the implementation standard and failure/fallback behavior.
