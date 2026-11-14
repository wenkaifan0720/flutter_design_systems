// Generated from the gallery's manifest: every page of the gallery, in its order.
import 'package:flutter/widgets.dart';

import 'kit_gallery/demos/foundations.dart';
import 'kit_gallery/demos/frames.dart';
import 'kit_gallery/demos/chrome.dart';
import 'kit_gallery/demos/controls.dart';
import 'kit_gallery/demos/rows.dart';
import 'kit_gallery/demos/objects.dart';
import 'kit_gallery/demos/lists.dart';
import 'kit_gallery/demos/charts.dart';
import 'kit_gallery/demos/raised.dart';
import 'kit_gallery/demos/entries.dart';
import 'kit_gallery/demos/complete.dart';
import 'kit_gallery/demos/coverage.dart';
import 'kit_gallery/demos/ordinary.dart';

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
    title: 'Type, colour and the page frame',
    build: kitFoundationsDemo,
  ),
  (
    id: 'frames',
    title: 'Windows, alerts and the desktop',
    build: kitFramesDemo,
  ),
  (id: 'chrome', title: 'Screen, bars and pictures', build: kitChromeDemo),
  (
    id: 'controls',
    title: 'Buttons, fields and choices',
    build: kitControlsDemo,
  ),
  (id: 'rows', title: 'Rows, facts and figures', build: kitRowsDemo),
  (id: 'objects', title: 'Objects and heroes', build: kitObjectsDemo),
  (id: 'lists', title: 'Lists, tables and folders', build: kitListsDemo),
  (id: 'charts', title: 'Charts and gauges', build: kitChartsDemo),
  (id: 'raised', title: 'Dialogs, sheets and menus', build: kitRaisedDemo),
  (id: 'entries', title: 'Search, choices and dates', build: kitEntriesDemo),
  (
    id: 'complete',
    title: 'Navigation, feedback and display',
    build: kitCompleteDemo,
  ),
  (id: 'coverage', title: 'The rest of the set', build: kitCoverageDemo),
  (id: 'ordinary', title: 'Everyday applications', build: kitOrdinaryDemo),
];
