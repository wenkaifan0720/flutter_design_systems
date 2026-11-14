/// Fluent 2's bottom action bar: a pushed page's one act with its lesser
/// one, a summary line beside them, and the one act alone; on a phone the
/// acts stack, the one act on top.
library;

import 'package:flutter/material.dart';
import 'package:fluent2_ui/fluent2_ui.dart';

import '../kit.dart';

Widget kitActionBarDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Action bar',
  sections: [
    kitSection('With a summary', children: [kitSpecimenActionBarSummary()]),
    kitSection('Two acts', children: [kitSpecimenActionBarTwo()]),
    kitSection('The one act', children: [kitSpecimenActionBarAlone()]),
  ],
  footer: Fluent2BottomActionBar(
    primaryLabel: 'Send invite',
    primaryIcon: Fluent2Icons.send,
    onPrimaryPressed: () {},
    secondaryLabel: 'Cancel',
    onSecondaryPressed: () {},
  ),
);

// --- Specimens --------------------------------------------------------------

Widget kitSpecimenActionBarSummary() => Fluent2BottomActionBar(
  summary: '3 files selected',
  detail: '12.4 MB · Shared with Northwind',
  primaryLabel: 'Share',
  primaryIcon: Fluent2Icons.share,
  onPrimaryPressed: () {},
  secondaryLabel: 'Download',
  onSecondaryPressed: () {},
);

Widget kitSpecimenActionBarTwo() => Fluent2BottomActionBar(
  primaryLabel: 'Schedule meeting',
  onPrimaryPressed: () {},
  secondaryLabel: 'Save draft',
  onSecondaryPressed: () {},
);

Widget kitSpecimenActionBarAlone() =>
    Fluent2BottomActionBar(primaryLabel: 'Join now', onPrimaryPressed: () {});
