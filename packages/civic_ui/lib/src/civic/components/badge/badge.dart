import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../format.dart';
import '../../internal/paint.dart';
import '../../theme.dart';

/// How many of something wait, after the words they belong to: [count] in
/// white on a square ink plate (on the error red when [needsAction]),
/// "99+" past [maxCount]. A screen reader hears the words and the count with
/// its noun as one: "Your applications, 2 need action". A count of 0
/// shows [child] alone.
///
/// Reads [CivicStyle]'s fill (the plate), foreground (the figure) and
/// textStyle: its `style:`, then [CivicThemeData.badgeStyle].
///
/// ```dart
/// CivicBadge(
///   count: 2,
///   noun: 'update',
///   child: Text('Your applications'),
/// )
/// ```
class CivicBadge extends StatelessWidget {
  /// [count] after [child].
  const CivicBadge({
    super.key,
    required this.count,
    required this.noun,
    this.nouns,
    this.child,
    this.needsAction = false,
    this.maxCount = 99,
    this.style,
  }) : assert(count >= 0 && maxCount > 0);

  /// How many there are.
  final int count;

  /// What one of them is, for a screen reader: "update", "new message".
  final String noun;

  /// What more than one are, when it is not [noun] and an s: "people".
  final String? nouns;

  /// The words the count belongs to; null: the plate alone.
  final Widget? child;

  /// Whether they need the reader to act: the plate on the error red.
  final bool needsAction;

  /// The largest figure shown; above it, "99+".
  final int maxCount;

  /// Overrides for this badge's look.
  final CivicStyle? style;

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final so = RawStyleOf(
      [style, t.badgeStyle],
      {if (needsAction) WidgetState.error},
    );
    final said = CivicFormat.plural(count, noun, nouns);
    final words = child;
    final plate = count == 0
        ? null
        : DecoratedBox(
            decoration: BoxDecoration(
              color: so.fill ?? (needsAction ? t.danger : t.textPrimary),
              borderRadius: BorderRadius.circular(CivicMetrics.corner / 2),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 24),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Text(
                  count > maxCount ? '$maxCount+' : CivicFormat.count(count),
                  textAlign: TextAlign.center,
                  style: context.civicText.bodySmall
                      .copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      )
                      .merge(so.textStyle)
                      .copyWith(
                        color:
                            so.foreground ??
                            (needsAction ? t.onDanger : t.background),
                      ),
                ),
              ),
            ),
          );
    if (words == null) {
      return Semantics(
        label: said,
        excludeSemantics: true,
        child: plate ?? const SizedBox.shrink(),
      );
    }
    return MergeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: CivicSpacing.s8,
        children: [
          Flexible(child: words),
          if (plate != null)
            Semantics(label: said, excludeSemantics: true, child: plate),
        ],
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IntProperty('count', count))
      ..add(StringProperty('noun', noun))
      ..add(
        FlagProperty('needsAction', value: needsAction, ifTrue: 'needs action'),
      )
      ..add(IntProperty('maxCount', maxCount, defaultValue: 99))
      ..add(
        DiagnosticsProperty<CivicStyle>('style', style, defaultValue: null),
      );
  }
}
