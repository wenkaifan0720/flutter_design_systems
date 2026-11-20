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
    title: 'Palette, type, the clay and its motion',
    build: kitFoundationsDemo,
  ),
  (
    id: 'buttons',
    title: 'Coral keys, clay keys, balls and groups',
    build: kitButtonsDemo,
  ),
  (
    id: 'fields',
    title: 'Wells, selects, steppers and tags',
    build: kitFieldsDemo,
  ),
  (
    id: 'choices',
    title: 'Cups, grooves, switches, chips and sliders',
    build: kitChoicesDemo,
  ),
  (
    id: 'pickers',
    title: 'Calendars, wheels and the colour well',
    build: kitPickersDemo,
  ),
  (
    id: 'lists',
    title: 'Slabs of rows, cards, tables and trees',
    build: kitListsDemo,
  ),
  (
    id: 'display',
    title: 'Disclosures, tables, faces, tags and meters',
    build: kitDisplayDemo,
  ),
  (
    id: 'navigation',
    title: 'Bars, the dock, rails, sidebars, tabs and wayfinding',
    build: kitNavigationDemo,
  ),
  (
    id: 'overlays',
    title: 'Dialogs, sheets, toasts, menus and popovers',
    build: kitOverlaysDemo,
  ),
  (
    id: 'feedback',
    title: 'Progress, banners and states',
    build: kitFeedbackDemo,
  ),
  (id: 'charts', title: 'Charts in clay', build: kitChartsDemo),
];
