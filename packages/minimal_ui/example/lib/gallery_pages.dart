// Generated from the gallery's manifest: every page of the gallery, in its order.
import 'package:flutter/widgets.dart';

import 'kit_gallery/demos/foundations.dart';
import 'kit_gallery/demos/inventory.dart';
import 'kit_gallery/demos/preview.dart';
import 'kit_gallery/demos/shell.dart';
import 'kit_gallery/demos/top_bar.dart';
import 'kit_gallery/demos/action_bar.dart';
import 'kit_gallery/demos/navigation.dart';
import 'kit_gallery/demos/menu_bar.dart';
import 'kit_gallery/demos/button.dart';
import 'kit_gallery/demos/button_group.dart';
import 'kit_gallery/demos/toggle_split.dart';
import 'kit_gallery/demos/toggle_check.dart';
import 'kit_gallery/demos/slider_stepper.dart';
import 'kit_gallery/demos/range_color.dart';
import 'kit_gallery/demos/radio_rating.dart';
import 'kit_gallery/demos/segmented_tabs.dart';
import 'kit_gallery/demos/chips.dart';
import 'kit_gallery/demos/input.dart';
import 'kit_gallery/demos/input_group.dart';
import 'kit_gallery/demos/combobox.dart';
import 'kit_gallery/demos/text_area.dart';
import 'kit_gallery/demos/pickers.dart';
import 'kit_gallery/demos/time_wheel.dart';
import 'kit_gallery/demos/calendar.dart';
import 'kit_gallery/demos/search.dart';
import 'kit_gallery/demos/selection.dart';
import 'kit_gallery/demos/swipe.dart';
import 'kit_gallery/demos/composer.dart';
import 'kit_gallery/demos/sign_in.dart';
import 'kit_gallery/demos/filters.dart';
import 'kit_gallery/demos/cards.dart';
import 'kit_gallery/demos/disclosure.dart';
import 'kit_gallery/demos/list_rows.dart';
import 'kit_gallery/demos/identity.dart';
import 'kit_gallery/demos/media.dart';
import 'kit_gallery/demos/carousel.dart';
import 'kit_gallery/demos/stats.dart';
import 'kit_gallery/demos/series_charts.dart';
import 'kit_gallery/demos/feedback.dart';
import 'kit_gallery/demos/status.dart';
import 'kit_gallery/demos/kpi.dart';
import 'kit_gallery/demos/table.dart';
import 'kit_gallery/demos/data_table.dart';
import 'kit_gallery/demos/panes.dart';
import 'kit_gallery/demos/list_behaviours.dart';
import 'kit_gallery/demos/properties.dart';
import 'kit_gallery/demos/activity.dart';
import 'kit_gallery/demos/sheet.dart';
import 'kit_gallery/demos/overlays.dart';
import 'kit_gallery/demos/states.dart';
import 'kit_gallery/demos/notices.dart';
import 'kit_gallery/demos/dialog.dart';
import 'kit_gallery/demos/command.dart';
import 'kit_gallery/demos/screen_today.dart';
import 'kit_gallery/demos/screen_habit.dart';
import 'kit_gallery/demos/screen_new_habit.dart';
import 'kit_gallery/demos/screen_orders.dart';
import 'kit_gallery/demos/screen_issues.dart';

/// One page of the gallery: its title and the screen it shows, by day or by night.
typedef GalleryPage = ({
  String id,
  String title,
  Widget Function(Brightness) build,
});

/// Every page, in the gallery's order.
const List<GalleryPage> galleryPages = [
  (id: 'foundations', title: 'Foundations', build: kitFoundationsDemo),
  (id: 'inventory', title: 'Inventory', build: kitInventoryDemo),
  (id: 'preview', title: 'Host and preview', build: kitPreviewDemo),
  (id: 'shell', title: 'Shell & routes', build: kitShellDemo),
  (id: 'top-bar', title: 'Top bar & screen', build: kitTopBarDemo),
  (id: 'action-bar', title: 'Action bar', build: kitActionBarDemo),
  (id: 'navigation', title: 'Rail, sidebar, pages', build: kitNavigationDemo),
  (id: 'menu-bar', title: 'Menu bar', build: kitMenuBarDemo),
  (id: 'button', title: 'Button', build: kitButtonDemo),
  (id: 'button-group', title: 'Button group & link', build: kitButtonGroupDemo),
  (
    id: 'toggle-split',
    title: 'Toggle group & split button',
    build: kitToggleSplitDemo,
  ),
  (id: 'toggle-check', title: 'Toggle & check', build: kitToggleCheckDemo),
  (
    id: 'slider-stepper',
    title: 'Slider, stepper, counter',
    build: kitSliderStepperDemo,
  ),
  (
    id: 'range-color',
    title: 'Range slider & colour picker',
    build: kitRangeColorDemo,
  ),
  (id: 'radio-rating', title: 'Radio & rating', build: kitRadioRatingDemo),
  (
    id: 'segmented-tabs',
    title: 'Segmented & tabs',
    build: kitSegmentedTabsDemo,
  ),
  (id: 'chips', title: 'Chips', build: kitChipsDemo),
  (id: 'input', title: 'Input & form', build: kitInputDemo),
  (
    id: 'input-group',
    title: 'Input group & form field',
    build: kitInputGroupDemo,
  ),
  (id: 'combobox', title: 'Combobox & multi-select', build: kitComboboxDemo),
  (id: 'text-area', title: 'Text area & file upload', build: kitTextAreaDemo),
  (id: 'pickers', title: 'Pickers & menu', build: kitPickersDemo),
  (id: 'time-wheel', title: 'Time & wheel pickers', build: kitTimeWheelDemo),
  (id: 'calendar', title: 'Calendar & date range', build: kitCalendarDemo),
  (id: 'search', title: 'Search', build: kitSearchDemo),
  (id: 'selection', title: 'Selection', build: kitSelectionDemo),
  (id: 'swipe', title: 'Swipe', build: kitSwipeDemo),
  (id: 'composer', title: 'Composer', build: kitComposerDemo),
  (id: 'sign-in', title: 'Sign-in', build: kitSignInDemo),
  (id: 'filters', title: 'Filter bar', build: kitFiltersDemo),
  (id: 'cards', title: 'Cards & sections', build: kitCardsDemo),
  (id: 'disclosure', title: 'Disclosure & divider', build: kitDisclosureDemo),
  (id: 'list-rows', title: 'List rows', build: kitListRowsDemo),
  (id: 'identity', title: 'Tags, avatars, tiles', build: kitIdentityDemo),
  (id: 'media', title: 'Media & reveal', build: kitMediaDemo),
  (id: 'carousel', title: 'Carousel', build: kitCarouselDemo),
  (id: 'stats', title: 'Stats, progress, charts', build: kitStatsDemo),
  (id: 'series-charts', title: 'Line, area, donut', build: kitSeriesChartsDemo),
  (
    id: 'feedback',
    title: 'Spinner, skeleton, meter, badge',
    build: kitFeedbackDemo,
  ),
  (id: 'status', title: 'Status & group headers', build: kitStatusDemo),
  (id: 'kpi', title: 'KPIs & heatmap', build: kitKpiDemo),
  (id: 'table', title: 'Table', build: kitTableDemo),
  (id: 'data-table', title: 'Data table', build: kitDataTableDemo),
  (id: 'panes', title: 'Scroll area & resizable', build: kitPanesDemo),
  (
    id: 'list-behaviours',
    title: 'Reorder, refresh, tree',
    build: kitListBehavioursDemo,
  ),
  (
    id: 'properties',
    title: 'Properties & breadcrumb',
    build: kitPropertiesDemo,
  ),
  (id: 'activity', title: 'Activity & code', build: kitActivityDemo),
  (id: 'sheet', title: 'Sheet', build: kitSheetDemo),
  (
    id: 'overlays',
    title: 'Side sheet, popover, hover card',
    build: kitOverlaysDemo,
  ),
  (id: 'states', title: 'States & toast', build: kitStatesDemo),
  (
    id: 'notices',
    title: 'Tooltip, banner, action sheet',
    build: kitNoticesDemo,
  ),
  (id: 'dialog', title: 'Dialog', build: kitDialogDemo),
  (id: 'command', title: 'Command palette', build: kitCommandDemo),
  (id: 'screen-today', title: 'Today', build: kitScreenTodayDemo),
  (id: 'screen-habit', title: 'Habit', build: kitScreenHabitDemo),
  (id: 'screen-new-habit', title: 'New habit', build: kitScreenNewHabitDemo),
  (id: 'screen-orders', title: 'Orders', build: kitScreenOrdersDemo),
  (id: 'screen-issues', title: 'Issues', build: kitScreenIssuesDemo),
];
