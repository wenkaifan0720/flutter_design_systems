/// A word on a control under a pointer's rest or a long press, in Ledger's
/// hand.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../internal/presence.dart';
import '../../internal/styled.dart';
import '../../style.dart';
import '../../theme.dart';

/// A few words on a control (what a glyph does, a figure's full value): the
/// toast's dark slip in the small radius, [message] in the mono on it,
/// above the control (below it when there is no room). It stands after a
/// pointer rests half a second, at once when the keys bring the focus to the
/// control, or on a long press; the pointer may move onto it, Escape hides
/// it, and it goes as the pointer or the focus leaves. A screen reader hears
/// [message] as the control's tooltip.
///
/// Built on Flutter's RawTooltip, with ui_core's RawTooltipFocusFix (it
/// shows on the keyboard's focus) and RawTooltipPlacement (its place).
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
    return RawTooltipPlacement(
      placement: _placement,
      builder: (context, positionDelegate) => MergeSemantics(
        // One node for the control and its tip, as the published tooltip
        // made: a screen reader hears the tip with the control. RawTooltip's
        // own tooltip semantics do not merge, and went to the node above.
        child: RawTooltip(
          semanticsTooltip: message,
          hoverDelay: const Duration(milliseconds: 500),
          positionDelegate: positionDelegate,
          tooltipBuilder: (context, animation) => FadeTransition(
            opacity: animation.drive(ledgerPresence),
            // At least 32 tall on a phone and 24 on a desktop, the words centred
            // (as Material's tooltip held Ledger's slip before 0.3.0).
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: _leastHeight),
              child: DecoratedBox(
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
                        border: so.side == null
                            ? null
                            : Border.fromBorderSide(so.side!),
                      ),
                child: Padding(
                  padding:
                      so.padding(Directionality.of(context)) ??
                      const EdgeInsets.symmetric(
                        horizontal: LedgerSpacing.s10,
                        vertical: LedgerSpacing.s6,
                      ),
                  child: Center(
                    widthFactor: 1,
                    heightFactor: 1,
                    child: Text(
                      message,
                      style: so.words(t.meta, so.foreground ?? t.onToast),
                    ),
                  ),
                ),
              ),
            ),
          ),
          child: RawTooltipFocusFix(child: child),
        ),
      ),
    );
  }

  static double get _leastHeight => switch (defaultTargetPlatform) {
    TargetPlatform.macOS ||
    TargetPlatform.linux ||
    TargetPlatform.windows => 24,
    _ => 32,
  };

  // Above the control and centred on it, 6 from it (Material's 28 from a 44
  // control's middle, as Ledger's tip stood before 0.3.0), 16 in from the
  // screen's edges.
  static const RawPopoverPlacement _placement = RawPopoverPlacement(
    side: RawPopoverSide.above,
    align: RawPopoverAlign.center,
    gap: 6,
    margin: LedgerSpacing.s16,
    preferredExtent: 48,
    matchAnchorWidth: false,
  );
}
