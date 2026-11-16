// The raised panel every overlay of round 4 opens (a split button's menu, a menu bar's menus, a popover, a hover card, a
// combobox's and a multi-select's list, the command palette), and the row a menu-like list draws: the same slab and the
// same pressed-in row as NeumorphicMenu, so a ui_core behaviour's surface is the look's menu exactly. Hidden from the
// barrel.
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../component_themes.dart';
import '../frames.dart';
import '../glyphs.dart';
import '../knobs.dart';
import '../shapes.dart';
import '../theme.dart';
import 'cap_label.dart';
import 'cell_bank.dart' show NeumorphicChosenBand;
import 'moulded.dart';

/// The panel's outline: the menu's (the theme's medium shape).
OutlinedBorder _panelShape(NeumorphicThemeData t) =>
    t.shapes.corner(NeumorphicRadii.slab);

/// A row's outline inside the panel: the panel's moved in by its 12 px padding, so a highlighted row is concentric
/// with the panel.
OutlinedBorder _panelRowShape(BuildContext context, {double inset = 12}) {
  final t = NeumorphicTheme.of(context);
  final outer = _panelShape(t);
  return NeumorphicShapes.inset(
    outer,
    inset + outer.dimensions.resolve(Directionality.of(context)).left,
  );
}

/// A field's open list (a select's, a combobox's, a multi-select's) starts its options' words where the field starts
/// its value, [words] in from the field's edge (design6 P, 11-11 night): the panel's inset, its shape's own [frame]
/// (the content-safe inset a surface adds for a shape it is given) and its rows' make up [words], the rows keeping 4 to
/// 8 of their own round their words, and the chosen row, pressed in, carries its check at its end.
({double panel, double row}) neumorphicFieldListInsets(
  double words, {
  double frame = 0,
}) {
  final row = (words - 8).clamp(4.0, 8.0);
  return (panel: math.max(0.0, words - row - frame), row: row);
}

/// [neumorphicFieldListInsets] for a [NeumorphicPanel], whose shape keeps its own inset.
({double panel, double row}) neumorphicFieldPanelInsets(BuildContext context) {
  final t = NeumorphicTheme.of(context);
  return neumorphicFieldListInsets(
    neumorphicFieldWords(t),
    frame: _panelShape(t).dimensions.resolve(Directionality.of(context)).left,
  );
}

/// Where a field (a text field's groove, a select's face) starts its value at [t]'s density.
double neumorphicFieldWords(NeumorphicThemeData t) =>
    t.density.padding(const EdgeInsets.symmetric(horizontal: 14)).left;

/// Keyboard focus on a part shaped [border] that draws its own face: it lifts off the wall, its lit side warmed by the
/// pigment ([neumorphicPaintFocusLift]). [reach] scales it to a small part among others.
CustomPainter neumorphicFocusLift(
  NeumorphicThemeData t,
  OutlinedBorder border, {
  double reach = 1,
}) => _Lift(t.colors, t.elevation, border, reach);

class _Lift extends CustomPainter {
  const _Lift(this.c, this.elevation, this.border, this.reach);
  final NeumorphicColors c;
  final NeumorphicElevation elevation;
  final OutlinedBorder border;
  final double reach;

  @override
  void paint(Canvas canvas, Size size) => neumorphicPaintFocusLift(
    canvas,
    border.getOuterPath(Offset.zero & size),
    c,
    reach: reach,
    elevation: elevation,
  );

  @override
  bool shouldRepaint(_Lift old) =>
      old.c != c ||
      old.elevation != elevation ||
      old.border != border ||
      old.reach != reach;
}

/// The raised panel: a slab of the material with the menu's 12 px padding. With [presence] (an overlay's 0→1) it
/// fades in and settles a few pixels from its anchor's [side].
class NeumorphicPanel extends StatelessWidget {
  /// A panel around [child].
  const NeumorphicPanel({
    super.key,
    required this.child,
    this.presence,
    this.side = DesignOverlaySide.below,
    this.width,
    this.maxHeight,
    this.padding = const EdgeInsets.all(12),
    this.style,
    this.label,
    this.menu = false,
  });

  /// What the panel holds.
  final Widget child;

  /// The overlay's presence; null stands it still.
  final Animation<double>? presence;

  /// Which side of its anchor it stands on: it settles from there.
  final DesignOverlaySide side;

  /// Its width; null takes its content's.
  final double? width;

  /// Its tallest; the content scrolls past it.
  final double? maxHeight;

  /// Its padding.
  final EdgeInsets padding;

  /// The surface's own style, before the menu theme.
  final NeumorphicStyle? style;

  /// What a screen reader calls it.
  final String? label;

  /// Whether it holds a menu's rows: whichever moved last, the keys or the pointer, has the one lit
  /// [NeumorphicPanelRow], never a lifted row and a raised one at once. Opened by the keys (a key still down as it
  /// opens) it lights its focused first row; opened by the pointer it lights nothing, whatever row it focused, until
  /// the pointer or the keys move.
  final bool menu;

  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    Widget panel = NeumorphicSurface(
      cast: NeumorphicSurfaceLevel.part,
      style: style,
      themeStyle: t.menuTheme,
      shape: _panelShape(t),
      radius: NeumorphicRadii.slab,
      outlined: true,
      padding: padding,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: width ?? 0,
          maxWidth: width ?? double.infinity,
          maxHeight: maxHeight ?? double.infinity,
        ),
        child: menu ? _MenuPlace(child: child) : child,
      ),
    );
    if (label != null) {
      panel = Semantics(
        container: true,
        explicitChildNodes: true,
        label: label,
        child: panel,
      );
    }
    final p = presence;
    if (p == null) return panel;
    final from = switch (side) {
      DesignOverlaySide.below => const Offset(0, -6),
      DesignOverlaySide.above => const Offset(0, 6),
      DesignOverlaySide.start => const Offset(6, 0),
      DesignOverlaySide.end => const Offset(-6, 0),
    };
    return AnimatedBuilder(
      animation: p,
      child: panel,
      builder: (context, child) {
        final v = p.value.clamp(0.0, 1.0);
        return Opacity(
          opacity: v,
          child: Transform.translate(offset: from * (1 - v), child: child),
        );
      },
    );
  }
}

/// One row of a menu-like list in a [NeumorphicPanel], for a ui_core item's [states]. [checked], the chosen row is
/// pressed in under the pigment's wash, its words bold and its check in the pigment; the keyboard's place lifts (the
/// look's keyboard focus); the pointer's row, or one whose menu is open ([highlighted]), stands up a little; a row held
/// under a finger presses in plain while it is held. Out of use, its words are in the quiet ink.
class NeumorphicPanelRow extends StatelessWidget {
  /// A row named [label].
  const NeumorphicPanelRow({
    super.key,
    required this.label,
    required this.states,
    this.icon,
    this.checked = false,
    this.danger = false,
    this.trailing,
    this.note,
    this.submenu = false,
    this.highlighted = false,
    this.style,
    this.inset = 8,
    this.panelInset = 12,
    this.checkAtEnd = false,
  });

  /// Its own inset round its words.
  final double inset;

  /// Its panel's inset, which its outline keeps concentric with.
  final double panelInset;

  /// Whether its check stands at its end (a field's list, whose words start on the field's value) instead of in a
  /// column before its words.
  final bool checkAtEnd;

  /// Its words.
  final String label;

  /// The item's states from its behaviour.
  final Set<WidgetState> states;

  /// A glyph before its words.
  final IconData? icon;

  /// Whether it carries the check: a chosen value, a ticked option.
  final bool checked;

  /// Whether it destroys something: a warning mark in its glyph slot when it has no glyph of its own.
  final bool danger;

  /// What stands at its end (a shortcut).
  final String? trailing;

  /// A note under its words.
  final String? note;

  /// Whether it opens a menu of its own: a chevron at its end.
  final bool submenu;

  /// Whether it shows as the active row whatever its states.
  final bool highlighted;

  /// The menu's own style for the row's states.
  final NeumorphicStyle? style;

  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final c = t.colors;
    final look = neumorphicStyleOf([style, t.menuTheme], states);
    final enabled = !states.contains(WidgetState.disabled);
    // Four states, four materials, so none reads as another: the chosen row is pressed in under the pigment's wash
    // (a chosen cell's well); a row held under a finger presses in plain, only while it is held; the keyboard's place
    // lifts with its lit side warmed (keyboard focus everywhere in the look); the pointer's row, or one whose menu is
    // open, stands up a little off the panel. Only the chosen row is ever pressed in at rest.
    // In a menu's panel ([NeumorphicPanel.menu]) the last to move, the keys or the pointer, has the one lit row: the
    // keys' place lifts only while the keys moved last, the pointer's row stands up only while the pointer did.
    final place = context
        .dependOnInheritedWidgetOfExactType<_MenuPlaceScope>()
        ?.keys;
    final focus = place == null || !enabled ? null : Focus.maybeOf(context);
    final chosen = enabled && checked;
    final held = enabled && !chosen && states.contains(WidgetState.pressed);
    final keys =
        enabled && place != false && states.contains(WidgetState.focused);
    final raised =
        enabled &&
        !chosen &&
        !held &&
        !keys &&
        (highlighted ||
            (place != true && states.contains(WidgetState.hovered)) ||
            states.contains(WidgetState.selected));
    final border = _panelRowShape(context, inset: panelInset);
    final ink = enabled ? c.ink : c.inkTertiary;
    final words = t.textTheme.body
        .copyWith(
          color: ink,
          fontWeight: checked ? FontWeight.w700 : FontWeight.w500,
        )
        .merge(look.textStyle)
        .copyWith(color: look.foreground);
    final iconSize = math.max(20.0, look.iconSize ?? 20);
    // A row that destroys says so in its glyph slot when it has no glyph of its own, as a menu's row does: parked at
    // the row's far end the triangle read as an error badge on it.
    final glyph = icon ?? (danger ? NeumorphicGlyphs.triangleAlert : null);
    final row = CustomPaint(
      painter: held
          ? NeumorphicPanelRowRelief(
              c,
              t.elevation,
              look.fill ?? c.ground,
              border,
            )
          : raised
          ? NeumorphicPanelRowRaise(c, t.elevation, border)
          : null,
      foregroundPainter: keys
          ? neumorphicFocusLift(t, border, reach: .5)
          : null,
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        // A shortcut at the end keeps clear of the band's end as the words do of its start: at the row's 8 it sat
        // jammed against the band while the words, past an icon's room, started 38 in.
        padding: EdgeInsetsDirectional.fromSTEB(
          inset,
          10,
          trailing != null ? inset + 8 : inset,
          10,
        ),
        child: Row(
          children: [
            if (!checkAtEnd || glyph != null) ...[
              SizedBox(
                width: iconSize,
                child: checked && !checkAtEnd
                    ? Icon(
                        NeumorphicGlyphs.check,
                        size: look.iconSize,
                        color: look.foreground ?? c.pigmentInkLit,
                      )
                    : glyph == null
                    ? null
                    : Icon(
                        glyph,
                        size: look.iconSize,
                        color: look.foreground ?? ink,
                      ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  neumorphicLabel(Text(label, style: words)),
                  if (note != null)
                    Text(
                      note!,
                      style: t.textTheme.micro.copyWith(
                        color: enabled ? c.inkTertiary : c.quiet,
                      ),
                    ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 12),
              neumorphicLabel(
                Text(
                  trailing!,
                  style: t.textTheme.micro.tabular.copyWith(
                    color: enabled ? c.inkTertiary : c.quiet,
                  ),
                ),
              ),
            ],
            if (submenu) ...[
              const SizedBox(width: 8),
              Icon(
                Directionality.of(context) == TextDirection.rtl
                    ? NeumorphicGlyphs.chevronLeft
                    : NeumorphicGlyphs.chevronRight,
                size: 16,
                color: ink,
              ),
            ],
            if (checkAtEnd && checked) ...[
              const SizedBox(width: 10),
              Icon(
                NeumorphicGlyphs.check,
                size: look.iconSize,
                color: look.foreground ?? c.pigmentInkLit,
              ),
            ],
          ],
        ),
      ),
    );
    // An app's own fill for the row's states keeps its say over the chosen row's face.
    final face = chosen && look.fill != null
        ? CustomPaint(
            painter: NeumorphicPanelRowRelief(
              c,
              t.elevation,
              look.fill,
              border,
            ),
            child: row,
          )
        : NeumorphicChosenBand(chosen: chosen, border: border, child: row);
    if (focus == null) return face;
    // The pointer's moves take the keys' place, as in a native menu: the keys go on from the pointer's row. A move,
    // not a row scrolled under a resting pointer.
    return MouseRegion(
      onHover: (_) {
        if (!focus.hasFocus) focus.requestFocus();
      },
      child: face,
    );
  }
}

/// [NeumorphicPanel.menu]'s one place: whether the keys moved last in the menu.
class _MenuPlace extends StatefulWidget {
  const _MenuPlace({required this.child});

  final Widget child;

  @override
  State<_MenuPlace> createState() => _MenuPlaceState();
}

class _MenuPlaceState extends State<_MenuPlace> {
  late bool _keys;

  @override
  void initState() {
    super.initState();
    _keys = HardwareKeyboard.instance.logicalKeysPressed.any(
      (key) =>
          key == LogicalKeyboardKey.enter ||
          key == LogicalKeyboardKey.numpadEnter ||
          key == LogicalKeyboardKey.space ||
          key == LogicalKeyboardKey.arrowDown ||
          key == LogicalKeyboardKey.arrowUp ||
          key == LogicalKeyboardKey.arrowLeft ||
          key == LogicalKeyboardKey.arrowRight,
    );
    HardwareKeyboard.instance.addHandler(_key);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_key);
    super.dispose();
  }

  /// Any key down while the menu is open hands the place to the keys. The menu never claims the key.
  bool _key(KeyEvent event) {
    if (event is KeyDownEvent && !_keys && mounted) {
      setState(() => _keys = true);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerHover: (_) {
      if (_keys) setState(() => _keys = false);
    },
    child: _MenuPlaceScope(keys: _keys, child: widget.child),
  );
}

class _MenuPlaceScope extends InheritedWidget {
  const _MenuPlaceScope({required this.keys, required super.child});

  final bool keys;

  @override
  bool updateShouldNotify(_MenuPlaceScope old) => old.keys != keys;
}

/// The pointer's row, or one whose menu is open: it stands up off its panel as a part does (the part's own cast, so it
/// still reads at night, where the light throw is a breath), in its exact outline, its face the panel's own. Raised,
/// never pressed in, so it never reads as the chosen row or a second choice.
class NeumorphicPanelRowRaise extends CustomPainter {
  /// The raise of a row shaped [border].
  const NeumorphicPanelRowRaise(this.colors, this.elevation, this.border);

  /// The palette.
  final NeumorphicColors colors;

  /// The theme's relief.
  final NeumorphicElevation elevation;

  /// The row's outline.
  final OutlinedBorder border;

  @override
  void paint(Canvas canvas, Size size) => neumorphicPaintRaised(
    canvas,
    border.getOuterPath(Offset.zero & size),
    colors,
    light: (const Offset(-4, -4), 10),
    dark: (const Offset(5, 5), 12),
    elevation: elevation,
  );

  @override
  bool shouldRepaint(NeumorphicPanelRowRaise old) =>
      old.colors != colors ||
      old.elevation != elevation ||
      old.border != border;
}

/// A row pressed in a little, in its exact outline, its face [fill] (a breath of the pigment when none is given).
class NeumorphicPanelRowRelief extends CustomPainter {
  /// The relief of a row shaped [border].
  const NeumorphicPanelRowRelief(
    this.colors,
    this.elevation,
    this.fill,
    this.border,
  );

  /// The palette.
  final NeumorphicColors colors;

  /// The theme's relief.
  final NeumorphicElevation elevation;

  /// A style's own fill for the row.
  final Color? fill;

  /// The row's outline.
  final OutlinedBorder border;

  @override
  void paint(Canvas canvas, Size size) {
    final box = Offset.zero & size;
    final shape = border.getOuterPath(box);
    final tint =
        fill ??
        Color.alphaBlend(colors.pigment.withValues(alpha: .08), colors.ground);
    neumorphicPaintPressed(
      canvas,
      shape,
      colors,
      light: (const Offset(-1, -1), 3),
      dark: (const Offset(1, 1), 3),
      face: LinearGradient(colors: [tint, tint]).createShader(box),
      elevation: elevation,
      contentBounds: box.deflate(6),
    );
  }

  @override
  bool shouldRepaint(NeumorphicPanelRowRelief old) =>
      old.colors != colors ||
      old.elevation != elevation ||
      old.fill != fill ||
      old.border != border;
}
