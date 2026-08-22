---
name: scrollytelling-video
description: Implement or repair experiences where a video's playback position is intentionally controlled by page scroll/progress. Trigger for scroll-scrub video, scroll-controlled playback, video scrollytelling, forward/reverse video seeking tied to scroll, or when an existing scroll-video implementation is janky or unreliable. Do not trigger for ordinary autoplay/background video, static hero media, simple parallax/fades, or animation that does not require video playback to track scroll position.
license: MIT
compatibility: JavaScript/TypeScript web projects; ScrollyVideo.js supports plain JS, React, Vue, Svelte, and Astro.
metadata:
  owner: till-tech-do-us-part
  capability_version: "1.0"
---

# Scroll-controlled video operating procedure

## 1. Confirm the dependency is justified

Use ScrollyVideo.js only when **video time must map to scroll progress**. If the effect can be implemented more simply with CSS scroll-driven animation, GSAP ScrollTrigger, Motion, native `<video>`, or Three.js without scroll-scrubbing a video, prefer the simpler architecture.

Before installing anything, inspect:

- framework and rendering model;
- existing animation/scroll libraries;
- package manager and lockfile;
- current media strategy/CDN;
- reduced-motion handling;
- mobile/browser support expectations.

Avoid multiple independent systems controlling the same scroll progress.

## 2. Install project-locally only when needed

Use the repository's existing package manager:

- pnpm lock/workspace → `pnpm add scrolly-video`
- npm lock → `npm install scrolly-video`
- yarn lock → `yarn add scrolly-video`
- bun lock → `bun add scrolly-video`

Do not globally install the runtime package. Do not change package managers.

## 3. Choose integration mode

ScrollyVideo.js provides integrations for plain JavaScript, React, Vue, Svelte, and Astro.

Default behavior can track scroll automatically. For a project that already has a canonical scroll timeline/controller, disable competing automatic tracking where appropriate and drive progress through the library's manual progress API (`videoPercentage` / `setVideoPercentage`) so one system owns scroll progress.

## 4. Media and performance requirements

- Reserve explicit media dimensions/aspect ratio to prevent layout shift.
- Compress video deliberately and avoid shipping an unnecessarily large source.
- Test seeking performance with the final production encoding, not a placeholder.
- The library documents WebCodecs/canvas, HTML5 playback-rate, and currentTime fallback paths. The currentTime fallback may benefit from keyframe interval 1; treat that as an encoding/performance tradeoff rather than a universal default.
- Do not preload an excessive asset if it materially harms LCP/data usage. Use loading strategy appropriate to where the scene appears in the journey.
- Keep debug logging off in production.

## 5. Accessibility and graceful degradation

Required:

- honor `prefers-reduced-motion`;
- provide a stable non-scrub alternative (representative frame, poster, or simpler non-motion presentation) when motion is reduced or the runtime cannot support the effect;
- keep content/controls semantically reachable around the visual scene;
- never make comprehension depend solely on rapid motion or scrubbing.

The upstream project documents an iOS Low Power Mode limitation. The experience must remain useful when the scroll-video effect does not run.

## 6. Validation matrix

Validate in the actual app:

1. slow forward scroll;
2. rapid forward scroll;
3. reverse scroll;
4. repeated direction changes;
5. resize and orientation change;
6. mobile Safari/iOS behavior;
7. reduced-motion mode;
8. navigation into/out of the page/section;
9. no console errors or runaway listeners;
10. no significant layout shift or unacceptable memory/CPU use.

If the project uses an existing browser/visual QA tool, use it rather than relying on code inspection alone.

## 7. Failure fallback

If ScrollyVideo remains unreliable or too expensive after realistic testing:

1. simplify to native video plus a lightweight progress controller;
2. use a poster/static frame on constrained devices;
3. consider an image-sequence/canvas solution only when the visual requirement justifies the payload and complexity;
4. prefer a simpler motion treatment over a fragile cinematic effect.

Do not keep the library merely because it was initially requested.
