# flutter_design_systems

**[Demo site](https://wenkaifan0720.github.io/flutter_design_systems/docs/)**: every component in every look side by side, with Flutter's Material and Cupertino for comparison, and [Stint](https://wenkaifan0720.github.io/flutter_design_systems/docs/stint/), one app built in each look.

Design systems for Flutter, one package per look, all built on one shared foundation, `ui_core`. Every look
works under a `MaterialApp`, a `CupertinoApp` or a `WidgetsApp`, at phone and desktop sizes, by day and by night.

| Package | What it is |
| --- | --- |
| [`ui_core`](packages/ui_core) | Headless behaviours for Flutter design systems: the state, keyboard, focus and semantics of 40 controls, routes and overlays, with every pixel left to the design system. [pub.dev](https://pub.dev/packages/ui_core) |
| [`ui_core_test`](packages/ui_core_test) | Checks for Flutter design systems on ui_core of what is wrong in any design: roles, radio groups, field names, tap targets, cursors, labels, clipped words and cut shadows. [pub.dev](https://pub.dev/packages/ui_core_test) |
| [`appliance_ui`](packages/appliance_ui) | Flutter controls inspired by household appliances, with moulded keys, indicator lights, recessed displays and responsive navigation in light and dark themes. [Docs](https://wenkaifan0720.github.io/flutter_design_systems/docs/looks/appliance/) · [pub.dev](https://pub.dev/packages/appliance_ui) |
| [`brutal_ui`](packages/brutal_ui) | A neo-brutalist Flutter design system: heavy black rules, square corners, a hard shadow under what you can press and one flat colour block a screen. [Docs](https://wenkaifan0720.github.io/flutter_design_systems/docs/looks/brutal/) · [pub.dev](https://pub.dev/packages/brutal_ui) |
| [`civic_ui`](packages/civic_ui) | A Flutter design system for public services: one thing per page, large type, a heavy yellow focus, errors said in words, answers checked before they are sent. [Docs](https://wenkaifan0720.github.io/flutter_design_systems/docs/looks/civic/) · [pub.dev](https://pub.dev/packages/civic_ui) |
| [`clay_ui`](packages/clay_ui) | Claymorphic widgets for Flutter: soft inflated controls, pastel colour, accessible forms, navigation and dialogs in coordinated light and dark themes. [Docs](https://wenkaifan0720.github.io/flutter_design_systems/docs/looks/clay/) · [pub.dev](https://pub.dev/packages/clay_ui) |
| [`comic_ui`](packages/comic_ui) | A Flutter design system drawn as a printed comic page: inked panels, speech balloons and Ben-Day dots in flat inks, every change of state a quick cut or pop. [Docs](https://wenkaifan0720.github.io/flutter_design_systems/docs/looks/comic/) · [pub.dev](https://pub.dev/packages/comic_ui) |
| [`fluent2_design_ui`](packages/fluent2_design_ui) | Fluent 2 widgets and themes for Flutter. Build forms, navigation, data grids and charts with seven light and dark presets, acrylic surfaces and Fluent icons. [Docs](https://wenkaifan0720.github.io/flutter_design_systems/docs/looks/fluent2/) · [pub.dev](https://pub.dev/packages/fluent2_design_ui) |
| [`frosted_ui`](packages/frosted_ui) | Frosted glass for Flutter: panes rimmed with light stand on a canvas lit by soft washes of colour, and one ink act carries each page, by day and by night. [Docs](https://wenkaifan0720.github.io/flutter_design_systems/docs/looks/frosted/) · [pub.dev](https://pub.dev/packages/frosted_ui) |
| [`gloss_ui`](packages/gloss_ui) | Skeuomorphic widgets for Flutter with glazed controls, recessed panels, accessible forms, navigation, and charts in coordinated light and dark themes. [Docs](https://wenkaifan0720.github.io/flutter_design_systems/docs/looks/gloss/) · [pub.dev](https://pub.dev/packages/gloss_ui) |
| [`keycap_ui`](packages/keycap_ui) | Flutter controls drawn as mechanical keyboard keycaps: sculpted keys that travel when pressed, latching choices, wells for lists and fields, in light and dark colourways. [Docs](https://wenkaifan0720.github.io/flutter_design_systems/docs/looks/keycap/) · [pub.dev](https://pub.dev/packages/keycap_ui) |
| [`ledger_ui`](packages/ledger_ui) | A Flutter design system kept in ink: warm paper, ink rules where other looks draw boxes, dot leaders, engraved figures and mono amounts, by day and by lamplight. [Docs](https://wenkaifan0720.github.io/flutter_design_systems/docs/looks/ledger/) · [pub.dev](https://pub.dev/packages/ledger_ui) |
| [`material_expressive_ui`](packages/material_expressive_ui) | Unofficial Material 3 Expressive for Flutter, ported from Compose: shapes that morph on springs, a 35-shape library, tonal colour and motion that overshoots. [Docs](https://wenkaifan0720.github.io/flutter_design_systems/docs/looks/material_expressive/) · [pub.dev](https://pub.dev/packages/material_expressive_ui) |
| [`minimal_ui`](packages/minimal_ui) | A precise, quiet design system for Flutter: hairlines, dense rows, mono tabular figures and one primary colour, in three presets by day and by night. [Docs](https://wenkaifan0720.github.io/flutter_design_systems/docs/looks/minimal/) · [pub.dev](https://pub.dev/packages/minimal_ui) |
| [`neumorphism_ui`](packages/neumorphism_ui) | Neumorphism for Flutter: every part is moulded from one wall colour, raised or pressed in by paired light and shadow, with one pigment marking what acts. [Docs](https://wenkaifan0720.github.io/flutter_design_systems/docs/looks/neumorphism/) · [pub.dev](https://pub.dev/packages/neumorphism_ui) |
| [`retro_desktop_ui`](packages/retro_desktop_ui) | Retro Desktop for Flutter: the pixel-era desktop of square windows, one-pixel bevels and striped title bars, in two appearances and five presets, by day and night. [Docs](https://wenkaifan0720.github.io/flutter_design_systems/docs/looks/retro_desktop/) · [pub.dev](https://pub.dev/packages/retro_desktop_ui) |
| [`studio_ui`](packages/studio_ui) | Flutter controls for audio and media apps, with brushed studio panels, dimmable readouts, faders, transport keys, and coordinated light and dark themes. [Docs](https://wenkaifan0720.github.io/flutter_design_systems/docs/looks/studio/) · [pub.dev](https://pub.dev/packages/studio_ui) |
| [`terminal_ui`](packages/terminal_ui) | Terminal widgets for Flutter: an app drawn on a character grid, with box-drawn panes, bracketed buttons, inverse selection and keys beside every action. [Docs](https://wenkaifan0720.github.io/flutter_design_systems/docs/looks/terminal/) · [pub.dev](https://pub.dev/packages/terminal_ui) |

Sixteen looks are built on `ui_core`. The [demo site](https://wenkaifan0720.github.io/flutter_design_systems/docs/) shows each one's components side by side, with the Dart code
behind them, and runs [Stint](https://wenkaifan0720.github.io/flutter_design_systems/docs/stint/), a team planner, in every look.

Material Expressive and Fluent 2 are independent Flutter implementations, not affiliated with or endorsed by Google or
Microsoft.

## Install

Most apps add a look, which brings `ui_core` with it. To build a look of your own on the foundation:

```yaml
dependencies:
  ui_core: ^0.7.0
```

`ui_core`'s README shows a button of your own, the behaviours, and who disposes what.

## Feedback

These are early releases, and feedback shapes the next ones: a component that's missing, a name that reads wrong, or a
control that looks off at some size. Open an issue and say which package, which component, and the screen size.

## How the packages are made

The packages are generated, not edited by hand. Each look is written once in a private design-system catalog, which
also builds the apps that use it, and is exported here with its tests and example app. A fix that arrives as a pull
request is carried back into the catalog and exported again, with credit kept in the commit.

## Working here

The repository is one pub workspace: `flutter pub get` at the root resolves every package and example. It needs
Flutter 3.47.0 or later.

```sh
flutter pub get
dart analyze --fatal-infos
cd packages/ui_core && flutter test --exclude-tags goldens
```

Tests tagged `goldens` read rendered pixels, which differ between platforms, so they run on macOS:
`flutter test --tags goldens`. CI runs them there only when started by hand. A look's golden images stay in the catalog
it is generated from, so here its golden comparisons skip themselves and its other pixel checks run.

## License

BSD-3-Clause; see [LICENSE](LICENSE). The fonts and icons a package bundles keep their own licences, which are listed
in that package's THIRD_PARTY_NOTICES.
