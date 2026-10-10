# SideBySide — business development draft (internal GTM)

Status: working draft, v0.1.0 product baseline. Not a commitment; assumptions
flagged inline. Current code and `plans/` outrank this document for product
facts.

## 1. Product snapshot

Flutter Android app, PT-PT source / EN fallback. Today, Calendar, Suggestions,
Definitions, Garden rewards, local reminders, neutral widget. No account, no
cloud sync, single local JSON file; lock-screen notifications reveal no cycle
detail.

## 2. Positioning

One-liner: a private companion that helps a partner with her cycle

Differentiators:
- Privacy architecture: offline-only by design, not by policy promise.
- Honest uncertainty: confidence bands, no precision theatre.

## 3. Competitive landscape

| Product | Model | Weakness vs SideBySide |
| --- | --- | --- |
| Flo for Partners | Free, cloud account, brand-led | Requires sync/account; prescriptive phase content |
| Clue | Freemium, cloud, inclusive framing | Built for the tracker, not the supporting partner |
| Natural Cycles | Subscription, FDA-cleared contraception | Medical positioning, heavy data collection |

Open gap: a male-partner, offline, non-prescriptive companion. Gap may exist
because it is hard to monetise trust-based privacy claims — see §4.

## 4. Monetization

Constraints: ads and data monetization are ruled out; they break the core
positioning and the local-only architecture.

Options:
1. **Recommended:** free core + one-time premium unlock (extra catalog depth,
   learning content, calendar export polish). Matches a trust-first product;
   one payment, no recurring data relationship.
2. Subscription later — only if ongoing content (learning cards, expert
   reviews) justifies recurrence.
3. Paid download — cleanest privacy story, but kills acquisition in a
   category trained on free.

Open question: is a partner-support niche large enough to support any paid
model? Unvalidated.

## 5. Go-to-market channels

- Google Play PT-first launch; ASO on queries like "Help with partner cycle",
  "App to support with mentration cycle" (low competition, untested volume).
- Content marketing: practical "how to support your partner" articles in PT,
  honest about estimation limits; the evidence notes in the app are the
  content moat.
- Communities: men's wellbeing forums/subreddits; frame as support tooling,
  never as "track her".
- No loops requiring partner install, sync, or shared accounts.

## 6. Partnerships

Candidates: relationship/family educators, men's wellbeing charities, PT
women's-health professionals as content reviewers (credibility, not
endorsement of efficacy).

Guardrails: co-marketing must never imply tracking without consent, clinical
benefit, or partner-side data. A partner-visible consent story (she can see
what is logged; deletion is easy) is a precondition for any partnership.

## 7. Risks and open questions

- Consent optics: an app about another person's body invites "creepy"
  backlash; mitigation is the ask-first copy and zero-partner-data design,
  but it is untested with real users.
- Regulatory: GDPR (PT/EU market) and Google Play Data Safety declarations —
  low risk by architecture, but declarations must be accurate.
- Product gaps before GTM: pending device/accessibility verification;
- Market size: male-partner cycle-support niche is unproven; validate
  acceptability (§ plans Phase 3) before spending on acquisition.

## 8. Next steps

1. Complete Phase 3 verification and user acceptability testing.
2. Run 10–15 user interviews (PT) on willingness-to-pay for the premium
   unlock hypothesis.
3. Draft Play Store listing copy within the no-claims guardrails.
