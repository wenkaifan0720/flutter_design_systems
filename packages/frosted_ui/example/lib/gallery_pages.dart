// Generated from the gallery's manifest: every page of the gallery, in its order.
import 'package:flutter/widgets.dart';

import 'kit_gallery/demos/foundations.dart';
import 'kit_gallery/demos/preview.dart';
import 'kit_gallery/demos/top_bar.dart';
import 'kit_gallery/demos/sheet.dart';
import 'kit_gallery/demos/menu.dart';
import 'kit_gallery/demos/states.dart';
import 'kit_gallery/demos/controls.dart';
import 'kit_gallery/demos/wordmark.dart';
import 'kit_gallery/demos/money.dart';
import 'kit_gallery/demos/marks.dart';
import 'kit_gallery/demos/structure.dart';
import 'kit_gallery/demos/charts.dart';
import 'kit_gallery/demos/tabs.dart';
import 'kit_gallery/demos/slider.dart';
import 'kit_gallery/demos/dialog.dart';
import 'kit_gallery/demos/action_bar.dart';
import 'kit_gallery/demos/composer.dart';
import 'kit_gallery/demos/sign_in.dart';
import 'kit_gallery/demos/swipe.dart';
import 'kit_gallery/demos/image.dart';
import 'kit_gallery/demos/week.dart';
import 'kit_gallery/demos/inputs.dart';
import 'kit_gallery/demos/selection.dart';
import 'kit_gallery/demos/forms.dart';
import 'kit_gallery/demos/meters.dart';
import 'kit_gallery/demos/card.dart';
import 'kit_gallery/demos/progress.dart';
import 'kit_gallery/demos/hold.dart';
import 'kit_gallery/demos/move.dart';
import 'kit_gallery/demos/raise.dart';
import 'kit_gallery/demos/actions.dart';
import 'kit_gallery/demos/choices.dart';
import 'kit_gallery/demos/pickers.dart';
import 'kit_gallery/demos/list_section.dart';
import 'kit_gallery/demos/entry.dart';
import 'kit_gallery/demos/combobox.dart';
import 'kit_gallery/demos/toggle.dart';
import 'kit_gallery/demos/calendar.dart';
import 'kit_gallery/demos/color_picker.dart';
import 'kit_gallery/demos/popover.dart';
import 'kit_gallery/demos/command.dart';
import 'kit_gallery/demos/data.dart';
import 'kit_gallery/demos/scroll.dart';
import 'kit_gallery/demos/inventory.dart';

/// One page of the gallery: its title and the screen it shows, by day or by night.
typedef GalleryPage = ({
  String id,
  String title,
  Widget Function(Brightness) build,
});

/// Every page, in the gallery's order.
const List<GalleryPage> galleryPages = [
  (id: 'foundations', title: 'Foundations', build: kitFoundationsDemo),
  (id: 'preview', title: 'App host and preview', build: kitPreviewDemo),
  (id: 'top-bar', title: 'Top bar and screen', build: kitTopBarDemo),
  (id: 'sheet', title: 'Bottom sheets', build: kitSheetDemo),
  (id: 'menu', title: 'Menus', build: kitMenuDemo),
  (id: 'states', title: 'States and toasts', build: kitStatesDemo),
  (id: 'controls', title: 'Buttons', build: kitControlsDemo),
  (id: 'wordmark', title: 'Wordmark', build: kitWordmarkDemo),
  (id: 'money', title: 'Money and numbers', build: kitMoneyDemo),
  (id: 'marks', title: 'Icons, chips and people', build: kitMarksDemo),
  (id: 'structure', title: 'Tiles and list rows', build: kitStructureDemo),
  (id: 'charts', title: 'Charts', build: kitChartsDemo),
  (id: 'tabs', title: 'Tabs', build: kitTabsDemo),
  (id: 'slider', title: 'Sliders', build: kitSliderDemo),
  (id: 'dialog', title: 'Dialogs', build: kitDialogDemo),
  (id: 'action-bar', title: 'Action bar', build: kitActionBarDemo),
  (id: 'composer', title: 'Message composer', build: kitComposerDemo),
  (id: 'sign-in', title: 'Sign-in buttons', build: kitSignInDemo),
  (id: 'swipe', title: 'Swipe actions', build: kitSwipeDemo),
  (id: 'image', title: 'Images', build: kitImageDemo),
  (id: 'week', title: 'Week strip', build: kitWeekDemo),
  (id: 'inputs', title: 'Text fields and search', build: kitInputsDemo),
  (
    id: 'selection',
    title: 'Segmented buttons, chips and switches',
    build: kitSelectionDemo,
  ),
  (id: 'forms', title: 'Settings and forms', build: kitFormsDemo),
  (id: 'meters', title: 'Meters and budget bars', build: kitMetersDemo),
  (id: 'card', title: 'Cards and goals', build: kitCardDemo),
  (id: 'progress', title: 'Progress and skeletons', build: kitProgressDemo),
  (id: 'hold', title: 'Expansion, tables and timelines', build: kitHoldDemo),
  (
    id: 'move',
    title: 'Navigation rail, breadcrumbs and pagination',
    build: kitMoveDemo,
  ),
  (id: 'raise', title: 'Snack bars and action sheets', build: kitRaiseDemo),
  (
    id: 'actions',
    title: 'Button groups and keyboard keys',
    build: kitActionsDemo,
  ),
  (
    id: 'choices',
    title: 'Radios, chips, rating and upload',
    build: kitChoicesDemo,
  ),
  (id: 'pickers', title: 'Select and date pickers', build: kitPickersDemo),
  (id: 'list-section', title: 'List sections', build: kitListSectionDemo),
  (id: 'entry', title: 'Password, code and form fields', build: kitEntryDemo),
  (id: 'combobox', title: 'Combobox and multi-select', build: kitComboboxDemo),
  (
    id: 'toggle',
    title: 'Toggle buttons and split button',
    build: kitToggleDemo,
  ),
  (id: 'calendar', title: 'Calendar and date range', build: kitCalendarDemo),
  (id: 'color-picker', title: 'Color picker', build: kitColorPickerDemo),
  (id: 'popover', title: 'Popover and hover card', build: kitPopoverDemo),
  (id: 'command', title: 'Menu bar and command palette', build: kitCommandDemo),
  (id: 'data', title: 'Data table and tree', build: kitDataDemo),
  (
    id: 'scroll',
    title: 'Scrolling, split view, carousel, reorder and refresh',
    build: kitScrollDemo,
  ),
  (id: 'inventory', title: 'Inventory', build: kitInventoryDemo),
];
