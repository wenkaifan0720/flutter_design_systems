/// Anchored action menus and their items, and the anchored popover every
/// Minimal control that opens in place shares (a picker's menu, a date
/// picker's calendar).
library;

import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../chrome_metrics.dart';
import '../component_themes.dart';
import '../internal/cap_label.dart';
import '../internal/controls.dart';
import '../internal/kit_paint.dart';
import '../internal/styled.dart';
import '../localizations.dart';
import '../shapes.dart';
import '../theme.dart';
import 'code.dart';
import 'pressable.dart';

/// One menu action, optionally checked, destructive, disabled, carrying a
/// keyboard shortcut or starting a new group; a null [onPressed] disables it.
///
/// ```dart
/// MinimalMenuItem('Rename', icon: LucideIcons.pencil, shortcut: 'R', onPressed: rename)
/// ```
@immutable
class MinimalMenuItem {
  /// A menu item saying [label].
  const MinimalMenuItem(
    this.label, {
    this.onPressed,
    this.icon,
    this.selected = false,
    this.destructive = false,
    this.startsGroup = false,
    this.shortcut,
  });

  /// What it says.
  final String label;

  /// What the item performs once the menu has closed; null disables it.
  final VoidCallback? onPressed;

  /// A glyph before the label.
  final IconData? icon;

  /// The current choice of a menu that picks one: a check at the end.
  final bool selected;

  /// The destructive register: the label and glyph in the destructive ink.
  final bool destructive;

  /// Draw a hairline above this item, opening a new group.
  final bool startsGroup;

  /// The key that performs it elsewhere, printed as key caps at the end,
  /// one per space-separated key (`⌘ D`, `R`): a hint, not a binding.
  final String? shortcut;
}

/// How a [MinimalMenu] opens: a tap on its child, or a long press that leaves
/// the child's ordinary tap to the child (a row's context menu).
enum MinimalMenuTrigger {
  /// A tap on the child.
  tap,

  /// A long press, leaving the child's tap to the child.
  longPress,
}

/// Anchored actions and checked choices: a compact card on the surface, a
/// hairline all round and a menu's shadow, of 32 px items — a glyph, the
/// label, a mono shortcut, a check for the current choice. It opens under
/// the control (above it when the space is below is short), aligned to the
/// control's nearer edge, fades in over [MinimalMotion.fast], and closes on a
/// choice, a tap outside or Escape. The arrow keys walk the items.
///
/// `trigger: longPress` adds a context menu to content while its ordinary
/// tap stays the content's own: the content takes the press wash while
/// held, and from the keyboard it is a focus stop that Shift+F10 or the
/// context-menu key opens.
///
/// [MinimalMenu.button] draws the kit's own trigger, so a page never draws
/// one: a glyph alone is the 32 px outlined square a bar action wears; a
/// glyph with [text] is a pill of the same height holding the current choice
/// and a disclosure chevron (`Sort: Streak ▾`). `small` takes both to 28,
/// level with small buttons, chips and filters.
///
/// Menu items are 32 px and abut, so each takes its whole row of the card,
/// not a padded 44 px square: the dense list's exception.
///
/// [style] dresses this menu's card, `components.menu` every one: fill,
/// edge or side and shape (else `shapes.medium`). The items keep their
/// own register. The kit's trigger reads `shapes.small` and
/// `t.rim`, as a button does.
///
/// ```dart
/// MinimalMenu(label: 'Habit actions', items: [MinimalMenuItem('Rename', onPressed: rename)], child: moreGlyph)
/// ```
class MinimalMenu extends StatefulWidget {
  /// A menu of [items] opened from [child].
  const MinimalMenu({
    super.key,
    required this.items,
    required Widget this.child,
    this.trigger = MinimalMenuTrigger.tap,
    this.label,
    this.style,
  }) : icon = null,
       text = null,
       small = false;

  /// A menu on the kit's own trigger: [icon] alone in the outlined 32 px
  /// square, or with [text] a 32 px pill of the glyph and the words; 28 with
  /// [small].
  ///
  /// ```dart
  /// MinimalMenu.button(LucideIcons.arrowDownUp, text: 'Sort: $sort', label: 'Sort habits', items: sorts)
  /// ```
  const MinimalMenu.button(
    IconData this.icon, {
    super.key,
    required this.items,
    this.text,
    this.label,
    this.small = false,
    this.style,
  }) : child = null,
       trigger = MinimalMenuTrigger.tap;

  /// The items, top to bottom.
  final List<MinimalMenuItem> items;

  /// What opens the menu. Draw it plainly (a glyph, a line of text): the
  /// menu supplies the press feedback and the control semantics. Null on a
  /// [MinimalMenu.button], which draws its own.
  final Widget? child;

  /// What opens it: a tap or a long press.
  final MinimalMenuTrigger trigger;

  /// What the control announces, and what the open menu is named.
  final String? label;

  /// The glyph of a [MinimalMenu.button].
  final IconData? icon;

  /// The words of a [MinimalMenu.button]'s pill; null draws the square.
  final String? text;

  /// Whether a [MinimalMenu.button]'s square or pill is the small height
  /// (28, a small button's) rather than a button's (32).
  final bool small;

  /// The card's style, over `components.menu`.
  final MinimalStyle? style;

  /// The anchored card itself, holding whatever [builder] draws: the
  /// surface every Minimal control that opens in place shares (a menu, a
  /// calendar). Pops with a value through `Navigator.pop`; a tap outside or
  /// Escape pops with null. Mounted on the root navigator, carrying the
  /// caller's theme across.
  static Future<T?> popover<T>(
    BuildContext context, {
    required Rect anchor,
    required String label,
    required WidgetBuilder builder,
    double width = _MenuMetrics.width,
    MinimalStyle? style,
  }) {
    final navigator = Navigator.of(context, rootNavigator: true);
    // The route mounts on the ROOT navigator, which may sit above a host
    // that knows nothing of Minimal; carry the inherited themes across,
    // as showDialog and showModalBottomSheet do. The card itself is built
    // inside them too, so its surface and its content read one scope.
    final themes = InheritedTheme.capture(from: context, to: navigator.context);
    final still = context.minimalStill;
    return navigator.push<T>(
      _PopoverRoute<T>(
        anchor: anchor,
        label: label,
        dismissLabel: '${MinimalLocalizations.of(context).dismiss} $label',
        width: width,
        duration: still ? Duration.zero : MinimalMotion.fast,
        themes: themes,
        builder: builder,
        style: style,
      ),
    );
  }

  @override
  State<MinimalMenu> createState() => _MinimalMenuState();
}

/// Present a [MinimalMenu]'s anchored menu from any control — a picker row, a
/// property pill, a button whose [anchor] the caller measured. The card is
/// [width] wide, or as wide as [anchor] where that is wider. Runs the
/// chosen item's [MinimalMenuItem.onPressed] after the menu has closed.
Future<void> showMinimalMenu(
  BuildContext context, {
  required Rect anchor,
  required List<MinimalMenuItem> items,
  String? label,
  double width = _MenuMetrics.width,
  MinimalStyle? style,
}) async {
  if (items.isEmpty) return;
  final chosen = await MinimalMenu.popover<int>(
    context,
    anchor: anchor,
    label: label ?? MinimalLocalizations.of(context).actions,
    // Never narrower than what opened it: a list from a select's value or
    // an expanded button covers that control's width.
    width: math.max(width, anchor.width),
    style: style,
    builder: (context) => _MenuSurface(items: items),
  );
  if (chosen != null) items[chosen].onPressed?.call();
}

class _MinimalMenuState extends State<MinimalMenu> {
  bool _open = false;

  Future<void> _show() async {
    if (_open || widget.items.isEmpty) return;
    final box = context.findRenderObject()! as RenderBox;
    _open = true;
    await showMinimalMenu(
      context,
      anchor: box.localToGlobal(Offset.zero) & box.size,
      items: widget.items,
      label: widget.label ?? MinimalLocalizations.of(context).moreActions,
      style: widget.style,
    );
    _open = false;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final icon = widget.icon;
    final text = widget.text;
    final side = widget.small
        ? MinimalChromeMetrics.controlSm
        : MinimalChromeMetrics.barControl;
    final child =
        widget.child ??
        (text == null
            // The icon button's square, at the theme's density.
            ? Container(
                width: t.density.height(side),
                height: t.density.height(side),
                decoration: minimalFrame(
                  t.shapes.small,
                  fill: t.background,
                  side: BorderSide(color: t.border, width: t.rim),
                ),
                child: MinimalIcon(icon!, color: t.foreground),
              )
            // The square's height, at the theme's density: the pill stands
            // level with the squares and buttons beside it.
            : Container(
                constraints: BoxConstraints(minHeight: t.density.height(side)),
                padding: const EdgeInsets.symmetric(
                  horizontal: MinimalControlMetrics.pillPadGlyph,
                ),
                // A trigger in a hairline on the ground, as the menu's
                // square is; no grey well.
                decoration: minimalFrame(
                  _pill(t),
                  side: BorderSide(color: t.border, width: t.rim),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MinimalIcon(
                      icon!,
                      size: MinimalIconSize.i14,
                      color: t.foreground,
                    ),
                    const MinimalGap(MinimalChromeMetrics.iconGap),
                    Flexible(
                      child: minimalCapLabel(
                        Text(
                          text,
                          style: t.control.copyWith(
                            fontSize: MinimalControlMetrics.pillLabel,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    // The disclosure mark: the pill opens a menu.
                    const MinimalGap(MinimalSpacing.s4),
                    MinimalIcon(
                      LucideIcons.chevronDown,
                      size: _MenuMetrics.chevron,
                      color: t.textTertiary,
                    ),
                  ],
                ),
              ));
    if (widget.trigger == MinimalMenuTrigger.tap) {
      final trigger = MinimalPressable(
        onPressed: _show,
        enabled: widget.items.isNotEmpty,
        semanticLabel:
            widget.label ?? MinimalLocalizations.of(context).moreActions,
        shape: text == null ? t.shapes.small : _pill(t),
        child: child,
      );
      // The kit's own square or pill keeps the width of what it shows,
      // whatever stretches it, from the compact width up, as a button does.
      return widget.child == null
          ? MinimalLayout.holdWidth(context, trigger)
          : trigger;
    }
    return _ContextTrigger(
      label: widget.label ?? MinimalLocalizations.of(context).moreActions,
      onOpen: _show,
      enabled: widget.items.isNotEmpty,
      child: child,
    );
  }
}

/// A pill's outline: a hair inside `shapes.small`, as a chip's.
OutlinedBorder _pill(MinimalThemeData t) =>
    MinimalShapes.inset(t.shapes.small, 1);

/// Opens a context menu: Shift+F10 or the context-menu key.
class _OpenMenuIntent extends Intent {
  const _OpenMenuIntent();
}

/// The long-press trigger: the content keeps its own tap; a long press
/// opens the menu, with the pressable's wash while the finger is held. It
/// is a focus stop that draws the kit's ring under keyboard focus and
/// opens on Shift+F10 or the context-menu key, and a screen reader reaches
/// it as a custom action named [label].
class _ContextTrigger extends StatefulWidget {
  const _ContextTrigger({
    required this.label,
    required this.onOpen,
    required this.enabled,
    required this.child,
  });

  final String label;
  final VoidCallback onOpen;
  final bool enabled;
  final Widget child;

  @override
  State<_ContextTrigger> createState() => _ContextTriggerState();
}

class _ContextTriggerState extends State<_ContextTrigger> {
  bool _held = false;
  bool _focus = false;

  void _hold(bool held) {
    if (_held != held) setState(() => _held = held);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final enabled = widget.enabled;
    return Semantics(
      customSemanticsActions: enabled
          ? <CustomSemanticsAction, VoidCallback>{
              CustomSemanticsAction(label: widget.label): widget.onOpen,
            }
          : null,
      child: FocusableActionDetector(
        enabled: enabled,
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.f10, shift: true):
              _OpenMenuIntent(),
          SingleActivator(LogicalKeyboardKey.contextMenu): _OpenMenuIntent(),
        },
        actions: <Type, Action<Intent>>{
          _OpenMenuIntent: CallbackAction<_OpenMenuIntent>(
            onInvoke: (_) {
              widget.onOpen();
              return null;
            },
          ),
        },
        onShowFocusHighlight: (v) => setState(() => _focus = v),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onLongPressDown: enabled ? (_) => _hold(true) : null,
          onLongPressCancel: enabled ? () => _hold(false) : null,
          onLongPressUp: enabled ? () => _hold(false) : null,
          onLongPress: enabled
              ? () {
                  _hold(false);
                  widget.onOpen();
                }
              : null,
          child: AnimatedContainer(
            duration: MinimalMotion.fast,
            curve: MinimalMotion.out,
            foregroundDecoration: minimalRingFrame(
              t.shapes.small,
              wash: t.foreground.withValues(alpha: _held ? 0.08 : 0),
              ring: _focus && enabled ? t.ring : null,
              ground: minimalGround(context),
              width: t.focusWidth,
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// The menu card's geometry: an item's height, the card's width when a
/// caller states none, the air between the control and the card, and
/// between the card and the screen's edges.
abstract final class _MenuMetrics {
  static const double itemHeight = 32;
  static const double width = 232;
  static const double gap = 4;
  static const double edge = 8;
  static const double chevron = 13;
}

/// The popover's route: a transparent, dismissible barrier and the card
/// laid out against the control that opened it. Minimal motion is a fade,
/// never a scale.
class _PopoverRoute<T> extends PopupRoute<T> {
  _PopoverRoute({
    required this.anchor,
    required this.label,
    required this.dismissLabel,
    required this.width,
    required this.duration,
    required this.themes,
    required this.builder,
    this.style,
  });

  final Rect anchor;
  final String label;

  /// What the scrim is called: a tap on it closes the card.
  final String dismissLabel;
  final double width;
  final Duration duration;
  final CapturedThemes themes;
  final WidgetBuilder builder;
  final MinimalStyle? style;

  @override
  Color? get barrierColor => null;

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => dismissLabel;

  @override
  Duration get transitionDuration => duration;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final m = MediaQuery.of(context);
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            Navigator.of(context).pop(),
      },
      child: CustomSingleChildLayout(
        delegate: _PopoverLayout(
          anchor: anchor,
          width: width,
          safe: EdgeInsets.fromLTRB(
            m.padding.left,
            m.padding.top,
            m.padding.right,
            math.max(m.padding.bottom, m.viewInsets.bottom),
          ),
        ),
        child: Semantics(
          container: true,
          namesRoute: true,
          explicitChildNodes: true,
          label: label,
          child: themes.wrap(
            Builder(
              builder: (context) {
                final t = context.minimalTheme;
                final so = MinimalStyleOf([style, t.components.menu], const {});
                final shape = so.shape ?? t.shapes.medium;
                return Material(
                  type: MaterialType.transparency,
                  child: Container(
                    decoration: minimalFrame(
                      shape,
                      fill: so.fill ?? t.card,
                      side: so.rim(t.border, t.rim),
                      shadows: t.shadowMd,
                    ),
                    child: minimalClip(
                      shape,
                      child: DefaultTextStyle(
                        style: t.body,
                        child: SingleChildScrollView(child: builder(context)),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => FadeTransition(
    opacity: animation.drive(CurveTween(curve: MinimalMotion.out)),
    child: child,
  );
}

/// Places the card under the control, or above it when the room below is
/// short and the room above is larger; aligned to the control's nearer
/// edge; never past the safe area or the keyboard.
class _PopoverLayout extends SingleChildLayoutDelegate {
  const _PopoverLayout({
    required this.anchor,
    required this.width,
    required this.safe,
  });

  final Rect anchor;
  final double width;
  final EdgeInsets safe;

  double _top() => safe.top + _MenuMetrics.edge;
  double _bottom(Size size) => size.height - safe.bottom - _MenuMetrics.edge;
  double _below(Size size) => _bottom(size) - anchor.bottom - _MenuMetrics.gap;
  double _above() => anchor.top - _MenuMetrics.gap - _top();

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final size = constraints.biggest;
    final w = math.min(
      width,
      size.width - safe.horizontal - 2 * _MenuMetrics.edge,
    );
    final room = math.max(_below(size), _above());
    return BoxConstraints.tightFor(width: math.max(0, w)).copyWith(
      maxHeight: room.clamp(MinimalLayout.minHitTarget, _bottom(size) - _top()),
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final top = _top();
    final lowest = math.max(top, _bottom(size) - childSize.height);
    final y = childSize.height <= _below(size) || _below(size) >= _above()
        ? anchor.bottom + _MenuMetrics.gap
        : anchor.top - _MenuMetrics.gap - childSize.height;
    final minX = safe.left + _MenuMetrics.edge;
    final maxX = math.max(
      minX,
      size.width - safe.right - _MenuMetrics.edge - childSize.width,
    );
    // On the control's leading edge wherever the card fits there (a list
    // from a field starts where the field does); else ending on its far
    // edge, as from a toolbar's last button.
    final x = anchor.left <= maxX
        ? anchor.left
        : anchor.right - childSize.width;
    return Offset(x.clamp(minX, maxX), y.clamp(top, lowest));
  }

  @override
  bool shouldRelayout(_PopoverLayout old) =>
      anchor != old.anchor || width != old.width || safe != old.safe;
}

/// The menu's items in the card, walked by the arrow keys.
class _MenuSurface extends StatelessWidget {
  const _MenuSurface({required this.items});

  final List<MinimalMenuItem> items;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    // A menu that picks one announces every item's selected state; a menu
    // of plain actions announces none.
    final choosing = items.any((item) => item.selected);
    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.arrowDown): NextFocusIntent(),
        SingleActivator(LogicalKeyboardKey.arrowUp): PreviousFocusIntent(),
      },
      child: FocusTraversalGroup(
        child: Padding(
          padding: const EdgeInsets.all(MinimalSpacing.s4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, item) in items.indexed) ...[
                if (i > 0 && item.startsGroup)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: MinimalSpacing.s4,
                    ),
                    child: Container(height: t.hairline, color: t.border),
                  ),
                _MenuAction(
                  item: item,
                  choosing: choosing,
                  onPressed: () => Navigator.of(context).pop(i),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// One 32 px item. Its box clips the pressable's padded hit area, so two
/// abutting items never take each other's taps.
class _MenuAction extends StatelessWidget {
  const _MenuAction({
    required this.item,
    required this.choosing,
    required this.onPressed,
  });

  final MinimalMenuItem item;
  final bool choosing;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final ink = item.destructive ? t.destructiveInk : t.foreground;
    final enabled = item.onPressed != null;
    final shortcut = item.shortcut;
    final icon = item.icon;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: _MenuMetrics.itemHeight),
      child: MinimalPressable(
        onPressed: enabled ? onPressed : null,
        enabled: enabled,
        shape: MinimalShapes.inset(t.shapes.medium, MinimalSpacing.s4),
        selected: choosing ? item.selected : null,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: _MenuMetrics.itemHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: MinimalSpacing.s8,
              vertical: MinimalSpacing.s4,
            ),
            child: Row(
              children: [
                if (icon != null) ...[
                  MinimalIcon(
                    icon,
                    size: MinimalIconSize.i16,
                    color: item.destructive
                        ? t.destructiveInk
                        : t.mutedForeground,
                  ),
                  const MinimalGap(MinimalSpacing.s8),
                ],
                Expanded(
                  child: minimalCapLabel(
                    Text(
                      item.label,
                      style: t.bodySmall.c(ink),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                if (shortcut != null) ...[
                  const MinimalGap(MinimalSpacing.s8),
                  MinimalKbd.chord(shortcut),
                ],
                if (item.selected) ...[
                  const MinimalGap(MinimalSpacing.s8),
                  MinimalIcon(
                    LucideIcons.check,
                    size: MinimalIconSize.i16,
                    color: t.primaryInk,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
