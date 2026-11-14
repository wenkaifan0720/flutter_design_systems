# flutter_design_systems

Design systems for Flutter, one package per look, all built on one shared foundation, `ui_core`. Every look
works under a `MaterialApp`, a `CupertinoApp` or a `WidgetsApp`, at phone and desktop sizes, by day and by night.

| Package | What it is |
| --- | --- |
| [`ui_core`](packages/ui_core) | Headless behaviours for Flutter design systems: the state, keyboard, focus and semantics of 24 controls, with every pixel left to the design system. |
| [`comic_ui`](packages/comic_ui) | A Flutter design system drawn as a printed comic: inked panels, speech balloons and everyday controls, five editions by day and night, with state motion. [Try the gallery](https://wenkaifan0720.github.io/flutter_design_systems/comic/) |
| [`fluent2_design_ui`](packages/fluent2_design_ui) | Unofficial Fluent 2 widgets for Flutter: Fluent's tokens, type ramp and components, seven brand presets in light and dark, accessible controls. [Try the gallery](https://wenkaifan0720.github.io/flutter_design_systems/fluent2/) |
| [`frosted_ui`](packages/frosted_ui) | Frosted glass widgets for Flutter: frosted panes on a canvas lit by soft washes of colour, seven light and dark palettes, accessible controls and a complete theme. [Try the gallery](https://wenkaifan0720.github.io/flutter_design_systems/frosted/) |
| [`ledger_ui`](packages/ledger_ui) | A Flutter design system kept in ink: warm paper, ink rules where other looks draw boxes, dot leaders, engraved figures and mono amounts, by day and by lamplight. [Try the gallery](https://wenkaifan0720.github.io/flutter_design_systems/ledger/) |
| [`material_expressive_ui`](packages/material_expressive_ui) | Unofficial Material 3 Expressive widgets for Flutter: morphing shapes, springs, dynamic colour, accessible controls and five light and dark presets. [Try the gallery](https://wenkaifan0720.github.io/flutter_design_systems/material_expressive/) |
| [`minimal_ui`](packages/minimal_ui) | A precise, quiet design system for Flutter: hairlines, dense rows, mono tabular figures and one primary colour, in three presets by day and by night. [Try the gallery](https://wenkaifan0720.github.io/flutter_design_systems/minimal/) |
| [`neumorphism_ui`](packages/neumorphism_ui) | Neumorphism for Flutter: soft raised surfaces, inset controls, five light and dark palettes, accessible interactions, role-based shapes and state-resolved styling. [Try the gallery](https://wenkaifan0720.github.io/flutter_design_systems/neumorphism/) |

Eight looks are built on `ui_core`, each with a live gallery you can try in your browser: Neumorphism, Retro Desktop,
Comic, Frosted, Ledger, Minimal, Material Expressive and Fluent 2. Those not in the table yet follow over the coming
days.

Material Expressive and Fluent 2 are independent Flutter implementations, not affiliated with or endorsed by Google or
Microsoft.

## Install

Most apps add a look, which brings `ui_core` with it. To build a look of your own on the foundation:

```yaml
dependencies:
  ui_core: ^0.1.0
```

`ui_core`'s README shows a button of your own, the behaviours, and who disposes what.

## Feedback

These are first releases, and feedback shapes the next ones: a component that's missing, a name that reads wrong, or a
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
