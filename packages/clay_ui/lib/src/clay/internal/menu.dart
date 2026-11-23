// The open list Clay's select and menus share: a floating volume of clay
// holding rows, one current row at a time pressed into it as a soft well.

import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../fonts.dart';
import '../surface.dart';
import '../theme.dart';

/// The equal inset every row keeps from the panel's edges, all round: with
/// a row's own inset, its words start where a field's do.
const double clayMenuInset = ClaySpacing.tight;

/// The panel's corner radius; a row's is this less [clayMenuInset], so the
/// two curves run side by side.
const double clayMenuRadius = ClayRadius.large;

/// One row of a [ClayMenuList].
@immutable
class ClayMenuEntry<T> {
  /// A row for [value], reading [label].
  const ClayMenuEntry({
    required this.value,
    required this.label,
    this.leading,
    this.enabled = true,
    this.isDestructiveAction = false,
  });

  /// What choosing the row gives.
  final T value;

  /// Its words.
  final String label;

  /// A glyph before the words.
  final Widget? leading;

  /// Whether it can be chosen.
  final bool enabled;

  /// Whether it destroys something: its words in the danger ink.
  final bool isDestructiveAction;
}

/// A floating panel of rows. [chosen] marks the current value (its words in
/// the accent's ink, a check at its end) and is in view when the list opens.
/// One row is lit at a time: the pointer's while the pointer moves, the
/// focused one once a key is pressed; a list a pointer opened lights none.
class ClayMenuList<T> extends StatefulWidget {
  /// A panel of [entries].
  const ClayMenuList({
    super.key,
    required this.entries,
    required this.onChosen,
    required this.rowHeight,
    required this.maxHeight,
    this.chosen,
    this.hasChosen = false,
    this.style,
  });

  /// The rows.
  final List<ClayMenuEntry<T>> entries;

  /// Called with a row's value when it is chosen.
  final ValueChanged<T> onChosen;

  /// Each row's height.
  final double rowHeight;

  /// The room the panel may take; it scrolls past it.
  final double maxHeight;

  /// The value now chosen, with [hasChosen].
  final T? chosen;

  /// Whether the list marks a chosen value (a select); a menu of actions
  /// marks none.
  final bool hasChosen;

  /// The panel's own style.
  final ClayStyle? style;

  @override
  State<ClayMenuList<T>> createState() => _ClayMenuListState<T>();
}

class _ClayMenuListState<T> extends State<ClayMenuList<T>> {
  late List<FocusNode> _nodes = _make();
  final ScrollController _scroll = ScrollController();

  // The row under a moving pointer; a key clears it, so the pointer's row
  // and the keys' row are never both lit.
  int? _pointerRow;

  List<FocusNode> _make() => [
    for (final e in widget.entries)
      FocusNode(debugLabel: 'ClayMenu ${e.label}'),
  ];

  @override
  void didUpdateWidget(ClayMenuList<T> old) {
    super.didUpdateWidget(old);
    if (old.entries.length != widget.entries.length) {
      for (final n in _nodes) {
        n.dispose();
      }
      _nodes = _make();
    }
  }

  @override
  void dispose() {
    for (final n in _nodes) {
      n.dispose();
    }
    _scroll.dispose();
    super.dispose();
  }

  void _point(int i) {
    if (_pointerRow == i) return;
    setState(() => _pointerRow = i);
    if (widget.entries[i].enabled) _nodes[i].requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    final c = theme.colors;
    final night = c.brightness == Brightness.dark;
    // The menu floats a shade lighter than the clay at night, so it stands
    // off the page it covers without a glow.
    final panel = night ? Color.lerp(c.clay, c.light, 0.06)! : c.clay;
    final rows = widget.entries.length;
    final fullHeight = rows * widget.rowHeight + 2 * clayMenuInset;
    final cap = math.max(
      widget.rowHeight + 2 * clayMenuInset,
      math.min(widget.maxHeight, widget.rowHeight * 7.5 + 2 * clayMenuInset),
    );
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent && _pointerRow != null) {
          setState(() => _pointerRow = null);
        }
        return KeyEventResult.ignored;
      },
      child: ClaySurface(
        face: ClayFace.floating(c, color: panel, radius: clayMenuRadius),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: math.min(fullHeight, cap)),
          child: MouseRegion(
            onExit: (_) => setState(() => _pointerRow = null),
            child: SingleChildScrollView(
              controller: _scroll,
              padding: const EdgeInsets.all(clayMenuInset),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (i, e) in widget.entries.indexed)
                    _row(theme, c, i, e),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(ClayThemeData theme, ClayColors c, int i, ClayMenuEntry<T> e) {
    final isChosen = widget.hasChosen && e.value == widget.chosen;
    return MouseRegion(
      onEnter: (_) => _point(i),
      onHover: (_) => _point(i),
      child: RawButton(
        focusNode: _nodes[i],
        onPressed: e.enabled ? () => widget.onChosen(e.value) : null,
        autofocus: isChosen,
        selected: isChosen,
        semanticSelected: widget.hasChosen ? isChosen : null,
        semanticLabel: e.label,
        excludeSemantics: true,
        builder: (context, states, _) {
          final focused = states.contains(WidgetState.focused);
          final lit =
              focused ||
              (states.contains(WidgetState.hovered) && _pointerRow == i);
          final pressed = states.contains(WidgetState.pressed);
          final words = !e.enabled
              ? c.inkDisabled
              : e.isDestructiveAction
              ? c.dangerInk
              : isChosen
              ? c.accentInk
              : c.ink;
          final weight = isChosen ? FontWeight.w600 : FontWeight.w400;
          final well = ClayFace.well(c, radius: clayMenuRadius - clayMenuInset);
          final show = lit || pressed;
          return SizedBox(
            height: widget.rowHeight,
            child: AnimatedClaySurface(
              face: well.copyWith(
                color: show ? null : well.color.withValues(alpha: 0),
                lightOpacity: show ? null : 0,
                shadeOpacity: show
                    ? well.shadeOpacity * (pressed ? 1.4 : 1)
                    : 0,
                focus: focused ? 1 : 0,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: ClaySpacing.medium,
                ),
                child: Row(
                  children: [
                    if (e.leading != null) ...[
                      IconTheme.merge(
                        data: IconThemeData(size: 20, color: words),
                        child: e.leading!,
                      ),
                      const SizedBox(width: ClaySpacing.medium),
                    ],
                    Expanded(
                      child: DesignCapCenter(
                        capHeightFactor: clayCapHeightFactor,
                        child: Text(
                          e.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.body.copyWith(
                            color: words,
                            fontWeight: weight,
                            fontVariations: clayWeight(weight),
                          ),
                        ),
                      ),
                    ),
                    if (isChosen) ...[
                      const SizedBox(width: ClaySpacing.small),
                      SizedBox.square(
                        dimension: 18,
                        child: CustomPaint(painter: ClayCheckPainter(words)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// A rounded check mark, drawn to fit its box.
class ClayCheckPainter extends CustomPainter {
  /// A check of [color], drawn [progress] of its way, [stroke] wide.
  ClayCheckPainter(this.color, {this.progress = 1, this.stroke = 2.4});

  /// Its colour.
  final Color color;

  /// How much of it is drawn, 0 to 1.
  final double progress;

  /// Its line's width.
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final path = Path()
      ..moveTo(size.width * 0.18, size.height * 0.53)
      ..lineTo(size.width * 0.42, size.height * 0.76)
      ..lineTo(size.width * 0.84, size.height * 0.28);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color;
    if (progress >= 1) {
      canvas.drawPath(path, paint);
      return;
    }
    for (final metric in path.computeMetrics()) {
      canvas.drawPath(metric.extractPath(0, metric.length * progress), paint);
    }
  }

  @override
  bool shouldRepaint(ClayCheckPainter old) =>
      old.color != color || old.progress != progress || old.stroke != stroke;
}

/// A soft chevron that turns from down to up as [open] goes 0 to 1.
class ClayChevronPainter extends CustomPainter {
  /// A chevron of [color], turned [open] of the way up.
  ClayChevronPainter(this.color, this.open);

  /// Its colour.
  final Color color;

  /// How far it has turned, 0 (down) to 1 (up).
  final double open;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas
      ..save()
      ..translate(w / 2, h / 2)
      ..rotate(math.pi * open)
      ..translate(-w / 2, -h / 2);
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.22, h * 0.38)
        ..lineTo(w * 0.5, h * 0.64)
        ..lineTo(w * 0.78, h * 0.38),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(ClayChevronPainter old) =>
      old.color != color || old.open != open;
}

/// One row of a menu driven by ui_core (a split key's, a menu button's, a
/// context menu's, a menu bar's): words, an optional glyph and trailing
/// words, pressed into the panel as a soft well while it is lit.
class ClayMenuRow extends StatelessWidget {
  /// A row reading [label] in [states].
  const ClayMenuRow({
    super.key,
    required this.label,
    required this.states,
    this.leading,
    this.trailing,
    this.isDestructiveAction = false,
    this.chosen = false,
    this.height,
  });

  /// Its words.
  final String label;

  /// The row's states (lit when focused or hovered, pressed, disabled).
  final Set<WidgetState> states;

  /// A glyph before the words.
  final Widget? leading;

  /// Something at its end: a shortcut, a chevron.
  final Widget? trailing;

  /// Whether it destroys something.
  final bool isDestructiveAction;

  /// Whether it is the chosen one (words in the accent's ink, a check).
  final bool chosen;

  /// Its height; the theme's row height when null.
  final double? height;

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    final c = theme.colors;
    final focused = states.contains(WidgetState.focused);
    final pressed = states.contains(WidgetState.pressed);
    final disabled = states.contains(WidgetState.disabled);
    final show =
        focused ||
        pressed ||
        states.contains(WidgetState.hovered) ||
        states.contains(WidgetState.selected) && !chosen;
    final words = disabled
        ? c.inkDisabled
        : isDestructiveAction
        ? c.dangerInk
        : chosen
        ? c.accentInk
        : c.ink;
    final weight = chosen ? FontWeight.w600 : FontWeight.w400;
    final well = ClayFace.well(c, radius: clayMenuRadius - clayMenuInset);
    return SizedBox(
      height: height ?? theme.density.height(ClayMetrics.controlHeight - 4),
      child: AnimatedClaySurface(
        face: well.copyWith(
          color: show ? null : well.color.withValues(alpha: 0),
          lightOpacity: show ? null : 0,
          shadeOpacity: show ? well.shadeOpacity * (pressed ? 1.4 : 1) : 0,
          focus: focused ? 1 : 0,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: ClaySpacing.medium),
          child: Row(
            children: [
              if (leading != null) ...[
                IconTheme.merge(
                  data: IconThemeData(size: 20, color: words),
                  child: leading!,
                ),
                const SizedBox(width: ClaySpacing.medium),
              ],
              Expanded(
                child: DesignCapCenter(
                  capHeightFactor: clayCapHeightFactor,
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.body.copyWith(
                      color: words,
                      fontWeight: weight,
                      fontVariations: clayWeight(weight),
                    ),
                  ),
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: ClaySpacing.medium),
                DefaultTextStyle.merge(
                  style: theme.textTheme.secondary,
                  child: IconTheme.merge(
                    data: IconThemeData(size: 18, color: c.inkSecondary),
                    child: trailing!,
                  ),
                ),
              ],
              if (chosen) ...[
                const SizedBox(width: ClaySpacing.small),
                SizedBox.square(
                  dimension: 18,
                  child: CustomPaint(painter: ClayCheckPainter(words)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The clay a menu or a field's options float in: by night a shade
/// lighter than the cards, so it stands off what it covers.
ClayFace clayMenuFace(ClayColors c) {
  final night = c.brightness == Brightness.dark;
  return ClayFace.floating(
    c,
    color: night ? Color.lerp(c.clay, c.light, 0.06)! : c.clay,
    radius: clayMenuRadius,
  );
}

/// The floating panel a menu's [rows] stand in, inset equally all round.
Widget clayMenuPanel(
  BuildContext context,
  List<Widget> rows, {
  double? width,
  double? maxHeight,
  Color? fill,
}) {
  final c = ClayTheme.of(context).colors;
  Widget body = Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: rows,
  );
  body = width == null
      ? IntrinsicWidth(stepWidth: 8, child: body)
      : SizedBox(width: width, child: body);
  final face = clayMenuFace(c);
  return ClaySurface(
    face: fill == null ? face : face.tinted(c, fill),
    child: ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: 180,
        maxHeight: maxHeight ?? double.infinity,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(clayMenuInset),
        child: body,
      ),
    ),
  );
}
