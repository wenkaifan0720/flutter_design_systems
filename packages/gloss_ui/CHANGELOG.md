## 0.1.2

- A stepper's pearl beads stand as tall as its readout (40 px beads beside a 48 px readout before), and both grow with the text, so its words stay whole in the window at 200% and 300%.
- Keyboard focus is a soft halo of jade round the glazed part, as Aqua's was, in place of a ring standing 2 px off it: a band of light against the part's edge that fades into a glow, and the part's highlight brightens. A part with no room round it (a list row, a menu's, a select's or a combobox's row, a position in a slot or a bank, a card's frame) glows inward from its own edge (in white on a chosen segment's jade, where jade would not show); a text button or a link, with no glaze, lights a faint plate just beyond its words. The band reads at 3:1 or more against the part unfocused over a 2 px perimeter, by day and night: by day the focus jade is deeper (`0xFF0C7A54`, 4.4:1 on the page), and `GlossThemeData.from` keeps a brand's at 4:1. `paintGlossHalo` and `GlossFocusHalo` (with an optional `color`) give a part of one's own the same light. `GlossMetrics.focusWidth` is the band's width (3), `focusReach` the glow's (6); `focusGap` is deprecated.
- A form field holding a group of controls (a row, column or wrap of them, a segmented choice, a stepper, a toggle group, a range slider, a tag input, a time picker) keeps each control's own node and tap, and its label names the group. Before, with semantics on (a screen reader, or a browser that turned them on), a tap on any of them went to the first. `GlossFormField.mergeSemantics` is now null by default and decides by the child; true and false still force it.

## 0.1.1

- Date and date-range panels scroll on short screens. Calendar dates, weekday labels, and the month heading follow the system text size.
- Line, area, and bar charts scale their axis labels. The plot makes room for larger text and skips labels that would overlap.
- The pie chart places its legend below the ring when labels need more width. Long entries wrap so their amounts remain visible. In the gallery, the inline sparkline and its total stay together when the caption wraps.
- The range slider's track meets both handles at the minimum and maximum. The colored interval follows the handle positions in both reading directions.
- At large text sizes, list rows measure their trailing control. The filter switches stay aligned and a servings stepper leaves room for its label.
- Simmer keeps the same weekly plan on Today, in the planner and in recipe details. Adding a dinner or clearing the week can be undone.
- Simmer builds its shopping list from the week's dinners and household size. Checked items and handwritten extras carry over when the list is rebuilt.
- Recipe tags grow with their text, the account address has room to wrap, and search keeps durations and quoted queries readable in right-to-left layouts.

## 0.1.0

- Added glazed buttons, fields, selection controls, calendars, lists, and charts, with light and dark themes, three densities, and a custom brand palette.
- Added `GlossHost`, `GlossScreen`, and `GlossScaffold` for app setup and layout. `GlossAppShell` adapts navigation to the window width.
- Added dialogs, sheets, menus, toasts, tooltips, and `glossPageTransitions` for navigation.
- Integrated keyboard navigation, screen reader labels, and reduced-motion behavior through `ui_core` 0.3.0.
- Added localized plural selection through `glossPlural` and `glossPluralCategory`. Searchable fields support asynchronous results, retries, and debouncing.
