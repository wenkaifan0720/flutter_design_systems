import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../theme.dart';

/// The signal where it holds 3:1 on [background], else the nearest tone of
/// its own hue that does (ui_core's [RawPalette.readableTone]). A focused
/// edge replaces pixels of [background].
Color brutalFocusInk(BrutalColors colors, Color background) =>
    RawPalette.readableTone(colors.signal, on: [background], ratio: 3);
