// Collections whose behaviour is ui_core's and whose every pixel is the look's: the data table, the scroll area, the
// resizable panels, the reorderable list, swipe actions, pull to refresh and the tree. A row that is chosen or held is
// pressed into the wall, in its own outline, with a breath of the pigment; the pointer resting on one changes nothing.
import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'entries.dart';
import 'frames.dart';
import 'glyphs.dart';
import 'internal/cell_bank.dart' show neumorphicFadedScroll;
import 'internal/cap_label.dart';
import 'internal/geometry.dart' show cssLinear;
import 'internal/panel.dart';
import 'knobs.dart' show NeumorphicElevation;
import 'localizations.dart';
import 'moves.dart';
import 'ornaments.dart';
import 'theme.dart';

OutlinedBorder _rowShape(NeumorphicThemeData t) =>
    t.shapes.corner(NeumorphicRadii.control);

/// A row between engraved rules: pressed in when [sunk], lifted when the keyboard is on it. The 4 px around it leave the
/// lift room clear of the rules and of the list's edge.
Widget _row(
  BuildContext context, {
  required Set<WidgetState> states,
  required bool sunk,
  required bool rule,
  required Widget child,
}) {
  final t = NeumorphicTheme.of(context);
  final shape = _rowShape(t);
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (rule) const NeumorphicEngraved(),
      Padding(
        padding: const EdgeInsets.all(4),
        child: CustomPaint(
          painter: sunk
              ? NeumorphicPanelRowRelief(t.colors, t.elevation, null, shape)
              : null,
          foregroundPainter: states.contains(WidgetState.focused)
              ? neumorphicFocusLift(t, shape)
              : null,
          child: child,
        ),
      ),
    ],
  );
}

/// A table that sorts, selects and pages: a press on a column's head sorts it (up, down, back to as given), each row
/// has its check and the head a check for the page, and the pages step under it. Rows run between engraved rules; a
/// chosen row is pressed in with a breath of the pigment, and the keyboard's row lifts.
///
/// ```dart
/// NeumorphicDataTable<Map<String, String>>(label: 'Bookings', controller: bookings, cell: (booking, column) => booking[column.id] ?? '')
/// ```
class NeumorphicDataTable<R> extends StatelessWidget {
  /// A table of [controller]'s rows, whose words are [cell]'s.
  const NeumorphicDataTable({
    super.key,
    required this.controller,
    required this.cell,
    this.selectable = true,
    this.onActivate,
    this.label,
  });

  /// The rows, columns, sort, selection and page.
  final DesignTableController<R> controller;

  /// A cell's words.
  final String Function(R row, DesignTableColumn<R> column) cell;

  /// Whether the rows have checks.
  final bool selectable;

  /// Called by Enter or a double press on a row.
  final ValueChanged<R>? onActivate;

  /// What a screen reader calls the table.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final c = t.colors;
    final words = NeumorphicLocalizations.of(context);
    Widget box(DesignTableColumn<R> column, Widget child) => Expanded(
      flex: column.numeric ? 2 : 3,
      child: Align(
        alignment: column.numeric
            ? AlignmentDirectional.centerEnd
            : AlignmentDirectional.centerStart,
        child: child,
      ),
    );
    return Semantics(
      label: label,
      container: true,
      explicitChildNodes: true,
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Sideways(
              least: _least(context, t),
              child: DesignDataTable<R>(
                controller: controller,
                selectable: selectable,
                onActivate: onActivate,
                headerRowBuilder: (context, cells) => Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        children: [
                          if (selectable)
                            NeumorphicCheckbox(
                              value: switch (controller.pageSelection) {
                                DesignSelection.all => true,
                                DesignSelection.none => false,
                                DesignSelection.some => null,
                              },
                              tristate: true,
                              label: words.selectAllRows,
                              onChanged: (_) => controller.togglePage(),
                            ),
                          for (final (i, column) in controller.columns.indexed)
                            box(column, cells[i]),
                        ],
                      ),
                    ),
                    const NeumorphicEngraved(),
                  ],
                ),
                headerBuilder: (context, column, sort, states) {
                  final shape = _rowShape(t);
                  return CustomPaint(
                    painter: states.contains(WidgetState.pressed)
                        ? NeumorphicPanelRowRelief(c, t.elevation, null, shape)
                        : null,
                    foregroundPainter: states.contains(WidgetState.focused)
                        ? neumorphicFocusLift(t, shape)
                        : null,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 12,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                column.label,
                                style: t.textTheme.caption.copyWith(
                                  color: sort == null ? c.inkTertiary : c.ink,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (sort != null) ...[
                              const SizedBox(width: 4),
                              Transform.rotate(
                                angle: sort == DesignSortDirection.ascending
                                    ? math.pi
                                    : 0,
                                child: Icon(
                                  NeumorphicGlyphs.chevronDown,
                                  size: 14,
                                  color: c.pigmentInkLit,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
                cellBuilder: (context, row, column) => Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 12,
                  ),
                  child: Text(
                    cell(row, column),
                    style: column.numeric
                        ? t.textTheme.body.tabular
                        : t.textTheme.body,
                    textAlign: column.numeric ? TextAlign.end : TextAlign.start,
                  ),
                ),
                rowBuilder: (context, row, cells) => _row(
                  context,
                  states: row.states,
                  sunk:
                      row.selected || row.states.contains(WidgetState.pressed),
                  rule: row.index > 0,
                  child: Row(
                    children: [
                      if (selectable)
                        NeumorphicCheckbox(
                          value: row.selected,
                          label: words.select(
                            cell(row.row, controller.columns.first),
                          ),
                          onChanged: (_) => row.toggle(),
                        ),
                      for (final (i, column) in controller.columns.indexed)
                        box(column, cells[i]),
                    ],
                  ),
                ),
              ),
            ),
            if (controller.pageCount > 1)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: NeumorphicPagination(
                  count: controller.pageCount,
                  page: controller.page,
                  onChanged: controller.goToPage,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// The least width at which every column holds its longest word on one line, at the reader's text size: the columns
  /// share the width by their flex, so the narrowest share sets it. Under it the table scrolls sideways; at twice the
  /// text on a phone the shares broke words ('Hea / t', 'Bedro / om').
  double _least(BuildContext context, NeumorphicThemeData t) {
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    double widest(String text, TextStyle style) {
      var most = 0.0;
      for (final word in text.split(RegExp(r'\s+'))) {
        if (word.isEmpty) continue;
        final painter = TextPainter(
          text: TextSpan(text: word, style: style),
          textDirection: direction,
          textScaler: scaler,
          maxLines: 1,
        )..layout();
        most = math.max(most, painter.width);
        painter.dispose();
      }
      return most;
    }

    final head = t.textTheme.caption.copyWith(fontWeight: FontWeight.w700);
    final flexes = [
      for (final column in controller.columns) column.numeric ? 2 : 3,
    ];
    final total = flexes.fold<int>(0, (a, b) => a + b);
    var least = 0.0;
    for (final (i, column) in controller.columns.indexed) {
      // A header holds its words and the sort mark; a cell its words; both 8 in from each side.
      var need = widest(column.label, head) + 18;
      for (final row in controller.pageRows) {
        final style = column.numeric
            ? t.textTheme.body.tabular
            : t.textTheme.body;
        need = math.max(need, widest(cell(row, column), style));
      }
      least = math.max(least, (need + 16) * total / flexes[i]);
    }
    // The row's own inset and the checkbox's target.
    return least + 8 + (selectable ? 48 : 0);
  }
}

/// A table at its [least] width, scrolling sideways when its room is narrower.
class _Sideways extends StatelessWidget {
  const _Sideways({required this.least, required this.child});

  final double least;
  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) => box.maxWidth >= least
        ? child
        // Its ends fade where more columns lie beyond them: cut square, a column past the edge was simply gone.
        : neumorphicFadedScroll(
            padding: EdgeInsets.zero,
            child: SizedBox(width: least, child: child),
          ),
  );
}

/// A scrolling region with the look's own bar: a capsule in the quiet ink that shows while it scrolls or the pointer is
/// over the region, and the keyboard's ring around the region when it has focus (arrows, Page Up and Down, Home and End
/// scroll it).
///
/// ```dart
/// NeumorphicScrollArea(controller: scroll, label: 'Notes', child: ListView(controller: scroll, children: rows))
/// ```
class NeumorphicScrollArea extends StatelessWidget {
  /// A region around [child], which scrolls by [controller].
  const NeumorphicScrollArea({
    super.key,
    required this.controller,
    required this.child,
    this.axis = Axis.vertical,
    this.label,
    this.alwaysShown = false,
    this.focusNode,
    this.autofocus = false,
  });

  /// The region's keyboard focus; its own when null.
  final FocusNode? focusNode;

  /// Whether the region takes focus when it first shows.
  final bool autofocus;

  /// The scroll view's controller.
  final ScrollController controller;

  /// The scroll view.
  final Widget child;

  /// The way it scrolls.
  final Axis axis;

  /// What a screen reader calls the region.
  final String? label;

  /// Whether the bar always shows.
  final bool alwaysShown;

  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final c = t.colors;
    final region = t.shapes.corner(NeumorphicRadii.well);
    return DesignScrollArea(
      controller: controller,
      axis: axis,
      focusNode: focusNode,
      autofocus: autofocus,
      thickness: 12,
      semanticLabel: label,
      visibility: alwaysShown
          ? DesignScrollbarVisibility.always
          : DesignScrollbarVisibility.auto,
      thumbBuilder: (context, thumb) {
        final held = thumb.states.contains(WidgetState.pressed);
        return AnimatedOpacity(
          opacity: thumb.visible ? 1 : 0,
          duration: t.motion.state,
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: DecoratedBox(
              decoration: ShapeDecoration(
                color: held ? c.inkSecondary : c.quiet,
                shape: t.shapes.capsule,
              ),
            ),
          ),
        );
      },
      frameBuilder: (context, focused, area) => CustomPaint(
        foregroundPainter: focused ? neumorphicFocusLift(t, region) : null,
        child: area,
      ),
      child: child,
    );
  }
}

/// Two panels with a groove between them and a raised knob on it, which drags (or, with the keyboard on it, arrows) to
/// share the room.
///
/// ```dart
/// NeumorphicResizable(first: list, second: detail, minFirst: 240, minSecond: 320)
/// ```
class NeumorphicResizable extends StatelessWidget {
  /// Two panels, [first] and [second], sharing the room.
  const NeumorphicResizable({
    super.key,
    required this.first,
    required this.second,
    this.axis = Axis.horizontal,
    this.initialFraction = .5,
    this.minFirst = 0,
    this.minSecond = 0,
    this.onChanged,
    this.focusNode,
    this.autofocus = false,
  });

  /// The knob's keyboard focus; its own when null.
  final FocusNode? focusNode;

  /// Whether the knob takes focus when it first shows.
  final bool autofocus;

  /// The panel at the start (or the top).
  final Widget first;

  /// The panel at the end (or the bottom).
  final Widget second;

  /// Side by side, or one over the other.
  final Axis axis;

  /// The first panel's share at the start.
  final double initialFraction;

  /// The least each panel may take, in logical pixels.
  final double minFirst, minSecond;

  /// Called with the first panel's share as it moves.
  final ValueChanged<double>? onChanged;

  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    return DesignSplitView(
      first: first,
      second: second,
      axis: axis,
      initialFraction: initialFraction,
      minFirst: minFirst,
      minSecond: minSecond,
      onChanged: onChanged,
      focusNode: focusNode,
      autofocus: autofocus,
      dividerThickness: 8,
      hitExtent: 16,
      semanticLabel: NeumorphicLocalizations.of(context).resize,
      dividerBuilder: (context, states, axis) {
        final side = axis == Axis.horizontal;
        final knob = t.shapes.capsule;
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // The groove stops short of the holder's edges, both ends round: run out to them, its end was cut flat
            // by the card's rim.
            Padding(
              padding: side
                  ? const EdgeInsets.symmetric(vertical: 12)
                  : const EdgeInsets.symmetric(horizontal: 12),
              child: NeumorphicSurface(
                cast: NeumorphicSurfaceLevel.groove,
                shape: t.shapes.capsule,
                child: const SizedBox.expand(),
              ),
            ),
            OverflowBox(
              maxWidth: side ? 14 : 44,
              maxHeight: side ? 44 : 14,
              child: CustomPaint(
                foregroundPainter: states.contains(WidgetState.focused)
                    ? neumorphicFocusLift(t, knob)
                    : null,
                child: SizedBox(
                  width: side ? 14 : 44,
                  height: side ? 44 : 14,
                  child: NeumorphicSurface(
                    cast: states.contains(WidgetState.pressed)
                        ? NeumorphicSurfaceLevel.groove
                        : NeumorphicSurfaceLevel.part,
                    shape: knob,
                    outlined: true,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// A list between engraved rules whose rows drag into a new order by their grip (a long press anywhere on touch); with
/// the keyboard, the grip's menu moves a row up or down, and the move is announced.
///
/// ```dart
/// NeumorphicReorderableListView<String>(items: stops, labelOf: (s) => s, onReorder: move, itemBuilder: (context, stop) => Text(stop))
/// ```
class NeumorphicReorderableListView<T extends Object> extends StatelessWidget {
  /// A list of [items].
  const NeumorphicReorderableListView({
    super.key,
    required this.items,
    required this.onReorder,
    required this.labelOf,
    required this.itemBuilder,
    this.shrinkWrap = true,
  });

  /// The rows, in order.
  final List<T> items;

  /// Moves the row at `from` to `to`.
  final void Function(int from, int to) onReorder;

  /// What a screen reader calls a row.
  final String Function(T item) labelOf;

  /// A row's contents; the grip and the rule are the list's.
  final Widget Function(BuildContext context, T item) itemBuilder;

  /// Whether the list takes only its rows' height.
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    return DesignReorderableList<T>(
      items: items,
      onReorder: onReorder,
      labelOf: labelOf,
      shrinkWrap: shrinkWrap,
      proxyDecorator: (child, index, animation) => NeumorphicSurface(
        cast: NeumorphicSurfaceLevel.part,
        shape: _rowShape(t),
        outlined: true,
        child: child,
      ),
      itemBuilder: (context, item, r) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (r.index > 0) const NeumorphicEngraved(),
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: 8,
                    top: 12,
                    bottom: 12,
                  ),
                  child: DefaultTextStyle.merge(
                    style: t.textTheme.body,
                    child: itemBuilder(context, item),
                  ),
                ),
              ),
              r.handle(
                MouseRegion(
                  cursor: SystemMouseCursors.grab,
                  child: SizedBox.square(
                    dimension: 48,
                    child: Icon(
                      NeumorphicGlyphs.gripVertical,
                      size: 18,
                      color: t.colors.inkTertiary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A row that slides aside to show what can be done to it (Archive, Delete): drag it, and a full swipe runs the
/// outermost action. An action is a face of the pigment; one that destroys something is a face of the ink. The row is
/// square and slides inside its own box: in a card, give the card 8 of padding so the rows clear its round corners.
///
/// ```dart
/// NeumorphicSwipeActions(endActions: [DesignSwipeAction(label: 'Delete', destructive: true, onPressed: remove)], child: row)
/// ```
class NeumorphicSwipeActions extends StatelessWidget {
  /// A row, [child], with actions behind it.
  const NeumorphicSwipeActions({
    super.key,
    required this.child,
    this.startActions = const [],
    this.endActions = const [],
    this.initiallyOpen = false,
  });

  /// The row.
  final Widget child;

  /// Actions behind the row's start edge.
  final List<DesignSwipeAction> startActions;

  /// Actions behind its end edge.
  final List<DesignSwipeAction> endActions;

  /// Whether it starts with a side open (the end's, else the start's): a preview, or a one-time hint that the row
  /// swipes. It closes as any open row does.
  final bool initiallyOpen;

  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final c = t.colors;
    final label = t.textTheme.caption.copyWith(fontWeight: FontWeight.w700);
    // An action is as wide as its longest word on one line, at the reader's text size, and never under 88: at twice
    // the text a fixed 88 broke 'Delete' and 'Archive' in two.
    var extent = 88.0;
    for (final action in [...startActions, ...endActions]) {
      final painter = TextPainter(
        text: TextSpan(text: action.label, style: label),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
        maxLines: 1,
      )..layout();
      extent = math.max(
        extent,
        painter.width + 2 * (_bandInset + 12) + _edgeInset - _bandInset,
      );
      painter.dispose();
    }
    // Held to its own box: slid open, the row's words went on past the card it stands in, over the wall.
    return _SwipeFrame(
      child: DesignSwipeActions(
        initiallyOpen: initiallyOpen,
        startActions: startActions,
        endActions: endActions,
        actionExtent: extent.ceilToDouble(),
        actionBuilder: (context, action, state) {
          // A destructive action is a plaster key with ink words, the act beside it the pigment's: an ink face was ink
          // as a body (law 5), a black slab by day and a silver one by night.
          final fill = action.destructive ? null : c.pigment;
          final words = action.destructive ? c.ink : c.onPigment;
          // Each action is a face of a control's corners, a little in from its neighbours and the row: the strip the
          // row uncovers is square at its ends while it slides, and a face held inside it never shows that.
          final face = t.shapes.corner(NeumorphicRadii.control);
          // The face at the row's edge keeps the row's own inset there, so it ends where the row's words end (the
          // strip's start is the row's edge).
          return Padding(
            padding: EdgeInsetsDirectional.fromSTEB(
              state.index == 0 ? _edgeInset : _bandInset,
              _bandInset,
              _bandInset,
              _bandInset,
            ),
            child: CustomPaint(
              foregroundPainter: state.states.contains(WidgetState.focused)
                  ? neumorphicFocusLift(t, face, reach: .5)
                  : null,
              // A moulded face, as a filled key's is, its relief small enough to stay inside the strip: painted flat it
              // read as a slab of colour laid on the row.
              child: CustomPaint(
                painter: _ActionFace(
                  c,
                  face,
                  state.armed
                      ? Color.alphaBlend(
                          words.withValues(alpha: fill == null ? .08 : .16),
                          fill ?? c.ground,
                        )
                      : fill,
                  t.elevation,
                  NeumorphicFlatScope.of(context),
                ),
                // The word on the face's middle by its capitals, as a key's: centred by its line box it stood high.
                child: Center(
                  child: Opacity(
                    opacity: state.reveal.clamp(0.0, 1.0),
                    child: neumorphicLabel(
                      Text(
                        action.label,
                        maxLines: 1,
                        softWrap: false,
                        style: label.copyWith(color: words),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
        // Inset as a reorderable row is: open, what stands at the row's end keeps clear of the band it slides up to.
        // Slid aside, its words sink under the edge it passes, as a scroll's do: cut sheer there, the open row read as
        // a broken scrap of text ("p, on until eleven") rather than a row half out of view (fresh-eyes rounds 1-11).
        child: _SinkingEdge(
          child: ColoredBox(
            color: c.ground,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// How far an action's face stands in from the strip the row uncovers: half the gap between two faces.
const double _bandInset = 4;

/// How far the face at the row's edge stands in from it: the row's own inset, so it ends on the words' keyline.
const double _edgeInset = 8;

/// How far a slid row's words take to sink under the edge they pass: a faded scroll's edge.
const double _sinkFade = 32;

/// The box a swipe row slides in, clipped to it: the edge the row's words sink under.
class _SwipeFrame extends SingleChildRenderObjectWidget {
  const _SwipeFrame({super.child});

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderSwipeFrame();
}

class _RenderSwipeFrame extends RenderClipRect {
  _RenderSwipeFrame() : super(clipBehavior: Clip.hardEdge);
}

/// A swipe row whose words fade out over [_sinkFade] where they pass under its frame's edge. The slide is the row's
/// own place in the frame, read as it paints, so it follows the drag and the open and close without a listener.
class _SinkingEdge extends SingleChildRenderObjectWidget {
  const _SinkingEdge({super.child});

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderSinkingEdge();
}

class _RenderSinkingEdge extends RenderProxyBox {
  @override
  bool get alwaysNeedsCompositing => child != null;

  @override
  void paint(PaintingContext context, Offset offset) {
    RenderObject? frame = parent;
    while (frame != null && frame is! _RenderSwipeFrame) {
      frame = frame.parent;
    }
    final w = size.width;
    final dx = frame is _RenderSwipeFrame
        ? getTransformTo(frame).getTranslation().x
        : 0.0;
    if (child == null ||
        frame is! _RenderSwipeFrame ||
        dx.abs() < .5 ||
        w <= 0) {
      layer = null;
      super.paint(context, offset);
      return;
    }
    // The frame's edge in the row's own terms: its left when the row slid left, its right when it slid right.
    final fade = math.min(_sinkFade, dx.abs());
    final edge = dx < 0 ? -dx : frame.size.width - dx;
    double at(double x) => (x / w).clamp(0.0, 1.0);
    const clear = Color(0x00000000), whole = Color(0xFF000000);
    final gradient = dx < 0
        ? LinearGradient(
            colors: const [clear, whole],
            stops: [at(edge), at(edge + fade)],
          )
        : LinearGradient(
            colors: const [whole, clear],
            stops: [at(edge - fade), at(edge)],
          );
    final mask = (layer as ShaderMaskLayer?) ?? ShaderMaskLayer();
    mask
      ..shader = gradient.createShader(Offset.zero & size)
      ..maskRect = offset & size
      ..blendMode = BlendMode.dstIn;
    layer = mask;
    context.pushLayer(mask, super.paint, offset);
  }
}

/// A swipe action's face: [fill] moulded as a filled key's face is, its light and shade a few pixels deep.
class _ActionFace extends CustomPainter {
  _ActionFace(this.c, this.shape, this.fill, this.elevation, this.flat);
  final NeumorphicColors c;
  final OutlinedBorder shape;

  /// The face's colour; null is the plaster's own face.
  final Color? fill;
  final NeumorphicElevation elevation;
  final bool flat;

  @override
  void paint(Canvas canvas, Size size) {
    final box = Offset.zero & size;
    neumorphicPaintRaised(
      canvas,
      shape.getOuterPath(box),
      c,
      light: (const Offset(-2, -2), 4),
      dark: (const Offset(2, 2), 5),
      // Lit top-left and deeper toward the bottom-right, as a filled key's face (pigment to its deep tone): shaded
      // toward the plaster's shadow, which is lighter than ink or pigment, the faces read lit from the bottom-right.
      face: fill == null
          ? null
          : cssLinear(box, 145, [
              fill!,
              // A plaster face (an armed destructive key) shades toward the plaster's own shadow.
              fill == c.pigment
                  ? c.pigmentDk
                  : Color.lerp(fill, c.shadow, .35)!,
            ]),
      elevation: elevation,
      flat: flat,
      rim: false,
    );
  }

  @override
  bool shouldRepaint(_ActionFace o) =>
      o.c != c ||
      o.shape != shape ||
      o.fill != fill ||
      o.elevation != elevation ||
      o.flat != flat;
}

/// A tree of nested rows (folders, a site's pages, a menu's sections): a chevron opens a row's children, set in under
/// it; arrows walk it (Right opens, Left closes or goes to the parent), and each row says its level and place. A chosen
/// row is pressed in.
///
/// ```dart
/// NeumorphicTreeView<String>(controller: places, labelOf: (place) => place, onActivate: open)
/// ```
class NeumorphicTreeView<T extends Object> extends StatelessWidget {
  /// A tree of [controller]'s nodes.
  const NeumorphicTreeView({
    super.key,
    required this.controller,
    required this.labelOf,
    this.onActivate,
    this.iconOf,
    this.label,
  });

  /// The roots, the children, and which are open and chosen.
  final DesignTreeController<T> controller;

  /// A row's words.
  final String Function(T node) labelOf;

  /// Called by Enter or a press on a row.
  final ValueChanged<T>? onActivate;

  /// A row's glyph.
  final IconData? Function(T node)? iconOf;

  /// What a screen reader calls the tree.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final c = t.colors;
    final words = NeumorphicLocalizations.of(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final shape = _rowShape(t);
    return DesignTree<T>(
      controller: controller,
      labelOf: labelOf,
      onActivate: onActivate,
      semanticLabel: label,
      rowBuilder: (context, item) {
        final node = item.row.node;
        final icon = iconOf?.call(node);
        final sunk = item.selected || item.states.contains(WidgetState.pressed);
        return Padding(
          padding: const EdgeInsets.all(3),
          child: CustomPaint(
            painter: sunk
                ? NeumorphicPanelRowRelief(c, t.elevation, null, shape)
                : null,
            foregroundPainter: item.states.contains(WidgetState.focused)
                ? neumorphicFocusLift(t, shape)
                : null,
            child: Padding(
              padding: EdgeInsetsDirectional.only(
                start: 4 + item.row.depth * 20.0,
                end: 8,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 44),
                child: Row(
                  children: [
                    // The chevron is the pointer's: the row is the tree's one keyboard stop (Right and Left open and
                    // close it) and a screen reader's one node.
                    SizedBox.square(
                      dimension: 36,
                      child: !item.hasChildren
                          ? null
                          : ExcludeFocus(
                              child: DesignPressable(
                                onPressed: item.toggle,
                                semanticLabel: item.expanded
                                    ? words.collapse
                                    : words.expand,
                                excludeSemantics: true,
                                builder: (context, states, _) => CustomPaint(
                                  painter: states.contains(WidgetState.pressed)
                                      ? NeumorphicPanelRowRelief(
                                          c,
                                          t.elevation,
                                          null,
                                          t.shapes.circle(36),
                                        )
                                      : null,
                                  child: Center(
                                    child: AnimatedRotation(
                                      turns: item.expanded
                                          ? 0
                                          : (rtl ? .25 : -.25),
                                      duration: t.motion.state,
                                      child: Icon(
                                        NeumorphicGlyphs.chevronDown,
                                        size: 16,
                                        color: c.inkSecondary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                    ),
                    if (icon != null) ...[
                      Icon(
                        icon,
                        size: 18,
                        color: item.selected ? c.pigmentInkLit : c.inkSecondary,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          labelOf(node),
                          style: t.textTheme.body.copyWith(
                            fontWeight: item.selected
                                ? FontWeight.w700
                                : FontWeight.w500,
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
    );
  }
}
