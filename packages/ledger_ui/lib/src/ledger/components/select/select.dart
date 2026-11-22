import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../internal/cap_center.dart';
import '../../internal/end_glyph.dart';
import '../../internal/field_frame.dart';
import '../../internal/option_paper.dart';
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
/// paper, ruled between its rows, the chosen one on the menu's paper and
/// ticked in the accent. Enter, Space or Down opens it too; open, the
/// keyboard stands on the chosen option (the first while none is), the
/// arrow keys move at once, round from the last to the first, Home and End
/// go to its ends, a letter to the next option it starts, Enter chooses and
/// closes, and Escape closes, the keyboard back on the field. A null
/// [onChanged] disables it. From 600 it stands at a short entry's measure
/// (at the start of its slot, at most [LedgerLayout.fieldMeasure]); on a
/// phone it spans the column. Its list is the field's width, on the field's
/// leading edge, wider only to fit its widest option (at most 320, as
/// ui_core holds every list from a field). The field's words stand on the
/// rule with no inset; the list's rows keep their 16, so its words stand 16
/// in from the field's.
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

  /// Shown while nothing is chosen; "Choose one" when null (in English:
  /// the shared words have no such prompt).
  final String? hint;

  /// Help under the rule.
  final String? helper;

  /// What is wrong, under the rule in the danger red.
  final String? error;

  /// Whether a choice must be made.
  final bool isRequired;

  /// Its focus; the select's own when null. The caller's to dispose.
  final FocusNode? focusNode;

  /// {@macro ledger.autofocus}
  final bool autofocus;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<LedgerSelectItem<T>>('items', items))
      ..add(DiagnosticsProperty<T>('value', value, defaultValue: null))
      ..add(ObjectFlagProperty<ValueChanged<T>>.has('onChanged', onChanged))
      ..add(StringProperty('label', label, defaultValue: null))
      ..add(StringProperty('hint', hint, defaultValue: null))
      ..add(StringProperty('helper', helper, defaultValue: null))
      ..add(StringProperty('error', error, defaultValue: null))
      ..add(FlagProperty('isRequired', value: isRequired, ifTrue: 'isRequired'))
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'));
  }

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
      RawInputDecorator(
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
        child: RawPopover(
          arrowKeyNavigation: true,
          semanticLabel: widget.label,
          placement: const RawPopoverPlacement(
            gap: 6,
            matchAnchorWidth: true,
            preferredExtent: 240,
          ),
          // Down opens the list from the field, as Enter and Space do.
          anchorBuilder: (context, anchor) => CallbackShortcuts(
            bindings: {
              if (enabled && !anchor.isOpen)
                const SingleActivator(LogicalKeyboardKey.arrowDown):
                    anchor.open,
            },
            child: LedgerPressable(
              onTap: enabled ? anchor.toggle : null,
              focusNode: _focus,
              autofocus: widget.autofocus,
              label: widget.label == null ? hint : null,
              value: chosen?.label,
              expanded: anchor.isOpen,
              isError: widget.error != null,
              child: SizedBox(
                height: LedgerTextField.heightOf(t),
                child: Row(
                  spacing: LedgerSpacing.s8,
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
          ),
          overlayBuilder: (context, info) => FadeTransition(
            // The overlay's spring can pass 1; an opacity can't.
            opacity: info.animation.drive(_unit),
            child: _SelectList<T>(
              items: widget.items,
              value: widget.value,
              maxHeight: info.maxSize.height,
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

class _SelectList<T> extends StatefulWidget {
  const _SelectList({
    required this.items,
    required this.value,
    required this.maxHeight,
    required this.onChosen,
  });

  final List<LedgerSelectItem<T>> items;
  final T? value;
  final double maxHeight;

  final ValueChanged<T> onChosen;

  @override
  State<_SelectList<T>> createState() => _SelectListState<T>();
}

class _SelectListState<T> extends State<_SelectList<T>> {
  late List<FocusNode> _nodes = _made();

  List<FocusNode> _made() => [for (final item in widget.items) _node(item)];

  // Wherever the keyboard goes in a long list (an arrow, Home, End, a
  // letter), its option is scrolled into view.
  FocusNode _node(LedgerSelectItem<T> item) {
    late final FocusNode node;
    node = FocusNode(debugLabel: item.label)..addListener(() => _inView(node));
    return node;
  }

  void _inView(FocusNode node) {
    final at = node.context;
    if (!node.hasPrimaryFocus || at == null || !at.mounted) return;
    for (final policy in const [
      ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      ScrollPositionAlignmentPolicy.keepVisibleAtStart,
    ]) {
      Scrollable.ensureVisible(at, alignmentPolicy: policy);
    }
  }

  @override
  void initState() {
    super.initState();
    // The overlay moves the keyboard to the list's first option once it has
    // built, in this frame's end; the chosen option takes it after, so a
    // list opens on what is chosen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final chosen = widget.items.indexWhere(
        (item) => item.enabled && item.value == widget.value,
      );
      if (chosen < 0) return;
      final node = _nodes[chosen]..requestFocus();
      // A long list opens with the chosen one in the middle of its view.
      final at = node.context;
      if (at != null) Scrollable.ensureVisible(at, alignment: 0.5);
    });
  }

  @override
  void didUpdateWidget(_SelectList<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items.length != widget.items.length) {
      for (final n in _nodes) {
        n.dispose();
      }
      _nodes = _made();
    }
  }

  @override
  void dispose() {
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  /// A letter typed in the list goes to the next option its words start
  /// with, round from the last to the first.
  KeyEventResult _typed(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final keys = HardwareKeyboard.instance;
    final letter = event.character?.trim().toLowerCase() ?? '';
    if (letter.isEmpty ||
        keys.isControlPressed ||
        keys.isMetaPressed ||
        keys.isAltPressed) {
      return KeyEventResult.ignored;
    }
    final from = _nodes.indexWhere((n) => n.hasPrimaryFocus);
    for (var step = 1; step <= _nodes.length; step++) {
      final i = (from + step) % _nodes.length;
      final item = widget.items[i];
      if (item.enabled && item.label.toLowerCase().startsWith(letter)) {
        _nodes[i].requestFocus();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    final value = widget.value;
    final onChosen = widget.onChosen;
    final maxHeight = widget.maxHeight;
    final t = context.ledgerTheme;
    final words = t.rowTitle.copyWith(
      leadingDistribution: TextLeadingDistribution.even,
    );
    // The overlay holds the list to the field's width, wider only as far as
    // its widest option (its rows' intrinsic width) needs.
    final glyphs = items.any((i) => i.icon != null);
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      includeSemantics: false,
      onKeyEvent: _typed,
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
              padding: const EdgeInsets.symmetric(vertical: LedgerSpacing.s4),
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
                    // The chosen option stands on the menu's paper, its words
                    // semibold and the green tick at its end, as a menu's
                    // chosen item does; a pointer or the keyboard marks the
                    // words alone ([LedgerOptionWords]), never the row.
                    LedgerPressable(
                      onTap: item.enabled ? () => onChosen(item.value) : null,
                      focusNode: _nodes[i],
                      label: item.label,
                      selected: item.value == value,
                      radius: 0,
                      rulesFocus: false,
                      child: Builder(
                        builder: (context) => Container(
                          height: t.density.height(_row),
                          color: item.value == value ? t.menuSelected : null,
                          padding: const EdgeInsets.symmetric(horizontal: _pad),
                          child: Row(
                            spacing: _gap,
                            children: [
                              if (item.icon case final g?)
                                Icon(g, size: _glyph, color: t.textSecondary)
                              else if (glyphs)
                                // The glyphs' column, kept on every row so
                                // every option's words start on one x.
                                const SizedBox(width: _glyph),
                              Expanded(
                                child: ledgerCapCenter(
                                  words,
                                  LedgerOptionWords(
                                    item.label,
                                    states: {
                                      ...LedgerPressStates.of(context),
                                      if (item.value == value)
                                        WidgetState.selected,
                                    },
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
}
