/// A face's one-line label drawn with its capitals on the face's middle.
/// Internal: the look wraps the label of each face once, here, never an
/// icon and never in page code.
library;

import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

/// Roboto Flex's cap height over its em (its OS/2 `sCapHeight` over its head
/// table's `unitsPerEm`): the look's label typeface.
const double expressiveCapHeightFactor = 0.711;

/// [label], a face's one-line label, drawn with its capitals on its box's
/// middle (ui_core's DesignCapCenter): centring the line box leaves them up
/// to a few device pixels off, by the engine's whole-pixel baseline.
Widget expressiveFaceLabel(Widget label) =>
    DesignCapCenter(capHeightFactor: expressiveCapHeightFactor, child: label);
