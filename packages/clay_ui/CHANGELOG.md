## 0.1.1

- Charts in clay. The donut is made of pieces of pastel clay: a small gap of the ground between slices instead of a white stroke, ends rounded with continuous corners, a soft light inside each piece's top-leading edge and a shade inside its bottom-trailing edge, one soft shadow straight down in its own hue, and a hole pressed into the ground that holds the total. Each piece's area is exactly its share of the clay, so the gaps and round ends never change how big a share looks; a piece too small to round keeps square ends. When a value changes the pieces spring to their new shares without a jump, and the picked piece rises.
- Every series weighs the same. By day the first is the accent itself, and each other slice, bar and line takes its pastel's hue at the accent's lightness and strength, so no series looks more important and each is told by its hue; legends, labels and values carry the data. By night the accent leads and chalky pastels follow (`claySliceColor`, `claySeriesColor`). A line, its area and its legend's ball share one colour.
- An area lies under its line as a slab of pastel clay with rounded feet; lines and sparklines are coils lit along their top and shaded along their foot; a picked bar's band dents the ground as a well.
- Progress rings: the band is clay, lit and shaded as every part is, its round ends standing exactly at 0 and at its value, closing into a whole ring at 100%.

## 0.1.0

- First release. Clay's theme: a palette designed by day and by night, the Rubik type scale, spacing on a 4 pt grid, rounded shapes, calm spring motion and a density setting; `ClayThemeData.from` builds a brand's theme from one accent, keeping its words readable.
- The clay material: soft volumes with cached light and shade, wells pressed into the ground, a press that squashes a part into it, and a focus rim in the part's own shape. Every part takes a `style:` and has a slot in the theme.
- Actions and choices: keys, icon balls, links, button, toggle and split groups, checkboxes, radios and a radio group, switches, segmented buttons, chips, sliders and a range slider, ratings, and a file drop.
- Fields: text, password, search, number, code and grouped fields, a note with its count, selects, a combobox and a tag field; a field's label, help, error and count stand on the line its words start on.
- Pickers: a calendar, date and date-range fields, wheels, a time field and a colour picker.
- Navigation: the top bar, a floating dock, a rail and a sidebar under one adaptive scaffold, tabs, breadcrumbs, pagination, page dots, step progress, a menu bar and a command palette.
- Content: slabs of rows, cards, section heads, description lists, tables and a data table, timelines, avatars and their group, badges, tags, media, a carousel, disclosures, a tree, split panes, and reorderable, swipeable and refreshable lists.
- Over a page: dialogs, bottom, side and action sheets, menus, popovers, hover cards, tooltips, toasts and banners.
- Feedback: progress bars and rings, a spinner, skeletons, meters and state views (empty, loading, error, done).
- Charts: line, area, bar and pie charts and sparklines, their bars moulded in clay.
- An app frame: `ClayHost` over the navigator, `ClayScreen` round each page, `ClayPage` and `ClaySheetPage` for the routes, `ClayAppShell` with `ClayTab`s and one `ClayShellAction`, `ClayPreview`, `ClayLoadingState`, `ClayErrorState` and `ClayInput`.
- Keyboard and screen reader: radio groups, segmented buttons and one-choice toggle groups take one Tab stop and choose with the arrows, on ui_core's `DesignRadioGroup`; a radio keeps the focus node its caller gives it; checkboxes, radios, switches and rows that are one (`ClayListTile.checked`, `toggled`) say what they are and their state, never a button.
- Large text and right to left: rows keep their title's line and move a wide part under it, segments show their words alone, and every part mirrors.
- Page transitions with the iOS swipe back; plurals in the reader's language with `clayPlural`.
