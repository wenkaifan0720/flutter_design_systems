## 0.1.0

First release of Comic: a Flutter design system that draws an app as a page of a printed comic.

- Five print editions (offset, reprint, newsstand, pulp, sunday), each with a day and a night issue, and
  `ComicThemeData.from` for an edition in your own colours. `ComicTheme` installs under MaterialApp, CupertinoApp or
  WidgetsApp; `AnimatedComicTheme` moves between themes.
- Everyday parts: `ComicButton` (outlined, `.filled`, `.text`, and `isDestructiveAction` on each), icon and send
  buttons, links, text fields, text areas, search, one-time codes, selects, comboboxes, checkboxes, radios, switches,
  sliders, segmented buttons, chips (`ComicChip.filter`, removable with `onDeleted`), steppers, date and time pickers,
  file upload.
- Pages and navigation: scaffold, app bar, navigation bar, rail and drawer, tabs, breadcrumbs, pagination, carousel.
- Lists and containers: list sections and tiles, switch and check rows, cards, panels in tiers, data tables,
  disclosure groups.
- Raised surfaces: dialogs, bottom sheets, action sheets, menus, popovers, tooltips, snack bars and toasts, each with a
  `showComic...` function that handles focus, dismissal and Escape.
- Status and data: badges, tags, avatars and avatar groups, progress, skeletons, empty, loading and error states,
  ratings; line, area and bar charts (`ComicChartType`), pie charts, sparklines.
- Comic's own: speech and thought balloons, captions, the burst, sound effects, Ben-Day dots, covers and splashes.
- Every change of a part's state animates in Comic's motion (a quick cut, a short pop): presses sink onto their print,
  fills, rims and words move to their new state, the focus ring inks in, and day turns to night. Reduced motion
  switches at once.
- Per-state styles (`ComicStyle`) for every part, above its component theme.
- Flutter's conventions: `value` and `onChanged` on every control (a null callback disables it), an optional
  `focusNode` and `autofocus` on every part with one focus target, an optional `controller` on every field, and
  Flutter's names (`initialValue`, `maxLines`, `firstDate`, `destinations`, `isError`, `waitDuration`).
- Keyboard focus and activation, screen-reader labels, roles and states, 48 by 48 touch targets, text scaling,
  right-to-left layouts and English words through `ComicLocalizations`.
- Bundled Bangers and Shantell Sans; `ComicGlyphs` on Lucide icons.
- `comic_parts.dart`: the tokens, painters and helpers the parts are built from, for copying a part into your app.
