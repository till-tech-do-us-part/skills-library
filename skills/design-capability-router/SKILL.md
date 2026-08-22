---
name: design-capability-router
description: Route frontend, product-design, UX, visual-reference, component, animation, and scroll-video work to the right durable capability. Use implicitly when a development task involves choosing or improving UI/UX patterns, researching how strong products solve an interface problem, finding reusable React/shadcn components, generating interface code, gathering design inspiration, or implementing scroll-controlled video. Do not trigger for backend-only work, routine non-visual bug fixes, or tasks whose UI design and implementation are already fully specified and require no design judgment.
license: MIT
compatibility: Claude Code and Codex; expects Refero/21st MCPs when authenticated, optional sandboxed CollectUI MCP, and repository-local package tooling.
metadata:
  owner: till-tech-do-us-part
  capability_version: "1.0"
---

# Design capability routing

Select capabilities from **intent and conditions**, not from whether the user names a tool.

## First inspect the repository

Before external design/component lookup:

1. Read the repository's agent instructions, design-system rules, component library, package manager, framework, and relevant existing code.
2. Reuse a suitable existing local component or established pattern when it already solves the problem well.
3. Identify constraints that external references must respect: accessibility, responsive behavior, tokens, dark mode, animation stack, server/client boundaries, bundle budget, and testing requirements.

External tools accelerate judgment; they do not override repository standards.

## Routing decision

### Use Refero first when the design decision is not yet settled

Invoke Refero research when the task needs evidence about:

- page or screen structure;
- navigation/information architecture;
- onboarding, checkout, settings, pricing, dashboard, table, form, or other interaction patterns;
- multi-step user flows;
- visual style/taste where several credible directions should be compared;
- redesign work where a current UI is weak, generic, inconsistent, or ambiguous.

Research sequence:

1. **Styles** for visual direction/taste.
2. **Screens** for concrete UI patterns.
3. **Flows** for multi-step journeys.
4. Synthesize patterns across references and lock a direction before implementation.

Do not copy one product verbatim. Use references as evidence, then adapt to this product.

### Use 21st.dev when implementation can benefit from reusable UI code

Invoke 21st after the intended direction is understood, or immediately when the task is a narrow component need with no unresolved UX decision.

Use it to:

- search for React/shadcn components, themes, and templates;
- compare implementation candidates;
- install/adapt a component;
- generate or iterate UI when that is faster than hand-authoring and the output can be reviewed as normal application code.

Before installing:

- prefer an adequate local component;
- verify framework compatibility;
- state important constraints in the search/generation request;
- compare material alternatives rather than taking the first result.

After installing/generated code:

- adapt to local tokens and conventions;
- remove unnecessary dependencies/complexity;
- validate semantics, keyboard behavior, reduced motion, responsiveness, dark mode if applicable, lint, types, tests, and bundle/performance impact.

### Use CollectUI only as a secondary inspiration source

CollectUI is served through a community MCP integration, not an established first-party integration.

Use it only when broad inspiration is useful and:

- Refero is unavailable, exhausted, or insufficient; or
- a lightweight category sweep would materially improve ideation.

Constraints:

- invoke only through the configured sandboxed `collectui` MCP;
- do not grant it repository/home mounts or credentials;
- treat results as inspiration, not authoritative UX evidence;
- do not block development if it is unavailable.

### Use ScrollyVideo only for actual scroll-synchronized video

If the requirement is video whose playback position tracks scroll progress, invoke the `scrollytelling-video` skill.

Do **not** reach for ScrollyVideo for generic hero animation, parallax, fades, autoplay video, or ordinary timeline animation. Prefer simpler CSS/native video/GSAP/Motion/Three.js techniques when they solve the requirement with lower runtime cost.

## Combined workflow

For substantial new frontend/product work, the preferred sequence is:

**repository audit → Refero evidence → direction lock → 21st component/code search → local implementation/adaptation → browser/visual/accessibility/performance validation**.

CollectUI may supplement the evidence stage. ScrollyVideo may enter only at implementation when scroll-controlled video is genuinely required.

## Failure policy

- Refero unavailable/auth blocked: continue with local skill guidance and existing repository evidence; optionally use sandboxed CollectUI or normal web research.
- 21st unavailable/auth/credits blocked: implement from the local component system; never stall a normal UI task.
- CollectUI unavailable: skip it; never downgrade to unsafe unsandboxed execution.
- ScrollyVideo unsuitable after testing: simplify the experience rather than forcing the dependency.

## Completion standard

Using an external design capability is not completion. The implemented result must still satisfy the active repository's quality gates and be verified in the actual application/runtime.
