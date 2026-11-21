## 0.2.0

- Needs ui_core 0.4.0 and Flutter 3.47. `keycap_ui` re-exports ui_core, whose types now take `Raw` names (`DesignPressable` is `RawButton`). The old names stay through ui_core 0.4 as deprecated typedefs, and `dart fix --apply` renames them.
- `KeycapRadioGroup`, a one-choice `KeycapSegmentedButton` and a one-at-a-time `KeycapToggleGroup` are Flutter's `RadioGroup`, each key a `RawRadio`, with ui_core's `RadioGroupKeyboardFix` inside. They answer Tab and the arrows as before, and a row that may be left empty still lets its chosen key up on a press. A radio shows its focus and its press as Flutter's `Radio` does, and on iOS and macOS a key also reads as selected.
- `KeycapTooltip` is Flutter's `RawTooltip`, with ui_core's `RawTooltipFocusFix` and `RawTooltipPlacement`. It fades on Flutter's tooltip timing, and each tooltip along a row of keys waits its half second.
- A latching `KeycapIconButton`, a selectable `KeycapChip` and a password field's reveal key read as buttons, selected while on, as `IconButton(isSelected:)` does. Before, they read as switches.

## 0.1.0

- First release: controls as keycaps on a mechanical keyboard, in day and night colourways on Rubik. Keys you press
  are sculpted caps that travel when pressed; what you read sits in wells cut into the case, and large reading and
  writing areas are light pages; menus, dialogs and sheets are flat panels laid over the keyboard.
- Keys: alpha, modifier and accent keys, printed and square keys, latching keys, two-legend keys, keyboard
  shortcuts, split buttons, toggle groups and toolbars.
- Fields: text fields, search, password, input groups with add-ons, one-time codes, number steppers, selects,
  comboboxes, tag inputs, chips, a colour picker and a drop zone.
- Choices: checkboxes, radios, switches and switch rows, segmented buttons and tab bars, whose legends reflow rather
  than cut short.
- Dates and values: a calendar, date, range and time pickers, sliders, range sliders, ratings and wheel pickers.
- Lists and layout: list groups and rows, cards, tables and data tables, trees, timelines, disclosures, carousels,
  reorderable lists, swipe actions, pull to refresh, split views and scroll areas.
- Navigation: the top bar, the phone's bar, the tablet's rail and the desktop's side column, breadcrumbs,
  pagination, step progress and page dots.
- Overlays and feedback: dialogs, bottom and side sheets, menus, context menus, a menu bar, a command palette,
  popovers, hover cards, tooltips, toasts, banners, progress bars, spinners, meters, skeletons, empty and status
  views; avatars, badges, tags, media, description lists and charts (line, area, bar, donut, sparkline).
- Ready for the world: right to left, text at 200%, a screen reader and the keyboard; calm motion that respects
  Reduce Motion. Checkboxes, radios and switches read as Flutter's do, not as buttons. A radio group, a one-choice
  segmented button and a one-at-a-time toggle group are each one Tab stop, at the choice; the arrows choose the next
  or the previous option, wrap, pass over options that are off and run the other way right to left, as Flutter's
  `RadioGroup` does.
- Requires ui_core 0.3.4.
