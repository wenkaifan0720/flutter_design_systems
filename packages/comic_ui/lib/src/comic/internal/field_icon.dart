// A button standing inside a field (a password's eye, a search's clear): the field's contour is its frame, so it draws
// no rim and no fill of its own, only its glyph. A framed square inside the field's frame stood a pixel or two off the
// field's rims, a box squeezed in a box.
import 'package:flutter/widgets.dart';

import '../component_themes.dart';

/// The style of an icon button inside a field: no rim, no fill.
const ComicStyle comicInFieldIcon = ComicStyle(
  side: WidgetStatePropertyAll(BorderSide.none),
  fill: WidgetStatePropertyAll(Color(0x00000000)),
);
