/// Pages of a long register, in Ledger's hand.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../chrome_metrics.dart';
import '../../internal/corners.dart';
import '../../internal/face.dart';
import '../../internal/position_words.dart';
import '../../theme.dart';
import '../icon-button/icon_button.dart';
import '../pressable/pressable.dart';

/// The pages of a long register: the way back and the way on as ringed
/// keys at the ends, between them the page figures in the mono, the page
/// shown underlined in the accountant's double rule and set in the ink, the
/// rest in the second ink, darkening under a pointer; a run of pages too
/// long to show folds into an ellipsis round the page shown. Where the
/// figures do not fit (a phone at a large text size) it reads PAGE 2 OF 9
/// between its keys. [page] counts from 1. Each figure is laid out at the
/// tap floor; a screen reader hears each as "Page 3", the shown one as
/// selected.
///
/// ```dart
/// LedgerPagination(page: 2, pageCount: 9, onChanged: (p) {})
/// ```
class LedgerPagination extends StatelessWidget {
  /// [page] of [pageCount].
  const LedgerPagination({
    required this.page,
    required this.pageCount,
    required this.onChanged,
    super.key,
  }) : assert(pageCount > 0),
       assert(page >= 1 && page <= pageCount);

  /// The page shown, from 1.
  final int page;

  /// How many pages.
  final int pageCount;

  /// Called with the page asked for; null holds it.
  final ValueChanged<int>? onChanged;

  /// The figures shown: the first, the last, the page and its neighbours,
  /// null for a fold.
  List<int?> _shown() {
    if (pageCount <= 7) return [for (var i = 1; i <= pageCount; i++) i];
    final set = <int>{1, pageCount, page - 1, page, page + 1};
    if (page <= 3) set.addAll([2, 3, 4]);
    if (page >= pageCount - 2) {
      set.addAll([pageCount - 3, pageCount - 2, pageCount - 1]);
    }
    final pages = set.where((p) => p >= 1 && p <= pageCount).toList()..sort();
    final out = <int?>[];
    for (final (i, p) in pages.indexed) {
      if (i > 0 && p - pages[i - 1] > 1) out.add(null);
      out.add(p);
    }
    return out;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IntProperty('page', page))
      ..add(IntProperty('pageCount', pageCount))
      ..add(ObjectFlagProperty<ValueChanged<int>>.has('onChanged', onChanged));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final words = RawWidgetsLocalizations.of(context);
    final change = onChanged;
    final back = LedgerIconButton.outlined(
      LucideIcons.chevronLeft,
      semanticLabel: words.previousPageTooltip,
      size: LedgerIconButtonSize.small,
      tapAlignment: AlignmentDirectional.centerStart,
      onPressed: change != null && page > 1 ? () => change(page - 1) : null,
    );
    final on = LedgerIconButton.outlined(
      LucideIcons.chevronRight,
      semanticLabel: words.nextPageTooltip,
      size: LedgerIconButtonSize.small,
      tapAlignment: AlignmentDirectional.centerEnd,
      onPressed: change != null && page < pageCount
          ? () => change(page + 1)
          : null,
    );
    return LayoutBuilder(
      builder: (context, box) {
        final shown = _shown();
        final cell = RawTapTargets.of(context).floorOn().width;
        final scale = MediaQuery.textScalerOf(context).scale(1);
        // The row as it lays out: the two ways at the floor, each figure a
        // target (wider with larger text), each gap mark half one, 8 apart.
        var need = 2 * cell + LedgerSpacing.s8 * (shown.length + 1);
        for (final p in shown) {
          need += p == null ? cell / 2 : cell * scale;
        }
        final figures = need <= box.maxWidth;
        return Semantics(
          container: true,
          label: 'Pages',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: LedgerSpacing.s8,
            children: [
              back,
              if (figures)
                for (final p in shown)
                  if (p == null)
                    ExcludeSemantics(
                      child: SizedBox(
                        width: cell / 2,
                        child: Center(
                          child: Text(
                            '…',
                            style: t.amount.colored(t.textTertiary),
                          ),
                        ),
                      ),
                    )
                  else
                    _Figure(
                      page: p,
                      shown: p == page,
                      onTap: change == null || p == page
                          ? null
                          : () => change(p),
                    )
              else
                Flexible(
                  child: Text(
                    ledgerPosition(
                      context,
                      'Page',
                      page,
                      pageCount,
                    ).toUpperCase(),
                    textAlign: TextAlign.center,
                    style: t.meta.medium.colored(t.textPrimary),
                  ),
                ),
              on,
            ],
          ),
        );
      },
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({required this.page, required this.shown, required this.onTap});

  final int page;
  final bool shown;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    return TapTargetPadding(
      child: LedgerPressable(
        onTap: onTap ?? (shown ? _stay : null),
        semanticLabel: 'Page $page',
        selected: shown,
        borderRadius: ledgerStep(t, RawCorner.small),
        child: Builder(
          builder: (context) {
            final hot = LedgerPressStates.isHot(context);
            return LedgerFace(
              style: LedgerFaceStyle(
                ink: shown || hot ? t.textPrimary : t.textSecondary,
              ),
              builder: (context, s, _) => SizedBox(
                width: _cell,
                height: _cell,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text('$page', style: t.amount.colored(s.ink)),
                    // The page shown: the accountant's double rule under it.
                    PositionedDirectional(
                      start: _rule,
                      end: _rule,
                      bottom: _foot,
                      child: LedgerEase(
                        value: shown ? 1 : 0,
                        builder: (context, at, _) => Opacity(
                          opacity: at.clamp(0.0, 1.0),
                          child: Column(
                            spacing: LedgerChromeMetrics.focusGap,
                            children: [
                              for (var i = 0; i < 2; i++)
                                SizedBox(
                                  height: 1,
                                  width: double.infinity,
                                  child: ColoredBox(color: t.textPrimary),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  static void _stay() {}

  static const double _cell = 36;
  static const double _rule = 9;
  static const double _foot = 4;
}
