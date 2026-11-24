# ui_core design skill

An agent skill for building a Flutter app's own design, neither Material nor
Cupertino, on [ui_core](https://pub.dev/packages/ui_core), and the app's
screens made of it: ui_core carries every part's behaviour, the design
paints it.

## Install

Copy this folder into your project's `.claude/skills/`, or into
`~/.claude/skills/` for every project:

```text
cp -R ui_core_design_system <your app>/.claude/skills/
```

The app depends on:

```text
flutter pub add ui_core:^0.6.1 material_ui
flutter pub add 'dev:ui_core_test:^0.4.0' dev:leak_tracker_flutter_testing
```

## What is inside

| Path | What it is |
|---|---|
| `SKILL.md` | The workflow: the design's laws, its theme, its face, the parts the screens need, the screens, and the checks. |
| `references/contract.md` | How each kind of part is wired on ui_core 0.6.x, and the API each part is painted on. |
| `references/taste.md` | The rules a good design keeps, each with a check. |
| `references/examples.md` | Excerpts from published designs on ui_core. |
| `samples/` | Tend, a small plant-care app with a design of its own (`lib/design/`), three screens (`lib/screens/`) and its tests. Every Dart block in the pages is taken from it, and a test keeps them in step. |
| `evals/` | App-design briefs, a rubric and a scorer for trying the skill on a fresh agent. |

Written for ui_core 0.6.x and ui_core_test 0.4.x, on Flutter 3.47 or later.
