/// Every row of the shared component inventory as Frosted answers it
/// ([FrostedInventoryGallery] over [frostedInventory]): each part's live
/// specimen under its class name, or the reason Frosted leaves it out.
library;

import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:frosted_ui/frosted_host.dart';

import '../kit.dart';

Widget kitInventoryDemo(Brightness brightness) => kitSurface(
  brightness: brightness,
  child: FrostedScaffold(
    topBar: const FrostedAppBar(title: 'Inventory'),
    scroll: false,
    body: const FrostedInventoryGallery(),
  ),
);
