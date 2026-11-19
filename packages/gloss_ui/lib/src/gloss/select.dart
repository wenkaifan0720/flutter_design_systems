/// Gloss's select: a field well with a pearl dial bead at its end, opening a
/// porcelain list of choices under it.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'fonts.dart';
import 'internal/chevron.dart';
import 'internal/menu_parts.dart';
import 'surface.dart';
import 'text_field.dart';
import 'theme.dart';

/// One choice of a [GlossSelect].
@immutable
class GlossSelectItem<T> {
  /// The choice [value], reading [label].
  const GlossSelectItem({
    required this.value,
    required this.label,
    this.enabled = true,
  });

  /// The value it stands for.
  final T value;

  /// Its words.
  final String label;

  /// Whether it can be chosen.
  final bool enabled;
}

/// A Gloss select: a field well showing the choice, a pearl dial bead at
/// its end; a press opens the choices on a porcelain panel under it (above
/// it when the room is there), the chosen one checked in jade and in view.
///
/// One row is current at a time: the pointer's row takes the keyboard's
/// place (`highlightFollowsPointer`), and a list opened by a pointer lights
/// no row until the pointer or a key moves. Up and Down move, Enter
/// chooses, Escape closes and gives focus back to the field.
///
/// ```dart
/// GlossSelect<String>(label: 'Units', value: 'metric', items: const [GlossSelectItem(value: 'metric', label: 'Metric'), GlossSelectItem(value: 'us', label: 'US cups')], onChanged: (value) {})
/// ```
class GlossSelect<T> extends StatelessWidget {
  /// A select over [items], [value] chosen.
  const GlossSelect({
    super.key,
    required this.items,
    required this.value,
    required this.onChanged,
    this.label,
    this.hint,
    this.helper,
    this.error,
    this.focusNode,
    this.style,
  });

  /// The choices.
  final List<GlossSelectItem<T>> items;

  /// The chosen value; [hint] shows when null.
  final T? value;

  /// Called with the value chosen; null turns it off.
  final ValueChanged<T>? onChanged;

  /// The label above the field.
  final String? label;

  /// What the field says while nothing is chosen.
  final String? hint;

  /// Help under the field.
  final String? helper;

  /// What is wrong, under the field in ruby.
  final String? error;

  /// {@macro design.focusNode}
  final FocusNode? focusNode;

  /// This select's own style, over [GlossThemeData.selectStyle].
  final GlossStyle? style;

  /// The widest a select stands from 600 px of window up.
  static const double maxWideWidth = 320;

  @override
  Widget build(BuildContext context) {
    final theme = GlossTheme.of(context);
    final c = theme.colors;
    final enabled = onChanged != null;
    final chosen = items.where((i) => i.value == value).firstOrNull;
    final height = theme.controlHeight;
    // The field: [toggle] opens and closes its list, [open] while it shows.
    Widget anchorField(VoidCallback? toggle, bool open) => DesignPressable(
      onPressed: toggle,
      focusNode: focusNode,
      // A field that cannot open says nothing of opening.
      expanded: enabled ? open : null,
      semanticLabel: label,
      semanticValue: chosen?.label,
      builder: (context, states, _) {
        final layered = DesignStyleOf(
          [style, theme.selectStyle],
          {...states, if (error != null) WidgetState.error},
        );
        final pressed = states.contains(WidgetState.pressed);
        var well = GlossFace.well(c, radius: GlossMetrics.fieldRadius);
        if (layered.fill != null) well = well.glazed(layered.fill!);
        well = well.copyWith(
          lift: enabled ? -1 : -0.45,
          edge: error != null ? c.danger : layered.edge,
          focus: glossGlazeOf(c, {...states, if (open) WidgetState.focused}),
          travel: states.contains(WidgetState.pressed) ? 1 : 0,
        );
        final bead = height - 14;
        return SizedBox(
          height: height,
          child: AnimatedGlossSurface(
            face: well,
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(
                      start: GlossSpacing.regular,
                      end: GlossSpacing.small,
                    ),
                    child: DesignCapCenter(
                      capHeightFactor: glossCapHeightFactor,
                      child: Text(
                        chosen?.label ?? hint ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.body.copyWith(
                          color: !enabled
                              ? c.inkDisabled
                              : chosen == null
                              ? c.inkSecondary
                              : c.ink,
                        ),
                      ),
                    ),
                  ),
                ),
                // The dial bead: a pearl knob seated at the well's end,
                // turning as the list opens.
                Padding(
                  padding: EdgeInsetsDirectional.only(end: (height - bead) / 2),
                  child: SizedBox.square(
                    dimension: bead,
                    child: AnimatedGlossSurface(
                      face: enabled
                          ? GlossFace.pearl(c)
                                .copyWith(travel: pressed || open ? 1 : 0)
                          // Disabled, the bead lies flat and dull: nothing
                          // to press.
                          : GlossFace.pearl(c).copyWith(
                              lens: 0,
                              lift: 0,
                              glow: const Color(0x00000000),
                              foreground: c.inkDisabled,
                            ),
                      child: Center(
                        child: GlossChevron(
                          open: open,
                          color: enabled ? c.inkSecondary : c.inkDisabled,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    // A select that cannot change is its field alone: nothing to open.
    final box = !enabled
        ? anchorField(null, false)
        : DesignAnchoredOverlay(
            arrowKeyNavigation: true,
            semanticLabel: label,
            placement: const DesignOverlayPlacement(margin: GlossSpacing.small),
            dampingRatio: GlossMotion.panelDamping,
            stiffness: GlossMotion.panelStiffness,
            anchorBuilder: (context, anchor) =>
                anchorField(anchor.toggle, anchor.isOpen),
            overlayBuilder: (context, info) {
              final shown = info.animation.drive(
                Animatable<double>.fromCallback((v) => v.clamp(0.0, 1.0)),
              );
              return FadeTransition(
                opacity: shown,
                child: AnimatedBuilder(
                  animation: info.animation,
                  builder: (context, child) => Transform.translate(
                    offset: Offset(
                      0,
                      (1 - info.animation.value) *
                          (info.side == DesignOverlaySide.above ? 6 : -6),
                    ),
                    child: child,
                  ),
                  child: _SelectList<T>(
                    items: items,
                    value: value,
                    rowHeight: height - 4,
                    maxHeight: info.maxSize.height,
                    onChosen: (v) {
                      info.close();
                      onChanged?.call(v);
                    },
                  ),
                ),
              );
            },
          );
    // From 600 up a select takes its words' room, never its column's.
    final narrow = MediaQuery.sizeOf(context).width < 600;
    final field = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (label != null)
          ExcludeSemantics(child: GlossFieldLabel(label!, enabled: enabled)),
        box,
        GlossFieldMessage(helper: helper, error: error),
      ],
    );
    if (narrow) return field;
    return Align(
      alignment: AlignmentDirectional.topStart,
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: maxWideWidth),
        child: field,
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<T>('value', value))
      ..add(IntProperty('items', items.length))
      ..add(StringProperty('label', label, defaultValue: null))
      ..add(
        FlagProperty('enabled', value: onChanged != null, ifFalse: 'disabled'),
      );
  }
}

class _SelectList<T> extends StatefulWidget {
  const _SelectList({
    required this.items,
    required this.value,
    required this.rowHeight,
    required this.maxHeight,
    required this.onChosen,
  });

  final List<GlossSelectItem<T>> items;
  final T? value;
  final double rowHeight;
  final double maxHeight;
  final ValueChanged<T> onChosen;

  @override
  State<_SelectList<T>> createState() => _SelectListState<T>();
}

class _SelectListState<T> extends State<_SelectList<T>> {
  static const double _inset = 4;
  static const double _radius = 16;

  late final List<FocusNode> _nodes = [
    for (final item in widget.items)
      FocusNode(debugLabel: 'GlossSelect ${item.label}'),
  ];
  final GlobalKey _chosenKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // A long list opens on its value: the chosen row is in view from the
    // first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final row = _chosenKey.currentContext;
      if (row != null && mounted) {
        Scrollable.ensureVisible(row, alignment: 0.5);
      }
    });
  }

  @override
  void dispose() {
    for (final node in _nodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = GlossTheme.of(context);
    final c = theme.colors;
    final light = c.brightness == Brightness.light;
    return GlossSurface(
      face: GlossFace.porcelain(c, radius: _radius).copyWith(
        lift: 1,
        top: light ? const Color(0xFFFFFFFF) : const Color(0xFF343A41),
        middle: light ? const Color(0xFFF8F9FA) : const Color(0xFF2C3137),
        bottom: light ? const Color(0xFFF3F5F7) : const Color(0xFF282C32),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: (widget.rowHeight * 7.5 + 2 * _inset).clamp(
            widget.rowHeight + 2 * _inset,
            widget.maxHeight,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(_inset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, item) in widget.items.indexed)
                _row(context, theme, c, i, item, light),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(
    BuildContext context,
    GlossThemeData theme,
    GlossColors c,
    int i,
    GlossSelectItem<T> item,
    bool light,
  ) {
    final isChosen = item.value == widget.value;
    return MouseRegion(
      // The pointer's row is the current row: it takes the focus, so the
      // keys go on from it and never light a second row.
      onEnter: item.enabled ? (_) => _nodes[i].requestFocus() : null,
      child: DesignPressable(
        key: isChosen ? _chosenKey : null,
        focusNode: _nodes[i],
        onPressed: item.enabled ? () => widget.onChosen(item.value) : null,
        autofocus: isChosen,
        selected: isChosen,
        semanticSelected: isChosen,
        semanticLabel: item.label,
        builder: (context, states, _) {
          final lit =
              states.contains(WidgetState.focused) ||
              states.contains(WidgetState.hovered);
          final pressed = states.contains(WidgetState.pressed);
          final plate = glossRowPlate(
            c,
            lit: !light && lit,
            pressed: pressed,
            radius: _radius - _inset,
          );
          final words = !item.enabled
              ? c.inkDisabled
              : isChosen
              ? c.jadeInk
              : c.ink;
          return SizedBox(
            height: widget.rowHeight,
            child: AnimatedGlossSurface(
              face: plate.copyWith(
                foreground: words,
                focus: glossGlazeOf(c, states),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: GlossSpacing.medium,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: DesignCapCenter(
                        capHeightFactor: glossCapHeightFactor,
                        child: Text(
                          item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.body.copyWith(
                            color: words,
                            fontWeight: isChosen
                                ? FontWeight.w600
                                : FontWeight.w400,
                            fontVariations: glossWeightAxis(
                              isChosen ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (isChosen)
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CustomPaint(painter: _CheckPainter(words)),
                      ),
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

class _CheckPainter extends CustomPainter {
  _CheckPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.16, size.height * 0.54)
        ..lineTo(size.width * 0.42, size.height * 0.78)
        ..lineTo(size.width * 0.86, size.height * 0.26),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_CheckPainter old) => old.color != color;
}
