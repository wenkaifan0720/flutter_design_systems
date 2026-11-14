// Generated from the gallery's manifest: every page of the gallery, in its order.
import 'package:flutter/widgets.dart';

import 'kit_gallery/demos/foundations.dart';
import 'kit_gallery/demos/frames.dart';
import 'kit_gallery/demos/chrome.dart';
import 'kit_gallery/demos/controls.dart';
import 'kit_gallery/demos/rows.dart';
import 'kit_gallery/demos/print.dart';
import 'kit_gallery/demos/speech.dart';
import 'kit_gallery/demos/people.dart';
import 'kit_gallery/demos/charts.dart';
import 'kit_gallery/demos/panels.dart';
import 'kit_gallery/demos/cover.dart';
import 'kit_gallery/demos/raised.dart';
import 'kit_gallery/demos/complete.dart';
import 'kit_gallery/demos/inventory.dart';

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
  (id: 'frames', title: 'Panels, tiers and captions', build: kitFramesDemo),
  (id: 'chrome', title: 'Screen, bars and pictures', build: kitChromeDemo),
  (
    id: 'controls',
    title: 'Buttons, fields and choices',
    build: kitControlsDemo,
  ),
  (id: 'rows', title: 'Rows, lists and figures', build: kitRowsDemo),
  (
    id: 'print',
    title: 'The print: dots, lines and lettering',
    build: kitPrintDemo,
  ),
  (id: 'speech', title: 'Balloons, bursts and stamps', build: kitSpeechDemo),
  (id: 'people', title: 'The cast', build: kitPeopleDemo),
  (id: 'charts', title: 'Numbers in print', build: kitChartsDemo),
  (id: 'panels', title: 'Panels that carry something', build: kitPanelsDemo),
  (id: 'cover', title: 'The cover and the splash', build: kitCoverDemo),
  (
    id: 'raised',
    title: 'Dialogs, sheets, menus and announcements',
    build: kitRaisedDemo,
  ),
  (
    id: 'complete',
    title: 'Navigation, reading, status and people',
    build: kitCompleteDemo,
  ),
  (
    id: 'inventory',
    title: 'Everything else an app reaches for',
    build: kitInventoryDemo,
  ),
];
