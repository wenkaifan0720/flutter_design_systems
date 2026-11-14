import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:ui_core/host.dart';

import '../chrome_metrics.dart';
import '../internal/icon_fill.dart';
import '../internal/measure.dart';
import '../internal/well.dart';
import '../localizations.dart';
import '../styled.dart';
import '../theme.dart';
import 'acrylic.dart';
import 'pressable/pressable.dart';

/// One destination of the tab bar and the nav pane, as generated apps
/// declare a tab: its [icon] (Fluent's regular design), the [label]
/// printed under it (and spoken) and the walkthrough [key] set on its hit
/// target, positionally. While selected it wears its [selectedIcon]
/// (Fluent's filled design; null wears [icon]'s filled twin) in the brand; its root
/// stands on its [ground].
///
/// ```dart
/// Fluent2NavItem(Fluent2Icons.home, 'Home', ValueKey('open-home'))
/// ```
@immutable
class Fluent2NavItem {
  /// A destination showing [icon] and [label].
  const Fluent2NavItem(this.icon, this.label, [this.key, this.selectedIcon])
    : ground = ChromeGround.surface;

  /// The item a runtime [NavTab] asks for.
  Fluent2NavItem.fromTab(NavTab tab)
    : icon = tab.icon,
      label = tab.label,
      selectedIcon = tab.selectedIcon,
      key = tab.key,
      ground = tab.ground;

  /// The destination's glyph.
  final IconData icon;

  /// The destination's word, under the glyph and spoken.
  final String label;

  /// The glyph while selected (Fluent's filled design); null wears
  /// [icon]'s filled twin.
  final IconData? selectedIcon;

  /// The key on its hit target, for tests and walkthroughs.
  final Key? key;

  /// The ground its root page stands on.
  final ChromeGround ground;
}

/// The phone tab bar, Fluent 2's mobile tab bar: the acrylic under a hairline
/// along its top, 56 tall over the device inset; the tabs share its width
/// evenly, each its glyph 2 over its word in caption1 (every word whole and
/// at one size, 8 in from its tab's sides: as the reader's text grows the
/// words grow only while all of them fit, as iOS keeps a tab bar's), at rest the regular
/// glyph in the third ink, selected the filled glyph and the word in the
/// brand under a short brand mark along the bar's top. An [accessory]
/// stands 8 over the bar; the shell's act floats over its end
/// ([Fluent2FloatingActionButton]). On the media ground ([solid]) the bar, and the room
/// over it the act and accessory stand in, are the dark surface and
/// nothing blurs.
///
/// The shell mounts the one bar at the foot of every root; a page never
/// composes navigation.
///
/// ```dart
/// Fluent2NavigationBar(items: tabs, selectedIndex: 0, onDestinationSelected: select)
/// ```
class Fluent2NavigationBar extends StatelessWidget {
  /// A phone tab bar of [items].
  const Fluent2NavigationBar({
    required this.items,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.accessory,
    this.action,
    this.solid = false,
    super.key,
  });

  /// The destinations, three to five.
  final List<Fluent2NavItem> items;

  /// The index of the selected tab.
  final int selectedIndex;

  /// Called with a tab's index when it is pressed.
  final ValueChanged<int> onDestinationSelected;

  /// What rides over the bar (a now-playing strip, a call in progress).
  final Widget? accessory;

  /// The shell's act, floating over the bar's end.
  final ShellAction? action;

  /// Paint the solid ground and blur nothing (the media ground).
  final bool solid;

  /// The bar's height over a bottom [inset]: the bar and the inset under
  /// it.
  static double heightIn(double inset) =>
      Fluent2ChromeMetrics.tabBarHeight + inset;

  /// How far the shell's act rises over the bar's top: the button and the
  /// gap under it.
  static const double actionRise =
      Fluent2ChromeMetrics.fab + Fluent2ChromeMetrics.fabInset;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final inset = MediaQuery.paddingOf(context).bottom;
    final bar = Fluent2Acrylic(
      solid: solid,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: t.colors.neutralStroke2)),
        ),
        child: Padding(
          padding: EdgeInsets.only(bottom: inset),
          child: LayoutBuilder(
            builder: (context, box) {
              // Every label whole, one size across the bar, 8 in from its
              // tab's sides (so from the screen's edge): the reader's text
              // size where all fit, else the largest at which they do (iOS
              // and Fluent's iOS tab bar keep these words at their size as
              // text grows; never an ellipsis). The bar grows by what that
              // line grows.
              final scale = fluent2FitScale(
                context,
                [for (final item in items) item.label],
                t.caption1Strong,
                box.maxWidth / math.max(1, items.length) -
                    2 * Fluent2ChromeMetrics.tabLabelSide,
              );
              final size = t.caption1.fontSize ?? 12;
              final grown = (scale - 1) * size * (t.caption1.height ?? 1);
              return SizedBox(
                height: Fluent2ChromeMetrics.tabBarHeight + math.max(0, grown),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (i, item) in items.indexed)
                      Expanded(
                        child: _Tab(
                          item: item,
                          selected: i == selectedIndex,
                          scale: scale,
                          onTap: () => onDestinationSelected(i),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
    final act = action;
    final stack = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (act != null)
          Padding(
            padding: const EdgeInsetsDirectional.only(
              end: Fluent2ChromeMetrics.fabInset,
              bottom: Fluent2ChromeMetrics.fabInset,
            ),
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Fluent2FloatingActionButton(
                key: act.key,
                icon: act.icon,
                label: act.label,
                onPressed: () => act.onPressed(context),
              ),
            ),
          ),
        if (accessory != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Fluent2ChromeMetrics.gutter,
              0,
              Fluent2ChromeMetrics.gutter,
              Fluent2ChromeMetrics.accessoryGap,
            ),
            child: accessory,
          ),
        bar,
      ],
    );
    // On the media ground the shell ends the page above the act and the
    // accessory, so they stand on the bar's dark surface, not on nothing.
    return solid ? ColoredBox(color: t.acrylic.fallback, child: stack) : stack;
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.item,
    required this.selected,
    required this.scale,
    required this.onTap,
  });

  final Fluent2NavItem item;
  final bool selected;

  /// The text scale the bar's labels share.
  final double scale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    return Fluent2Pressable(
      key: item.key,
      onPressed: onTap,
      label: item.label,
      selected: selected,
      radius: Fluent2Radius.medium,
      builder: (context, states) {
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
                      selected
                          ? (item.selectedIcon ?? fluent2Filled(item.icon))
                          : item.icon,
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
                          item.label,
                          maxLines: 1,
                          softWrap: false,
                          textAlign: TextAlign.center,
                          textScaler: TextScaler.linear(scale),
                          style: (selected ? t.caption1Strong : t.caption1).c(
                            ink,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        });
      },
    );
  }
}

/// Fluent 2's floating action button, the shell's act on a phone: a 56
/// disc of the brand with its glyph 24 in the ink on brand, in the brand's
/// `shadow8`; with [label] the extended button, a 48 pill with the glyph 8
/// before the words. Read as a button named [label] (or [semanticLabel]).
///
/// ```dart
/// Fluent2FloatingActionButton(icon: Fluent2Icons.edit, label: 'New message', onPressed: compose)
/// ```
class Fluent2FloatingActionButton extends StatelessWidget {
  /// A floating action button showing [icon].
  const Fluent2FloatingActionButton({
    required this.icon,
    required this.onPressed,
    this.label,
    this.semanticLabel,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  /// The glyph on its face.
  final IconData icon;

  /// Called when it is pressed.
  final VoidCallback? onPressed;

  /// The words of the extended button; null draws the disc.
  final String? label;

  /// What a screen reader says; null says [label].
  final String? semanticLabel;

  /// The control's focus node; null makes and disposes its own.
  final FocusNode? focusNode;

  /// Whether the control takes focus when it first builds.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final words = label;
    final extended = words != null && words.isNotEmpty;
    final h = extended
        ? Fluent2ChromeMetrics.fabExtended
        : Fluent2ChromeMetrics.fab;
    // Its own size wherever it stands: a column that stretches its
    // children never runs it across.
    final fab = Fluent2Pressable(
      focusNode: focusNode,
      autofocus: autofocus,
      onPressed: onPressed,
      label: semanticLabel ?? words ?? Fluent2Localizations.of(context).create,
      radius: h / 2,
      builder: (context, states) {
        // Disabled, it is Fluent's disabled primary button: the grey fill,
        // the disabled ink and no lift.
        final off = states.press == Fluent2Press.disabled;
        final ink = off
            ? t.colors.neutralForegroundDisabled
            : t.colors.neutralForegroundOnBrand;
        return fluent2EasedInks(
          [
            ink,
            states.press.pick(
              t.colors.brandBackground,
              t.colors.brandBackgroundHover,
              t.colors.brandBackgroundPressed,
              fluent2WellDisabled(t),
            ),
          ],
          (context, inks) {
            final [ink, fabFill] = inks;
            return Container(
              height: h,
              width: extended ? null : h,
              padding: extended
                  ? const EdgeInsets.symmetric(horizontal: Fluent2Spacing.l)
                  : null,
              decoration: BoxDecoration(
                color: fabFill,
                borderRadius: BorderRadius.circular(h / 2),
                boxShadow: off ? null : t.brandShadows.shadow8,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: Fluent2Spacing.s,
                children: [
                  Icon(icon, size: Fluent2ChromeMetrics.fabGlyph, color: ink),
                  if (extended)
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 200),
                      child: Text(
                        words,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.body1Strong.c(ink),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
    return Align(
      alignment: AlignmentDirectional.centerStart,
      widthFactor: 1,
      heightFactor: 1,
      child: fab,
    );
  }
}

/// The least a tab bar's allowance can be: its bar over [inset], and the
/// act's rise when it floats over it. Plumbing of the shell.
double fluent2BarAllowance(double inset, {bool action = false}) =>
    Fluent2NavigationBar.heightIn(inset) +
    (action ? math.max(0, Fluent2NavigationBar.actionRise) : 0);
