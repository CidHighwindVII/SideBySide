# Research & Evidence — planning and content basis

Sources reviewed for `new-implementation.md` content decisions. The earlier
version of this file summarized papers against a deleted specification
(`SPEC-v0.9.0.md`) and quoted some venue labels from retrieval metadata without
verification; those references are historical and must not be treated as
implemented claims. Current code and the phase record in
`new-implementation.md` define actual behaviour.

**Verification pass (2026-10-11).** The sources that directly anchor published
app content were re-fetched and checked; the rest are marked with their status.
Numbers below come from the abstracts/results sections of the retrieved pages.
Study findings are associations or trial outcomes in specific populations —
never individual predictions, and never clinical guidance.

---

## Verified this pass

### V1 — Johnson, Marriott & Zinaman (2018). "Can apps and calendar methods predict ovulation with accuracy?"
*Current Medical Research & Opinion* 34(9):1587–1594. DOI 10.1080/03007995.2018.1475348.
Earlier notes in this file mislabelled the venue as BJOG; corrected here.
https://pubmed.ncbi.nlm.nih.gov/29749274/

- **Population:** 949 volunteers (768 analysed) aged ≥18, seeking to conceive,
  self-reported cycles 23–35 days; cycles outside that range were excluded —
  so results do not characterise very short or long cycles.
- **Findings:** for a 28-day cycle the most likely ovulation day was day 16
  (21% probability); app day-prediction accuracy was "no better than 21%";
  "it is not possible for calendar/app methods that use cycle-length
  information alone to accurately predict the day of ovulation."
- **Limitations:** best-case scoring assumptions; apps' undisclosed methods had
  to be modelled; volunteers were fertile-window-motivated, not representative
  of all users.
- **App content it supports:** uncertainty band widening by confidence
  (`bandDays`); the Calendar ovulation-day marker and its "estimate, not
  confirmed day" detail sheet; lesson `l:ovulation-uncertainty`.

### V2 — Verhofstadt et al. (2016). "The Role of Cognitive and Affective Empathy in Spouses' Support Interactions: An Observational Study"
*PLoS ONE* 11(2): e0149944. PMC4765893.
https://pmc.ncbi.nlm.nih.gov/articles/PMC4765893/

- **Population:** 45 committed heterosexual couples (50 recruited) living
  together ≥6 months; lab-based observed support conversations, not a
  generalisation to all couples or relationship forms.
- **Findings:** for male providers, higher situational perspective-taking was
  associated with less negative support; across both partners, situational
  perspective-taking correlated with more instrumental support; dispositional
  empathic concern predicted lower negative support.
- **Limitations:** cross-sectional observation; association ≠ causation; coded
  10-minute lab tasks, not daily life; no app involved.
- **App content it supports:** the Support screen's concrete-offer and
  listening-first ordering; lessons `l:listen-dont-fix`,
  `l:comfort-or-space`; warnings in `catalog.json` against unsolicited advice.

### V3 — Ussher & Perz (2017). "Evaluation of the relative efficacy of a couple CBT for Premenstrual Disorders… RCT"
*PLoS ONE* 12(4): e0175068. PMC5395168.
https://pmc.ncbi.nlm.nih.gov/articles/PMC5395168/

- **Population:** 83 women randomised (63 completed) meeting moderate–severe
  PMD criteria — a clinical sample, not the general population.
- **Findings:** both CBT arms reduced premenstrual symptoms/distress vs
  wait-list; the couple arm showed more active behavioural coping; increased
  partner understanding was reported by 84% (couple) vs 39% (one-to-one) vs
  19% (wait-list), relationship improvement by 57% vs 26% vs 5%.
- **Limitations:** attrition and small final sample; partners' own perspectives
  were not assessed; mostly heterosexual couples; therapy effects do not
  transfer to app features.
- **App content it supports:** communication topics (`l:timing-talks`,
  `l:tracking-together`, `l:ask-dont-assume`); the framing that shared
  awareness helps while never claiming the app itself reproduces trial effects.

### V4 — Yonkers, O'Brien & Eriksson (2008). "Premenstrual syndrome" — *The Lancet* 371:1200–1210
https://www.thelancet.com/journals/lancet/article/PIIS0140-6736(08)60527-9/fulltext

- **Findings checked:** symptoms "often worsen substantially 6 days before, and
  peak at about 2 days before, menses start"; anger/irritability are among the
  most severe complaints and start slightly earlier; peak days by factor
  (depressive −2, physical −1, anger −2, cravings −3); 5–8% have moderate–severe
  symptoms; a symptom-free interval before ovulation is part of the definition.
- **App content:** background for the last-7-days product window and lessons
  `l:before-period` / `l:irritability-leads`. Current feeling eligibility is
  explicitly mapped to V9/V10 below; the window is not clinical precision.

### V5 — Withdrawn citation: ovulatory positive affect

The earlier Ocampo/Heliyon citation could not be substantiated in this repair
pass. Europe PMC resolves `10.1016/j.heliyon.2016.e00186` to a reactive-stepping
stroke study (PMID 27861645), not the claimed affect study. The ScienceDirect
PII did not retrieve successfully. The claimed population and findings must
not be reused as verified evidence. `good-mood` remains searchable/loggable,
but has no stage association; `l:positive-window` retains its ID and now teaches
the distinction between population associations and individual expectations.

### V6 — Delray, Lewis & Hayes (2025). "Tracking mood symptoms across the menstrual cycle in women with depression using ecological momentary assessment and heart rate variability" *BMJ Mental Health* 28(1): e301674
https://mentalhealth.bmj.com/content/28/1/e301674

- **Population:** 352 women **with depression** tracked by EMA; the analysed range
  excludes cycles outside ~21–35 days — findings describe that group, not all
  menstruants.
- **Findings used:** mood lowest roughly from ~3 days before to ~2 days after
  menstruation onset; energy was not reliably associated with cycle day; the
  study frames premenstrual *exacerbation* of depression, which this app must
  not present as a diagnosis.
- **App content:** lessons `l:energy-myth` / `l:mood-lowest` now name the clinical
  population. A null energy result in this cohort does not exclude premenstrual
  fatigue elsewhere (the paper explicitly notes fatigue in PMDs). It does not
  override V9's patient information or validate a universal mood window.
- **Rechecked 2026-10-11:** publisher returned 403; full text retrieved from
  https://pmc.ncbi.nlm.nih.gov/articles/PMC12198828/ (DOI `10.1136/bmjment-2025-301674`).

### V7 — Pierson, Althoff, Thomas, Hillard & Leskovec (2021). "Daily, weekly, seasonal and menstrual cycles in women's mood, behaviour and vital signs" *Nature Human Behaviour* 5:716–725
https://www.nature.com/articles/s41562-020-01046-9

- **Population:** 241 million observations from 3.3 million women in 109
  countries, using the Clue women's-health app. Self-tracking, app-user selection
  and reporting effects apply; these are not universal wearable measurements.
- **Findings used:** mood and vital signs varied most across the menstrual
  cycle while sleep and exercise behaviour remained more constant.
- **App content it supports:** sleep treated as weakly stage-linked
  (`l:sleep-steady`), and the general caution in lesson
  `l:estimates-not-facts`.

- **Rechecked 2026-10-11:** publisher abstract, authors/citation and data
  availability retrieved. Subscription full text was not available; do not
  attribute additional detailed effects to this abstract-only inspection.

### V8 — Google ML Kit GenAI Summarization (Android), developer docs, retrieved 2026-10-11
https://developers.google.com/ml-kit/genai/summarization/android

- Beta API; requires Android API ≥26 and AICore/Gemini Nano on supported
  devices; documented language support is English, Japanese and Korean —
  **not Portuguese**. Availability must be checked at runtime; installed
  assistant apps do not imply an accessible model.
- **App impact:** adapter scaffolding only; no provider is bundled, the app
  reports unavailable and there is no cloud fallback or Portuguese promise.

### V9 — NHS, "PMS (premenstrual syndrome)"
https://www.nhs.uk/conditions/pre-menstrual-syndrome/

- **Retrieved 2026-10-11:** patient information; reviewed 18 June 2024. Symptoms
  vary between women and months. Lists mood swings, depressed/irritable or
  anxious/emotional feelings, tiredness/sleep trouble, bloating, breast
  tenderness, skin changes and appetite/cravings before a period.
- **Supports exactly 12 luteal concepts:** tender-breasts, bloating, acne,
  appetite-up, cravings, irritable, mood-swings, anxious, sad, emotional,
  low-energy, slept-badly. Presented only in the estimated pre-period window,
  with limitations/source access. No frequency, individual prediction or
  diagnosis is inferred. Vivid dreams, general pain tolerance and other
  unsubstantiated stage associations were removed.

### V10 — NHS, "Period pain"
https://www.nhs.uk/conditions/period-pain/

- **Retrieved 2026-10-11:** patient information; reviewed 18 March 2026. Describes
  cramps/tummy pain around period onset that may spread to back and thighs.
- **Supports four menstrual concepts:** cramps, backache, pelvic-pain, leg-ache.
  These are tentative possibilities, not proof of symptoms or their cause.
- **Curated everyday fallback:** calm, content, neutral, private, sociable.
  This is editorially selected everyday context, explicitly not an evidenced
  cycle association. Its source panel says so; no paper is claimed to predict it.

## Reviewed earlier at planning time, not re-verified this pass
These informed historical decisions; treat their quoted numbers as planning
memory until someone re-checks them (the file's earlier revision claimed
verification it had not performed):

- "Period tracker applications: What menstrual cycle information are they
  giving women?" *Women's Health* 2021 (10 apps × 5 women; 8% exact ovulation
  matches) — https://sage.cnperereading.com/doi/10.1177/17455065211049905
- "Oura Ring as a Tool for Ovulation Detection" JMIR 2025 e60667 (calendar MAE
  3.44→6.63 days with irregularity).
- "The diagnostic accuracy of wearable digital technology in detecting the
  fertility window" npj Digital Medicine 2026 (pooled calendar 0.72).
- "Plausibility of Menstrual Cycle Apps Claiming to Support Conception"
  PMC5891577.
- "28 days later" Psychological Medicine 2025; StatPearls NBK560698/NBK532307;
  Frontiers in Psychiatry 2024 (PMS ~47.8%, PMDD ~3–8%); PMC8168625;
  Endotext NBK279045; Heliyon/Davydov mood-variability items; Akbağ & Güler
  2026; Schwartz & Drexel 2001; "Men's Perceptions… with PMS" 2014.

## Evidence → content mapping (current)

| Published content | Anchor | Confidence boundary kept |
|---|---|---|
| 16 stage-associated feeling concepts (12 pre-period luteal, four menstrual, none ovulatory/follicular) | V9, V10 | Specific source/limitations metadata; searchable entries are not automatically briefing candidates |
| Fatigue/sleep possibilities before a period; neutral energy forecast axis | V9, V6, V7 | Clinical-cohort null results do not negate symptoms in other groups; no individual energy prediction |
| PMS = final ~7 days | V4 (worsening ~6 days before) | Engine window; clamp keeps PMS after ovulation |
| Confidence-scaled ±2/3/4-day bands, ovulation uncertainty sheet | V1, V7 | Band width is date-uncertainty, not a fertility window |
| Support ordering: concrete offers, listen-first, space respected | V2 | Association evidence, no efficacy claim |
| Couple communication lessons | V3 | Clinical-population trial; never promised as app outcomes |
| Health nudge, PMDD lesson framing | V4 prevalence + V6 population | Suggests a conversation; never diagnoses |
| No Portuguese AI summary claim | V8 | Capability-checked; EN/JA/KO only per docs |

## Guardrails (unchanged)
Calendar-only methods cannot pinpoint ovulation; no pregnancy wording;
recurrence in History is a product threshold, not validated accuracy; lock
screen reveals nothing; research retrieved here is not user-research — the
rendered Support tasks and Today prototype still require real human review.
