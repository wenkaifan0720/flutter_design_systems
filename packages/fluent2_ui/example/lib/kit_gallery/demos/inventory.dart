/// Every row of the shared component inventory, each under its group with
/// the class that answers it over its live specimen.
library;

import 'package:flutter/material.dart';
import 'package:fluent2_ui/fluent2_ui.dart';
import 'package:fluent2_ui/fluent2_host.dart';

import '../kit.dart';

Widget kitInventoryDemo(Brightness brightness) => kitSurface(
  brightness: brightness,
  child: const Fluent2Scaffold(
    scroll: false,
    topBar: Fluent2AppBar(title: 'Every component, row by row'),
    body: Fluent2InventoryGallery(),
  ),
);
