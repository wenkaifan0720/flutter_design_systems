## 0.1.0

First release: an independent Flutter implementation of Fluent 2, not affiliated with or endorsed by Microsoft.

- **Theme.** `Fluent2Theme` and `Fluent2ThemeData` with Fluent's alias tokens by their spec names (from
  `@fluentui/tokens` 1.0.0-alpha.24, MIT), the shared palette, the brand ramp, the type ramp, acrylic and shadows;
  `AnimatedFluent2Theme`; `Fluent2ThemeData.from(brand:)` for your own brand colour, held to 4.5:1 for words and 3:1
  for edges; a density (`standard`, `comfortable`, `compact`) and a typeface setting; a component theme per part
  (`Fluent2Style`).
- **Seven presets**, each in light and dark: `lapis` (Fluent's web blue, the default), `iris`, `juniper`, `clover`,
  `pumpkin`, `berry` and `flint`.
- **Components** on Fluent's measures: buttons (with split, toggle and compound buttons and menu buttons), links,
  text fields, text areas, password and search boxes, spin buttons, selects, comboboxes, tag groups, check boxes,
  radios, switches, sliders and range sliders, segmented buttons, ratings, file drop zones, date and time pickers, a
  calendar and a week strip, cards, list items and grouped lists, a tree, a data grid, tabs (`Fluent2TabList`),
  breadcrumbs, a toolbar, an accordion, avatars and persona rows, badges and presence, tags and interaction tags,
  message bars, toasts, tooltips, popovers, menus, dialogs, sheets and drawers, a spinner, progress and segment bars,
  skeletons, stats, charts, a carousel, resizable panes, swipe actions, pull to refresh, an activity feed and empty,
  error and success states. Parts Fluent never drew are built from its own laws (the README's "How Fluent 2 is
  built").
- **Navigation and pages**: a scaffold and top bar, a phone tab bar and a desktop navigation pane.
- **Motion**: every change of state eases the part's whole face (fills, strokes, inks, a card's shadow) over Fluent's
  durations and curves, turning mid-way without a jump; day to night eases every token; `Fluent2Eased` for your own
  parts. Reduce Motion cuts.
- **Accessibility**: Fluent's two-tone focus ring, screen-reader names and values on every control, 44 and 48 px touch
  targets, right-to-left layouts, text scaling to 2.0 and Reduce Motion.
- **Fonts and glyphs**, bundled: Selawik (SIL OFL 1.1) as the text face and a subset of Fluent UI System Icons (MIT).
- **Example**: the gallery, every component on its page in every preset, light and dark, with a sample app's screens.
