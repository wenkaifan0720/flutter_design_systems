// Generated from the gallery's manifest: every page of the gallery, in its order.
import 'package:flutter/widgets.dart';

import 'kit_gallery/demos/foundations.dart';
import 'kit_gallery/demos/buttons.dart';
import 'kit_gallery/demos/fields.dart';
import 'kit_gallery/demos/choices.dart';
import 'kit_gallery/demos/pickers.dart';
import 'kit_gallery/demos/lists.dart';
import 'kit_gallery/demos/blocks.dart';
import 'kit_gallery/demos/navigation.dart';
import 'kit_gallery/demos/app.dart';
import 'kit_gallery/demos/overlays.dart';
import 'kit_gallery/demos/feedback.dart';
import 'kit_gallery/demos/charts.dart';

/// One page of the gallery: its title and the screen it shows, by day or by night.
typedef GalleryPage = ({
  String id,
  String title,
  Widget Function(Brightness) build,
});

/// Every page, in the gallery's order.
const List<GalleryPage> galleryPages = [
  (id: 'foundations', title: 'Type and colour', build: kitFoundationsDemo),
  (id: 'buttons', title: 'Buttons', build: kitButtonsDemo),
  (id: 'fields', title: 'Text fields', build: kitFieldsDemo),
  (id: 'choices', title: 'Selection', build: kitChoicesDemo),
  (id: 'pickers', title: 'Pickers', build: kitPickersDemo),
  (id: 'lists', title: 'Lists and tables', build: kitListsDemo),
  (id: 'blocks', title: 'Cards and media', build: kitBlocksDemo),
  (id: 'navigation', title: 'Navigation', build: kitNavigationDemo),
  (id: 'app', title: 'App frame', build: kitAppDemo),
  (id: 'overlays', title: 'Dialogs and sheets', build: kitOverlaysDemo),
  (id: 'feedback', title: 'Feedback', build: kitFeedbackDemo),
  (id: 'charts', title: 'Charts', build: kitChartsDemo),
];
