import 'package:minimal_ui/minimal_ui.dart';

/// An orders table's columns: id, customer, quantity, due time and status.
const orderColumns = [
  MinimalColumn('#', width: 54, mono: true, sortable: true),
  MinimalColumn('Customer'),
  MinimalColumn('Qty', width: 38, numeric: true, sortable: true),
  MinimalColumn('Due', width: 56, numeric: true, sortable: true),
  MinimalColumn('Status', width: 84, alignEnd: true),
];

/// Two rows of [orderColumns].
const orderRows = [
  MinimalTableRow([
    MinimalCell('1047'),
    MinimalCell('Hanna Berg', strong: true),
    MinimalCell('3'),
    MinimalCell('09:30'),
    MinimalCell.badge('Late', tone: MinimalTone.warning),
  ]),
  MinimalTableRow([
    MinimalCell('1045'),
    MinimalCell('Café Morgen', strong: true),
    MinimalCell('24'),
    MinimalCell('10:00'),
    MinimalCell.badge('Baking', tone: MinimalTone.primary),
  ]),
];
