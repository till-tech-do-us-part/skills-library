# Autonomous UI Capability Operating Standard

## Purpose

Make Refero, 21st.dev, CollectUI, and ScrollyVideo available as condition-driven development capabilities for Claude Code and Codex. Agents select them from task context; users do not need to name them.

## Selection order

| Condition | Primary capability | Why | Fallback / exception |
|---|---|---|---|
| A product/UI decision needs evidence from real products, screens, flows, or visual styles | Refero | Research-first, read-only product/design evidence | If Refero is unavailable or the need is lightweight inspiration only, use CollectUI in its sandbox |
| The direction is known and implementation can benefit from an existing React/shadcn component, theme, template, or generated UI | 21st.dev | Implementation-ready code and vendor-maintained agent skills | Prefer existing repository components first; do not replace a sound design system merely because a 21st component exists |
| Broad visual inspiration is useful and Refero is unavailable/insufficient | CollectUI | Large inspiration catalog | Low-trust community MCP; read-only, isolated, never authoritative for architecture, UX correctness, accessibility, or product behavior |
| The task specifically requires video playback controlled by scroll position/progress | ScrollyVideo.js | Purpose-built runtime library | Prefer CSS/native video/GSAP/Motion for ordinary animation; do not add ScrollyVideo for decorative autoplay or non-scroll video |

## Global vs project-local boundary

### Global/user-scoped

- Refero MCP and Refero's official `refero-design` skill.
- 21st.dev MCP and official vendor skills.
- CollectUI MCP wrapper, but only when an approved Docker/Podman sandbox is available; the MCP is not registered otherwise.
- This repository's routing skills.

### Project-local/on-demand

- `scrolly-video` npm dependency. Install only in a repository whose active task requires it, using that repository's existing package manager and lockfile.
- Any component code pulled from 21st.dev becomes normal repository code and must pass the project's tests, linting, accessibility, performance, and design-system rules.

## Capability 1 — Refero

**Authority**

- https://doc.refero.design/mcp/getting-started
- https://doc.refero.design/mcp/tools
- https://doc.refero.design/skill/overview
- https://github.com/referodesign/refero_skill

**Implementation**

- Remote MCP endpoint: `https://api.refero.design/mcp`.
- Prefer OAuth so long-lived access tokens are not copied into config files.
- Install the official `refero-design` skill from the vendor repository; do not fork its methodology into a competing local skill.
- Live MCP research requires an account/plan with MCP access; the bundled craft guidance remains useful without live research.
- Claude Code registration is non-interactive; OAuth is completed in the client when required.
- Codex 0.149.0 was observed to begin Refero OAuth immediately during `codex mcp add`. Unattended bootstrap therefore writes only the `mcp_servers.refero` URL table to `~/.codex/config.toml`, preserving any other Codex configuration, and leaves owner authentication to `codex mcp login refero`. Bootstrap must never block waiting for OAuth.

**Invocation rules**

Use proactively for:

- new screens, workflows, onboarding, dashboards, pricing, settings, navigation, forms, tables, empty states, or other UX structures where precedent matters;
- redesigns where the current implementation is weak or ambiguous;
- visual-direction work where several credible styles should be compared before implementation;
- multi-step flows where real user-flow evidence can reduce guesswork.

Do not use for:

- routine bug fixes with no design decision;
- exact implementation tasks whose design is already locked and adequately specified;
- copying a single reference verbatim.

**Required behavior**

1. Search styles first when the question is taste/visual direction.
2. Search screens for concrete UI patterns.
3. Search flows for multi-step journeys.
4. Synthesize patterns from multiple references before implementation.
5. Preserve the repository's design system and accessibility standards.

**Validation**

- Claude: `claude mcp list` / `/mcp` shows `refero` connected or requiring OAuth, then a style/screen search succeeds after authentication.
- Codex: `codex mcp list` shows `refero`; run `codex mcp login refero` if it reports `Not logged in`, then perform a real search.
- Skill discovery: `refero-design/SKILL.md` is reachable from both user skill directories.
- Registration/enabled state is not treated as proof of authentication.

## Capability 2 — 21st.dev

**Authority**

- https://21st.dev/blog/introducing-agents-cli
- https://docs.21st.dev/mcp
- https://github.com/21st-dev/skill
- https://github.com/21st-dev/claude-code-plugin
- https://github.com/21st-dev/codex-plugin

**Implementation**

- Remote MCP endpoint: `https://21st.dev/api/mcp`.
- Credential source: `API_KEY_21ST` environment variable; never commit the key.
- Install/sync the official `21st-dev/skill` skill repository. It provides `21st-cli-use`, `21st-ai`, `21st-registry`, and `21st-design-sync`.
- Claude Code uses a header helper so the `x-api-key` value is read from the environment at connection time rather than serialized into Git/config.
- Codex stores only `bearer_token_env_var = "API_KEY_21ST"`; the secret value stays outside configuration.
- The bootstrap registers the remote MCP directly rather than depending on an interactive plugin browser. The official vendor plugins remain a valid interactive alternative.

**Invocation rules**

Use proactively when:

- a React/shadcn UI task could reuse a high-quality component instead of hand-building one;
- a frontend implementation needs several candidate component directions;
- a new theme/template or AI-generated interface can shorten implementation time without compromising repository standards;
- an existing 21st component can be adapted rather than duplicating functionality.

Do not use when:

- the repository already has an appropriate component;
- the target stack is incompatible;
- introducing a third-party component would add more complexity than writing a small local component;
- the task is only design research (use Refero first).

**Required behavior**

1. Inspect the repository's existing components and design tokens first.
2. Search and compare options before installing code when the choice is material.
3. State constraints such as server/client compatibility, animation-library restrictions, and accessibility requirements.
4. Treat installed component code as owned application code: review, adapt, lint, test, and validate it.
5. Preserve dark mode, reduced motion, responsive behavior, semantic HTML, and keyboard accessibility where applicable.

**Validation**

- MCP lists search/get/generate tools after authentication.
- `21st` CLI can report auth/usage and perform a metadata search.
- Official skills are discoverable in both agent skill directories.

## Capability 3 — CollectUI

**Authority / provenance**

- CollectUI itself: https://collectui.com/
- Community npm integration: `collectui-mcp@1.0.0`, published by `jsstechio` (not established as an official CollectUI package).

**Risk classification**: LOW-TRUST / OPTIONAL / READ-ONLY.

The package is deliberately not run directly in the host agent process. CI audits the exact npm package before execution, including identity, lifecycle scripts, executable metadata, and dependencies. The runtime wrapper launches it in Docker or Podman with:

- no repository or home-directory mount;
- read-only root filesystem;
- temporary `/tmp` only;
- all Linux capabilities dropped;
- `no-new-privileges`;
- memory/PID/CPU limits;
- no credentials passed through;
- only outbound network access required for design lookup.

If neither Docker nor Podman exists, bootstrap removes/skips the CollectUI MCP registration instead of leaving a broken tool visible or silently falling back to unsandboxed execution.

**Invocation rules**

Use only when:

- the task benefits from broad UI inspiration; and
- Refero is unavailable, exhausted, or not yielding adequate breadth; or
- a lightweight category-level inspiration sweep is useful before choosing a direction.

Do not use for architecture, security, framework decisions, product requirements, accessibility truth, or as the only source for a design decision.

**Validation**

- CI builds the sandbox image and runs MCP Inspector `tools/list` through the wrapper.
- The validated package exposes `collectui_categories`, `collectui_browse`, and `collectui_search`.
- A host validation succeeds only if a container runtime exists and the MCP returns a non-empty tool list; otherwise safe omission is the expected state.

## Capability 4 — ScrollyVideo.js

**Authority**

- https://github.com/dkaoster/scrolly-video
- https://scrollyvideo.js.org/

**Implementation boundary**

ScrollyVideo is a runtime library, not an MCP. It is never installed globally. The `scrollytelling-video` skill decides whether it is appropriate and, when required, installs it with the active repository's existing package manager and lockfile.

Supported by the project: plain JS, React, Vue, Svelte, and Astro. The library exposes scroll tracking and manual progress control, including `setVideoPercentage` / `videoPercentage`.

**Invocation rules**

Use when the visual requirement is genuinely **scroll-position-controlled video playback**, especially where forward/reverse scrub behavior is central to the experience.

Do not use for:

- ordinary autoplay/background video;
- simple reveal/fade/parallax animation;
- a static hero image;
- a motion effect better expressed with CSS, GSAP, Motion, or Three.js;
- projects where the added payload/performance tradeoff is unjustified.

**Required implementation checks**

- Respect `prefers-reduced-motion` and provide a non-scrub fallback.
- Test mobile Safari and account for the documented iOS Low Power Mode limitation.
- Size/compress assets deliberately; the project's fallback strategy may require keyframe interval 1 for best seeking behavior.
- Avoid layout shifts; reserve media dimensions.
- Validate forward and reverse scroll, rapid scroll, resize/orientation change, keyboard navigation around the section, and mobile performance.
- Coordinate with GSAP/other scroll controllers only through one source of truth for progress; avoid two competing scroll controllers.

## Durable discovery

`skills/design-capability-router/SKILL.md` has broad intent-based triggers and decides which capability should be applied. `skills/scrollytelling-video/SKILL.md` contains the narrower runtime procedure. Both are symlinked into:

- Claude Code: `~/.claude/skills/`
- Codex: `~/.agents/skills/`

Vendor skills are linked from pinned upstream checkouts into the same directories. This preserves upstream maintainability while keeping local routing policy separate.

## Bootstrap and regression validation

The capability package is validated in CI against a clean user profile rather than assuming pre-existing state. The current validation baseline installs and exercises Claude Code 2.1.239 and Codex CLI 0.149.0, verifies both clients can discover the intended skills/MCP registrations, smoke-tests CollectUI over MCP, installs `scrolly-video@0.0.24` in a clean temporary npm project, and confirms the official remote MCP endpoints are reachable. Authentication-dependent live calls remain separate owner/secret-bound checks.

## Failure and fallback

- **Refero authentication/subscription unavailable** → continue with its local skill guidance; use CollectUI sandbox or ordinary web research only when design evidence remains necessary.
- **21st authentication/credits unavailable** → use free metadata search if available; otherwise implement from the repository's existing component system. Never block a normal frontend task on 21st.
- **CollectUI sandbox unavailable** → omit/skip it. Do not run the community package unsandboxed merely to satisfy availability.
- **ScrollyVideo fails browser/performance validation** → fall back to native video with a simpler scroll controller, image-sequence/canvas only if justified, or a non-scrub motion treatment.

## Owner escalation boundary

Owner action is required only for:

- obtaining/exporting `API_KEY_21ST` if not already available;
- completing 21st account/API-key creation if no key exists;
- completing Refero OAuth and/or enabling a paid plan that grants MCP access;
- installing/authorizing Docker or Podman if the target host has no approved container runtime and CollectUI is required;
- granting an execution path to a persistent development host when the current agent session has no terminal/SSH/self-hosted-runner access.

Everything else in this standard is agent-operable and should not be escalated.
