/// Toggles, split buttons and links: `TermToggleGroup` (a segmented control
/// too), `TermSplitButton`, `TermButtonGroup` and `TermLink`.
library;

import 'package:flutter/widgets.dart';

import '../kit.dart';

Widget kitActionsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'actions',
  sections: kitParts(const [
    ('a group of buttons', 'ButtonGroup'),
    ('toggles', 'ToggleGroup'),
    ('one of a few', 'SegmentedButton'),
    ('a split button', 'SplitButton'),
    ('a link', 'Link'),
  ]),
);
