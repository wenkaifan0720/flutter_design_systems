# ui_core design system skill

An agent skill for building a Flutter design system (a "look", like
material_ui or cupertino_ui) on [ui_core](https://pub.dev/packages/ui_core).
ui_core carries the behaviour: focus, keyboard, screen-reader semantics, tap
targets, overlays, dialog and toast layout, motion policy, built-in words.
The look paints every part. With this skill an agent plans the look's scope,
wires each part to the right ui_core API, designs every state in the look's
own material, and proves each part with
[ui_core_test](https://pub.dev/packages/ui_core_test) and screenshots.

Written for ui_core 0.5.x and ui_core_test 0.3.x, on Flutter 3.47 or later.

## Install

Copy this folder into the project's `.claude/skills/`, or into
`~/.claude/skills/` for every project:

```sh
cp -R ui_core_design_system <project>/.claude/skills/
```

The agent then reads it when asked to build, extend or review a design
system that is neither Material nor Cupertino. `SKILL.md` is the entry
point; it says which page to read for each step.

The package it builds depends on ui_core ^0.5.5 and material_ui, and
dev-depends on ui_core_test ^0.3.0, leak_tracker_flutter_testing and
flutter_lints.

## Contents

| Path | What it holds |
|---|---|
| `SKILL.md` | The workflow, from the look's laws to a published package, what done means, and the common faults |
| `references/contract.md` | Each ui_core API a look builds on, and how to wire it |
| `references/inventory.md` | Every component an app expects, in build order, with the ui_core API under each |
| `references/taste.md` | Designing states, sizes and motion; parts as one family; an API Flutter developers know |
| `references/checks.md` | The ui_core_test checks, the commands, the screenshot review |
| `references/examples.md` | Excerpts from three published looks: minimal_ui, brutal_ui, neumorphism_ui |
| `samples/` | A small look that compiles and passes every check; every Dart block in the pages is taken from it |
| `evals/` | Three cold briefs, the rubric and the scoring script that measure the skill |

## How it is checked

`samples/test/docs_test.dart` fails when a Dart block in the pages is not
found in the samples' sources, so the pages can't drift from code that
compiles. The samples are a member of this repository's pub workspace: they
resolve on the ui_core and ui_core_test beside them, and CI runs them with
every change to either, so a core change that breaks the skill fails CI.
To run them outside the repository, delete `resolution: workspace` from
`samples/pubspec.yaml`; they then resolve on the published packages.

`evals/` measures the skill itself: a fresh agent with only this folder
builds a look from each brief, and `evals/score.sh` scores it against
`evals/rubric.md`.
