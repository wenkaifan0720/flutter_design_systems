# Stint

Stint follows a five-person design studio through a work week. Each design system opens the same forty tasks, three projects and two weeks of time entries on Friday, November 20, 2026. Edits last for the running session.

To build Stint in another design system, follow the [contributor guide](CONTRIBUTING.md).

Each directory is a member of the site's Flutter workspace. Run `flutter pub get` in `site/`. From a look directory such as `minimal_ui`, run `flutter run -d chrome`. Run `flutter test` from a look directory or `stint_core` to check its tests. Each edition's `resize_test.dart` widens its window from 390 to 1440 and narrows it again on every place, and fails if any part keeps asking for frames once the window is still. The [documentation site](../README.md) builds all available editions into its app switcher.

## Checks

Run `bash site/tool/stint_gate.sh` before building or reviewing Stint. It runs strict analysis and every Stint test suite, including the shared Today check.

## Click-through check

`site/tool/stint_click_test.mjs` opens every edition in the built site the way Stint launches, with semantics on. It clicks every control on every screen with a mouse at 1440 px and taps it at 390 px. Each control must change something: a control that shows a state must change its own state, and a menu, sheet or dialog that opens must respond to a control inside it. A checkbox row, its box and words one target, is pressed on its words. A Search button is pressed after a word is typed into its field. A group whose options reach the semantics tree as one control fails, because neither a pointer nor a screen reader can pick an option. Run it after building and before publishing the site.

```sh
npm --prefix site/tool install
npx --prefix site/tool playwright-core install chromium-headless-shell
python3 site/tool/serve.py &
node site/tool/stint_click_test.mjs --editions minimal,cupertino --out click-report.json
```

Without `--editions` it checks all of them. `--widths`, `--screens` and `--shots <dir>` narrow the run or save a screenshot of each failure.

## Embedding an edition

A host app, such as the docs site’s examples app, can load each edition separately. This example uses path dependencies on `stint_core`, `stint_minimal` and `stint_appliance`. The standalone web entry points use the same deferred loading path.

```dart
import 'package:flutter/widgets.dart';
import 'package:stint_appliance/stint_appliance.dart' deferred as appliance;
import 'package:stint_core/stint_core.dart';
import 'package:stint_minimal/stint_minimal.dart' deferred as minimal;

Future<Widget> openStudy(String look, StintLaunch launch) async {
  switch (look) {
    case 'minimal_ui':
      await minimal.loadLibrary();
      return minimal.openStintMinimal(launch);
    case 'appliance_ui':
      await appliance.loadLibrary();
      return appliance.openStintAppliance(launch);
    default:
      throw ArgumentError.value(look, 'look');
  }
}
```

For a preview, pass `StintLaunch.fromUri(uri)` or construct a `StintLaunch`. The standalone app accepts URLs such as `/?page=detail&theme=night&lang=ja&scale=2` and `/#/tasks?state=error`. To share one set of preferences between several apps, or to change them while an app runs, give each launch `launch.sharing(settings)`: the app reads and writes that `StintSettings` and leaves it to its owner to dispose.

| Parameter | Values |
| --- | --- |
| `page` | `today`, `tasks`, `detail`, `time`, `settings` |
| `theme` | `system`, `day`, `night` |
| `lang` | `en`, `ar`, `ja`, `de` |
| `dir` | `rtl` opens Arabic, kept for older links |
| `scale` | 1 to 2, or omit to follow the platform |
| `density` | `standard`, `compact` |
| `accent` | `navy`, `green`, `gold` (black + gold), `purple`, `pastel`: the look in that palette through its own colour API; omit or `look` for the look's own |
| `state` | `empty` starts an empty workspace, `error` fails the first read so Retry can recover, `loading` delays reads for three seconds |
| `a11y` | `1` enables Flutter web semantics at startup |

The docs site's Stint page adds four settings it applies around the app, not through `StintLaunch`: `motion=reduce` turns animations off, `bold=1` asks for bold text, `targets=1` outlines each tap target against the device's minimum size, and `reader=1` outlines each screen-reader stop with what it announces. The page changes all of them, and the four above, in the running app without reloading it.

The command palette opens with Ctrl/Cmd–K. Ctrl/Cmd–S saves the open task. The Tasks menu supports individual or bulk actions. A delete notification restores the affected tasks with Undo.
