import 'package:flutter/widgets.dart';

import '../chrome_metrics.dart';
import '../components/pressable.dart';
import '../components/shell_frame.dart';
import 'styled.dart';
import '../localizations.dart';
import '../theme.dart';

/// The shell's act as a rail's leading square: the ink square (the accent's
/// when [MinimalShellAction.primary]) the bottom bar ends with, standing at the
/// top of the rail instead. `MinimalShell` and `MinimalPreview` stand it in
/// their rail form.
class MinimalRailAction extends StatelessWidget {
  /// The rail's square for [action].
  const MinimalRailAction({super.key, required this.action});

  /// The act it performs.
  final MinimalShellAction action;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    return MinimalPressable(
      key: action.key,
      onPressed: () => action.onPressed(context),
      semanticLabel: action.label ?? MinimalLocalizations.of(context).create,
      child: Container(
        width: MinimalChromeMetrics.tabAction,
        height: MinimalChromeMetrics.tabAction,
        decoration: minimalFrame(
          t.shapes.small,
          fill: action.primary ? t.primary : t.foreground,
        ),
        child: MinimalIcon(
          action.icon,
          color: action.primary ? t.primaryForeground : t.background,
        ),
      ),
    );
  }
}
