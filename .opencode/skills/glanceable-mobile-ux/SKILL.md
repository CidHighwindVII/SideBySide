---
name: glanceable-mobile-ux
description: Use when designing SideBySide screens, wireframes, interactions, or reviewing rendered layouts for quick-glance usability, accessibility, and minimal text.
---

# Glanceable Mobile UX

Design for a few seconds of scanning, with detail available on demand.
Use `new-implementation.md` and applicable `AGENTS.md` as the design authority.

## Workflow
1. Establish the screen's primary question and one main action from the approved plan.
2. Inspect current routes, data states, localization, and available components.
3. Sketch hierarchy before styling: primary information, supporting cues, then secondary utilities.
4. Use shared slate/teal tokens and clear typographic contrast rather than equally weighted cards everywhere.
5. Specify normal, empty, loading, error, unknown-stage, and large-text behavior.
6. Render at a representative phone size and evaluate the actual result.
7. Record prototype feedback and approval before expanding scope beyond the planned review gate.

## Screen-Specific Checks
- Today leads with the countdown, three short feeling items, and direct response cues.
- Historical provenance is explicit; icons/asterisks alone are insufficient.
- Explanations, calculation details, and research context are disclosed on tap, not paragraphs in the default briefing.
- Calendar feeling selection is searchable, multi-select, editable, and ranked for the selected date.
- Suggested feelings are never preselected. Unknown data is not disguised as an inference.
- Learn offers short lessons and optional deeper reading; Garden belongs there.
- Keep due reminders discoverable and one useful action visually dominant.

## Accessibility and Interaction
- Pair meaningful icons/colors with text; preserve contractual phase/traffic indicators.
- Check contrast, focus/semantics, comfortably sized touch targets, and visible selected states.
- Reflow for large text; allow scrolling rather than clipping to enforce a one-screen target.
- Check PT-PT expansion, keyboard-open search, narrow screens, and dark mode.
- Honor reduced motion and avoid attention-seeking animations or compulsory timed challenges.
- Test sheets with many selections/records; constrain height and make overflow scrollable.

## Deliverable
Provide a compact wireframe or implemented prototype, state/interaction notes, and actual rendered review results.
Do not prescribe new storage, sync, dependencies, or unrelated information architecture without an approved need.
