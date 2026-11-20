# flutter_design_systems

Design systems for Flutter, one package per look, all built on one shared foundation, `ui_core`. Every look
works under a `MaterialApp`, a `CupertinoApp` or a `WidgetsApp`, at phone and desktop sizes, by day and by night.

| Package | What it is |
| --- | --- |
| [`ui_core`](packages/ui_core) | Headless behaviours for Flutter design systems: the state, keyboard, focus and semantics of 24 controls, with every pixel left to the design system. |
| [`ui_core_test`](packages/ui_core_test) | Checks for design systems built on `ui_core`, read from what is drawn: rows that line up, labels on their faces' middles, shared keylines, tap targets, cut words and shadows. A dev dependency, as `flutter_test` is. |
| [`appliance_ui`](packages/appliance_ui) | Flutter controls inspired by household appliances, with moulded keys, indicator lights, recessed displays and responsive navigation in light and dark themes. [Try the gallery](https://wenkaifan0720.github.io/flutter_design_systems/appliance/) |
| [`brutal_ui`](packages/brutal_ui) | A neo-brutalist Flutter design system: heavy black rules, square corners, a hard shadow under what you can press and one flat colour block a screen. [Try the gallery](https://wenkaifan0720.github.io/flutter_design_systems/brutal/) |
| [`civic_ui`](packages/civic_ui) | A Flutter design system for public services: one thing per page, large type, a heavy yellow focus, errors said in words, answers checked before they are sent. [Try the gallery](https://wenkaifan0720.github.io/flutter_design_systems/civic/) |
| [`comic_ui`](packages/comic_ui) | A Flutter design system drawn as a printed comic page: inked panels, speech balloons and Ben-Day dots in flat inks, every change of state a quick cut or pop. [Try the gallery](https://wenkaifan0720.github.io/flutter_design_systems/comic/) |
| [`fluent2_design_ui`](packages/fluent2_design_ui) | Fluent 2 widgets and themes for Flutter. Build forms, navigation, data grids and charts with seven light and dark presets, acrylic surfaces and Fluent icons. [Try the gallery](https://wenkaifan0720.github.io/flutter_design_systems/fluent2/) |
| [`frosted_ui`](packages/frosted_ui) | Frosted glass for Flutter: panes rimmed with light stand on a canvas lit by soft washes of colour, and one ink act carries each page, by day and by night. [Try the gallery](https://wenkaifan0720.github.io/flutter_design_systems/frosted/) |
| [`gloss_ui`](packages/gloss_ui) | Skeuomorphic widgets for Flutter with glazed controls, recessed panels, accessible forms, navigation, and charts in coordinated light and dark themes. [Try the gallery](https://wenkaifan0720.github.io/flutter_design_systems/gloss/) |
| [`keycap_ui`](packages/keycap_ui) | Flutter controls drawn as mechanical keyboard keycaps: sculpted keys that travel when pressed, latching choices, wells for lists and fields, in light and dark colourways. [Try the gallery](https://wenkaifan0720.github.io/flutter_design_systems/keycap/) |
| [`ledger_ui`](packages/ledger_ui) | A Flutter design system kept in ink: warm paper, ink rules where other looks draw boxes, dot leaders, engraved figures and mono amounts, by day and by lamplight. [Try the gallery](https://wenkaifan0720.github.io/flutter_design_systems/ledger/) |
| [`material_expressive_ui`](packages/material_expressive_ui) | Unofficial Material 3 Expressive for Flutter, ported from Compose: shapes that morph on springs, a 35-shape library, tonal colour and motion that overshoots. [Try the gallery](https://wenkaifan0720.github.io/flutter_design_systems/material_expressive/) |
| [`minimal_ui`](packages/minimal_ui) | A precise, quiet design system for Flutter: hairlines, dense rows, mono tabular figures and one primary colour, in three presets by day and by night. [Try the gallery](https://wenkaifan0720.github.io/flutter_design_systems/minimal/) |
| [`neumorphism_ui`](packages/neumorphism_ui) | Neumorphism for Flutter: every part is moulded from one wall colour, raised or pressed in by paired light and shadow, with one pigment marking what acts. [Try the gallery](https://wenkaifan0720.github.io/flutter_design_systems/neumorphism/) |
| [`retro_desktop_ui`](packages/retro_desktop_ui) | Retro Desktop for Flutter: the pixel-era desktop of square windows, one-pixel bevels and striped title bars, in two appearances and five presets, by day and night. [Try the gallery](https://wenkaifan0720.github.io/flutter_design_systems/retro_desktop/) |
| [`studio_ui`](packages/studio_ui) | Flutter controls for audio and media apps, with brushed studio panels, dimmable readouts, faders, transport keys, and coordinated light and dark themes. [Try the gallery](https://wenkaifan0720.github.io/flutter_design_systems/studio/) |
| [`terminal_ui`](packages/terminal_ui) | Terminal widgets for Flutter: an app drawn on a character grid, with box-drawn panes, bracketed buttons, inverse selection and keys beside every action. [Try the gallery](https://wenkaifan0720.github.io/flutter_design_systems/terminal/) |

Eleven looks are built on `ui_core`, each with a live gallery you can try in your browser: Neumorphism, Retro Desktop,
Comic, Frosted, Ledger, Minimal, Material Expressive, Fluent 2, Civic, Terminal and Brutal. The
[gallery index](https://wenkaifan0720.github.io/flutter_design_systems/) shows them side by side.

Material Expressive and Fluent 2 are independent Flutter implementations, not affiliated with or endorsed by Google or
Microsoft.

## Install

Most apps add a look, which brings `ui_core` with it. To build a look of your own on the foundation:

```yaml
dependencies:
  ui_core: ^0.3.0
```

`ui_core`'s README shows a button of your own, the behaviours, and who disposes what.

## Feedback

These are early releases, and feedback shapes the next ones: a component that's missing, a name that reads wrong, or a
control that looks off at some size. Open an issue and say which package, which component, and the screen size.

## How the packages are made

The packages are generated, not edited by hand. Each look is written once in a private design-system catalog, which
also builds the apps that use it, and is exported here with its tests and example gallery. A fix that arrives as a pull
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
