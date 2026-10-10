# lib/ui

- Follow `new-implementation.md` for target layouts: clean slate/teal; Today leads with countdown, three feeling items, and direct response cues. Keep paragraphs/details behind disclosure.
- Navigation is the implemented four tabs — Today / Calendar / Learn / Settings; Garden lives in Learn and Support is a route opened from Today, not a tab. The former five-tab instruction was stale and is resolved in favour of the approved plan navigation.
- Feeling entry/editing belongs to a selected Calendar date. Support searchable multiple selections/custom feelings; rank for that date, never preselect inferred feelings.
- History is reached from Calendar. Show explicit historical provenance; Show others rotates only general items. Keep actual logs distinguishable from possibilities.
- Preserve labeled phase/traffic hex indicators, EN/PT locale-aware dates, reduced motion, and large-text reflow. Update both ARBs for copy; generated localization is not hand-edited.
- Preserve Tomorrow's read-only support/reminder behavior and `PhaseCatalog.pick` selection. Keep due reminders and empty/error states usable when simplifying Today.
- Validate rendered phone layouts; source inspection alone is not visual approval. Micro-lessons use short cards, optional questions, and explicit completion.
