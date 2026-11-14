/// The top bar in each register its route earns (a tab's root under its
/// caption with the account's bell and avatar, a pushed page with its
/// derived way back, a sheet's head with its close) and the screen around
/// it: the page on the ground, the bar pinned over it on the acrylic on a phone,
/// a pushed page's footer band with its acts.
library;

import 'package:flutter/material.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';
import 'package:fluent2_design_ui/fluent2_design_host.dart';

import '../kit.dart';

Widget kitTopBarDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Top bar & screen',
  sections: [
    kitSection('A root', children: [kitSpecimenTopBarRoot()]),
    kitSection('With commands', children: [kitSpecimenTopBarCommands()]),
    kitSection('Pushed', children: [kitSpecimenTopBarPushed()]),
    kitSection('A sheet\'s head', children: [kitSpecimenTopBarSheet()]),
    kitSection(
      'A pushed page and its footer',
      children: [SizedBox(height: 520, child: kitSpecimenScreenFooter())],
    ),
  ],
);

class _Row extends StatelessWidget {
  const _Row(this.icon, this.title, this.meta, {this.trailing});

  final IconData icon;
  final String title;
  final String meta;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Fluent2Spacing.s),
      child: Row(
        spacing: Fluent2Spacing.m,
        children: [
          Icon(icon, size: Fluent2IconSize.i24, color: t.accentText),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: t.body1,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(meta, style: t.caption1.c(t.textSecondary)),
              ],
            ),
          ),
          if (trailing case final trailing?)
            Text(trailing, style: t.caption1.c(t.textTertiary)),
        ],
      ),
    );
  }
}

// --- Specimens --------------------------------------------------------------
// One builder per specimen in metadata.yaml. The stage (kitSpecimenStage)
// styles them; a builder never names a style.

/// Files, the root of its tab: the workspace's caption over the title, the
/// account's bell and avatar, a recent file list under the bar.
Widget kitSpecimenScreenHome() => Stack(
  fit: StackFit.expand,
  children: [
    Fluent2Scaffold(
      topBar: Fluent2AppBar(
        title: 'Files',
        caption: 'Northwind',
        actions: [
          Fluent2IconButton(
            Fluent2Icons.search,
            label: 'Search',
            onPressed: () {},
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          final t = context.fluent2Theme;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Fluent2Gap(Fluent2Spacing.s),
              Text('Recent', style: t.subtitle2),
              const Fluent2Gap(Fluent2Spacing.xs),
              const _Row(
                Fluent2Icons.documentText,
                'Launch plan.docx',
                'Kai Tanaka edited',
                trailing: '2h',
              ),
              const _Row(
                Fluent2Icons.dataBarVertical,
                'Q4 forecast.xlsx',
                'Mara Okafor commented',
                trailing: 'Mon',
              ),
              const _Row(
                Fluent2Icons.image,
                'Brand refresh.png',
                'You shared',
                trailing: 'Oct 28',
              ),
              const _Row(
                Fluent2Icons.board,
                'Design review deck',
                'Tomas Lindqvist edited',
                trailing: 'Oct 27',
              ),
              const Fluent2Gap(Fluent2Spacing.l),
              Text('Folders', style: t.subtitle2),
              const Fluent2Gap(Fluent2Spacing.xs),
              const _Row(Fluent2Icons.folder, 'Launch', '14 files'),
              const _Row(Fluent2Icons.folder, 'Research', '32 files'),
            ],
          );
        },
      ),
    ),
    Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Fluent2NavigationBar(
        items: kitTabs,
        selectedIndex: 3,
        onDestinationSelected: (_) {},
      ),
    ),
  ],
);

/// A pushed meeting's page and the act that joins it at the foot, with its
/// secondary (DERIVED: Fluent draws no page footer; the band is its
/// surface over a hairline).
Widget kitSpecimenScreenFooter() => kitInRegister(
  RoutePresentation.pushed,
  Fluent2Scaffold(
    topBar: Fluent2AppBar(
      title: 'Design review',
      backLabel: 'Calendar',
      actions: [
        Fluent2IconButton(
          Fluent2Icons.moreHorizontal,
          label: 'More',
          onPressed: () {},
        ),
      ],
    ),
    // The acts as a sheet's foot lays them: sharing the phone's width, at
    // their own widths at the end from the desktop's.
    footer: Fluent2SheetShell.footOf([
      Fluent2Button('Decline', onPressed: () {}),
      Fluent2Button(
        'Join',
        appearance: Fluent2ButtonAppearance.primary,
        icon: Fluent2Icons.video,
        onPressed: () {},
      ),
    ]),
    body: Builder(
      builder: (context) {
        final t = context.fluent2Theme;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Fluent2Gap(Fluent2Spacing.m),
            Text('Today, 15:00 – 15:45', style: t.subtitle1),
            const Fluent2Gap(Fluent2Spacing.xs),
            Text('Video call · Organizer Mara Okafor', style: t.body1),
            const Fluent2Gap(Fluent2Spacing.l),
            Fluent2AvatarGroup(people: kitPeople, max: 5),
            const Fluent2Gap(Fluent2Spacing.l),
            Text(
              'Walk through the launch screens and agree the last copy '
              'changes before Friday.',
              style: t.body1.c(t.textSecondary),
            ),
          ],
        );
      },
    ),
  ),
);

/// A bar on the page's gutter over the ground, as a screen's room holds it.
Widget _onGutter(Widget bar) => Builder(
  builder: (context) {
    final t = context.fluent2Theme;
    return ColoredBox(
      color: t.background,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: Fluent2Layout.gutter(context),
        ),
        child: bar,
      ),
    );
  },
);

Widget kitSpecimenTopBarRoot() =>
    _onGutter(const Fluent2AppBar(title: 'Chat', caption: 'Northwind'));

Widget kitSpecimenTopBarCommands() => _onGutter(
  Fluent2AppBar(
    title: 'Calendar',
    caption: 'November 2026',
    actions: [
      Fluent2IconButton(
        Fluent2Icons.calendarAdd,
        label: 'New event',
        onPressed: () {},
      ),
      Fluent2IconButton(Fluent2Icons.filter, label: 'Filter', onPressed: () {}),
    ],
  ),
);

Widget kitSpecimenTopBarPushed() => kitInRegister(
  RoutePresentation.pushed,
  _onGutter(
    Fluent2AppBar(
      title: 'Launch plan.docx',
      backLabel: 'Files',
      actions: [
        Fluent2IconButton(Fluent2Icons.share, label: 'Share', onPressed: () {}),
      ],
    ),
  ),
);

/// A sheet page's bar on its card: the head, the title and the close the
/// route derives, under the handle on a phone.
Widget kitSpecimenTopBarSheet() => kitInRegister(
  RoutePresentation.sheet,
  Fluent2SheetCard(
    child: Builder(
      builder: (context) => Padding(
        padding: Fluent2SheetShell.padding(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!Fluent2Layout.isWide(context)) const Fluent2SheetHandle(),
            const Fluent2AppBar(title: 'Share Launch plan'),
          ],
        ),
      ),
    ),
  ),
);
