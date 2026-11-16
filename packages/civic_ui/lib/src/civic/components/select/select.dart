import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../internal/field_frame.dart';
import '../../internal/list_option.dart';
import '../../internal/paint.dart';
import '../../internal/spring.dart';
import '../../theme.dart';

/// One choice of a [CivicSelect].
@immutable
class CivicSelectItem<T> {
  /// A choice saying [label].
  const CivicSelectItem({
    required this.value,
    required this.label,
    this.enabled = true,
  });

  /// What choosing it gives the select.
  final T value;

  /// Its words.
  final String label;

  /// Whether it can be chosen.
  final bool enabled;
}

/// One answer from a list too long for radios: the field's box with the
/// answer in it and a chevron, opening the list under it, floating on a
/// hairline and a soft shadow. The chosen row stands on the inset rule in the
/// action colour, bold and ticked; a pointer greys a row; the focused row
/// stands on the yellow plate. From 600 wide it keeps to 320 points: a
/// select is as wide as its answers.
///
/// The keys, as a platform's own select: Enter, Space or Down open the list
/// with the focus on the answer chosen (the first answer while none is),
/// and so does a press, so the arrows go on from there. Up and Down walk
/// the list, round from one end to the other; Home and End go to its ends;
/// a letter typed goes to the next answer starting with it (letters typed
/// quickly spell an answer's start). Enter or Space takes the answer and
/// closes the list, Escape closes it; either way the focus is back on the
/// field.
///
/// Prefer [CivicRadioGroup] for seven answers or fewer: radios show every
/// answer at once.
///
/// Reads [CivicStyle]'s fill, foreground and edge, by state: its `style:`,
/// then [CivicThemeData.selectStyle]. The list, the edge's width and the
/// focus ring are the look's.
///
/// ```dart
/// CivicSelect<String>(
///   labelText: 'Permit zone',
///   value: zone,
///   onChanged: (value) => setState(() => zone = value),
///   items: const [
///     CivicSelectItem(value: 'a', label: 'Zone A: Old Town'),
///     CivicSelectItem(value: 'b', label: 'Zone B: Harbourside'),
///   ],
/// )
/// ```
class CivicSelect<T> extends StatefulWidget {
  /// A select.
  const CivicSelect({
    super.key,
    required this.value,
    required this.onChanged,
    required this.items,
    this.labelText,
    this.helperText,
    this.errorText,
    this.hintText,
    this.focusNode,
    this.autofocus = false,
    this.style,
  });

  /// The answer chosen; null while none is.
  final T? value;

  /// Called with an answer as it is chosen; null disables the select.
  final ValueChanged<T>? onChanged;

  /// The answers.
  final List<CivicSelectItem<T>> items;

  /// What the select asks.
  final String? labelText;

  /// How to answer.
  final String? helperText;

  /// What to fix; null while the answer is fine.
  final String? errorText;

  /// Shown while nothing is chosen.
  final String? hintText;

  /// {@macro civic.focusNode}
  final FocusNode? focusNode;

  /// {@macro civic.autofocus}
  final bool autofocus;

  /// Overrides for this select's look.
  final CivicStyle? style;

  /// The widest a select stands from 600.
  static const double maxWidth = 320;

  @override
  State<CivicSelect<T>> createState() => _CivicSelectState<T>();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<T>('value', value, defaultValue: null))
      ..add(ObjectFlagProperty<ValueChanged<T>>.has('onChanged', onChanged))
      ..add(IterableProperty<CivicSelectItem<T>>('items', items))
      ..add(StringProperty('labelText', labelText, defaultValue: null))
      ..add(StringProperty('helperText', helperText, defaultValue: null))
      ..add(StringProperty('errorText', errorText, defaultValue: null))
      ..add(StringProperty('hintText', hintText, defaultValue: null))
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'))
      ..add(
        DiagnosticsProperty<CivicStyle>('style', style, defaultValue: null),
      );
  }
}

class _CivicSelectState<T> extends State<CivicSelect<T>> {
  FocusNode? _ownFocus;
  FocusNode get _focus => widget.focusNode ?? (_ownFocus ??= FocusNode());

  @override
  void dispose() {
    _ownFocus?.dispose();
    super.dispose();
  }

  CivicSelectItem<T>? get _chosen {
    for (final item in widget.items) {
      if (item.value == widget.value) return item;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final text = context.civicText;
    final enabled = widget.onChanged != null;
    final chosen = _chosen;
    final wide =
        (MediaQuery.maybeSizeOf(context)?.width ?? 0) >= CivicLayout.medium;
    final field = DesignField(
      labelText: widget.labelText,
      helperText: widget.helperText,
      errorText: widget.errorText,
      enabled: enabled,
      focusNode: _focus,
      builder: (context, parts) =>
          CivicFieldFrame(parts: parts, labelFocuses: true),
      child: DesignAnchoredOverlay(
        arrowKeyNavigation: true,
        semanticLabel: widget.labelText,
        placement: const DesignOverlayPlacement(
          gap: CivicSpacing.s8,
          preferredExtent: 240,
        ),
        // Down or Up on the field opens the list, as Enter and Space do.
        anchorBuilder: (context, anchor) => CallbackShortcuts(
          bindings: {
            for (final key in [
              LogicalKeyboardKey.arrowDown,
              LogicalKeyboardKey.arrowUp,
            ])
              SingleActivator(key): () {
                if (enabled && !anchor.isOpen) anchor.open();
              },
          },
          child: DesignPressable(
            onPressed: enabled ? anchor.toggle : null,
            focusNode: _focus,
            autofocus: widget.autofocus,
            isError: widget.errorText != null,
            expanded: anchor.isOpen,
            semanticValue: chosen?.label,
            mouseCursor: enabled
                ? SystemMouseCursors.click
                : SystemMouseCursors.basic,
            builder: (context, states, _) {
              final so = DesignStyleOf([widget.style, t.selectStyle], states);
              final disabled = states.contains(WidgetState.disabled);
              final ink =
                  so.foreground ?? (disabled ? t.textDisabled : t.textPrimary);
              final edge =
                  so.edge ??
                  (disabled
                      ? t.rule
                      : widget.errorText != null
                      ? t.danger
                      : t.border);
              // A keyboard focus rings it, and so does its open list.
              final ringed =
                  states.contains(WidgetState.focused) || anchor.isOpen;
              return CivicSpringValue(
                value: ringed ? 1 : 0,
                spring: CivicMotion.focus,
                effects: true,
                builder: (context, focus, _) => CustomPaint(
                  painter: CivicWellPainter(
                    fill: so.fill ?? (disabled ? t.disabledFill : t.background),
                    edgeColor: edge,
                    focus: focus,
                    focusColor: t.focus,
                    focusEdgeColor: t.border,
                  ),
                  child: SizedBox(
                    height: CivicMetrics.controlHeight,
                    child: Padding(
                      // The words stand where a text field's do, past the
                      // edge, so a form's answers line up down the page and
                      // the open list's words stand on them.
                      padding: const EdgeInsetsDirectional.only(
                        start: CivicMetrics.edge + CivicSpacing.s12,
                        end: CivicSpacing.s8,
                      ),
                      child: Row(
                        spacing: CivicSpacing.s8,
                        children: [
                          Expanded(
                            child: DesignCapCenter(
                              capHeightFactor: context.civicText.capHeight,
                              child: Text(
                                chosen?.label ?? widget.hintText ?? '',
                                maxLines: 1,
                                softWrap: false,
                                overflow: TextOverflow.ellipsis,
                                style: text.body.copyWith(
                                  color: chosen == null ? t.textSecondary : ink,
                                ),
                              ),
                            ),
                          ),
                          Icon(
                            anchor.isOpen
                                ? LucideIcons.chevronUp
                                : LucideIcons.chevronDown,
                            size: 24,
                            color: ink,
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
        // The overlay sizes the list from its first frame: the field's
        // width, wider only for its longest item, up to 320 (a field wider
        // than that keeps its own), so it starts where the field starts and
        // never spans the screen. A longer item wraps.
        overlayBuilder: (context, info) => FadeTransition(
          opacity: info.animation.drive(_unit),
          child: _CivicSelectList<T>(
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
    );
    if (!wide) return field;
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: CivicSelect.maxWidth),
        child: field,
      ),
    );
  }

  static final Animatable<double> _unit = Animatable<double>.fromCallback(
    (v) => v.clamp(0.0, 1.0),
  );
}

class _CivicSelectList<T> extends StatefulWidget {
  const _CivicSelectList({
    required this.items,
    required this.value,
    required this.maxHeight,
    required this.onChosen,
  });

  final List<CivicSelectItem<T>> items;
  final T? value;
  final double maxHeight;
  final ValueChanged<T> onChosen;

  @override
  State<_CivicSelectList<T>> createState() => _CivicSelectListState<T>();
}

class _CivicSelectListState<T> extends State<_CivicSelectList<T>> {
  final List<FocusNode> _nodes = [];

  // Letters typed within a second of each other spell an answer's start.
  String _typed = '';
  Timer? _typing;

  @override
  void initState() {
    super.initState();
    _sync();
    // The overlay gives its first row the focus once the list is up; the
    // answer chosen takes it straight after, in the same frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final items = widget.items;
      final chosen = items.indexWhere(
        (item) => item.enabled && item.value == widget.value,
      );
      final at = chosen >= 0 ? chosen : items.indexWhere((i) => i.enabled);
      if (at >= 0) _reach(at);
    });
  }

  @override
  void didUpdateWidget(_CivicSelectList<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  @override
  void dispose() {
    _typing?.cancel();
    for (final node in _nodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _sync() {
    while (_nodes.length < widget.items.length) {
      _nodes.add(FocusNode(debugLabel: 'CivicSelect answer'));
    }
    while (_nodes.length > widget.items.length) {
      _nodes.removeLast().dispose();
    }
  }

  void _reach(int i) {
    final node = _nodes[i];
    node.requestFocus();
    final at = node.context;
    if (at != null) Scrollable.ensureVisible(at, alignment: 0.5);
  }

  KeyEventResult _onKey(FocusNode _, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    final char = event.character;
    final keys = HardwareKeyboard.instance;
    if (char == null ||
        char.length != 1 ||
        char.codeUnitAt(0) <= 0x20 ||
        char.codeUnitAt(0) == 0x7f ||
        keys.isControlPressed ||
        keys.isMetaPressed ||
        keys.isAltPressed) {
      return KeyEventResult.ignored;
    }
    _typing?.cancel();
    _typing = Timer(const Duration(seconds: 1), () => _typed = '');
    final c = char.toLowerCase();
    _typed += c;
    // One letter again and again goes from one answer starting with it to
    // the next; letters that differ spell the start of one.
    final same = _typed.split('').every((x) => x == c);
    final start = same ? c : _typed;
    final items = widget.items;
    final current = _nodes.indexWhere((n) => n.hasFocus);
    final from = same || current < 0 ? current + 1 : current;
    for (var k = 0; k < items.length; k++) {
      final i = (from + k) % items.length;
      final item = items[i];
      if (item.enabled && item.label.toLowerCase().startsWith(start)) {
        _reach(i);
        break;
      }
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final items = widget.items;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: widget.maxHeight),
      child: DecoratedBox(
        // The list floats over the page: a card's face, a hairline round
        // it, a soft shadow; no ink edge.
        decoration: civicFloating(
          face: t.background,
          hairline: t.rule,
          dark: t.isDark,
        ),
        // The rows stand inside the hairline by as much as the field's words
        // stand inside its edge, so their words stand on the field's words.
        child: Padding(
          padding: const EdgeInsets.all(CivicMetrics.edge - 1),
          child: Focus(
            canRequestFocus: false,
            skipTraversal: true,
            includeSemantics: false,
            onKeyEvent: _onKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < items.length; i++)
                    DesignPressable(
                      focusNode: _nodes[i],
                      onPressed: items[i].enabled
                          ? () => widget.onChosen(items[i].value)
                          : null,
                      selected: items[i].value == widget.value,
                      semanticLabel: items[i].label,
                      semanticSelected: items[i].value == widget.value,
                      excludeSemantics: true,
                      mouseCursor: items[i].enabled
                          ? SystemMouseCursors.click
                          : SystemMouseCursors.basic,
                      builder: (context, states, _) => CivicListOption(
                        label: items[i].label,
                        chosen: items[i].value == widget.value,
                        hovered: states.contains(WidgetState.hovered),
                        pressed: states.contains(WidgetState.pressed),
                        focused: states.contains(WidgetState.focused),
                        enabled: items[i].enabled,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
