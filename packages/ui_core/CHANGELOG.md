## 0.5.5

- A `RawPopover` surface its `positionDelegate` places is sized by the bounds the popover keeps to (`RawPopoverPositionContext.bounds`: the overlay less the safe area, the on-screen keyboard, a `RawPopoverPadding` and the placement's margin), and `RawPopoverInfo.maxSize` is their size. It was sized by the room on its placement's side of the anchor, so a delegate that turned a menu over its control low on the screen got a surface as short as the room under the control: the lower rows were cut off and took no press. The placement's widths and side are kept, and a popover that places itself is sized as before.
- `RawPopover.role` gives the surface's node a semantics role beside its `semanticLabel` (`SemanticsRole.menu` for a menu, `SemanticsRole.dialog` for a popover that holds a task), so a screen reader hears what it is. With none, the default, its node is as before.
- A `RawPopover` surface drawn through its close spring takes no pointer and no focus: a press on a row as it closes, or a screen reader's tap there, no longer reaches the row, and a row asking for the focus no longer takes it back from where it went. A tap on it is a tap outside it, as on a route going out. Opened again during the spring, it takes them again.

## 0.5.4

- A required `RawInputDecorator` with no `labelText`, named by what its control says (the words it draws, merged into its node, or a semantic label), says that it is required: `requiredHint` starts its hint, as it does where the control says the label itself. It carried the required flag and no words, so a screen reader everywhere but the web (where the flag is heard on a text field's input) never heard it. The same holds merged whole (`mergeSemantics: true`), in a group of its own (`false`), and on the node a number field's or a tag input's entry carries the words on. A labelled field is as before.
- `RawTabGroupTab.order` places a tab among its group's tabs for the arrows, Home and End where they are not in reading order, as `RawRovingFocusItem.order` places an item: the group takes the tabs' order when every tab gives one.
- `RawReorderItemDetails.buildHandle` builds a drag handle whose face paints from its states, as a `RawButton`'s does: `WidgetState.focused` while the keyboard's focus shows on it (where Alt+Up and Alt+Down move the item), `WidgetState.hovered` under a pointer and `WidgetState.pressed` while a pointer holds it down. `handle` gave the face no states, so a look could not show where the keyboard was. `handle` is unchanged.
- `SwipeBackPageTransitionsBuilder` gives a route one swipe however often its transition is wrapped: one round another, or round a builder that hands the route to one. Each added a recognizer at the screen's edge, an edge and a slide of its own; the outermost now plays the swipe and those inside it add nothing. A page in a navigator of its own keeps its own swipe.

## 0.5.3

- `RawTagInput` in a `RawInputDecorator`: the text entry's node, and the area a tap on it reaches, is at least a touch target (`DesignTapTargets.floorOn`, the look's own where it declares one) about the entry's middle. A look whose entry is a short text line beside its tags read it on a node as small as the line (24 px), under the floor of the platforms' tap target guidelines. The target keeps inside the tag input and stops at each tag, which keeps its own taps and its own node; a tap in it that reaches nothing else goes to the entry's line. A node the look gives its line that is larger still (a lane round it) is kept: the entry's node was the entry's box alone. The layout and the pixels are unchanged.
- `DesignCapCenter` measures its label's baseline once for each layout of the label's line and keeps it between paints, hit tests and transforms, each of which laid the label's words out again. A full repaint of a screen with six cap-centred labels on the web (profile build) goes from 2.0 ms to 1.5 ms (each label's move from 27 µs to 3 µs). It lays out again when the system's fonts change (a web font arriving), as the label does. The pixels are unchanged.

## 0.5.2

- `RawModalRoute` raises a modal page that states no role: the barrier, the spring in and out, Escape and Android back, Tab kept inside (on the web too, where a route lets Tab leave the page by default) and the focus given back to the opener, as `DesignDialogRoute` has them. Its page is a route's scope with no role, named as the page names itself (a heading with `namesRoute`), so a modal page that is not a dialog (a search over the page, a picture shown large) is no longer heard as "dialog". Its `builder` gets `RawModalDetails` (`animation`, `close`). `DesignDialogRoute` is now a `RawModalRoute` that says dialog, and `DesignDialogDetails` a `RawModalDetails` that adds `isAlert`; nothing else about them changes.
- `RawPopover.positionDelegate` places the surface where its caller says, as Flutter's `RawTooltip.positionDelegate` places a tip: a `RawPopoverPositionDelegate` returns the surface's top-left corner in the overlay from a `RawPopoverPositionContext` (the anchor's rectangle, the surface's size as laid out for its side, the overlay's size, the bounds the popover keeps to when it places itself, the side, the reading direction and the point it opened at). The popover keeps the rest: dismissal, focus, semantics, the surface's fit and `RawPopoverInfo.surfaceRect`. With no delegate it places itself as before.

## 0.5.1

- `RenderDesignSemanticsProxy` is a `RenderSemanticsAnnotations`, the render object of Flutter's `Semantics` widget, with empty `properties` (it was a plain `RenderProxyBox`). A layout that looks through the render objects which add only semantics by Flutter's types (`RenderSemanticsAnnotations`, `RenderMergeSemantics`, `RenderExcludeSemantics`, `RenderBlockSemantics`, `RenderIndexedSemantics`) now looks through ui_core's own too (round a labelled `RawButton`'s face, a `RawInputDecorator`'s control, a `RawTabGroup`'s tabs), with no import of ui_core. The semantics tree, the layout and the pixels are unchanged.
- `RawToasterKeepClear` lets go while its part is out of sight under an opaque route. It read where its part stood each frame the part was laid out or painted, and a page under an opaque pushed route stays in the tree, so a bar on it (`DesignAdaptiveShell`'s too) kept holding the toasts up on the pushed page. It now lets go while tickers are off where it stands (`TickerMode`, which the `Overlay` turns off on a covered route, as a shell does in a hidden branch) and keeps clear again as they come back on: the toasts settle at the screen's edge once the pushed page covers the bar, and rise above the bar again as it pops. A page under a dialog keeps its bar in sight, and its toasts clear of it.
- `RawTagInput` in a `RawInputDecorator` reads the field's label, error and help on its text entry. Holding a tag, it brought two or more controls to the field (the entry and each tag), so the field read its words on a group node of its own, apart from the entry, and `DesignFieldWordsCheck` failed. The entry now carries them, with the field's validity and required flag, on one node with its text field, which it merges, so they read together also where the look's entry is a field of its own (a text field built on a `RawInputDecorator`, whose node stood apart under the words); words the entry says already are not said twice, and an entry that holds another control (a clear key) is not merged, so each keeps its node and action. Each tag keeps its own node, with its name and its remove action. With no tags the words are read as before, on the entry.
- A heading and the text under it stay two nodes under `RawToaster`, `DesignAdaptiveShell`, `DesignListDetail` and `RawCommandShortcut`. Their keys (F6 between panes, F6 to the toasts, Ctrl+K and Cmd+K) sat on a `Shortcuts` or `CallbackShortcuts` whose `Focus` added a semantics annotation of its own (focusable: false) over everything they held, so on a page (under a route's node) the nodes of plain siblings merged into one: a heading and the text after it read as one header. They now add no semantics (`includeSemantics: false`; `RawCommandShortcut` sets its keys on a `Focus` that adds none), and a page under them reads as it does without them. `RawCommandPalette`'s field is a field's node, as a `RawInputDecorator`'s: words the look draws beside its text field (a "Search" before it) name the text field on its one node, read once (they did only through that merge). The popover surface's keys and `RawDataTable`'s Ctrl+A / Cmd+A add no semantics either, which drops an empty node round an open surface and one between a table's headers and its rows; their children read as before.

## 0.5.0

- `RawActionBar` lays out a dialog's or a sheet's actions: side by side while they fit (at the end, or sharing the row when `expanded`), else stacked in one column, each as wide as the bar, the last given (the confirming one) on top and the first (the dismissive one) at the foot, as Material and iOS stack them; never two on a line and one under them. The row is mirrored right to left. Whether they fit is read from each action's widest content, so text at 2x stacks them where 1x fits. `onStackedChanged` tells the look when they stack, for its stacked styles. A look gives it its styled actions and draws nothing else; `RawAlertDialog` lays its actions out with it, so its stacked actions are now as wide as the dialog (before, each kept its own width at the end of its line).
- `DesignChartValueFormat` writes a chart's values with their unit (`prefix`, `suffix`, or `DesignChartValueFormat.custom` from the reader's figure) in the reader's digits, each tick at its scale's decimals (`DesignScaleTick.fractionDigits`, so 0.5, 1.0, 1.5 keep their decimals). `DesignChart`, `DesignPieChart` and `DesignChartTable` take one as `valueFormat`, for the axis, the readout and what a screen reader hears; `formatY` and `formatValue` still win where given. `DesignChart.yLabelGutter` keeps the y labels' room at the reading start (the right, right to left), measured with `DesignScaleTick.widestLabel`; `DesignChartDetails.textDirection` tells a painter the side. A look's painter drops its own number formatting, label measuring and mirroring.
- Focus that a pointer, a screen reader or a closing route gives is told apart from the keyboard's (`DesignFocusVisible`): a tooltip, a `RawTooltipFocusFix`'s tip and a hover card show on focus only when the keyboard moved it, as a browser's `:focus-visible` does, so a click or a screen reader's focus on a tipped control shows no tip, and focus given back as a dialog closes shows the control's ring and no tip. A `RawCombobox` whose focus is given back (a dialog over it closed, by keys or a pointer) no longer opens its list; a Tab into it still does.
- `RawPopoverPlacement.fit`: `RawPopoverFit.whole` for a surface that can't shrink sensibly (a calendar, a grid, a picker's wheels) wants its whole measured extent on its side before it takes it, so a 300 px month opens above a field low on a phone rather than shrink and scroll below, or run off the screen's foot, while above holds it whole. It is measured on the roomier side, so a surface that caps itself at `RawPopoverInfo.maxSize` still shows its whole extent; where neither side holds it, it takes the roomier and scrolls. `RawPopoverFit.scroll`, the default, keeps a list's rule: below while below holds it or 200 px of it (`preferredExtent`). A look that passed `preferredExtent: double.infinity` for this passes `fit: RawPopoverFit.whole` instead.
- A field's help and error: Material's `TextField` reads its error as the field's hint and keeps both inside the field's node, and `RawInputDecorator` already does the same (its `helperText` and `errorText`), keeping 0.4.1's stable entry node. A look that draws them beside the decorator, as most published looks do, leaves a screen reader on the field without them: ui_core_test 0.3.0's `DesignFieldWordsCheck` finds it.
- `RawToasterKeepClear` keeps the nearest `RawToaster`'s toasts clear of a bar along the screen's bottom or top, as Material's `Scaffold` keeps a snackbar above its bottom navigation bar: the toasts stand above the bar (below a top one), following it as it springs in or away, and stand where they did once it goes. `DesignAdaptiveShell` keeps its phone bar clear, so a toast no longer covers the tab bar; a rail or a sidebar keeps nothing clear. A look that padded its toaster by its bar's height drops that padding.
- `DesignComboboxField.isOpen` tells a combobox's or a tag input's field whether its options show under it (the list, or its loading, no-match or failure view), so a look turns its chevron as a select's anchor does by `DesignOverlayAnchor.isOpen`, and says it on its text input, `Semantics(expanded: field.isOpen, child: input)`, as a select says it on its button. A command palette's field hears `true`: its list always shows.
- A `RawPopover` that takes the focus as it opens leaves it on a widget in its surface that asks for it as it mounts (`autofocus: true`): a select's chosen option, a calendar's chosen day, kept in view, however the surface was opened, as browsers, Material and Radix focus a select's chosen option. Before, the surface's first focusable widget took it (a select's first option, the month's arrows ahead of the chosen day). A surface with nothing asking is as before.
- A part that keeps the focus while its arrows move inside it (`RawCalendarDatePicker`'s day) shows it on the first key after a touch. Flutter switches its highlight mode after ui_core's key handler has run, and what the parts that show focus hold now hears that switch too: registered as the first of them mounts and taken away as the last goes, as in 0.4.2. Before, the day stayed unlit until the next key.
- `DesignCapCenter` reads its label's baseline afresh, in the fonts the engine has now. A font that arrives after the first layout (a web font) left Flutter's dry baseline on the fallback font's: over a `DesignTextEntryBox` with a hint, or a label, a debug build failed Flutter's dry-baseline check as it painted, and a release build set the capitals off the middle.
- `RawRovingFocusGroup` and `RawRovingFocusItem` give a caller's own group (a row of tabs it lays out, a toolbar, a grid of choices) what the radio group, the toggle group and the tab bar share: one tab stop, the arrows along `orientation` (mirrored right to left), wrapping (`loop`), Home and End (`homeAndEnd`), items turned off passed over, the order the caller gives (`order`), and an app changing a key the Flutter way through `RawRovingFocusIntent`. The group moves the focus only: selection that follows the focus is chosen in the item's `onMovedTo`, selection on a press in the control's own press.
- `RawTabGroup<T>` and `RawTabGroupTab<T>` are a tab bar's behaviour round tabs the caller lays out as given, shaped as Flutter's `RadioGroup`: the group is a scope (`groupValue`, `onChanged`, `selectionFollowsFocus`), and each tab finds it by its `value` wherever it stands below, in the caller's frames, between its words, in a row, a wrap or a scroll view. It owns the roving focus, the selection and the semantics: each tab is read as a tab with its own words and whether it is selected, and the group's node is a tab bar (`SemanticsRole.tabBar`) while every node under it is a tab, as Flutter's debug check requires. Words between the tabs make no node of their own and are read with the bar's name; a part with a node of its own between the group and its tabs (a scroll view inside the group, an image with a label) leaves the group a plain group, its tabs still tabs, rather than failing the check. A tab the arrows reach is brought into view in the scroll views round it. `RawTabBar` is now this group with its own strip: its pixels and its semantics are unchanged.
- `RenderDesignSemanticsProxy` is the one public type of every render object ui_core puts round a control only to add semantics (round a labelled `RawButton`'s face, a `RawInputDecorator`'s control, a `RawTabGroup`'s tabs): it lays out, paints and takes hits as its child. A layout that looks through such proxies by type names this one.
- A required `RawInputDecorator` sets the required flag (`isRequired`) on its field's node, a number field's included. Its "required" words stay in the name where the platform says nothing of the flag: in Flutter 3.47 everywhere but the web, which reads the flag as `aria-required`; on the web a field whose node is its text entry drops them, and a group, a select or a field merged whole keeps them.
- `RawInputDecorator.invalid` marks a field invalid with no words to say why (`SemanticsValidationResult.invalid`, as `errorText` does), and `RawInputDecoratorDetails.invalid` tells the look to paint its error state.
- `RawButton.semanticSelected` says why a toggle button stays selected rather than `toggled` (a switch on every platform) or `checked`.

## 0.4.2

- A page drawn with ui_core instantiated afresh over a Flutter framework that lives on (a widget-preview host that runs each preview with its own package instances: App Preview, drip's preview) no longer fails its first focus-showing part with `'!_globalRoutes.containsKey(route)': is not true` from `PointerRouter.addGlobalRoute`. What ui_core hears focus by, to show it after a key and hide it after a press as a browser's `:focus-visible` does (a pointer route, a key handler, a semantics action listener), is now held by the parts that show focus: registered afresh as the first of them mounts, each registration its own, and taken away as the last is disposed, so nothing outlives the page that made it. Focus shows and hides as in 0.4.1.

## 0.4.1

- A list opens below its field while below holds it, as Material's menus and autocomplete place theirs. `RawCombobox` now opens down by default (it opened on the side with more room, so a field in a form's lower half opened its list upward with room to spare below), and a list on its side, `RawTagInput`'s suggestions too, takes the other side only when the side it asks for can't hold it, or 200 px of a longer one, and the other side has more room; else it fills the room and scrolls. A list is never drawn on the wrong side, even in the frame it opens. `OptionsViewOpenDirection.mostSpace` keeps Flutter's meaning, the larger side. `RawPopover` measures its surface before it turns: a short list that fits under its anchor stays there, though the room is under the placement's `preferredExtent`.
- A `RawInputDecorator`'s text entry keeps its semantics node as controls come and go beside it (a clear key that shows with the first letter), when its line's tap is left out of the semantics tree (`GestureDetector.excludeFromSemantics`), as Flutter's text field leaves its own: the entry is the field's node, alone or beside its keys. On the web that node is the browser's input, and a new one loses the keys typed while it is made. A lone entry that stands in a node of its own (a line's tap left in the tree, or a node between) is still one node with the field's label and hint, as in 0.4.0, so a screen reader reads it as a named text field; a control that joins it stands it apart.
- `RawMenuEntry.isDestructiveAction` marks an item that destroys something (Delete, Remove), for the look to paint in its destructive tone, as Cupertino's context menu and dialog actions do. It is false by default and changes nothing else: the item is pressed, reached and read as any other.
- `DesignLinearScale.nice` with `includeZero` gives zeros alone (an empty week) a scale from 0 up in whole steps, 0 to 4 for about five ticks, as a week with data counts. Before, it gave -1 to 1, and a chart drew its zero bars down from the middle of the plot.

## 0.4.0

- **Renamed:** the behaviours and the parts they are built from take `Raw` names, as Flutter's own unstyled widgets do (`RawButton`, `RawPopover`, `RawCombobox`, `RawDataTable`), 148 names in all (the table below). Each old name stays through 0.4 as a deprecated typedef of its new one, so code that names it still builds, and `dart fix --apply` renames it (`lib/fix_data.yaml`) where a file imports it from ui_core or from a published look. What `dart fix` cannot reach is renamed by hand: a name in a `show` or `hide` list, in a string (a test that finds a widget by its type's name), or in a file that imports it through a library of its own that re-exports it. `DesignValueHandle` and `DesignInputGroup` keep their names until they change shape.
- **Deprecated:** `DesignRadioGroup`. Use Flutter's `RadioGroup` with a `RawRadio` per radio, its face drawn in `RawRadio.builder` on a box that is hit all over (a press between a face's painted parts otherwise misses the radio), and `RadioGroupKeyboardFix` inside the group, round the radios. The fix makes two keys work as Flutter's own fixes make them, until a Flutter release that ui_core needs has them: Tab stops on the group when the chosen radio is turned off ([flutter#197073](https://github.com/flutter/flutter/pull/197073)), and Left and Right follow right-to-left text. `dart fix` can't make this move: the group's shape differs.
- **Deprecated:** `DesignTooltip`. Use Flutter's `RawTooltip`, with `RawTooltipFocusFix` round its child, which shows it on the keyboard's focus as a hover does ([flutter#196554](https://github.com/flutter/flutter/issues/196554)) and hides it on Escape, as Flutter 3.47's `RawTooltip` does not, and `RawTooltipPlacement` round it, which places the tip as a popover is placed and tells it which side it took (`RawTooltipPlacement.sideOf`), for a tail. Drive the tip's spring or fade from the animation `tooltipBuilder` gets. Put the `RawTooltip` in a `MergeSemantics`: `DesignTooltip` merged its message into the control's semantics node, and `RawTooltip` does not, so without it a screen reader hears the tip apart from the control. `dart fix` can't make this move either.
- A toggle button built with `RawButton` reads as a button that is selected, as `IconButton(isSelected:)` does: give it `semanticSelected`. `toggled` and `checked` are for a switch and a checkbox, which are not buttons. A `RawSegmentedButton` that allows many choices gives its items `semanticSelected`. Before, it gave them `toggled`, and a screen reader heard switches.
- In a scroll view, a mouse press shows as pressed at once. A touch or a stylus still waits `kPressTimeout`, in case it starts a scroll. A mouse waits too when the scroll view drags with a mouse (its `ScrollBehavior.dragDevices`).
- `DesignRadioGroup`, `RawSegmentedButton` (and so a segmented control) and `RawTabBar` answer the keys alike, through one implementation inside the package: one Tab stop on the chosen item (else the first enabled one), arrows that wrap and pass over items turned off, mirrored right to left. A `RawSegmentedButton` of one choice now moves and chooses with every arrow, as a radio group does; before, the arrows across it moved without choosing.
- `RawRovingFocusIntent` (with `RawRovingFocusMove`) is the move an arrow, Home or End makes in those groups. An `Actions` round a group with an action for it runs in place of the group's own, which is `Action.overridable`.
- A `RawBottomSheetRoute`'s barrier says "Dismiss", and a `RawSideSheetRoute`'s "Close sheet", only over the part of the screen the sheet leaves (above the sheet and the keyboard, beside a side sheet), as Material's modal bottom sheet does. Before, a screen reader outlined the whole window.
- A drag adds `WidgetState.dragged` beside `WidgetState.pressed` to the states a look draws for, as Flutter's `Slider` and `Scrollbar` do: a `DesignValueHandle` (and so a range slider's thumbs, a split view's divider and a colour slider), a `RawColorArea`'s thumb, a `RawScrollArea`'s thumb and a `RawPicker`'s column. A `RawBottomSheetDragHandle`'s states take it while a finger drags the sheet, as Material's sheet's drag handle does.
- `DesignValueHandle.statesController`: a caller's `WidgetStatesController` watches and drives a handle's states, as `RawButton.statesController` does a pressable's.

### The renames

| 0.3 name | 0.4 name |
|---|---|
| `DefaultDesignLocalizations` | `DefaultRawWidgetsLocalizations` |
| `DesignAnchoredOverlay` | `RawPopover` |
| `DesignBottomSheetBuilder` | `RawBottomSheetBuilder` |
| `DesignBottomSheetController` | `RawBottomSheetController` |
| `DesignBottomSheetDetails` | `RawBottomSheetDetails` |
| `DesignBottomSheetDragHandle` | `RawBottomSheetDragHandle` |
| `DesignBottomSheetRoute` | `RawBottomSheetRoute` |
| `DesignCalendar` | `RawCalendarDatePicker` |
| `DesignCalendarController` | `RawCalendarController` |
| `DesignCalendarDay` | `RawCalendarDayDetails` |
| `DesignCalendarDayBuilder` | `RawCalendarDayBuilder` |
| `DesignCalendarHeader` | `RawCalendarHeaderDetails` |
| `DesignCalendarMode` | `RawCalendarMode` |
| `DesignCarousel` | `RawCarousel` |
| `DesignCarouselControls` | `RawCarouselDetails` |
| `DesignColorArea` | `RawColorArea` |
| `DesignColorAreaDetails` | `RawColorAreaDetails` |
| `DesignColorChannel` | `RawColorChannel` |
| `DesignColorController` | `RawColorController` |
| `DesignColorPicker` | `RawColorPicker` |
| `DesignColorSlider` | `RawColorSlider` |
| `DesignCombobox` | `RawCombobox` |
| `DesignCommand` | `RawCommand` |
| `DesignCommandPalette` | `RawCommandPalette` |
| `DesignCommandShortcut` | `RawCommandShortcut` |
| `DesignContextMenu` | `RawContextMenu` |
| `DesignDataTable` | `RawDataTable` |
| `DesignDateField` | `RawDateField` |
| `DesignDateFieldFrameBuilder` | `RawDateFieldFrameBuilder` |
| `DesignDateLiteralBuilder` | `RawDateLiteralBuilder` |
| `DesignDateRange` | `RawDateRange` |
| `DesignDateSegmentBuilder` | `RawDateSegmentBuilder` |
| `DesignDateSegmentDetails` | `RawDateSegmentDetails` |
| `DesignDateSegmentType` | `RawDateSegmentType` |
| `DesignDialog` | `RawAlertDialog` |
| `DesignDialogAction` | `RawDialogAction` |
| `DesignDialogActionBuilder` | `RawDialogActionBuilder` |
| `DesignDialogActionDetails` | `RawDialogActionDetails` |
| `DesignDialogFrameDetails` | `RawAlertDialogFrameDetails` |
| `DesignDialogPartBuilder` | `RawAlertDialogPartBuilder` |
| `DesignDividerBuilder` | `RawDividerBuilder` |
| `DesignField` | `RawInputDecorator` |
| `DesignFieldBuilder` | `RawInputDecoratorBuilder` |
| `DesignFieldParts` | `RawInputDecoratorDetails` |
| `DesignListSurfaceBuilder` | `RawOptionsSurfaceBuilder` |
| `DesignLocalizations` | `RawWidgetsLocalizations` |
| `DesignMenuBar` | `RawMenuBar` |
| `DesignMenuEntry` | `RawMenuEntry` |
| `DesignMenuItemBuilder` | `RawMenuItemBuilder` |
| `DesignMenuLevel` | `RawMenuLevel` |
| `DesignMenuSurfaceBuilder` | `RawMenuBarOverlayBuilder` |
| `DesignNumberField` | `RawNumberField` |
| `DesignNumberFieldBuilder` | `RawNumberFieldBuilder` |
| `DesignNumberFieldButtonBuilder` | `RawNumberFieldButtonBuilder` |
| `DesignNumberFieldButtonDetails` | `RawNumberFieldButtonDetails` |
| `DesignNumberFieldDetails` | `RawNumberFieldDetails` |
| `DesignNumberFieldLayoutBuilder` | `RawNumberFieldLayoutBuilder` |
| `DesignOptionBuilder` | `RawOptionBuilder` |
| `DesignOtpContextMenuBuilder` | `RawOtpContextMenuBuilder` |
| `DesignOtpController` | `RawOtpController` |
| `DesignOtpField` | `RawOtpField` |
| `DesignOtpLayoutBuilder` | `RawOtpLayoutBuilder` |
| `DesignOtpSlot` | `RawOtpSlot` |
| `DesignOtpSlotBuilder` | `RawOtpSlotBuilder` |
| `DesignOverlayAlign` | `RawPopoverAlign` |
| `DesignOverlayInfo` | `RawPopoverInfo` |
| `DesignOverlayPadding` | `RawPopoverPadding` |
| `DesignOverlayPlacement` | `RawPopoverPlacement` |
| `DesignOverlaySide` | `RawPopoverSide` |
| `DesignOverlaySurfaceBuilder` | `RawPopoverOverlayBuilder` |
| `DesignOverlayTrigger` | `RawPopoverTrigger` |
| `DesignPaletteLayoutBuilder` | `RawPaletteLayoutBuilder` |
| `DesignPasswordController` | `RawPasswordController` |
| `DesignPasswordDetails` | `RawPasswordDetails` |
| `DesignPasswordReveal` | `RawPasswordReveal` |
| `DesignPressable` | `RawButton` |
| `DesignPressableBuilder` | `RawButtonBuilder` |
| `DesignPressableState` | `RawButtonState` |
| `DesignPullToRefresh` | `RawRefreshIndicator` |
| `DesignPullToRefreshState` | `RawRefreshIndicatorState` |
| `DesignRangeSlider` | `RawRangeSlider` |
| `DesignRangeTrack` | `RawRangeSliderTrackDetails` |
| `DesignRangeValues` | `RawRangeValues` |
| `DesignRating` | `RawRating` |
| `DesignRatingItemBuilder` | `RawRatingItemBuilder` |
| `DesignRatingItemDetails` | `RawRatingItemDetails` |
| `DesignRatingLayoutBuilder` | `RawRatingLayoutBuilder` |
| `DesignRefreshDetails` | `RawRefreshIndicatorDetails` |
| `DesignRefreshMode` | `RawRefreshIndicatorMode` |
| `DesignReorderItem` | `RawReorderItemDetails` |
| `DesignReorderableList` | `RawReorderableList` |
| `DesignScrollArea` | `RawScrollArea` |
| `DesignScrollThumb` | `RawScrollbarThumbDetails` |
| `DesignScrollbarBuilder` | `RawScrollbarThumbBuilder` |
| `DesignSearchError` | `RawSearchError` |
| `DesignSearchErrorBuilder` | `RawSearchErrorBuilder` |
| `DesignSelection` | `RawDataTableSelection` |
| `DesignSheetEdge` | `RawSheetEdge` |
| `DesignSheetInfo` | `RawSideSheetDetails` |
| `DesignSheetPageRoute` | `RawSheetRoute` |
| `DesignSideSheetRoute` | `RawSideSheetRoute` |
| `DesignSortDirection` | `RawSortDirection` |
| `DesignSplitAction` | `RawSplitAction` |
| `DesignSplitButton` | `RawSplitButton` |
| `DesignSplitPart` | `RawSplitPart` |
| `DesignSplitView` | `RawSplitView` |
| `DesignSwipeAction` | `RawSwipeAction` |
| `DesignSwipeActionBuilder` | `RawSwipeActionBuilder` |
| `DesignSwipeActionDetails` | `RawSwipeActionDetails` |
| `DesignSwipeActions` | `RawSwipeActions` |
| `DesignSwipeActionsController` | `RawSwipeActionsController` |
| `DesignSwipeBackPageTransitionsBuilder` | `SwipeBackPageTransitionsBuilder` |
| `DesignTab` | `RawTab` |
| `DesignTabBar` | `RawTabBar` |
| `DesignTabBuilder` | `RawTabBuilder` |
| `DesignTabController` | `RawTabController` |
| `DesignTabDetails` | `RawTabDetails` |
| `DesignTabIndicatorBuilder` | `RawTabIndicatorBuilder` |
| `DesignTabIndicatorDetails` | `RawTabIndicatorDetails` |
| `DesignTabView` | `RawTabBarView` |
| `DesignTableColumn` | `RawDataColumn` |
| `DesignTableController` | `RawDataTableController` |
| `DesignTableHeaderBuilder` | `RawDataTableHeaderBuilder` |
| `DesignTableRow` | `RawDataRowDetails` |
| `DesignTagBuilder` | `RawTagBuilder` |
| `DesignTagDetails` | `RawTagDetails` |
| `DesignTagInput` | `RawTagInput` |
| `DesignTagLayoutBuilder` | `RawTagLayoutBuilder` |
| `DesignTapTarget` | `TapTargetPadding` |
| `DesignTimeField` | `RawTimeField` |
| `DesignTimeOfDay` | `RawTimeOfDay` |
| `DesignToast` | `RawToast` |
| `DesignToastBuilder` | `RawToastBuilder` |
| `DesignToastClosedReason` | `RawToastClosedReason` |
| `DesignToastDetails` | `RawToastDetails` |
| `DesignToastHandle` | `RawToastController` |
| `DesignToastStackBuilder` | `RawToastStackBuilder` |
| `DesignToaster` | `RawToaster` |
| `DesignToasterState` | `RawToasterState` |
| `DesignToggleGroup` | `RawSegmentedButton` |
| `DesignToggleItemBuilder` | `RawSegmentBuilder` |
| `DesignWheelColumn` | `RawPickerColumn` |
| `DesignWheelColumnBuilder` | `RawPickerColumnBuilder` |
| `DesignWheelColumnDetails` | `RawPickerColumnDetails` |
| `DesignWheelItemBuilder` | `RawPickerItemBuilder` |
| `DesignWheelItemDetails` | `RawPickerItemDetails` |
| `DesignWheelPicker` | `RawPicker` |
| `RenderDesignTapTarget` | `RenderTapTargetPadding` |

## 0.3.4

- A checkbox, switch or radio built with `DesignPressable` exposes its checkable role by default. An ordinary button keeps its button role.
- A selectable `DesignDataTable` row exposes its checked state, including when the look adds a checkbox. Enter still opens a row with an activation callback.
- `DesignRadioGroup` gives custom radio faces a single Tab stop, arrow-key selection in reading order, wrapping, disabled-option skipping and right-to-left navigation. Pass each radio's existing focus node with `focusNodeFor` to preserve programmatic focus and its listeners.
- The package metadata links to the design systems documentation.

## 0.3.3

- A date or time field's segments wrap between parts when its frame is narrower than them, each segment kept with the separator after it, so no line starts with one. Right to left, a run of digits wraps left to right within itself. Segments that fit stay on one line, laid out as before.
- A key pressed with Control, Meta or Alt while a date or time segment has focus goes on to the app's shortcuts (Control-S, Command-K, Control-Z) instead of being typed. AltGr still types.
- A colour picker says its values in the reader's language and digits: the area says "Saturation 40%, Brightness 60%" with `DesignLocalizations`' channel names, list separator and percentages, the hue slider says degrees ("270°"), and the other sliders say percentages.
- Value handles format their spoken percentages in the current locale, including the next and previous values.
- A range slider announces the values each thumb can actually reach and offers adjustments only while there is room to move.
- The Ink proof example shows how to draw custom controls with a paper selector and a halftone wheel. Its widget tests can be adapted to another look.
- The example's chart and data table switch can be reached with Tab and activated with Enter or Space.
- A `DesignField` round a text entry and other controls (a search field's Search button, a clear button) says its label, help and error on the entry's node, as Material's `TextField` does, and each other control keeps its own node and name. Before, it said them on a node of its own round all of them.
- A `DesignNumberField`'s node spans the field but its step buttons (each cut away from the side of the entry it stands on), so a tap through the semantics tree on a step button reaches the button, not the number. Inside a `DesignField` it says the field's label, help and error itself, and the field says them on no other node.
- A `DesignPressable` turned off takes no tap and no long press, and offers a screen reader no long press.
- A state the widget brings to a `DesignPressable` (`selected`, turned off) reaches its controller's listeners and `onStatesChanged`, as a state the pointer brings does.
- A range slider whose drag is cancelled lets its thumb go: it is no longer drawn pressed, and `onChangeEnd` gets the values. A slider turned off mid-drag lets go without calling `onChangeEnd`.
- The inventory's Segmented control row names its behaviour, `DesignToggleGroup`: a segmented control is a toggle group of which one is chosen. An inventory page that prints a row's behaviour shows it.
- Docs: `DesignPressable` says how a small icon keeps its tap target (`DesignTapTarget`), and `DesignFormField` that it validates and registers but draws nothing, a `DesignField` built in its `builder` drawing the label, help and error.

## 0.3.2

- Focus shows as a browser's `:focus-visible` shows it. A dialog, sheet, menu or popover opened with a mouse, a touch or a screen reader still focuses its safe action or first control, so Enter, Tab and Escape work as before, but paints no focus until the next key press. Opened from the keyboard, it paints the focus at once. A mouse press anywhere hides a shown focus until the next key. Buttons, value handles, wheel pickers, colour areas, calendars, carousels, scroll areas, tooltips and hover cards follow it; text fields still show their focus on a click. An app that sets `FocusHighlightStrategy.alwaysTraditional` shows focus whatever the input, as before.
- A mouse over a value handle (a slider's or a colour slider's thumb, a knob) shows the grab cursor, and the grabbing cursor while it is dragged; a range slider's and a colour slider's track show the click cursor, and the grabbing cursor over the whole slider while a thumb moves; a wheel picker grabs and is grabbing while the mouse turns it; a split view's divider shows the resize cursor along its axis. A disabled one shows the basic arrow. A cursor a look passes still wins.
- Moving a calendar's keyboard focus to another day scrolls that day into view inside a scroll view, such as a date picker's popup.
- `DesignField` no longer makes one node of a group of controls. With `mergeSemantics` left null, the new default, a child that holds one control (a text field, a select, a switch, a slider) is still one node with the field's label, help and error. A child that holds several (a stepper's buttons and its field, segmented buttons, chips, radios) keeps each control's own node under the label, so a screen reader's tap, or a click on the web with semantics on, reaches the control under it. The label is not added again when the child already says it, as a stepper named as its field or a group that names itself does; a required field then says it is required at the start of its hint. `true` and `false` keep 0.3.1's behaviour.

## 0.3.1

- Escape dismisses a chart's hovered or touch-selected point while keyboard focus stays in place. A dialog or menu above the chart handles Escape first.
- Combobox and tag suggestions open on the side of the field with more space. Enter selects the highlighted suggestion on a hardware keyboard, including when the field already contains tags.
- Split-button menus keep their trailing alignment. Use `placement` to align the menu with the leading edge or choose a different side.
- Moving the pointer away from a menu bar clears its highlight immediately. The open menu still accepts keyboard input. Switching menus highlights the new title as soon as it opens.
- Buttons announce matching visible and supplied labels or values once. Additional text, such as a row subtitle, remains available to screen readers.
- Plain reorder handles accept keyboard focus. Press Alt+Up or Alt+Down to move the item and keep its focus.
- Number fields expose their configured minimum and maximum in Flutter semantics.
- Wheel pickers support mouse dragging. Ratings expose the pressed state on the item under the pointer.
- On compact screens, dialog actions share the row equally and stack when their labels need more space. Use `DesignDialog.actionWidgets` to supply custom actions.
- Use `DesignSheetPageRoute` for a full-screen sheet with native back navigation and reduced-motion support.
- Opening a bottom sheet from a focused control puts keyboard focus on its first action, or on the control with autofocus.
- Pass `divisions` to `DesignLinearScale.nice` for an exact number of chart intervals with a rounded domain.

## 0.3.0

Forty behaviours, up from 24. Overlays open at a point and keep clear of the on-screen keyboard, menus light one row,
and there are a context menu, a tooltip, shortcut labels and a search that may take time and fail. Routes add a dialog,
a bottom sheet, tabs, an adaptive shell and a list beside its detail, each moving on a spring, with F6 between panes.
Values add a wheel picker, date and time fields typed in segments, a number field, a rating and headless charts, with
numbers, dates and times in the reader's language, and haptics in one table. Every new word is in all 30 languages.
The checks a look's tests run moved to a package of their own, `ui_core_test`, so an app carries none of them.
It compiles on Flutter 3.50, where `RawDialogRoute` gained a `barrierBuilder` that the command palette's route
clashed with.

### Breaking

- `package:ui_core/alignment.dart` is removed: its 24 names (the alignment matrix and sheet, the text entry check,
  the screen checks and their results) moved, unchanged, to `ui_core_test`. Add `ui_core_test: ^0.1.0` to
  `dev_dependencies` and import `package:ui_core_test/ui_core_test.dart` in its place (see Tooling).
- `DesignSideSheetRoute.transitionDuration` is removed: the sheet moves on a spring. Give `dampingRatio` and
  `stiffness` (ζ 1, k 700 by default) in its place.
- `DesignLocalizations` has 59 new members, the new behaviours' words and the number, date and time formatters
  (`formatDecimal`, `parseDecimal`, `formatTimeOfDay` and the rest). A subclass of `DefaultDesignLocalizations` gets
  them, in English until it translates them; a class that implements `DesignLocalizations` itself must add them.

### Overlays
<!-- 0.3.0 overlays -->
- A surface opens at a point: `controller.open(position:)` on a `DesignAnchoredOverlay` (an offset in its anchor)
  places it below the point from its start in reading order, above it or towards its other end where there is no
  room, never under the point; `DesignOverlayInfo.position` says where. A list opened at a point does not take its
  anchor's width.
- Every anchored surface (menus, lists, popovers) keeps clear of the on-screen keyboard: one below a field the
  keyboard covers flips above it, and one open as the keyboard comes up moves. It reads the keyboard and the safe area
  from the overlay's own view, so a scaffold that took them out of its page no longer hides them. A look's own chrome
  over its pages (a desktop side bar) is kept clear of with `DesignOverlayPadding` round the pages.
- `DesignOverlayInfo.surfaceRect`: where the surface landed after any flip or shift, set as it is laid out, so a
  painter given it as its `repaint` points a tail or an arrow at the anchor from the first frame and follows it.
- A menu (`arrowKeyNavigation`) that a pointer opened starts with the focus on the surface itself and no item lit, as
  a clicked menu does on every desktop: Down then goes to the first item, Up to the last, Tab to the first and
  Shift+Tab to the last. Opened from the keys or by a screen reader, it starts on its first item as before. On the
  web with semantics on, a click arrives as a screen reader's tap: a mouse resting on the anchor makes it the
  pointer's. A look's test that tapped a menu open and expected its first item focused should press Down first.
- In a menubar's menus and a split button's menu the highlight follows the pointer (`highlightFollowsPointer`, new,
  true by default, as on every desktop): a pointer over an item moves the keys there, and one item is lit, the current
  one, hovered when the pointer moved last and focused when the keys did; no other item is hovered or focused, a
  disabled item under the pointer lights none, and the pointer leaving the menu lights none. A submenu a pointer opened
  lights none of its items, its own item staying selected. False keeps 0.2's states, each item's own. A look that
  drew the hover and the focus apart (Ledger's split menu) can drop its own bookkeeping, and one that left an item
  unlit until the first key after a pointer open (Comic's quiet menu) must: the menu surface now takes that first key
  itself, so a wrapper waiting for it never hears it and the next key is spent waking it.
- `DesignMenuSurfaceBuilder` names the menu panel builder's type (`DesignMenuBar.surfaceBuilder`'s, unchanged).
- `DesignContextMenu`, new: a menu of `DesignMenuEntry`s over a region, opened at the pointer by a right click or a
  long press of a finger (with `DesignHaptics.longPress`), at the focused widget by Shift+F10 or the Menu key, and by
  a screen reader's "Show menu" (a custom action, and the long press's hint). Its rows are the menubar's. On the web
  the browser's own menu stays shut while a pointer is over the region or pressed in it, focus is in it, or its menu
  is open, and is left alone when the app shut it itself. A region inside another opens alone. Focus goes back where
  it was, not to the region's first control.
- `DesignTooltip`, new: a message beside a control, shown after a pointer rests on it (`hoverDelay`), at once when it
  takes the keyboard's focus, and after a long press of a finger (with `DesignHaptics.longPress`; `triggerMode` takes
  Flutter's `TooltipTriggerMode`). As WCAG 1.4.13 asks: the pointer may move onto the tip, Escape hides it without
  moving the focus and goes no further, and it stays until the pointer or the focus leaves. One at a time, app-wide;
  the next shows at once within `DesignTooltip.warmUpDuration` (300 ms). A screen reader hears the message as the
  control's tooltip, in one node; the tip itself stays out of the tree. Its placement (above, centred, flipping below)
  and `surfaceRect` are the anchored overlay's; it fades on an effects spring. `DesignTooltip.dismissAll()` hides it.
- `designShortcutLabel` and `designShortcutKeys`, new: a `SingleActivator`'s or a `CharacterActivator`'s keys as
  Flutter's own menu rows (`MenuItemButton`) show them, for a look's `DesignMenuEntry.shortcut`: ⌃ ⌥ ⇧ ⌘ in Apple's
  order on macOS and iOS ("⇧ ⌘ N"), Alt, Ctrl, Win or Meta and Shift elsewhere ("Ctrl+Shift+N"), arrows and Enter as
  symbols, the other named keys in the reader's words. `appleSymbols: false` spells Apple's keys out
  ("Shift+Command+N") for a look whose font draws no ⌘. Fifteen key names are Material's own translations
  (`keyboardKeyControl`, `keyboardKeyMetaMacOs` and the rest, under Material's names); `keyboardKeyOption`,
  `keyboardKeyEnter` and `keyboardKeyTab` are ui_core's own, translated, awaiting a native speaker's check.
- A combobox's, a tag input's and a command palette's field takes Enter in its input's `onEditingComplete`
  (`onEditingComplete: field.submit`), never `onSubmitted`, as the docs and their examples now say: the field keeps
  the focus for the next words. With `onSubmitted`, Flutter restarts the text input's connection after Enter, and on
  the web the restarted input never takes the browser's focus, so letters stop reaching a field that still looks
  focused. A look that wired `onSubmitted` should move to `onEditingComplete`; nothing else changes.
- A combobox's and a tag input's `search` may take time and fail: `debounceDuration`, `loadingBuilder` and
  `errorBuilder`, new on both, null by default (0.2's behaviour). `debounceDuration` runs the search once typing
  rests, not at every letter. `loadingBuilder` paints the list's surface while a search is pending; a screen reader
  hears `loadingLabel` as it appears. `errorBuilder` paints a failed search with a way to try again
  (`DesignSearchError.retry`, lit while `focused`: Down moves the keys there and Enter runs it, the focus staying in
  the field); a screen reader hears `searchFailedMessage` ("Couldn't load results", new, ui_core's own, translated,
  awaiting a native speaker's check) as it appears. Only the latest words' result shows: a search that ends after a
  later one started is dropped, as is one pending when the list closes. A search that fails with no `errorBuilder`
  closes the list and goes to `FlutterError.reportError`, where 0.2 left an unhandled error.
<!-- 0.3.0 overlays end -->

### Routes
<!-- 0.3.0 routes -->
- A dialog route, `DesignDialogRoute`: it opens and closes on a spring (ζ 1, k 1400 by default; under Reduce Motion it
  fades), keeps Tab inside it and gives focus back to what opened it as it closes. Escape, Android's back, a barrier
  tap and its `close` go through `Navigator.maybePop`, so a `PopScope` may refuse them. An alert (`isAlert`) is heard as
  an alert dialog and its barrier does not close it; Escape does. `DesignDialog` lays out a title and words that scroll
  over actions that stay put, side by side at the end while they fit and stacked, the confirm on top, when they do
  not; focus opens on the safe action (`DesignDialog.safeActionIndex`). New words: `dialogLabel`, `alertDialogLabel`,
  `bottomSheetLabel`, `drawerLabel` and `tabLabel`, Flutter's own in every locale.
- A bottom sheet route, `DesignBottomSheetRoute`: it rises on a spring (ζ 1, k 700) and rests at one of its
  `snapSizes` (shares of the room above the on-screen keyboard), laid out at its size, or at its content's own
  height. A drag moves it with the finger; let go, it settles on the nearest size, or the next one a fling points to,
  and below half its smallest size, or flung down from it, it closes through `Navigator.maybePop` (a `PopScope` that
  refuses springs it back). The scroll view given `details.scrollController` hands drags over: up, the sheet grows to
  its largest size first; down with the content at its top, it shrinks. `DesignBottomSheetController` moves it from
  outside; `DesignBottomSheetDragHandle` is the handle's behaviour (a press to the next size, Up and Down, a screen
  reader's increase and decrease). It plays `thresholdCrossed` as a drag passes the point where letting go closes it
  and `selectionChanged` as a drag settles it on another size. New word: `dragHandleLabel`, in every locale.
- The side sheet (`DesignSideSheetRoute`) moves on the routes' spring: `dampingRatio` and `stiffness` (ζ 1, k 700 by
  default); a drag let go settles at its speed. `transitionDuration` is removed (see Breaking).
- Escape closes a dialog, a bottom sheet or a side sheet whose barrier does not dismiss however the focus sits. With
  nothing in it focused (the focus on the route's own scope, from the push until something in it takes the focus) it
  stopped at the barrier, as Flutter's own Escape does; a side sheet's stopped there wherever the focus was. A
  `PopScope` still refuses it. The command palette's barrier always dismisses, so its Escape already reached it.
- The dialog, bottom sheet and side sheet routes take a close token, `closeDampingRatio` and `closeStiffness`, so a
  look can close on a spring of its own (a quicker fall than the rise, or a slower one). Each defaults to the open
  token's, so a route that gives neither closes as before. Under Reduce Motion a close still fades, and a sheet
  dragged away carries the drag's speed into the close spring.
- Swipe rows (`DesignSwipeActions`) in one scroll view open one at a time: opening one closes the others, and the
  scroll view scrolling closes it (`closeOnScroll`, on by default). A `DesignSwipeActionsController` opens either side
  or closes it from outside and says whether it is open. The slide and the edge action's widening move on a spring
  (`dampingRatio`, `stiffness`; ζ 1, k 700), a let-go carrying its speed, and a full swipe plays `thresholdCrossed` as
  it arms.
- iOS's swipe back (`DesignSwipeBackPageTransitionsBuilder`) follows the finger from where it went down on a page that
  paints nothing at its leading edge. Before, the route's barrier held the gesture there until the drag passed its
  slop, and the page trailed the finger by it (18 px).
- A drag that leaves a sheet open, or a swipe back that leaves the page, gives the focus back to where it was inside
  it, and a swipe back that pops the page gives the page under it its focus, as a back button does. Flutter takes the
  focus out of every route while a drag or swipe runs and does not bring it back, so Escape and the keys went to the
  page under the sheet.
- Tabs: `DesignTabController`, `DesignTabBar` and `DesignTabView`, Material's three on the widgets layer. The bar is one
  tab stop; the arrows move along it (mirrored right to left, Up and Down when vertical), wrapping, Home and End, disabled
  tabs skipped, and choose as they move unless `selectionFollowsFocus` is false. Swiping the pages moves the selection
  (`controller.animation`), so the look's indicator (`indicatorBuilder`) and each tab's `selection` follow the finger;
  pages, indicator and a scrolling bar (`isScrollable`) settle on the controller's spring. A screen reader hears a tab
  bar of tabs, "Inbox, Tab 1 of 3", each controlling its page, a tab panel.
- A tab is laid out along the bar at the extent it was measured at (its share, or its own in a scrolling bar), never
  held at a size: a tab whose words grow where it stands (twice the text size, a tab renamed, the chosen tab's words
  turning bold as a tap or an arrow key chooses it) lays the bar out again rather than cutting its words or
  overflowing. Across the bar every tab's face stands as tall as the tallest face (as wide as the widest,
  in a column). A tab whose touch target (`DesignTapTarget`) stands larger than its face keeps the target as its hit
  area and the face at its own size in it, on both axes: a 32 high face in a 48 target was stretched to 48.
- The indicator is laid out in the selected tab's face (`DesignTabIndicatorDetails.rect`: what a touch target larger
  than the face holds, else the whole tab), the whole tab in `tabRect`, and is handed the selected tab's states
  (`states`: hovered, pressed, focused), so it can take the tab's hover and press inks. `indicatorPosition` paints it
  under the tabs (`DecorationPosition.background`, the default: a pill or a fill behind the words must not cover
  them) or over them (`foreground`: a line a tab's own fill would hide).
- An adaptive shell, `DesignAdaptiveShell`: the destinations in a bar along the bottom, a rail or a sidebar at the start
  by the shell's width (`DesignNavigationMode.fromWidth` on Material's window size classes, `DesignWindowSizeClass`), the
  body beside or above. The destinations are one tab stop with the tabs' arrow keys; Enter or Space chooses. A bar is a
  tab bar to a screen reader, a sidebar the "Navigation menu". A tab bar holds tabs and nothing else (Flutter fails one
  that holds anything else), so a look whose bar holds more than its destinations (a compose button beside them)
  places `DesignNavigationDetails.group` round the destinations alone, which is then the tab bar.
  `showNavigation: false` springs the bar away.
  `DesignAdaptiveShell.branches` gives each destination its own navigator, built when first shown and kept; choosing
  the selected one again pops it to its root, and back pops the selected branch, then goes where `backBehavior` says.
- A list and its detail, `DesignListDetail`: side by side from 840 wide (resizable with a `dividerBuilder`), else the
  list alone and the chosen item's detail pushed in the look's route, its pop clearing the choice. Crossing the width
  keeps the reader where they were.
- F6 and Shift+F6 move focus between panes: a shell's navigation and body, a list-detail's list and detail, and a
  shown `DesignToaster`'s toasts, landing where each pane last had focus. With no other pane about, a toaster's F6
  still goes to its newest toast.
<!-- 0.3.0 routes end -->

### Values
<!-- 0.3.0 values -->
- Haptics in one table, `DesignHaptics`: a step (`selectionChanged`), a long press (`longPress`) and a drag past its
  threshold (`thresholdCrossed`), each the platform's own feedback by default, swapped or silenced below a
  `DesignHapticsScope`. A slider's or a range slider's thumb plays a step as a drag crosses each division.
- A wheel picker, `DesignWheelPicker`: columns of rows that turn past a centre line, linked (the columns are a function
  of the selection, so a pick refills the others, February's days included), with rows that can't be chosen
  (`DesignWheelColumn.minIndex`, `maxIndex`, `isItemEnabled`) passed on to the nearest live one, looping columns, the
  keys (Up and Down, Page Up and Down, Home and End, typing a row's name, Left and Right between columns) and an
  adjustable node per column for a screen reader. Keys and a parent's new selection turn the wheels on a spring.
- Numbers, dates and times in the reader's language, on `DesignLocalizations`: `formatDecimal` and `parseDecimal`
  (German's `1.234,5`, India's `12,34,567`, Arabic's `١٬٢٣٤٫٥`; a grouping separator out of place does not read),
  `formatPercent`, `formatYear`, `formatShortMonth`, `formatShortMonthDay`, `formatTimeOfDay` (`DesignTimeOfDay`, a
  time with no date) and the fields' patterns, `dateFieldPattern` and `timeFieldPattern` (CLDR's yMd, jm, Hm). The
  symbols and patterns are CLDR's through package:intl's data, read when the translations are generated: no
  dependency on intl. With them 24 words: five of Material's, the segment names from CLDR, the empty segments'
  letters, and the rating's and the charts' (counts in each language's plural forms), the last 11 awaiting a native
  speaker's check.
- Date and time fields, `DesignDateField` and `DesignTimeField`: a date or a time typed segment by segment in the
  reader's order (`M/d/y`, `d.M.y`, `y/M/d`; `h:mm a`, `HH:mm`, Korean's `a h:mm`), each segment a tab stop and an
  adjustable node a screen reader steps and hears by name ("Month, November"). Digits, the reader's or ASCII, fill a
  segment and move on once no further digit fits; Up and Down step and wrap, Home and End go to the ends, Backspace
  clears and then moves back, Left and Right move as drawn, a typed separator moves on; a phone's keyboard types through
  one text input, a number pad but for AM/PM. A day past the month's end moves back to its last day; outside
  `firstDate` and `lastDate` the field reads as invalid and says so once. Right to left, a run of digits reads left to
  right, as a number does (Hebrew's `16.11.2026`, Arabic's `٣:٠٥`). With them `DesignLocalizations.formatMonth`, a
  month's standalone name, which a month segment's value speaks.
- A number field, `DesignNumberField`: a number typed in the reader's digits and separators (German's `1.234,5`,
  Arabic's `١٢`, or ASCII), taken on Enter (`onEditingComplete`: the focus stays), as the focus leaves or on a step,
  clamped to `min` and `max` and rounded to `fractionDigits` (by default the step's and `min`'s); text that does not
  read puts the last value back. A step goes to the next multiple of `step` (1 by default) counted from `min`, exactly
  in decimals; Up and Down step, Page Up and Down by `pageStep`, Home and End stay the caret's. Two step buttons
  (`buttonBuilder`, placed by `layoutBuilder`) step on a press and repeat while held; they are no tab stops and no
  nodes, as the field is adjustable itself. A whole step gets a number pad with no decimal key, a `min` of 0 or more
  no minus, and formatters keep out what can't become a number. The field's node takes its value from the input's; an
  input that says itself whether it is enabled (Material's `TextField`) stays a node of its own, so a look gives the
  value round it (`Semantics(value:)` on the field's text, as `DesignNumberField`'s docs show), or Flutter 3.47
  asserts that a node that steps has next and previous values but no value.
- A rating, `DesignRating`: a row of `itemCount` items filled up to a value, in whole steps or halves (`allowHalf`),
  a fraction shown as one. A tap sets the item tapped (a tap on the value already set changes nothing); hovering
  previews (`DesignRatingItemDetails.isPreview`); a drag sweeps across, changing the value as it goes, a step played at
  each, between `onChangeStart` and `onChangeEnd`. One tab stop: Right and Up step up, Left and Down down (mirrored
  right to left), End fills it, Home or 0 clears it, a digit sets that many; a screen reader hears a slider, "Rating,
  3 of 5", and steps it. `readOnly` shows a value (an average of 3.7): no input, no tab stop, not read as disabled.
- Charts, headless: the look draws every mark, axis and readout from the details it is handed. Scales with no
  widgets: `DesignLinearScale` (`.nice`: whole 1, 2 or 5 × 10ⁿ ticks), `DesignTimeScale` (ticks on calendar steps,
  seconds to centuries) and `DesignBandScale` (categories, `indexAt`), their ticks labelled in the reader's numbers and
  dates. `DesignChart` (line, area, bars, a sparkline; x as numbers, times or categories) and `DesignPieChart` (a pie or
  a donut) pick a point: a mouse the nearest along x, its series the nearest by y (a pie, the slice under it); a finger
  scrubs with a horizontal drag and a list still scrolls; a tap holds it until a tap elsewhere; one tab stop, Left and
  Right along x (mirrored right to left), Up and Down across series, Home, End and Escape. A screen reader hears the
  data in a sentence ("2 series, 12 points, January 2026 to December 2026, lowest 820, highest 1,640") or the picked
  point, steps through every point, and is offered "Show data table": `DesignChartTable`, the data as a table with
  its roles. New data springs from the values drawn, critically damped under Reduce Motion; x runs right to left in
  right-to-left text.
<!-- 0.3.0 values end -->

### Tooling
<!-- 0.3.0 tooling -->
- **Breaking: moved to ui_core_test.** The checks a design system's tests run, and the sheets that draw them for
  review, left `package:ui_core/alignment.dart` for a package of their own, `ui_core_test` (0.1.0, its versions its
  own), which a design system takes as a dev dependency, as an app takes flutter_test. An app compiles, analyzes and
  downloads none of it now: ui_core's library is about 9,700 lines smaller. `package:ui_core/alignment.dart` is gone,
  with no stand-in. To move: add `ui_core_test: ^0.1.0` to `dev_dependencies` (to a gallery example's
  `dependencies` when a page of it shows a sheet) and import `package:ui_core_test/ui_core_test.dart` where you
  imported `package:ui_core/alignment.dart`. The names are unchanged:
  - the alignment matrix: `DesignAlignmentMatrix`, `DesignAlignmentRow`, `DesignAlignmentEntry`,
    `DesignAlignmentBuilder`, `DesignAlignmentTheme`, `DesignInlineControl`, `DesignAlignmentSheet`;
  - the text entry check: `DesignTextEntryCheck`, `DesignTextEntryBuilder`;
  - the screen checks: `DesignKeylineCheck`, `DesignKeylineSheet`, `DesignLabelCheck`, `DesignRowCheck`,
    `DesignWidthCheck`, `DesignWidthLimit`, `DesignWidthKind`, `DesignWordBreakCheck`, `DesignClipCheck`,
    `DesignTapTargetCheck`, `DesignCursorCheck`, `DesignShadowClipCheck`, `DesignSpacingCheck`;
  - their results: `DesignAlignmentReport`, `DesignAlignmentError`.

  `DesignSpacing`, `DesignSpacingScope`, `DesignInput`, `DesignTapTargets` and `DesignTapTargetScope`, which
  `alignment.dart` also passed on, stay in `package:ui_core/ui_core.dart`. What a look's widgets wear for the checks
  stays too: `DesignCapCenter`, `DesignKeylineRegion` and `DesignKeylineFace`.
- `RenderDesignCapCenter`, `DesignCapCenter`'s render object, is public, as `RenderBaseline` is `Baseline`'s, so that
  a check in ui_core_test can find the cap center a label is drawn in and read its `capHeightFactor`.
<!-- 0.3.0 tooling end -->

## 0.2.1

- A menu or popover (`DesignAnchoredOverlay`) that its anchor opened gives focus back to the anchor as it closes
  (Escape, Android's back, a choice), even when a tap on the anchor left focus elsewhere. Before, focus went back to
  whatever held it before the tap: a combobox's field, say, whose list then opened again and held Android's next back,
  so the page did not pop.
- A combobox's or a tag input's list no longer opens on focus that ui_core gives back to its field (a popover the app
  opened, closing). Focus the user gives (a tap, Tab) opens it as before, and Down, a press or typing opens it at any
  time.
- Home and End in a menu or popover (`DesignAnchoredOverlay` with `arrowKeyNavigation`) focus its first or last item
  and keep it wholly in view, a lazy list run to that end first so the row is built; the item focused as it opens is
  kept in view too. Before, focus could land on a row scrolled out of sight, or, in a lazy list, on the last row built
  rather than the last item.
- Reduce Motion now includes iOS's. Flutter puts iOS's Reduce Motion in dart:ui's `AccessibilityFeatures.reduceMotion`,
  not `MediaQuery.disableAnimationsOf`, which is all ui_core read, so on an iPhone with Reduce Motion on, every spring
  ran as designed. A new read, `designReduceMotionOf(context)`, is true for Android's Remove animations, the web's
  `prefers-reduced-motion` and iOS's Reduce Motion. A widget that read it builds again when any of them changes.
  `DesignMotionPolicy.of` and every part that calms its motion (the carousel, side sheet, pull to refresh, command
  palette, scroll area, swipe actions and toasts) now read it. A look's own `MediaQuery.disableAnimationsOf` reads
  should move to it.

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
