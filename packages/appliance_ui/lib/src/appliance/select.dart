/// Appliance's select: [ApplianceSelect], a key printed with its value and
/// an up-and-down legend, whose list rises on a faceplate under it: a row
/// of lamps down its start, the chosen option's lit.
library;

import 'dart:async' show scheduleMicrotask;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'internal/glyphs.dart';
import 'internal/keep_in_view.dart';
import 'internal/type_ahead.dart';
import 'material.dart';
import 'theme.dart';
import 'internal/field_frame.dart';

/// One choice in an [ApplianceSelect].
@immutable
class ApplianceSelectItem<T> {
  /// The choice [value], shown as [label].
  const ApplianceSelectItem({
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

/// A choice of one from a short list: a key printed with the chosen value
/// and a small up-and-down legend at its end, its [labelText] above and its
/// [helperText] or [errorText] below, as a field's.
///
/// Its list rises on a faceplate under the key, as wide as the key (wider
/// only as far as its longest option needs). Down the list's start runs a
/// column of lamps: the chosen option's is lit and its words stand in medium
/// weight. The one row the pointer or the keyboard is on sits down as a
/// pressed key, inset from the faceplate's edge by the same 4 px on every
/// side, its corners concentric with the faceplate's.
///
/// The lit row follows the pointer (`highlightFollowsPointer`), as in a
/// desktop's own menus, and the keys go on from wherever it is. Opened by a
/// press, the list lights no row until the pointer or a key moves; opened
/// from the keyboard (Enter, Space, Down or Up), it lights the chosen
/// option. A long list opens scrolled to the chosen option.
///
/// Up and Down move through the open list, round past the ends; Home and
/// End go to the ends; a typed letter goes to the next option starting with
/// it; Enter or Space chooses and closes; Escape closes. Either way the
/// keyboard comes back to the key.
///
/// Below 600 px it spans its column; wider, it stands at most
/// [maxWideWidth] at its column's start. A null [onChanged] disables it.
///
/// Reads [style]'s `fill`, `foreground`, `edge`, `padding`, `minimumSize`
/// (the key's height) and `textStyle` in its states, then
/// [ApplianceThemeData.selectStyle]'s; the open list reads
/// [ApplianceThemeData.menuStyle].
///
/// ```dart
/// ApplianceSelect<String>(labelText: 'Sort by', value: sort, items: const [ApplianceSelectItem(value: 'new', label: 'Newest'), ApplianceSelectItem(value: 'low', label: 'Price, low to high')], onChanged: (value) => setState(() => sort = value))
/// ```
class ApplianceSelect<T> extends StatefulWidget {
  /// A select over [items].
  const ApplianceSelect({
    super.key,
    required this.items,
    required this.value,
    required this.onChanged,
    this.labelText,
    this.semanticLabel,
    this.hintText,
    this.helperText,
    this.errorText,
    this.focusNode,
    this.style,
  });

  /// The choices.
  final List<ApplianceSelectItem<T>> items;

  /// The chosen value, or null for none (the [hintText] shows).
  final T? value;

  /// Called with the value chosen; null disables the select.
  final ValueChanged<T>? onChanged;

  /// The words over the key.
  final String? labelText;

  /// The select's name for a screen reader when [labelText] is not shown.
  final String? semanticLabel;

  /// What the key says while nothing is chosen.
  final String? hintText;

  /// Help under the key.
  final String? helperText;

  /// What is wrong, under the key beside a red lamp.
  final String? errorText;

  /// {@macro design.focusNode}
  final FocusNode? focusNode;

  /// The key's style, over [ApplianceThemeData.selectStyle].
  final ApplianceStyle? style;

  /// The widest a select stands from 600 px up; below, it spans its column.
  static const double maxWideWidth = 320;

  @override
  State<ApplianceSelect<T>> createState() => _ApplianceSelectState<T>();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<T>('value', value))
      ..add(IntProperty('items', items.length))
      ..add(StringProperty('labelText', labelText, defaultValue: null))
      ..add(StringProperty('errorText', errorText, defaultValue: null))
      ..add(
        FlagProperty('enabled', value: onChanged != null, ifFalse: 'disabled'),
      );
  }
}

class _ApplianceSelectState<T> extends State<ApplianceSelect<T>> {
  FocusNode? _ownFocus;

  FocusNode get _focus =>
      widget.focusNode ??
      (_ownFocus ??= FocusNode(debugLabel: 'ApplianceSelect'));

  // Whether the last thing to reach the key was a pointer (a press opens
  // the list with no row lit) or a key (the chosen row lit).
  bool _byPointer = false;

  @override
  void dispose() {
    _ownFocus?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ApplianceSelect(
      :items,
      :value,
      :onChanged,
      :labelText,
      :hintText,
      :helperText,
      :errorText,
      :style,
    ) = widget;
    final theme = ApplianceTheme.of(context);
    final c = theme.colors;
    final enabled = onChanged != null;
    final chosen = items.where((i) => i.value == value).firstOrNull;
    final height =
        RawStyleOf([style, theme.selectStyle], const {}).minimumSize?.height ??
        theme.controlHeight;

    Widget face(RawOverlayAnchor? anchor) {
      final open = anchor?.isOpen ?? false;
      return Listener(
        onPointerDown: (_) => _byPointer = true,
        child: RawButton(
          onPressed: anchor == null
              ? null
              : () {
                  final node = _focus;
                  if (anchor.isOpen || node.hasPrimaryFocus) {
                    anchor.toggle();
                    return;
                  }
                  // A press focuses the key first, as a click does a native
                  // select, and opens the list once the focus has landed: the
                  // list gives the keyboard back here when it closes.
                  node.requestFocus();
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
          // The field names the key (its label, or the semantic label).
          semanticValue: chosen?.label,
          excludeSemantics: true,
          builder: (context, states, _) {
            final layered = RawStyleOf(
              [style, theme.selectStyle],
              {...states, if (errorText != null) WidgetState.error},
            );
            final disabled = !enabled;
            final down = states.contains(WidgetState.pressed) || open;
            final base = disabled
                ? ApplianceFace.key(c).asDisabled(c)
                : down
                ? ApplianceFace.keyDown(c)
                : ApplianceFace.key(c);
            final ink = disabled ? c.printDisabled : c.print;
            final f = layered.on(
              base.copyWith(
                foreground: ink,
                edge: errorText != null ? c.danger : null,
                focus: states.contains(WidgetState.focused) && !open
                    ? (errorText != null ? c.danger : c.focus)
                    : c.focus.withValues(alpha: 0),
              ),
            );
            return TapTargetPadding(
              child: SizedBox(
                height: height,
                child: AnimatedApplianceSurface(
                  face: f,
                  child: Padding(
                    padding:
                        layered.padding(Directionality.of(context)) ??
                        const EdgeInsetsDirectional.only(
                          start: ApplianceSpacing.regular,
                          end: ApplianceSpacing.medium,
                        ),
                    child: Row(
                      children: [
                        Expanded(
                          child: RawCapCenter(
                            capHeightFactor: theme.capHeightFactor,
                            child: Text(
                              chosen?.label ?? hintText ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: layered.text(
                                theme.textTheme.body.copyWith(
                                  color: disabled
                                      ? c.printDisabled
                                      : chosen == null
                                      ? c.printMuted
                                      : f.foreground,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: ApplianceSpacing.small),
                        CustomPaint(
                          size: ApplianceUpDownPainter.size,
                          painter: ApplianceUpDownPainter(
                            disabled ? c.printDisabled : c.printMuted,
                          ),
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
        ? face(null)
        : RawPopover(
            arrowKeyNavigation: true,
            semanticLabel: widget.semanticLabel ?? labelText,
            placement: const RawPopoverPlacement(
              gap: ApplianceSpacing.tight + 2,
              margin: ApplianceSpacing.small,
            ),
            dampingRatio: ApplianceMotion.lid.dampingRatio,
            stiffness: ApplianceMotion.lid.stiffness,
            anchorBuilder: (context, anchor) => face(anchor),
            overlayBuilder: (context, info) => ApplianceMenuReveal(
              animation: info.animation,
              below: info.side != RawPopoverSide.above,
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
    final narrow = MediaQuery.sizeOf(context).width < 600;
    final field = applianceFieldFrame(
      labelText: labelText,
      semanticLabel: widget.semanticLabel,
      helperText: helperText,
      errorText: errorText,
      enabled: enabled,
      control: box,
    );
    if (narrow) return field;
    return Align(
      alignment: AlignmentDirectional.topStart,
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: ApplianceSelect.maxWideWidth,
        ),
        child: field,
      ),
    );
  }
}

/// An open list's reveal: it rises out of the panel toward the side it
/// opens on, from 92% of its height, and fades in over the first part of
/// the rise; it sinks back the same way. For a select's list and a menu.
///
/// ```dart
/// ApplianceMenuReveal(animation: info.animation, child: list)
/// ```
class ApplianceMenuReveal extends StatelessWidget {
  /// [child] revealed by [animation].
  const ApplianceMenuReveal({
    super.key,
    required this.animation,
    required this.child,
    this.below = true,
  });

  /// 0 closed, 1 open.
  final Animation<double> animation;

  /// Whether the list opens below its anchor (it grows from its top).
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
        opacity: (t / 0.4).clamp(0.0, 1.0),
        child: Transform(
          alignment: below ? Alignment.topCenter : Alignment.bottomCenter,
          transform: Matrix4.translationValues(0, (1 - t) * (below ? -4 : 4), 0)
            ..scaleByDouble(1, 0.92 + 0.08 * t, 1, 1),
          child: child,
        ),
      );
    },
  );
}

/// The faceplate an open list stands on: a raised lid with the menu's
/// corner, rows inset [ApplianceSpacing.tight] from its edge.
class ApplianceMenuPlate extends StatelessWidget {
  /// A faceplate holding [child].
  const ApplianceMenuPlate({
    super.key,
    required this.child,
    this.maxHeight,
    this.scroll = true,
  });

  /// The rows.
  final Widget child;

  /// The tallest it stands before its rows scroll.
  final double? maxHeight;

  /// Whether the plate scrolls its rows; false for a list that scrolls
  /// itself (a combobox's).
  final bool scroll;

  /// The plate's corner.
  static const double radius = ApplianceMetrics.troughRadius;

  /// A lit row's corner, concentric with the plate's.
  static const double rowRadius = radius - ApplianceSpacing.tight;

  @override
  Widget build(BuildContext context) {
    final theme = ApplianceTheme.of(context);
    final panel = RawStyleOf([theme.menuStyle], const {});
    final face = panel.on(
      ApplianceFace(
        top: theme.colors.keyTop,
        bottom: theme.colors.face,
        lift: 1,
        radius: BorderRadius.circular(radius),
        foreground: theme.colors.print,
      ),
    );
    final night = theme.colors.brightness == Brightness.dark;
    return Padding(
      // Room under the plate for its shade.
      padding: const EdgeInsets.only(bottom: ApplianceSpacing.tight),
      child: DecoratedBox(
        // A lid lifted off the panel casts a longer, softer shade than a key
        // seated in it; what the plate covers sinks into that shade.
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            // Close round its edge, where the corners lift off what they
            // cover,
            BoxShadow(
              color: theme.colors.shade.withValues(alpha: night ? 0.7 : 0.3),
              blurRadius: 4,
              spreadRadius: 1,
              offset: const Offset(0, 1),
            ),
            // and far and soft under it.
            BoxShadow(
              color: theme.colors.shade.withValues(alpha: night ? 0.5 : 0.18),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ApplianceSurface(
          face: face,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: maxHeight ?? double.infinity,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: scroll
                  ? SingleChildScrollView(
                      padding: const EdgeInsets.all(ApplianceSpacing.tight),
                      child: child,
                    )
                  : Padding(
                      padding: const EdgeInsets.all(ApplianceSpacing.tight),
                      child: child,
                    ),
            ),
          ),
        ),
      ),
    );
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

  final List<ApplianceSelectItem<T>> items;
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

  // While the list puts the keyboard on its first row, quietly.
  bool _quiet = true;

  @override
  void initState() {
    super.initState();
    applianceKeepInView(_nodes);
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
    final theme = ApplianceTheme.of(context);
    final c = theme.colors;
    final rowHeight = widget.rowHeight - ApplianceSpacing.tight;
    return ApplianceMenuPlate(
      maxHeight: widget.maxHeight,
      child: ApplianceTypeAhead(
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
                // The lit row follows the pointer, and the keys go on from it.
                onEnter: item.enabled
                    ? (_) {
                        if (_lit != i) setState(() => _lit = i);
                        _nodes[i].requestFocus();
                      }
                    : null,
                child: RawButton(
                  onPressed: item.enabled
                      ? () => widget.onChosen(item.value)
                      : null,
                  focusNode: _nodes[i],
                  selected: item.value == widget.value,
                  semanticSelected: item.value == widget.value,
                  semanticLabel: item.label,
                  excludeSemantics: true,
                  builder: (context, states, _) {
                    final row = RawStyleOf([theme.menuStyle], states);
                    final chosen = item.value == widget.value;
                    final lit =
                        item.enabled &&
                        (_lit == i || states.contains(WidgetState.pressed));
                    final words =
                        row.foreground ??
                        (item.enabled ? c.print : c.printDisabled);
                    final face = ApplianceFace(
                      top: lit
                          ? c.keyDownTop
                          : c.keyDownTop.withValues(alpha: 0),
                      bottom: lit
                          ? c.keyDownBottom
                          : c.keyDownBottom.withValues(alpha: 0),
                      lift: lit ? -0.6 : 0,
                      travel: lit ? 0.6 : 0,
                      radius: BorderRadius.circular(
                        ApplianceMenuPlate.rowRadius,
                      ),
                      foreground: words,
                    );
                    return SizedBox(
                      height: rowHeight,
                      child: AnimatedApplianceSurface(
                        control: false,
                        face: row.fill == null ? face : row.on(face),
                        child: Padding(
                          padding:
                              row.padding(Directionality.of(context)) ??
                              const EdgeInsets.symmetric(
                                horizontal: ApplianceSpacing.medium,
                              ),
                          child: Row(
                            children: [
                              Expanded(
                                child: RawCapCenter(
                                  capHeightFactor: theme.capHeightFactor,
                                  child: Text(
                                    item.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: row.text(
                                      theme.textTheme.body.copyWith(
                                        color: words,
                                        fontWeight: chosen
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: ApplianceSpacing.medium),
                              ApplianceLamp(lit: chosen),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
