/// A word on a control under a pointer's rest or a long press, in Ledger's
/// hand.
library;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import '../../internal/styled.dart';
import '../../style.dart';
import '../../theme.dart';

/// A few words on a control (what a glyph does, a figure's full value): the
/// toast's dark slip in the small radius, [message] in the mono on it,
/// above the control (below it when there is no room). It stands after a
/// pointer rests half a second or on a long press, and goes as the pointer
/// leaves; a screen reader hears [message] as the control's tooltip.
///
/// ```dart
/// LedgerTooltip(message: 'Export as CSV', child: LedgerIconButton(LucideIcons.download, semanticLabel: 'Export', onPressed: () {}))
/// ```
class LedgerTooltip extends StatelessWidget {
  /// [child] explained by [message].
  const LedgerTooltip({
    required this.message,
    required this.child,
    this.style,
    super.key,
  });

  /// The words.
  final String message;

  /// The control explained.
  final Widget child;

  /// The slip's look, over `components.tooltip`. It reads `fill`,
  /// `foreground`, `side`, `shape`, `padding` and `textStyle`.
  final LedgerStyle? style;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('message', message))
      ..add(
        DiagnosticsProperty<LedgerStyle>('style', style, defaultValue: null),
      );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final so = LedgerStyleOf([style, t.components.tooltip], const {});
    final corners = so.shape;
    return Tooltip(
      message: message,
      preferBelow: false,
      verticalOffset: _offset,
      waitDuration: _wait,
      exitDuration: LedgerMotion.fast,
      padding:
          so.padding(Directionality.of(context)) ??
          const EdgeInsets.symmetric(
            horizontal: LedgerSpacing.s10,
            vertical: LedgerSpacing.s6,
          ),
      margin: const EdgeInsets.symmetric(horizontal: LedgerSpacing.s16),
      decoration: corners != null
          ? ShapeDecoration(
              color: so.fill ?? t.toast,
              shape: so.side == null
                  ? corners
                  : corners.copyWith(side: so.side),
            )
          : BoxDecoration(
              color: so.fill ?? t.toast,
              borderRadius: BorderRadius.circular(t.smallRadius),
              border: so.side == null ? null : Border.fromBorderSide(so.side!),
            ),
      textStyle: so.words(t.meta, so.foreground ?? t.onToast),
      child: child,
    );
  }

  static const double _offset = 28;
  static const Duration _wait = Duration(milliseconds: 500);
}
