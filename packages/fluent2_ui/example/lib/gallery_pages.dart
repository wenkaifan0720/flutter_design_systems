// Generated from the gallery's manifest: every page of the gallery, in its order.
import 'package:flutter/widgets.dart';

import 'kit_gallery/demos/app_overview.dart';
import 'kit_gallery/demos/app_files.dart';
import 'kit_gallery/demos/app_request.dart';
import 'kit_gallery/demos/app_settings.dart';
import 'kit_gallery/demos/foundations.dart';
import 'kit_gallery/demos/preview.dart';
import 'kit_gallery/demos/top_bar.dart';
import 'kit_gallery/demos/sheet.dart';
import 'kit_gallery/demos/dialog.dart';
import 'kit_gallery/demos/menu.dart';
import 'kit_gallery/demos/states.dart';
import 'kit_gallery/demos/buttons.dart';
import 'kit_gallery/demos/people.dart';
import 'kit_gallery/demos/selection.dart';
import 'kit_gallery/demos/slider.dart';
import 'kit_gallery/demos/inputs.dart';
import 'kit_gallery/demos/forms.dart';
import 'kit_gallery/demos/date.dart';
import 'kit_gallery/demos/composer.dart';
import 'kit_gallery/demos/card.dart';
import 'kit_gallery/demos/lists.dart';
import 'kit_gallery/demos/tabs.dart';
import 'kit_gallery/demos/toolbar.dart';
import 'kit_gallery/demos/accordion.dart';
import 'kit_gallery/demos/table.dart';
import 'kit_gallery/demos/image.dart';
import 'kit_gallery/demos/action_bar.dart';
import 'kit_gallery/demos/swipe.dart';
import 'kit_gallery/demos/pattern_list_section.dart';
import 'kit_gallery/demos/badges.dart';
import 'kit_gallery/demos/message_bar.dart';
import 'kit_gallery/demos/progress.dart';
import 'kit_gallery/demos/popover.dart';
import 'kit_gallery/demos/stats.dart';
import 'kit_gallery/demos/week.dart';
import 'kit_gallery/demos/charts.dart';
import 'kit_gallery/demos/actions.dart';
import 'kit_gallery/demos/entries.dart';
import 'kit_gallery/demos/navigation.dart';
import 'kit_gallery/demos/raised.dart';
import 'kit_gallery/demos/collections.dart';
import 'kit_gallery/demos/inventory.dart';

/// One page of the gallery: its title and the screen it shows, by day or by night.
typedef GalleryPage = ({
  String id,
  String title,
  Widget Function(Brightness) build,
});

/// Every page, in the gallery's order.
const List<GalleryPage> galleryPages = [
  (id: 'app-overview', title: 'Northwind · Home', build: kitAppOverviewDemo),
  (id: 'app-files', title: 'Northwind · Files', build: kitAppFilesDemo),
  (
    id: 'app-request',
    title: 'Northwind · New request',
    build: kitAppRequestDemo,
  ),
  (
    id: 'app-settings',
    title: 'Northwind · Settings',
    build: kitAppSettingsDemo,
  ),
  (id: 'foundations', title: 'Foundations', build: kitFoundationsDemo),
  (id: 'preview', title: 'Host, materials & preview', build: kitPreviewDemo),
  (id: 'top-bar', title: 'Top bar & screen', build: kitTopBarDemo),
  (id: 'sheet', title: 'Sheet & drawer', build: kitSheetDemo),
  (id: 'dialog', title: 'Dialog', build: kitDialogDemo),
  (id: 'menu', title: 'Menu', build: kitMenuDemo),
  (id: 'states', title: 'States, spinner & toast', build: kitStatesDemo),
  (id: 'buttons', title: 'Buttons', build: kitButtonsDemo),
  (id: 'people', title: 'Avatar, presence & persona', build: kitPeopleDemo),
  (
    id: 'selection',
    title: 'Checkbox, radio, switch & segmented',
    build: kitSelectionDemo,
  ),
  (id: 'slider', title: 'Slider, spin button & rating', build: kitSliderDemo),
  (
    id: 'inputs',
    title: 'Input, search, dropdown, tag picker & link',
    build: kitInputsDemo,
  ),
  (id: 'forms', title: 'Field, label & form section', build: kitFormsDemo),
  (id: 'date', title: 'Date picker & calendar', build: kitDateDemo),
  (id: 'composer', title: 'Composer', build: kitComposerDemo),
  (id: 'card', title: 'Card', build: kitCardDemo),
  (id: 'lists', title: 'Lists', build: kitListsDemo),
  (id: 'tabs', title: 'Tabs & breadcrumb', build: kitTabsDemo),
  (id: 'toolbar', title: 'Toolbar & divider', build: kitToolbarDemo),
  (id: 'accordion', title: 'Accordion & tree', build: kitAccordionDemo),
  (id: 'table', title: 'Table & properties', build: kitTableDemo),
  (id: 'image', title: 'Image', build: kitImageDemo),
  (id: 'action-bar', title: 'Action bar', build: kitActionBarDemo),
  (id: 'swipe', title: 'Swipe actions', build: kitSwipeDemo),
  (
    id: 'pattern-list-section',
    title: 'List section',
    build: kitPatternListSectionDemo,
  ),
  (id: 'badges', title: 'Badges & tags', build: kitBadgesDemo),
  (id: 'message-bar', title: 'Message bar', build: kitMessageBarDemo),
  (id: 'progress', title: 'Progress & skeleton', build: kitProgressDemo),
  (id: 'popover', title: 'Tooltip & popover', build: kitPopoverDemo),
  (id: 'stats', title: 'Stats & tiles', build: kitStatsDemo),
  (id: 'week', title: 'Week strip', build: kitWeekDemo),
  (id: 'charts', title: 'Charts', build: kitChartsDemo),
  (id: 'actions', title: 'Shortcuts', build: kitActionsDemo),
  (id: 'entries', title: 'Passwords, ranges & times', build: kitEntriesDemo),
  (
    id: 'navigation',
    title: 'Rail, pages, steps & commands',
    build: kitNavigationDemo,
  ),
  (
    id: 'raised',
    title: 'Bottom sheet, action sheet & popover',
    build: kitRaisedDemo,
  ),
  (
    id: 'collections',
    title: 'Tables, panes, carousels & history',
    build: kitCollectionsDemo,
  ),
  (
    id: 'inventory',
    title: 'Every component, row by row',
    build: kitInventoryDemo,
  ),
];
