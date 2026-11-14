import 'dart:math' as math;

import 'package:material_ui/material_ui.dart'
    show Material, MaterialLocalizations, MaterialType;
import 'package:flutter/widgets.dart';

import '../../glyphs.dart';

import '../../chrome_metrics.dart';
import '../../internal/face.dart';
import '../../internal/styled.dart';
import '../../theme.dart';
import '../host.dart';
import '../pressable/pressable.dart';
import '../../internal/dim.dart';
import '../../internal/rest_ring.dart';
import '../../internal/cap.dart';

/// One choice in a sheet, as the source sets its options (`.opt`): an
/// optional [hue] swatch (a category's light) or [lead] mark, the [label]
/// in the body type, a quiet [trailing] note (an amount), and at the end the
/// round check, 24 across: a ring while unchosen, the ink with its white
/// tick when [checked], the chosen one's label semibold. At least 52 tall,
/// 6 over and under, its parts 12 apart, a hairline between two. A null
/// [onPressed] leaves it inert.
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

  /// The node that holds this part's keyboard focus; null keeps one of its own.
  final FocusNode? focusNode;

  /// Whether this part takes keyboard focus when first shown.
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
      label: label,
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
                child: selected
                    ? FrostedFace(
                        material: FrostedMaterial.paint,
                        radius: BorderRadius.circular(check / 2),
                        color: fill,
                        gradients: fill == null
                            ? [t.colorScheme.buttonFill]
                            : const <Gradient>[],
                        sheen: t.colorScheme.buttonSheen,
                        child: Center(
                          child: Icon(
                            FrostedGlyphs.check,
                            size: FrostedChromeMetrics.optionCheckGlyph,
                            color: s.foreground ?? t.colorScheme.onButton,
                          ),
                        ),
                      )
                    : FrostedFace(
                        material: FrostedMaterial.paint,
                        radius: BorderRadius.circular(check / 2),
                        color: fill,
                        ring: s.edge ?? frostedRestRing(t),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A category's light as a swatch (`.sw`): 8 across in its [color].
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
}

/// One choice of a [FrostedMenu]: its [value], its [label], an optional
/// [hue] swatch and quiet [trailing] note, the check when [checked], whether
/// it can be chosen ([enabled]; a disabled one stands faded and inert), and
/// the walkthrough [key] set on its row.
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

  /// The walkthrough key set on its row.
  final Key? key;
}

/// A menu dropping from the control that opened it, as the source's month
/// menu does (`.menu`): a white card 288 wide, 6 inside, its corners at
/// 16, a hairline round it and a deep soft shadow, its [title] in the
/// caption type over the [items]: each a row 40 tall with its corners at
/// 10, the check's column 16 wide before the label, the chosen one on the
/// wash with its label in the ink. It stands 8 under the control, centred
/// on it on a phone and with its end on the control's end at desktop width,
/// and drops no scrim. [show] opens it and completes with the chosen value,
/// or null when it is dismissed (a tap outside, the system back).
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
    this.label,
    this.width,
    super.key,
  });

  /// The items, in order.
  final List<FrostedMenuItem<T>> items;

  /// The menu's width; null keeps the source's 288.
  final double? width;

  /// Called with the chosen item's value.
  final ValueChanged<T> onSelected;

  /// The caption over the items.
  final String? title;

  /// What a screen reader calls the menu; null says the [title].
  final String? label;

  /// Opens a menu under the control [context] belongs to, over the whole
  /// app: the context of a [Builder] round that control, never the page's
  /// (whose box is the whole screen, so the menu would drop from nowhere).
  /// [anchor] widens the box it drops from: a context round the control's
  /// row, as the source hangs the month menu from the whole month switch.
  /// With [fitAnchor] the menu is at least as wide as that box and stands
  /// on its leading edge, as a select's list stands under its field.
  static Future<T?> show<T>(
    BuildContext context, {
    required List<FrostedMenuItem<T>> items,
    String? title,
    String? label,
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
    return navigator.push(
      _MenuRoute<T>(
        duration: FrostedMotion.of(context).fast,
        anchor: rect,
        wide: wide,
        start: fitAnchor,
        label: MaterialLocalizations.of(context).modalBarrierDismissLabel,
        builder: (menuContext) => themes.wrap(
          FrostedMenu<T>(
            items: items,
            title: title,
            label: label,
            width: fitAnchor
                ? math.max(FrostedChromeMetrics.menuWidth, rect.width)
                : null,
            onSelected: (value) => Navigator.of(menuContext).pop(value),
          ),
        ),
      ),
    );
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
      label: label ?? head,
      child: Material(
        type: MaterialType.transparency,
        child: SizedBox(
          width: width ?? FrostedChromeMetrics.menuWidth,
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
                for (final item in items)
                  _MenuRow(
                    key: item.key,
                    label: item.label,
                    hue: item.hue,
                    end: item.trailing,
                    checked: item.checked,
                    onTap: item.enabled ? () => onSelected(item.value) : null,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A menu's row (`.menu-i`): 40 tall, 10 in, corners 10; the check's
/// column 16 wide, then the label in the link type, then the end note; the
/// chosen one on the wash, its label in the ink and semibold.
class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.label,
    required this.onTap,
    required this.checked,
    this.hue,
    this.end,
    super.key,
  });

  final String label;
  final VoidCallback? onTap;
  final bool checked;
  final Color? hue;
  final Widget? end;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final swatch = hue;
    return FrostedPressable(
      onPressed: onTap,
      label: label,
      selected: checked,
      radius: FrostedChromeMetrics.menuItemRadius,
      child: FrostedDim(
        off: onTap == null,
        child: SizedBox(
          height: FrostedChromeMetrics.menuItem,
          child: FrostedFace(
            material: FrostedMaterial.paint,
            radius: BorderRadius.circular(FrostedChromeMetrics.menuItemRadius),
            color: checked ? t.glass.wash : null,
            padding: const EdgeInsets.symmetric(
              horizontal: FrostedChromeMetrics.menuItemInset,
            ),
            child: Row(
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
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: checked
                          ? t.textTheme.link.semibold.c(
                              t.colorScheme.textPrimary,
                            )
                          : t.textTheme.link.c(t.colorScheme.textSecondary),
                    ),
                  ),
                ),
                if (end != null)
                  DefaultTextStyle.merge(
                    style: t.textTheme.amountSmall.c(t.colorScheme.textPrimary),
                    child: end!,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The route a menu rides: no scrim, dismissed by a tap outside, laid out
/// under its anchor.
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
