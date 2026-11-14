// Generated from the gallery's manifest: every page of the gallery, in its order.
import 'package:flutter/widgets.dart';

import 'kit_gallery/demos/foundations.dart';
import 'kit_gallery/demos/frames.dart';
import 'kit_gallery/demos/chrome.dart';
import 'kit_gallery/demos/controls.dart';
import 'kit_gallery/demos/entries.dart';
import 'kit_gallery/demos/pickers.dart';
import 'kit_gallery/demos/moves.dart';
import 'kit_gallery/demos/raised.dart';
import 'kit_gallery/demos/holds.dart';
import 'kit_gallery/demos/rows.dart';
import 'kit_gallery/demos/tell.dart';
import 'kit_gallery/demos/shows.dart';
import 'kit_gallery/demos/ornaments.dart';
import 'kit_gallery/demos/dial.dart';
import 'kit_gallery/demos/relief.dart';
import 'kit_gallery/demos/charts.dart';
import 'kit_gallery/demos/day.dart';
import 'kit_gallery/demos/actions.dart';
import 'kit_gallery/demos/fields.dart';
import 'kit_gallery/demos/collections.dart';
import 'kit_gallery/demos/overlays.dart';
import 'kit_gallery/demos/records.dart';
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
  (id: 'frames', title: 'Slabs, wells and heads', build: kitFramesDemo),
  (id: 'chrome', title: 'Screen, rail and pictures', build: kitChromeDemo),
  (id: 'controls', title: 'Buttons, latches, fields', build: kitControlsDemo),
  (
    id: 'entries',
    title: 'Search, codes and typed choices',
    build: kitEntriesDemo,
  ),
  (id: 'pickers', title: 'Dates and times', build: kitPickersDemo),
  (id: 'moves', title: 'Views and sequences', build: kitMovesDemo),
  (
    id: 'raised',
    title: 'Dialogs, sheets, menus and notices',
    build: kitRaisedDemo,
  ),
  (id: 'holds', title: 'Groups and records', build: kitHoldsDemo),
  (id: 'rows', title: 'Rows, lists and figures', build: kitRowsDemo),
  (id: 'tell', title: 'Status and progress', build: kitTellDemo),
  (id: 'shows', title: 'People and portraits', build: kitShowsDemo),
  (id: 'ornaments', title: 'Lamps and marks', build: kitOrnamentsDemo),
  (id: 'dial', title: 'Fluted dials and knobs', build: kitDialDemo),
  (id: 'relief', title: 'The relief', build: kitReliefDemo),
  (id: 'charts', title: 'Charts in wells', build: kitChartsDemo),
  (id: 'day', title: 'The day, the month, the bank', build: kitDayDemo),
  (
    id: 'actions',
    title: 'Groups of buttons, toggles and keys',
    build: kitActionsDemo,
  ),
  (
    id: 'fields',
    title: 'Passwords, groups, combos and colours',
    build: kitFieldsDemo,
  ),
  (
    id: 'collections',
    title: 'Tables, trees and lists that move',
    build: kitCollectionsDemo,
  ),
  (
    id: 'overlays',
    title: 'Popovers, menus, palettes and toasts',
    build: kitOverlaysDemo,
  ),
  (
    id: 'records',
    title: 'Timelines, terms, meters and status',
    build: kitRecordsDemo,
  ),
  (
    id: 'inventory',
    title: 'Every component, row by row',
    build: kitInventoryDemo,
  ),
];
