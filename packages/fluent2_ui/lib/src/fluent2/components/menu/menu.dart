import 'package:material_ui/material_ui.dart' show Material, MaterialType;
import 'package:flutter/widgets.dart';

import '../../chrome_metrics.dart';
import '../../icons.dart';
import '../../internal/cap_label.dart';
import '../../internal/icon_fill.dart';
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
/// strong in the third ink); one row per item, 32 tall on the desktop and
/// 44 on a phone, 6 round its parts, the glyph 20 in the second ink, the
/// words in body1, a subtle fill under the pointer. A choice calls
/// [onSelected] with its value. Open one from a control with [show].
///
/// ```dart
/// Builder(builder: (anchor) => Fluent2IconButton(Fluent2Icons.moreHorizontal, label: 'More options', onPressed: () async { final picked = await Fluent2Menu.show<String>(anchor, items: actions); }))
/// ```
class Fluent2Menu<T> extends StatelessWidget {
  /// A menu of [items].
  const Fluent2Menu({
    required this.items,
    required this.onSelected,
    this.title,
    this.label,
    super.key,
  });

  /// The menu's items, in order.
  final List<Fluent2MenuItem<T>> items;

  /// Called with the value of the item chosen.
  final ValueChanged<T> onSelected;

  /// The group header over the items.
  final String? title;

  /// What a screen reader calls the menu; null says [title].
  final String? label;

  /// Opens a menu under the control [context] belongs to, over the whole
  /// app: the context of a [Builder] round that control, never the page's.
  /// [anchor] widens the box it drops from. Completes with the value
  /// chosen, or null when it is dismissed.
  static Future<T?> show<T>(
    BuildContext context, {
    required List<Fluent2MenuItem<T>> items,
    String? title,
    String? label,
    BuildContext? anchor,
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
        label: DesignLocalizations.of(context).modalBarrierDismissLabel,
        builder: (menuContext) => themes.wrap(
          Fluent2Menu<T>(
            items: items,
            title: title,
            label: label,
            onSelected: (value) => Navigator.of(menuContext).pop(value),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final head = title;
    final checks = items.any((i) => i.checked != null);
    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: label ?? head ?? Fluent2Localizations.of(context).menu,
      child: Material(
        type: MaterialType.transparency,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: Fluent2ChromeMetrics.menuMinWidth,
            maxWidth: Fluent2ChromeMetrics.menuMaxWidth,
          ),
          child: IntrinsicWidth(
            child: Container(
              padding: const EdgeInsets.all(Fluent2ChromeMetrics.menuPadding),
              decoration: BoxDecoration(
                color: t.colors.neutralBackground1,
                borderRadius: BorderRadius.circular(Fluent2Radius.medium),
                border: Border.all(
                  color: t.isDark
                      ? t.colors.neutralStroke2
                      : t.colors.transparentStroke,
                ),
                boxShadow: t.shadows.shadow16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (head != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
                      child: Text(
                        head,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.caption1Strong.c(t.textTertiary),
                      ),
                    ),
                  for (final item in items) ...[
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
                      onTap: item.enabled ? () => onSelected(item.value) : null,
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

class _MenuRow<T> extends StatelessWidget {
  const _MenuRow({
    required this.item,
    required this.checks,
    required this.onTap,
    super.key,
  });

  final Fluent2MenuItem<T> item;
  final bool checks;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Fluent2Pressable(
      onPressed: onTap,
      label: item.label,
      value: item.secondary,
      selected: item.checked,
      radius: Fluent2Radius.medium,
      builder: (context, states) => Fluent2MenuRowFace(
        label: item.label,
        states: states,
        icon: item.icon,
        secondary: item.secondary,
        checks: checks,
        checked: item.checked == true,
        danger: item.danger,
      ),
    );
  }
}

/// A menu row's face, Fluent's `MenuItem`: 32 tall on the desktop and 44 on
/// a phone, the check column when [checks], the glyph 20 in the second ink,
/// the words in body1, [secondary] in the third ink at the end, a chevron
/// when [submenu]. Hover and press step the fill and turn the glyph brand; a
/// face a behaviour drives by key draws its ring from [ring] with the focused
/// state. The rows of the menu, the command palette and the menu bar are this
/// one face.
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
    final wide = Fluent2Layout.popsOver(context);
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
    return fluent2EasedInks(
      [
        ink,
        glyph,
        press.pick(
          t.colors.neutralBackground1,
          t.colors.neutralBackground1Hover,
          t.colors.neutralBackground1Pressed,
          t.colors.neutralBackground1,
        ),
      ],
      (context, inks) {
        final [ink, glyph, rowFill] = inks;
        final face = Container(
          constraints: BoxConstraints(
            minHeight: wide
                ? Fluent2ChromeMetrics.menuItem
                : Fluent2ChromeMetrics.menuItemTouch,
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
                      ? Icon(Fluent2Icons.checkmark16, size: 16, color: glyph)
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
        if (!ring || !states.focused) return face;
        return Stack(
          fit: StackFit.passthrough,
          children: [
            face,
            const Positioned.fill(
              child: IgnorePointer(
                child: Fluent2FocusRing(radius: Fluent2Radius.medium),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// The route a menu rides: no overlay, dismissed by a tap outside, laid
/// out under its anchor.
class _MenuRoute<T> extends PopupRoute<T> {
  _MenuRoute({
    required this.anchor,
    required this.label,
    required this.builder,
  });

  final Rect anchor;
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
    opacity: CurvedAnimation(
      parent: animation,
      curve: Fluent2Motion.decelerateMid,
    ),
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
