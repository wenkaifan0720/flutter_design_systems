## 0.2.0

Nothing is renamed or removed: an app on 0.1.0 compiles on 0.2.0 unchanged. In a debug build, a value out of its
range now fails at once (see Behaviours). A list opened from a field is now the field's width, wider only to fit its
widest item (see Behaviours).

### Words in 30 languages

- `DesignLocalizations.delegate` loads the words for an app's locale: English and 29 more
  (`DesignLocalizations.supportedLocales`), English for any other. Translations are opt in: add the delegate beside
  Flutter's (`...GlobalMaterialLocalizations.delegates`, from `flutter_localizations`), as the README shows; a look
  supplies its own Material and Cupertino words.
- Dates, plurals and digits come from CLDR, through `DesignLocaleData`; the words Material already translates are
  Material's own. Our own 38 messages are new translations, awaiting a native speaker's check in every language but
  English (the README lists them).
- Three more shared words: Try again, Done and Confirm (`retryButtonLabel`, `doneButtonLabel`,
  `confirmButtonLabel`).

### Tap targets, density, spacing and style

- `DesignTapTargetScope` and `DesignTapTargets` declare the floors a look's controls stand at (44 by 44 for a finger,
  24 by 24 for a pointer, by default), and `DesignTapTarget` lays a control out at its floor, aligned where you say,
  with its semantics node spanning the whole target. `DesignInput` says whether a finger or a pointer reaches the
  controls.
- `DesignDensity` tightens a control's face in steps, never its tap target.
- `DesignSpacingScope` and `DesignSpacing` declare the grid a look's spacing stands on (4 pt by default).
- `DesignStyle`: one per-part style (fill, foreground, edge, overlay, side, shape, padding, minimum size, text
  style, icon size, each resolved against the part's states) for every look, in place of a copy in each.
  `DesignStyleOf` reads a part's own `style:` and then its component theme, first wins.

### The checks a look is held to

- `DesignTapTargetCheck`: every control's tap target reaches the look's floor for its input, where it is drawn.
- `DesignCursorCheck`: a live control shows the click cursor (or one that says more) over its whole hit area, an off
  control nothing of its own.
- `DesignShadowClipCheck`: no shadow, glow or rim is cut flat by a clip, and none shows square behind a round face.
  A scroll view's edge along its scroll, with more content past it, is scrolling, not a cut. `near:` reads only the
  casts that reach one control, for a test of its press, hover or focus.
- `DesignSpacingCheck`: a page's margin, concentric insets and gaps on the grid; `literals` reads a look's sources
  for spacing off its grid.
- `DesignWidthCheck.checkList` also fails a list wider than the larger of its field and its widest item, and names
  both widths. It reads a text field's face round its entry (an autocomplete's field view, with no toggle), a
  right-to-left line's words from the end they start at (Latin words in a right-to-left layout too), and a list as
  drawn where it can (one laid out with room round its face for a shadow is as wide as its face), its face too where
  it lies over the field's edge by a rule they share. It takes only a list across from its field, nearest first (a
  dialog's button beside the field's column is none of its), and reads a face lit from one corner (a groove's
  highlight too faint to stand off) to its box on its lit sides, so right to left its leading edge is not read short.
- `DesignAlignmentReport.advisories`: what a check notes without failing (uneven gaps, say).
- `test/moving_states.dart`: holds a press, a hover, a focus, a sheet and a swipe halfway, so a test can capture and
  check the moments between states.

### Behaviours

- A list opened from a field (`DesignAnchoredOverlay` above or below, `DesignOverlayPlacement.matchAnchorWidth`, on
  by default) is the field's width, wider only as far as its widest item needs, up to
  `DesignOverlayPlacement.maxWidth` (320 by default), never to the screen; its width is set before its first frame,
  so a reveal inside it stays under the field from the start. Before, a list whose rows stretched spread to the
  screen's width. Its widest item is read from its intrinsic width: rows in a `Column` (in a
  `SingleChildScrollView` when they scroll) say it; a lazy `ListView` keeps the field's width. A popover that keeps
  its own width (a calendar, a picker) turns `matchAnchorWidth` off, as before.
- A menu, select or popover (`DesignAnchoredOverlay`, the menu bar's menus) closes when a route is pushed over its
  anchor's (an alert, a dialog, a sheet), on the anchor's navigator or another (an alert on the root navigator over a
  page in a nested one), and leaves focus to that route. Before, it stayed open under the new route, and was still
  open when the route was popped.
- A quick tap shows its press, in a list and beside a long press: `DesignPressable` takes its pressed state from the
  pointer, and holds it at least `minimumPressDuration`.
- Under Reduce Motion an effects spring (opacity, colour) is a short fade with no overshoot, as a spatial one already
  was.
- `DesignScrollArea.thumbLength` gives the thumb one length whatever the content's (null keeps it proportional).
- `showDesignCommandPalette` and `DesignSideSheetRoute` take a `barrierBuilder`, so a look can paint its own barrier;
  `barrierColor` stays the default.
- An open swipe row shows the click cursor, and its strip clips only along the swipe, so an action's shadow is not
  cut at its top and bottom.
- A combobox's and a tag input's field keep a node of their own, so a screen reader outlines the field, not the
  options beside it.
- A combobox's and a tag input's list keys are ui_core's own, over `RawAutocomplete`'s: Up and Down go round past the
  ends; on a closed list, Down or Up opens it without moving; an opened list's highlight starts on the combobox's
  `value` (else the first option that can be taken). Opened before the user edits the words (by Down, a press, focus,
  a look's toggle), a combobox lists every option (with a `search`, what it finds for no query), its value
  highlighted; it filters once the user edits them. Home, End and letters stay with the text. Before, the keys stopped
  at the ends, Down on a closed list opened it one past the highlight, and a combobox reopened on its value listed
  only that option.
- `isOptionEnabled` (`DesignCombobox`, `DesignTagInput`) disables an option: it is painted with
  `WidgetState.disabled`, the keys pass over it, and neither a tap nor Enter takes it (nor, in a tag input, its name
  typed before a separator, pasted, or entered as free text).
- `highlightFollowsPointer` (`DesignCombobox`, `DesignTagInput`; off by default) makes the pointer and the keys one
  place, as in a native menu: a pointer moving over an option that can be taken highlights it, the keys go on from
  there, the highlight stays when the pointer leaves the list, and no option shows `WidgetState.hovered` apart. Off,
  the pointer's option is hovered and the keys' focused, for a look that paints them apart.
- A long list opened from a field (`DesignCombobox`, `DesignTagInput`) or in a command palette opens with its value
  (else its highlighted option) in view, and keeps the highlighted row wholly in view as the keys move it: round the
  ends, a page at a time, to the first or the last, rows of differing heights too. Before, a lazily built list never
  scrolled to a row it had not built yet, and the highlight moved out of sight.
- Android's back (its button or gesture) closes what ui_core holds open, the innermost first, and the page stays; the
  back after the last pops it. A menu or popover (`DesignAnchoredOverlay`: the menu bar's menus, a split button's, a
  popover) returns focus to its anchor; a combobox's or a tag input's list closes as Escape closes it, focus staying in
  the field; a list in a popover closes before the popover. Before, the back popped the page under them.
- In a menu bar's menu, a typed letter goes to the next item it starts (the same letter steps through them), and
  letters typed in a run spell the start, as a select's do.
- Every public widget describes its fields in the widget inspector and in test failures (`debugFillProperties`).
- A value out of its range fails at once in a debug build, with what was given: a slider's or a handle's value past
  its `min` and `max`, a `min` over its `max`, a split view's fraction outside 0 to 1, a non-positive step, size or
  spring.

### For a look's package

- ui_core's `analysis_options.yaml` is a template a look copies: the strict modes and Flutter's lints, with
  `public_member_api_docs`, `avoid_dynamic_calls`, `unawaited_futures` and a few more.
- `test/flutter_test_config.dart` turns on Flutter's leak tracking for every test, the test helpers' own objects left
  to them as in Flutter's config; `test/doc_examples.dart` compiles and runs every example in a package's docs. Copy
  them into your package's `test/`. A test that walks a whole gallery in one go passes the config's
  `longWalkLeakTesting` as its `experimentalLeakTesting:`: it tracks no leaks of its own, where a stack kept for every
  object it makes would run it out of memory.
- A rename keeps its old name, deprecated, for one minor version, with a `dart fix` (`lib/fix_data.yaml`) and a
  `test_fixes/` pair; the README shows the pattern, and how a theme's `.of` falls back. A package's `test_fixes/` has
  analysis options of its own, as Flutter's has, so `dart fix --compare-to-golden test_fixes` reads it through the
  package's exclude.
- A look's page transitions (the README's "A look's page transitions"): a look exposes its push as a map of
  widgets-level `PageTransitionsBuilder`s, one map for both Materials, and its example puts it in the app's
  `ThemeData`. Installed only in the Material theme a look builds (material_ui's), it never reaches Flutter's
  `MaterialPageRoute`. `example/test/page_transitions_test.dart` holds the pattern for a look's example to copy.
- `DesignSwipeBackPageTransitionsBuilder` keeps iOS's swipe back from the screen's leading edge round a look's own
  push, which drops Cupertino's transition and the swipe with it; `designSwipeBack` wraps a map's iOS entry in it. The
  README's page-transition pattern puts it in a look's map, and the example's test swipes a page back on iOS.
- `host.dart`, `inventory.dart` and `alignment.dart`, and a look's `<look>_parts.dart` and `<look>_host.dart`, say in
  their library docs that they are outside semver: tooling for looks that may change in any version.

## 0.1.0

- First release: 24 headless behaviours (see the README), the press and the value handle they are built from,
  `DesignLocalizations` for the words they and a look say by themselves, and spring motion that respects Reduce Motion.
- `host.dart`: the scaffold contract the look packages share (tabs, the shell's action, how a route is presented,
  preview frames, the media slot, English formats). It leaves the package in a later minor version.
- `inventory.dart`: the component checklist a design system answers, and the gallery that lists its answers.
- `alignment.dart`: the checks a design system's tests and review pages run on its screens: that its controls line
  up where they share a line, on Android, iOS and macOS, from their drawn pixels (`DesignAlignmentMatrix`,
  `DesignRowCheck`), that each label sits on the middle of its face (`DesignLabelCheck`), that a card's or a
  gallery section's contents start and end on shared lines (`DesignKeylineCheck`), that controls keep to their
  content's width on a wide screen (`DesignWidthCheck`), that no word breaks across lines
  (`DesignWordBreakCheck`) and nothing is cut (`DesignClipCheck`), and the sheets that draw them for review.
  `DesignKeylineRegion`, in the main library, marks a card or a section for them.
- `DesignControlBox` and `DesignTextEntryBox`: the layout that keeps a control or a text entry on its line.
- `DesignCapCenter`: a one-line label drawn with its capitals on the middle of its box.
