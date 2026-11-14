/// Minimal's command palette: raised live in its card (type, arrow keys,
/// Enter), and composed statically in a card — the full grouped list with
/// a disabled action, a filtered search, and the empty result.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

Widget kitCommandDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Command palette',
  sections: [
    kitSection(
      'Live',
      children: [
        const _Launcher(),
        kitNote(
          'Type to filter, ↑ ↓ to move, ↵ to run. The action runs once the '
          'card has closed.',
        ),
      ],
    ),
    kitSection(
      'Palette',
      children: [
        Builder(
          builder: (context) => _Panel(
            child: MinimalCommand(
              actions: _actions(context),
              autofocus: false,
              onSelected: (action) =>
                  showMinimalSnackBar(context, action.label),
            ),
          ),
        ),
        kitNote(
          'Export as CSV needs a paid plan, so it shows dimmed and cannot '
          'run.',
        ),
      ],
    ),
    kitSection(
      'Filtered',
      children: [
        Builder(
          builder: (context) => _Panel(
            child: MinimalCommand(
              actions: _actions(context),
              initialQuery: 'mark',
              autofocus: false,
              onSelected: (action) =>
                  showMinimalSnackBar(context, action.label),
            ),
          ),
        ),
      ],
    ),
    kitSection(
      'No match',
      children: [
        Builder(
          builder: (context) => _Panel(
            child: MinimalCommand(
              actions: _actions(context),
              initialQuery: 'invoice',
              autofocus: false,
            ),
          ),
        ),
      ],
    ),
  ],
);

/// Ritual's commands, each confirming with a toast in [context].
List<MinimalCommandItem> _actions(BuildContext context) {
  void say(String message) => showMinimalSnackBar(context, message);
  return [
    MinimalCommandItem(
      'New habit',
      icon: LucideIcons.plus,
      group: 'Habits',
      shortcut: 'N',
      keywords: const ['create', 'add'],
      onSelected: () => say('New habit'),
    ),
    MinimalCommandItem(
      'Mark Morning run done',
      icon: LucideIcons.circleCheck,
      group: 'Habits',
      // A detail or a shortcut, not both: at the largest text the three
      // overrun a phone's row and the detail ellipsizes.
      detail: 'HAB-4',
      keywords: const ['complete', 'check'],
      onSelected: () => say('Morning run marked done'),
    ),
    MinimalCommandItem(
      'Mark all morning habits done',
      icon: LucideIcons.listChecks,
      group: 'Habits',
      onSelected: () => say('3 habits marked done'),
    ),
    MinimalCommandItem(
      'Move reminder',
      icon: LucideIcons.bell,
      group: 'Habits',
      detail: '07:00',
      onSelected: () => say('Reminder picker'),
    ),
    MinimalCommandItem(
      'Go to Today',
      icon: LucideIcons.calendarCheck,
      group: 'Navigate',
      shortcut: 'G T',
      onSelected: () => say('Today'),
    ),
    MinimalCommandItem(
      'Go to Trends',
      icon: LucideIcons.activity,
      group: 'Navigate',
      shortcut: 'G R',
      onSelected: () => say('Trends'),
    ),
    const MinimalCommandItem(
      'Export as CSV',
      icon: LucideIcons.download,
      group: 'Data',
      keywords: ['download', 'backup'],
    ),
    MinimalCommandItem(
      'Switch appearance',
      icon: LucideIcons.sunMoon,
      group: 'Data',
      shortcut: '⌘ ⇧ L',
      keywords: const ['dark', 'light', 'theme'],
      onSelected: () => say('Appearance switched'),
    ),
  ];
}

/// Raises the palette in its sheet and prints what ran.
class _Launcher extends StatefulWidget {
  const _Launcher();

  @override
  State<_Launcher> createState() => _LauncherState();
}

class _LauncherState extends State<_Launcher> {
  Future<void> _open() async {
    final chosen = await MinimalCommand.show(
      context,
      subtitle: 'Habits',
      actions: _actions(context),
    );
    if (!mounted || chosen == null) return;
    // The chosen action has run; here a toast stands for its effect.
    showMinimalSnackBar(context, chosen.label, icon: chosen.icon);
  }

  @override
  Widget build(BuildContext context) => kitRow([
    MinimalButton(
      'Command menu',
      icon: LucideIcons.command,
      variant: MinimalButtonVariant.secondary,
      onPressed: _open,
    ),
  ]);
}

// --- catalog specimens -------------------------------------------------------
//
// MinimalCommand.show raises the palette in a card a third of the way down
// a dimmed page; each specimen stands it there. The stage
// (kitSpecimenStage) styles it; a builder never names a style.

/// Every action grouped, each with its glyph and shortcut caps.
Widget kitSpecimenCommandPalette() => Builder(
  builder: (context) => _Raised(
    child: MinimalCommand(actions: _actions(context), autofocus: false),
  ),
);

/// The palette filtered by what has been typed.
Widget kitSpecimenCommandFiltered() => Builder(
  builder: (context) => _Raised(
    child: MinimalCommand(
      actions: _actions(context),
      initialQuery: 'mark',
      autofocus: false,
    ),
  ),
);

/// A palette composed in a page: on a card, padded as the shown one is.
class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // The search field stands in a 44 px band; the card takes the band's
    // air over the box off its top, so the field is 8 px from every edge.
    final t = context.minimalTheme;
    final line = MediaQuery.textScalerOf(context).scale(16);
    final box =
        t.density.height(MinimalChromeMetrics.control) +
        math.max(0.0, line - 16);
    final air = math.max(0.0, (MinimalLayout.minHitTarget - box) / 2);
    return MinimalCard(
      padding: EdgeInsets.fromLTRB(
        MinimalSpacing.s8,
        math.max(0.0, MinimalSpacing.s8 - air),
        MinimalSpacing.s8,
        MinimalSpacing.s8,
      ),
      child: child,
    );
  }
}

/// Stands the palette's card where [MinimalCommand.show] raises it — a third
/// of the way down, at most 560 wide — over the dimmed page, as one still
/// frame of the open palette.
class _Raised extends StatelessWidget {
  const _Raised({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      ColoredBox(color: context.minimalTheme.overlay),
      Align(
        alignment: const Alignment(0, -0.5),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: MinimalChromeMetrics.gutter,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: _Panel(child: child),
          ),
        ),
      ),
    ],
  );
}
