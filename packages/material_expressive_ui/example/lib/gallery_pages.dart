// Generated from the gallery's manifest: every page of the gallery, in its order.
import 'package:flutter/widgets.dart';

import 'kit_gallery/demos/foundations.dart';
import 'kit_gallery/demos/inventory.dart';
import 'kit_gallery/demos/color.dart';
import 'kit_gallery/demos/type.dart';
import 'kit_gallery/demos/shape.dart';
import 'kit_gallery/demos/motion.dart';
import 'kit_gallery/demos/spacing.dart';
import 'kit_gallery/demos/icons.dart';
import 'kit_gallery/demos/elevation.dart';
import 'kit_gallery/demos/states.dart';
import 'kit_gallery/demos/host.dart';
import 'kit_gallery/demos/preview.dart';
import 'kit_gallery/demos/shell.dart';
import 'kit_gallery/demos/nav.dart';
import 'kit_gallery/demos/fab.dart';
import 'kit_gallery/demos/app_bar.dart';
import 'kit_gallery/demos/screen.dart';
import 'kit_gallery/demos/page.dart';
import 'kit_gallery/demos/buttons.dart';
import 'kit_gallery/demos/icon_buttons.dart';
import 'kit_gallery/demos/split_button.dart';
import 'kit_gallery/demos/toolbar.dart';
import 'kit_gallery/demos/text_fields.dart';
import 'kit_gallery/demos/select.dart';
import 'kit_gallery/demos/selection.dart';
import 'kit_gallery/demos/choice.dart';
import 'kit_gallery/demos/sliders.dart';
import 'kit_gallery/demos/pickers.dart';
import 'kit_gallery/demos/chips.dart';
import 'kit_gallery/demos/lists.dart';
import 'kit_gallery/demos/cards.dart';
import 'kit_gallery/demos/carousel.dart';
import 'kit_gallery/demos/table.dart';
import 'kit_gallery/demos/panes.dart';
import 'kit_gallery/demos/media.dart';
import 'kit_gallery/demos/content.dart';
import 'kit_gallery/demos/chart.dart';
import 'kit_gallery/demos/hero.dart';
import 'kit_gallery/demos/badge.dart';
import 'kit_gallery/demos/progress.dart';
import 'kit_gallery/demos/loading.dart';
import 'kit_gallery/demos/splash.dart';
import 'kit_gallery/demos/feedback.dart';
import 'kit_gallery/demos/sheet.dart';
import 'kit_gallery/demos/menus.dart';
import 'kit_gallery/demos/overlays.dart';
import 'kit_gallery/demos/toast.dart';

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
  (id: 'color', title: 'Colour', build: kitColorDemo),
  (id: 'type', title: 'Type', build: kitTypeDemo),
  (id: 'shape', title: 'Shape', build: kitShapeDemo),
  (id: 'motion', title: 'Motion', build: kitMotionDemo),
  (id: 'spacing', title: 'Spacing', build: kitSpacingDemo),
  (id: 'icons', title: 'Icons', build: kitIconsDemo),
  (id: 'elevation', title: 'Elevation', build: kitElevationDemo),
  (id: 'states', title: 'Interaction states', build: kitStatesDemo),
  (id: 'host', title: 'Host', build: kitHostDemo),
  (id: 'preview', title: 'Preview', build: kitPreviewDemo),
  (id: 'shell', title: 'Shell', build: kitShellDemo),
  (id: 'nav', title: 'Navigation', build: kitNavDemo),
  (id: 'fab', title: 'Floating action button', build: kitFabDemo),
  (id: 'app-bar', title: 'App bars', build: kitAppBarDemo),
  (id: 'screen', title: 'Screen', build: kitScreenDemo),
  (id: 'page', title: 'Page', build: kitPageDemo),
  (id: 'buttons', title: 'Buttons', build: kitButtonsDemo),
  (id: 'icon-buttons', title: 'Icon buttons', build: kitIconButtonsDemo),
  (id: 'split-button', title: 'Split button', build: kitSplitButtonDemo),
  (id: 'toolbar', title: 'Toolbars', build: kitToolbarDemo),
  (id: 'text-fields', title: 'Text fields', build: kitTextFieldsDemo),
  (id: 'select', title: 'Select', build: kitSelectDemo),
  (id: 'selection', title: 'Selection controls', build: kitSelectionDemo),
  (id: 'choice', title: 'Choice tiles', build: kitChoiceDemo),
  (id: 'sliders', title: 'Sliders', build: kitSlidersDemo),
  (id: 'pickers', title: 'Pickers', build: kitPickersDemo),
  (id: 'chips', title: 'Chips', build: kitChipsDemo),
  (id: 'lists', title: 'Lists', build: kitListsDemo),
  (id: 'cards', title: 'Cards', build: kitCardsDemo),
  (id: 'carousel', title: 'Carousel', build: kitCarouselDemo),
  (id: 'table', title: 'Table', build: kitTableDemo),
  (id: 'panes', title: 'Panes', build: kitPanesDemo),
  (id: 'media', title: 'Media', build: kitMediaDemo),
  (id: 'content', title: 'Content', build: kitContentDemo),
  (id: 'chart', title: 'Chart', build: kitChartDemo),
  (id: 'hero', title: 'Hero', build: kitHeroDemo),
  (id: 'badge', title: 'Badges', build: kitBadgeDemo),
  (id: 'progress', title: 'Progress', build: kitProgressDemo),
  (id: 'loading', title: 'Loading indicator', build: kitLoadingDemo),
  (id: 'splash', title: 'Splash', build: kitSplashDemo),
  (id: 'feedback', title: 'Feedback', build: kitFeedbackDemo),
  (id: 'sheet', title: 'Sheet', build: kitSheetDemo),
  (id: 'menus', title: 'Menus', build: kitMenusDemo),
  (id: 'overlays', title: 'Overlays', build: kitOverlaysDemo),
  (id: 'toast', title: 'Toast', build: kitToastDemo),
];
