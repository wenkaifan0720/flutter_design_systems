/// A main action with a menu of the others beside it, painted on ui_core's
/// split button.
library;

import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../chrome_metrics.dart';
import '../component_themes.dart';
import '../internal/cap_label.dart';
import '../internal/kit_paint.dart';
import '../internal/styled.dart';
import '../localizations.dart';
import '../theme.dart';
import 'button.dart';
import 'code.dart';
import 'menu.dart';
import 'pressable.dart';

/// A button whose action has close relatives: Save, and beside it a
/// chevron that opens Save as, Save a copy. The two halves are one
/// [MinimalButton] cut in two (each takes its share of the outline, a
/// hairline between on a filled or outlined register; a ghost pair, with
/// no frame, is divided by space), in any [variant] and [size]; the keyboard's ring
/// stands outside the focused half, as a button's does, on that half's
/// share of the outline (round on its outer side, square at the seam).
/// The menu is Minimal's
/// card of 32 px items under the chevron's end, the active item in the
/// selection fill.
///
/// Both halves are tab stops. Down on either opens the menu at its first
/// item; Escape closes it and focus goes back to the half that opened it.
/// The behaviour is ui_core's ([DesignSplitButton]); Minimal paints it.
/// The chevron is announced as [menuLabel] (More actions, in the
/// app's language, unstated).
///
/// [style] dresses both halves over the variant's component theme, as a
/// [MinimalButton]'s does; the menu reads `components.menu`.
///
/// ```dart
/// MinimalSplitButton('Save', onPressed: save, actions: [MinimalMenuItem('Save as…', onPressed: saveAs), MinimalMenuItem('Save a copy', onPressed: copy)])
/// ```
class MinimalSplitButton extends StatelessWidget {
  /// A split button whose main action is [onPressed].
  const MinimalSplitButton(
    this.label, {
    super.key,
    required this.onPressed,
    required this.actions,
    this.variant = MinimalButtonVariant.primary,
    this.size = MinimalButtonSize.medium,
    this.icon,
    this.menuLabel,
    this.style,
  });

  /// The main action's words.
  final String label;

  /// The main action; null disables the main half alone (the chevron still
  /// opens the others). A null [onPressed] with no [actions] disables both.
  final VoidCallback? onPressed;

  /// The menu's actions, each run after the menu closed; an item with no
  /// `onPressed` is disabled, and with none the chevron is.
  final List<MinimalMenuItem> actions;

  /// The register, as a [MinimalButton]'s.
  final MinimalButtonVariant variant;

  /// The height, as a [MinimalButton]'s.
  final MinimalButtonSize size;

  /// A glyph before the main action's words.
  final IconData? icon;

  /// What a screen reader calls the chevron.
  final String? menuLabel;

  /// Both halves' style, over the variant's component theme.
  final MinimalStyle? style;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final themed = switch (variant) {
      MinimalButtonVariant.primary => t.components.primaryButton,
      MinimalButtonVariant.secondary => t.components.secondaryButton,
      MinimalButtonVariant.ghost => t.components.ghostButton,
      MinimalButtonVariant.destructive => t.components.destructiveButton,
    };
    final layers = <MinimalStyle?>[style, themed];
    final (bg, fg, edge) = switch (variant) {
      MinimalButtonVariant.primary => (t.primary, t.primaryForeground, null),
      MinimalButtonVariant.secondary => (t.card, t.foreground, t.border),
      MinimalButtonVariant.ghost => (null, t.foreground, null),
      MinimalButtonVariant.destructive => (
        t.destructive,
        t.destructiveForeground,
        null,
      ),
    };
    final (height, pad, iconSize, type) = switch (size) {
      MinimalButtonSize.small => (
        MinimalChromeMetrics.controlSm,
        MinimalChromeMetrics.buttonPadSm,
        MinimalIconSize.i14,
        t.control,
      ),
      MinimalButtonSize.medium => (
        MinimalChromeMetrics.control,
        MinimalSpacing.s12,
        MinimalIconSize.i16,
        t.control,
      ),
      MinimalButtonSize.large => (
        MinimalChromeMetrics.controlLg,
        MinimalSpacing.s16,
        MinimalIconSize.i16,
        t.body.medium,
      ),
    };
    final h = t.density.height(height);
    final byLabel = {for (final a in actions) a.label: a};
    final ground = minimalGround(context);
    final action = onPressed;
    final menu = actions;

    Widget half(DesignSplitPart part, Set<WidgetState> states, bool open) {
      final so = MinimalStyleOf(layers, states);
      final ink = so.foreground ?? fg;
      final whole = so.shape ?? t.shapes.small;
      final main = part == DesignSplitPart.main;
      final cell = minimalCell(whole, index: main ? 0 : 1, count: 2);
      final glyph = icon;
      return Container(
        height: so.minimumSize?.height ?? h,
        width: main ? null : (so.minimumSize?.height ?? h),
        padding: main
            ? (so.padding ?? EdgeInsets.symmetric(horizontal: pad))
            : null,
        alignment: Alignment.center,
        decoration: minimalFrame(cell, fill: so.fill ?? bg),
        // The button's ring, outside the half's own share of the outline;
        // the focused half paints over its neighbour (_Halves).
        foregroundDecoration: minimalStateLayer(
          t,
          cell,
          states,
          face: so.fill ?? bg,
          faceInk: ink,
          ground: ground,
        ),
        child: main
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (glyph != null) ...[
                    MinimalIcon(
                      glyph,
                      size: so.iconSize ?? iconSize,
                      color: ink,
                    ),
                    const MinimalGap(MinimalChromeMetrics.iconGap),
                  ],
                  Flexible(
                    child: minimalCapLabel(
                      Text(
                        label,
                        style: so.text(type, ink),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              )
            : MinimalIcon(
                open ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                size: so.iconSize ?? iconSize,
                color: ink,
              ),
      );
    }

    final split = DesignSplitButton(
      label: label,
      onPressed: action,
      menuLabel: menuLabel ?? MinimalLocalizations.of(context).moreActions,
      minimumSize: Size.zero,
      actions: [
        for (final a in menu)
          DesignSplitAction(label: a.label, onPressed: a.onPressed),
      ],
      layoutBuilder: (context, mainHalf, toggle) {
        final so = MinimalStyleOf(layers, const {});
        final face = so.fill ?? bg;
        // The seam: the rim on the outlined register, a hairline of the
        // face's own ink on a filled one, laid on the face so no ground
        // shows through it; a bare (ghost) pair has none, space divides it.
        final seamInk =
            so.edge ??
            edge ??
            (face == null ? null : fg.withValues(alpha: 0.28));
        final seamColour = seamInk == null
            ? null
            : face == null
            ? seamInk
            : Color.alphaBlend(seamInk, face);
        return Container(
          // One rim round both halves, over their fills.
          foregroundDecoration: minimalFrame(
            so.shape ?? t.shapes.small,
            side: so.rim(edge, t.rim),
          ),
          child: _Halves(
            main: Opacity(opacity: action == null ? 0.45 : 1, child: mainHalf),
            seam: Container(
              width: t.hairline,
              height: so.minimumSize?.height ?? h,
              color: seamColour,
            ),
            toggle: Opacity(opacity: menu.isEmpty ? 0.45 : 1, child: toggle),
          ),
        );
      },
      buttonBuilder: (context, part, states, open) => half(part, states, open),
      itemBuilder: (context, action, states) {
        final item = byLabel[action.label]!;
        final keys = item.shortcut;
        return MinimalKitRow(
          states: states,
          label: item.label,
          icon: item.icon,
          destructive: item.destructive,
          trailing: keys == null ? null : MinimalKbd.chord(keys),
        );
      },
      surfaceBuilder: (context, info, items) => minimalKitPresence(
        context,
        info,
        MinimalKitPanel(
          padding: const EdgeInsets.all(MinimalSpacing.s4),
          width: 200,
          maxHeight: info.maxSize.height,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (i, row) in items.indexed) ...[
                  if (i > 0 && menu[i].startsGroup)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: MinimalSpacing.s4,
                      ),
                      child: Container(height: t.hairline, color: t.border),
                    ),
                  row,
                ],
              ],
            ),
          ),
        ),
      ),
    );
    return MinimalHitTarget(child: split);
  }
}

/// The two halves with the seam between. A half's ring stands outside its
/// edge, over the seam and the edge of its neighbour, so the half the
/// keyboard is on paints last: the main half's focus lays the row out in
/// the opposite direction with its children reversed, which paints it
/// after the chevron and keeps every half where it stood.
class _Halves extends StatefulWidget {
  const _Halves({required this.main, required this.seam, required this.toggle});

  final Widget main;
  final Widget seam;
  final Widget toggle;

  @override
  State<_Halves> createState() => _HalvesState();
}

class _HalvesState extends State<_Halves> {
  /// Whether focus is in the main half.
  bool _lift = false;

  @override
  Widget build(BuildContext context) {
    // Keyed, so reversing the row moves each half rather than rebuilding
    // one in the other's place.
    final main = KeyedSubtree(
      key: const ValueKey(DesignSplitPart.main),
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        includeSemantics: false,
        onFocusChange: (focused) {
          if (mounted) setState(() => _lift = focused);
        },
        child: widget.main,
      ),
    );
    final seam = KeyedSubtree(key: const ValueKey(#seam), child: widget.seam);
    final toggle = KeyedSubtree(
      key: const ValueKey(DesignSplitPart.toggle),
      child: widget.toggle,
    );
    final direction = Directionality.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      textDirection: _lift
          ? switch (direction) {
              TextDirection.ltr => TextDirection.rtl,
              TextDirection.rtl => TextDirection.ltr,
            }
          : direction,
      children: _lift ? [toggle, seam, main] : [main, seam, toggle],
    );
  }
}
