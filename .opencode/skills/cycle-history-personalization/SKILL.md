---
name: cycle-history-personalization
description: Use when implementing or reviewing cycle-stage history grouping, feeling recurrence, similar-position matching, provenance, or deterministic suggestion rotation in SideBySide.
---

# Cycle History Personalization

Produce inspectable local rankings from dated observations, not opaque claims about current feelings.
Read the personalization decisions in `new-implementation.md` and engine/state scoped guidance.

## Workflow
1. Inspect existing observations, date estimates, catalog concepts, and persistence models.
2. Define inputs, matching windows, stage position, recurrence counts, recency weights, and deterministic tie-breaking.
3. Record consequential parameter choices in the plan; do not present product thresholds as clinically validated accuracy.
4. Implement pure functions with injected dates; separate matching from persistence and rendering.
5. Return provenance/explanation data alongside ranking, including the supporting records/cycles.
6. Invalidate results after date corrections, edits/deletions, custom merges, and wipe.

## Matching and Ranking
- Records belong to dates. Derive four-stage display groups without replacing existing phase enums.
- Pre-period records remain within luteal with position context; unknown stage remains unknown.
- Compare similar points within stages, not calendar months or exact elapsed 24-hour blocks.
- Handle irregular cycles and uncertain phase boundaries explicitly; avoid manufactured precision.
- Count distinct cycles; repeated same-cycle logs are not independent recurrence evidence.
- Missing logs are unknown, not absence. Optional intensity cannot turn missing data into a zero score.
- One prior cycle supports Previously logged context; recurrence across two separate cycles supports From history ranking.
- Canonicalize aliases and merged custom terms without deleting dated evidence.

## Today Selection
- Three slots: up to two historical items and at least one reviewed general possibility.
- Fill sparse-history slots with general items; do not force weak history results.
- Deduplicate canonical concepts across slots and explain history with accessible provenance.
- Keep daily ordering stable across rebuilds/restarts.
- Show others changes only general items; persist the day's manual rotation.
- Keep actual current logs distinct from history/general items. LLM summaries are never matching inputs.
- Support recommendations still use existing catalog filtering/priority/feedback pathways.

## Verification
Cover unknown/sparse history, irregular cycles, position boundaries, distinct-cycle thresholds, corrected dates, DST, merges, deletion/wipe, deduplication, and restart/rotation stability.
Assert explainable supporting evidence as well as order. Report rules and limitations, not invented accuracy percentages.
