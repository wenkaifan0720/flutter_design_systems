## 0.1.0

- First release: Appliance's foundations (warm plastic by day and by night, three depths under one light, Barlow,
  the 4 px grid, the lamp, the focus bezel, springs), its keys, fields, select, latching keys, preset keys, slide
  switch, slide selector, stepper, faceplates and rows, top bar, key strip, rail and side panel, dialog, sheet and
  toast, and its page change (`appliancePageTransitions`). Larder, the example shop.
- Built on ui_core 0.3.0 (`ui_core: ^0.3.0`; the review sheets come from `ui_core_test: ^0.1.0`, a dev dependency):
  ui_core's tooltip, context menu, dialog and bottom-sheet routes, tab bar, adaptive shell (from 600 px), rating and
  charts carry the behaviour; Appliance paints them. The dialog rises on a spring and takes `isAlert`; a sheet
  follows a drag down, its grip a handle; the side sheet slides on a spring (`ApplianceMotion.slide`); a search
  says it is looking or that it failed, with a row to try again (`debounceDuration`); `ApplianceKbd.shortcut`
  shows a shortcut in the platform's words. A chart's summary is ui_core's, in its 30 languages.
