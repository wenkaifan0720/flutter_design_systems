/// A one-line label on a face, drawn with its capitals on the face's middle.
library;

import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

/// Geist's and Geist Mono's cap height over their em (OS/2 sCapHeight over
/// unitsPerEm): the label typefaces of every Minimal face.
const double minimalCapHeight = 0.710;

/// [label] (one line) drawn so its capitals' middle is its box's middle, so
/// a face that centres the box centres the capitals: a button's, a tab's, a
/// segment's, a chip's, a menu item's, a select's, a badge's, a one-line
/// row's and a title bar's. Never around an icon.
Widget minimalCapLabel(Widget label) =>
    DesignCapCenter(capHeightFactor: minimalCapHeight, child: label);
