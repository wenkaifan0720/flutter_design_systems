// A face's one-line label, centred by its capitals (ui_core's DesignCapCenter).
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

/// Manrope's cap height over its em (1440 / 2000): the look's label typeface.
const double neumorphicCapHeight = 0.720;

/// [label], one line of words on a face, drawn with its capitals on its box's middle: whatever centres the box (a
/// face's alignment, a row's cross axis) then centres the capitals. The look wraps each face's label once, here and
/// nowhere in page code; never an icon.
Widget neumorphicLabel(Widget label) => neumorphicCapCentred
    ? DesignCapCenter(capHeightFactor: neumorphicCapHeight, child: label)
    : label;

/// Off: labels centred by their line boxes, as before DesignCapCenter. For the label sweep's before-and-after count.
@visibleForTesting
bool neumorphicCapCentred = true;
