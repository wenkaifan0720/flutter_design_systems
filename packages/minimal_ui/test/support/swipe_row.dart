import 'package:material_ui/material_ui.dart';
import 'package:minimal_ui/minimal_host.dart';

/// A 44 px row the swipe tests drag.
Widget swipeRow(String name, {VoidCallback? onTap}) => GestureDetector(
  onTap: onTap,
  child: SizedBox(
    height: MinimalChromeMetrics.row,
    child: Align(alignment: Alignment.centerLeft, child: Text(name)),
  ),
);
