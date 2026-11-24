import 'package:flutter/foundation.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../internal/spinner_arc.dart';
import '../../theme.dart';

/// A short wait the reader must sit through, said in words: a
/// square-ended arc turning in the action colour on a hairline ring, its
/// [label] beside it ("Loading" in the reader's language). Under Reduce
/// Motion the arc stands still; the words say it either way. A screen
/// reader hears the words once, as it appears.
///
/// For a page still on its way, [CivicLoadingState]; for a wait with a
/// measure (an upload), [CivicProgressBar]; for a button whose press is
/// being sent, [CivicButton.busy].
///
/// Reads [CivicStyle]'s foreground (the arc), edge (the ring) and
/// textStyle (the words): its `style:`, then
/// [CivicThemeData.spinnerStyle].
///
/// ```dart
/// const CivicSpinner(label: 'Checking your vehicle')
/// ```
class CivicSpinner extends StatelessWidget {
  /// A wait.
  const CivicSpinner({super.key, this.label, this.size = 24, this.style});

  /// The words; null says "Loading" in the reader's language.
  final String? label;

  /// The arc's size across, at the reader's text size of 1; it grows with
  /// the words.
  final double size;

  /// Overrides for this spinner's look.
  final CivicStyle? style;

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final text = context.civicText;
    final so = RawStyleOf([style, t.spinnerStyle], const {});
    final words = label ?? RawWidgetsLocalizations.of(context).loadingLabel;
    final across = MediaQuery.textScalerOf(context).scale(size);
    return Semantics(
      container: true,
      role: SemanticsRole.loadingSpinner,
      liveRegion: true,
      label: words,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: CivicSpacing.s12,
        children: [
          CivicSpinnerArc(
            size: across,
            color: so.foreground ?? t.action,
            ring: so.edge ?? t.rule,
          ),
          Flexible(
            child: Text(
              words,
              style: text.body
                  .copyWith(color: t.textSecondary)
                  .merge(so.textStyle),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('label', label, defaultValue: null))
      ..add(DoubleProperty('size', size, defaultValue: 24))
      ..add(
        DiagnosticsProperty<CivicStyle>('style', style, defaultValue: null),
      );
  }
}
