/// Brutal's anchored and edge surfaces: a popover, a hover card and a
/// on the foundation's anchored overlay, a tooltip on its tooltip; a side
/// sheet on its side sheet route; and an action sheet on the look's bottom
/// sheet.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'button.dart';
import 'lists.dart';
import 'overlays.dart';
import 'surface.dart';
import 'theme.dart';

/// A raised ruled box: the popover's and the hover card's. Reads [style]'s
/// `fill`, `edge`, `foreground`, `padding` and `textStyle`, then
/// [BrutalThemeData.popoverStyle]'s.
Widget _box(
  BuildContext context,
  double width,
  BrutalStyle? style,
  Widget child,
) {
  final theme = BrutalTheme.of(context);
  final c = theme.colors;
  final layered = DesignStyleOf([style, theme.popoverStyle], const {});
  final face = layered.on(
    BrutalFace(
      fill: c.surface,
      border: c.ink,
      foreground: c.ink,
      shadow: c.ink,
    ),
  );
  return ConstrainedBox(
    constraints: BoxConstraints(maxWidth: width),
    child: BrutalSurface(
      face: face,
      child: Padding(
        padding:
            layered.padding(Directionality.of(context)) ??
            const EdgeInsets.all(BrutalSpacing.regular),
        child: DefaultTextStyle.merge(
          style: layered.text(
            theme.textTheme.body.copyWith(color: face.foreground),
          ),
          child: child,
        ),
      ),
    ),
  );
}

/// A raised box of anything, dropped from what [builder] draws when it
/// calls `toggle`: focus moves into it and Tab stays there; Escape or a
/// press outside closes it, and focus goes back.
///
/// Its box reads [style]'s `fill`, `edge`, `foreground`, `padding` and
/// `textStyle`, then [BrutalThemeData.popoverStyle]'s.
///
/// ```dart
/// BrutalPopover(builder: (context, toggle, open) => BrutalButton('Share', onPressed: toggle), content: (context, close) => BrutalButton('Copy the link', onPressed: close))
/// ```
class BrutalPopover extends StatelessWidget {
  /// A popover over [content], opened from [builder]'s anchor.
  const BrutalPopover({
    super.key,
    required this.builder,
    required this.content,
    this.width = 320,
    this.semanticLabel,
    this.style,
  });

  /// The anchor; `toggle` opens and closes it, `open` says whether it is.
  final Widget Function(BuildContext context, VoidCallback toggle, bool open)
  builder;

  /// What it holds; `close` closes it.
  final Widget Function(BuildContext context, VoidCallback close) content;

  /// The widest it goes.
  final double width;

  /// What a screen reader calls it.
  final String? semanticLabel;

  /// Its box's style, over [BrutalThemeData.popoverStyle].
  final BrutalStyle? style;

  @override
  Widget build(BuildContext context) => DesignAnchoredOverlay(
    semanticLabel: semanticLabel,
    placement: const DesignOverlayPlacement(
      gap: BrutalSpacing.small,
      margin: BrutalSpacing.small,
      matchAnchorWidth: false,
    ),
    dampingRatio: BrutalMotion.dampingRatio,
    stiffness: BrutalMotion.overlayStiffness,
    anchorBuilder: (context, anchor) =>
        builder(context, anchor.toggle, anchor.isOpen),
    overlayBuilder: (context, info) => FadeTransition(
      opacity: info.animation,
      child: _box(context, width, style, content(context, info.close)),
    ),
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        ObjectFlagProperty<
          Widget Function(BuildContext context, VoidCallback close)
        >.has('content', content),
      )
      ..add(DoubleProperty('width', width))
      ..add(StringProperty('semanticLabel', semanticLabel, defaultValue: null))
      ..add(
        DiagnosticsProperty<BrutalStyle>('style', style, defaultValue: null),
      );
  }
}

/// A raised box shown while the pointer rests on [child] (or the keyboard
/// is on it, or after a long press): a preview of a person or a place.
/// Focus stays on [child]; what it shows must also be reachable another
/// way, as a screen reader never opens it.
///
/// Its box reads [style] as [BrutalPopover]'s does, then
/// [BrutalThemeData.popoverStyle]'s.
///
/// ```dart
/// BrutalHoverCard(content: (context) => const Text('A warehouse on the river, 400 standing'), child: BrutalLink('The Shed', onPressed: open))
/// ```
class BrutalHoverCard extends StatelessWidget {
  /// A hover card of [content] on [child].
  const BrutalHoverCard({
    super.key,
    required this.child,
    required this.content,
    this.width = 300,
    this.style,
  });

  /// The anchor.
  final Widget child;

  /// What it shows.
  final WidgetBuilder content;

  /// The widest it goes.
  final double width;

  /// Its box's style, over [BrutalThemeData.popoverStyle].
  final BrutalStyle? style;

  @override
  Widget build(BuildContext context) => DesignAnchoredOverlay(
    trigger: DesignOverlayTrigger.hover,
    focusOnOpen: false,
    placement: const DesignOverlayPlacement(
      gap: BrutalSpacing.small,
      margin: BrutalSpacing.small,
      matchAnchorWidth: false,
    ),
    dampingRatio: BrutalMotion.dampingRatio,
    stiffness: BrutalMotion.overlayStiffness,
    anchorBuilder: (context, anchor) => child,
    overlayBuilder: (context, info) => FadeTransition(
      opacity: info.animation,
      child: ExcludeSemantics(
        child: _box(context, width, style, Builder(builder: content)),
      ),
    ),
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(ObjectFlagProperty<WidgetBuilder>.has('content', content))
      ..add(DoubleProperty('width', width))
      ..add(
        DiagnosticsProperty<BrutalStyle>('style', style, defaultValue: null),
      );
  }
}

/// A short label on an ink slab over [child] (below it where there is no
/// room above), over ui_core's [DesignTooltip]: it shows after a pointer
/// rests on [child] half a second, at once when the keys bring the focus
/// there, or after a long press. The pointer may move onto it, Escape hides
/// it, and it goes as the pointer or the focus leaves; running the pointer
/// along a row of controls shows each one's at once. A screen reader hears
/// [message] as [child]'s tooltip.
///
/// Reads [style]'s `fill` (the slab), `foreground`, `padding` and
/// `textStyle`, then [BrutalThemeData.tooltipStyle]'s.
///
/// ```dart
/// BrutalTooltip(message: 'Doors open at 19:30', child: const Text('19:30'))
/// ```
class BrutalTooltip extends StatelessWidget {
  /// [child] explained by [message].
  const BrutalTooltip({
    super.key,
    required this.message,
    required this.child,
    this.style,
  });

  /// The label.
  final String message;

  /// What it explains.
  final Widget child;

  /// Its style, over [BrutalThemeData.tooltipStyle].
  final BrutalStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = BrutalTheme.of(context);
    final c = theme.colors;
    final layered = DesignStyleOf([style, theme.tooltipStyle], const {});
    return DesignTooltip(
      message: message,
      placement: _placement,
      tooltipBuilder: (context, info) => FadeTransition(
        opacity: info.animation,
        child: ExcludeSemantics(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 240),
            child: ColoredBox(
              color: layered.fill ?? c.ink,
              child: Padding(
                padding:
                    layered.padding(Directionality.of(context)) ??
                    const EdgeInsets.symmetric(
                      horizontal: BrutalSpacing.small,
                      vertical: 6,
                    ),
                child: Text(
                  message,
                  style: layered.text(
                    theme.textTheme.caption.copyWith(
                      color:
                          layered.foreground ??
                          c.onColor(layered.fill ?? c.ink),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      child: child,
    );
  }

  // Above the child and centred on it, 6 from it, a gutter in from the
  // screen's edges; below it where two lines of a tip do not fit above.
  static const DesignOverlayPlacement _placement = DesignOverlayPlacement(
    side: DesignOverlaySide.above,
    align: DesignOverlayAlign.center,
    gap: 6,
    margin: BrutalSpacing.small,
    preferredExtent: 48,
    matchAnchorWidth: false,
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('message', message))
      ..add(
        DiagnosticsProperty<BrutalStyle>('style', style, defaultValue: null),
      );
  }
}

/// Opens a panel the full height of the screen from its end edge (start,
/// with [fromStart]) under the look's scrim: a title row with a square
/// close cell, a rule, then [builder]'s content, scrolling. A drag toward
/// the edge, Escape or a press on the scrim closes it.
///
/// Its panel reads [style]'s `fill`, `edge`, `foreground`, `padding` (round
/// the content) and `textStyle` (the title), then
/// [BrutalThemeData.sideSheetStyle]'s.
///
/// ```dart
/// showBrutalSideSheet<void>(context: context, title: 'Filters', builder: (context) => filters)
/// ```
Future<T?> showBrutalSideSheet<T>({
  required BuildContext context,
  required String title,
  required WidgetBuilder builder,
  double width = 380,
  bool fromStart = false,
  BrutalStyle? style,
}) {
  final theme = BrutalTheme.of(context);
  final words = DesignLocalizations.of(context);
  return Navigator.of(context, rootNavigator: true).push<T>(
    DesignSideSheetRoute<T>(
      edge: fromStart ? DesignSheetEdge.start : DesignSheetEdge.end,
      width: width,
      barrierColor: theme.colors.scrim,
      barrierLabel: words.modalBarrierDismissLabel,
      semanticLabel: title,
      builder: (context, sheet) => BrutalTheme(
        data: theme,
        child: _SidePanel(
          title: title,
          sheet: sheet,
          builder: builder,
          style: style,
        ),
      ),
    ),
  );
}

class _SidePanel extends StatelessWidget {
  const _SidePanel({
    required this.title,
    required this.sheet,
    required this.builder,
    this.style,
  });

  final String title;
  final DesignSheetInfo sheet;
  final WidgetBuilder builder;
  final BrutalStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = BrutalTheme.of(context);
    final c = theme.colors;
    final pad = MediaQuery.paddingOf(context);
    final words = DesignLocalizations.of(context);
    final layered = DesignStyleOf([style, theme.sideSheetStyle], const {});
    final edge = layered.side?.color ?? layered.edge ?? c.ink;
    final ink0 = layered.foreground ?? c.ink;
    final rule = BorderSide(color: edge, width: theme.borderWidth);
    final onEnd = sheet.side == AxisDirection.right
        ? Directionality.of(context) == TextDirection.ltr
        : Directionality.of(context) == TextDirection.rtl;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: layered.fill ?? c.surface,
        border: BorderDirectional(
          start: onEnd ? rule : BorderSide.none,
          end: onEnd ? BorderSide.none : rule,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(top: pad.top, bottom: pad.bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 56,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(
                        start: BrutalSpacing.large,
                      ),
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Semantics(
                          header: true,
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: layered.text(
                              theme.textTheme.title.copyWith(color: ink0),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  BrutalRule(vertical: true, color: edge),
                  SizedBox(
                    width: 56,
                    child: DesignPressable(
                      onPressed: sheet.close,
                      semanticLabel: words.closeButtonLabel,
                      builder: (context, states, _) {
                        final lit = states.contains(WidgetState.pressed);
                        final ink = lit ? c.paper : ink0;
                        return AnimatedBrutalSurface(
                          stiffness: BrutalMotion.colorStiffness,
                          face: BrutalFace(
                            fill: lit ? c.ink : c.ink.withValues(alpha: 0),
                            border: c.ink.withValues(alpha: 0),
                            foreground: ink,
                            borderWidth: 0,
                          ),
                          child: CustomPaint(
                            foregroundPainter:
                                states.contains(WidgetState.focused)
                                ? BrutalInsetFocusPainter(ink)
                                : null,
                            child: Center(
                              child: Icon(LucideIcons.x, size: 24, color: ink),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            BrutalRule(color: edge),
            Expanded(
              child: SingleChildScrollView(
                padding:
                    layered.padding(Directionality.of(context)) ??
                    const EdgeInsets.all(BrutalSpacing.large),
                child: DesignKeylineRegion(
                  label: title,
                  child: DefaultTextStyle.merge(
                    style: theme.textTheme.body.copyWith(color: ink0),
                    child: Builder(builder: builder),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One choice in an action sheet.
@immutable
class BrutalSheetAction<T> {
  /// A choice reading [label] that answers [value].
  const BrutalSheetAction({
    required this.label,
    required this.value,
    this.icon,
    this.isDestructiveAction = false,
  });

  /// What it says.
  final String label;

  /// What the sheet answers when it is chosen.
  final T value;

  /// An icon before the label.
  final IconData? icon;

  /// Whether it destroys: drawn in the danger colour.
  final bool isDestructiveAction;
}

/// Asks for one of [actions] from a sheet at the foot of the screen (a
/// framed box from 600 wide): [message] over the choices, stacked on rules
/// in one box, and a cancel button under them. Answers the chosen action's
/// value, or null when cancelled.
///
/// Its rows read [style]'s `fill` (the box), `edge` (its rules),
/// `foreground` (in each row's states), `padding`, `minimumSize` (a row's
/// height), `textStyle` and `iconSize`, then
/// [BrutalThemeData.actionSheetStyle]'s; the sheet round them is a
/// [showBrutalBottomSheet]'s.
///
/// ```dart
/// final pick = await showBrutalActionSheet<String>(context: context, title: 'This ticket', actions: [BrutalSheetAction(label: 'Transfer', value: 'transfer')]);
/// ```
Future<T?> showBrutalActionSheet<T>({
  required BuildContext context,
  required String title,
  required List<BrutalSheetAction<T>> actions,
  String? message,
  String cancelLabel = 'Cancel',
  BrutalStyle? style,
}) => showBrutalBottomSheet<T>(
  context: context,
  title: title,
  builder: (context) {
    final theme = BrutalTheme.of(context);
    final c = theme.colors;
    final layers = [style, theme.actionSheetStyle];
    final box = DesignStyleOf(layers, const {});
    final edge = box.side?.color ?? box.edge ?? c.ink;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (message != null) ...[
          Text(message, style: theme.textTheme.secondary),
          const SizedBox(height: BrutalSpacing.regular),
        ],
        BrutalSurface(
          face: BrutalFace(
            fill: box.fill ?? c.surface,
            border: edge,
            foreground: c.ink,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (i, a) in actions.indexed) ...[
                if (i > 0) BrutalRule(color: edge),
                DesignPressable(
                  onPressed: () => Navigator.of(context).pop(a.value),
                  semanticLabel: a.label,
                  builder: (context, states, _) {
                    final layered = DesignStyleOf(layers, states);
                    final lit = states.contains(WidgetState.pressed);
                    final tone = a.isDestructiveAction ? c.danger : c.ink;
                    final ink =
                        layered.foreground ?? (lit ? c.onColor(tone) : tone);
                    return AnimatedBrutalSurface(
                      stiffness: BrutalMotion.colorStiffness,
                      face: BrutalFace(
                        fill: lit ? tone : tone.withValues(alpha: 0),
                        border: tone.withValues(alpha: 0),
                        foreground: ink,
                        borderWidth: 0,
                      ),
                      child: CustomPaint(
                        foregroundPainter: states.contains(WidgetState.focused)
                            ? BrutalInsetFocusPainter(ink)
                            : null,
                        child: SizedBox(
                          height:
                              layered.minimumSize?.height ??
                              theme.controlHeight + 8,
                          child: Padding(
                            padding:
                                layered.padding(Directionality.of(context)) ??
                                const EdgeInsets.symmetric(
                                  horizontal: BrutalSpacing.regular,
                                ),
                            child: Row(
                              children: [
                                if (a.icon != null) ...[
                                  Icon(
                                    a.icon,
                                    size: layered.iconSize ?? 20,
                                    color: ink,
                                  ),
                                  const SizedBox(width: BrutalSpacing.medium),
                                ],
                                Expanded(
                                  child: Text(
                                    a.label,
                                    style: layered.text(
                                      theme.textTheme.label.copyWith(
                                        color: ink,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: BrutalSpacing.regular),
        BrutalButton(cancelLabel, onPressed: () => Navigator.of(context).pop()),
      ],
    );
  },
);
