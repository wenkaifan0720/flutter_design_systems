import 'package:flutter/widgets.dart';

import '../theme.dart';

/// A row's least [height] (a list's, a setting's, a form's, an option's) at
/// the theme's density, 4 a step as a control's, never under the touch
/// target: Material's list tile moves with its visual density so.
double frostedRowHeight(BuildContext context, double height) => context
    .frostedTheme
    .density
    .height(height, least: FrostedBreakpoints.hitTargetOf(context));
