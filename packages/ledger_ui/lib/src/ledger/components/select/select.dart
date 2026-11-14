import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../internal/cap_center.dart';
import '../../internal/end_glyph.dart';
import '../../internal/field_frame.dart';
import '../../theme.dart';
import '../pressable/pressable.dart';
import '../text-field/text_field.dart';

/// One choice of a [LedgerSelect]: its [value] and the words it shows.
@immutable
class LedgerSelectItem<T> {
  /// A choice of [value], worded [label].
  const LedgerSelectItem({
    required this.value,
    required this.label,
    this.icon,
    this.enabled = true,
  });

  /// What choosing it sets.
  final T value;

  /// Its words, in the field and in the list.
  final String label;

  /// A Lucide glyph before its words in the list.
  final IconData? icon;

  /// Whether it can be chosen.
  final bool enabled;
}

/// A choice among [items], written on a rule as [LedgerTextField] is: the
/// chosen item's words on the line (its [hint] in the third ink while none
/// is), a chevron at the end. A press opens the list under it on the raised
/// paper, ruled between its rows, the chosen one ticked in the accent; the
/// arrow keys move through it, Enter chooses, Escape closes. A null
/// [onChanged] disables it. From 600 it stands at a short entry's measure
/// (at the start of its slot, at most [LedgerLayout.fieldMeasure]) and its
/// list hugs its options (never narrower than the select); on a phone both
/// span the column. The field's words stand on the rule with no inset, so
/// the list's paper stands out past the field by its rows' inset (a glyph
/// column's too, hung before the words) and past its end by the same 16:
/// every option's words start on the field's words, the tick on its
/// chevron's end, the paper kept 4 inside the window (a phone's 20 gutter
/// holds the 16).
///
/// ```dart
/// LedgerSelect<String>(label: 'Currency', value: 'USD', items: const [LedgerSelectItem(value: 'USD', label: 'US dollar'), LedgerSelectItem(value: 'EUR', label: 'Euro')], onChanged: (v) {})
/// ```
class LedgerSelect<T> extends StatefulWidget {
  /// A choice among [items], [value] chosen.
  const LedgerSelect({
    required this.items,
    required this.value,
    required this.onChanged,
    this.label,
    this.hint,
    this.helper,
    this.error,
    this.isRequired = false,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  /// The choices, in order.
  final List<LedgerSelectItem<T>> items;

  /// The chosen value, or null for none.
  final T? value;

  /// Called with the value chosen; null disables the select.
  final ValueChanged<T>? onChanged;

  /// What it chooses, over the line in the small capitals; its spoken name.
  final String? label;

  /// Shown while nothing is chosen; "Choose one" when null (English in
  /// 0.1.0: the shared words have no such prompt).
  final String? hint;

  /// Help under the rule.
  final String? helper;

  /// What is wrong, under the rule in the danger red.
  final String? error;

  /// Whether a choice must be made.
  final bool isRequired;

  /// Its focus; the select's own when null. The caller's to dispose.
  final FocusNode? focusNode;

  /// Whether it takes focus when it first appears.
  final bool autofocus;

  @override
  State<LedgerSelect<T>> createState() => _LedgerSelectState<T>();
}

class _LedgerSelectState<T> extends State<LedgerSelect<T>> {
  FocusNode? _ownFocus;
  FocusNode get _focus => widget.focusNode ?? (_ownFocus ??= FocusNode());

  @override
  void dispose() {
    _ownFocus?.dispose();
    super.dispose();
  }

  LedgerSelectItem<T>? get _chosen {
    for (final item in widget.items) {
      if (item.value == widget.value) return item;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final words = LedgerTextField.wordsOf(t);
    final enabled = widget.onChanged != null;
    final chosen = _chosen;
    final hint = widget.hint ?? 'Choose one';
    return LedgerLayout.measured(
      context,
      DesignField(
        labelText: widget.label,
        helperText: widget.helper,
        errorText: widget.error,
        required: widget.isRequired,
        enabled: enabled,
        focusNode: _focus,
        builder: (context, parts) => LedgerFieldFrame(
          parts: parts,
          focusNode: _focus,
          line: parts.control,
        ),
        child: DesignAnchoredOverlay(
          arrowKeyNavigation: true,
          semanticLabel: widget.label,
          placement: const DesignOverlayPlacement(
            gap: 6,
            matchAnchorWidth: true,
            preferredExtent: 240,
          ),
          anchorBuilder: (context, anchor) => LedgerPressable(
            onTap: enabled ? anchor.toggle : null,
            focusNode: _focus,
            autofocus: widget.autofocus,
            label: widget.label ?? hint,
            value: chosen?.label,
            expanded: anchor.isOpen,
            isError: widget.error != null,
            child: SizedBox(
              height: LedgerTextField.heightOf(t),
              child: Row(
                spacing: 8,
                children: [
                  Expanded(
                    child: ledgerCapCenter(
                      words,
                      Text(
                        chosen?.label ?? hint,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                        style: chosen == null
                            ? words
                                  .copyWith(fontWeight: FontWeight.w400)
                                  .colored(t.textTertiary)
                            : words.colored(
                                enabled ? t.textPrimary : t.textTertiary,
                              ),
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: anchor.isOpen ? .5 : 0,
                    duration: const Duration(milliseconds: 160),
                    child: LedgerEndGlyph(
                      LucideIcons.chevronDown,
                      size: _chevron,
                      color: enabled ? t.textSecondary : t.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          overlayBuilder: (context, info) => FadeTransition(
            // The overlay's spring can pass 1; an opacity can't.
            opacity: info.animation.drive(_unit),
            child: _SelectList<T>(
              items: widget.items,
              value: widget.value,
              maxHeight: info.maxSize.height,
              anchor: info.anchorRect,
              onChosen: (value) {
                info.close();
                widget.onChanged?.call(value);
              },
            ),
          ),
        ),
      ),
    );
  }

  static const double _chevron = 18;

  static final Animatable<double> _unit = Animatable<double>.fromCallback(
    (v) => v.clamp(0.0, 1.0),
  );
}

class _SelectList<T> extends StatelessWidget {
  const _SelectList({
    required this.items,
    required this.value,
    required this.maxHeight,
    required this.anchor,
    required this.onChosen,
  });

  final List<LedgerSelectItem<T>> items;
  final T? value;
  final double maxHeight;

  /// The field's box in the overlay (the window).
  final Rect anchor;
  final ValueChanged<T> onChosen;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final words = t.rowTitle.copyWith(
      leadingDistribution: TextLeadingDistribution.even,
    );
    // The list hugs its options: its widest words with the room round them,
    // the glyphs' and the tick's columns; the overlay holds it to at least
    // the select's own width.
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    var widest = 0.0;
    for (final item in items) {
      final p = TextPainter(
        text: TextSpan(text: item.label, style: words),
        textDirection: direction,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      if (p.width > widest) widest = p.width;
      p.dispose();
    }
    final glyphs = items.any((i) => i.icon != null) ? _glyph + _gap : 0.0;
    final hug = (2 * _pad + glyphs + widest + _gap + _glyph).ceilToDouble();
    // Out past the field's start by the rows' inset, so the words stand on
    // the field's; past its end by the pad, so the tick ends on the
    // chevron's end. Each kept [_margin] inside the window.
    final window = MediaQuery.sizeOf(context).width;
    final rtl = direction == TextDirection.rtl;
    final before = rtl ? window - anchor.right : anchor.left;
    final after = rtl ? anchor.left : window - anchor.right;
    final start = math.max(0.0, math.min(_pad + glyphs, before - _margin));
    final end = math.max(0.0, math.min(_pad, after - _margin));
    return _Outdent(
      start: start,
      end: end,
      hug: hug,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(t.smallRadius),
            border: Border.all(color: t.border),
            boxShadow: t.menuShadow,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(t.smallRadius),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (i, item) in items.indexed) ...[
                    if (i > 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: _pad),
                        child: SizedBox(
                          height: 1,
                          child: ColoredBox(color: t.hairline),
                        ),
                      ),
                    LedgerPressable(
                      onTap: item.enabled ? () => onChosen(item.value) : null,
                      label: item.label,
                      selected: item.value == value,
                      radius: 0,
                      ringInsets: const EdgeInsets.all(2),
                      child: SizedBox(
                        height: t.density.height(_row),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: _pad),
                          child: Row(
                            spacing: _gap,
                            children: [
                              if (item.icon case final g?)
                                Icon(g, size: _glyph, color: t.textSecondary)
                              else if (glyphs > 0)
                                // The glyphs' column, kept on every row so
                                // every option's words start on one x.
                                const SizedBox(width: _glyph),
                              Expanded(
                                child: ledgerCapCenter(
                                  words,
                                  Text(
                                    item.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: words.colored(
                                      item.enabled
                                          ? t.textPrimary
                                          : t.textTertiary,
                                    ),
                                  ),
                                ),
                              ),
                              if (item.value == value)
                                Icon(
                                  LucideIcons.check,
                                  size: _glyph,
                                  color: t.accent,
                                )
                              else
                                // The tick's column, kept on every row.
                                const SizedBox(width: _glyph),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static const double _row = 48;
  static const double _pad = 16;
  static const double _glyph = 18;
  static const double _gap = 12;
  static const double _margin = 4;
}

/// Lays its [child] (the list's paper) out [start] wider before the box the
/// overlay places on the field and [end] wider after it, at least [hug]
/// across, and stands it that far out: the box stays on the field (where
/// the overlay holds it), the paper reaches past it. Taken by a press
/// anywhere on the paper.
class _Outdent extends SingleChildRenderObjectWidget {
  const _Outdent({
    required this.start,
    required this.end,
    required this.hug,
    required super.child,
  });

  final double start;
  final double end;
  final double hug;

  @override
  _RenderOutdent createRenderObject(BuildContext context) =>
      _RenderOutdent(start, end, hug, Directionality.of(context));

  @override
  void updateRenderObject(BuildContext context, _RenderOutdent r) => r
    ..start = start
    ..end = end
    ..hug = hug
    ..direction = Directionality.of(context);
}

class _RenderOutdent extends RenderShiftedBox {
  _RenderOutdent(this._start, this._end, this._hug, this._direction)
    : super(null);

  double _start;
  set start(double v) {
    if (v == _start) return;
    _start = v;
    markNeedsLayout();
  }

  double _end;
  set end(double v) {
    if (v == _end) return;
    _end = v;
    markNeedsLayout();
  }

  double _hug;
  set hug(double v) {
    if (v == _hug) return;
    _hug = v;
    markNeedsLayout();
  }

  TextDirection _direction;
  set direction(TextDirection v) {
    if (v == _direction) return;
    _direction = v;
    markNeedsLayout();
  }

  @override
  void performLayout() {
    final c = child!;
    final width = constraints.constrainWidth(
      math.max(constraints.minWidth, _hug - _start - _end),
    );
    final paper = width + _start + _end;
    c.layout(
      BoxConstraints(
        minWidth: paper,
        maxWidth: paper,
        maxHeight: constraints.maxHeight,
      ),
      parentUsesSize: true,
    );
    final before = _direction == TextDirection.rtl ? _end : _start;
    (c.parentData! as BoxParentData).offset = Offset(-before, 0);
    size = constraints.constrain(Size(width, c.size.height));
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    final c = child;
    if (c == null) return false;
    final at = (c.parentData! as BoxParentData).offset;
    if (!(at & c.size).contains(position)) return false;
    if (hitTestChildren(result, position: position)) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    }
    return false;
  }

  @override
  Rect get paintBounds {
    final c = child;
    if (c == null) return Offset.zero & size;
    return (c.parentData! as BoxParentData).offset & c.size;
  }
}
