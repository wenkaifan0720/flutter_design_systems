import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart' show Material, MaterialType;
import 'package:flutter/widgets.dart';

import '../../chrome_metrics.dart';
import '../../icons.dart';
import '../../internal/cap_label.dart';
import '../../internal/chosen.dart';
import '../../internal/icon_fill.dart';
import '../../internal/list_keys.dart';
import '../../internal/menu_lead.dart';
import '../../localizations.dart';
import '../../styled.dart';
import '../../theme.dart';
import '../host.dart';
import '../pressable/pressable.dart';

import 'package:ui_core/ui_core.dart';

/// One choice of a [Fluent2Menu] (Fluent's `MenuItem`): its [label], a
/// glyph before it ([icon]), its [secondary] words at the end (a shortcut,
/// a count), the check before it while [checked] (a `MenuItemRadio` or
/// `MenuItemCheckbox`), the danger ink when [danger] (Delete), and the
/// [value] the menu returns. A [divider] draws a hairline above it.
///
/// ```dart
/// Fluent2MenuItem('rename', 'Rename', icon: Fluent2Icons.edit, secondary: 'F2')
/// ```
@immutable
class Fluent2MenuItem<T> {
  /// A menu item for [value], labelled [label].
  const Fluent2MenuItem(
    this.value,
    this.label, {
    this.icon,
    this.secondary,
    this.checked,
    this.danger = false,
    this.divider = false,
    this.enabled = true,
    this.key,
  });

  /// The value [Fluent2Menu.onSelected] is told when the item is chosen.
  final T value;

  /// The item's words.
  final String label;

  /// The glyph before [label]; null shows none.
  final IconData? icon;

  /// Quieter words at the item's end (a shortcut); null shows none.
  final String? secondary;

  /// Null draws no check column; true or false a checkable item.
  final bool? checked;

  /// Whether the item destroys something, drawn in the danger colour.
  final bool danger;

  /// Whether a divider stands over the item.
  final bool divider;

  /// False draws the item disabled; it cannot be chosen.
  final bool enabled;

  /// The item's key, for tests and tours.
  final Key? key;
}

/// Fluent 2's Menu, its popover drawn in place: the surface in
/// `shadow16`, its corners 4, 4 round its items, at least 138 and at most
/// 300 wide; an optional [title] (Fluent's `MenuGroupHeader`, caption1
/// strong in the third ink); one row per item, 32 tall under a pointer and
/// the floor (40) under a finger, 6 round its parts, the glyph 20 in the second ink, the
/// words in body1, a subtle fill under the pointer. A choice calls
/// [onSelected] with its value. Open one from a control with [show]: the
/// focus goes to its checked item, else its first; Down and Up move round
/// it, Home and End go to its ends, a typed letter to the next item it
/// starts, Enter chooses and Escape closes it, the focus back on the
/// control. One row is current, as in Fluent's menus: opened by a key, the
/// focused row in the focus ring; opened by a pointer, none until the
/// pointer or a key moves; the pointer's row takes the focus, so the keys
/// go on from it, and a key puts the pointer's fill out until it moves.
/// Its surface reads [style], then the menu theme
/// ([Fluent2ThemeData.menuTheme]), then Fluent's own: `fill`, `edge` or
/// `side`, `shape` and `padding`.
///
/// ```dart
/// Builder(builder: (anchor) => Fluent2IconButton(Fluent2Icons.moreHorizontal, semanticLabel: 'More options', onPressed: () async { final picked = await Fluent2Menu.show<String>(anchor, items: actions); if (picked != null) run(picked); }))
/// ```
class Fluent2Menu<T> extends StatefulWidget {
  /// A menu of [items].
  const Fluent2Menu({
    required this.items,
    required this.onSelected,
    this.title,
    this.semanticLabel,
    this.style,
    super.key,
  });

  /// The menu's items, in order.
  final List<Fluent2MenuItem<T>> items;

  /// Called with the value of the item chosen.
  final ValueChanged<T> onSelected;

  /// The group header over the items.
  final String? title;

  /// What a screen reader calls the menu; null says [title].
  final String? semanticLabel;

  /// This menu's own look, slot by slot, over the menu theme
  /// ([Fluent2ThemeData.menuTheme]): the slots this class's doc names.
  final Fluent2Style? style;

  /// Opens a menu under the control [context] belongs to, over the whole
  /// app: the context of a [Builder] round that control, never the page's.
  /// [anchor] widens the box it drops from. Completes with the value
  /// chosen, or null when it is dismissed.
  static Future<T?> show<T>(
    BuildContext context, {
    required List<Fluent2MenuItem<T>> items,
    String? title,
    String? semanticLabel,
    BuildContext? anchor,
    Fluent2Style? style,
  }) {
    final navigator = Fluent2Host.navigatorOf(context);
    final box = (anchor ?? context).findRenderObject()! as RenderBox;
    final overlay = navigator.overlay!.context.findRenderObject()! as RenderBox;
    final rect = Rect.fromPoints(
      box.localToGlobal(Offset.zero, ancestor: overlay),
      box.localToGlobal(box.size.bottomRight(Offset.zero), ancestor: overlay),
    );
    assert(
      rect.height < overlay.size.height / 2,
      'Fluent2Menu.show takes the context of the control that opens it (a '
      "Builder round it), not the page's.",
    );
    final themes = InheritedTheme.capture(from: context, to: navigator.context);
    return navigator.push(
      _MenuRoute<T>(
        anchor: rect,
        keys: fluent2KeysLed(),
        label: RawWidgetsLocalizations.of(context).modalBarrierDismissLabel,
        builder: (menuContext) => themes.wrap(
          Fluent2Menu<T>(
            items: items,
            title: title,
            semanticLabel: semanticLabel,
            style: style,
            onSelected: (value) => Navigator.of(menuContext).pop(value),
          ),
        ),
      ),
    );
  }

  @override
  State<Fluent2Menu<T>> createState() => _Fluent2MenuState<T>();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<Fluent2MenuItem<T>>('items', items))
      ..add(ObjectFlagProperty<ValueChanged<T>>.has('onSelected', onSelected))
      ..add(StringProperty('title', title, defaultValue: null))
      ..add(StringProperty('semanticLabel', semanticLabel, defaultValue: null))
      ..add(
        DiagnosticsProperty<Fluent2Style>('style', style, defaultValue: null),
      );
  }
}

class _Fluent2MenuState<T> extends State<Fluent2Menu<T>> {
  List<FocusNode> _nodes = const [];
  bool _placed = false;

  void _fit() {
    final n = widget.items.length;
    if (_nodes.length == n) return;
    for (final node in _nodes.skip(n)) {
      node.dispose();
    }
    _nodes = [
      for (var i = 0; i < n; i++)
        i < _nodes.length ? _nodes[i] : FocusNode(debugLabel: 'menu item $i'),
    ];
  }

  // Opened as a menu ([Fluent2Menu.show]): the focus on its checked item,
  // else its first in use, once it shows. A menu drawn in place takes none.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_placed || ModalRoute.of(context) is! _MenuRoute) return;
    _placed = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _fit();
      if (_nodes.isEmpty) return;
      final items = widget.items;
      _nodes[fluent2FirstFocus([
            for (final item in items) item.enabled,
          ], items.indexWhere((item) => item.checked ?? false))]
          .requestFocus();
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
    final t = context.fluent2Theme;
    final look = Fluent2StyleOf([widget.style, t.menuTheme], const {});
    final head = widget.title;
    final items = widget.items;
    _fit();
    final checks = items.any((i) => i.checked != null);
    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label:
          widget.semanticLabel ?? head ?? Fluent2Localizations.of(context).menu,
      child: Material(
        type: MaterialType.transparency,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: Fluent2ChromeMetrics.menuMinWidth,
            maxWidth: Fluent2ChromeMetrics.menuMaxWidth,
          ),
          child: IntrinsicWidth(
            child: Fluent2Plate(
              fill: look.fill ?? t.colors.neutralBackground1,
              side: fluent2Rim(
                t,
                look,
                t.isDark ? t.colors.neutralStroke2 : t.colors.transparentStroke,
              ),
              radius: BorderRadius.circular(Fluent2Radius.medium),
              shape: look.shape,
              shadows: t.shadows.shadow16,
              // Fluent's 4 round the items, inside the 1 px stroke.
              padding:
                  look.padding(Directionality.of(context)) ??
                  const EdgeInsets.all(
                    Fluent2ChromeMetrics.menuPadding +
                        Fluent2ChromeMetrics.hairline,
                  ),
              child: Fluent2ListKeys(
                nodes: _nodes,
                labels: [for (final item in items) item.label],
                enabled: [for (final item in items) item.enabled],
                child: _led(
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (head != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            Fluent2Spacing.s,
                            Fluent2Spacing.sNudge,
                            Fluent2Spacing.s,
                            Fluent2Spacing.xs,
                          ),
                          child: Text(
                            head,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: t.caption1Strong.c(t.textTertiary),
                          ),
                        ),
                      for (final (i, item) in items.indexed) ...[
                        if (item.divider)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: Fluent2Spacing.xxs,
                            ),
                            child: SizedBox(
                              height: 1,
                              child: ColoredBox(color: t.colors.neutralStroke2),
                            ),
                          ),
                        _MenuRow<T>(
                          key: item.key,
                          item: item,
                          checks: checks,
                          focusNode: _nodes[i],
                          onTap: item.enabled
                              ? () => widget.onSelected(item.value)
                              : null,
                        ),
                      ],
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

  // Opened as a menu, one row current ([Fluent2MenuLead]); drawn in place,
  // each row draws its own states.
  Widget _led(Widget rows) => switch (ModalRoute.of(context)) {
    final _MenuRoute<Object?> route => Fluent2MenuLead(
      keys: route.keys,
      child: rows,
    ),
    _ => rows,
  };
}

class _MenuRow<T> extends StatelessWidget {
  const _MenuRow({
    required this.item,
    required this.checks,
    required this.onTap,
    this.focusNode,
    super.key,
  });

  final Fluent2MenuItem<T> item;
  final bool checks;
  final VoidCallback? onTap;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    return Fluent2Pressable(
      onPressed: onTap,
      semanticLabel: item.label,
      value: item.secondary,
      selected: item.checked,
      focusNode: focusNode,
      radius: Fluent2Radius.medium,
      // The face rings itself, as the open menu's lead says.
      ring: false,
      builder: (context, states) => Fluent2MenuRowFace(
        label: item.label,
        states: states,
        icon: item.icon,
        secondary: item.secondary,
        checks: checks,
        checked: item.checked == true,
        danger: item.danger,
        ring: true,
      ),
    );
  }
}

/// A menu row's face, Fluent's `MenuItem`: 32 tall under a pointer and 44
/// under a finger, the check column when [checks], the glyph 20 in the second ink,
/// the words in body1, [secondary] in the third ink at the end, a chevron
/// when [submenu]. Hover and press step the fill and turn the glyph brand; a
/// [checked] row in the check column stands out as the chosen option of an
/// open list does (the brand's fill, its pill, the check in the brand); a
/// face a behaviour drives by key draws its ring from [ring] with the focused
/// state. In an open menu it draws what the menu's lead shows
/// ([Fluent2MenuLead]: one current row), and the pointer moving over it
/// takes the focus there. The rows of the menu, the command palette and the
/// menu bar are this one face.
class Fluent2MenuRowFace extends StatelessWidget {
  /// A row saying [label], drawn for [states].
  const Fluent2MenuRowFace({
    super.key,
    required this.label,
    required this.states,
    this.icon,
    this.secondary,
    this.checks = false,
    this.checked = false,
    this.danger = false,
    this.submenu = false,
    this.ring = false,
    this.emphasis = false,
  });

  /// Its words.
  final String label;

  /// The press's states.
  final Set<WidgetState> states;

  /// The glyph before the words.
  final IconData? icon;

  /// The words at its end: a shortcut, a count.
  final String? secondary;

  /// Keep the check column, for a menu with something to tick.
  final bool checks;

  /// Ticked.
  final bool checked;

  /// A loss: the danger ink.
  final bool danger;

  /// Opens a menu of its own.
  final bool submenu;

  /// Draw the focus ring here, for a row the keyboard walks without a press.
  final bool ring;

  /// The words in body1 strong (an action sheet's way out).
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    // A finger's row under a finger, a pointer's under a pointer.
    final touch = Fluent2Layout.padded(context);
    final lead = Fluent2MenuLead.of(context);
    final states = lead?.shown(this.states) ?? this.states;
    final press = states.press;
    final ink = danger && press != Fluent2Press.disabled
        ? t.danger
        : press.pick(
            t.colors.neutralForeground2,
            t.colors.neutralForeground2Hover,
            t.colors.neutralForeground2Pressed,
            t.colors.neutralForegroundDisabled,
          );
    final glyph = danger && press != Fluent2Press.disabled
        ? t.danger
        : press.pick(
            t.colors.neutralForeground2,
            t.colors.neutralForeground2BrandHover,
            t.colors.neutralForeground2BrandPressed,
            t.colors.neutralForegroundDisabled,
          );
    final chosen = checks && checked;
    return fluent2EasedInks(
      [
        ink,
        glyph,
        fluent2RowFill(
          t.colors,
          press,
          chosen: chosen,
          resting: t.colors.neutralBackground1,
        ),
      ],
      (context, inks) {
        final [ink, glyph, rowFill] = inks;
        final face = Container(
          constraints: BoxConstraints(
            minHeight: touch
                ? Fluent2Layout.hitTargetOf(context)
                : Fluent2ChromeMetrics.menuItem,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: Fluent2ChromeMetrics.menuItemPadding,
          ),
          decoration: BoxDecoration(
            color: rowFill,
            borderRadius: BorderRadius.circular(Fluent2Radius.medium),
          ),
          child: Row(
            spacing: Fluent2ChromeMetrics.menuItemGap,
            children: [
              if (checks)
                SizedBox(
                  width: 16,
                  child: checked
                      ? Icon(
                          Fluent2Icons.checkmark16,
                          size: 16,
                          color: fluent2ChosenInk(t.colors, press),
                        )
                      : null,
                ),
              if (icon != null)
                Icon(
                  press == Fluent2Press.hover || press == Fluent2Press.pressed
                      ? fluent2Filled(icon!)
                      : icon,
                  size: 20,
                  color: glyph,
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Fluent2ChromeMetrics.menuItemWordsInset,
                  ),
                  child: fluent2CapCentred(
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: (emphasis ? t.body1Strong : t.body1).c(ink),
                    ),
                  ),
                ),
              ),
              if (secondary != null)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Fluent2ChromeMetrics.menuItemWordsInset,
                  ),
                  child: fluent2CapCentred(
                    Text(
                      secondary!,
                      maxLines: 1,
                      style: t.caption1.c(
                        press == Fluent2Press.disabled
                            ? t.colors.neutralForegroundDisabled
                            : t.textTertiary,
                      ),
                    ),
                  ),
                ),
              if (submenu)
                Icon(
                  Directionality.of(context) == TextDirection.rtl
                      ? Fluent2Icons.chevronLeft
                      : Fluent2Icons.chevronRight,
                  size: 16,
                  color: glyph,
                ),
            ],
          ),
        );
        final row = fluent2ChosenRow(
          row: face,
          chosen: chosen,
          colors: t.colors,
          press: press,
        );
        if (!ring || !states.focused) return _pointed(context, lead, row);
        return _pointed(
          context,
          lead,
          Stack(
            fit: StackFit.passthrough,
            children: [
              row,
              const Positioned.fill(
                child: IgnorePointer(
                  child: Fluent2FocusRing(radius: Fluent2Radius.medium),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // In an open menu, the pointer moving over the row leads and takes the
  // focus there (not a row that comes to lie under a resting pointer).
  static Widget _pointed(
    BuildContext context,
    Fluent2MenuLeadState? lead,
    Widget row,
  ) => lead == null
      ? row
      : MouseRegion(
          opaque: false,
          onHover: (_) => lead.pointed(Focus.maybeOf(context)),
          child: row,
        );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('label', label))
      ..add(IterableProperty<WidgetState>('states', states))
      ..add(DiagnosticsProperty<IconData>('icon', icon, defaultValue: null))
      ..add(StringProperty('secondary', secondary, defaultValue: null))
      ..add(FlagProperty('checks', value: checks, ifTrue: 'checks'))
      ..add(FlagProperty('checked', value: checked, ifTrue: 'checked'))
      ..add(FlagProperty('danger', value: danger, ifTrue: 'danger'))
      ..add(FlagProperty('submenu', value: submenu, ifTrue: 'submenu'))
      ..add(FlagProperty('ring', value: ring, ifTrue: 'ring'))
      ..add(FlagProperty('emphasis', value: emphasis, ifTrue: 'emphasis'));
  }
}

/// The route a menu rides: no overlay, dismissed by a tap outside, laid
/// out under its anchor.
class _MenuRoute<T> extends PopupRoute<T> {
  _MenuRoute({
    required this.anchor,
    required this.keys,
    required this.label,
    required this.builder,
  });

  final Rect anchor;

  // Whether a key opened it: its focused row shows at once.
  final bool keys;
  final String label;
  final WidgetBuilder builder;

  @override
  Color? get barrierColor => null;

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => label;

  @override
  Duration get transitionDuration =>
      Fluent2Motion.of(navigator!.context, Fluent2Motion.normal);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => FadeTransition(
    // A tween's drive, not a CurvedAnimation: nothing to dispose when the
    // route goes.
    opacity: animation.drive(CurveTween(curve: Fluent2Motion.decelerateMid)),
    child: CustomSingleChildLayout(
      delegate: _Below(anchor, Directionality.of(context)),
      child: builder(context),
    ),
  );
}

class _Below extends SingleChildLayoutDelegate {
  const _Below(this.anchor, this.direction);

  final Rect anchor;
  final TextDirection direction;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      constraints.loosen().deflate(
        const EdgeInsets.all(Fluent2ChromeMetrics.gutter / 2),
      );

  @override
  Offset getPositionForChild(Size size, Size child) {
    const edge = Fluent2ChromeMetrics.gutter / 2;
    // Its start on the control's start, 4 under it (Fluent's
    // `below-start`); near the foot it rises above the control instead.
    final x = direction == TextDirection.rtl
        ? anchor.right - child.width
        : anchor.left;
    final below = anchor.bottom + Fluent2Spacing.xs;
    final y = below + child.height > size.height - edge
        ? anchor.top - Fluent2Spacing.xs - child.height
        : below;
    return Offset(
      x.clamp(edge, size.width - edge - child.width),
      y.clamp(edge, size.height - edge - child.height),
    );
  }

  @override
  bool shouldRelayout(_Below old) =>
      old.anchor != anchor || old.direction != direction;
}
