/// Slides turned one at a time under a ledger's page marks, on ui_core's
/// carousel.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../internal/corners.dart';
import '../../theme.dart';
import '../icon-button/icon_button.dart';
import '../page-dots/page_dots.dart';

/// Slides turned one at a time (this month's highlights, a goal's
/// milestones): each slide in the slip's small corners, [height] tall at
/// the standard text size and growing with the reader's, a
/// swipe, the arrow keys or the ringed arrows at its foot turning it in
/// Ledger's one motion, and the page dots between the arrows saying where it
/// stands (each a press to that slide). [viewportFraction] under 1 shows a
/// sliver of its neighbours. A screen reader hears it as [semanticLabel]
/// and each slide as its place of the count.
///
/// ```dart
/// LedgerCarousel(semanticLabel: 'Highlights', itemCount: 3, itemBuilder: (context, i) => Text('Slide $i'))
/// ```
class LedgerCarousel extends StatelessWidget {
  /// [itemCount] slides [itemBuilder] builds.
  const LedgerCarousel({
    required this.itemCount,
    required this.itemBuilder,
    required this.semanticLabel,
    this.height = 180,
    this.viewportFraction = 1,
    this.onPageChanged,
    super.key,
  }) : assert(itemCount >= 0),
       assert(height > 0),
       assert(viewportFraction > 0 && viewportFraction <= 1);

  /// How many slides.
  final int itemCount;

  /// Builds slide `index`.
  final IndexedWidgetBuilder itemBuilder;

  /// What a screen reader calls it.
  final String semanticLabel;

  /// The slides' height.
  final double height;

  /// Each slide's share of the width.
  final double viewportFraction;

  /// Called as the slide shown changes.
  final ValueChanged<int>? onPageChanged;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IntProperty('itemCount', itemCount))
      ..add(
        ObjectFlagProperty<IndexedWidgetBuilder>.has(
          'itemBuilder',
          itemBuilder,
        ),
      )
      ..add(StringProperty('semanticLabel', semanticLabel))
      ..add(DoubleProperty('height', height))
      ..add(DoubleProperty('viewportFraction', viewportFraction))
      ..add(
        ObjectFlagProperty<ValueChanged<int>>.has(
          'onPageChanged',
          onPageChanged,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return RawCarousel(
      itemCount: itemCount,
      semanticLabel: semanticLabel,
      viewportFraction: viewportFraction,
      onPageChanged: onPageChanged,
      duration: LedgerMotion.of(context, LedgerMotion.base),
      itemBuilder: (context, i) => Padding(
        padding: EdgeInsets.symmetric(
          horizontal: viewportFraction < 1 ? LedgerSpacing.s4 : 0,
        ),
        child: ClipRRect(
          borderRadius: ledgerStep(t, RawCorner.small),
          child: itemBuilder(context, i),
        ),
      ),
      layoutBuilder: (context, viewport, controls) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: LedgerSpacing.s12,
        children: [
          DecoratedBox(
            position: DecorationPosition.foreground,
            decoration: BoxDecoration(
              borderRadius: ledgerStep(t, RawCorner.small),
              border: controls.focused
                  ? Border.all(color: t.textPrimary, width: 1.5)
                  : null,
            ),
            child: SizedBox(
              height: MediaQuery.textScalerOf(context).scale(height),
              child: viewport,
            ),
          ),
          Row(
            children: [
              LedgerIconButton.outlined(
                rtl ? LucideIcons.chevronRight : LucideIcons.chevronLeft,
                semanticLabel: 'Previous',
                size: LedgerIconButtonSize.small,
                tapAlignment: AlignmentDirectional.centerStart,
                onPressed: controls.previous,
              ),
              Expanded(
                child: Center(
                  child: LedgerPageDots(
                    pageCount: controls.count,
                    page: controls.page,
                    onChanged: controls.goToPage,
                  ),
                ),
              ),
              LedgerIconButton.outlined(
                rtl ? LucideIcons.chevronLeft : LucideIcons.chevronRight,
                semanticLabel: 'Next',
                size: LedgerIconButtonSize.small,
                tapAlignment: AlignmentDirectional.centerEnd,
                onPressed: controls.next,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
