/// The select: a field's frame showing the chosen value and a `▾`, whose
/// press opens a menu of the choices, as wide as the field.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../internal/field_cursor.dart';
import '../internal/list_open.dart';
import '../internal/menu_marks.dart';
import '../internal/type_ahead.dart';
import '../primitives/field_frame.dart';
import '../primitives/control.dart';
import '../style.dart';
import '../theme.dart';
import 'list_tile.dart';
import 'pane.dart';

/// One choice in a [TermSelect]: its [value], the [label] shown, and an
/// optional dim [detail] beside it.
@immutable
class TermSelectItem<T> {
  /// A choice standing for [value].
  const TermSelectItem({
    required this.value,
    required this.label,
    this.detail,
    this.enabled = true,
  });

  /// What choosing it sets.
  final T value;

  /// Its words.
  final String label;

  /// Dim words beside it: what it means, a count.
  final String? detail;

  /// Whether it can be chosen.
  final bool enabled;
}

/// A select: the frame a [TermTextField] has, with the chosen [value]'s
/// label on its line and a `▾` at the end. A press, Return, Space or Down
/// opens a menu of [items] under it, exactly as wide as the field, the
/// chosen one in inverse video and the cursor on it. Up and Down move through
/// it, round from the last to the first, Home and End go to the ends, a
/// letter to the next item it starts; Return chooses, Escape closes it and
/// the keys are back on the field. The pointer over an item, and the keys
/// on one, mark it with the accent: its words, and a block at its start.
///
/// ```dart
/// TermSelect<String>(
///   labelText: 'environment',
///   value: environment,
///   items: const [
///     TermSelectItem(value: 'staging', label: 'staging'),
///     TermSelectItem(value: 'production', label: 'production'),
///   ],
///   onChanged: (value) => setState(() => environment = value),
/// )
/// ```
///
/// Reads [TermStyle]'s `edge` (the frame), `foreground` (the value) and
/// `textStyle`.
class TermSelect<T> extends StatefulWidget {
  /// A select over [items], in a three-line frame.
  const TermSelect({
    super.key,
    required this.items,
    required this.value,
    required this.onChanged,
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.focusNode,
    this.autofocus = false,
    this.style,
  }) : inline = false,
       labelCols = null;

  /// A select on one line, as a config file lays one out: the label, then
  /// the chosen value and its `▾` in brackets; the menu opens under the
  /// brackets, as wide as they are. [labelCols] gives the label a width in
  /// cells, as [TermTextField.inline] does.
  const TermSelect.inline({
    super.key,
    required this.items,
    required this.value,
    required this.onChanged,
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.focusNode,
    this.autofocus = false,
    this.style,
    this.labelCols,
  }) : inline = true;

  /// Whether it stands on one line ([TermSelect.inline]).
  final bool inline;

  /// On one line, the label's width in cells; null for the label's own.
  final int? labelCols;

  /// The choices.
  final List<TermSelectItem<T>> items;

  /// The chosen value, or null for none (the [hintText] shows).
  final T? value;

  /// Called with the value chosen; null disables the select.
  final ValueChanged<T>? onChanged;

  /// What the select is, cut into the frame's top line.
  final String? labelText;

  /// The dim words while nothing is chosen.
  final String? hintText;

  /// Help, cut into the bottom line.
  final String? helperText;

  /// What is wrong, in place of the help; null while it is fine.
  final String? errorText;

  /// {@macro term.focusNode}
  final FocusNode? focusNode;

  /// {@macro term.autofocus}
  final bool autofocus;

  /// Overrides, over the theme's [TermThemeData.selectStyle]: `edge` (the
  /// frame or the brackets), `foreground` (the value) and `textStyle` (its
  /// colour and weight). The menu's rows read [TermThemeData.menuStyle].
  final TermStyle? style;

  @override
  State<TermSelect<T>> createState() => _TermSelectState<T>();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<T>('value', value))
      ..add(IntProperty('items', items.length))
      ..add(StringProperty('labelText', labelText, defaultValue: null))
      ..add(StringProperty('errorText', errorText, defaultValue: null))
      ..add(FlagProperty('inline', value: inline, ifTrue: 'inline'))
      ..add(IntProperty('labelCols', labelCols, defaultValue: null))
      ..add(
        FlagProperty('enabled', value: onChanged != null, ifFalse: 'disabled'),
      );
  }
}

class _TermSelectState<T> extends State<TermSelect<T>> {
  FocusNode? _ownFocus;
  FocusNode get _focus => widget.focusNode ?? (_ownFocus ??= FocusNode());
  final _menu = MenuController();

  @override
  void dispose() {
    _ownFocus?.dispose();
    super.dispose();
  }

  // Among the rows that can be chosen, the chosen one's place, or -1.
  int _chosenAt() => [
    for (final item in widget.items)
      if (item.enabled) item,
  ].indexWhere((item) => item.value == widget.value);

  @override
  Widget build(BuildContext context) {
    TermMenuMarks.watchInput();
    final theme = TermTheme.of(context);
    final grid = context.termGrid;
    final cw = grid.cellWidth;
    final lh = grid.lineHeight;
    final enabled = widget.onChanged != null;
    final chosenAt = _chosenAt();
    TermSelectItem<T>? chosen;
    for (final item in widget.items) {
      if (item.value == widget.value) chosen = item;
    }

    // The value at rest: its words' colour and weight.
    final rest = TermStyleOf(
      [widget.style, theme.selectStyle],
      {if (!enabled) WidgetState.disabled},
    );
    // What the field shows: the chosen value's words and the `▾`.
    // Under the keyboard's cursor its words are cut out of it.
    final value = Builder(
      builder: (context) => Row(
        children: [
          Expanded(
            child: Text(
              chosen?.label ?? widget.hintText ?? '',
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: chosen == null
                  ? theme.dimStyle.copyWith(
                      color: TermFieldCursor.inkOf(context, theme.dim),
                    )
                  : theme.textStyle
                        .merge(rest.textStyle)
                        .copyWith(
                          color: TermFieldCursor.inkOf(
                            context,
                            enabled
                                ? rest.foreground ?? theme.foreground
                                : theme.rule,
                          ),
                        ),
            ),
          ),
          SizedBox(width: cw),
          ExcludeSemantics(
            child: Text(
              '▾',
              style: theme.textStyle.copyWith(
                color: TermFieldCursor.inkOf(
                  context,
                  enabled ? theme.accent : theme.rule,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    // The field, its list open or not ([anchor] null: an off select, which
    // opens nothing and so hangs no list at all).
    Widget field(DesignOverlayAnchor? anchor) => TermListOpen(
      open: anchor?.isOpen ?? false,
      child: DesignField(
        labelText: widget.labelText,
        helperText: widget.helperText,
        errorText: widget.errorText,
        enabled: enabled,
        focusNode: _focus,
        builder: (context, parts) {
          // The press, round the frame, or on one line round the brackets
          // alone: the label is the line's words.
          Widget press(Widget Function(Set<WidgetState> states) face) =>
              MergeSemantics(
                child: DesignPressable(
                  onPressed: termOpener(_focus, anchor),
                  focusNode: _focus,
                  autofocus: widget.autofocus,
                  // An off select opens nothing, so it says nothing of
                  // opening.
                  expanded: anchor?.isOpen,
                  isError: parts.hasError,
                  semanticValue: chosen?.label,
                  shortcuts: const {
                    SingleActivator(LogicalKeyboardKey.arrowDown):
                        ActivateIntent(),
                  },
                  mouseCursor: enabled
                      ? SystemMouseCursors.click
                      : SystemMouseCursors.basic,
                  builder: (context, states, _) => face(states),
                ),
              );
          TermStyleOf own(Set<WidgetState> states) =>
              TermStyleOf([widget.style, theme.selectStyle], states);
          bool active(Set<WidgetState> states) =>
              states.contains(WidgetState.focused) || (anchor?.isOpen ?? false);
          if (widget.inline) {
            return TermFieldLine(
              parts: parts,
              active: false,
              labelCols: widget.labelCols,
              control: (brackets) =>
                  press((states) => brackets(active(states), own(states).edge)),
              child: parts.control,
            );
          }
          return press(
            (states) => TermStateSprings(
              pressed: false,
              focused: states.contains(WidgetState.focused),
              builder: (context, _, focus) => TermFieldFrame(
                parts: parts,
                active: active(states),
                edge: own(states).edge,
                child: TermFieldCursor(focus: focus, child: parts.control),
              ),
            ),
          );
        },
        child: value,
      ),
    );

    if (!enabled) return field(null);
    return DesignAnchoredOverlay(
      controller: _menu,
      arrowKeyNavigation: true,
      dampingRatio: TermMotion.reveal.dampingRatio,
      stiffness: TermMotion.reveal.stiffness,
      semanticLabel: widget.labelText,
      placement: DesignOverlayPlacement(
        gap: 0,
        margin: cw,
        preferredExtent: lh * 6,
      ),
      anchorBuilder: (context, anchor) => field(anchor),
      overlayBuilder: (context, info) => AnimatedBuilder(
        animation: info.animation,
        builder: (context, child) {
          // A spring only nears 1: within a hair of it, the menu is open.
          final v = info.animation.value;
          final t = v >= 0.995 ? 1.0 : v.clamp(0.0, 1.0);
          // On one line the menu starts under the brackets, not the label.
          final indent = widget.inline
              ? TermFieldLine.indentOf(
                  grid,
                  info.anchorRect.width,
                  widget.labelText,
                  widget.labelCols,
                )
              : 0.0;
          // As wide as the field's own box: a framed field's, all it is
          // given; an inline one's brackets, whole cells (the cells left
          // over past them stay empty under the list too).
          final w = info.anchorRect.width;
          final menu = Padding(
            padding: EdgeInsetsDirectional.only(start: indent),
            child: SizedBox(
              width: (indent > 0 ? grid.cols(grid.colsIn(w)) : w) - indent,
              child: child,
            ),
          );
          // Revealed from the field's side, the menu itself never moving:
          // as wide as it is from the first frame (widthFactor 1, so the
          // reveal never widens it to the screen), the same tree once open.
          return ClipRect(
            clipBehavior: t >= 1 ? Clip.none : Clip.hardEdge,
            child: Align(
              alignment: info.side == DesignOverlaySide.above
                  ? AlignmentDirectional.bottomStart
                  : AlignmentDirectional.topStart,
              widthFactor: 1,
              heightFactor: t,
              child: menu,
            ),
          );
        },
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: info.maxSize.height),
          child: TermPane(
            raised: true,
            focused: true,
            // A cell inside the frame each side, as a menu's: the keys'
            // block and the chosen bar stand as far from the frame's sides
            // as from its top and bottom lines.
            padding: const TermInset(),
            // The keys: the focus on the chosen one (or the first that
            // takes it) as the menu comes up, a letter to the next it starts.
            // Opened by the pointer, the keys' block waits for a key: with
            // nothing chosen, no row reads current until then.
            child: TermTypeAhead(
              initial: chosenAt >= 0 ? chosenAt : 0,
              child: TermMenuMarks(
                quietFirst: chosenAt < 0,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final item in widget.items)
                        TermListTile(
                          title: Text(item.label),
                          subtitle: item.detail == null
                              ? null
                              : Text(item.detail!),
                          selected: item.value == widget.value,
                          enabled: item.enabled,
                          option: true,
                          style: theme.menuStyle,
                          onTap: item.enabled
                              ? () {
                                  info.close();
                                  widget.onChanged?.call(item.value);
                                }
                              : null,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
