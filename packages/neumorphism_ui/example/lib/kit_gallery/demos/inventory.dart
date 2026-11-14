/// The whole component inventory, row by row.
library;

import 'package:flutter/widgets.dart';

import '../kit.dart';

Widget kitInventoryDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Every component',
  sections: kitInventorySections(),
);

// Every row's specimen is on its own page too; here the list scrolls itself in a window of the page, so the section
// shows how the inventory reads rather than all 89 parts at once.
List<Widget> kitInventorySections() => [
  kitSection(
    'Every row, answered',
    children: [SizedBox(height: 640, child: kitLiveInventoryGallery())],
  ),
];
