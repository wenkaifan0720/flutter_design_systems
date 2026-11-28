/// Clay's floating surfaces anchored to a part: a menu under a key, a
/// context menu at the pointer, a popover, a hover card and a tooltip, each
/// a small slab of clay floating over the page.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'fonts.dart';
import 'internal/corners.dart';
import 'internal/menu.dart';
import 'select.dart' show ClayMenuReveal;
import 'surface.dart';
import 'theme.dart';

/// One item of a [ClayMenu], a [ClayContextMenu] or a menu bar's menu.
@immutable
class ClayMenuItem {
  /// An item named [label] that does [onPressed]; null shows it off.
  const ClayMenuItem({
    required this.label,
    required this.onPressed,
    this.icon,
    this.shortcut,
    this.isDestructiveAction = false,
  });

  /// Its words.
  final String label;

  /// What it does; null shows it off.
  final VoidCallback? onPressed;

  /// Its glyph, before the words.
  final IconData? icon;

  /// Its keys, as the reader's keyboard writes them (⌘D).
  final String? shortcut;

  /// Whether it destroys something: its words in the danger ink.
  final bool isDestructiveAction;

  @override
  String toString() => 'ClayMenuItem($label)';
}

/// The narrowest and widest a key's menu stands.
const double _menuMinWidth = 160;
const double _menuMaxWidth = 320;

/// A menu that floats under the key [builder] makes: a slab of clay, its
/// items as rows that dent under the pointer and the keys. Down on the key
/// opens it; the arrows walk it; Escape closes it. A tooltip on the key
/// stays down while the menu is open.
///
/// ```dart
/// ClayMenu(items: [ClayMenuItem(label: 'Edit', onPressed: () {})], builder: (context, toggle, open) => ClayIconButton(onPressed: toggle, icon: const Icon(IconData(0x2026)), tooltip: 'More'))
/// ```
class ClayMenu extends StatelessWidget {
  /// A menu of [items] under [builder]'s key.
  const ClayMenu({
    super.key,
    required this.items,
    required this.builder,
    this.semanticLabel,
    this.alignEnd = false,
    this.style,
  });

  /// What it holds.
  final List<ClayMenuItem> items;

  /// The key that opens it: given the toggle and whether it is open.
  final Widget Function(BuildContext context, VoidCallback toggle, bool open)
  builder;

  /// What a screen reader calls the menu.
  final String? semanticLabel;

  /// Whether it lines up with the key's end rather than its start.
  final bool alignEnd;

  /// This menu's own style, over [ClayThemeData.menuStyle].
  final ClayStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    return RawPopover(
      arrowKeyNavigation: true,
      semanticLabel: semanticLabel,
      placement: RawPopoverPlacement(
        align: alignEnd ? RawPopoverAlign.end : RawPopoverAlign.start,
        gap: ClaySpacing.small,
        margin: ClaySpacing.small,
        matchAnchorWidth: false,
      ),
      dampingRatio: ClayMotion.panelDamping,
      stiffness: ClayMotion.panelStiffness,
      anchorBuilder: (context, anchor) => Focus(
        canRequestFocus: false,
        skipTraversal: true,
        includeSemantics: false,
        onKeyEvent: (node, event) {
          if (event is! KeyDownEvent ||
              event.logicalKey != LogicalKeyboardKey.arrowDown ||
              anchor.isOpen) {
            return KeyEventResult.ignored;
          }
          anchor.open();
          return KeyEventResult.handled;
        },
        child: _Opened(
          open: anchor.isOpen,
          child: builder(context, anchor.toggle, anchor.isOpen),
        ),
      ),
      overlayBuilder: (context, info) => ClayMenuReveal(
        info: info,
        // As wide as its widest row, within a menu's measures: a key's menu
        // is not as wide as the window.
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: _menuMinWidth,
            maxWidth: _menuMaxWidth,
          ),
          child: IntrinsicWidth(
            child: ClayMenuList<int>(
              entries: [
                for (final (i, item) in items.indexed)
                  ClayMenuEntry(
                    value: i,
                    label: item.label,
                    leading: item.icon == null ? null : Icon(item.icon),
                    enabled: item.onPressed != null,
                    isDestructiveAction: item.isDestructiveAction,
                  ),
              ],
              rowHeight: theme.controlHeight,
              maxHeight: info.maxSize.height.clamp(120.0, 360.0),
              style: style,
              onChosen: (i) {
                info.close();
                items[i].onPressed?.call();
              },
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
      ..add(IntProperty('items', items.length))
      ..add(FlagProperty('alignEnd', value: alignEnd, ifTrue: 'end'));
  }
}

/// A menu at the pointer: a right click, a long press, or the keyboard's
/// menu key on [child] floats [items] there on a slab of clay.
///
/// ```dart
/// ClayContextMenu(items: [ClayMenuItem(label: 'Pause', onPressed: () {})], child: const Text('Drink water'))
/// ```
class ClayContextMenu extends StatelessWidget {
  /// [items] for a menu at the pointer over [child].
  const ClayContextMenu({
    super.key,
    required this.items,
    required this.child,
    this.semanticLabel,
    this.style,
  });

  /// What it holds.
  final List<ClayMenuItem> items;

  /// What it is the menu of.
  final Widget child;

  /// What a screen reader calls the menu.
  final String? semanticLabel;

  /// This menu's own style, over [ClayThemeData.contextMenuStyle]: `fill`
  /// the slab its rows float on.
  final ClayStyle? style;

  @override
  Widget build(BuildContext context) => RawContextMenu(
    semanticLabel: semanticLabel,
    dampingRatio: ClayMotion.panelDamping,
    stiffness: ClayMotion.panelStiffness,
    menuChildren: [
      for (final item in items)
        RawMenuEntry(
          label: item.label,
          onPressed: item.onPressed,
          shortcut: item.shortcut,
          isDestructiveAction: item.isDestructiveAction,
          data: item,
        ),
    ],
    itemBuilder: (context, entry, level, states) {
      final item = entry.data as ClayMenuItem?;
      return ClayMenuRow(
        label: entry.label,
        leading: item?.icon == null ? null : Icon(item!.icon),
        isDestructiveAction: entry.isDestructiveAction,
        states: states,
        trailing: entry.shortcut == null ? null : Text(entry.shortcut!),
      );
    },
    surfaceBuilder: (context, info, rows) => ClayMenuReveal(
      info: info,
      child: clayMenuPanel(
        context,
        rows,
        maxHeight: info.maxSize.height.clamp(120.0, 420.0),
        fill: RawStyleOf([
          style,
          ClayTheme.of(context).contextMenuStyle,
        ], const {}).fill,
      ),
    ),
    child: child,
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('items', items.length));
  }
}

/// A small slab of floating clay holding [child], [width] wide.
class _Card extends StatelessWidget {
  const _Card({required this.width, required this.style, required this.child});

  final double width;
  final ClayStyle? style;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    final c = theme.colors;
    final layered = RawStyleOf([style, theme.popoverStyle], const {});
    return SizedBox(
      width: width,
      child: ClaySurface(
        face: clayMenuFace(theme).copyWith(
          color: layered.fill,
          radius: clayCornerRadius(theme, layered, RawCorner.large),
        ),
        child: Padding(
          padding:
              layered.padding(Directionality.of(context)) ??
              const EdgeInsets.all(ClaySpacing.regular),
          child: DefaultTextStyle.merge(
            style: theme.textTheme.body
                .copyWith(color: layered.foreground ?? c.ink)
                .merge(layered.textStyle),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// A popover: a small slab of clay floating beside the key [builder]
/// makes, holding [content]; a tap beside it or Escape closes it. A
/// tooltip on the key stays down while the popover is open.
///
/// ```dart
/// ClayPopover(builder: (context, toggle, open) => ClayButton('Streak', onPressed: toggle), content: (context, close) => const Text('Twelve days running'))
/// ```
class ClayPopover extends StatelessWidget {
  /// A popover of [content] beside [builder]'s key.
  const ClayPopover({
    super.key,
    required this.builder,
    required this.content,
    this.side = RawPopoverSide.below,
    this.width = 280,
    this.semanticLabel,
    this.style,
  });

  /// The key that opens it: given the toggle and whether it is open.
  final Widget Function(BuildContext context, VoidCallback toggle, bool open)
  builder;

  /// What it holds, given a way to close it.
  final Widget Function(BuildContext context, VoidCallback close) content;

  /// Which side of the key it floats on.
  final RawPopoverSide side;

  /// Its width.
  final double width;

  /// What a screen reader calls it.
  final String? semanticLabel;

  /// This popover's own style, over [ClayThemeData.popoverStyle].
  final ClayStyle? style;

  @override
  Widget build(BuildContext context) => RawPopover(
    semanticLabel: semanticLabel,
    placement: RawPopoverPlacement(
      side: side,
      gap: ClaySpacing.small,
      margin: ClaySpacing.small,
      matchAnchorWidth: false,
    ),
    dampingRatio: ClayMotion.panelDamping,
    stiffness: ClayMotion.panelStiffness,
    anchorBuilder: (context, anchor) => _Opened(
      open: anchor.isOpen,
      child: builder(context, anchor.toggle, anchor.isOpen),
    ),
    overlayBuilder: (context, info) => ClayMenuReveal(
      info: info,
      child: _Card(
        width: width,
        style: style,
        child: Builder(builder: (context) => content(context, info.close)),
      ),
    ),
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(EnumProperty<RawPopoverSide>('side', side))
      ..add(DoubleProperty('width', width));
  }
}

/// A hover card: a slab of clay that floats under [child] while the pointer
/// rests on it (or the keys are on it), holding [content].
///
/// ```dart
/// ClayHoverCard(content: (context) => const Text('Mia, 41-day streak'), child: ClayLink('Mia', onPressed: () {}))
/// ```
class ClayHoverCard extends StatelessWidget {
  /// A card of [content] over [child].
  const ClayHoverCard({
    super.key,
    required this.child,
    required this.content,
    this.width = 280,
    this.semanticLabel,
    this.style,
  });

  /// What it is the card of.
  final Widget child;

  /// What it holds.
  final WidgetBuilder content;

  /// Its width.
  final double width;

  /// What a screen reader calls it.
  final String? semanticLabel;

  /// This card's own style, over [ClayThemeData.popoverStyle].
  final ClayStyle? style;

  @override
  Widget build(BuildContext context) => RawPopover(
    trigger: RawPopoverTrigger.hover,
    focusOnOpen: false,
    semanticLabel: semanticLabel,
    placement: const RawPopoverPlacement(
      gap: ClaySpacing.small,
      margin: ClaySpacing.small,
      matchAnchorWidth: false,
    ),
    dampingRatio: ClayMotion.panelDamping,
    stiffness: ClayMotion.panelStiffness,
    anchorBuilder: (context, anchor) => child,
    overlayBuilder: (context, info) => ClayMenuReveal(
      info: info,
      child: _Card(
        width: width,
        style: style,
        child: Builder(builder: content),
      ),
    ),
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('width', width));
  }
}

/// A tooltip: a small dark slab of clay with [message], floating above
/// [child] once the pointer rests on it, or on a long press. One shows at a
/// time; Escape hides it, and it stays down while a [ClayMenu] or
/// [ClayPopover] that [child] opened is open. Where no overlay stands over it (a toast's key,
/// over the app's navigator) it shows nothing and names [child] for a
/// screen reader alone.
///
/// ```dart
/// ClayTooltip(message: 'Streak so far', child: const Text('12'))
/// ```
class ClayTooltip extends StatelessWidget {
  /// A tooltip saying [message] over [child].
  const ClayTooltip({
    super.key,
    required this.message,
    required this.child,
    this.style,
  });

  /// What it says.
  final String message;

  /// What it is the tooltip of.
  final Widget child;

  /// This tooltip's own style, over [ClayThemeData.tooltipStyle].
  final ClayStyle? style;

  @override
  Widget build(BuildContext context) {
    // Over the app's navigator (a toast's key) no overlay stands to show a
    // tip in: the words name the child for a screen reader alone.
    if (Overlay.maybeOf(context) == null) {
      return MergeSemantics(
        child: Semantics(tooltip: message, child: child),
      );
    }
    return _tip(context);
  }

  Widget _tip(BuildContext context) => RawTooltipPlacement(
    placement: const RawPopoverPlacement(
      side: RawPopoverSide.above,
      align: RawPopoverAlign.center,
      gap: 6,
      margin: ClaySpacing.small,
      matchAnchorWidth: false,
    ),
    // One node with the control: RawTooltip's tooltip doesn't merge, so
    // without this a screen reader hears the tip on an ancestor and the
    // control alone ('Save' for 'Save to your recipes, Save').
    builder: (context, positionDelegate) => MergeSemantics(
      child: RawTooltip(
        semanticsTooltip: message,
        hoverDelay: const Duration(milliseconds: 500),
        dismissDelay: const Duration(milliseconds: 80),
        // The tip arrives and goes on a spring of its own (_TipPresence): the
        // tooltip's animation says only whether it shows, at once, and keeps
        // the tip up for as long as the spring takes it away (about 230 ms).
        animationStyle: const AnimationStyle(
          duration: Duration.zero,
          reverseDuration: Duration(milliseconds: 300),
        ),
        positionDelegate: positionDelegate,
        // Down while the menu or popover its control opened is open: a
        // click on the web with its semantics on reaches the control as the
        // tree's tap, and the tip hears no pointer go down to hide it.
        tooltipBuilder: (context, shown) => _Opened.isOpen(context)
            ? const SizedBox.shrink()
            : _TipPresence(
                shown: shown,
                builder: (context, presence) => _TipReveal(
                  presence: presence,
                  above:
                      (RawTooltipPlacement.sideOf(context) ??
                          RawPopoverSide.above) ==
                      RawPopoverSide.above,
                  child: _Tip(message: message, style: style),
                ),
              ),
        child: RawTooltipFocusFix(child: child),
      ),
    ),
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('message', message));
  }
}

/// Whether the menu or popover that the control under it opens is open: a
/// tip on that control stays down while it is, never over what it opened.
class _Opened extends InheritedWidget {
  const _Opened({required this.open, required super.child});

  final bool open;

  static bool isOpen(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_Opened>()?.open ?? false;

  @override
  bool updateShouldNotify(_Opened old) => open != old.open;
}

/// The tip's presence: to 1 on an effects spring while [shown] says it
/// shows, back to 0 as it goes (critically damped, stiffness 1600; Reduce
/// Motion honoured), from wherever it was.
class _TipPresence extends StatefulWidget {
  const _TipPresence({required this.shown, required this.builder});

  final Animation<double> shown;
  final Widget Function(BuildContext context, Animation<double> presence)
  builder;

  @override
  State<_TipPresence> createState() => _TipPresenceState();
}

class _TipPresenceState extends State<_TipPresence>
    with SingleTickerProviderStateMixin {
  late final AnimationController _presence = AnimationController(vsync: this);
  bool? _showing;

  @override
  void initState() {
    super.initState();
    widget.shown.addStatusListener(_follow);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_showing == null) _follow(widget.shown.status);
  }

  @override
  void didUpdateWidget(_TipPresence old) {
    super.didUpdateWidget(old);
    if (old.shown != widget.shown) {
      old.shown.removeStatusListener(_follow);
      widget.shown.addStatusListener(_follow);
      _follow(widget.shown.status);
    }
  }

  void _follow(AnimationStatus status) {
    final showing = status.isForwardOrCompleted;
    if (showing == _showing) return;
    _showing = showing;
    _presence.springTo(
      showing ? 1 : 0,
      RawMotionPolicy.of(context).effects(dampingRatio: 1, stiffness: 1600),
    );
  }

  @override
  void dispose() {
    widget.shown.removeStatusListener(_follow);
    _presence.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _presence);
}

/// The tip arriving as Clay's floating lists do ([ClayMenuReveal]): it grows
/// from 96% of its size toward the control, on [presence], opaque from its
/// first frame. A
/// screen reader hears the words as the control's tooltip, so the tip itself
/// is left out.
class _TipReveal extends StatelessWidget {
  const _TipReveal({
    required this.presence,
    required this.above,
    required this.child,
  });

  final Animation<double> presence;
  final bool above;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: presence,
    child: ExcludeSemantics(child: child),
    builder: (context, child) {
      final t = presence.value.clamp(0.0, 1.0);
      return Transform.scale(
        scale: 0.96 + 0.04 * t,
        alignment: above
            ? AlignmentDirectional.bottomStart
            : AlignmentDirectional.topStart,
        child: child,
      );
    },
  );
}

class _Tip extends StatelessWidget {
  const _Tip({required this.message, required this.style});

  final String message;
  final ClayStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    final c = theme.colors;
    final layered = RawStyleOf([style, theme.tooltipStyle], const {});
    final fill = layered.fill ?? c.inverse;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 260),
      child: ClaySurface(
        face: ClayFace.raised(
          c,
          color: fill,
          radius: theme.shapeScheme.corners.small + 3,
        ).copyWith(elevation: 0.8),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: ClaySpacing.medium,
            vertical: ClaySpacing.small - 2,
          ),
          child: Text(
            message,
            style: theme.textTheme.caption
                .copyWith(
                  color: layered.foreground ?? c.onColor(fill),
                  fontWeight: FontWeight.w500,
                  fontVariations: clayWeight(FontWeight.w500),
                )
                .merge(layered.textStyle),
          ),
        ),
      ),
    );
  }
}
