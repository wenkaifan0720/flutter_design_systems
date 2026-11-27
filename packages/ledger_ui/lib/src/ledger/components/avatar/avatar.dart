import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../chrome_metrics.dart';
import '../../internal/cap_center.dart';
import '../../theme.dart';
import '../pressable/pressable.dart';

import '../marks/marks.dart' show LedgerTag;

/// The owner's avatar: their [initials] in the italic serif on a 36 ink
/// disc, saying [semanticLabel] (Profile and settings). A null [onTap] draws it
/// unpressable (the sidebar's foot presses as a whole).
///
/// ```dart
/// LedgerAvatar(initials: 'MH', semanticLabel: 'Profile and settings', onTap: () {})
/// ```
class LedgerAvatar extends StatelessWidget {
  /// The avatar of [initials], saying [semanticLabel].
  const LedgerAvatar({
    required this.initials,
    this.semanticLabel,
    this.onTap,
    this.focusNode,
    this.autofocus = false,
    this.tapAlignment = AlignmentDirectional.center,
    super.key,
  });

  /// One or two letters.
  final String initials;

  /// Where the disc stands in its tap target where the target is larger:
  /// centred, or on the edge a keyline runs ([AlignmentDirectional.centerStart]
  /// at the start of a column, [AlignmentDirectional.centerEnd] at its end),
  /// the target growing away from it.
  final AlignmentDirectional tapAlignment;

  /// What a press opens, spoken; null speaks the initials.
  final String? semanticLabel;

  /// Opens the profile; null draws it unpressable.
  final VoidCallback? onTap;

  /// {@template ledger.focusNode}
  /// The control's focus; null keeps one of its own. The caller disposes
  /// the node it gives.
  /// {@endtemplate}
  final FocusNode? focusNode;

  /// {@template ledger.autofocus}
  /// Whether it takes focus when it first appears.
  /// {@endtemplate}
  final bool autofocus;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('initials', initials))
      ..add(
        DiagnosticsProperty<AlignmentDirectional>('tapAlignment', tapAlignment),
      )
      ..add(StringProperty('semanticLabel', semanticLabel, defaultValue: null))
      ..add(ObjectFlagProperty<VoidCallback>.has('onTap', onTap))
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    // With a larger text the disc and its letters grow with the words, to
    // the marks' 130% at most ([LedgerTag.textScale]).
    final scaler = MediaQuery.textScalerOf(context)
        .clamp(maxScaleFactor: LedgerTag.textScale);
    final disc = Container(
      width: LedgerChromeMetrics.avatar * scaler.scale(1),
      height: LedgerChromeMetrics.avatar * scaler.scale(1),
      alignment: Alignment.center,
      decoration: BoxDecoration(shape: BoxShape.circle, color: t.avatar),
      // Its capitals on the disc's middle, as every face's label stands.
      child: ledgerCapCenter(
        t.initials,
        Text(
          initials,
          maxLines: 1,
          softWrap: false,
          textScaler: scaler,
          style: t.initials.colored(t.onAvatar),
        ),
      ),
    );
    if (onTap == null) {
      return Semantics(
        label: semanticLabel ?? initials,
        excludeSemantics: true,
        child: disc,
      );
    }
    return TapTargetPadding(
      alignment: tapAlignment,
      child: LedgerPressable(
        focusNode: focusNode,
        autofocus: autofocus,
        onTap: onTap,
        semanticLabel: semanticLabel ?? initials,
        radius: LedgerChromeMetrics.avatar / 2,
        child: disc,
      ),
    );
  }
}
