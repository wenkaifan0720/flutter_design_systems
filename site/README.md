# Documentation site

The source of the [documentation site](https://wenkaifan0720.github.io/flutter_design_systems/docs/): a page for every
component, with a live example in each look and the Dart source behind it, a page for each look, and Stint, a team
planner built in every look.

## Build and serve

The site is a pub workspace of its own, apart from the packages': it builds on the looks released on pub.dev, as an app
would. It needs Flutter 3.47.0 or later, and Python 3 to serve the build. From the repository root:

```sh
bash site/tool/build.sh
python3 site/tool/serve.py
```

Then open `http://127.0.0.1:8000/docs/`. The build resolves the site's packages, generates the pages and the example
routes, and compiles the Flutter web app into `build/site/`. `serve.py` serves that folder the way a static host does,
missing pages included; `--port` picks another port.

The looks' versions are the ones in `examples/pubspec.yaml` and `study/*/pubspec.yaml`. To see a change to a package
before it is released, point the site at it in a `site/pubspec_overrides.yaml` of your own (git ignores it), for
example `dependency_overrides: {minimal_ui: {path: ../packages/minimal_ui}}`, with every look it needs on the same
`ui_core`.

## What is where

| Path | What it holds |
| --- | --- |
| `examples/` | The Flutter web app behind every preview. Each page's text, manifest and examples live in `lib/components/<component>/`; `lib/<look>/theme.dart` wraps an example in its look. |
| `study/` | Stint: `stint_core`, its shared model, and one edition per look. See [Stint](study/README.md). |
| `tool/` | The page generator and templates, the site's scripts and styles, the build and the local server. |
| `looks.json` | The looks the site shows, in order, with Flutter's Material and Cupertino as references. |
| `assets/` | The site's fonts, icon and images. |

The home page, search directory and look pages are static. Each component page loads the selected look's highlighted
source and Flutter examples on demand, and Stint loads the selected edition separately. The `docs/` folder can sit
below a path prefix, as it does on GitHub Pages.

## Links

A documentation link such as `/docs/dialog/?look=ledger` opens the component in that look. A standalone link such as
`/docs/examples/#/ledger/dialog/draft-details?theme=night&dir=rtl&scale=2&width=390` also carries its preview settings.

Open `/docs/looks/minimal/` to browse one design system. Open `/docs/stint/?look=minimal` for the framed team planner or
`/docs/examples/?stint=minimal&page=tasks` for its full-window Tasks screen. Resizing the frame keeps the running
workspace. [Stint apps and launch parameters](study/README.md)

To add a component or check one locally, see [Contributing](CONTRIBUTING.md).
