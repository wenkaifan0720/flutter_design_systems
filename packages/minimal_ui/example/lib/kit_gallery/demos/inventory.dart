/// Minimal in the shared inventory: the 89 components every look names
/// alike, each as Minimal's class, live, and the one Minimal leaves out.
library;

import 'package:flutter/material.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';

import '../kit.dart';

Widget kitInventoryDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Inventory',
  scroll: false,
  padding: EdgeInsets.zero,
  body: const MinimalInventoryGallery(
    padding: EdgeInsets.all(MinimalSpacing.s16),
  ),
);
