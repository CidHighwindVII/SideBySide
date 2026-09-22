# Research & Evidence — basis for SPEC v0.9.0

Papers reviewed to decide which utility features SideBySide should add. Each
finding lists the sources, what they say, and the concrete recommendation that
became a decision (D27–D30) in `SPEC-v0.9.0.md`. Numbers are quoted from the
abstracts/full text returned during retrieval.

---

## F1 — Calendar-only methods cannot pinpoint ovulation/period; error scales with variability → **D27**

- **"Can apps and calendar methods predict ovulation with sufficient accuracy?"** (BJOG 2018; PubMed 29749274). 949 volunteers with urinary LH across a full cycle. *Accuracy of ovulation prediction was no better than 21% by the apps*; "it is not possible for calendar/app methods that use cycle-length information alone to accurately predict the day of ovulation."
- **"Period tracker applications: What menstrual cycle information are they giving women?"** (Women's Health 2021). 10 apps × 5 women: of 36 ovulation predictions, only 3 (8%) exact, **67% were 2–9 days early**; apps assume a textbook 28-day / day-14 model.
- **"Oura Ring as a Tool for Ovulation Detection"** (JMIR 2025; e60667). Calendar method **MAE 3.44 days** (regular) rising to **6.63 days for irregular cycles**; physiology method 1.26 d. "calendar method performed significantly worse in participants with irregular cycles."
- **"The diagnostic accuracy of wearable digital technology in detecting the fertility window"** (npj Digital Medicine 2026). Pooled accuracy: wearables 0.88, BBT 0.75, **calendar 0.72** (worst).
- **"Plausibility of Menstrual Cycle Apps Claiming to Support Conception"** (PMC5891577). Calendar-based apps scored **0/30** on a quality rubric; "the utility of this technique is limited."

**Recommendation → D27:** the app's fixed ±2-day bands overstate precision for low-confidence users. Scale band width to confidence (high 2 / medium 3 / low 4) so the displayed uncertainty tracks the real error the literature measures. This is the honesty rule (§3/D19) made quantitative.

---

## F2 — The premenstrual window is ~the final week, not the final 5 days → **D28**

- **"Premenstrual syndrome"** (The Lancet 2008). "Symptoms often worsen substantially **6 days before**, and peak at about **2 days before**, menses start." Anger/irritability start slightly earlier than other symptoms.
- **"Premenstrual Syndrome"** (StatPearls NBK560698, 2023). "Symptoms often worsen a week before and spike two days before menstruation begins."
- **"Premenstrual Disorders"** (StatPearls NBK532307). Symptoms "typically begin **1 to 2 weeks before** menstruation"; DSM-5 timing criterion = "final week before the onset of menses."
- **"Premenstrual Dysphoric Disorder"** (Endotext NBK279045, 2017). Onset "often **7–10 days prior** to menstruation."
- **"Premenstrual syndrome: new insights into etiology"** (Frontiers in Psychiatry 2024). PMS prevalence ~47.8%; PMDD (severe form) ~3–8%.
- **"Are there temporal subtypes of PMDD?"** (PMC8168625, 2021). Trajectory modelling: a majority "premenstrual-week" group plus a smaller "full-luteal" group — i.e. the rough window is *at least* the last week, sometimes longer.

**Recommendation → D28:** widen the PMS phase from the last 5 days to the last **7** days (the "premenstrual week"), so the warning cards and the PMS-start briefing fire ~2 days earlier — exactly when the evidence says irritability/sensitivity begin. Clamp against short-cycle overlap with ovulation.

---

## F3 — Variability (not just absolute length) is the marker and the error driver → **D29**

- **"Oura Ring as a Tool for Ovulation Detection"** (JMIR 2025). Cycle *variability* significantly degraded calendar accuracy (irregular → 6.6 d MAE); the physiology method was robust to it.
- **"Tracking mood symptoms across the menstrual cycle… EMA + HRV"** (BMJ Mental Health 2025; e301674). Uses cycle day −14…+20; **excludes lengths outside 21–35 d** as outside the normal range — the same range the app already nudges on.
- Gynecology norm (echoed across the PMS sources): a cycle is "regular" only if cycle-to-cycle variation is small (~≲ 7–9 d); larger variation warrants evaluation even when each cycle is in the 21–35 d range.

**Recommendation → D29:** the current nudge only catches gaps outside 21–35 d. Add a **variability trigger** (max − min ≥ 9 days over the last ≥ 3 gaps) so an in-range-but-wild pattern is also flagged — in-app only, no notification, no diagnosis.

---

## F4 — Shared awareness of the cyclical pattern is the active ingredient → **D30**

- **Frank et al.** (reported in the couple-CBT RCT below): including the male partner in **monitoring** the woman's premenstrual symptoms gave "significant improvement in relationship functioning and reduction in premenstrual distress compared to a self-monitoring control group"; awareness of the pattern let couples "develop joint strategies… and discuss major issues at times other than the premenstrual phase."
- **"Evaluation of the relative efficacy of couple CBT for Premenstrual Disorders"** (RCT, PMC5395168, 2017). Increased partner understanding/support reported by **84%** in the couple condition vs 39% one-to-one and 19% wait-list; relationship improvement **57%** vs 26% vs 5%.
- **"Impact of women's coping with premenstrual symptoms on dyadic adjustment and perceived social support"** (Akbağ & Güler, 2026). Concludes clinicians should involve "spouses or romantic partners in educational interventions to improve awareness of premenstrual symptoms."
- **"The relationship between partner social support and premenstrual symptoms"** (Schwartz, Drexel, 2001). Women perceiving lower available partner support are "more susceptible to experiencing distressing emotional and physical symptoms" pre- and post-menstrually.
- **"Empathy, Egalitarianism and Emotion Work in the Relational Negotiation of PMS"** (2008). Awareness/recognition of premenstrual change + responsiveness → open communication and better outcomes.

**Recommendation → D30:** the app already makes *him* a monitor, but never surfaces the **pattern** back to him. Add a read-only view clustering his own observations by derived phase across cycles — operationalising "shared awareness of the pattern" without feeding the engine or making clinical claims.

---

## F5 — Partner support = validate + instrumental, not "fixing" → **catalog validated (no change)**

- **"The Role of Cognitive and Affective Empathy in Spouses' Support Interactions"** (observational, PMC4765893). For **male** providers, situational perspective-taking (empathic accuracy) → **lower negative support** (less unsolicited advice/criticism) and **more instrumental support**.
- **"Men's Perceptions and Attitudes Toward the Partner With PMS"** (2014). Knowledge of the cycle → better understanding and conflict-avoidance; the risk is **medicalizing** PMS and rendering her complaints invisible.
- **"28 days later"** (Psychological Medicine 2025): anger/irritability are the most distressing premenstrual complaints.

**Recommendation:** the catalog's existing items — "validate before fixing", "take on chores unasked", "ask: vent or help?", and the warnings "never say 'it's your hormones' / 'it's PMS'" — already match this evidence. **No content change.** (Also satisfies the §3 honesty + anti-medicalization framing.)

---

## F6 — Mood/energy across the cycle → **axes kept; energy is the softest signal**

- **"Daily, weekly, seasonal and menstrual cycles in women's mood, behaviour and vital signs"** (Nature Human Behaviour 2021; 241 M observations, 3.3 M women). "Mood, vital signs and sexual behaviour vary most substantially over the menstrual cycle, while **sleep and exercise behaviour remain more constant**."
- **"Tracking mood symptoms… EMA"** (BMJ 2025). Mood lowest from **3 d before to 2 d after** menstruation; **energy NOT associated with cycle day**.
- **"28 days later"** (2025): progesterone → less energy / lower happiness / worse sleep in luteal; OC users show flattened variability.
- **"Comparison of affect changes during the ovulatory phase"** (Heliyon 2016): positive affect highest periovulation in naturally-cycling women.
- **"Moods in everyday situations"** (Davydov et al.): follicular/luteal per se don't *determine* mood — they modulate arousal reactivity.

**Recommendation:** the phase→status `axes` map (green follicular/ovulation, yellow luteal, red menstrual/PMS) is directionally consistent with the mood data — **keep it**. `energy` is the weakest-evidenced axis (already in-app-only, never on the lock screen), so it stays soft and is **not** expanded. No new energy feature.

---

## Guardrails — what the evidence says NOT to build
- **Fertile-window / ovulation-day precision:** F1 shows calendar data can't do it, and it collides with D14 (zero pregnancy wording) + §3. Ovulation stays a mood anchor only.
- **ML / personalization / retraining:** not supported by any finding as a utility need; fixed rule engine stands.
- **Severity/PMDD screening:** F2/F5 flag PMDD but diagnosis needs prospective clinical charting; the app's §3 "no medical advice" boundary holds. The D29 nudge stays a gentle, non-diagnostic prompt.

---

## Full source list (as retrieved)
1. BJOG 2018 — https://pubmed.ncbi.nlm.nih.gov/29749274/
2. Women's Health 2021, period-tracker apps — https://sage.cnpereading.com/doi/10.1177/17455065211049905
3. JMIR 2025, Oura ovulation detection — https://www.jmir.org/2025/1/e60667/PDF
4. npj Digital Medicine 2026, wearable accuracy NMA — https://www.nature.com/articles/s41746-025-02320-8
5. PMC5891577, plausibility of conception apps — https://pmc.ncbi.nlm.nih.gov/articles/PMC5891577/
6. Reprod Biol Endocrinol 2022, BBT+HR ML — https://link.springer.com/article/10.1186/s12958-022-00993-4
7. Lancet 2008, Premenstrual syndrome — https://www.thelancet.com/journals/lancet/article/PIIS0140-6736(08)60527-9/fulltext
8. PMC8168625 2021, temporal subtypes of PMDD — https://pmc.ncbi.nlm.nih.gov/articles/PMC8168625/
9. Endotext NBK279045 2017, PMDD — https://www.ncbi.nlm.nih.gov/books/NBK279045/
10. StatPearls NBK532307, Premenstrual Disorders — https://www.ncbi.nlm.nih.gov/books/NBK532307/
11. Frontiers in Psychiatry 2024, PMS new insights — https://www.frontiersin.org/journals/psychiatry/articles/10.3389/fpsyt.2024.1363875/full
12. StatPearls NBK560698 2023, Premenstrual Syndrome — https://www.ncbi.nlm.nih.gov/books/NBK560698/
13. Psychological Medicine 2025, "28 days later" — https://www.cambridge.org/core/journals/psychological-medicine/article/19A3FE300575FB7D86414DEA0C34629E
14. Davydov et al., Moods in everyday situations — https://escholarship.org/content/qt7gr0z2xd/qt7gr0z2xd.pdf
15. BMJ Mental Health 2025, EMA + HRV in depression — https://mentalhealth.bmj.com/content/28/1/e301674
16. Nature Human Behaviour 2021, daily/seasonal/menstrual cycles — https://www.nature.com/articles/s41562-020-01046-9
17. Heliyon 2016, affect at ovulation (OC vs natural) — https://www.sciencedirect.com/science/article/pii/S2405844016322794
18. PMC5395168 2017, couple-CBT RCT for PMDs (incl. Frank et al.) — https://pmc.ncbi.nlm.nih.gov/articles/PMC5395168/
19. Drexel 2001 (Schwartz), partner social support & PMS — https://researchdiscovery.drexel.edu/esploro/outputs/doctoral/991021888879704721
20. Akbağ & Güler 2026, coping → dyadic adjustment — https://exa.ai/library/publication/wfb2fm26l8q
21. PMC4765893, cognitive/affective empathy in spousal support — https://pmc.ncbi.nlm.nih.gov/articles/PMC4765893/
22. Men's Perceptions of Partner with PMS, 2014 — https://journals.sagepub.com/doi/10.1177/1557988313497050
23. UG 2008, empathy/egalitarianism in lesbian PMS negotiation — https://sage.cnpereading.com/doi/10.1177/0959353507084954
