/// A count marked on a control's corner, in Ledger's hand.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../internal/face.dart';
import '../../internal/styled.dart';
import '../../style.dart';
import '../../theme.dart';

/// A count on a control's corner (notes unread, entries to file): the
/// figure in the mono on a disc of the green centred on [child]'s top end
/// corner (clear of what the control shows inside it), the vermilion when
/// [urgent], 99+ past 99; with no [count], the green dot alone. A count of
/// 0 takes the mark away in Ledger's one motion. A screen reader hears the
/// count after the control's own name.
///
/// ```dart
/// LedgerBadge(count: 3, child: LedgerIconButton(LucideIcons.inbox, semanticLabel: 'Inbox', onPressed: () {}))
/// ```
class LedgerBadge extends StatelessWidget {
  /// [child] marked with [count].
  const LedgerBadge({
    required this.child,
    this.count,
    this.urgent = false,
    this.semanticLabel = 'unread',
    this.style,
    super.key,
  }) : assert(count == null || count >= 0);

  /// The control marked.
  final Widget child;

  /// The count; null shows the dot alone; 0 shows nothing.
  final int? count;

  /// Whether the mark is the vermilion.
  final bool urgent;

  /// What the count counts, spoken after it ("3 unread").
  final String semanticLabel;

  /// The mark's look, over `components.badge`. It reads `fill`,
  /// `foreground`, `edge`, `side` and `textStyle`; an [urgent] mark is in
  /// the `error` state.
  final LedgerStyle? style;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IntProperty('count', count, defaultValue: null))
      ..add(FlagProperty('urgent', value: urgent, ifTrue: 'urgent'))
      ..add(StringProperty('semanticLabel', semanticLabel))
      ..add(
        DiagnosticsProperty<LedgerStyle>('style', style, defaultValue: null),
      );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final n = count;
    final shown = n != 0;
    final words = n == null ? null : (n > 99 ? '99+' : '$n');
    final so = LedgerStyleOf(
      [style, t.components.badge],
      {if (urgent) WidgetState.error},
    );
    final fill = so.fill ?? (urgent ? t.danger : t.moneyIn);
    final rim =
        so.side ?? BorderSide(color: so.edge ?? t.background, width: _rim);
    final mark = LedgerEase(
      value: shown ? 1 : 0,
      builder: (context, at, _) => Opacity(
        opacity: at.clamp(0.0, 1.0),
        child: Transform.scale(
          scale: .6 + .4 * at.clamp(0.0, 1.0),
          child: words == null
              ? Container(
                  width: _dot,
                  height: _dot,
                  decoration: BoxDecoration(
                    color: fill,
                    shape: BoxShape.circle,
                    border: Border.fromBorderSide(rim),
                  ),
                )
              : Container(
                  constraints: const BoxConstraints(minWidth: _disc),
                  height: _disc,
                  padding: const EdgeInsets.symmetric(
                    horizontal: LedgerSpacing.s4,
                  ),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: fill,
                    borderRadius: BorderRadius.circular(_disc / 2),
                    border: Border.fromBorderSide(rim),
                  ),
                  child: Text(
                    words,
                    textScaler: TextScaler.noScaling,
                    style: so.words(t.meta.medium, so.foreground ?? t.onAccent),
                  ),
                ),
        ),
      ),
    );
    // The control keeps its own size wherever it is set: a cell that would
    // stretch it stands it in its middle instead.
    return Center(
      widthFactor: 1,
      heightFactor: 1,
      child: Semantics(
        value: shown && n != null ? '$n $semanticLabel' : null,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            child,
            PositionedDirectional(
              top: -(words == null ? _dot : _disc) / 2,
              end: -(words == null ? _dot : _disc) / 2,
              child: ExcludeSemantics(child: IgnorePointer(child: mark)),
            ),
          ],
        ),
      ),
    );
  }

  static const double _dot = 10;
  static const double _disc = 18;
  // The paper's ring that lifts the mark off the control it marks.
  static const double _rim = 1.5;
}
