import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../internal/menu_row.dart';
import '../../internal/paint.dart';
import '../../internal/tip_hold.dart';
import '../../theme.dart';

/// A little more about something, on a panel beside the control [builder]
/// paints: an explanation ("What counts as a visitor?"), a short form (a
/// filter of two answers). The page's face (by night the raised band)
/// floating on a hairline and the soft shadow, as an open list does, [width]
/// wide, with its [title] as a heading over [content]: ui_core's
/// [RawPopover] as a popover, Civic's painting.
///
/// A press on the control, Enter or Space opens it and the focus moves
/// into it (Tab stays inside); Escape, a press outside and Android's back
/// close it, and the focus goes back to the control. Nothing opens it on
/// hover alone. What the reader must know to finish the page stands on the
/// page, never only here.
///
/// Reads [CivicStyle]'s fill and edge (the panel), foreground, padding and
/// textStyle (the title): its `style:`, then [CivicThemeData.popoverStyle].
///
/// ```dart
/// CivicPopover(
///   title: 'Who counts as a visitor',
///   content: const Text('Anyone staying less than 14 days who does not live at the address.'),
///   builder: (context, anchor) => CivicLink(
///     onPressed: anchor.toggle,
///     child: const Text('Who counts as a visitor?'),
///   ),
/// )
/// ```
class CivicPopover extends StatelessWidget {
  /// A popover of [content] opened from [builder]'s control.
  const CivicPopover({
    super.key,
    required this.builder,
    required this.content,
    this.title,
    this.semanticLabel,
    this.width = 320,
    this.controller,
    this.onOpenChanged,
    this.side = RawPopoverSide.below,
    this.align = RawPopoverAlign.start,
    this.style,
  });

  /// Paints the control that opens it: call the anchor's `toggle` on its
  /// press.
  final Widget Function(BuildContext context, RawOverlayAnchor anchor) builder;

  /// What it holds.
  final Widget content;

  /// Its heading.
  final String? title;

  /// What a screen reader calls it; null: [title].
  final String? semanticLabel;

  /// Its width, narrowed to the screen's less its margins.
  final double width;

  /// Opens and closes it from outside; null: its own.
  final MenuController? controller;

  /// Told when it opens (true) and closes (false).
  final ValueChanged<bool>? onOpenChanged;

  /// The side of the control it prefers; the other where there is no room.
  final RawPopoverSide side;

  /// Which edge of the control it lines up with.
  final RawPopoverAlign align;

  /// Overrides for this popover's look.
  final CivicStyle? style;

  @override
  Widget build(BuildContext context) => RawPopover(
    controller: controller,
    semanticLabel: semanticLabel ?? title,
    onOpenChanged: onOpenChanged,
    dampingRatio: CivicMotion.state.dampingRatio,
    stiffness: CivicMotion.state.stiffness,
    placement: RawPopoverPlacement(
      side: side,
      align: align,
      gap: CivicSpacing.s8,
      preferredExtent: 200,
      matchAnchorWidth: false,
      maxWidth: width,
    ),
    // While the popover is open the control's tip stands down.
    anchorBuilder: (context, anchor) =>
        CivicTipHold(held: anchor.isOpen, child: builder(context, anchor)),
    overlayBuilder: (context, info) {
      final t = context.civicTheme;
      final text = context.civicText;
      final so = RawStyleOf([style, t.popoverStyle], const {});
      final heading = title;
      final ink = so.foreground ?? t.textPrimary;
      // By night what floats stands on the raised band, and what it holds
      // takes that band for its page.
      final face = so.fill ?? (t.isDark ? t.surface : t.background);
      return civicRise(
        animation: info.animation,
        fromAbove: info.side == RawPopoverSide.below,
        child: SizedBox(
          width: width < info.maxSize.width ? width : info.maxSize.width,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: info.maxSize.height),
            child: DecoratedBox(
              decoration: civicFloating(
                face: face,
                hairline: so.edge ?? t.rule,
                dark: t.isDark,
              ),
              child: CivicTheme(
                data: t.copyWith(background: face),
                child: SingleChildScrollView(
                  padding:
                      so.padding(Directionality.of(context)) ??
                      const EdgeInsets.all(CivicSpacing.s16),
                  child: DefaultTextStyle(
                    style: text.body.copyWith(color: ink),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: CivicSpacing.s8,
                      children: [
                        if (heading != null)
                          Semantics(
                            header: true,
                            child: Text(
                              heading,
                              style: text.headingS
                                  .merge(so.textStyle)
                                  .copyWith(color: ink),
                            ),
                          ),
                        content,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('title', title, defaultValue: null))
      ..add(StringProperty('semanticLabel', semanticLabel, defaultValue: null))
      ..add(DoubleProperty('width', width, defaultValue: 320))
      ..add(
        EnumProperty<RawPopoverSide>(
          'side',
          side,
          defaultValue: RawPopoverSide.below,
        ),
      )
      ..add(
        EnumProperty<RawPopoverAlign>(
          'align',
          align,
          defaultValue: RawPopoverAlign.start,
        ),
      )
      ..add(
        DiagnosticsProperty<CivicStyle>('style', style, defaultValue: null),
      );
  }
}
