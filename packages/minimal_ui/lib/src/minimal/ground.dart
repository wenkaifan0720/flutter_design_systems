import 'package:flutter/services.dart' show SystemUiOverlayStyle;
import 'package:flutter/widgets.dart';

import 'theme.dart';

/// The ground a page stands on, which is what its chrome is drawn against:
/// the theme's own [surface], or [media] — a full-bleed feed of video or
/// photographs.
///
/// On media the chrome is dark and solid: drawn in the host's dark tokens
/// ([MinimalTheme.darkOf]) with light ink and a light status bar, and
/// nothing in it blurs. A tab whose item is `MinimalNavItem.media` paints the
/// shell's bar so, and its root page ends at the bar's top; a page stands
/// on media through `MinimalPage(ground:)`.
enum MinimalGround {
  /// The theme's own ground: every page's default.
  surface,

  /// A full-bleed media feed.
  media;

  /// The ground published at [context] ([MinimalGroundScope]), [surface] when
  /// none is.
  static MinimalGround of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<_MinimalGroundMark>()
          ?.ground ??
      surface;
}

/// Stands [child] on [ground]: on [MinimalGround.media], in the host's dark
/// tokens under a light status bar; on [MinimalGround.surface], as it is. The
/// shell mounts one around its bar, `MinimalPage(ground:)` one around a page.
class MinimalGroundScope extends StatelessWidget {
  /// Stands [child] on [ground].
  const MinimalGroundScope({
    required this.ground,
    required this.child,
    super.key,
  });

  /// The ground [child] stands on.
  final MinimalGround ground;

  /// What stands on it.
  final Widget child;

  @override
  Widget build(BuildContext context) => _MinimalGroundMark(
    ground: ground,
    child: ground == MinimalGround.surface
        ? child
        : MinimalTheme(
            data: MinimalTheme.darkOf(context),
            darkData: MinimalTheme.darkOf(context),
            child: AnnotatedRegion<SystemUiOverlayStyle>(
              value: SystemUiOverlayStyle.light,
              child: child,
            ),
          ),
  );
}

class _MinimalGroundMark extends InheritedWidget {
  const _MinimalGroundMark({required this.ground, required super.child});

  final MinimalGround ground;

  @override
  bool updateShouldNotify(_MinimalGroundMark oldWidget) =>
      ground != oldWidget.ground;
}
