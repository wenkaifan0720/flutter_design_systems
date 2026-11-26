# Contributing a component

Keep the entire contribution in `site/examples/lib/components/<component>/`. The site discovers those folders, generates the navigation in inventory order, and compiles each example into its look’s deferred library. Two people adding different components can commit their folders independently.

## Add the page

1. Pick the component’s row in `RawInventoryRow.all` in `packages/ui_core/lib/src/inventory.dart`. The first row is 1. Use its group and a short kebab-case folder name, which becomes the page URL.
2. Add `component.json` with the row number, group, page title and examples in reading order. The example key becomes the link and Flutter route. For instance, this is the Button page’s manifest.

   ```json
   {
     "order": 1,
     "group": "Actions",
     "title": "Button",
     "examples": { "save-draft": "Save a draft" }
   }
   ```

   For a calendar or another tall control, add an optional positive `previewHeight` in logical pixels. The frame leaves space below its trigger and grows at double text size.

3. Add `content.md` with a `#` title and an introductory paragraph explaining when to use the component. Give each example a `##` heading that matches its manifest title exactly and explain what to try. End with `## Shared behaviour`. Describe the keyboard, focus, screen reader, RTL and text scaling behaviour readers can observe. Check shared claims against the examples.
4. For each look ID in `site/looks.json`, add a subfolder named for that ID. Check the published look’s inventory and public widget API. A present component gets an `api.json` and one Dart file per example. For `save-draft`, the path is `<look>/save_draft.dart` and the file exports a widget with a const zero-argument constructor, `SaveDraft`. The site displays and copies the exact file it compiles.

   ```json
   {
     "widget": "LedgerTabs",
     "parameters": {
       "tabs": "Section names in reading order.",
       "selectedIndex": "Index of the current section.",
       "onSelected": "Receives the chosen index."
     }
   }
   ```

   Use `keyboardNote` for a look-specific interaction or accessibility detail. The widget or function name links to its API page on pub.dev. Set `library` when pub.dev lists the symbol under a different library from the package’s main library.

5. For a deliberately absent component, write only `{"gap": "<reason from this look’s inventory>"}` in its `api.json`. The page displays “Not in <look>: <reason>”.

   `material` and `cupertino` are Flutter’s own libraries, `material_ui` and `cupertino_ui`, marked `reference` in `site/looks.json`. They show beside the design systems for comparison, in a group of their own. Write their examples as a Flutter developer would with that library. When it has no widget for a component, the gap is one plain sentence, such as `"Material has no hover card."`, and the page displays it as written, with no stand-in. The generator checks every look and reports a missing manifest or example file. The [Button](examples/lib/components/button), [Dialog](examples/lib/components/dialog) and [Tabs](examples/lib/components/tabs) folders are working examples.

## Write the example

Use ordinary Flutter code and the look’s public package import. Keep each file short enough to read as a single example. Show an action with an observable result. Let the look supply its own components, vocabulary, styling and interaction. The preview host already supplies the theme, fonts, direction, text scale and navigator.

Use public constructors, use the look’s own modal helper where it has one, and keep example state local. Avoid private imports, shared adapters, hand-drawn substitutes and low-level accessibility wrappers that conceal a package defect. Describe the controls and keyboard actions readers can use. Report package defects separately with the version and steps to reproduce.

## Run and check locally

With Flutter 3.47.0 or later on your path, build and serve from the repository root.

```sh
bash site/tool/build.sh
python3 site/tool/serve.py
```

Open `http://127.0.0.1:8000/docs/<component>/`. The build resolves dependencies, generates the site and example routes, and compiles the Flutter app. For a prose or parameter edit, run `dart site/tool/generate.dart` to refresh the pages; it reads the packages the last build resolved. Rebuild after editing Dart examples or adding routes. For Flutter hot reload, run the generator first, then run `flutter run -d chrome` from `site/examples/` and open `/#/<look>/<component>/<example>` on its local server.

- Run `dart format site/examples/lib/components/<component>` and `dart analyze --fatal-infos site` after generation. Commit the component folder. Route tables and build output are generated locally.
- Switch through every look on the page. Try the action in Preview, open Code, and check that Copy code matches the entire example. Open preview should show the same example at native size.
- Check Desktop at 1440px and 1024px browser widths and Phone at its fixed 390px width. Both previews render at native size. Try day and night, LTR and RTL, and 100% and 200% text. Check long labels, focus indicators and overlays at the narrow size.
- Operate each present example with the keyboard. Check traversal, activation or selection and, for overlays, dismissal and return of focus. Check with a screen reader that names, roles, values and state changes describe what happened. A browser accessibility tree also helps localize a missing role or name.
