import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart'
    show Icons, Material, MaterialType, TextField;
import 'package:ui_core/ui_core.dart';

import 'face.dart';
import 'theme.dart';

/// The face every field stands on: a text field, a select and a combobox
/// alike, so a reader sees one kind of field wherever a value is typed or
/// chosen. Its own rule darkens and thickens for focus and turns to the
/// danger tone for an error; no ring is added round it.
LookFace lookFieldFace(
  LookThemeData theme, {
  required bool focused,
  bool error = false,
  bool enabled = true,
}) {
  final c = theme.colors;
  return LookFace(
    fill: enabled ? c.surface : c.ground,
    rule: error
        ? c.danger
        : focused
        ? c.accent
        : c.rule,
    ruleWidth: focused || error ? 2 : 1,
    foreground: enabled ? c.ink : c.mutedInk,
  );
}

/// The sign at the end of a field that opens a list: a select's and a
/// combobox's are the same, so both read as fields that offer choices. It
/// turns over while the list shows.
class LookListSign extends StatelessWidget {
  /// The sign, in the face's foreground, turned over while [open].
  const LookListSign({super.key, this.open = false});

  /// Whether the field's list shows.
  final bool open;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: LookSpringBuilder(
      value: open ? 1 : 0,
      builder: (context, turn, sign) =>
          Transform.rotate(angle: turn * math.pi, child: sign),
      child: SizedBox.square(
        dimension: 20,
        child: CustomPaint(
          painter: _ChevronPainter(DefaultTextStyle.of(context).style.color),
        ),
      ),
    ),
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(FlagProperty('open', value: open, ifTrue: 'open'));
  }
}

/// The closed face of a field that opens a list or a month (a select, a date
/// field): the text field's face, [value] at its start and the list sign at
/// its end. Every such field stands on this one, so they match the text field
/// and each other.
class LookFieldTrigger extends StatelessWidget {
  /// A field showing [value].
  const LookFieldTrigger({
    super.key,
    required this.value,
    required this.open,
    required this.onPressed,
  });

  /// What the field holds, as shown and as a screen reader hears it; null:
  /// nothing yet.
  final String? value;

  /// Whether its list or month is open; the field shows focus meanwhile.
  final bool open;

  /// Opens or closes it; null turns the field off.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = LookTheme.of(context);
    return TapTargetPadding(
      child: RawButton(
        onPressed: onPressed,
        semanticValue: value,
        expanded: open,
        builder: (context, states, _) => AnimatedLookSurface(
          face: lookFieldFace(
            theme,
            focused: states.contains(WidgetState.focused) || open,
            enabled: onPressed != null,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(theme.radius),
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.only(start: 12, end: 8),
            child: DesignControlBox(
              minHeight: theme.density.height(theme.controlHeight),
              child: Row(
                children: [
                  Expanded(
                    child: DesignCapCenter(
                      capHeightFactor: theme.capHeightFactor,
                      child: Text(
                        value ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.body.copyWith(height: 1.2),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  LookListSign(open: open),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('value', value))
      ..add(FlagProperty('open', value: open, ifTrue: 'open'))
      ..add(
        ObjectFlagProperty<VoidCallback>(
          'onPressed',
          onPressed,
          ifNull: 'disabled',
        ),
      );
  }
}

class _ChevronPainter extends CustomPainter {
  const _ChevronPainter(this.color);

  final Color? color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    canvas.drawPath(
      Path()
        ..moveTo(c.dx - 5, c.dy - 2.5)
        ..lineTo(c.dx, c.dy + 2.5)
        ..lineTo(c.dx + 5, c.dy - 2.5),
      Paint()
        ..color = color ?? const Color(0xFF000000)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_ChevronPainter old) => old.color != color;
}

/// The panel an open list stands in: the field's own material (its fill,
/// its rule, its corner), opaque, so the list reads as the field's and the
/// page's words never show through it. Its rows are clipped to its corners,
/// so a chosen row's fill meets them.
class LookListSurface extends StatelessWidget {
  /// [child] in the panel.
  const LookListSurface({super.key, required this.child});

  /// The rows.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = LookTheme.of(context);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(theme.radius),
    );
    return LookSurface(
      face: lookFieldFace(theme, focused: false),
      shape: shape,
      child: ClipPath(
        clipper: ShapeBorderClipper(shape: shape),
        child: Padding(padding: const EdgeInsets.all(1), child: child),
      ),
    );
  }
}

/// One row of an open list, a menu's or a field's: the same row for a
/// select, a combobox and a menu, so a choice is marked one way across the
/// look.
///
/// The keys' highlight ([WidgetState.focused]) and the pointer's
/// ([WidgetState.hovered]) tint the whole row, edge to edge; the chosen
/// row ([WidgetState.selected]) carries a check at its end. Neither is
/// painted in the accent, which belongs to the screen's main action. A
/// destructive row (Delete) takes the danger tone.
Widget lookOptionRow(
  LookThemeData theme,
  Set<WidgetState> states,
  String label, {
  bool destructive = false,
}) {
  final c = theme.colors;
  final lit =
      states.contains(WidgetState.focused) ||
      states.contains(WidgetState.hovered);
  final ink = states.contains(WidgetState.disabled)
      ? c.mutedInk
      : destructive
      ? c.danger
      : c.ink;
  return AnimatedLookSurface(
    face: LookFace(
      fill: lit
          ? Color.alphaBlend(c.ink.withValues(alpha: .08), c.surface)
          : c.surface,
      rule: const Color(0x00000000),
      ruleWidth: 0,
      foreground: ink,
    ),
    shape: const RoundedRectangleBorder(),
    child: Padding(
      padding: const EdgeInsetsDirectional.only(start: 12, end: 8),
      child: DesignControlBox(
        minHeight: theme.density.height(theme.controlHeight),
        alignment: AlignmentDirectional.centerStart,
        child: Row(
          children: [
            Expanded(
              child: DesignCapCenter(
                capHeightFactor: theme.capHeightFactor,
                child: Text(
                  label,
                  style: theme.body.copyWith(color: ink, height: 1.2),
                ),
              ),
            ),
            SizedBox.square(
              dimension: 20,
              child: states.contains(WidgetState.selected)
                  ? CustomPaint(painter: _CheckPainter(ink))
                  : null,
            ),
          ],
        ),
      ),
    ),
  );
}

class _CheckPainter extends CustomPainter {
  const _CheckPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    canvas.drawPath(
      Path()
        ..moveTo(c.dx - 5, c.dy)
        ..lineTo(c.dx - 1.5, c.dy + 3.5)
        ..lineTo(c.dx + 5, c.dy - 4),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.75
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_CheckPainter old) => old.color != color;
}

/// The label above a field, in the look's label type.
Widget _fieldLabel(LookThemeData theme, Widget label) => DefaultTextStyle(
  style: theme.label.copyWith(color: theme.colors.ink),
  child: label,
);

/// The widest a select or a combobox grows when its parent lets it choose:
/// room for its label and its widest option, as Material's DropdownMenu
/// sizes to its widest entry. The field keeps one width as the choice
/// changes, and a select and a combobox offering one list are one width. A
/// form that sets its fields' width (a stretched column) still sets it.
double _choiceWidth(
  BuildContext context,
  LookThemeData theme,
  String label,
  Iterable<String> options,
) {
  double measure(String text, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final width = painter.width;
    painter.dispose();
    return width.ceilToDouble();
  }

  final entry = theme.body.copyWith(height: 1.2);
  final widest = options.fold(0.0, (w, o) => math.max(w, measure(o, entry)));
  // The face's insets (12 and 8), the gap (8) and the sign (20).
  return math.max(widest + 48, measure(label, theme.label));
}

/// Chooses one of [options] from a list that opens below the field: a
/// [RawPopover] round a [RawButton], on the same face and with the same
/// sign as [LookCombobox], so the two read as one kind of field.
///
/// ```dart
/// LookSelect<String>(labelText: 'Plan', options: const ['Day', 'Week'], value: plan, onChanged: (next) => plan = next)
/// ```
class LookSelect<T extends Object> extends StatelessWidget {
  /// A field labelled [labelText] offering [options].
  const LookSelect({
    super.key,
    required this.labelText,
    required this.options,
    required this.value,
    required this.onChanged,
    this.optionLabel = _words,
  });

  /// What the choice is for, above the field.
  final String labelText;

  /// What can be chosen.
  final List<T> options;

  /// The option chosen; null: none yet.
  final T? value;

  /// Called with the option chosen; null turns the field off.
  final ValueChanged<T>? onChanged;

  /// An option's words.
  final String Function(T option) optionLabel;

  @override
  Widget build(BuildContext context) {
    final theme = LookTheme.of(context);
    final chosen = value;
    final change = onChanged;
    final width = _choiceWidth(
      context,
      theme,
      labelText,
      options.map(optionLabel),
    );
    return RawInputDecorator(
      labelText: labelText,
      enabled: change != null,
      builder: (context, parts) => ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (parts.label != null) _fieldLabel(theme, parts.label!),
            const SizedBox(height: 6),
            parts.control,
          ],
        ),
      ),
      child: RawPopover(
        arrowKeyNavigation: true,
        semanticLabel: labelText,
        anchorBuilder: (context, anchor) => LookFieldTrigger(
          value: chosen == null ? null : optionLabel(chosen),
          open: anchor.isOpen,
          onPressed: change == null ? null : anchor.toggle,
        ),
        overlayBuilder: (context, info) => LookListSurface(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final option in options)
                  RawButton(
                    selected: option == chosen,
                    // The chosen option takes the focus as the list opens,
                    // from the keys or a pointer, and is kept in view.
                    autofocus: option == chosen,
                    onPressed: change == null
                        ? null
                        : () {
                            info.close();
                            if (option != chosen) change(option);
                          },
                    builder: (context, states, _) =>
                        lookOptionRow(theme, states, optionLabel(option)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('labelText', labelText))
      ..add(DiagnosticsProperty<T>('value', value, defaultValue: null));
  }
}

String _words(Object option) => '$option';

/// A field whose typing filters [options] in a list that opens below it:
/// ui_core's [RawCombobox], on the same face and with the same sign as
/// [LookSelect], its rows the same as the select's and the menu's.
///
/// ```dart
/// LookCombobox<String>(labelText: 'Assignee', options: const ['Ada', 'Grace'], value: who, onSelected: (next) => who = next)
/// ```
class LookCombobox<T extends Object> extends StatefulWidget {
  /// A field labelled [labelText] filtering [options].
  const LookCombobox({
    super.key,
    required this.labelText,
    required this.options,
    this.value,
    this.onSelected,
    this.optionLabel = _words,
    this.focusNode,
  });

  /// What the choice is for, above the field.
  final String labelText;

  /// What can be chosen.
  final List<T> options;

  /// The option chosen; null: none yet.
  final T? value;

  /// Called with the option chosen.
  final ValueChanged<T>? onSelected;

  /// An option's words: what typing matches.
  final String Function(T option) optionLabel;

  /// {@macro design.focusNode}
  final FocusNode? focusNode;

  @override
  State<LookCombobox<T>> createState() => _LookComboboxState<T>();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('labelText', labelText))
      ..add(DiagnosticsProperty<T>('value', value, defaultValue: null));
  }
}

class _LookComboboxState<T extends Object> extends State<LookCombobox<T>> {
  FocusNode? _ownFocusNode;

  FocusNode get _focusNode =>
      widget.focusNode ?? (_ownFocusNode ??= FocusNode());

  @override
  void didUpdateWidget(LookCombobox<T> old) {
    super.didUpdateWidget(old);
    if (widget.focusNode != null && _ownFocusNode != null) {
      _ownFocusNode!.dispose();
      _ownFocusNode = null;
    }
  }

  @override
  void dispose() {
    _ownFocusNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = LookTheme.of(context);
    final c = theme.colors;
    final entryStyle = theme.body.copyWith(height: 1.2);
    final width = _choiceWidth(
      context,
      theme,
      widget.labelText,
      widget.options.map(widget.optionLabel),
    );
    return RawInputDecorator(
      labelText: widget.labelText,
      focusNode: _focusNode,
      builder: (context, parts) => ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (parts.label != null)
              MouseRegion(
                cursor: SystemMouseCursors.text,
                child: _fieldLabel(theme, parts.label!),
              ),
            const SizedBox(height: 6),
            parts.control,
          ],
        ),
      ),
      child: RawCombobox<T>(
        options: widget.options,
        value: widget.value,
        onSelected: widget.onSelected,
        displayStringForOption: widget.optionLabel,
        focusNode: _focusNode,
        semanticLabel: widget.labelText,
        fieldBuilder: (context, field) {
          Widget entry = TextField(
            controller: field.controller,
            focusNode: field.focusNode,
            onEditingComplete: field.submit,
            decoration: null,
            style: entryStyle,
            cursorColor: c.accent,
          );
          if (Material.maybeOf(context) == null) {
            entry = Material(type: MaterialType.transparency, child: entry);
          }
          // The text input says whether its list shows, as the select's
          // button does: on the input itself, not round the whole field.
          entry = Semantics(expanded: field.isOpen, child: entry);
          return ListenableBuilder(
            listenable: field.focusNode,
            builder: (context, _) => MouseRegion(
              cursor: SystemMouseCursors.text,
              // The line's tap stays out of the semantics tree, so the
              // entry keeps one node as the list and its keys come and go.
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                excludeFromSemantics: true,
                onTap: field.focusNode.requestFocus,
                child: AnimatedLookSurface(
                  face: lookFieldFace(theme, focused: field.focusNode.hasFocus),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(theme.radius),
                  ),
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(
                      start: 12,
                      end: 8,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: DesignCapCenter(
                            capHeightFactor: theme.capHeightFactor,
                            child: DesignTextEntryBox(
                              minHeight: math.max(
                                theme.density.height(theme.controlHeight),
                                DesignTapTargets.of(context).floorOn().height,
                              ),
                              controller: field.controller,
                              child: entry,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        LookListSign(open: field.isOpen),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
        optionBuilder: (context, option, states) =>
            lookOptionRow(theme, states, widget.optionLabel(option)),
        surfaceBuilder: (context, list) => LookListSurface(child: list),
      ),
    );
  }
}

/// A menu of [entries] over [child], opened by a right click, a long press,
/// Shift+F10 or a screen reader's "Show menu": ui_core's [RawContextMenu],
/// its rows the look's list rows. An entry marked
/// [RawMenuEntry.isDestructiveAction] (Delete) takes the danger tone.
///
/// ```dart
/// LookMenu(entries: [RawMenuEntry(label: 'Delete', isDestructiveAction: true, onPressed: () {})], child: const Text('Draft'))
/// ```
class LookMenu extends StatelessWidget {
  /// A menu of [entries] over [child].
  const LookMenu({super.key, required this.entries, required this.child});

  /// The menu's rows.
  final List<RawMenuEntry> entries;

  /// The region that opens it.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = LookTheme.of(context);
    return RawContextMenu(
      menuChildren: entries,
      // A destructive row is set apart by its tone, not by anything it
      // does: it is pressed, reached and read as any other.
      itemBuilder: (context, entry, level, states) => lookOptionRow(
        theme,
        states,
        entry.label,
        destructive: entry.isDestructiveAction,
      ),
      surfaceBuilder: (context, info, items) => LookListSurface(
        child: IntrinsicWidth(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: items,
          ),
        ),
      ),
      child: child,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IterableProperty<RawMenuEntry>('entries', entries));
  }
}

/// A button that opens a menu of [entries] over itself, the menu's end
/// corner on the button's, as iOS's pull-down menus open: ui_core's
/// [RawPopover], placed by the look through [RawPopover.positionDelegate].
/// The popover keeps the rest: Escape and a tap outside close it, the keys
/// start on the first row, the focus goes back to the button, and the menu
/// is named.
///
/// ```dart
/// LookMoreMenu(semanticLabel: 'More', entries: [RawMenuEntry(label: 'Rename', onPressed: () {})])
/// ```
class LookMoreMenu extends StatelessWidget {
  /// A button named [semanticLabel] that opens [entries].
  const LookMoreMenu({
    super.key,
    required this.semanticLabel,
    required this.entries,
  });

  /// What a screen reader calls the button and its menu.
  final String semanticLabel;

  /// The menu's rows.
  final List<RawMenuEntry> entries;

  @override
  Widget build(BuildContext context) {
    final theme = LookTheme.of(context);
    return RawPopover(
      arrowKeyNavigation: true,
      semanticLabel: semanticLabel,
      // Over the button, the menu's end corner on the button's (its right
      // corner, or its left right to left), kept inside the room the
      // popover keeps to on its own.
      positionDelegate: (place) {
        final size = place.surfaceSize;
        final room = place.bounds;
        final x = place.textDirection == TextDirection.ltr
            ? place.anchorRect.right - size.width
            : place.anchorRect.left;
        return Offset(
          x.clamp(room.left, math.max(room.left, room.right - size.width)),
          place.anchorRect.top.clamp(
            room.top,
            math.max(room.top, room.bottom - size.height),
          ),
        );
      },
      anchorBuilder: (context, anchor) => TapTargetPadding(
        child: RawButton(
          onPressed: anchor.toggle,
          semanticLabel: semanticLabel,
          excludeSemantics: true,
          expanded: anchor.isOpen,
          builder: (context, states, _) => AnimatedLookSurface(
            face: lookFieldFace(
              theme,
              focused: states.contains(WidgetState.focused) || anchor.isOpen,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(theme.radius),
            ),
            child: SizedBox.square(
              dimension: theme.density.height(theme.controlHeight),
              child: Center(child: Text('…', style: theme.label)),
            ),
          ),
        ),
      ),
      overlayBuilder: (context, info) => LookListSurface(
        child: IntrinsicWidth(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final entry in entries)
                RawButton(
                  onPressed: entry.onPressed == null
                      ? null
                      : () {
                          info.close();
                          entry.onPressed!();
                        },
                  builder: (context, states, _) => lookOptionRow(
                    theme,
                    states,
                    entry.label,
                    destructive: entry.isDestructiveAction,
                  ),
                ),
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
      ..add(StringProperty('semanticLabel', semanticLabel))
      ..add(IterableProperty<RawMenuEntry>('entries', entries));
  }
}

/// A list the reader puts in their own order: ui_core's [RawReorderableList]
/// for the behaviour (a drag on the grip, or Alt with Up or Down on it, and
/// the move announced), each row the caller's with the look's grip at its
/// end.
///
/// ```dart
/// LookReorderableList<String>(items: const ['Milk', 'Eggs'], labelOf: (item) => item, onReorder: (from, to) {}, itemBuilder: (context, item) => Text(item))
/// ```
class LookReorderableList<T extends Object> extends StatelessWidget {
  /// [items] in their order, each row built by [itemBuilder].
  const LookReorderableList({
    super.key,
    required this.items,
    required this.labelOf,
    required this.onReorder,
    required this.itemBuilder,
  });

  /// The items, in their order.
  final List<T> items;

  /// What a screen reader calls an item, in the move it announces.
  final String Function(T item) labelOf;

  /// Called with an item's old index and its new one.
  final void Function(int from, int to) onReorder;

  /// An item's row, the grip aside.
  final Widget Function(BuildContext context, T item) itemBuilder;

  @override
  Widget build(BuildContext context) {
    final theme = LookTheme.of(context);
    return RawReorderableList<T>(
      items: items,
      labelOf: labelOf,
      onReorder: onReorder,
      shrinkWrap: true,
      itemBuilder: (context, item, reorder) => Row(
        children: [
          Expanded(child: itemBuilder(context, item)),
          // The grip paints from its states, as a button does: the look's
          // focus under the keyboard (where Alt with Up or Down moves the
          // row), a tint under a pointer and while it holds the row.
          reorder.buildHandle((context, states, _) => _lookGrip(theme, states)),
        ],
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('items', items.length));
  }
}

/// A reorderable row's grip: a rule round it under the keyboard (the
/// look's focus, as on every other stop), a tint under a pointer and a
/// deeper one while it holds the row.
Widget _lookGrip(LookThemeData theme, Set<WidgetState> states) {
  final c = theme.colors;
  return MouseRegion(
    cursor: SystemMouseCursors.grab,
    child: AnimatedLookSurface(
      face: LookFace(
        fill: states.contains(WidgetState.pressed)
            ? c.ink.withValues(alpha: .08)
            : states.contains(WidgetState.hovered)
            ? c.ink.withValues(alpha: .04)
            : const Color(0x00000000),
        rule: states.contains(WidgetState.focused)
            ? c.ink
            : const Color(0x00000000),
        ruleWidth: 2,
        foreground: c.mutedInk,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(theme.radius / 2),
      ),
      child: SizedBox.square(
        dimension: theme.density.height(theme.controlHeight),
        child: const Icon(Icons.drag_handle, size: 20),
      ),
    ),
  );
}
