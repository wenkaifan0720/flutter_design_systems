/// Studio's select: [StudioSelect], a glass window showing the chosen
/// setting with a stepper glyph at its end, opening a list of the settings on
/// glass in which the chosen one's lamp is lit.
library;

import 'dart:async' show scheduleMicrotask;
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'internal/control_light.dart';
import 'internal/field_frame.dart';

import 'internal/list_keys.dart';
import 'internal/stepper_glyph.dart';
import 'surface.dart';
import 'theme.dart';

/// One setting a [StudioSelect] offers.
@immutable
class StudioSelectItem<T> {
  /// [value], shown as [label].
  const StudioSelectItem({
    required this.value,
    required this.label,
    this.enabled = true,
  });

  /// What choosing it sets.
  final T value;

  /// What it is called.
  final String label;

  /// Whether it can be chosen.
  final bool enabled;
}

/// A select: a glass window showing the chosen setting, a stepper glyph at
/// its end. A press, Down or Up opens the settings under it on glass, the
/// list opening on the chosen one (in view, however long the list); the
/// chosen setting's lamp is lit. Arrows move through the list, a letter goes
/// to the next setting it starts, Enter or Space chooses, Escape closes, and
/// the keyboard comes back to the window. The pointer's row is the
/// keyboard's: a pointer that moves over the list lights the row under it.
///
/// A null [onChanged] disables it. It stands as wide as a text field in the
/// same column.
///
/// Reads [style]'s `fill`, `foreground`, `padding`, `minimumSize` and
/// `textStyle`, then [StudioThemeData.selectStyle].
///
/// ```dart
/// StudioSelect<String>(labelText: 'Quality', value: q, items: const [StudioSelectItem(value: 'hi', label: 'High')], onChanged: (v) => setState(() => q = v))
/// ```
class StudioSelect<T> extends StatefulWidget {
  /// A select over [items], showing [value].
  const StudioSelect({
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

  /// The settings, in order.
  final List<StudioSelectItem<T>> items;

  /// The chosen setting's value; null for none.
  final T? value;

  /// Called with the value chosen; null disables the select.
  final ValueChanged<T>? onChanged;

  /// Its label, above it.
  final String? labelText;

  /// Shown while nothing is chosen.
  final String? hintText;

  /// A note under it.
  final String? helperText;

  /// What is wrong, under it.
  final String? errorText;

  /// {@macro design.focusNode}
  final FocusNode? focusNode;

  /// Its style, over [StudioThemeData.selectStyle].
  final StudioStyle? style;

  @override
  State<StudioSelect<T>> createState() => _StudioSelectState<T>();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<T>('value', value))
      ..add(StringProperty('label', labelText, defaultValue: null))
      ..add(IntProperty('items', items.length))
      ..add(
        FlagProperty('enabled', value: onChanged != null, ifFalse: 'disabled'),
      );
  }
}

class _StudioSelectState<T> extends State<StudioSelect<T>> {
  FocusNode? _ownFocus;

  FocusNode get _focus =>
      widget.focusNode ?? (_ownFocus ??= FocusNode(debugLabel: 'StudioSelect'));

  @override
  void dispose() {
    _ownFocus?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final StudioSelect(
      :items,
      :value,
      :onChanged,
      labelText: label,
      hintText: hint,
      helperText: helper,
      errorText: error,
      :style,
    ) = widget;
    final theme = StudioTheme.of(context);
    final c = theme.colors;
    final enabled = onChanged != null;
    final chosen = items.where((i) => i.value == value).firstOrNull;
    // As tall as a text field: the control height, or the chosen line at
    // the reader's text size where that is taller.
    final body = theme.textTheme.body;
    final height = math.max(
      RawStyleOf([style, theme.selectStyle], const {}).minimumSize?.height ??
          theme.controlHeight,
      MediaQuery.textScalerOf(context).scale(body.fontSize ?? 16) *
          (body.height ?? 1.5),
    );

    Widget window(RawOverlayAnchor? anchor) {
      final open = anchor?.isOpen ?? false;
      return RawButton(
        onPressed: anchor == null
            ? null
            : () {
                if (anchor.isOpen || _focus.hasPrimaryFocus) {
                  anchor.toggle();
                  return;
                }
                // Focus first, as a click does a native select, so the list
                // gives the keyboard back here when it closes.
                _focus.requestFocus();
                scheduleMicrotask(anchor.open);
              },
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
        // Named by its field, which reads the label on this node; a name of
        // its own would be read twice.
        semanticValue: chosen?.label,
        builder: (context, states, _) {
          final layered = RawStyleOf(
            [style, theme.selectStyle],
            {...states, if (error != null) WidgetState.error},
          );
          final words =
              layered.foreground ??
              (!enabled
                  ? c.onDisplayMuted
                  : chosen == null
                  ? c.onDisplayMuted
                  : c.onDisplay);
          final face = layered.on(
            c.displayFace.copyWith(
              radius: theme.radiusKey,
              fill: enabled ? null : Color.lerp(c.display, c.panelLow, 0.4),
              // The window's rim lights as it opens; half lit under a
              // finger, before it does.
              rim: error != null
                  ? c.danger
                  : open
                  ? c.indicator.withValues(alpha: 0.9)
                  : states.contains(WidgetState.pressed)
                  ? c.indicator.withValues(alpha: 0.45)
                  : c.indicator.withValues(alpha: 0),
              focus: states.contains(WidgetState.focused) && !open
                  ? c.focusRing
                  : c.focusRing.withValues(alpha: 0),
            ),
          );
          return SizedBox(
            height: height,
            child: AnimatedStudioSurface(
              face: face,
              stiffness: StudioMotion.lampStiffness,
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding:
                          layered.padding(Directionality.of(context)) ??
                          const EdgeInsetsDirectional.only(
                            start: StudioSpacing.medium + StudioSpacing.hair,
                          ),
                      child: RawCapCenter(
                        capHeightFactor: theme.capHeightFactor,
                        child: Text(
                          chosen?.label ?? hint ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: layered.text(
                            theme.textTheme.body.copyWith(color: words),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: height,
                    child: Center(
                      child: StudioStepperGlyph(
                        color: !enabled
                            ? c.disabled
                            : open
                            ? c.litLegend
                            : c.onDisplayMuted,
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

    // The window is one node, its press and its words: the field merges a
    // lone control with its label.
    final Widget box = !enabled
        ? MergeSemantics(child: window(null))
        : RawPopover(
            arrowKeyNavigation: true,
            // The list names itself by its options; the field is heard by
            // its label once, on the field.
            placement: const RawPopoverPlacement(
              gap: StudioSpacing.tight,
              margin: StudioSpacing.small,
            ),
            dampingRatio: StudioMotion.dampingRatio,
            stiffness: StudioMotion.overlayStiffness,
            anchorBuilder: (context, anchor) =>
                MergeSemantics(child: window(anchor)),
            overlayBuilder: (context, info) => FadeTransition(
              opacity: info.animation,
              child: StudioMenuList<T>(
                items: [
                  for (final i in items)
                    StudioMenuEntry(
                      value: i.value,
                      label: i.label,
                      enabled: i.enabled,
                    ),
                ],
                value: value,
                rowHeight: height,
                onChosen: (v) {
                  info.close();
                  onChanged(v);
                },
              ),
            ),
          );
    return StudioFieldFrame(
      labelText: label,
      helperText: helper,
      errorText: error,
      enabled: enabled,
      child: box,
    );
  }
}

/// One row of a [StudioMenuList].
@immutable
class StudioMenuEntry<T> {
  /// [value], shown as [label].
  const StudioMenuEntry({
    required this.value,
    required this.label,
    this.enabled = true,
    this.icon,
    this.shortcut,
    this.isDestructiveAction = false,
  });

  /// What choosing it gives.
  final T value;

  /// What it says.
  final String label;

  /// Whether it can be chosen.
  final bool enabled;

  /// A glyph before its words.
  final Widget? icon;

  /// The keys that do it too, printed at its end (`⌘ S`).
  final String? shortcut;

  /// Whether it destroys something: its words in the danger colour.
  final bool isDestructiveAction;
}

/// The list an open select or menu shows: rows on glass in a raised bezel,
/// each row inset 4 px from the bezel so its corners are concentric with it.
/// The chosen row's lamp is lit; the keyboard's row, and the pointer's once
/// it moves, lights its legend. Opened, the keyboard goes to the chosen
/// row (else the first), scrolled into view; a pointer that opened it lights
/// no row until it moves.
///
/// ```dart
/// StudioMenuList<int>(items: const [StudioMenuEntry(value: 1, label: 'One')], value: 1, onChosen: print)
/// ```
class StudioMenuList<T> extends StatefulWidget {
  /// A list of [items], [value] chosen.
  const StudioMenuList({
    super.key,
    required this.items,
    required this.onChosen,
    this.value,
    this.rowHeight,
    this.showLamps = true,
  });

  /// The rows.
  final List<StudioMenuEntry<T>> items;

  /// The chosen row's value, if any.
  final T? value;

  /// A row's height; the theme's control height when null.
  final double? rowHeight;

  /// Called with a row's value when it is chosen.
  final ValueChanged<T> onChosen;

  /// Whether rows keep a lamp's room at their start (a select's list does;
  /// a menu of actions does not).
  final bool showLamps;

  @override
  State<StudioMenuList<T>> createState() => _StudioMenuListState<T>();
}

class _StudioMenuListState<T> extends State<StudioMenuList<T>> {
  late final List<FocusNode> _nodes = [
    for (final item in widget.items) FocusNode(debugLabel: item.label),
  ];

  bool _pointer = false;

  // The row the keys start on, from the list's first frame: the chosen one,
  // else the first that takes a press.
  late final int _first = () {
    final items = widget.items;
    final at = items.indexWhere((i) => i.enabled && i.value == widget.value);
    return at >= 0 ? at : items.indexWhere((i) => i.enabled);
  }();

  @override
  void initState() {
    super.initState();
    studioKeepInView(_nodes);
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
    final theme = StudioTheme.of(context);
    final items = widget.items;
    final rowHeight = widget.rowHeight ?? theme.controlHeight;
    const inset = StudioMetrics.recessInset;
    return StudioListBezel(
      padding: EdgeInsets.zero,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: rowHeight * 6.5 + inset * 2),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(inset),
          child: StudioTypeAhead(
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
                    onHover: item.enabled
                        ? (_) {
                            if (!_nodes[i].hasPrimaryFocus) {
                              _nodes[i].requestFocus();
                            }
                            if (!_pointer) setState(() => _pointer = true);
                          }
                        : null,
                    child: _row(i, item, rowHeight),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(int i, StudioMenuEntry<T> item, double rowHeight) {
    final isChosen = item.value == widget.value && widget.value != null;
    return RawButton(
      onPressed: item.enabled ? () => widget.onChosen(item.value) : null,
      focusNode: _nodes[i],
      autofocus: i == _first,
      selected: isChosen,
      semanticSelected: widget.showLamps ? isChosen : null,
      semanticLabel: item.label,
      builder: (context, states, _) => StudioMenuRow(
        label: item.label,
        icon: item.icon,
        trailing: item.shortcut == null ? null : Text(item.shortcut!),
        states: states,
        highlighted:
            states.contains(WidgetState.focused) ||
            (_pointer && (Focus.maybeOf(context)?.hasPrimaryFocus ?? false)),
        chosen: isChosen,
        showLamp: widget.showLamps,
        isDestructiveAction: item.isDestructiveAction,
        height: rowHeight,
      ),
    );
  }
}

/// The bezel an open list stands in: glass framed by a 2 px metal rim, with
/// a soft shadow under it, clipped to its corners; [child] inset [padding]
/// in the glass (4 px, the slots' inset, by default) so a row's slot is
/// concentric with it.
///
/// By day the rim is the bars' anodised tone and the shadow parts the list
/// from the pale panel under it. By night the rim is the caps' brushed
/// aluminium with a lit top edge, so a list over a field's black glass or a
/// pane still reads as a plate above it: the rim stands at least 3:1 from
/// the glass on both sides of it.
///
/// Every open list draws on it: a select's, a combobox's, a tag input's,
/// a date picker's calendar, a menu's, the menu bar's and the command
/// palette's.
///
/// ```dart
/// StudioListBezel(child: Column(children: rows))
/// ```
class StudioListBezel extends StatelessWidget {
  /// A bezel round [child].
  const StudioListBezel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(StudioMetrics.recessInset),
  });

  /// The list.
  final Widget child;

  /// Room between the bezel and the list.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final c = StudioTheme.of(context).colors;
    final night = c.brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          StudioTheme.of(context).radiusBank + _bezelRim,
        ),
        boxShadow: [
          BoxShadow(
            color: c.shadow.withValues(alpha: night ? 0.55 : 0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: CustomPaint(
        // By night the rim is laid over the glass's edge, so the glass's own
        // contact shadow can't darken it; by day that shadow shades the rim's
        // lower edge, as it always has.
        painter: night
            ? null
            : _BezelRimPainter(c, StudioTheme.of(context).radiusBank),
        foregroundPainter: night
            ? _BezelRimPainter(
                c,
                StudioTheme.of(context).radiusBank,
                over: true,
              )
            : null,
        child: Padding(
          padding: const EdgeInsets.all(_bezelRim),
          child: StudioSurface(
            face: StudioFace(
              fill: c.display,
              fillLow: c.displayLow,
              depth: StudioDepth.level,
              radius: StudioTheme.of(context).radiusBank,
              foreground: c.onDisplay,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                StudioTheme.of(context).radiusBank,
              ),
              child: Padding(padding: padding, child: child),
            ),
          ),
        ),
      ),
    );
  }
}

// How wide the bezel's metal rim is.
const double _bezelRim = 2;

// The light the bezel's top edge catches by night: brighter than the panels'
// faint edge, as bare aluminium catches more of the room's light than
// graphite does.
const Color _nightEdgeLight = Color(0x59FFFFFF);

// The bezel's metal rim, framing the glass, its top edge catching the light,
// so an open list stands apart from any glass under it. By day it is the
// bars' anodised tone, and the list's shadow on the pale panel parts it from
// what lies under it. By night a field's glass is as black as the list's and
// no shadow reads on it, so the rim is the caps' brushed aluminium, lit from
// above: falling from the caps' tone to halfway to their lower tone, it
// stands at least 3:1 from the glass on both sides of it, all round, and its
// top edge catches the room's light.
class _BezelRimPainter extends CustomPainter {
  _BezelRimPainter(this.colors, this.radius, {this.over = false});

  final StudioColors colors;

  // The glass's corners, the theme's bank.
  final double radius;

  // Whether the rim is laid over the glass's edge rather than under it.
  final bool over;

  @override
  void paint(Canvas canvas, Size size) {
    final night = colors.brightness == Brightness.dark;
    final outline = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius + _bezelRim),
    );
    final metal = Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(0, size.height),
        night
            ? [colors.cap, Color.lerp(colors.cap, colors.capLow, 0.5)!]
            : [colors.bar, colors.barLow],
      );
    if (over) {
      // Laid over the glass: only the ring round it.
      canvas.drawDRRect(outline, outline.deflate(_bezelRim), metal);
    } else {
      // Under the glass: the whole plate, the glass painting the middle.
      canvas.drawRRect(outline, metal);
    }
    // The top edge catches the light: the crescent between the outline and
    // the outline a pixel lower.
    canvas.save();
    canvas.clipRRect(outline);
    canvas.drawPath(
      Path()
        ..fillType = PathFillType.evenOdd
        ..addRRect(outline)
        ..addRRect(outline.shift(const Offset(0, 1))),
      Paint()..color = night ? _nightEdgeLight : colors.edgeLight,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BezelRimPainter old) =>
      old.colors != colors || old.over != over || old.radius != radius;
}

/// A row in an open list. Keyboard focus and hover illuminate its legend.
/// Holding the row depresses its slot. A [chosen] row has a lit lamp and
/// heavier text. Disabled and destructive rows use their own legend colours.
///
/// A list's own behaviour (keys, focus, a press) is the caller's; this is
/// the paint every Studio list shares.
///
/// ```dart
/// StudioMenuRow(label: 'High', states: states, chosen: true, showLamp: true)
/// ```
class StudioMenuRow extends StatelessWidget {
  /// A row reading [label].
  const StudioMenuRow({
    super.key,
    required this.label,
    this.states = const <WidgetState>{},
    this.highlighted,
    this.chosen,
    this.showLamp = false,
    this.icon,
    this.trailing,
    this.isDestructiveAction = false,
    this.height,
  });

  /// Its words.
  final String label;

  /// Its states: focused (the keyboard's row), hovered, pressed, selected,
  /// disabled.
  final Set<WidgetState> states;

  /// Whether the command legend is lit. By default focus or hover lights it.
  final bool? highlighted;

  /// Whether it is the list's value; by default when [states] has selected.
  final bool? chosen;

  /// Whether it keeps a lamp at its end (a list that holds a value does).
  final bool showLamp;

  /// A glyph before its words.
  final Widget? icon;

  /// Something at its end: a shortcut, a count.
  final Widget? trailing;

  /// Whether it destroys something.
  final bool isDestructiveAction;

  /// Its height; the theme's control height when null.
  final double? height;

  @override
  Widget build(BuildContext context) {
    final theme = StudioTheme.of(context);
    final c = theme.colors;
    final disabled = states.contains(WidgetState.disabled);
    final cue = highlighted == false || disabled
        ? 0.0
        : highlighted == true && !states.contains(WidgetState.hovered)
        ? 0.72
        : studioControlLight(states);
    final pressed = states.contains(WidgetState.pressed);
    final isChosen = chosen ?? states.contains(WidgetState.selected);
    final words = disabled
        ? c.disabled
        : isDestructiveAction
        ? c.dangerLegend
        : Color.lerp(c.onDisplay, c.litLegend, cue)!;
    final slot = StudioFace(
      fill: Color.lerp(c.displayLow, c.shadow, 0.06)!,
      fillLow: Color.lerp(c.display, c.shadow, 0.03)!,
      depth: StudioDepth.sunk,
      radius: theme.radiusBank - StudioMetrics.recessInset,
      foreground: words,
      presence: pressed && !disabled ? 1 : 0,
    );
    return SizedBox(
      height: height ?? theme.controlHeight,
      child: AnimatedStudioSurface(
        face: slot,
        stiffness: StudioMotion.lampStiffness,
        // A row's words stand on the field's words (the list hangs from the
        // field's edge, inside its bezel); the lamp at the end.
        child: Padding(
          padding: const EdgeInsetsDirectional.only(
            start:
                StudioSpacing.medium +
                StudioSpacing.hair -
                StudioMetrics.recessInset,
            end: StudioSpacing.medium,
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                IconTheme.merge(
                  data: IconThemeData(
                    size: StudioIconSizes.regular,
                    color: words,
                  ),
                  child: icon!,
                ),
                const SizedBox(width: StudioSpacing.medium),
              ],
              Expanded(
                child: RawCapCenter(
                  capHeightFactor: theme.capHeightFactor,
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.body.copyWith(
                      color: words,
                      fontWeight: isChosen ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: StudioSpacing.medium),
                DefaultTextStyle.merge(
                  style: theme.textTheme.secondary.copyWith(
                    color: disabled ? c.disabled : c.onDisplayMuted,
                  ),
                  child: trailing!,
                ),
              ],
              if (showLamp) ...[
                const SizedBox(width: StudioSpacing.medium),
                StudioControlLamp(on: isChosen && !disabled, states: states),
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
      ..add(DiagnosticsProperty<bool>('chosen', chosen, defaultValue: null));
  }
}
