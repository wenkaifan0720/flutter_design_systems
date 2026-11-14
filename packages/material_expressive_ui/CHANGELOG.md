## 0.1.0

First release: an independent Flutter implementation of Material 3 Expressive, ported from Jetpack Compose
`material3` 1.5.0-alpha29 and held to Compose's own renders. Not affiliated with or endorsed by Google.

- Material's names and Flutter's words. Components are named as Material names them (`ExpressiveButton`,
  `ExpressiveTextField`, `ExpressiveNavigationBar`, `ExpressiveSnackBar`, `ExpressiveLinearProgressIndicator`, ...)
  and take the parameters a Flutter developer expects: `onPressed`, `value`/`onChanged`, `selectedIndex`/
  `onDestinationSelected` over `destinations`, a button's `child`, a list tile's `onTap` and `tileColor`, `hintText`,
  `helperText`, `obscureText`, `title`/`subtitle`, `currentDate`. A part without its handler is disabled, as in
  Flutter, with no separate `enabled` flag; every interactive part takes `focusNode` and `autofocus`. Every public
  member has a dartdoc.
- `ExpressiveTheme` is the whole install, in the `builder:` of a `MaterialApp`, `CupertinoApp` or `WidgetsApp`, an
  `InheritedTheme`. `ExpressiveThemeData` has `of`, `copyWith`, `lerp`, diagnostics and a factory per preset;
  `AnimatedExpressiveTheme` springs from one theme to the next as Compose animates colour.
- Five presets baked from their seeds by material-color-utilities (baseline, slate, bloom, grove, ember), each light
  and dark at standard, medium and high contrast, and `ExpressiveThemeData.from(seed:)` for an app's own colour.
  Success and warning tones (`theme.status`), harmonised to each preset's seed, on `ExpressiveBanner` and
  `ExpressiveTag`.
- Component themes with Flutter's slots: `ExpressiveComponentThemeData` holds `backgroundColor`, `foregroundColor`,
  `outline`, `overlayColor`, `side`, `shape`, `padding`, `minimumSize`, `textStyle` and `iconSize`, each a
  `WidgetStateProperty`. A `shape` takes any `OutlinedBorder`, the shape library's `ExpressiveMaterialShapeBorder`
  among them, and morphs when it changes. The shape scale, `ExpressiveDensity` (Flutter's steps, adaptive by
  default), the motion scheme and the type families.
- The look in its own material: the thirty-five library shapes for avatars, pictures, indicators and image
  placeholders (an unloaded picture is two seeded library shapes on its tone, not a grey box); charts with
  round-capped 4 dp lines, shape points and a band on the extra-large corner; skeletons on the large corner in
  `secondaryContainer`; the loading indicator's seven shapes; wavy progress; the button group that widens the
  pressed button.
- `ui_core`'s shared inventory: 83 of its 89 rows live, each under the shared name (`Expressive<Stem>`), and
  `expressiveInventory` answers every row. The other six say what Material uses instead: a keyboard key, a command
  palette, a tree view, an action sheet, a hover card and a wheel picker are not Material components (a number
  wheel is `ExpressiveScrollField`, a word wheel the select, an action sheet's rows a bottom sheet's list).
- On `ui_core`'s behaviours, painted in Material's states: `ExpressiveToggleGroup`, `ExpressivePasswordField`,
  `ExpressiveInputGroup`, `ExpressiveFormField`, `ExpressiveMultiSelect`, `ExpressiveMenuBar`,
  `ExpressiveCalendar`, `ExpressiveColorPicker`, `ExpressiveDataTable`, `ExpressiveSheet` (the side sheet),
  `ExpressiveScrollArea` and `ExpressiveResizable`. The data table's state (`DesignTableController`,
  `DesignTableColumn`, ...) comes with the package's one import.
- Drawn whole from Expressive's parts where Material has none: `ExpressiveTimeline`, `ExpressiveDescriptionList`,
  `ExpressiveStatusView`, `ExpressiveLineChart`, `ExpressiveAreaChart`, `ExpressiveBarChart`, `ExpressivePieChart`,
  `ExpressiveSparkline` and `ExpressiveNavigationDrawer`.
- Accessibility: every control has a semantics role and name and takes focus and the keyboard; Material's focus
  ring, concentric with the part's corners (inside parts that sit flush); state layers in the part's own shape;
  every target at least 48 dp (Compose's `minimumInteractiveComponentSize`) with the face at its own size. A
  checkbox, radio or switch without a handler is disabled at full size, as in Flutter's own controls.
- Right to left, large text and other scripts: every part mirrors under a right-to-left `Directionality` (start and
  end, `EdgeInsetsGeometry`), lays out at 200% text, and draws Arabic, Hebrew, Chinese, Japanese, Devanagari and Thai
  in the platform's fallback fonts. Built-in words are English; dates and numbers are English-only in this release.
- Three libraries: `material_expressive_ui.dart` for an app's screens; `material_expressive_host.dart` for its frame
  (`ExpressivePage`, `ExpressiveSheetPage`, `ExpressiveFullScreenDialogPage`, `ExpressiveShellScaffold`, the
  preview frame and the inventory), on any `Navigator` with no router package; `material_expressive_parts.dart`,
  everything the components are drawn with, for a component you copy into your app. The parts library's generated
  token and behaviour classes keep Compose's names (`ButtonSmallTokens`, `AlertDialogBehavior`, ...); everything
  hand-written carries the `Expressive` prefix.
- The words a component says by itself, English built in: the shared ones from `ui_core`'s `DesignLocalizations`
  (translated once for every look by extending `DefaultDesignLocalizations`), the look's own in
  `ExpressiveLocalizations` (its delegate, or `ExpressiveLocalizationsScope` for a subtree); `firstDayOfWeek` starts
  the date pickers' and the calendar's weeks.
- `ExpressiveCombobox` says when nothing matches (`emptyBuilder` for your own words); `ExpressiveMenuNote` is that
  line, for any menu.
- An example app built on the package: an overview, a trip planner (home, a plan form, a shared list, a packing
  checkout and settings) and every exported widget live, its destinations in the navigation rail or the modal
  drawer. Customize re-themes every page.
- Roboto Flex and Jost (SIL OFL 1.1) and a Material Symbols Rounded subset (Apache-2.0) bundled.
