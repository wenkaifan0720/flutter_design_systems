// The top bar and the page: the band that says whose service it is, the
// back link, the caption and the heading over a reading column.
import 'package:flutter/material.dart';
import 'package:civic_ui/civic_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

Widget kitPageDemo(Brightness brightness) => kitApp(
  brightness: brightness,
  home: CivicScaffold(
    skipLinkLabel: 'Skip to main content',
    topBar: CivicTopBar(
      title: 'Brindlemere parking permits',
      emblem: const KitEmblem(),
      onTitlePressed: () {},
      actions: [
        CivicIconButton(
          icon: LucideIcons.circleUser,
          semanticLabel: 'Your account',
          onPressed: () {},
        ),
      ],
    ),
    body: CivicPageBody(
      backLink: CivicBackLink(onPressed: () {}),
      caption: 'Apply for a resident permit',
      title: 'Top bar & page',
      children: const [
        Text(
          'The band says whose service this is; the page says where you are. '
          'A back link stands above the heading, a caption over it says which '
          'part of the service this is, and the words keep to a short line.',
        ),
        SizedBox(height: CivicSpacing.s24),
        CivicInset(
          child: Text(
            'From 600 wide a service shows its places down the start; below, '
            'along the bottom. The question pages show neither.',
          ),
        ),
        SizedBox(height: CivicSpacing.s32),
        _Bars(),
      ],
    ),
  ),
);

class _Bars extends StatelessWidget {
  const _Bars();

  @override
  Widget build(BuildContext context) => KitSection(
    title: 'Top bars',
    children: [
      const CivicTopBar(title: 'Brindlemere council'),
      CivicTopBar(
        title: 'Report a fault in a street light',
        emblem: const KitEmblem(),
        actions: [
          CivicIconButton(
            icon: LucideIcons.menu,
            semanticLabel: 'Menu',
            onPressed: () {},
          ),
        ],
      ),
    ],
  );
}
