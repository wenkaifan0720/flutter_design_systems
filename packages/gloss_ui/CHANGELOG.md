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
