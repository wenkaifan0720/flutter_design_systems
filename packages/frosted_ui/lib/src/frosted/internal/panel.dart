import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../chrome_metrics.dart';
import '../components/pressable/pressable.dart';
import '../glyphs.dart';
import '../theme.dart';
import 'face.dart';
import 'chosen_plate.dart';
import 'dim.dart';
import 'menu_wake.dart';
import 'styled.dart';

/// The look's floating panel, as a menu stands (`.menu`): the menu fill,
/// its hairline ring and soft drop, corners at [FrostedCorners.medium],
/// 6 in. Every part ui_core raises over the page (a popover, a hover
/// card, a combobox's list, a split button's or a menubar's menu, the
/// command palette) stands on it, so they read as one family with
/// [FrostedMenu]. Raised over the page, it is a slab of its own wherever its
/// part stands: a list dropping from a field on a card still frosts the card
/// and the words under it, rather than taking the card's glass as its own.
/// Built in place ([inPlace], a command palette set in a page) it stands on
/// the glass it is set in. Plumbing of the components.
class FrostedPanel extends StatelessWidget {
  /// A panel round [child], [width] wide (null: as wide as [child]).
  const FrostedPanel({
    required this.child,
    this.width,
    this.padding = const EdgeInsets.all(FrostedChromeMetrics.menuInset),
    this.presence,
    this.inPlace = false,
    super.key,
  });

  /// Whether the panel is set in the page rather than raised over it.
  final bool inPlace;

  /// What the panel holds.
  final Widget child;

  /// The panel's width; null sizes it to [child].
  final double? width;

  /// The room inside the face.
  final EdgeInsets padding;

  /// ui_core's 0→1 spring as the panel opens: it grows from 96% with it,
  /// frosted from its first frame; null stands it whole.
  final Animation<double>? presence;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final s = FrostedStyleLayers(null, t.components.menu);
    final (cut, corner) = s.surface(
      FrostedCorners.medium,
      FrostedStyleLayers.stockMedium,
      FrostedChromeMetrics.menuRadius,
    );
    // A menu floats: the thick glass.
    final face = FrostedFace(
      material: FrostedMaterial.slab,
      radius: BorderRadius.circular(corner),
      shape: cut,
      color: s.fill,
      shadows: [
        ...t.shadows.menu,
        BoxShadow(
          color: s.edge ?? t.glass.menuEdge,
          spreadRadius: FrostedStrokes.regular,
        ),
      ],
      clipChild: true,
      padding: s.padding?.resolve(Directionality.of(context)) ?? padding,
      child: child,
    );
    // Raised, it reads the page behind it whatever glass its part stands on
    // (an overlay inherits from the field that opened it), and no focus of
    // that part clears it.
    final raised = inPlace
        ? face
        : FrostedOnGlass(
            on: false,
            child: FrostedClearing(level: 0, child: face),
          );
    final sized = width == null
        ? raised
        : SizedBox(width: width, child: raised);
    final grow = presence;
    if (grow == null) return sized;
    return AnimatedBuilder(
      animation: grow,
      child: sized,
      // Glass is never faded from above: under an Opacity its blur reads an
      // empty layer and draws a grey plate until the fade ends. It grows in
      // frosted from its first frame instead; closed (0) it is not drawn,
      // but its rows stay in the tree, so a menu or a popover opened by a
      // key can give its first row the focus on the frame it opens.
      builder: (context, child) {
        final v = grow.value;
        return _Drawn(
          drawn: v > 0,
          child: Transform.scale(
            scale: .96 + .04 * v.clamp(0.0, 1.2),
            child: child,
          ),
        );
      },
    );
  }
}

/// [child] laid out and kept (its focus too), but drawn, hit and read out
/// only while [drawn].
class _Drawn extends SingleChildRenderObjectWidget {
  const _Drawn({required this.drawn, required super.child});

  final bool drawn;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderDrawn(drawn);

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) =>
      (renderObject as _RenderDrawn).drawn = drawn;
}

class _RenderDrawn extends RenderProxyBox {
  _RenderDrawn(this._drawn);

  bool _drawn;
  set drawn(bool value) {
    if (value == _drawn) return;
    _drawn = value;
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_drawn) super.paint(context, offset);
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) =>
      _drawn && super.hitTest(result, position: position);

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    if (_drawn) super.visitChildrenForSemantics(visitor);
  }
}

/// A row of a [FrostedPanel] painted for its [states] (`.menu-i`): 40 tall,
/// and at least a finger's target (48, on every platform, as Material's
/// menu rows are), so the row a tap reaches is the row a screen reader
/// outlines and no neighbour's; 10 in, corners 10; the check's column 16 wide when [checkable], then the
/// [label] in the link type, then [trailing]. The chosen row (`selected`)
/// stands on the chosen plate, the brighter glass every chosen chip, segment
/// and link stands on (law 6), with the check and its words in the ink,
/// semibold; the list's one held row (`focused`: the keys', or the
/// pointer's where the list moves its highlight with the pointer) and a
/// press lay the quieter wash under a row that is not chosen, so neither
/// reads as a second choice and a resting pointer never lights a second
/// row. With [followsPointer] a pointer moving over the row gives it the
/// focus, for the lists whose highlight is the focus (a menu bar's or a
/// split button's menu). A [destructive] row sets its words in the over
/// tone, as a `FrostedMenuItem`'s loss is. A disabled row fades. Plumbing
/// of the components.
class FrostedPanelRow extends StatelessWidget {
  /// A row saying [label] in [states].
  const FrostedPanelRow({
    required this.label,
    required this.states,
    this.leading,
    this.trailing,
    this.checkable = true,
    this.height = FrostedChromeMetrics.menuItem,
    this.followsPointer = false,
    this.destructive = false,
    super.key,
  });

  /// Whether the row destroys something (Delete): its words in the over
  /// tone.
  final bool destructive;

  /// Whether a pointer moving over the row gives it the focus (the row's
  /// own [Focus], above it), so the list's one lit row follows the pointer.
  final bool followsPointer;

  /// The row's words.
  final String label;

  /// The row's states, from ui_core.
  final Set<WidgetState> states;

  /// A glyph or swatch in the check's column, while the row is not chosen.
  final Widget? leading;

  /// A note or shortcut at the row's end.
  final Widget? trailing;

  /// Whether the row keeps the check's column.
  final bool checkable;

  /// The row's height, at least a finger's target
  /// ([FrostedBreakpoints.touchHitTarget]).
  final double height;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final chosen = states.contains(WidgetState.selected);
    // In a menu ui_core raises, the row with the focus, once a key or the
    // pointer moved (FrostedMenuWake: not the row it gives the focus as a
    // pointer opens it), whatever the focus highlight mode (the web's is
    // touch's until a key is pressed, so `focused` would wait for a key);
    // in a list, the row ui_core holds (`focused`).
    final awake = FrostedMenuWake.of(context);
    final held = awake == null
        ? states.contains(WidgetState.focused)
        : awake && (Focus.maybeOf(context)?.hasPrimaryFocus ?? false);
    // Held, the frost under the row clears; pressed, the row's plate lights.
    final pressed = states.contains(WidgetState.pressed);
    final lit = pressed || held;
    final off = states.contains(WidgetState.disabled);
    final corner = BorderRadius.circular(FrostedChromeMetrics.menuItemRadius);
    const inset = EdgeInsets.symmetric(
      horizontal: FrostedChromeMetrics.menuItemInset,
    );
    final content = Row(
      spacing: FrostedChromeMetrics.menuItemGap,
      children: [
        if (checkable || leading != null)
          SizedBox(
            width: FrostedChromeMetrics.menuItemGlyph,
            child: chosen && checkable
                ? Icon(
                    FrostedGlyphs.check,
                    size: FrostedChromeMetrics.menuItemGlyph,
                    color: t.colorScheme.textPrimary,
                  )
                : leading,
          ),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: chosen
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
        if (trailing case final trailing?)
          DefaultTextStyle.merge(
            style: t.textTheme.labelMedium.c(t.colorScheme.textTertiary),
            child: trailing,
          ),
      ],
    );
    final row = SizedBox(
      height: math.max(height, FrostedBreakpoints.touchHitTarget),
      // The keyboard's row catches the light along its rim; one the pointer
      // holds only clears.
      child: FrostedCleared(
        level: held ? 1 : 0,
        lit: held && FrostedLastInput.keyed ? 1 : 0,
        outline: RoundedRectangleBorder(borderRadius: corner),
        inside: true,
        child: chosen
            ? FrostedChosenPlate(radius: corner, padding: inset, child: content)
            : FrostedFace(
                material: FrostedMaterial.paint,
                radius: corner,
                color: pressed ? t.glass.wash : null,
                padding: inset,
                child: content,
              ),
      ),
    );
    final dimmed = FrostedDim(off: off, child: row);
    if (!followsPointer || off) return dimmed;
    return MouseRegion(
      onHover: (_) {
        final node = Focus.maybeOf(context);
        if (node != null && node.canRequestFocus && !node.hasPrimaryFocus) {
          node.requestFocus();
        }
      },
      child: dimmed,
    );
  }
}

/// [child]'s frost cleared ([FrostedFocusRing]) while [states] say the
/// keyboard holds it (ui_core puts `focused` in the set only when focus came
/// by the keyboard), and a little under a pointer.
Widget frostedRingFor(
  Set<WidgetState> states,
  Widget child, {
  double radius = 0,
  OutlinedBorder? shape,
}) => FrostedFocusRing(
  shown: states.contains(WidgetState.focused),
  hovered: states.contains(WidgetState.hovered),
  radius: radius,
  shape: shape,
  child: child,
);
