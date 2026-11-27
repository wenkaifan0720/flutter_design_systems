import 'package:flutter/foundation.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../theme.dart';

/// Where content is on its way, held in its shape so the page does not
/// jump when it comes: [child] laid out as the content will be, of
/// [CivicSkeletonBlock]s and [CivicSkeletonText], plain grey (a wash of
/// the ink, so they show on the ground and on a card alike), fading
/// slowly together (still under Reduce Motion). A screen reader hears one
/// "Loading" (or [semanticLabel]), not the blocks.
///
/// Use it where the shape is known (a list of applications, a record's
/// rows) and the wait is short; for a whole page on its way,
/// [CivicLoadingState] says it in words.
///
/// Reads [CivicStyle]'s fill (the blocks): its `style:`, then
/// [CivicThemeData.skeletonStyle].
///
/// ```dart
/// const CivicSkeleton(
///   child: Row(
///     spacing: 16,
///     children: [
///       CivicSkeletonBlock(width: 48, height: 48, circle: true),
///       Expanded(child: CivicSkeletonText(lines: 2)),
///     ],
///   ),
/// )
/// ```
class CivicSkeleton extends StatefulWidget {
  /// A skeleton of [child].
  const CivicSkeleton({
    super.key,
    required this.child,
    this.semanticLabel,
    this.style,
  });

  /// The blocks, laid out as the content will be.
  final Widget child;

  /// What a screen reader hears; null: "Loading" in the reader's language.
  final String? semanticLabel;

  /// Overrides for this skeleton's look.
  final CivicStyle? style;

  @override
  State<CivicSkeleton> createState() => _CivicSkeletonState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('semanticLabel', semanticLabel, defaultValue: null))
      ..add(
        DiagnosticsProperty<CivicStyle>('style', style, defaultValue: null),
      );
  }
}

class _CivicSkeletonState extends State<CivicSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );
  late final Animation<double> _opacity = _fade.drive(
    Tween<double>(
      begin: 1,
      end: 0.55,
    ).chain(CurveTween(curve: Curves.easeInOut)),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (RawMotionPolicy.of(context).reduceMotion) {
      _fade
        ..stop()
        ..value = 0;
    } else if (!_fade.isAnimating) {
      _fade.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final so = RawStyleOf([widget.style, t.skeletonStyle], const {});
    return Semantics(
      container: true,
      role: SemanticsRole.loadingSpinner,
      label:
          widget.semanticLabel ??
          RawWidgetsLocalizations.of(context).loadingLabel,
      excludeSemantics: true,
      child: _SkeletonFill(
        color: so.fill ?? _wash(t),
        child: FadeTransition(opacity: _opacity, child: widget.child),
      ),
    );
  }
}

class _SkeletonFill extends InheritedWidget {
  const _SkeletonFill({required this.color, required super.child});

  final Color color;

  @override
  bool updateShouldNotify(_SkeletonFill old) => old.color != color;
}

Color _wash(CivicThemeData t) =>
    t.textPrimary.withValues(alpha: t.isDark ? 0.16 : 0.12);

Color _fillOf(BuildContext context) =>
    context.dependOnInheritedWidgetOfExactType<_SkeletonFill>()?.color ??
    _wash(context.civicTheme);

/// A grey block in a [CivicSkeleton]: [width] by [height] (null: as wide
/// as its room), with a control's corners, or round ([circle]: a picture
/// of a person).
///
/// ```dart
/// const CivicSkeletonBlock(height: 120)
/// ```
class CivicSkeletonBlock extends StatelessWidget {
  /// A block.
  const CivicSkeletonBlock({
    super.key,
    this.width,
    required this.height,
    this.circle = false,
  });

  /// Its width; null: its room's.
  final double? width;

  /// Its height.
  final double height;

  /// Whether it is round.
  final bool circle;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width ?? double.infinity,
    height: height,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: _fillOf(context),
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle
            ? null
            : BorderRadius.circular(
                context.civicTheme.shapeScheme.corners.small,
              ),
      ),
    ),
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DoubleProperty('width', width, defaultValue: null))
      ..add(DoubleProperty('height', height))
      ..add(FlagProperty('circle', value: circle, ifTrue: 'circle'));
  }
}

/// Lines of words still on their way, in a [CivicSkeleton]: [lines] grey
/// bars of the body's height and line, the last shorter, as a paragraph
/// ends.
///
/// ```dart
/// const CivicSkeletonText(lines: 3)
/// ```
class CivicSkeletonText extends StatelessWidget {
  /// Lines.
  const CivicSkeletonText({super.key, this.lines = 3}) : assert(lines > 0);

  /// How many.
  final int lines;

  @override
  Widget build(BuildContext context) {
    final body = context.civicText.body;
    final scaler = MediaQuery.textScalerOf(context);
    final size = scaler.scale(body.fontSize ?? 18);
    final line = size * (body.height ?? 1.3);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < lines; i++)
          Padding(
            padding: EdgeInsets.symmetric(vertical: (line - size * 0.7) / 2),
            child: FractionallySizedBox(
              widthFactor: i == lines - 1 && lines > 1 ? 0.6 : 1,
              child: CivicSkeletonBlock(height: size * 0.7),
            ),
          ),
      ],
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('lines', lines, defaultValue: 3));
  }
}
