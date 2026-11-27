import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart'
    show Material, MaterialLocalizations, MaterialType;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../glyphs.dart';

import '../../chrome_metrics.dart';
import '../../internal/face.dart';
import '../../internal/menu_wake.dart';
import '../../internal/styled.dart';
import '../../internal/chosen_plate.dart';
import '../../theme.dart';
import '../host.dart';
import '../pressable/pressable.dart';
import '../../internal/dim.dart';
import '../../internal/cap.dart';

/// One choice in a sheet its options: an optional [hue] swatch (a category's
/// light) or [lead] mark, the [label] in the body type, a quiet [trailing] note
/// (an amount), and at the end the round check, 24 across: a ring while
/// unchosen, and when [selected] the same ring round a little clearer glass
/// with its tick printed in the ink, the chosen one's label semibold. At least
/// 52 tall, 6 over and under, its parts 12 apart, a hairline between two. A
/// null [onPressed] leaves it inert.
///
/// ```dart
/// FrostedOption(label: 'Dining out', hue: t.hue(2).a, selected: true, onPressed: () => Navigator.of(context).pop('dining'))
/// ```
class FrostedOption extends StatelessWidget {
  /// Creates a [FrostedOption].
  const FrostedOption({
    required this.label,
    required this.onPressed,
    this.hue,
    this.lead,
    this.trailing,
    this.selected = false,
    this.style,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  /// The choice's name.
  final String label;

  /// What choosing it does.
  final VoidCallback? onPressed;

  /// {@macro frosted.focusNode}
  final FocusNode? focusNode;

  /// {@macro frosted.autofocus}
  final bool autofocus;

  /// The light of the swatch before the name.
  final Color? hue;

  /// A mark before the name in place of the swatch (a category's token).
  final Widget? lead;

  /// The quiet note at the end (an amount: `FrostedAmount(v, quiet: true)`).
  final Widget? trailing;

  /// Whether it is the chosen one.
  final bool selected;

  /// This option's own style, over `FrostedThemeData.components.option`:
  /// the check's fill (selected when chosen), its tick (foreground) and its
  /// ring at rest (edge), the words' style and the row's padding.
  ///
  /// ```dart
  /// FrostedOption(
  ///   label: 'Weekly',
  ///   selected: true,
  ///   onPressed: pick,
  ///   style: const FrostedStyle(
  ///     fill: WidgetStatePropertyAll(Color(0xFF2F7D5B)),
  ///   ),
  /// )
  /// ```
  final FrostedStyle? style;

  @override
  Widget build(BuildContext context) {
    final option = _option(context);
    return FrostedDim(off: onPressed == null, child: option);
  }

  Widget _option(BuildContext context) {
    final t = context.frostedTheme;
    final swatch = hue;
    const check = FrostedChromeMetrics.optionCheck;
    final s = FrostedStyleLayers(style, t.components.option, {
      if (selected) WidgetState.selected,
      if (onPressed == null) WidgetState.disabled,
    });
    final fill = s.fill;
    return FrostedPressable(
      focusNode: focusNode,
      autofocus: autofocus,
      onPressed: onPressed,
      semanticLabel: label,
      selected: selected,
      radius: FrostedCorners.r10,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: FrostedChromeMetrics.option,
        ),
        child: Padding(
          padding:
              s.padding ??
              const EdgeInsetsDirectional.fromSTEB(
                0,
                FrostedChromeMetrics.optionInset,
                FrostedChromeMetrics.optionInsetEnd,
                FrostedChromeMetrics.optionInset,
              ),
          child: Row(
            spacing: FrostedChromeMetrics.optionGap,
            children: [
              if (lead != null)
                lead!
              else if (swatch != null)
                FrostedHueDot(swatch),
              Expanded(
                child: frostedCapCentred(
                  Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: s.words(
                      selected
                          ? t.textTheme.titleMedium.semibold
                          : t.textTheme.titleMedium,
                    ),
                  ),
                ),
              ),
              if (trailing != null)
                DefaultTextStyle.merge(
                  style: TextStyle(color: t.colorScheme.textSecondary),
                  child: trailing!,
                ),
              SizedBox.square(
                dimension: check,
                // The check is a small bead of glass in a field's language:
                // a well a step deeper than the menu's glass, its rim the lit
                // hairline by day and the night glass's rim by night, never a
                // dark line. Chosen, it takes a little more frost and its tick
                // is printed in the ink, never a fill of ink.
                child: FrostedFace(
                  material: fill == null
                      ? FrostedMaterial.well
                      : FrostedMaterial.paint,
                  radius: BorderRadius.circular(check / 2),
                  color: fill,
                  wash: selected ? t.glass.wash : null,
                  ring: s.edge ?? frostedLitEdge(t, t.controlEdge),
                  child: selected
                      ? Center(
                          child: Icon(
                            FrostedGlyphs.check,
                            size: FrostedChromeMetrics.optionCheckGlyph,
                            color: s.foreground ?? t.colorScheme.textPrimary,
                          ),
                        )
                      : null,
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
      ..add(StringProperty('label', label))
      ..add(ObjectFlagProperty<VoidCallback>.has('onPressed', onPressed))
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'))
      ..add(ColorProperty('hue', hue, defaultValue: null))
      ..add(FlagProperty('selected', value: selected, ifTrue: 'selected'))
      ..add(
        DiagnosticsProperty<FrostedStyle>('style', style, defaultValue: null),
      );
  }
}

/// A category's light as a swatch: 8 across in its [color].
///
/// ```dart
/// FrostedHueDot(t.hue(0).a)
/// ```
class FrostedHueDot extends StatelessWidget {
  /// Creates a [FrostedHueDot].
  const FrostedHueDot(this.color, {super.key});

  /// The dot's colour.
  final Color color;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox.square(
      dimension: FrostedChromeMetrics.swatch,
      child: DecoratedBox(
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    ),
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ColorProperty('color', color));
  }
}

/// One choice of a [FrostedMenu]: its [value], its [label], an optional
/// [hue] swatch and quiet [trailing] note, the check when [checked], whether
/// it can be chosen ([enabled]; a disabled one stands faded and inert),
/// whether it is a loss ([isDestructiveAction], its words in the over ink, as the
/// action sheet sets one), and the walkthrough [key] set on its row.
@immutable
class FrostedMenuItem<T> {
  /// Creates a [FrostedMenuItem].
  const FrostedMenuItem(
    this.value,
    this.label, {
    this.hue,
    this.trailing,
    this.checked = false,
    this.enabled = true,
    this.isDestructiveAction = false,
    this.key,
  });

  /// What choosing it hands back.
  final T value;

  /// The item's words.
  final String label;

  /// A dot of this colour before the words.
  final Color? hue;

  /// What stands at the item's end.
  final Widget? trailing;

  /// Whether it carries the check.
  final bool checked;

  /// Whether it can be chosen.
  final bool enabled;

  /// Whether choosing it loses something (Delete): its words stand in the
  /// over ink.
  final bool isDestructiveAction;

  /// The walkthrough key set on its row.
  final Key? key;
}

/// A menu dropping from the control that opened it: a white card 288 wide, 6 inside, its corners at 16, a hairline round
/// it and a deep soft shadow, its [title] in the caption type over the [items]:
/// each a row 40 tall with its corners at 10, the check's column 16 wide before
/// the label, the chosen one on the wash with its label in the ink. It stands 8
/// under the control, centred on it on a phone and with its end on the
/// control's end at desktop width, and drops no scrim. [show] opens it and
/// completes with the chosen value, or null when it is dismissed (a tap
/// outside, the system back).
///
/// ```dart
/// Builder(builder: (anchor) => FrostedButton.glass('October 2026', onPressed: () async { final month = await FrostedMenu.show<String>(anchor, title: 'Spent each month', items: months); }))
/// ```
class FrostedMenu<T> extends StatelessWidget {
  /// Creates a [FrostedMenu].
  const FrostedMenu({
    required this.items,
    required this.onSelected,
    this.title,
    this.semanticLabel,
    this.width,
    super.key,
  }) : _rows = null,
       _place = null,
       _focused = null;

  // A menu [show] raises: its rows take these focus nodes, which its keys
  // move between (_MenuKeys).
  const FrostedMenu._keyed(
    this._rows,
    this._place,
    this._focused, {
    required this.items,
    required this.onSelected,
    this.title,
    this.semanticLabel,
    this.width,
  });

  final List<FocusNode>? _rows;

  // The row that takes the focus as it mounts: the chosen one, when keys
  // opened the menu (_MenuKeys).
  final int? _focused;

  // The one row a menu [show] raises lights: where the keys or the pointer
  // last went (_MenuKeys).
  final _MenuPlace? _place;

  /// The items, in order.
  final List<FrostedMenuItem<T>> items;

  /// The menu's width; null keeps Frosted's 288.
  final double? width;

  /// Called with the chosen item's value.
  final ValueChanged<T> onSelected;

  /// The caption over the items.
  final String? title;

  /// What a screen reader calls the menu; null says the [title].
  final String? semanticLabel;

  /// Opens a menu under the control [context] belongs to, over the whole app:
  /// the context of a [Builder] round that control, never the page's (whose box
  /// is the whole screen, so the menu would drop from nowhere). [anchor] widens
  /// the box it drops from: a context round the control's row (a month
  /// menu hangs from the whole month switch). With [fitAnchor] the menu is
  /// at least as wide as that box and stands on its leading edge, as a select's
  /// list stands under its field.
  ///
  /// The keyboard walks it as every list ui_core opens: opened by a key
  /// (Enter, Space or an arrow on its control) the chosen item takes the
  /// focus, or the first when none is chosen; opened by a pointer the menu
  /// holds it, and the first arrow moves on from the chosen item. The arrows
  /// go round the ends, Home and End go to them, a typed letter jumps to the
  /// next item it starts, Enter or Space chooses and closes, and Escape
  /// closes; the control opened by a key has the focus back.
  static Future<T?> show<T>(
    BuildContext context, {
    required List<FrostedMenuItem<T>> items,
    String? title,
    String? semanticLabel,
    BuildContext? anchor,
    bool fitAnchor = false,
  }) {
    final navigator = FrostedHost.navigatorOf(context);
    final box = (anchor ?? context).findRenderObject()! as RenderBox;
    final overlay = navigator.overlay!.context.findRenderObject()! as RenderBox;
    final rect = Rect.fromPoints(
      box.localToGlobal(Offset.zero, ancestor: overlay),
      box.localToGlobal(box.size.bottomRight(Offset.zero), ancestor: overlay),
    );
    assert(
      rect.height < overlay.size.height / 2,
      'FrostedMenu.show takes the context of the control that opens it (a '
      "Builder round it), not the page's.",
    );
    final themes = InheritedTheme.capture(from: context, to: navigator.context);
    final wide = FrostedBreakpoints.isWide(context);
    // A key held as the control fires opened it; a pointer's press holds
    // none.
    final keyed = HardwareKeyboard.instance.logicalKeysPressed.any(
      _openingKeys.contains,
    );
    final opener = keyed ? FocusManager.instance.primaryFocus : null;
    final picked = navigator.push(
      _MenuRoute<T>(
        duration: FrostedMotion.of(context).fast,
        anchor: rect,
        wide: wide,
        start: fitAnchor,
        label: MaterialLocalizations.of(context).modalBarrierDismissLabel,
        builder: (menuContext) => themes.wrap(
          _MenuKeys<T>(
            items: items,
            title: title,
            label: semanticLabel,
            keyed: keyed,
            width: fitAnchor
                ? math.max(FrostedChromeMetrics.menuWidth, rect.width)
                : null,
            onSelected: (value) => Navigator.of(menuContext).pop(value),
          ),
        ),
      ),
    );
    if (opener == null) return picked;
    return picked.whenComplete(() {
      if (opener.context != null && opener.canRequestFocus) {
        opener.requestFocus();
      }
    });
  }

  static final _openingKeys = <LogicalKeyboardKey>{
    LogicalKeyboardKey.enter,
    LogicalKeyboardKey.numpadEnter,
    LogicalKeyboardKey.space,
    LogicalKeyboardKey.select,
    LogicalKeyboardKey.arrowDown,
    LogicalKeyboardKey.arrowUp,
  };

  /// [base] grown with the text, as far as the window's gutters: a menu's
  /// names keep their room at 200% rather than cutting off beside amounts
  /// that stay whole.
  static double _grown(BuildContext context, double base) {
    final grow = MediaQuery.textScalerOf(context).scale(16) / 16;
    if (grow <= 1) return base;
    final room =
        MediaQuery.sizeOf(context).width - 2 * FrostedChromeMetrics.gutter;
    return math.max(base, math.min(base * grow, room));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final head = title;
    // The theme's menu style: its fill, edge colour, shape (the corner
    // scale's medium step) and padding.
    final s = FrostedStyleLayers(null, t.components.menu);
    final (cut, corner) = s.surface(
      FrostedCorners.medium,
      FrostedStyleLayers.stockMedium,
      FrostedChromeMetrics.menuRadius,
    );
    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: semanticLabel ?? head,
      child: Material(
        type: MaterialType.transparency,
        child: SizedBox(
          width: _grown(context, width ?? FrostedChromeMetrics.menuWidth),
          child: FrostedFace(
            material: FrostedMaterial.slab,
            radius: BorderRadius.circular(corner),
            shape: cut,
            color: s.fill,
            // `.menu { box-shadow: 0 0 0 1px ..., 0 22px 44px -18px ... }`:
            // the edge is a ring round the face, taking no room of its own
            // (a face's edge would stand every row 1 lower and 2 narrower).
            shadows: [
              ...t.shadows.menu,
              BoxShadow(
                color: s.edge ?? t.glass.menuEdge,
                spreadRadius: FrostedStrokes.regular,
              ),
            ],
            padding:
                s.padding?.resolve(Directionality.of(context)) ??
                const EdgeInsets.all(FrostedChromeMetrics.menuInset),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: FrostedChromeMetrics.menuItemsGap,
              children: [
                if (head != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      FrostedChromeMetrics.menuHeadSide,
                      FrostedChromeMetrics.menuHeadTop,
                      FrostedChromeMetrics.menuHeadSide,
                      FrostedChromeMetrics.menuHeadBottom,
                    ),
                    // `.cap.menu-h`: 12 on .cap's 15.6 line (12px/1.3).
                    child: Text(
                      head,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.textTheme.labelMedium.line(15.6),
                    ),
                  ),
                for (final (i, item) in items.indexed)
                  _MenuRow(
                    key: item.key,
                    index: i,
                    place: _place,
                    focusNode: _rows?[i],
                    autofocus: i == _focused,
                    label: item.label,
                    hue: item.hue,
                    end: item.trailing,
                    checked: item.checked,
                    destructive: item.isDestructiveAction,
                    onTap: item.enabled ? () => onSelected(item.value) : null,
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
      ..add(IterableProperty<FrostedMenuItem<T>>('items', items))
      ..add(DoubleProperty('width', width, defaultValue: null))
      ..add(ObjectFlagProperty<ValueChanged<T>>.has('onSelected', onSelected))
      ..add(StringProperty('title', title, defaultValue: null))
      ..add(StringProperty('semanticLabel', semanticLabel, defaultValue: null));
  }
}

/// A menu's row: 40 tall, 10 in, corners 10; the check's
/// column 16 wide, then the label in the link type, then the end note; the
/// chosen one on the chosen plate, its label in the ink and semibold; a loss
/// sets its label in the over ink, lit or not. The
/// row the keys or a moving pointer last went to lights with the quieter
/// wash (the row a press would pick), never the plate, so it never
/// reads as a second choice; one row at a time. The keyboard's ring stands
/// inside the row, concentric with the menu, never against its edge.
class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.label,
    required this.onTap,
    required this.checked,
    this.destructive = false,
    this.index = 0,
    this.place,
    this.hue,
    this.end,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  final bool destructive;

  // Whether the row takes the focus as it mounts.
  final bool autofocus;
  final int index;
  final _MenuPlace? place;
  final FocusNode? focusNode;
  final String label;
  final VoidCallback? onTap;
  final bool checked;
  final Color? hue;
  final Widget? end;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final swatch = hue;
    final corner = BorderRadius.circular(FrostedChromeMetrics.menuItemRadius);
    // Room above and below for a name that wraps at large text; a line's
    // row stands at its least height.
    const inset = EdgeInsets.symmetric(
      horizontal: FrostedChromeMetrics.menuItemInset,
      vertical: FrostedChromeMetrics.optionInset,
    );
    // Lit: under a pointer or held by the keyboard (law 7), its words in the
    // ink as a panel row's are.
    Widget row(bool lit) => Row(
      spacing: FrostedChromeMetrics.menuItemGap,
      children: [
        SizedBox(
          width: FrostedChromeMetrics.menuItemGlyph,
          child: checked
              ? Icon(
                  FrostedGlyphs.check,
                  size: FrostedChromeMetrics.menuItemGlyph,
                  color: t.colorScheme.textPrimary,
                )
              : swatch == null
              ? null
              : Center(child: FrostedHueDot(swatch)),
        ),
        Expanded(
          child: frostedCapCentred(
            // A long name wraps rather than losing its end beside an
            // amount that stays whole ("Augu…" at 200%).
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: checked
                  ? t.textTheme.link.semibold.c(
                      destructive
                          ? t.colorScheme.over
                          : t.colorScheme.textPrimary,
                    )
                  : t.textTheme.link.c(
                      destructive
                          ? t.colorScheme.over
                          : lit
                          ? t.colorScheme.textPrimary
                          : t.colorScheme.textSecondary,
                    ),
            ),
          ),
        ),
        if (end != null)
          DefaultTextStyle.merge(
            style: t.textTheme.amountSmall.c(t.colorScheme.textPrimary),
            child: end!,
          ),
      ],
    );
    // The row clears the frost under it, within its edge: the menu's inset
    // clear all round it, its corner concentric with the menu's. It draws
    // its own clearing (lit by its place as well as by focus), so the
    // pressable's stands down.
    Widget pressable() => FrostedClearingHeld(
      child: FrostedPressable(
        onPressed: onTap,
        focusNode: focusNode,
        autofocus: autofocus,
        semanticLabel: label,
        selected: checked,
        radius: FrostedChromeMetrics.menuItemRadius,
        ringInside: true,
        builder: (context, states, _) {
          final at = place;
          // In a menu [FrostedMenu.show] raises, the one place the keys or
          // the pointer last went; a menu standing in a page, the pointer's
          // row or the keyboard's.
          final pressed = states.contains(WidgetState.pressed);
          final level = at == null
              ? states.contains(WidgetState.focused)
                    ? 1.0
                    : states.contains(WidgetState.hovered)
                    ? FrostedClearing.hover
                    : 0.0
              : at.current.value == index
              ? 1.0
              : 0.0;
          // Its words take the strong ink while lit; pressed, its plate lights.
          final lit = pressed || level > 0;
          return FrostedDim(
            off: onTap == null,
            // At least a finger's target tall, as a panel row is, and taller
            // as a long name wraps.
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: math.max(
                  FrostedChromeMetrics.menuItem,
                  FrostedBreakpoints.hitTargetOf(context),
                ),
              ),
              // Chosen is the brighter glass (law 6), the plate every chosen
              // chip, segment and link stands on, not a quieter wash under it
              // (a darker plate reads as the opposite).
              // The keyboard's row catches the light along its rim; the
              // pointer's only clears.
              child: FrostedCleared(
                level: level,
                lit: level == 1 && (at == null || FrostedLastInput.keyed)
                    ? 1
                    : 0,
                outline: RoundedRectangleBorder(borderRadius: corner),
                inside: true,
                child: checked
                    ? FrostedChosenPlate(
                        radius: corner,
                        padding: inset,
                        child: row(lit),
                      )
                    : FrostedFace(
                        material: FrostedMaterial.paint,
                        radius: corner,
                        color: pressed ? t.glass.wash : null,
                        padding: inset,
                        child: row(lit),
                      ),
              ),
            ),
          );
        },
      ),
    );
    final at = place;
    if (at == null) return pressable();
    return MouseRegion(
      // A pointer moving over a row moves the place there (not one resting
      // under a menu as it opens).
      onHover: (_) => at.point(index),
      child: ValueListenableBuilder<int?>(
        valueListenable: at.current,
        builder: (context, _, _) => pressable(),
      ),
    );
  }
}

/// The one row a raised menu lights, and the pointer's way to move it.
class _MenuPlace {
  _MenuPlace(this.point);

  final ValueNotifier<int?> current = ValueNotifier(null);
  final void Function(int index) point;
}

/// The keys of a menu [FrostedMenu.show] raises, round it: as it opens the
/// chosen row takes the focus when a key opened it ([keyed]; the first row
/// when none is chosen), the menu itself when a pointer did. A key goes up
/// from the focus, so they are read here, above every row and the menu's
/// own node, before the app's shortcuts (a web app's arrows scroll).
class _MenuKeys<T> extends StatefulWidget {
  const _MenuKeys({
    required this.items,
    required this.onSelected,
    required this.keyed,
    this.title,
    this.label,
    this.width,
  });

  final List<FrostedMenuItem<T>> items;
  final ValueChanged<T> onSelected;
  final bool keyed;
  final String? title;
  final String? label;
  final double? width;

  @override
  State<_MenuKeys<T>> createState() => _MenuKeysState<T>();
}

class _MenuKeysState<T> extends State<_MenuKeys<T>> {
  final _menu = FocusNode(debugLabel: 'FrostedMenu', skipTraversal: true);
  late List<FocusNode> _rows = _nodes();
  late final _place = _MenuPlace(_point);

  // What was typed for the type-ahead, and when its last letter came.
  String _typed = '';
  DateTime? _typedAt;

  // Each row's node; the row the keys move to becomes the place.
  List<FocusNode> _nodes() => [
    for (final (i, item) in widget.items.indexed)
      FocusNode(debugLabel: item.label)..addListener(() => _focused(i)),
  ];

  void _focused(int i) {
    if (i < _rows.length && _rows[i].hasPrimaryFocus) {
      _place.current.value = i;
    }
  }

  // A pointer moving over a row that can be chosen makes it the place, and
  // the menu takes the focus back from a row the keys held, so one row is
  // lit and the keys go on from it.
  void _point(int i) {
    if (!_on(i) || _place.current.value == i) return;
    _place.current.value = i;
    _menu.requestFocus();
  }

  // Opened by a key, the chosen row (else the first) takes the focus as it
  // mounts; opened by a pointer, the menu holds it.
  late final int? _start = widget.keyed ? (_chosen ?? _step(-1, 1)) : null;

  @override
  void didUpdateWidget(_MenuKeys<T> old) {
    super.didUpdateWidget(old);
    if (old.items.length != widget.items.length) {
      for (final node in _rows) {
        node.dispose();
      }
      _rows = _nodes();
    }
  }

  @override
  void dispose() {
    _menu.dispose();
    for (final node in _rows) {
      node.dispose();
    }
    _place.current.dispose();
    super.dispose();
  }

  bool _on(int i) => widget.items[i].enabled;

  int? get _chosen {
    final i = widget.items.indexWhere((item) => item.checked && item.enabled);
    return i < 0 ? null : i;
  }

  int? get _held {
    final i = _rows.indexWhere((node) => node.hasPrimaryFocus);
    return i < 0 ? null : i;
  }

  /// The next row that can be chosen from [from], [by] at a time, round the
  /// ends; null when none can.
  int? _step(int from, int by) {
    final n = widget.items.length;
    for (var k = 1; k <= n; k++) {
      final i = ((from + by * k) % n + n) % n;
      if (_on(i)) return i;
    }
    return null;
  }

  void _hold(int? i) {
    if (i != null) _rows[i].requestFocus();
  }

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final n = widget.items.length;
    final from = _held ?? _place.current.value ?? _chosen;
    final key = event.logicalKey;
    // The pointer's row, with the focus on the menu: Return or Space takes
    // it, as on a row the keys hold.
    final at = _place.current.value;
    if (_held == null && at != null && _choosingKeys.contains(key)) {
      if (_on(at)) widget.onSelected(widget.items[at].value);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowDown) {
      _hold(_step(from ?? -1, 1));
    } else if (key == LogicalKeyboardKey.arrowUp) {
      _hold(_step(from ?? n, -1));
    } else if (key == LogicalKeyboardKey.home) {
      _hold(_step(-1, 1));
    } else if (key == LogicalKeyboardKey.end) {
      _hold(_step(n, -1));
    } else if (_letter(event) case final letter?) {
      _jump(letter, from ?? -1);
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  static final _choosingKeys = <LogicalKeyboardKey>{
    LogicalKeyboardKey.enter,
    LogicalKeyboardKey.numpadEnter,
    LogicalKeyboardKey.space,
    LogicalKeyboardKey.select,
  };

  // A printable letter or digit typed with no command key; Space chooses.
  static String? _letter(KeyEvent event) {
    final c = event.character;
    if (c == null || c.trim().isEmpty || c.runes.length != 1) return null;
    // Escape, Backspace and their kind say a control character: no letter.
    final rune = c.runes.first;
    if (rune < 0x20 || rune == 0x7f) return null;
    final keys = HardwareKeyboard.instance;
    if (keys.isControlPressed || keys.isMetaPressed || keys.isAltPressed) {
      return null;
    }
    return c.toLowerCase();
  }

  /// The type-ahead: letters typed within a moment of each other spell the
  /// start of an item's words, from the row held; a letter alone jumps to
  /// the next row it starts.
  void _jump(String letter, int from) {
    final now = DateTime.now();
    final last = _typedAt;
    final more =
        last != null && now.difference(last) < const Duration(seconds: 1);
    _typedAt = now;
    int? find(String typed, int start) {
      final n = widget.items.length;
      for (var k = 0; k < n; k++) {
        final i = ((start + k) % n + n) % n;
        if (_on(i) && widget.items[i].label.toLowerCase().startsWith(typed)) {
          return i;
        }
      }
      return null;
    }

    if (more) {
      final spelt = find('$_typed$letter', math.max(from, 0));
      if (spelt != null) {
        _typed = '$_typed$letter';
        _hold(spelt);
        return;
      }
    }
    _typed = letter;
    _hold(find(letter, from + 1));
  }

  @override
  Widget build(BuildContext context) => Focus(
    focusNode: _menu,
    autofocus: _start == null,
    includeSemantics: false,
    onKeyEvent: _key,
    child: FrostedMenu<T>._keyed(
      _rows,
      _place,
      _start,
      items: widget.items,
      title: widget.title,
      semanticLabel: widget.label,
      width: widget.width,
      onSelected: widget.onSelected,
    ),
  );
}

/// The route a menu rides: no scrim, dismissed by a tap outside or Escape,
/// laid out under its anchor.
class _MenuRoute<T> extends PopupRoute<T> {
  _MenuRoute({
    required this.duration,
    required this.anchor,
    required this.wide,
    required this.label,
    required this.builder,
    this.start = false,
  });

  final Duration duration;
  final Rect anchor;
  final bool wide;
  final bool start;
  final String label;
  final WidgetBuilder builder;

  @override
  Color? get barrierColor => null;

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => label;

  @override
  Duration get transitionDuration => duration;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => CustomSingleChildLayout(
    delegate: _Below(anchor, wide, Directionality.of(context), start: start),
    // Glass is never faded from above (an Opacity over its blur reads an
    // empty layer): the menu grows out of its anchor, frosted from its
    // first frame.
    child: AnimatedBuilder(
      animation: animation,
      child: builder(context),
      builder: (context, child) => animation.value <= 0
          ? const SizedBox.shrink()
          : Transform.scale(
              scale: .94 + .06 * Curves.easeOutCubic.transform(animation.value),
              alignment: Alignment.topCenter,
              child: child,
            ),
    ),
  );
}

class _Below extends SingleChildLayoutDelegate {
  const _Below(this.anchor, this.wide, this.direction, {this.start = false});

  final Rect anchor;
  final bool wide;
  final TextDirection direction;

  /// Whether it stands on the anchor's leading edge (a select's list).
  final bool start;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      constraints.loosen().deflate(
        const EdgeInsets.all(FrostedChromeMetrics.gutter),
      );

  @override
  Offset getPositionForChild(Size size, Size child) {
    const edge = FrostedChromeMetrics.gutter;
    // Centred under the control on a phone; its end on the control's end
    // at desktop width.
    final x = start
        ? (direction == TextDirection.rtl
              ? anchor.right - child.width
              : anchor.left)
        : !wide
        ? anchor.center.dx - child.width / 2
        : direction == TextDirection.rtl
        ? anchor.left
        : anchor.right - child.width;
    final gap = start
        ? FrostedChromeMetrics.listGap
        : FrostedChromeMetrics.menuGap;
    final below = anchor.bottom + gap;
    // Opened near the foot, it rises instead.
    final y = below + child.height > size.height - edge
        ? anchor.top - gap - child.height
        : below;
    return Offset(
      x.clamp(edge, size.width - edge - child.width),
      y.clamp(edge, size.height - edge - child.height),
    );
  }

  @override
  bool shouldRelayout(_Below old) =>
      old.anchor != anchor ||
      old.wide != wide ||
      old.direction != direction ||
      old.start != start;
}
