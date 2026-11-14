/// Slides turned one at a time, with arrows, dots and play, painted on
/// ui_core's carousel.
library;

import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../internal/edge_fade.dart';
import '../internal/kit_paint.dart';
import '../internal/styled.dart';
import '../localizations.dart';
import '../theme.dart';
import 'button.dart';
import 'icon_button.dart';
import 'pagination.dart';

/// Slides one at a time, a swipe or a press apart: a product's pictures, an
/// onboarding's cards, featured items. Each slide stands on the card's
/// outline (`shapes.medium`, clipped); under them, two small outlined
/// arrows, Minimal's page dots between them on the slides' middle, and a
/// pause button beside the next arrow when it plays on its own. Under 1,
/// [viewportFraction] shows the neighbours' edges: the frame cuts them
/// square, and they fade at the cut, as every sideways cut does.
///
/// The slides are one tab stop the arrows turn (a focus ring round them
/// while the keyboard is there); a screen reader hears "Slide 2 of 5". With
/// [autoplay] it turns every so long, pausing under a pointer or the
/// keyboard, and never on its own under Reduce Motion. The behaviour is
/// ui_core's ([DesignCarousel]); Minimal paints it.
///
/// ```dart
/// MinimalCarouselView(height: 220, children: [for (final slot in photos) MinimalMedia.media(slot)])
/// ```
class MinimalCarouselView extends StatelessWidget {
  /// A carousel of [children].
  const MinimalCarouselView({
    super.key,
    required this.children,
    this.height = 200,
    this.viewportFraction = 1,
    this.loop = false,
    this.autoplay,
    this.initialPage = 0,
    this.onPageChanged,
    this.label,
    this.showControls = true,
    this.focusNode,
    this.autofocus = false,
  });

  /// The carousel's keyboard stop (the arrow keys turn the slides).
  final FocusNode? focusNode;

  /// Whether it takes focus when it first shows.
  final bool autofocus;

  /// The slides, in order.
  final List<Widget> children;

  /// The slides' height.
  final double height;

  /// Each slide's share of the width.
  final double viewportFraction;

  /// Whether the last slide turns on to the first, and back.
  final bool loop;

  /// How long each slide shows while it plays; null: it does not play.
  final Duration? autoplay;

  /// The slide it starts on.
  final int initialPage;

  /// Called when the slide shown changes.
  final ValueChanged<int>? onPageChanged;

  /// What a screen reader calls it.
  final String? label;

  /// Whether the arrows, dots and pause stand under the slides.
  final bool showControls;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final words = MinimalLocalizations.of(context);
    final shape = t.shapes.medium;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return DesignCarousel(
      itemCount: children.length,
      initialPage: initialPage,
      viewportFraction: viewportFraction,
      loop: loop,
      autoplayInterval: autoplay,
      onPageChanged: onPageChanged,
      focusNode: focusNode,
      autofocus: autofocus,
      semanticLabel: label ?? words.carousel,
      slideLabel: words.slideOf,
      duration: context.minimalStill ? Duration.zero : MinimalMotion.slow,
      itemBuilder: (context, i) => Padding(
        padding: EdgeInsets.symmetric(
          horizontal: viewportFraction < 1 ? MinimalSpacing.s4 : 0,
        ),
        child: minimalClip(shape, child: children[i]),
      ),
      layoutBuilder: (context, viewport, c) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: height,
            foregroundDecoration: minimalStateLayer(t, shape, {
              if (c.focused) WidgetState.focused,
            }, ground: minimalGround(context)),
            // The frame holds the shape, not only each slide: mid-swipe the
            // viewport's edge cuts the moving slide, and that cut keeps the
            // corners a slide at rest has. Peeking, the frame is no slide's:
            // it cuts the neighbours square and fades them at the cut (a
            // rounded cut ended their rims before their words).
            child: viewportFraction < 1
                ? ClipRect(child: MinimalEdgeFade(child: viewport))
                : minimalClip(shape, child: viewport),
          ),
          if (showControls && c.count > 1) ...[
            const MinimalGap(MinimalSpacing.s8),
            // The dots stand between two equal sides, so they are centred on
            // the slides whatever controls stand at either end: a carousel
            // that plays lines its dots up with one that does not.
            Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: MinimalIconButton(
                      rtl ? LucideIcons.chevronRight : LucideIcons.chevronLeft,
                      label: words.previousSlide,
                      variant: MinimalIconButtonVariant.outline,
                      size: MinimalButtonSize.small,
                      onPressed: c.previous,
                    ),
                  ),
                ),
                // The long dot travels with the slides, mid-swipe too.
                ValueListenableBuilder<double>(
                  valueListenable: c.position,
                  builder: (context, at, _) => MinimalPageDots(
                    count: c.count,
                    selectedIndex: c.page,
                    position: at,
                    onChanged: c.goToPage,
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (c.togglePlay != null) ...[
                          MinimalIconButton(
                            c.playing ? LucideIcons.pause : LucideIcons.play,
                            label: c.playing ? words.pause : words.play,
                            // One row of controls, one register: the
                            // arrows'.
                            variant: MinimalIconButtonVariant.outline,
                            size: MinimalButtonSize.small,
                            onPressed: c.togglePlay,
                          ),
                          const MinimalGap(MinimalSpacing.s8),
                        ],
                        MinimalIconButton(
                          rtl
                              ? LucideIcons.chevronLeft
                              : LucideIcons.chevronRight,
                          label: words.nextSlide,
                          variant: MinimalIconButtonVariant.outline,
                          size: MinimalButtonSize.small,
                          onPressed: c.next,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
