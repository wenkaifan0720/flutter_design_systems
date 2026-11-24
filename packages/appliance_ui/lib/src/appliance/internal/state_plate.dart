/// The faceplate an empty or a failed list stands on.
library;

import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../lists.dart';
import '../material.dart';
import '../theme.dart';

/// A faceplate holding a display window that reads [reading], a heading, a
/// line under it and a key: an empty state's (the window's dashes dim) and a
/// failed one's (the window's code lit, a lamp lit beside the heading).
class ApplianceStatePlate extends StatelessWidget {
  /// A plate headed [title].
  const ApplianceStatePlate({
    super.key,
    required this.reading,
    required this.title,
    this.message,
    this.action,
    this.lit = false,
    this.lamp,
    this.style,
  });

  /// What the window reads.
  final String reading;

  /// Whether the reading is lit at full strength (a code), rather than dim
  /// (the dashes of nothing to show).
  final bool lit;

  /// The light of the lamp lit beside the heading; null: no lamp.
  final Color? lamp;

  /// The heading.
  final String title;

  /// The line under it.
  final String? message;

  /// The key under the words.
  final Widget? action;

  /// Its style, over [ApplianceThemeData.displayStyle]: fill (the window),
  /// foreground and textStyle (the title).
  final ApplianceStyle? style;

  @override
  Widget build(BuildContext context) {
    final look = RawStyleOf([
      style,
      ApplianceTheme.of(context).displayStyle,
    ], const {});
    final theme = ApplianceTheme.of(context);
    final c = theme.colors;
    final t = theme.textTheme;
    final heading = Text(
      title,
      textAlign: TextAlign.center,
      style: look.text(t.heading).copyWith(color: look.foreground ?? c.print),
    );
    return AppliancePanel(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 120, minHeight: 56),
              child: ApplianceSurface(
                face: ApplianceFace.well(c, fill: look.fill ?? c.display),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Center(
                    widthFactor: 1,
                    heightFactor: 1,
                    child: Text(
                      reading,
                      style: t.display.copyWith(
                        color: lit
                            ? c.onDisplay
                            : c.onDisplay.withValues(alpha: 0.55),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: ApplianceSpacing.regular),
          Semantics(
            header: true,
            child: lamp == null
                ? heading
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ApplianceLamp(lit: true, color: lamp),
                      const SizedBox(width: ApplianceSpacing.small),
                      Flexible(child: heading),
                    ],
                  ),
          ),
          if (message != null) ...[
            const SizedBox(height: ApplianceSpacing.small),
            ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: ApplianceMetrics.readingWidth,
              ),
              child: Text(
                message!,
                textAlign: TextAlign.center,
                style: t.body.copyWith(color: c.printMuted),
              ),
            ),
          ],
          if (action != null) ...[
            const SizedBox(height: ApplianceSpacing.large),
            action!,
          ],
        ],
      ),
    );
  }
}
