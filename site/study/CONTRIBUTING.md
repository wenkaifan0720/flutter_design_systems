# Build Stint in one look

Stint follows a five-person design studio through its tasks and timesheet. Every look opens the same workspace on Friday, November 20, 2026. Compose the screens from your look’s own controls, typography, surfaces, density and transitions. Minimal summarizes the week with a sparkline and hairline rows. Appliance uses a meter, recessed readouts and physical keys. Read your package’s README and run through its example app before choosing how your look presents the same work. [Minimal study](minimal_ui/lib/src/workspace.dart) · [Appliance study](appliance_ui/lib/src/workspace.dart) · [ui_core](../../packages/ui_core/README.md)

## Start a study package

Keep each app in `site/study/<look_package>/`. For example, `brutal_ui` uses the private package `stint_brutal`, the public library `lib/stint_brutal.dart`, the widget `StintBrutal` and the loader `Future<Widget> openStintBrutal(StintLaunch launch)`. Use the same naming pattern for your look.

- Set `publish_to: none` and `resolution: workspace`. Depend on `../stint_core` and your look's release on pub.dev. The site workspace's `study/*` glob already includes your study. Add the app as a path dependency in `site/examples/pubspec.yaml`. The site finds its public library when it generates the Stint switcher. [Example pubspec](minimal_ui/pubspec.yaml)
- Give the public widget an optional `StintRepository` so tests can inspect edits. Create one `StintController` per running app, start `refresh()` and dispose it when the app unmounts. Keep it alive across theme, locale and window changes. [Example widget](appliance_ui/lib/stint_appliance.dart)
- Supply `lib/main.dart`, `web/index.html` and `test/study_test.dart`. The standalone entry point reads `StintLaunch.fromUri(Uri.base)`, honors `a11y=1`, imports the study `deferred as`, awaits `loadLibrary()`, then mounts the public loader’s result. Load any bundled look fonts in that loader so the embedded and standalone app paint identically. [Standalone entry point](minimal_ui/lib/main.dart) · [Embedding example and launch parameters](README.md)

## What the look owns

`stint_core` owns `Person`, `Project`, `Task`, `TimeEntry`, the fixture clock, IDs, five people, three projects, forty tasks and two weeks of entries. `StintRepository` owns the in-memory edits, simulated delay, empty data and one-shot read failure. Create it through `launch.createRepository()` for the standalone app. Reloading the standalone URL starts a fresh workspace. [Models and fixtures](stint_core/lib/src/fixtures.dart) · [Repository](stint_core/lib/src/repository.dart)

Read `StintController.visible` for search, intersecting filters and sort. Use its selection methods, `changeTasks`, `deleteTasks` and `undoDelete` for row and bulk actions. Keep the exact list returned by a deletion for that notification’s Undo action. Use `openTask`, `TaskDraft` and `saveTask` for editing, and `EntryDraft`, `addEntry`, `shiftWeek`, `entriesFor`, `dailyMinutes` and `totalMinutes` for Time. Settings, sign-in state, English and Arabic strings, localized seed content and validation messages live in the core. The look binds its fields to this state and presents the resulting errors. [Controller](stint_core/lib/src/controller.dart) · [Drafts](stint_core/lib/src/forms.dart) · [Words](stint_core/lib/src/words.dart)

The look owns composition, field controllers, overlay presentation and how it draws interactive states. Use its public widgets and the `ui_core` behaviors they expose. Where a look needs a different visual treatment, paint the relevant `ui_core` builder with the look’s tokens. Keep keyboard traversal, list/detail routing, calendar navigation, combobox search interactions, focus restoration and semantics in those primitives. Register the look’s localized control names as well as the app strings. [Minimal Arabic control adapter](minimal_ui/lib/src/localizations.dart)

## Five places and their shell

| Place | Required behavior |
| --- | --- |
| Today | Greet the current teammate. Show open tasks and this week’s hours with a chart or meter. Open a task from the next-up list and show a useful empty state when it clears. |
| Tasks | Search, filter by status, project and assignee, and sort. Support refresh, loading skeletons and retry. Provide row actions to mark done, move and delete with Undo, plus multi-select and bulk actions. Keep search, filters, row dividers and row actions on the same column edges. |
| Task detail | Open a page on a phone and an editable pane beside the list on desktop. Include title, multiline notes, project select, searchable assignee, due-date field and picker, numeric estimate, segmented priority, label chips, done checkbox and reminder switch with time. Show validation in words. Offer Save and Discard when leaving a dirty draft, including system Back. Dismissing the dialog keeps the draft. Resizing keeps the edits. |
| Time | Browse weeks in both directions. Show entries, a weekly total and a chart. At 390 pixels and 2× text, keep the range and both arrows on one row. Keep every key at least at the 40 × 40 touch floor. The visible range can ellipsize. Give screen readers the complete range. Add an entry in a sheet with date, start, end, project and note. Validate, save and update the week and total. |
| Settings | Support system, day and night appearance, text size, English and Arabic, the look’s density choices when available, and About. Confirm sign-out, support Cancel and allow returning to the study. |

Paint `RawAdaptiveShell` as phone tabs, a tablet rail and desktop side navigation. Detail belongs to Tasks. Use `RawListDetail` for the page/pane transition. Give menus and icon buttons accessible names, show tooltips and shortcut labels, open the desktop command palette with Ctrl/Cmd–K, and save the current task with Ctrl/Cmd–S. Use directional layout and icons so week navigation and task panes read correctly in Arabic. [Task navigation example](minimal_ui/lib/src/tasks.dart)

## Run and check

Run `flutter pub get` in `site/`. From the look’s app directory, run `flutter test` and `flutter run -d chrome`. Run the shared model tests in `stint_core`. Build and serve the integrated [documentation site](../README.md) to try the frame and full-window app.

Check Today, Tasks, task detail, Time and Settings at 390 and 1440 pixels, in both themes, in English and Arabic, and at 100% and 200% text. At 800 pixels check the navigation rail. Standalone launch parameters let you reopen a specific screen. [Launch parameters](README.md)

- Navigate by keyboard, open and dismiss a menu, open the command palette from search and save an edit. Listen for control names, selection, chart values and validation errors with a screen reader.
- Search to zero results and clear the query. Combine filters, sort, select multiple tasks, delete them and restore them with Undo. Open `?page=tasks&state=error` and use Retry. Check the empty and loading states.
- Edit on a phone and resize before saving. Check invalid fields, the date picker, assignee search, reminder time and unsaved changes. Add a time entry and check the week and total. Change language and appearance in Settings, then try both sign-out actions.

## Today alignment

Register `checkTodayAlignment` in the edition’s `today_test.dart`. Pass the public app constructor, its font loader and its timer composition. The shared check rasterizes the keyed subtrees at 390, 768, 1024, 1280 and 1440 logical pixels in English and Arabic. Put each `ValueKey<String>` on the visible face, glyph, text or group of marks it identifies. Padding or an empty slot can have the right layout bounds while its contents paint elsewhere. [Shared check](stint_core/test/support/today_alignment.dart) · [Appliance example](appliance_ui/test/today_test.dart) · [Minimal example](minimal_ui/test/today_test.dart)

| Keys | What they identify |
| --- | --- |
| `today-timer-card`, `today-timer-title`, `today-timer-digits` | Key the timer’s face, task group and elapsed reading. At 1024, 1280 and 1440 px, a timer strip places the clock on the leading edge of the Open tasks tile below, even after switching tasks. Keep the controls on the trailing edge and centre the three groups vertically. Mirror the grid in RTL. |
| `today-timer-well` | Editions with a console key the recessed display at the top of the timer column. |
| `today-timer-lamp`, `today-timer-label` | A console with a timer lamp passes `hasTimerLamp: true`. Key the lamp face and the adjacent running or stopped label. The whole lamp sits inside the well, on the leading side of the label and on its centre line. |
| `today-action-first`, `today-action-last` | The running timer’s Stop and Switch task faces in reading order. Console keys share the well’s width equally. |
| `today-stat-tasks`, `today-stat-hours`, `today-chart` | Two equal stat faces over the chart. Their outside edges meet the chart edges. The weekly duration keeps its localized units and fits inside its painted face, including when it wraps. When the summary stands beside the timer, the stat tops meet the timer top and the chart bottom meets the key bottoms. |
| `today-day-slot-<i>`, `today-day-label-<i>` | The painted bar, point or rest mark and its weekday, indexed Monday 0 through Sunday 6 in both languages. Use the same position for the mark and its label. |
| `today-plan-lead-<taskId>`, `today-plan-lead-all`, `today-later-lead-<taskId>` | Key the plan section `today-plan`. Its rows and the later task rows key their leading marks. A “View all tasks” row in the plan uses `all` and shares the checkbox centre and task-title edge. |
| `today-blocks-lead-<i>`, `today-team-lead-<personId>`, `today-feed-lead-<i>` | Each time block’s leading mark or stamp, teammate avatar, and activity mark or stamp. Indices follow display order, starting at zero. |
