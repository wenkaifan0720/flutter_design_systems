// Generated from the gallery's manifest: every page of the gallery, in its order.
import 'package:flutter/widgets.dart';

import 'kit_gallery/demos/foundations.dart';
import 'kit_gallery/demos/buttons.dart';
import 'kit_gallery/demos/fields.dart';
import 'kit_gallery/demos/choices.dart';
import 'kit_gallery/demos/controls.dart';
import 'kit_gallery/demos/pickers.dart';
import 'kit_gallery/demos/lists.dart';
import 'kit_gallery/demos/display.dart';
import 'kit_gallery/demos/feedback.dart';
import 'kit_gallery/demos/charts.dart';
import 'kit_gallery/demos/navigation.dart';
import 'kit_gallery/demos/app.dart';
import 'kit_gallery/demos/overlays.dart';

/// One page of the gallery: its title and the screen it shows, by day or by night.
typedef GalleryPage = ({
  String id,
  String title,
  Widget Function(Brightness) build,
});

/// Every page, in the gallery's order.
const List<GalleryPage> galleryPages = [
  (
    id: 'foundations',
    title: 'Metal, glass and light',
    build: kitFoundationsDemo,
  ),
  (id: 'buttons', title: 'Keys', build: kitButtonsDemo),
  (id: 'fields', title: 'Text fields, selects and entry', build: kitFieldsDemo),
  (id: 'choices', title: 'Switches and choices', build: kitChoicesDemo),
  (id: 'controls', title: 'Faders, knobs and meters', build: kitControlsDemo),
  (
    id: 'pickers',
    title: 'Calendars, wheels and pickers',
    build: kitPickersDemo,
  ),
  (id: 'lists', title: 'Lists, tables and panes', build: kitListsDemo),
  (id: 'display', title: 'Plates, portholes and glass', build: kitDisplayDemo),
  (id: 'feedback', title: 'Lamps and progress', build: kitFeedbackDemo),
  (id: 'charts', title: 'Scope charts', build: kitChartsDemo),
  (id: 'navigation', title: 'Navigation', build: kitNavigationDemo),
  (id: 'app', title: 'App frame', build: kitAppDemo),
  (
    id: 'overlays',
    title: 'Dialogs, sheets, menus and popovers',
    build: kitOverlaysDemo,
  ),
];
