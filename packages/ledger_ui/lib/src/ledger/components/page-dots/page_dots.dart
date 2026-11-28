/// Which page of a few a person is on, in Ledger's hand.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../internal/face.dart';
import '../../internal/position_words.dart';
import '../../theme.dart';
import '../pressable/pressable.dart';

/// Which of a few pages shows (a welcome's cards, a carousel's slips): a
/// short rule for each page in the light rule, the page shown a longer one
/// in the ink that runs to the next in Ledger's one motion, as a ruler marks
/// its place. With [onChanged] each mark is a key laid out at the tap floor
/// that turns to its page, darkening under a pointer; without, the marks
/// only show the place. A screen reader hears "Page 2 of 5".
///
/// ```dart
/// LedgerPageDots(pageCount: 5, page: 1, onChanged: (i) {})
/// ```
class LedgerPageDots extends StatelessWidget {
  /// [pageCount] marks, [page] the one shown (from 0).
  const LedgerPageDots({
    required this.pageCount,
    required this.page,
    this.onChanged,
    super.key,
  }) : assert(pageCount > 0),
       assert(page >= 0 && page < pageCount);

  /// How many pages.
  final int pageCount;

  /// The page shown, from 0.
  final int page;

  /// Turns to a page; null: the marks only show the place.
  final ValueChanged<int>? onChanged;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IntProperty('pageCount', pageCount))
      ..add(IntProperty('page', page))
      ..add(ObjectFlagProperty<ValueChanged<int>>.has('onChanged', onChanged));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final change = onChanged;
    Widget mark(int i, bool hot) => LedgerEase(
      value: i == page ? 1 : 0,
      builder: (context, at, _) => Container(
        width: _short + (_long - _short) * at.clamp(0.0, 1.0),
        height: _thick,
        decoration: BoxDecoration(
          color: Color.lerp(
            hot ? t.textSecondary : t.border,
            t.textPrimary,
            at.clamp(0.0, 1.0),
          ),
          borderRadius: BorderRadius.circular(_thick / 2),
        ),
      ),
    );
    if (change == null) {
      return Semantics(
        label: ledgerPosition(context, 'Page', page + 1, pageCount),
        excludeSemantics: true,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: _gap,
          children: [for (var i = 0; i < pageCount; i++) mark(i, false)],
        ),
      );
    }
    return Semantics(
      container: true,
      label: 'Pages',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < pageCount; i++)
            TapTargetPadding(
              child: LedgerPressable(
                onTap: i == page ? _stay : () => change(i),
                semanticLabel: ledgerPosition(
                  context,
                  'Page',
                  i + 1,
                  pageCount,
                ),
                selected: i == page,
                borderRadius: BorderRadius.circular(_thick),
                child: Builder(
                  builder: (context) => Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: _gap / 2,
                      vertical: LedgerSpacing.s8,
                    ),
                    child: mark(i, LedgerPressStates.isHot(context)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  static void _stay() {}

  static const double _short = 12;
  static const double _long = 28;
  static const double _thick = 3;
  static const double _gap = LedgerSpacing.s6;
}
