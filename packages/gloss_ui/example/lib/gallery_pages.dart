// Generated from the gallery's manifest: every page of the gallery, in its order.
import 'package:flutter/widgets.dart';

import 'kit_gallery/demos/foundations.dart';
import 'kit_gallery/demos/buttons.dart';
import 'kit_gallery/demos/fields.dart';
import 'kit_gallery/demos/choices.dart';
import 'kit_gallery/demos/pickers.dart';
import 'kit_gallery/demos/lists.dart';
import 'kit_gallery/demos/display.dart';
import 'kit_gallery/demos/navigation.dart';
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
  (
    id: 'foundations',
    title: 'Glazes, type, depths and the light',
    build: kitFoundationsDemo,
  ),
  (
    id: 'buttons',
    title: 'Gel keys, pearl keys and beads',
    build: kitButtonsDemo,
  ),
  (id: 'fields', title: 'Fields and selects', build: kitFieldsDemo),
  (
    id: 'choices',
    title: 'Sockets, slots, troughs and steppers',
    build: kitChoicesDemo,
  ),
  (
    id: 'pickers',
    title: 'Drums, calendars and the colour well',
    build: kitPickersDemo,
  ),
  (id: 'lists', title: 'Wells, rows and cards', build: kitListsDemo),
  (
    id: 'display',
    title: 'Tables, tags, faces and timelines',
    build: kitDisplayDemo,
  ),
  (
    id: 'navigation',
    title: 'Bars, tabs and navigation',
    build: kitNavigationDemo,
  ),
  (id: 'overlays', title: 'Dialogs, sheets and toasts', build: kitOverlaysDemo),
  (
    id: 'feedback',
    title: 'Banners, states and progress',
    build: kitFeedbackDemo,
  ),
  (id: 'charts', title: 'Charts in gel', build: kitChartsDemo),
];
