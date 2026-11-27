/// The faces of Fluent 2's navigation destinations, each drawn for a press's
/// states: the phone tab bar's tab and the nav pane's item (its glyph alone
/// when folded to a rail). The standalone [Fluent2NavigationBar] and
/// [Fluent2NavigationDrawer] and the app shell draw their destinations with
/// them, so the three look alike. Not exported.
library;

import 'package:flutter/widgets.dart';

import '../chrome_metrics.dart';
import '../components/nav_bar.dart';
import '../components/nav_pane.dart';
import '../components/pressable/pressable.dart';
import '../styled.dart';
import '../theme.dart';
import 'cap_label.dart';
import 'icon_fill.dart';
import 'well.dart';

/// A phone tab bar's tab in [states]: its [icon] over its [label] at the
/// bar's shared [scale], the brand's mark along the top while [selected].
class Fluent2TabFace extends StatelessWidget {
  /// The tab showing [icon] over [label].
  const Fluent2TabFace({
    super.key,
    required this.icon,
    this.selectedIcon,
    required this.label,
    required this.selected,
    required this.scale,
    required this.states,
  });

  /// Its glyph.
  final IconData icon;

  /// Its glyph while [selected]; the filled [icon] when null.
  final IconData? selectedIcon;

  /// Its name.
  final String label;

  /// Whether it is the current one.
  final bool selected;

  /// The text scale the bar's labels share.
  final double scale;

  /// The press's states.
  final Set<WidgetState> states;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final press = states.press;
    final ink = selected
        ? t.colors.compoundBrandForeground1
        : press.pick(
            t.colors.neutralForeground3,
            t.colors.neutralForeground3Hover,
            t.colors.neutralForeground3Pressed,
          );
    return fluent2EasedInks([ink], (context, inks) {
      final [ink] = inks;
      return Stack(
        children: [
          if (selected)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: Fluent2ChromeMetrics.tabMarkWidth,
                  height: Fluent2ChromeMetrics.tabMarkHeight,
                  decoration: BoxDecoration(
                    color: t.colors.compoundBrandForeground1,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(Fluent2Radius.circular),
                    ),
                  ),
                ),
              ),
            ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: Fluent2ChromeMetrics.tabGap,
              children: [
                Icon(
                  selected ? (selectedIcon ?? fluent2Filled(icon)) : icon,
                  size: Fluent2ChromeMetrics.tabGlyph,
                  color: ink,
                ),
                // Whole, at the bar's shared scale; a hair over its
                // room (a font's rounding) is drawn smaller, not cut.
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Fluent2ChromeMetrics.tabLabelSide,
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      maxLines: 1,
                      softWrap: false,
                      textAlign: TextAlign.center,
                      textScaler: TextScaler.linear(scale),
                      style: (selected ? t.caption1Strong : t.caption1).c(ink),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }
}

/// A nav pane's item in [states]: 40 tall, its glyph 20 and 16 before its
/// [label], a subtle fill under the pointer and while [selected], the
/// selection indicator at its start; [collapsed], the glyph alone.
class Fluent2PaneItemFace extends StatelessWidget {
  /// The item showing [icon] and [label].
  const Fluent2PaneItemFace({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.states,
    this.selectedIcon,
    this.collapsed = false,
    this.trailing,
  });

  /// The glyph.
  final IconData icon;

  /// The glyph while selected; null wears [icon]'s filled twin.
  final IconData? selectedIcon;

  /// The words.
  final String label;

  /// Whether it is the current destination.
  final bool selected;

  /// The press's states.
  final Set<WidgetState> states;

  /// Whether the pane is a rail, the item its glyph alone.
  final bool collapsed;

  /// What stands at the item's end (a count).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final press = states.press;
    final fill = selected
        ? press.pick(
            fluent2Step(t, t.colors.subtleBackgroundSelected),
            fluent2Step(t, t.colors.subtleBackgroundHover),
            fluent2Step(t, t.colors.subtleBackgroundPressed),
          )
        : press.pick(
            t.colors.subtleBackground,
            fluent2Step(t, t.colors.subtleBackgroundHover),
            fluent2Step(t, t.colors.subtleBackgroundPressed),
          );
    // Disabled, the glyph and the words take the disabled ink.
    final off = press == Fluent2Press.disabled;
    final ink = off
        ? t.colors.neutralForegroundDisabled
        : selected
        ? t.colors.neutralForeground1
        : press.pick(
            t.colors.neutralForeground2,
            t.colors.neutralForeground2Hover,
            t.colors.neutralForeground2Pressed,
          );
    return fluent2EasedInks(
      [
        fill,
        ink,
        selected && !off ? t.colors.neutralForeground2BrandSelected : ink,
      ],
      (context, inks) {
        final [fill, ink, glyphInk] = inks;
        final glyph = Icon(
          selected
              ? (selectedIcon ?? fluent2Filled(icon))
              : press == Fluent2Press.hover || press == Fluent2Press.pressed
              ? fluent2Filled(icon)
              : icon,
          size: Fluent2IconSize.i20,
          color: glyphInk,
        );
        return Container(
          height: Fluent2ChromeMetrics.paneItem,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(Fluent2Radius.medium),
          ),
          // The glyph and the words stand in the item's middle (a stack
          // leaves a loose child at its top).
          child: Stack(
            alignment: AlignmentDirectional.centerStart,
            children: [
              if (selected)
                PositionedDirectional(
                  start: 0,
                  top:
                      (Fluent2ChromeMetrics.paneItem -
                          Fluent2ChromeMetrics.paneIndicatorHeight) /
                      2,
                  child: Container(
                    width: Fluent2ChromeMetrics.paneIndicatorWidth,
                    height: Fluent2ChromeMetrics.paneIndicatorHeight,
                    decoration: BoxDecoration(
                      color: t.colors.compoundBrandForeground1,
                      borderRadius: BorderRadius.circular(
                        Fluent2Radius.circular,
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: EdgeInsetsDirectional.only(
                  start: collapsed ? 0 : Fluent2ChromeMetrics.paneItemStart,
                  end: collapsed ? 0 : Fluent2ChromeMetrics.paneItemEnd,
                ),
                child: collapsed
                    ? Center(child: glyph)
                    : Row(
                        spacing: Fluent2ChromeMetrics.paneItemGap,
                        children: [
                          glyph,
                          // A destination's name stays whole: one
                          // longer than the pane is drawn smaller,
                          // never cut.
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: AlignmentDirectional.centerStart,
                              child: fluent2CapCentred(
                                Text(
                                  label,
                                  maxLines: 1,
                                  softWrap: false,
                                  style: (selected ? t.body1Strong : t.body1).c(
                                    ink,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          ?trailing,
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
