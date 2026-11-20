/// Keycap's select: an alpha key that shows its value and, pressed, lays a
/// panel of the choices over the keyboard. Its list is every open list's:
/// the one lit row a plate inset in the panel, the chosen row ticked.
library;

import 'dart:async' show scheduleMicrotask;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'cap.dart';
import 'internal/field_width.dart';
import 'internal/keep_in_view.dart';
import 'internal/spring_value.dart';
import 'internal/type_ahead.dart';
import 'text_field.dart';
import 'theme.dart';

/// One choice in a [KeycapSelect].
///
/// ```dart
/// const KeycapSelectItem(value: 'md', label: 'Markdown')
/// ```
@immutable
class KeycapSelectItem<T> {
  /// A choice.
  const KeycapSelectItem({
    required this.value,
    required this.label,
    this.enabled = true,
  });

  /// What choosing it gives.
  final T value;

  /// Its words.
  final String label;

  /// Whether it can be chosen.
  final bool enabled;
}

/// A select: an alpha key showing the chosen [value]'s words, a chevron at
/// its end. Pressed (or Down, Up, Space or Enter on it) it lays the
/// [items] over the keyboard, opened on the chosen one; from the keyboard
/// that row is lit, from a pointer none is until the pointer goes over one.
/// From 600 wide it stands at most [maxWideWidth] wide, as a field does,
/// but spans a column not much wider than that (a pane, a dialog).
///
/// ```dart
/// KeycapSelect<String>(label: 'Format', value: format, items: formats, onChanged: setFormat)
/// ```
class KeycapSelect<T> extends StatefulWidget {
  /// A select over [items].
  const KeycapSelect({
    super.key,
    required this.items,
    required this.value,
    required this.onChanged,
    this.label,
    this.semanticLabel,
    this.hint,
    this.helper,
    this.error,
    this.focusNode,
    this.style,
  });

  /// The choices.
  final List<KeycapSelectItem<T>> items;

  /// The chosen value; null shows [hint].
  final T? value;

  /// Called with a new choice; null turns the select off.
  final ValueChanged<T>? onChanged;

  /// The words over the select.
  final String? label;

  /// The select's name for a screen reader, when there is no [label].
  final String? semanticLabel;

  /// The words shown while nothing is chosen.
  final String? hint;

  /// Help under the select.
  final String? helper;

  /// What is wrong, under the select.
  final String? error;

  /// The key's focus node.
  final FocusNode? focusNode;

  /// Overrides for the key, over [KeycapThemeData.selectStyle].
  final KeycapStyle? style;

  /// The widest a select stands on a screen 600 or more wide.
  static const double maxWideWidth = 320;

  @override
  State<KeycapSelect<T>> createState() => _KeycapSelectState<T>();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<T>('value', value))
      ..add(IntProperty('items', items.length))
      ..add(StringProperty('label', label, defaultValue: null))
      ..add(StringProperty('error', error, defaultValue: null))
      ..add(
        FlagProperty('enabled', value: onChanged != null, ifFalse: 'disabled'),
      );
  }
}

class _KeycapSelectState<T> extends State<KeycapSelect<T>> {
  FocusNode? _ownFocus;

  FocusNode get _focus =>
      widget.focusNode ?? (_ownFocus ??= FocusNode(debugLabel: 'KeycapSelect'));

  // Whether the last thing to reach the key was a pointer (the list opens
  // with no row lit) or a key (the chosen row lit).
  bool _byPointer = false;

  @override
  void dispose() {
    _ownFocus?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final KeycapSelect(
      :items,
      :value,
      :onChanged,
      :label,
      :hint,
      :helper,
      :error,
      :style,
    ) = widget;
    final theme = KeycapTheme.of(context);
    final c = theme.colors;
    final enabled = onChanged != null;
    final chosen = items.where((i) => i.value == value).firstOrNull;
    final height = KeycapMetrics.grown(
      context,
      DesignStyleOf([style, theme.selectStyle], const {}).minimumSize?.height ??
          theme.controlHeight,
      theme.textTheme.body,
    );
    final walls = KeycapMetrics.walls(theme.controlHeight);

    Widget key(DesignOverlayAnchor? anchor) {
      final open = anchor?.isOpen ?? false;
      return Listener(
        onPointerDown: (_) => _byPointer = true,
        child: DesignPressable(
          onPressed: anchor == null
              ? null
              : () {
                  if (anchor.isOpen || _focus.hasPrimaryFocus) {
                    anchor.toggle();
                    return;
                  }
                  // A press focuses the key first, as a click does a native
                  // select, and opens the list once the focus has landed, so
                  // the list gives the keyboard back here when it closes.
                  _focus.requestFocus();
                  scheduleMicrotask(anchor.open);
                },
          onKeyEvent: anchor == null
              ? null
              : (node, event) {
                  if (event is KeyDownEvent) _byPointer = false;
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
          semanticLabel: widget.semanticLabel ?? label,
          semanticValue: chosen?.label,
          excludeSemantics: true,
          builder: (context, states, _) {
            final layered = DesignStyleOf(
              [style, theme.selectStyle],
              {...states, if (error != null) WidgetState.error},
            );
            var face = keycapKeyFace(theme, KeycapKind.alpha, {
              ...states,
              if (open) WidgetState.focused,
            });
            if (open && !states.contains(WidgetState.pressed)) {
              // Held down while its list is open, in its own plastic.
              face = face.copyWith(travel: keycapLatchTravel);
            }
            if (!states.contains(WidgetState.focused) || open) {
              face = face.copyWith(focus: c.focus.withValues(alpha: 0));
            }
            if (error != null && enabled) {
              face = face.copyWith(
                edge: c.dangerInk,
                focus: states.contains(WidgetState.focused) && !open
                    ? c.dangerInk
                    : null,
              );
            }
            face = layered.on(face);
            final words = !enabled
                ? c.inkDisabled
                : chosen == null
                ? c.inkMuted
                : face.legend;
            return DesignTapTarget(
              child: SizedBox(
                height: height,
                child: AnimatedKeycapCap(
                  face: face,
                  walls: walls,
                  child: Padding(
                    padding:
                        layered.padding(Directionality.of(context)) ??
                        EdgeInsetsDirectional.only(
                          start:
                              KeycapSpacing.medium +
                              theme.density.paddingDelta / 2,
                          end: KeycapSpacing.small + 2,
                        ),
                    child: Row(
                      children: [
                        Expanded(
                          child: DesignCapCenter(
                            capHeightFactor: theme.capHeightFactor,
                            child: Text(
                              chosen?.label ?? hint ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.body
                                  .merge(layered.textStyle)
                                  .copyWith(color: words),
                            ),
                          ),
                        ),
                        const SizedBox(width: KeycapSpacing.small),
                        Icon(
                          LucideIcons.chevronDown,
                          size: 18,
                          color: enabled ? c.inkMuted : c.inkDisabled,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    final Widget box = !enabled
        ? key(null)
        : DesignAnchoredOverlay(
            arrowKeyNavigation: true,
            semanticLabel: widget.semanticLabel ?? label,
            placement: const DesignOverlayPlacement(
              gap: KeycapSpacing.tight + 2,
              margin: KeycapSpacing.small,
            ),
            dampingRatio: KeycapMotion.panel.dampingRatio,
            stiffness: KeycapMotion.panel.stiffness,
            anchorBuilder: (context, anchor) => key(anchor),
            overlayBuilder: (context, info) => KeycapMenuReveal(
              animation: info.animation,
              below: info.side != DesignOverlaySide.above,
              child: _SelectList<T>(
                items: items,
                value: value,
                rowHeight: height,
                lightChosen: !_byPointer,
                maxHeight: info.maxSize.height,
                onChosen: (v) {
                  info.close();
                  onChanged(v);
                },
              ),
            ),
          );
    final field = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (label != null)
          ExcludeSemantics(child: KeycapFieldLabel(label, enabled: enabled)),
        box,
        KeycapFieldMessage(helper: helper, error: error),
      ],
    );
    return keycapFieldWidth(context, field, KeycapSelect.maxWideWidth);
  }
}

/// How an open list arrives over the keyboard: it fades in and settles the
/// last few pixels toward its key; it leaves the same way.
///
/// ```dart
/// KeycapMenuReveal(animation: info.animation, child: list)
/// ```
class KeycapMenuReveal extends StatelessWidget {
  /// Reveals [child] as [animation] runs.
  const KeycapMenuReveal({
    super.key,
    required this.animation,
    required this.child,
    this.below = true,
  });

  /// From 0 (gone) to 1 (laid down).
  final Animation<double> animation;

  /// Whether the list opens below its key (it settles upward to it).
  final bool below;

  /// The list.
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: animation,
    child: child,
    builder: (context, child) {
      final t = animation.value;
      return Opacity(
        opacity: (t / 0.45).clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, (1 - t) * (below ? -6 : 6)),
          child: child,
        ),
      );
    },
  );
}

/// The panel every open list stands on (a select's, a menu's): keycap
/// plastic over the keyboard, its rows inset by [KeycapSpacing.tight] so
/// the lit row's plate sits concentric with its corners.
///
/// ```dart
/// KeycapMenuPanel(child: Column(children: rows))
/// ```
class KeycapMenuPanel extends StatelessWidget {
  /// A panel round [child].
  const KeycapMenuPanel({
    super.key,
    required this.child,
    this.maxHeight,
    this.scroll = true,
  });

  /// The rows.
  final Widget child;

  /// The tallest the panel stands before its rows scroll.
  final double? maxHeight;

  /// Whether the rows scroll inside it.
  final bool scroll;

  /// The panel's corner.
  static const double radius = 12;

  /// A row's plate's corner: concentric with the panel's.
  static const double rowRadius = radius - KeycapSpacing.tight;

  @override
  Widget build(BuildContext context) {
    final theme = KeycapTheme.of(context);
    final style = DesignStyleOf([theme.menuStyle], const {});
    const pad = EdgeInsets.all(KeycapSpacing.tight);
    return Padding(
      // Room under the panel for its shadow.
      padding: const EdgeInsets.only(bottom: KeycapSpacing.small),
      child: KeycapPanel(
        radius: BorderRadius.circular(radius),
        color: style.fill,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight ?? double.infinity),
          child: scroll
              ? SingleChildScrollView(padding: pad, child: child)
              : Padding(padding: pad, child: child),
        ),
      ),
    );
  }
}

/// One row of an open list: its words on the panel, the [lit] row on a
/// plate of modifier plastic inset in it, the [chosen] row in medium weight
/// with a tick at its end.
///
/// ```dart
/// KeycapMenuRow(label: 'Markdown', height: 40, chosen: true)
/// ```
class KeycapMenuRow extends StatelessWidget {
  /// A row reading [label].
  const KeycapMenuRow({
    super.key,
    required this.label,
    required this.height,
    this.chosen = false,
    this.lit = false,
    this.enabled = true,
    this.leading,
    this.trailing,
    this.destructive = false,
    this.inset = KeycapSpacing.medium,
  });

  /// The row's words.
  final String label;

  /// The room at each end of the row, inside the panel's own inset: words
  /// in a list a field opens stand on the field's words, so a well's list
  /// (its words 12 in) takes less than a key's (whose words stand inside
  /// its walls).
  final double inset;

  /// The row's height.
  final double height;

  /// Whether it is the chosen one.
  final bool chosen;

  /// Whether it is the one lit row.
  final bool lit;

  /// Whether it can be chosen.
  final bool enabled;

  /// A glyph before the words.
  final Widget? leading;

  /// Something at the row's end, before the tick: a shortcut, a chevron to
  /// a submenu.
  final Widget? trailing;

  /// Whether choosing it destroys something.
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final theme = KeycapTheme.of(context);
    final c = theme.colors;
    final style = DesignStyleOf(
      [theme.menuStyle],
      {
        if (lit) WidgetState.hovered,
        if (chosen) WidgetState.selected,
        if (!enabled) WidgetState.disabled,
      },
    );
    final plate = Color.lerp(
      c.panel,
      c.modifier.top,
      c.brightness == Brightness.light ? 0.42 : 0.9,
    )!;
    final words =
        style.foreground ??
        (!enabled
            ? c.inkDisabled
            : destructive
            ? c.dangerInk
            : c.ink);
    return SizedBox(
      height: KeycapMetrics.grown(context, height, theme.textTheme.body),
      child: KeycapSpringColor(
        color: lit && enabled ? plate : plate.withValues(alpha: 0),
        darken: KeycapMotion.press,
        lighten: KeycapMotion.colour,
        builder: (context, color, child) => DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(KeycapMenuPanel.rowRadius),
          ),
          child: child,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: inset),
          child: Row(
            children: [
              if (leading != null) ...[
                IconTheme.merge(
                  data: IconThemeData(size: 18, color: words),
                  child: leading!,
                ),
                const SizedBox(width: KeycapSpacing.medium),
              ],
              Expanded(
                child: DesignCapCenter(
                  capHeightFactor: theme.capHeightFactor,
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.body
                        .merge(style.textStyle)
                        .copyWith(
                          color: words,
                          fontWeight: chosen
                              ? FontWeight.w500
                              : FontWeight.w400,
                        ),
                  ),
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: KeycapSpacing.medium),
                DefaultTextStyle(
                  style: theme.textTheme.figure.copyWith(
                    color: enabled ? c.inkMuted : c.inkDisabled,
                  ),
                  child: IconTheme.merge(
                    data: IconThemeData(size: 16, color: c.inkMuted),
                    child: trailing!,
                  ),
                ),
              ],
              if (chosen) ...[
                const SizedBox(width: KeycapSpacing.medium),
                Icon(LucideIcons.check, size: 18, color: words),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('label', label))
      ..add(FlagProperty('chosen', value: chosen, ifTrue: 'chosen'))
      ..add(FlagProperty('lit', value: lit, ifTrue: 'lit'));
  }
}

class _SelectList<T> extends StatefulWidget {
  const _SelectList({
    required this.items,
    required this.value,
    required this.rowHeight,
    required this.lightChosen,
    required this.maxHeight,
    required this.onChosen,
  });

  final List<KeycapSelectItem<T>> items;
  final T? value;
  final double rowHeight;
  final bool lightChosen;
  final double maxHeight;
  final ValueChanged<T> onChosen;

  @override
  State<_SelectList<T>> createState() => _SelectListState<T>();
}

class _SelectListState<T> extends State<_SelectList<T>> {
  late final List<FocusNode> _nodes = [
    for (final item in widget.items) FocusNode(debugLabel: item.label),
  ];

  // The one lit row: where the pointer or the keyboard last went.
  int? _lit;

  // While the list puts the keyboard on its chosen row, quietly.
  bool _quiet = true;

  @override
  void initState() {
    super.initState();
    keycapKeepInView(_nodes);
    for (final (i, node) in _nodes.indexed) {
      node.addListener(() {
        if (_quiet || !node.hasPrimaryFocus || _lit == i) return;
        setState(() => _lit = i);
      });
    }
    // The overlay puts the keyboard on the first row as the list opens; a
    // select's goes on to the chosen row (the first when none is), in view.
    // It is lit only when the keyboard opened the list.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final items = widget.items;
      var at = items.indexWhere((i) => i.enabled && i.value == widget.value);
      if (at < 0) at = items.indexWhere((i) => i.enabled);
      if (at < 0) {
        _quiet = false;
        return;
      }
      FocusTraversalPolicy.defaultTraversalRequestFocusCallback(_nodes[at]);
      scheduleMicrotask(() {
        if (!mounted) return;
        _quiet = false;
        if (widget.lightChosen) setState(() => _lit = at);
      });
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
    final items = widget.items;
    final rowHeight = widget.rowHeight - KeycapSpacing.tight;
    return KeycapMenuPanel(
      maxHeight: widget.maxHeight,
      child: KeycapTypeAhead(
        labels: [for (final item in items) item.label],
        nodes: [
          for (final (i, item) in items.indexed)
            item.enabled ? _nodes[i] : null,
        ],
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, item) in items.indexed)
              MouseRegion(
                // The lit row follows the pointer; the keys go on from it.
                onEnter: item.enabled
                    ? (_) {
                        if (_lit != i) setState(() => _lit = i);
                        _nodes[i].requestFocus();
                      }
                    : null,
                child: DesignPressable(
                  onPressed: item.enabled
                      ? () => widget.onChosen(item.value)
                      : null,
                  focusNode: _nodes[i],
                  selected: item.value == widget.value,
                  semanticSelected: item.value == widget.value,
                  semanticLabel: item.label,
                  excludeSemantics: true,
                  builder: (context, states, _) => KeycapMenuRow(
                    label: item.label,
                    height: rowHeight,
                    enabled: item.enabled,
                    chosen: item.value == widget.value,
                    lit:
                        item.enabled &&
                        (_lit == i || states.contains(WidgetState.pressed)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
