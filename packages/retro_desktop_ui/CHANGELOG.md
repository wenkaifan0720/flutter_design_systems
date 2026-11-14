## 0.1.0

The first release of Retro Desktop: a pixel-era desktop UI for Flutter.

- **Theme.** `RetroDesktopTheme` and `RetroDesktopThemeData` with five presets (classic, lagoon, berry, marmalade,
  slate), each for day and night, and `RetroDesktopThemeData.from` for a palette from one brand colour. Two
  appearances, `RetroDesktopAppearance.platinum` (the classic Mac, the default) and `RetroDesktopAppearance.chisel`
  (the 95-era PC), each with its own corners, bevels, default button, pressed state, focus mark, title bar, checks,
  select, progress, slider and tabs. Density (`standard`, `comfortable`, `compact`, adapting to the platform when
  unset) and a replaceable typeface. `copyWith`, equality and `lerp`; `AnimatedRetroDesktopTheme`.
- **The era's pictures.** Alerts, banners, snack bars, error states and dialogs given a tone open with the
  period's alert pictures, drawn for this package in whole pixels; the spinner and the loading state show the busy
  pointer, the wristwatch in Platinum and the hourglass in Chisel; skeleton bars are the 50% checkerboard.
- **Styles.** A component theme for each part, set through the theme's `copyWith`, and a `style:` on each widget, both
  `RetroDesktopStyle`: fill, foreground, edge, overlay, side, shape, padding, minimum size, text style and icon size,
  each resolved by widget state.
- **Parts.** One `RetroDesktopButton` (default, destructive and text forms), icon, toggle and split buttons, button
  groups; text field, text area, password, search, number, code and file fields, input group, form field and combobox;
  checkbox, radio, switch, slider, range slider, stepper, segmented control, chips and rating; select, calendar, date
  and time pickers, date range and colour pickers; menu bar, menus, tabs, navigation bar and rail, breadcrumb,
  pagination and steps; lists, tables, data table, tree and reorderable list; cards, media, avatar groups and
  description lists; dialogs, sheets, action sheets, popovers, tooltips and snack bars; progress, banners, empty,
  loading and error states; line, bar, area and pie charts.
- **Built by the look's laws.** A part the period never had is made from its materials, or left out: a reordered row
  is dragged as a dotted outline to an insertion line, and nothing behind a dialog or a sheet is dimmed. Swipe actions,
  pull to refresh, carousels, toasts, hover cards and tag-style multi-select aren't in 0.1.0; the README's "How Retro
  Desktop is built" says what to use instead.
- **The desktop's own.** Windows on a woven desktop, a 12-column tiled desk from 1024 wide and a stack of windows on a
  phone, the menu bar, desktop marks, window shades, pixel art slots, gauges, calendars and figures.
- **Input and accessibility.** Shared keyboard, pointer and semantic activation; visible focus in each appearance;
  48-pixel touch and 44-pixel desktop targets; the user's text scale kept. Changes are instant, as the era's were:
  every timed change takes a `RetroDesktopMotion` duration, all zero by default, and Reduce Motion forces zero.
- **Localizations.** The words every look shares from ui_core's `DesignLocalizations` (translated by extending
  `DefaultDesignLocalizations`); the look's own words, English, from `RetroDesktopLocalizations`; dates and numbers
  through `intl`. Right to left mirrors every part.
- **Fonts.** Jersey 15, Atkinson Hyperlegible Next and Mono and the icon face bundled, loaded with
  `retroDesktopLoadFonts`.
- **Libraries.** `retro_desktop_ui.dart` for apps; `retro_desktop_parts.dart` for a component copied out to change;
  `retro_desktop_host.dart` for an app shell's host layer.
- **Example.** The live gallery: every part, six ordinary applications, the look's own pieces and a Customize panel.
