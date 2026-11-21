# The inventory, in build order

ui_core's component checklist (`package:ui_core/inventory.dart`) names every
component an ordinary app expects from a design system: one
`DesignInventoryRow` each, grouped as Actions, Inputs, Navigation, Containers,
Overlays, Feedback and Charts. A complete look answers every row: a live
specimen for each part it carries, or the reason it deliberately leaves the
part out.

A row's id is a label for the thing (Material's name where Material has one,
shadcn's where only shadcn does), not a name the look must use. Each look
names its own parts and designs their API for its own language. The **In**
column says which references carry the part (M Material, C Cupertino, S
shadcn); a part all three carry is one nobody will forgive missing. **Build
on** names the ui_core or Flutter API the part paints. A part drawn by the
look still takes its press from `RawButton` wherever it acts.

The checklist itself is outside semantic versioning: rows can be added in any
ui_core release. Read `DesignInventoryRow.all` from the version you depend on;
`DesignInventory.verify()` names any row the look has not answered.

## What every part carries

- **Every state it has**: rest, hover, focus, pressed, disabled, and where
  they apply selected, error and busy; day and night; each different from
  rest, each change animated on the look's springs.
- **Its tap target**: at least 44 by 44 for touch and 24 by 24 for a pointer,
  the same box a screen reader outlines.
- **Its semantics**: the role, name, value and state Flutter's own widget
  gives (see [contract.md](contract.md)).
- **Its keys**: Tab reaches it; Enter and Space act; arrows move inside it if
  it holds several things.
- **Every size and reader**: 390, 768, 1024 and 1440 wide; right to left;
  twice the text size; Reduce Motion.
- **Its specimen**: a gallery tile and an inventory entry, and a widget test.

Absent rows need a designer's reason, written for the person choosing the
look: "Material vocabulary; the page's main action sits in its top bar" is a
reason. "Not built yet" is not, and `DesignInventory` rejects it.

## Stage 1: the parts that set the system

Build these first, in this order. They fix the control height, the label's
place, focus, press and disabled, the field, and the raised surface; every
later part reuses what they decide.

| Row id | What it is | In | Build on |
|---|---|---|---|
| `Button` | Button (filled/outlined/text/danger) | MCS | `RawButton` |
| `IconButton` | Icon button | MCS | `RawButton` |
| `Link` | Link | S | `RawButton(link: true)` |
| `TextField` | Text field | MCS | `TextField`, `DesignTextEntryBox` |
| `FormField` | Form + field (label, help, error) | MCS | `RawInputDecorator` |
| `Checkbox` | Checkbox | MCS | `RawButton(checked:, mixed:)` |
| `RadioGroup` | Radio group | MCS | `RadioGroup`, `RawRadio`, `RadioGroupKeyboardFix` |
| `Switch` | Switch | MCS | `RawButton(toggled:)` |
| `Tooltip` | Tooltip | MS | `RawTooltip`, `RawTooltipPlacement`, `RawTooltipFocusFix` |
| `Dialog` | Dialog / alert dialog | MCS | `DesignDialogRoute`, `RawAlertDialog` |

## Stage 2: actions

The rest of what a person presses. A toggle group whose choice is single is the segmented control (an input); a split button is two presses in one face, each with its own focus.

| Row id | What it is | In | Build on |
|---|---|---|---|
| `FloatingActionButton` | Floating action button (+extended, menu) | M | drawn by the look |
| `ButtonGroup` | Button group / toolbar | MS | drawn by the look |
| `ToggleGroup` | Toggle button / toggle group | MS | `RawSegmentedButton` |
| `SplitButton` | Split button | M | `RawSplitButton` |
| `Kbd` | Keyboard key (Kbd) | S | drawn by the look |

## Stage 3: inputs

Each input stands at the control height, takes the field's rule and its focus treatment, and reads its words from the theme. A select, a combobox and a multi-select stand on the text field's face and end in one sign that they open a list; their lists share one surface and one row (see [contract.md](contract.md), "Lists, selects and menus"). Pickers (date, time, colour) open on the look's own popover or sheet, where their whole height fits, and fit a 390-wide phone. A chip that acts is a `RawButton`; a removable chip's remove key is its own target.

| Row id | What it is | In | Build on |
|---|---|---|---|
| `TextArea` | Text area | S | `TextField`, `DesignTextEntryBox(maxLines:)` |
| `SearchField` | Search field / search bar | MC | `TextField`, `DesignTextEntryBox` |
| `PasswordField` | Password field (reveal) | S | `RawPasswordReveal` |
| `InputGroup` | Input group (prefix/suffix add-ons) | S | `DesignInputGroup` |
| `InputOtp` | OTP / PIN code | S | `RawOtpField` |
| `NumberField` | Number field / quantity stepper | – | `RawNumberField` |
| `Select` | Select / dropdown | MS | `RawPopover`, `RawButton` |
| `Combobox` | Combobox / autocomplete | MS | `RawCombobox` |
| `MultiSelect` | Multi-select / tag input | – | `RawTagInput` |
| `Slider` | Slider | MCS | `DesignValueHandle` |
| `RangeSlider` | Range slider | M | `RawRangeSlider` |
| `SegmentedButton` | Segmented control | MC | `RawSegmentedButton` |
| `Chip` | Chips (filter/choice/input) | M | `RawButton` |
| `Rating` | Rating | – | `RawRating` |
| `FileUpload` | File upload / drop zone | – | drawn by the look |
| `DatePicker` | Date picker | MCS | drawn by the look |
| `DateRangePicker` | Date range picker | M | `RawCalendarDatePicker` |
| `TimePicker` | Time picker | MCS | `RawTimeField` |
| `Calendar` | Inline calendar | MS | `RawCalendarDatePicker` |
| `WheelPicker` | Wheel picker | C | `RawPicker` |
| `ColorPicker` | Color picker | – | `RawColorPicker` |

## Stage 4: navigation

`DesignAdaptiveShell` switches between a bottom bar at phone widths, a rail at tablet widths and a sidebar on desktop; the look paints each. Tabs, menubar and command palette take arrows, Home and End through their ui_core APIs.

| Row id | What it is | In | Build on |
|---|---|---|---|
| `AppBar` | App bar (incl. large/collapsing) | MC | drawn by the look |
| `NavigationBar` | Bottom navigation bar | MC | `DesignAdaptiveShell` |
| `NavigationRail` | Navigation rail | M | `DesignAdaptiveShell` |
| `NavigationDrawer` | Navigation drawer / sidebar | MS | `DesignAdaptiveShell` |
| `TabBar` | Tabs | MCS | `RawTabBar` |
| `Breadcrumb` | Breadcrumbs | S | drawn by the look |
| `Pagination` | Pagination | S | drawn by the look |
| `StepProgress` | Step progress / wizard | M | drawn by the look |
| `PageDots` | Page indicator dots | – | drawn by the look |
| `MenuBar` | Menubar (desktop) | MS | `RawMenuBar` |
| `Command` | Command palette | S | `RawCommandPalette` |
| `Scaffold` | Adaptive app shell / scaffold | MC | `DesignAdaptiveShell` |

## Stage 5: containers

Rows and cards that act are `RawButton`s with the row's whole face as the target. A data table's form must survive 390 px wide. A grouped list's corners are concentric with its card's.

| Row id | What it is | In | Build on |
|---|---|---|---|
| `Card` | Card | MCS | `RawButton` where it acts |
| `ListTile` | List row / list tile | MCS | `RawButton` where it acts |
| `ListSection` | Grouped / inset list | C | drawn by the look |
| `SectionHeader` | Section header | C | drawn by the look |
| `Disclosure` | Accordion / expansion / collapsible | MCS | `RawButton(expanded:)` |
| `Table` | Table | MS | drawn by the look |
| `DataTable` | Data table (sort, select, paginate) | MS | `RawDataTableController` |
| `Divider` | Divider / separator | MCS | drawn by the look |
| `ScrollArea` | Scroll area / scrollbar | MCS | `RawScrollArea` |
| `Resizable` | Resizable panels / split view | S | `RawSplitView` |
| `CarouselView` | Carousel | MS | `RawCarousel` |
| `ReorderableListView` | Reorderable list | M | `RawReorderableList` |
| `SwipeActions` | Swipe actions / dismissible | C | `RawSwipeActions` |
| `RefreshIndicator` | Pull to refresh | MC | `RawRefreshIndicator` |
| `TreeView` | Tree view | – | `DesignTree` |
| `Timeline` | Timeline | – | drawn by the look |
| `Avatar` | Avatar | MS | drawn by the look |
| `AvatarGroup` | Avatar group / face pile | – | drawn by the look |
| `Badge` | Badge (count) | MS | drawn by the look |
| `Tag` | Tag / label pill | S | drawn by the look |
| `Media` | Image / media with fallback | – | drawn by the look |
| `EmptyState` | Empty state | S | drawn by the look |
| `DescriptionList` | Key-value / description list | – | drawn by the look |

## Stage 6: overlays

Each raised part has its own `show<Look>…` function or widget that owns its route or overlay, scrim, motion, dismissal and focus return. Android back closes the top overlay before it pops the page. A menu's rows are the select's rows, its destructive items (`RawMenuEntry.isDestructiveAction`) in the look's destructive tone; a dialog takes a list of actions.

| Row id | What it is | In | Build on |
|---|---|---|---|
| `BottomSheet` | Bottom sheet / modal sheet | MCS | `RawBottomSheetRoute` |
| `Sheet` | Side sheet / drawer overlay | MS | `RawSideSheetRoute` |
| `ActionSheet` | Action sheet | C | drawn by the look |
| `Popover` | Popover | S | `RawPopover` |
| `HoverCard` | Hover card | S | `RawPopover` |
| `Menu` | Menu / context menu | MCS | `RawContextMenu`, `RawPopover`, `RawMenuEntry` |
| `SnackBar` | Toast / snackbar (stacking) | MS | `RawToaster` |
| `Banner` | Banner / inline alert | MS | drawn by the look |

## Stage 7: feedback

Progress and spinners stop moving under Reduce Motion (a static or pulsing state the look chooses). Status views (loading, error, success, empty) are pages a part can stand in, and siblings: one frame and layout, told apart by glyph, words and tone.

| Row id | What it is | In | Build on |
|---|---|---|---|
| `LinearProgressIndicator` | Linear progress | MCS | drawn by the look |
| `CircularProgressIndicator` | Circular progress / spinner | MCS | drawn by the look |
| `Skeleton` | Skeleton | S | drawn by the look |
| `StatusView` | Loading / error / success states | – | drawn by the look |
| `Meter` | Meter / gauge | – | drawn by the look |

## Stage 8: charts

`DesignChart` and `DesignPieChart` carry scales, hit testing, keyboard inspection and semantics; the look paints marks, axes and the tooltip, passes the app's `formatX` and `formatY` through (units, the locale's digits), and draws an all-zero series on ui_core's 0 to 4 scale.

| Row id | What it is | In | Build on |
|---|---|---|---|
| `LineChart` | Line chart | – | `DesignChart` |
| `BarChart` | Bar chart | – | `DesignChart` |
| `AreaChart` | Area chart | – | `DesignChart` |
| `PieChart` | Donut / pie | – | `DesignPieChart` |
| `Sparkline` | Sparkline | – | `DesignChart` |


## Answering the inventory

```dart
final DesignInventory lookInventory = DesignInventory(
  look: 'Look',
  entries: [
    DesignInventoryEntry.present(
      'Button',
      (context) => LookButton('Save', onPressed: () {}),
    ),
// ...
    const DesignInventoryEntry.absent(
      'FloatingActionButton',
```

The look's test calls `lookInventory.verify()`, which fails on any row that
is missing, any entry for an unknown row, and any reason that only says the
part is not built. The gallery lists the same inventory with
`DesignInventoryGallery`, so a person choosing the look sees every part it
has and the reason for every part it does not.
