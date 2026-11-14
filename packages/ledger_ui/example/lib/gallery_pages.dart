// Generated from the gallery's manifest: every page of the gallery, in its order.
import 'package:flutter/widgets.dart';

import 'kit_gallery/demos/foundations.dart';
import 'kit_gallery/demos/preview.dart';
import 'kit_gallery/demos/top_bar.dart';
import 'kit_gallery/demos/sheet.dart';
import 'kit_gallery/demos/states.dart';
import 'kit_gallery/demos/money.dart';
import 'kit_gallery/demos/controls.dart';
import 'kit_gallery/demos/structure.dart';
import 'kit_gallery/demos/marks.dart';
import 'kit_gallery/demos/register.dart';
import 'kit_gallery/demos/inputs.dart';
import 'kit_gallery/demos/goals.dart';
import 'kit_gallery/demos/gauge.dart';
import 'kit_gallery/demos/charts.dart';
import 'kit_gallery/demos/engravings.dart';
import 'kit_gallery/demos/receipt.dart';
import 'kit_gallery/demos/card.dart';
import 'kit_gallery/demos/notice.dart';
import 'kit_gallery/demos/slips.dart';
import 'kit_gallery/demos/choices.dart';
import 'kit_gallery/demos/selection.dart';
import 'kit_gallery/demos/commit.dart';
import 'kit_gallery/demos/entry.dart';
import 'kit_gallery/demos/rolls.dart';

/// One page of the gallery: its title and the screen it shows, by day or by night.
typedef GalleryPage = ({
  String id,
  String title,
  Widget Function(Brightness) build,
});

/// Every page, in the gallery's order.
const List<GalleryPage> galleryPages = [
  (id: 'foundations', title: 'Foundations', build: kitFoundationsDemo),
  (id: 'preview', title: 'Host & preview', build: kitPreviewDemo),
  (id: 'top-bar', title: 'Top bar & screen', build: kitTopBarDemo),
  (id: 'sheet', title: 'Sheet', build: kitSheetDemo),
  (id: 'states', title: 'States & toast', build: kitStatesDemo),
  (id: 'money', title: 'Money', build: kitMoneyDemo),
  (id: 'controls', title: 'Buttons, marks & the seal', build: kitControlsDemo),
  (
    id: 'structure',
    title: 'Heads, rows, facts & notes',
    build: kitStructureDemo,
  ),
  (
    id: 'marks',
    title: 'Glyphs, monograms, date tabs, pills & tags',
    build: kitMarksDemo,
  ),
  (id: 'register', title: 'The register & the bills', build: kitRegisterDemo),
  (
    id: 'inputs',
    title: 'Chips, filters, switches, fields & the stepper',
    build: kitInputsDemo,
  ),
  (id: 'goals', title: 'Goals & categories', build: kitGoalsDemo),
  (
    id: 'gauge',
    title: 'Gauges, the stack bar & chart keys',
    build: kitGaugeDemo,
  ),
  (id: 'charts', title: 'Charts', build: kitChartsDemo),
  (id: 'engravings', title: 'Engravings', build: kitEngravingsDemo),
  (id: 'receipt', title: 'Receipts & the cheque', build: kitReceiptDemo),
  (id: 'card', title: 'Card faces', build: kitCardDemo),
  (id: 'notice', title: 'Notifications & effects', build: kitNoticeDemo),
  (id: 'slips', title: 'Slips & memos', build: kitSlipsDemo),
  (
    id: 'choices',
    title: 'Menus, choices & the member card',
    build: kitChoicesDemo,
  ),
  (
    id: 'selection',
    title: 'Chips, checks, sliders & tabs',
    build: kitSelectionDemo,
  ),
  (id: 'commit', title: 'Dialog, action bar & composer', build: kitCommitDemo),
  (id: 'entry', title: 'Search entry & dates', build: kitEntryDemo),
  (id: 'rolls', title: 'Stacks, weeks & counters', build: kitRollsDemo),
];
