/// [FrostedTabBar]: a short row sharing the width, a long one scrolling and an
/// inert one, each the sidebar's lit pill under the chosen section.
library;

import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';

import '../kit.dart';

Widget kitTabsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Tabs',
  sections: [
    kitSection(
      'Sharing the width',
      children: [
        StatefulBuilder(
          builder: (context, setState) => _Chosen(
            builder: (index, set) => FrostedTabBar(
              tabs: const ['Spending', 'Income', 'Transfers'],
              selectedIndex: index,
              expand: true,
              onChanged: set,
            ),
          ),
        ),
      ],
    ),
    kitSection(
      'Scrolling',
      children: [
        _Chosen(
          builder: (index, set) => FrostedTabBar(
            tabs: const [
              'Cards',
              'Budgets',
              'Goals',
              'Reports',
              'Alerts',
              'Limits',
              'Rewards',
            ],
            selectedIndex: index,
            label: 'More sections',
            onChanged: set,
          ),
        ),
      ],
    ),
    kitSection(
      'Inert',
      children: [
        const FrostedTabBar(
          tabs: ['Spending', 'Income'],
          selectedIndex: 0,
          expand: true,
          onChanged: null,
        ),
      ],
    ),
    kitSection(
      'Specimens',
      children: [kitSpecimenTabsFit(), kitSpecimenTabsScroll()],
    ),
  ],
);

/// Three sections sharing the width, the first chosen.
Widget kitSpecimenTabsFit() => FrostedTabBar(
  tabs: const ['Spending', 'Income', 'Transfers'],
  selectedIndex: 0,
  expand: true,
  onChanged: (_) {},
);

/// Seven sections scrolling past the edge, the second chosen.
Widget kitSpecimenTabsScroll() => FrostedTabBar(
  tabs: const [
    'Cards',
    'Budgets',
    'Goals',
    'Reports',
    'Alerts',
    'Limits',
    'Rewards',
  ],
  selectedIndex: 1,
  label: 'More sections',
  onChanged: (_) {},
);

/// The page's own choice of tab, kept for the demo.
class _Chosen extends StatefulWidget {
  const _Chosen({required this.builder});

  final Widget Function(int index, ValueChanged<int> set) builder;

  @override
  State<_Chosen> createState() => _ChosenState();
}

class _ChosenState extends State<_Chosen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) =>
      widget.builder(_index, (i) => setState(() => _index = i));
}
