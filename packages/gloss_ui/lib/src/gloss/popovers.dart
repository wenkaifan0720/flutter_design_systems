/// Gloss's anchored surfaces: the menu, the popover and the hover card,
/// porcelain panels raised beside what opened them, and the tooltip, a
/// smoke-gel capsule.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'fonts.dart';
import 'internal/menu_parts.dart';
import 'surface.dart';
import 'theme.dart';

/// One row of a [GlossMenu].
@immutable
class GlossMenuItem {
  /// A row named [label] that does [onPressed]; null disables it.
  const GlossMenuItem({
    required this.label,
    required this.onPressed,
    this.icon,
    this.shortcut,
    this.isDestructiveAction = false,
  });

  /// What the row says.
  final String label;

  /// What it does; the menu closes first. Null disables it.
  final VoidCallback? onPressed;

  /// Its glyph, before its words.
  final IconData? icon;

  /// The keys that do it too, written at the row's end (⌘D).
  final String? shortcut;

  /// Whether it destroys something: its words take the danger ink.
  final bool isDestructiveAction;
}

/// A row on a Gloss menu's panel for its [states]: clear at rest, a pale
/// glazed plate under the pointer or the keys, pressed into a well under a
/// press. Menus, the menubar and the split key's list draw their rows with
/// it.
class GlossMenuRow extends StatelessWidget {
  /// A row reading [label].
  const GlossMenuRow({
    super.key,
    required this.label,
    required this.states,
    this.icon,
    this.trailing,
    this.isDestructiveAction = false,
    this.checked = false,
    this.style,
  });

  /// What it says.
  final String label;

  /// Its states: hovered or focused lights it, pressed sinks it.
  final Set<WidgetState> states;

  /// Its glyph.
  final IconData? icon;

  /// At its end: a shortcut's words, a chevron to a submenu.
  final Widget? trailing;

  /// Whether its words take the danger ink.
  final bool isDestructiveAction;

  /// Whether it is ticked (a menu of options).
  final bool checked;

  /// This row's own style, over [GlossThemeData.menuStyle].
  final GlossStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = GlossTheme.of(context);
    final c = theme.colors;
    final layered = DesignStyleOf([style, theme.menuStyle], states);
    final disabled = states.contains(WidgetState.disabled);
    final ink =
        layered.foreground ??
        (disabled
            ? c.inkDisabled
            : isDestructiveAction
            ? c.danger
            : checked
            ? c.jadeInk
            : c.ink);
    final focused = !disabled && states.contains(WidgetState.focused);
    var plate = glossRowPlate(
      c,
      lit: focused || (!disabled && states.contains(WidgetState.hovered)),
      pressed: states.contains(WidgetState.pressed),
    );
    if (layered.fill != null) plate = plate.glazed(layered.fill!);
    return SizedBox(
      height: layered.minimumSize?.height ?? theme.controlHeight - 4,
      child: GlossFocusHalo(
        focused: focused,
        inside: true,
        radius: glossPanelCorner - glossPanelInset,
        child: AnimatedGlossSurface(
          face: plate.copyWith(foreground: ink),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: GlossSpacing.medium,
            ),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: layered.iconSize ?? 18, color: ink),
                  const SizedBox(width: GlossSpacing.medium),
                ],
                Expanded(
                  child: DesignCapCenter(
                    capHeightFactor: glossCapHeightFactor,
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.body
                          .copyWith(color: ink)
                          .merge(layered.textStyle),
                    ),
                  ),
                ),
                if (checked) ...[
                  const SizedBox(width: GlossSpacing.medium),
                  SizedBox.square(
                    dimension: 16,
                    child: CustomPaint(painter: _TickPainter(ink)),
                  ),
                ],
                if (trailing != null) ...[
                  const SizedBox(width: GlossSpacing.large),
                  DefaultTextStyle(
                    style: theme.textTheme.secondary.copyWith(
                      color: disabled ? c.inkDisabled : c.inkSecondary,
                    ),
                    child: IconTheme.merge(
                      data: IconThemeData(size: 16, color: c.inkSecondary),
                      child: trailing!,
                    ),
                  ),
                ],
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
      ..add(StringProperty('label', label))
      ..add(IterableProperty<WidgetState>('states', states))
      ..add(
        FlagProperty(
          'isDestructiveAction',
          value: isDestructiveAction,
          ifTrue: 'destructive',
        ),
      )
      ..add(FlagProperty('checked', value: checked, ifTrue: 'checked'));
  }
}

class _TickPainter extends CustomPainter {
  _TickPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.18, w * 0.52)
        ..lineTo(w * 0.42, w * 0.74)
        ..lineTo(w * 0.84, w * 0.28),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_TickPainter old) => old.color != color;
}

/// The raised porcelain panel a menu's rows stand on, scrolling past
/// [maxHeight]; as wide as its widest row, at least [minWidth].
class GlossMenuPanel extends StatelessWidget {
  /// A panel of [children] (rows).
  const GlossMenuPanel({
    super.key,
    required this.children,
    this.maxHeight = 360,
    this.minWidth = 200,
  });

  /// The rows.
  final List<Widget> children;

  /// The tallest it grows before it scrolls.
  final double maxHeight;

  /// The narrowest it is.
  final double minWidth;

  @override
  Widget build(BuildContext context) {
    final c = GlossTheme.of(context).colors;
    return GlossSurface(
      face: glossPanelFace(c),
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: minWidth, maxHeight: maxHeight),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(glossPanelInset),
          child: IntrinsicWidth(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
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
      ..add(IntProperty('children', children.length))
      ..add(DoubleProperty('maxHeight', maxHeight));
  }
}

/// A panel's way in and out: it fades, and settles 6 px toward its anchor
/// as it opens.
Widget glossPanelArrival(DesignOverlayInfo info, Widget child) {
  final shown = info.animation.drive(
    Animatable<double>.fromCallback((v) => v.clamp(0.0, 1.0)),
  );
  final toward = switch (info.side) {
    DesignOverlaySide.below => const Offset(0, -6),
    DesignOverlaySide.above => const Offset(0, 6),
    DesignOverlaySide.start => const Offset(6, 0),
    DesignOverlaySide.end => const Offset(-6, 0),
  };
  return FadeTransition(
    opacity: shown,
    child: AnimatedBuilder(
      animation: info.animation,
      builder: (context, child) => Transform.translate(
        offset: toward * (1 - info.animation.value),
        child: child,
      ),
      child: child,
    ),
  );
}

/// The rows of an open menu: the pointer's row is the keys' row, and a
/// press closes the menu before the row's action.
class GlossMenuList extends StatefulWidget {
  /// The rows for [items], closing through [close].
  const GlossMenuList({
    super.key,
    required this.items,
    required this.close,
    this.maxHeight = 360,
    this.style,
  });

  /// The rows.
  final List<GlossMenuItem> items;

  /// Closes the menu.
  final VoidCallback close;

  /// The tallest the panel grows.
  final double maxHeight;

  /// The rows' style.
  final GlossStyle? style;

  @override
  State<GlossMenuList> createState() => _GlossMenuListState();
}

class _GlossMenuListState extends State<GlossMenuList> {
  late List<FocusNode> _nodes = _make();

  List<FocusNode> _make() => [
    for (final item in widget.items)
      FocusNode(debugLabel: 'GlossMenu ${item.label}'),
  ];

  @override
  void didUpdateWidget(GlossMenuList old) {
    super.didUpdateWidget(old);
    if (old.items.length != widget.items.length) {
      for (final node in _nodes) {
        node.dispose();
      }
      _nodes = _make();
    }
  }

  @override
  void dispose() {
    for (final node in _nodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GlossMenuPanel(
    maxHeight: widget.maxHeight,
    children: [
      for (final (i, item) in widget.items.indexed)
        MouseRegion(
          onEnter: item.onPressed == null
              ? null
              : (_) => _nodes[i].requestFocus(),
          child: DesignPressable(
            focusNode: _nodes[i],
            onPressed: item.onPressed == null
                ? null
                : () {
                    widget.close();
                    item.onPressed!();
                  },
            semanticLabel: item.label,
            builder: (context, states, _) => GlossMenuRow(
              label: item.label,
              states: states,
              icon: item.icon,
              isDestructiveAction: item.isDestructiveAction,
              style: widget.style,
              trailing: item.shortcut == null ? null : Text(item.shortcut!),
            ),
          ),
        ),
    ],
  );
}

/// A menu: [builder]'s key opens a porcelain panel of [items] under it.
/// Down on the key opens it too; Up and Down move through the rows, Home
/// and End go to the ends, Escape closes it and gives the key its focus
/// back.
///
/// ```dart
/// GlossMenu(items: [GlossMenuItem(label: 'Share', onPressed: () {})], builder: (context, toggle, open) => GlossButton('More', onPressed: toggle))
/// ```
class GlossMenu extends StatelessWidget {
  /// A menu of [items] opened by [builder]'s key.
  const GlossMenu({
    super.key,
    required this.items,
    required this.builder,
    this.semanticLabel,
    this.alignEnd = false,
    this.style,
  });

  /// The rows.
  final List<GlossMenuItem> items;

  /// The key that opens it: call `toggle` on its press; `open` says
  /// whether the menu shows.
  final Widget Function(BuildContext context, VoidCallback toggle, bool open)
  builder;

  /// What a screen reader calls the menu.
  final String? semanticLabel;

  /// Whether the panel lines up with the key's end rather than its start
  /// (a menu from a key at a bar's end).
  final bool alignEnd;

  /// The rows' own style, over [GlossThemeData.menuStyle].
  final GlossStyle? style;

  @override
  Widget build(BuildContext context) => DesignAnchoredOverlay(
    arrowKeyNavigation: true,
    semanticLabel: semanticLabel,
    placement: DesignOverlayPlacement(
      align: alignEnd ? DesignOverlayAlign.end : DesignOverlayAlign.start,
      gap: GlossSpacing.small,
      margin: GlossSpacing.small,
      matchAnchorWidth: false,
    ),
    dampingRatio: GlossMotion.panelDamping,
    stiffness: GlossMotion.panelStiffness,
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
      child: builder(context, anchor.toggle, anchor.isOpen),
    ),
    overlayBuilder: (context, info) => glossPanelArrival(
      info,
      GlossMenuList(
        items: items,
        close: info.close,
        maxHeight: info.maxSize.height.clamp(120.0, 360.0),
        style: style,
      ),
    ),
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IntProperty('items', items.length))
      ..add(FlagProperty('alignEnd', value: alignEnd, ifTrue: 'end'));
  }
}

/// A popover: [builder]'s key opens a porcelain panel of [content] beside
/// it, for a few controls or words that belong to the key (share, a quick
/// edit). Focus goes in and stays in until it closes; Escape or a press
/// outside closes it.
///
/// ```dart
/// GlossPopover(builder: (context, toggle, open) => GlossButton('Share', onPressed: toggle), content: (context, close) => const Text('Share this recipe'))
/// ```
class GlossPopover extends StatelessWidget {
  /// A popover opened by [builder]'s key.
  const GlossPopover({
    super.key,
    required this.builder,
    required this.content,
    this.side = DesignOverlaySide.below,
    this.width = 280,
    this.semanticLabel,
    this.style,
  });

  /// The key that opens it.
  final Widget Function(BuildContext context, VoidCallback toggle, bool open)
  builder;

  /// What it holds; `close` closes it.
  final Widget Function(BuildContext context, VoidCallback close) content;

  /// The side it prefers.
  final DesignOverlaySide side;

  /// Its width.
  final double width;

  /// What a screen reader calls it.
  final String? semanticLabel;

  /// Its own style, over [GlossThemeData.popoverStyle].
  final GlossStyle? style;

  @override
  Widget build(BuildContext context) => DesignAnchoredOverlay(
    semanticLabel: semanticLabel,
    placement: DesignOverlayPlacement(
      side: side,
      gap: GlossSpacing.small,
      margin: GlossSpacing.small,
      matchAnchorWidth: false,
    ),
    dampingRatio: GlossMotion.panelDamping,
    stiffness: GlossMotion.panelStiffness,
    anchorBuilder: (context, anchor) =>
        builder(context, anchor.toggle, anchor.isOpen),
    overlayBuilder: (context, info) => glossPanelArrival(
      info,
      _Card(
        width: width,
        style: style,
        styleOf: (t) => t.popoverStyle,
        child: Builder(builder: (context) => content(context, info.close)),
      ),
    ),
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(EnumProperty<DesignOverlaySide>('side', side))
      ..add(DoubleProperty('width', width));
  }
}

/// A hover card: a pointer resting on [child], or the keys' focus on it,
/// raises a porcelain panel of [content] beside it after a moment: a
/// preview of what a link or a name leads to. A long press opens it on a
/// touch screen.
///
/// ```dart
/// GlossHoverCard(content: (context) => const Text('Noa Ferreira, 42 recipes'), child: const Text('Noa'))
/// ```
class GlossHoverCard extends StatelessWidget {
  /// A hover card over [child].
  const GlossHoverCard({
    super.key,
    required this.child,
    required this.content,
    this.width = 280,
    this.semanticLabel,
    this.style,
  });

  /// What the pointer rests on.
  final Widget child;

  /// What the card holds.
  final WidgetBuilder content;

  /// Its width.
  final double width;

  /// What a screen reader calls it.
  final String? semanticLabel;

  /// Its own style, over [GlossThemeData.popoverStyle].
  final GlossStyle? style;

  @override
  Widget build(BuildContext context) => DesignAnchoredOverlay(
    trigger: DesignOverlayTrigger.hover,
    focusOnOpen: false,
    semanticLabel: semanticLabel,
    placement: const DesignOverlayPlacement(
      gap: GlossSpacing.small,
      margin: GlossSpacing.small,
      matchAnchorWidth: false,
    ),
    dampingRatio: GlossMotion.panelDamping,
    stiffness: GlossMotion.panelStiffness,
    anchorBuilder: (context, anchor) => child,
    overlayBuilder: (context, info) => glossPanelArrival(
      info,
      _Card(
        width: width,
        style: style,
        styleOf: (t) => t.popoverStyle,
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

class _Card extends StatelessWidget {
  const _Card({
    required this.width,
    required this.style,
    required this.styleOf,
    required this.child,
  });

  final double width;
  final GlossStyle? style;
  final GlossStyle? Function(GlossThemeData theme) styleOf;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = GlossTheme.of(context);
    final c = theme.colors;
    final layered = DesignStyleOf([style, styleOf(theme)], const {});
    var face = glossPanelFace(c);
    if (layered.fill != null) face = face.glazed(layered.fill!);
    return SizedBox(
      width: width,
      child: GlossSurface(
        face: face.copyWith(foreground: layered.foreground ?? c.ink),
        child: Padding(
          padding:
              layered.padding(Directionality.of(context)) ??
              const EdgeInsets.all(GlossSpacing.regular),
          child: DefaultTextStyle.merge(
            style: theme.textTheme.body.merge(layered.textStyle),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// A tooltip: a pointer resting on [child], the keys' focus on it or a
/// long press shows [message] on a small smoke-gel capsule over it. Escape
/// hides it; the pointer may move onto it and it stays.
///
/// ```dart
/// GlossTooltip(message: 'Add to week', child: Icon(LucideIcons.calendarPlus))
/// ```
class GlossTooltip extends StatelessWidget {
  /// A tooltip saying [message] over [child].
  const GlossTooltip({
    super.key,
    required this.message,
    required this.child,
    this.style,
  });

  /// What it says.
  final String message;

  /// What it explains.
  final Widget child;

  /// Its own style, over [GlossThemeData.tooltipStyle].
  final GlossStyle? style;

  // ui_core's tooltip runs it: one at a time, the next at once along a
  // toolbar, Escape hides it, the pointer may rest on the tip.
  @override
  Widget build(BuildContext context) => DesignTooltip(
    message: message,
    hoverDelay: const Duration(milliseconds: 500),
    dismissDelay: const Duration(milliseconds: 80),
    placement: const DesignOverlayPlacement(
      side: DesignOverlaySide.above,
      align: DesignOverlayAlign.center,
      gap: 6,
      margin: GlossSpacing.small,
      matchAnchorWidth: false,
    ),
    tooltipBuilder: (context, info) =>
        glossPanelArrival(info, _Smoke(message: message, style: style)),
    child: child,
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('message', message));
  }
}

/// The tooltip's capsule: dark tinted gel by day and night, its words
/// white, the top light's sheen across it.
class _Smoke extends StatelessWidget {
  const _Smoke({required this.message, required this.style});

  final String message;
  final GlossStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = GlossTheme.of(context);
    final c = theme.colors;
    final layered = DesignStyleOf([style, theme.tooltipStyle], const {});
    final light = c.brightness == Brightness.light;
    var face = GlossFace(
      top: light ? const Color(0xF2505A64) : const Color(0xF25E6872),
      middle: light ? const Color(0xF2363E46) : const Color(0xF2434B53),
      bottom: light ? const Color(0xF22B3238) : const Color(0xF2383F46),
      edge: light ? const Color(0xFF1C2227) : const Color(0xFF15191D),
      glow: const Color(0x33FFFFFF),
      foreground: const Color(0xFFF7F9FA),
      lens: 0.6,
      lift: 0.6,
      radius: 10,
    );
    if (layered.fill != null) face = face.glazed(layered.fill!);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 260),
      child: GlossSurface(
        face: face,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: GlossSpacing.small + GlossMetrics.rimRoom,
            vertical: GlossSpacing.tight + GlossMetrics.rimRoom,
          ),
          child: Text(
            message,
            style: theme.textTheme.caption
                .copyWith(
                  color: layered.foreground ?? face.foreground,
                  fontWeight: FontWeight.w500,
                )
                .merge(layered.textStyle),
          ),
        ),
      ),
    );
  }
}
