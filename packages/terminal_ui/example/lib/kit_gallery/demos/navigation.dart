/// Getting around: [TermTopBar], [TermTabBar], the window list at a phone's
/// foot ([TermNavigationBar]), the side pane at a desk ([TermSideBar]) with
/// its [TermNavigationDestination]s, and [TermStatusLine].
library;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:terminal_ui/terminal_ui.dart';

import '../kit.dart';

Widget kitNavigationDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'navigation',
  sections: [const _Live()],
);

const _places = [
  TermNavigationDestination(
    label: 'home',
    glyph: '~',
    shortcut: SingleActivator(LogicalKeyboardKey.digit1, alt: true),
  ),
  TermNavigationDestination(
    label: 'runs',
    glyph: '#',
    shortcut: SingleActivator(LogicalKeyboardKey.digit2, alt: true),
  ),
  TermNavigationDestination(label: 'deploy', glyph: '↑', badge: '1'),
  TermNavigationDestination(label: 'config', glyph: '='),
];

class _Live extends StatefulWidget {
  const _Live();

  @override
  State<_Live> createState() => _LiveState();
}

class _LiveState extends State<_Live> {
  int _place = 1;
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final grid = context.termGrid;
    return kitSection(
      'live',
      children: [
        TermTopBar(
          title: 'slipway',
          subtitle: 'atlas-api › ${_places[_place].label}',
          actions: [
            TermIconButton(
              glyph: '/',
              semanticLabel: 'search',
              onPressed: () {},
            ),
          ],
        ),
        TermTabBar(
          tabs: const ['steps', 'log', 'env'],
          selectedIndex: _tab,
          onTap: (i) => setState(() => _tab = i),
        ),
        SizedBox(
          width: grid.cols(26),
          child: TermSideBar(
            title: 'harbor',
            destinations: _places,
            selectedIndex: _place,
            onDestinationSelected: (i) => setState(() => _place = i),
          ),
        ),
        TermNavigationBar(
          destinations: _places,
          selectedIndex: _place,
          onDestinationSelected: (i) => setState(() => _place = i),
        ),
        TermStatusLine(
          mode: _places[_place].label.toUpperCase(),
          segments: const [
            TermStatusSegment('atlas-api'),
            TermStatusSegment('\u{E0A0} main', semanticLabel: 'branch main'),
          ],
          keys: const [(keys: 'M-1…4', label: 'go')],
        ),
      ],
    );
  }
}
