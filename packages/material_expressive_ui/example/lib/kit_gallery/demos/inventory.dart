/// The inventory group's demo: every row of ui_core's shared inventory,
/// each its live Expressive class, group by group (ExpressiveInventoryGallery,
/// a host-library name the gallery reaches through kit.dart).
library;

import 'package:flutter/widgets.dart';

import '../kit.dart';

/// The inventory group's demo, in [brightness].
Widget kitInventoryDemo(Brightness brightness) =>
    kitSurface(brightness: brightness, child: kitInventoryGallery());
