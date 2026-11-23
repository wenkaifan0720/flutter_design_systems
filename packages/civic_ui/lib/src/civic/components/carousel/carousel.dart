import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../internal/paint.dart';
import '../../internal/spring.dart';
import '../../theme.dart';
import '../button/button.dart';
import '../page-dots/page_dots.dart';

/// Slides a reader turns through, one at a time: [itemCount] of them that
/// [itemBuilder] builds, [height] tall in a frame with a card's corners;
/// under them the page marks with "2 of 5", then "Previous" and "Next" as
/// worded buttons. It never turns on its own. A swipe turns it too, and
/// so do the arrow keys while the keyboard is on the slides (the frame
/// then stands in the yellow ring). A screen reader hears "Slide 2 of 5"
/// as each lands. ui_core's [RawCarousel], Civic's painting.
///
/// What a slide says must be on the page another way too (a list, a
/// link): a reader may never turn to it.
///
/// Reads [CivicStyle]'s fill (the frame's ground): its `style:`, then
/// [CivicThemeData.carouselStyle]; the buttons and marks are the look's.
///
/// ```dart
/// CivicCarousel(
///   semanticLabel: 'Photos of Zone B',
///   itemCount: 3,
///   itemBuilder: (context, index) => Center(child: Text('Photo $index')),
/// )
/// ```
class CivicCarousel extends StatelessWidget {
  /// [itemCount] slides.
  const CivicCarousel({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.semanticLabel,
    this.height = 240,
    this.viewportFraction = 1,
    this.initialPage = 0,
    this.onPageChanged,
    this.previousLabel = 'Previous',
    this.nextLabel = 'Next',
    this.style,
  });

  /// How many slides there are.
  final int itemCount;

  /// Builds slide `index`.
  final IndexedWidgetBuilder itemBuilder;

  /// What a screen reader calls the slides: "Photos of Zone B".
  final String semanticLabel;

  /// The slides' height.
  final double height;

  /// Each slide's share of the view (under 1 shows the neighbours).
  final double viewportFraction;

  /// The slide it starts on.
  final int initialPage;

  /// Called with the slide shown as it changes.
  final ValueChanged<int>? onPageChanged;

  /// The button that turns back.
  final String previousLabel;

  /// The button that turns on.
  final String nextLabel;

  /// Overrides for this carousel's look.
  final CivicStyle? style;

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final so = DesignStyleOf([style, t.carouselStyle], const {});
    return RawCarousel(
      itemCount: itemCount,
      itemBuilder: itemBuilder,
      initialPage: initialPage,
      viewportFraction: viewportFraction,
      onPageChanged: onPageChanged,
      semanticLabel: semanticLabel,
      duration: const Duration(milliseconds: 300),
      layoutBuilder: (context, viewport, controls) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: CivicSpacing.s12,
        children: [
          CivicSpringValue(
            value: controls.focused ? 1 : 0,
            spring: CivicMotion.focus,
            effects: true,
            child: SizedBox(
              height: height,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(CivicMetrics.cardCorner),
                child: ColoredBox(color: so.fill ?? t.surface, child: viewport),
              ),
            ),
            builder: (context, focus, slides) => DecoratedBox(
              // The keyboard on the slides: the well's focus, the yellow
              // ring outside an ink edge, over the slides and never across
              // them.
              position: DecorationPosition.foreground,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(CivicMetrics.cardCorner),
                border: Border.all(
                  color: t.focus.withValues(alpha: focus),
                  width: CivicMetrics.focusRing,
                  strokeAlign: BorderSide.strokeAlignOutside,
                ),
              ),
              child: DecoratedBox(
                position: DecorationPosition.foreground,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(CivicMetrics.cardCorner),
                  border: Border.all(
                    color: t.onFocus.withValues(alpha: focus),
                    width: CivicMetrics.edge,
                  ),
                ),
                child: slides,
              ),
            ),
          ),
          Center(
            child: CivicPageDots(
              pageCount: controls.count,
              selectedIndex: controls.page,
              onPageChanged: controls.goToPage,
            ),
          ),
          // Previous at the start and Next at the end; one over the other
          // when the words are too large for one line.
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: CivicSpacing.s8,
            runSpacing: CivicSpacing.s8,
            children: [
              CivicButton.secondary(
                expand: false,
                onPressed: controls.previous,
                child: Text(previousLabel),
              ),
              CivicButton.secondary(
                expand: false,
                onPressed: controls.next,
                child: Text(nextLabel),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IntProperty('itemCount', itemCount))
      ..add(StringProperty('semanticLabel', semanticLabel))
      ..add(DoubleProperty('height', height, defaultValue: 240))
      ..add(
        DoubleProperty('viewportFraction', viewportFraction, defaultValue: 1),
      )
      ..add(
        DiagnosticsProperty<CivicStyle>('style', style, defaultValue: null),
      );
  }
}
