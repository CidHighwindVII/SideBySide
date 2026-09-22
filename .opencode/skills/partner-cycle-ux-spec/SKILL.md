---
name: partner-cycle-ux-spec
description: >
  Senior Mobile Product Designer & UX Architect specialising in Flutter.
  Produces a comprehensive UX/UI design specification and wireframe structure
  for the Flutter-based menstrual cycle tracking app designed for men to
  follow and support their partner's cycle. Use when the user asks for the
  UX/UI design spec, wireframes, screen specs, action-card matrix, IA map, or
  state/storage architecture for the partner cycle app.
---

# Partner Cycle App — UX/UI Design Spec

Role: Senior Mobile Product Designer & UX Architect specialising in Flutter.

Task: Create a comprehensive UX/UI design specification and wireframe
structure for a Flutter-based menstrual cycle tracking app designed
specifically for men to follow and support their partner's cycle.

## Target Audience & Tone

- Audience: Men in committed relationships.
- UX Goal: Provide context, actionable insights, timing awareness, and
  proactive recommendations rather than raw medical data or manual symptom
  logging.
- Tone & Aesthetic: Gender-neutral, calm, supportive, and modern. Avoid
  hyper-feminine pink aesthetics and aggressive "bro-tech" dark modes. Use
  soft teals, warm sage, and neutral tones.

## Functional & Technical Requirements

1. Core Views & Architecture:
   - Home Dashboard: define the central visual element (e.g., segmented
     circular cycle ring using Flutter `CustomPainter`) showing current cycle
     phase (Menstrual, Follicular, Ovulating, Luteal/PMS) and day.
   - Action Cards ("How to Support Today"): contextual advice cards based on
     the active phase (energy levels, suggested social/outdoor activities,
     chores to take over, dietary/snack suggestions).
   - Preparation & Calendar View: using `table_calendar` to display predicted
     period dates, fertile windows, and key milestones.
   - Notification System: triggers for actionable prep (e.g., "3 days before
     period: check supplies", "Fertile window starting").
2. Technical & Privacy Constraints:
   - State management approach using Flutter (e.g., Riverpod/Bloc).
   - End-to-end privacy and security architecture (`flutter_secure_storage`,
     local-first storage with Hive/Isar, row-level security for partner sync).

## Required Output Structure

Produce the design spec with exactly these sections:

1. User Persona & Information Architecture (IA) map.
2. Screen-by-Screen UX Specification — components, Flutter widgets to use,
   and layout wireframes in ASCII or structured Markdown.
3. Contextual Action Matrix — Phase → Partner Experience → Recommended UI
   Card.
4. Flutter State Management & Local Storage Implementation Architecture.
