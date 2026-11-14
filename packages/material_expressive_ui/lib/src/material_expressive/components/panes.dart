/// Panes ui_core's behaviours hold, painted in Material's hand: a scroll
/// area's scrollbar ([ExpressiveScrollArea], on `DesignScrollArea`), two
/// panes and the handle between them ([ExpressiveResizable], on
/// `DesignSplitView`) and the modal side sheet ([ExpressiveSheet], on
/// `DesignSideSheetRoute`).
library;

import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../elevation.dart';
import '../icons.dart';
import '../internal/focus_ring.dart';
import '../internal/tokens/keys.g.dart';
import '../internal/tokens/scrim_tokens.g.dart';
import '../motion.dart';
import '../spacing.dart';
import '../strings.dart';
import '../theme.dart';
import 'icon_buttons.dart';
import 'lists.dart' show ExpressiveDivider;

// --- The scroll area ---------------------------------------------------------

/// Material's scrollbar (`_ScrollbarDefaultsM3`): 8dp, 12dp with its track
/// under a pointer, 2dp in from the edge, the full corner.
const double _barThickness = 8;
const double _barThicknessHot = 12;
const double _barMargin = 2;

/// [child], a scroll view on [controller], with Material's scrollbar on its
/// end edge (or its bottom, [axis] horizontal): a pill thumb of `onSurface`
/// (10% light, 30% dark; 50% and 65% under a pointer; 60% and 75% while
/// dragged), 8dp wide, 12dp over a faint track while a pointer is on the
/// bar, fading out after the scroll stops. Under the keyboard the area
/// takes focus (its own tab stop) and wears the focus ring inside its
/// edge; the arrows scroll by a step, Page Up and Down by a page, Home and
/// End to the ends (ui_core's `DesignScrollArea`).
///
/// ```dart
/// ExpressiveScrollArea(controller: scroll, child: ListView(controller: scroll, children: rows))
/// ```
class ExpressiveScrollArea extends StatelessWidget {
  /// A scroll area around [child], which scrolls on [controller].
  const ExpressiveScrollArea({
    required this.controller,
    required this.child,
    this.axis = Axis.vertical,
    this.alwaysShown = false,
    this.focusable = true,
    this.semanticLabel,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  /// The controller [child] scrolls on.
  final ScrollController controller;

  /// The scroll view.
  final Widget child;

  /// The way it scrolls.
  final Axis axis;

  /// Whether the thumb stays while there is anything to scroll.
  final bool alwaysShown;

  /// Whether the area is a tab stop of its own.
  final bool focusable;

  /// What a screen reader calls the area.
  final String? semanticLabel;

  /// The area's focus node (with [focusable]); null lets it keep its own.
  final FocusNode? focusNode;

  /// Whether the area takes focus when first built (with [focusable]).
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final c = t.colors;
    final dark = t.brightness == Brightness.dark;
    final vertical = axis == Axis.vertical;
    return DesignScrollArea(
      controller: controller,
      axis: axis,
      thickness: _barThicknessHot + 2 * _barMargin,
      minThumbLength: ExpressiveSpacing.s48,
      focusable: focusable,
      focusNode: focusNode,
      autofocus: autofocus,
      semanticLabel: semanticLabel,
      visibility: alwaysShown
          ? DesignScrollbarVisibility.always
          : DesignScrollbarVisibility.auto,
      trackBuilder: (context, thumb) => ExpressiveSpringValue(
        value: thumb.states.isEmpty ? 0 : 1,
        motion: ExpressiveMotionKey.fastEffects,
        builder: (context, shown, _) => Opacity(
          opacity: shown.clamp(0, 1),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: c.onSurface.withValues(alpha: dark ? 0.05 : 0.03),
              border: BorderDirectional(
                start: vertical
                    ? BorderSide(
                        color: c.onSurface.withValues(alpha: dark ? 0.25 : 0.1),
                      )
                    : BorderSide.none,
                top: vertical
                    ? BorderSide.none
                    : BorderSide(
                        color: c.onSurface.withValues(alpha: dark ? 0.25 : 0.1),
                      ),
              ),
            ),
          ),
        ),
      ),
      thumbBuilder: (context, thumb) {
        final dragged = thumb.states.contains(WidgetState.pressed);
        final hovered = thumb.states.contains(WidgetState.hovered);
        final alpha = dragged
            ? (dark ? 0.75 : 0.6)
            : hovered
            ? (dark ? 0.65 : 0.5)
            : (dark ? 0.3 : 0.1);
        return ExpressiveSpringValue(
          value: thumb.visible ? 1 : 0,
          motion: ExpressiveMotionKey.fastEffects,
          builder: (context, shown, _) => Opacity(
            opacity: shown.clamp(0, 1),
            child: Padding(
              padding: const EdgeInsets.all(_barMargin),
              child: Align(
                alignment: vertical
                    ? AlignmentDirectional.centerEnd
                    : Alignment.bottomCenter,
                child: ExpressiveSpringValue(
                  value: dragged || hovered ? _barThicknessHot : _barThickness,
                  motion: ExpressiveMotionKey.fastSpatial,
                  // The thumb fills its run: under the Align's loose
                  // constraints a childless box sized to nothing, so the
                  // thumb was never drawn (11-13).
                  builder: (context, extent, _) => SizedBox(
                    width: vertical ? extent : double.infinity,
                    height: vertical ? double.infinity : extent,
                    child: DecoratedBox(
                      decoration: ShapeDecoration(
                        color: c.onSurface.withValues(alpha: alpha),
                        shape: t.shapes.full,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      frameBuilder: (context, focused, area) => CustomPaint(
        foregroundPainter: focused
            ? _FrameRing(
                shape: t.shapes.medium,
                color: c.secondary,
                thickness: 3,
                textDirection: Directionality.of(context),
                inward: true,
              )
            : null,
        child: area,
      ),
      child: child,
    );
  }
}

/// The focus ring round a part ui_core gives focus to: inside the edge of
/// a scroll area, outside a drag handle.
class _FrameRing extends CustomPainter {
  const _FrameRing({
    required this.shape,
    required this.color,
    required this.thickness,
    required this.textDirection,
    required this.inward,
  });

  final OutlinedBorder shape;
  final Color color;
  final double thickness;
  final TextDirection textDirection;
  final bool inward;

  @override
  void paint(Canvas canvas, Size size) => expressivePaintFocusRing(
    canvas,
    Offset.zero & size,
    shape,
    color: color,
    thickness: thickness,
    offset: 2,
    textDirection: textDirection,
    inward: inward,
  );

  @override
  bool shouldRepaint(_FrameRing old) =>
      old.shape != shape ||
      old.color != color ||
      old.thickness != thickness ||
      old.textDirection != textDirection ||
      old.inward != inward;
}

// --- The resizable panes -----------------------------------------------------

/// Compose's adaptive drag handle (`VerticalDragHandle`): a 4 x 48dp pill,
/// 12 x 52dp while dragged.
const Size _handle = Size(4, 48);
const Size _handlePressed = Size(12, 52);

/// [first] and [second] beside each other (or stacked, [axis] vertical)
/// across a 24dp gutter, the drag handle of Material's adaptive panes in
/// it (Compose's `VerticalDragHandle`): a 4 x 48dp pill of `outline`,
/// `onSurface` under a pointer or the keyboard, which springs to 12 x 52dp
/// while dragged and wears the focus ring under the keyboard. The handle
/// is ui_core's: drag it, or focus it and press the arrows (Enter folds the
/// first pane away and back); a screen reader hears it as an adjustable
/// "Resize" ([ExpressiveLocalizations.resize]) at its percentage.
///
/// ```dart
/// ExpressiveResizable(first: folders, second: messages, initialFraction: 0.3, minFirst: 200)
/// ```
class ExpressiveResizable extends StatelessWidget {
  /// [first] and [second], split.
  const ExpressiveResizable({
    required this.first,
    required this.second,
    this.axis = Axis.horizontal,
    this.fraction,
    this.initialFraction = 0.5,
    this.onChanged,
    this.minFirst = 0,
    this.minSecond = 0,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  /// The start (or top) pane.
  final Widget first;

  /// The end (or bottom) pane.
  final Widget second;

  /// Side by side ([Axis.horizontal]) or stacked.
  final Axis axis;

  /// The first pane's share of the room, when the parent holds it.
  final double? fraction;

  /// The first pane's share to start with, when [fraction] is null.
  final double initialFraction;

  /// Each new share.
  final ValueChanged<double>? onChanged;

  /// The first pane's least extent.
  final double minFirst;

  /// The second pane's least extent.
  final double minSecond;

  /// The drag handle's focus node; null lets the handle keep its own.
  final FocusNode? focusNode;

  /// Whether the drag handle takes focus when first built.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final c = t.colors;
    return DesignSplitView(
      first: first,
      second: second,
      axis: axis,
      fraction: fraction,
      initialFraction: initialFraction,
      onChanged: onChanged,
      minFirst: minFirst,
      minSecond: minSecond,
      focusNode: focusNode,
      autofocus: autofocus,
      dividerThickness: ExpressiveSpacing.s24,
      hitExtent: ExpressiveSpacing.s24,
      semanticLabel: ExpressiveLocalizations.of(context).resize,
      dividerBuilder: (context, states, axis) {
        final dragged = states.contains(WidgetState.pressed);
        final lit =
            dragged ||
            states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.focused);
        final focused =
            states.contains(WidgetState.focused) &&
            !states.contains(WidgetState.disabled);
        final size = dragged ? _handlePressed : _handle;
        final across = axis == Axis.horizontal;
        return Center(
          child: ExpressiveSpringSize(
            value: across ? size : Size(size.height, size.width),
            motion: ExpressiveMotionKey.fastSpatial,
            builder: (context, value, _) {
              final pill = SizedBox.fromSize(
                size: value,
                child: DecoratedBox(
                  decoration: ShapeDecoration(
                    color: lit ? c.onSurface : c.outline,
                    shape: t.shapes.full,
                  ),
                ),
              );
              if (!focused) return pill;
              return CustomPaint(
                foregroundPainter: _FrameRing(
                  shape: t.shapes.full,
                  color: c.secondary,
                  thickness: 3,
                  textDirection: Directionality.of(context),
                  inward: false,
                ),
                child: pill,
              );
            },
          ),
        );
      },
    );
  }
}

// --- The side sheet ----------------------------------------------------------

/// Material's modal side sheet: the panel on `surfaceContainerLow` at
/// level 1, the large corner on its inner edge, its headline in
/// `titleLarge` `onSurfaceVariant` beside a close button, [child] under it
/// and [actions] in a row under a divider at its foot. Open it with
/// [ExpressiveSheet.show]: it slides in from the end edge (or the start)
/// over the scrim at 32%, closes on the scrim, Escape, its close button or
/// a fling toward its edge, and holds the keyboard inside while open
/// (ui_core's `DesignSideSheetRoute`).
///
/// ```dart
/// ExpressiveSheet.show(context, title: 'Filters', builder: (context) => filters)
/// ```
class ExpressiveSheet extends StatelessWidget {
  /// A side sheet's panel headed [title].
  const ExpressiveSheet({
    required this.child,
    this.title,
    this.actions = const <Widget>[],
    this.onClose,
    this.edge = DesignSheetEdge.end,
    super.key,
  });

  /// Opens a side sheet holding [builder]'s content, headed [title], from
  /// [edge]; completes with the value it closes with.
  static Future<T?> show<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    String? title,
    List<Widget> actions = const <Widget>[],
    DesignSheetEdge edge = DesignSheetEdge.end,
    double width = 360,
    bool useRootNavigator = true,
  }) {
    final t = context.expressiveTheme;
    final navigator = Navigator.of(context, rootNavigator: useRootNavigator);
    final themes = InheritedTheme.capture(from: context, to: navigator.context);
    return navigator.push<T>(
      DesignSideSheetRoute<T>(
        edge: edge,
        width: width,
        semanticLabel: title,
        barrierLabel: ExpressiveLocalizations.of(context).close,
        barrierColor: t.colors
            .role(ScrimTokens.containerColor)
            .withValues(alpha: ScrimTokens.containerOpacity),
        builder: (context, sheet) => themes.wrap(
          ExpressiveSheet(
            title: title,
            actions: actions,
            edge: edge,
            onClose: sheet.close,
            child: Builder(builder: builder),
          ),
        ),
      ),
    );
  }

  /// What the sheet holds; it scrolls when taller than the room.
  final Widget child;

  /// The headline.
  final String? title;

  /// Buttons at the foot: a filled one and an outlined one, usually.
  final List<Widget> actions;

  /// The close button; none when null.
  final VoidCallback? onClose;

  /// The edge it stands on: its inner corners are the large ones.
  final DesignSheetEdge edge;

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final c = t.colors;
    final close = onClose;
    final title = this.title;
    return ExpressiveSurface(
      shape: t.shapes.of(
        edge == DesignSheetEdge.end
            ? ExpressiveShapeKey.cornerLargeStart
            : ExpressiveShapeKey.cornerLargeEnd,
      ),
      color: c.surfaceContainerLow,
      contentColor: c.onSurfaceVariant,
      tonalElevation: ExpressiveElevationLevel.level1,
      shadowElevation: ExpressiveElevationLevel.level1,
      // The safe area on the sheet's own edge: the start edge is the right
      // one, right to left.
      child: SafeArea(
        left:
            edge ==
            (Directionality.of(context) == TextDirection.rtl
                ? DesignSheetEdge.end
                : DesignSheetEdge.start),
        right:
            edge ==
            (Directionality.of(context) == TextDirection.rtl
                ? DesignSheetEdge.start
                : DesignSheetEdge.end),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (title != null || close != null)
              Padding(
                padding: const EdgeInsetsDirectional.only(
                  start: ExpressiveSpacing.s24,
                  end: ExpressiveSpacing.s12,
                  top: ExpressiveSpacing.s12,
                  bottom: ExpressiveSpacing.s4,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: ExpressiveSpacing.s56,
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: title == null
                            ? const SizedBox.shrink()
                            : Semantics(
                                header: true,
                                child: Text(
                                  title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: t.type.titleLarge.copyWith(
                                    color: c.onSurfaceVariant,
                                  ),
                                ),
                              ),
                      ),
                      if (close != null)
                        ExpressiveIconButton(
                          ExpressiveSymbols.close,
                          onPressed: close,
                          semanticLabel: ExpressiveLocalizations.of(context)
                              .close,
                        ),
                    ],
                  ),
                ),
              ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: ExpressiveSpacing.s24,
                  vertical: ExpressiveSpacing.s8,
                ),
                child: child,
              ),
            ),
            if (actions.isNotEmpty) ...<Widget>[
              const ExpressiveDivider(),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  ExpressiveSpacing.s24,
                  ExpressiveSpacing.s16,
                  ExpressiveSpacing.s24,
                  ExpressiveSpacing.s24,
                ),
                child: Wrap(
                  spacing: ExpressiveSpacing.s8,
                  runSpacing: ExpressiveSpacing.s8,
                  children: actions,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
