// Generated from the gallery's manifest: every page of the gallery, in its order.
import 'package:flutter/widgets.dart';

import 'kit_gallery/demos/foundations.dart';
import 'kit_gallery/demos/page.dart';
import 'kit_gallery/demos/app_frame.dart';
import 'kit_gallery/demos/navigation.dart';
import 'kit_gallery/demos/actions.dart';
import 'kit_gallery/demos/entry.dart';
import 'kit_gallery/demos/choices.dart';
import 'kit_gallery/demos/search.dart';
import 'kit_gallery/demos/errors.dart';
import 'kit_gallery/demos/answers.dart';
import 'kit_gallery/demos/content.dart';
import 'kit_gallery/demos/tables.dart';
import 'kit_gallery/demos/history.dart';
import 'kit_gallery/demos/overlays.dart';
import 'kit_gallery/demos/permits.dart';
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
  (id: 'page', title: 'Top bar & page', build: kitPageDemo),
  (id: 'app-frame', title: 'The app\'s frame', build: kitAppFrameDemo),
  (id: 'navigation', title: 'Navigation & tabs', build: kitNavigationDemo),
  (id: 'actions', title: 'Buttons & links', build: kitActionsDemo),
  (id: 'entry', title: 'Text, dates & files', build: kitEntryDemo),
  (
    id: 'choices',
    title: 'Radios, checkboxes, select & switch',
    build: kitChoicesDemo,
  ),
  (id: 'search', title: 'Search & pagination', build: kitSearchDemo),
  (id: 'errors', title: 'Error summary', build: kitErrorsDemo),
  (id: 'answers', title: 'Answers summary', build: kitAnswersDemo),
  (id: 'content', title: 'Rows, tags, insets & panels', build: kitContentDemo),
  (id: 'tables', title: 'Tables', build: kitTablesDemo),
  (
    id: 'history',
    title: 'Timeline, empty & loading states',
    build: kitHistoryDemo,
  ),
  (id: 'overlays', title: 'Dialog & toast', build: kitOverlaysDemo),
  (id: 'permits', title: 'Brindlemere parking permits', build: kitPermitsDemo),
  (id: 'inventory', title: 'The component inventory', build: kitInventoryDemo),
];
