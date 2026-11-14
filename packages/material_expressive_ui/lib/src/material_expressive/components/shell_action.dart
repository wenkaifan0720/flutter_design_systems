/// The shell's action (CONTRACT §4.2): [ExpressiveShellAction], the design
/// kit's `ShellAction` drawn as Expressive's floating action button, its
/// extended form or its FAB menu. Part of the host layer: an app's own
/// screens place an [ExpressiveFloatingActionButton] instead.
library;

import 'package:flutter/widgets.dart';
import 'package:ui_core/host.dart';

import '../shape.dart';
import '../strings.dart';
import '../theme.dart';
import 'fab.dart';
import 'hero.dart';
import 'nav.dart' show ExpressiveNavigationRail;
import 'splash.dart' show ExpressiveSplashScreenAnchor;

/// The shell's action (CONTRACT §4.2): the design kit's [ShellAction]
/// (icon, onPressed, label, accent, key) plus [menu]. As a spec it goes to
/// `ExpressiveShell(action:)`; as a widget — `ExpressiveShellAction(action:
/// spec)`, what the shell draws — it draws any spec by its type:
///
/// - a plain spec: the primary-container FAB (`accent` = the vibrant
///   primary FAB), its [label] announced;
/// - an [ExpressiveShellAction] with a [label]: the small extended FAB
///   printing it (a kit [ShellAction]'s label stays announced only),
///   wearing its [mark] in the icon's place when it has one, and
///   collapsing to its icon while a branch scrolls down when it says
///   [collapseOnScroll];
/// - an [ExpressiveShellAction] with a [menu] (2–5 items): the FAB menu, the
///   shell's hero moment (drawn inside its own [ExpressiveHeroMoment]); [onPressed],
///   when given, runs as the menu opens. A menu never opens from an
///   extended FAB: [label] and [menu] are exclusive. The items open in the
///   overlay, so the action's box (and the shell's band) stays the closed
///   toggle's. [accent] gives it the vibrant family, and [scrim] dims the
///   screen behind it while it is open. In a rail's header (the shell at
///   ≥ 600dp) the menu is never drawn (no FAB menu beside a rail, CONTRACT
///   §3): the plain FAB runs [onPressed].
///
/// The shell places it 16dp in from the end and above the bar
/// (`ScaffoldBehavior.fabSpacing`).
class ExpressiveShellAction extends StatelessWidget implements ShellAction {
  /// A spec ([icon] with [onPressed], or a [menu]), or — with [action] —
  /// the widget that draws [action]. [onPressed] is handed the context it
  /// was pressed in.
  const ExpressiveShellAction({
    IconData? icon,
    void Function(BuildContext context)? onPressed,
    this.label,
    this.accent = false,
    this.menu,
    this.scrim = false,
    this.semanticLabel,
    this.splashAnchor = false,
    this.expanded,
    this.onExpandedChanged,
    this.action,
    this.mark,
    this.collapseOnScroll = false,
    this.labelShown = true,
    super.key,
  }) : _icon = icon,
       _onPressed = onPressed,
       assert(
         (action == null) != (icon == null),
         'ExpressiveShellAction is a spec (icon:) or draws one (action:).',
       ),
       assert(
         action != null || onPressed != null || menu != null,
         'An ExpressiveShellAction without a menu needs onPressed.',
       ),
       assert(
         menu == null || label == null,
         'A FAB menu never opens from an extended FAB (CONTRACT §3): give '
         'the action a label or a menu, not both.',
       ),
       assert(
         menu == null || (menu.length >= 2 && menu.length <= 5),
         'A FAB menu holds 2–5 items (CONTRACT §3).',
       ),
       assert(!scrim || menu != null, 'Only a FAB menu dims the screen.'),
       assert(
         expanded == null || menu != null,
         'Only a FAB menu opens: expanded needs a menu.',
       ),
       assert(
         !collapseOnScroll || label != null || action != null,
         'Only an extended FAB collapses: collapseOnScroll needs a label.',
       );

  final IconData? _icon;
  final void Function(BuildContext context)? _onPressed;

  /// The spec this widget draws, when it draws another spec (the shell's
  /// `ExpressiveShellAction(action: spec)`).
  final ShellAction? action;

  @override
  IconData get icon => _icon ?? action!.icon;

  /// What a press runs: the constructor's `onPressed`, or the drawn spec's.
  @override
  void Function(BuildContext context) get onPressed =>
      _onPressed ?? action?.onPressed ?? _none;

  static void _none(BuildContext context) {}

  /// What the act does: announced, and printed on the extended FAB.
  @override
  final String? label;

  /// Whether the FAB wears the vibrant primary rather than the primary
  /// container; a menu then wears [ExpressiveFabMenuColor.vibrant].
  @override
  final bool accent;

  /// The FAB menu's acts, top to bottom: 2–5. Null for a plain or extended
  /// FAB.
  final List<ExpressiveFabMenuItem>? menu;

  /// Whether the open menu dims the screen behind it
  /// ([ExpressiveFabMenu.scrim]). Only with a [menu].
  final bool scrim;

  /// What the act is called, announced and never printed: the name a menu
  /// toggle or a plain FAB carries when it has no [label] (a menu can't
  /// take one, and a label on a plain spec prints an extended FAB). A
  /// [label], when given, is announced instead.
  final String? semanticLabel;

  /// Whether the FAB is where the app's splash lands
  /// ([ExpressiveSplashScreenAnchor], its large corner in the FAB's container
  /// colour): the shell's action on the page the app opens on.
  final bool splashAnchor;

  /// A FAB menu's open state, when the app holds it (opening the menu once
  /// to show what it offers); null leaves it to the menu. With it, the
  /// menu reports every open and close to [onExpandedChanged] and opens or
  /// closes only when [expanded] does.
  final bool? expanded;

  /// Told when a held menu asks to open or close.
  final ValueChanged<bool>? onExpandedChanged;

  /// An app's own mark in the icon's place on the extended FAB
  /// ([ExpressiveFloatingActionButton.mark]); the plain FAB and a menu wear [icon].
  final Widget? mark;

  /// Whether the extended FAB collapses to its icon while a branch root
  /// scrolls down and expands again when it scrolls up or returns to its
  /// top (Material's extended FAB guidance, as
  /// [ExpressiveFabScrollExpansion] does for a page's own FAB). The shell
  /// follows the scroll and draws the action with [labelShown].
  final bool collapseOnScroll;

  /// Whether an extended FAB shows its label: the shell sets it from the
  /// scroll when the spec says [collapseOnScroll]; always true otherwise.
  final bool labelShown;

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final spec = action ?? this;
    final expressive = spec is ExpressiveShellAction ? spec : null;
    final fab = _fab(context, spec, expressive);
    if (expressive == null || !expressive.splashAnchor) return fab;
    final besideRail =
        context.findAncestorWidgetOfExactType<ExpressiveNavigationRail>() !=
        null;
    final menu = besideRail ? null : expressive.menu;
    final container = menu != null
        ? (spec.accent
                  ? ExpressiveFabMenuColor.vibrant
                  : ExpressiveFabMenuColor.primary)
              .container
        : (spec.accent
                  ? ExpressiveFabColor.primary
                  : ExpressiveFabColor.primaryContainer)
              .container;
    return ExpressiveSplashScreenAnchor(
      corner: ExpressiveCorner.large,
      color: t.colors.role(container),
      child: fab,
    );
  }

  Widget _fab(
    BuildContext context,
    ShellAction spec,
    ExpressiveShellAction? expressive,
  ) {
    // Drawn from another spec, the walkthrough key goes on the hit target; a
    // spec drawn as itself carries its key as this widget's.
    final hitKey = action == null ? null : spec.key;
    final color = spec.accent
        ? ExpressiveFabColor.primary
        : ExpressiveFabColor.primaryContainer;
    final announced = spec.label ?? expressive?.semanticLabel;
    // A FAB menu never sits beside a rail (CONTRACT §3): in the rail's
    // header (the shell at ≥ 600dp) the action falls back to the plain FAB,
    // its [onPressed] the act.
    final besideRail =
        context.findAncestorWidgetOfExactType<ExpressiveNavigationRail>() !=
        null;
    final menu = besideRail ? null : expressive?.menu;
    if (menu != null) {
      return ExpressiveHeroMoment(
        label: ExpressiveLocalizations.of(context).fabMenu,
        child: ExpressiveFabMenu(
          buttonKey: hitKey,
          icon: spec.icon,
          semanticLabel: announced,
          items: menu,
          color: spec.accent
              ? ExpressiveFabMenuColor.vibrant
              : ExpressiveFabMenuColor.primary,
          scrim: expressive?.scrim ?? false,
          padded: false,
          // The shell measures the band its action stands in: the items
          // open in the overlay so the band stays the toggle's.
          overlayItems: true,
          expanded: expressive?.expanded,
          onExpandedChanged: (open) {
            if (open) spec.onPressed(context);
            expressive?.onExpandedChanged?.call(open);
          },
        ),
      );
    }
    final label = spec.label;
    if (expressive != null && label != null) {
      return ExpressiveFloatingActionButton.extended(
        key: hitKey,
        icon: spec.icon,
        mark: expressive.mark,
        label: label,
        expanded: labelShown,
        color: color,
        onPressed: () => spec.onPressed(context),
      );
    }
    return ExpressiveFloatingActionButton(
      key: hitKey,
      icon: spec.icon,
      color: color,
      semanticLabel: announced,
      onPressed: () => spec.onPressed(context),
    );
  }
}
