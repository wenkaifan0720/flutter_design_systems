/// Brutal's select: [BrutalSelect], a field-shaped box whose chevron stands
/// in a cell of its own, and whose list hangs from the box on its bottom
/// rule.
library;

import 'dart:async' show scheduleMicrotask;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'internal/drop_mark.dart';
import 'internal/field_frame.dart';
import 'internal/focus_ink.dart';
import 'internal/keep_in_view.dart';
import 'internal/keyed_row.dart';
import 'internal/type_ahead.dart';
import 'surface.dart';
import 'text_field.dart';
import 'theme.dart';

/// One choice in a [BrutalSelect].
@immutable
class BrutalSelectItem<T> {
  /// The choice [value], shown as [label].
  const BrutalSelectItem({
    required this.value,
    required this.label,
    this.enabled = true,
  });

  /// What choosing it sets.
  final T value;

  /// What it says.
  final String label;

  /// Whether it can be chosen.
  final bool enabled;
}

/// A choice of one from a short list, shaped like a [BrutalTextField]: its
/// [labelText] above, its [helperText] or [errorText] below. The chevron stands in a
/// square cell at the box's end, on a rule of its own; the open list hangs
/// from the box, its top rule the box's bottom one, as wide as the box: the
/// chosen item ink, bold, with a square mark; where the pointer or the
/// keyboard is, a rule round the row, inside its edges.
/// Held down, the chevron's cell turns over (ink for paper).
///
/// It takes its column's width at every width, as a text field does, so
/// the fields of a form stand on one edge.
///
/// A null [onChanged] disables it. Enter, Space, Down or Up opens it with
/// the keyboard on the chosen item (the first when none is); a press opens
/// it with the box focused, so the keys work at once there too. Up and Down
/// move through the open list, round from the end to the start; Home and End
/// go to the ends; a typed letter goes to the next item starting with it;
/// Enter or Space chooses and closes; Escape closes. Either way the keyboard
/// comes back to the box.
///
/// Reads [style]'s `fill`, `edge`, `foreground`, `padding`, `minimumSize`
/// (the box's height) and `textStyle` in its states, then
/// [BrutalThemeData.textFieldStyle]'s; the open list reads
/// [BrutalThemeData.menuStyle], as every menu does.
///
/// ```dart
/// BrutalSelect<String>(labelText: 'City', value: city, items: const [BrutalSelectItem(value: 'north', label: 'North quarter'), BrutalSelectItem(value: 'harbour', label: 'Harbour')], onChanged: (value) => setState(() => city = value))
/// ```
class BrutalSelect<T> extends StatefulWidget {
  /// A select over [items].
  const BrutalSelect({
    super.key,
    required this.items,
    required this.value,
    required this.onChanged,
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.focusNode,
    this.style,
  });

  /// The choices.
  final List<BrutalSelectItem<T>> items;

  /// The chosen value, or null for none (the [hintText] shows).
  final T? value;

  /// Called with the value chosen; null disables the select.
  final ValueChanged<T>? onChanged;

  /// The words over the box.
  final String? labelText;

  /// What the box says while nothing is chosen.
  final String? hintText;

  /// Help under the box.
  final String? helperText;

  /// What is wrong, under the box in red.
  final String? errorText;

  /// {@macro design.focusNode}
  final FocusNode? focusNode;

  /// The box's style, over [BrutalThemeData.textFieldStyle].
  final BrutalStyle? style;

  @override
  State<BrutalSelect<T>> createState() => _BrutalSelectState<T>();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<T>('value', value))
      ..add(IntProperty('items', items.length))
      ..add(StringProperty('labelText', labelText, defaultValue: null))
      ..add(
        FlagProperty('enabled', value: onChanged != null, ifFalse: 'disabled'),
      );
  }
}

class _BrutalSelectState<T> extends State<BrutalSelect<T>> {
  // The box's focus node when the app gives none, as a text field keeps
  // one: a press focuses the box, so the list gives the keyboard back here.
  FocusNode? _ownFocus;

  FocusNode get _focus =>
      widget.focusNode ?? (_ownFocus ??= FocusNode(debugLabel: 'BrutalSelect'));

  @override
  void dispose() {
    _ownFocus?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final BrutalSelect(
      :items,
      :value,
      :onChanged,
      :labelText,
      :hintText,
      :helperText,
      :errorText,
      :style,
    ) = widget;
    final theme = BrutalTheme.of(context);
    final c = theme.colors;
    final enabled = onChanged != null;
    final chosen = items.where((i) => i.value == value).firstOrNull;
    final height =
        RawStyleOf([
          style,
          theme.textFieldStyle,
        ], const {}).minimumSize?.height ??
        theme.controlHeight;
    // The box. Disabled (no [onChanged]) it opens nothing, so it is drawn
    // without the overlay and says nothing about opening.
    Widget face(RawOverlayAnchor? anchor) {
      final open = anchor?.isOpen ?? false;
      return RawButton(
        onPressed: anchor == null
            ? null
            : () {
                final node = _focus;
                if (anchor.isOpen || node.hasPrimaryFocus) {
                  anchor.toggle();
                  return;
                }
                // A press focuses the box first, as a click does a native
                // select, and opens the list once the focus has landed: the
                // list gives the keyboard back here when it closes.
                node.requestFocus();
                scheduleMicrotask(anchor.open);
              },
        // Down or Up opens it too, as on every platform's select.
        onKeyEvent: anchor == null
            ? null
            : (node, event) {
                final arrow =
                    event.logicalKey == LogicalKeyboardKey.arrowDown ||
                    event.logicalKey == LogicalKeyboardKey.arrowUp;
                if (event is! KeyDownEvent || !arrow || anchor.isOpen) {
                  return KeyEventResult.ignored;
                }
                anchor.open();
                return KeyEventResult.handled;
              },
        focusNode: _focus,
        expanded: anchor?.isOpen,
        // Named by its field (ui_core's RawInputDecorator), with its help.
        semanticValue: chosen?.label,
        builder: (context, states, _) {
          final layered = RawStyleOf(
            [style, theme.textFieldStyle],
            {...states, if (errorText != null) WidgetState.error},
          );
          final rule =
              layered.side?.color ??
              layered.edge ??
              (!enabled
                  ? c.disabled
                  : errorText != null
                  ? c.danger
                  : c.ink);
          final ink = layered.foreground ?? (enabled ? c.ink : c.disabled);
          final held = enabled && states.contains(WidgetState.pressed);
          return SizedBox(
            height: height,
            child: AnimatedBrutalSurface(
              stiffness: BrutalMotion.colorStiffness,
              face: BrutalFace(
                fill: layered.fill ?? c.surface,
                border: rule,
                foreground: ink,
                // Focused and closed: open, the list says so and the
                // keyboard is in it (a ring would stub out beside its top).
                focus: states.contains(WidgetState.focused) && !open
                    ? (errorText != null
                          ? c.danger
                          : brutalFocusInk(c, layered.fill ?? c.surface))
                    : rule.withValues(alpha: 0),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding:
                          layered.padding(Directionality.of(context)) ??
                          const EdgeInsets.symmetric(
                            horizontal: BrutalSpacing.medium,
                          ),
                      child: RawCapCenter(
                        capHeightFactor: BrutalTheme.of(context)
                            .capHeightFactor,
                        child: Text(
                          chosen?.label ?? hintText ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: layered.text(
                            theme.textTheme.body.copyWith(
                              color: !enabled
                                  ? c.disabled
                                  : chosen == null
                                  ? c.inkMuted
                                  : ink,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: theme.borderWidth,
                    child: ColoredBox(color: rule),
                  ),
                  // Held down, the chevron's cell turns over, as a cell does
                  // under a press.
                  SizedBox(
                    width: height - 2 * theme.borderWidth,
                    child: ColoredBox(
                      color: held ? rule : rule.withValues(alpha: 0),
                      child: Center(
                        child: BrutalDropMark(
                          open: open,
                          color: held ? layered.fill ?? c.surface : ink,
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
    }

    final Widget box = !enabled
        ? face(null)
        : RawPopover(
            arrowKeyNavigation: true,
            semanticLabel: labelText,
            placement: RawPopoverPlacement(
              gap: -theme.borderWidth,
              margin: BrutalSpacing.small,
            ),
            dampingRatio: BrutalMotion.dampingRatio,
            stiffness: BrutalMotion.overlayStiffness,
            anchorBuilder: (context, anchor) => face(anchor),
            overlayBuilder: (context, info) => FadeTransition(
              opacity: info.animation,
              child: _SelectList<T>(
                items: items,
                value: value,
                rowHeight: height,
                onChosen: (v) {
                  info.close();
                  onChanged(v);
                },
              ),
            ),
          );
    return BrutalFieldFrame(
      labelText: labelText,
      helperText: helperText,
      errorText: errorText,
      enabled: enabled,
      child: box,
    );
  }
}

class _SelectList<T> extends StatefulWidget {
  const _SelectList({
    required this.items,
    required this.value,
    required this.rowHeight,
    required this.onChosen,
  });

  final List<BrutalSelectItem<T>> items;
  final T? value;
  final double rowHeight;
  final ValueChanged<T> onChosen;

  @override
  State<_SelectList<T>> createState() => _SelectListState<T>();
}

class _SelectListState<T> extends State<_SelectList<T>> {
  late final List<FocusNode> _nodes = [
    for (final item in widget.items) FocusNode(debugLabel: item.label),
  ];

  // Whether a pointer has moved over the list: from then on the keyboard's row
  // is lit even where the platform shows no focus after a touch.
  bool _pointer = false;

  // The keyboard's row changes without the platform showing it, after a touch.
  void _moved() {
    if (_pointer && mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    for (final node in _nodes) {
      node.addListener(_moved);
    }
    brutalKeepInView(_nodes);
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
    final items = widget.items;
    final value = widget.value;
    final rowHeight = widget.rowHeight;
    final onChosen = widget.onChosen;
    final theme = BrutalTheme.of(context);
    final c = theme.colors;
    final panel = RawStyleOf([theme.menuStyle], const {});
    final ruleColor = panel.side?.color ?? panel.edge ?? c.ink;
    // The rule is drawn over the list, so the list itself is the field's
    // width from the field's edge; its rows stand inside the rule.
    return BrutalSurface(
      face: BrutalFace(
        fill: panel.fill ?? c.surface,
        border: ruleColor,
        foreground: c.ink,
        shadow: c.ink,
        borderWidth: 0,
      ),
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          border: Border.all(color: ruleColor, width: theme.borderWidth),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: rowHeight * 6.5),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(theme.borderWidth),
            child: BrutalTypeAhead(
              labels: [for (final item in items) item.label],
              nodes: [
                for (final (i, item) in items.indexed)
                  item.enabled ? _nodes[i] : null,
              ],
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (i, item) in items.indexed) ...[
                    if (i > 0)
                      SizedBox(
                        height: theme.borderWidth,
                        child: ColoredBox(color: ruleColor),
                      ),
                    MouseRegion(
                      // A move, not a row scrolled under a resting pointer,
                      // takes the keyboard to the pointer's row.
                      onHover: item.enabled
                          ? (_) {
                              if (!_nodes[i].hasPrimaryFocus) {
                                _nodes[i].requestFocus();
                              }
                              if (!_pointer) setState(() => _pointer = true);
                            }
                          : null,
                      child: RawButton(
                        onPressed: item.enabled
                            ? () => onChosen(item.value)
                            : null,
                        focusNode: _nodes[i],
                        // The chosen row takes the keyboard as the list
                        // opens, and the popover keeps it in view.
                        autofocus: item.enabled && item.value == value,
                        selected: item.value == value,
                        semanticSelected: item.value == value,
                        semanticLabel: item.label,
                        builder: (context, states, _) {
                          final row = RawStyleOf([theme.menuStyle], states);
                          // Ink is the chosen item, or the one pressed on the way
                          // to choosing it; where the pointer or the keyboard is,
                          // a line inside the row: never a second ink row.
                          final lit =
                              item.enabled &&
                              (item.value == value ||
                                  states.contains(WidgetState.pressed));
                          // The pointer moves the keyboard (above): one row
                          // is lit, the keyboard's, whether or not the
                          // platform shows focus after a touch.
                          final here =
                              states.contains(WidgetState.focused) ||
                              (_pointer && _nodes[i].hasPrimaryFocus);
                          final words =
                              row.foreground ??
                              (!item.enabled
                                  ? c.disabled
                                  : row.fill != null
                                  ? c.onColor(row.fill!)
                                  : lit
                                  ? c.paper
                                  : c.ink);
                          return SizedBox(
                            height: rowHeight - theme.borderWidth,
                            child: CustomPaint(
                              foregroundPainter: here
                                  ? BrutalKeyedRowPainter(
                                      lit || row.fill != null ? words : c.ink,
                                    )
                                  : null,
                              child: AnimatedBrutalSurface(
                                stiffness: BrutalMotion.colorStiffness,
                                face: BrutalFace(
                                  fill:
                                      row.fill ??
                                      (lit
                                          ? c.ink
                                          : c.ink.withValues(alpha: 0)),
                                  border: c.ink.withValues(alpha: 0),
                                  foreground: words,
                                  borderWidth: 0,
                                ),
                                child: Padding(
                                  padding:
                                      row.padding(Directionality.of(context)) ??
                                      const EdgeInsets.symmetric(
                                        horizontal: BrutalSpacing.medium,
                                      ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: RawCapCenter(
                                          capHeightFactor: BrutalTheme.of(
                                            context,
                                          ).capHeightFactor,
                                          child: Text(
                                            item.label,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: row.text(
                                              theme.textTheme.body.copyWith(
                                                color: words,
                                                fontWeight: item.value == value
                                                    ? FontWeight.w700
                                                    : FontWeight.w400,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (item.value == value)
                                        SizedBox.square(
                                          dimension: 12,
                                          child: ColoredBox(color: words),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
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
}
