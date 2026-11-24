import 'package:flutter/painting.dart';

import '../theme.dart';

/// The line laid over the outer edge of a lamp's ink contour (a chosen day, a wheel's chosen row) at night.
///
/// A lamp keeps its ink contour, which reads on its yellow. On the night page the ink is lost against the ground, so a
/// hairline of the night line is laid over the contour's outer edge, and the lamp's edge reads on the page as well. By
/// day the ink reads on both, and nothing is laid.
BorderSide comicLampNightLine(ComicColors colors) =>
    colors.dark ? BorderSide(color: colors.nightLine) : BorderSide.none;
