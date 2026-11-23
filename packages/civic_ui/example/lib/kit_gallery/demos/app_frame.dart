// The frame an app built on Civic stands its pages in: its places (a bar
// along a phone's foot, a column down the start from 600 wide) with the
// app's one act beside them, a page in its reading column, and the plain
// field a generated page asks with.
import 'package:material_ui/material_ui.dart';
import 'package:civic_ui/civic_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

const _places = [
  CivicNavItem(LucideIcons.house, 'Home'),
  CivicNavItem(LucideIcons.fileText, 'Applications'),
  CivicNavItem(LucideIcons.circleUser, 'Account'),
];

Widget kitAppFrameDemo(Brightness brightness) =>
    kitApp(brightness: brightness, home: const _Frame());

class _Frame extends StatefulWidget {
  const _Frame();

  @override
  State<_Frame> createState() => _FrameState();
}

class _FrameState extends State<_Frame> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final text = context.civicText;
    return CivicShellFrame(
      destinations: _places,
      selectedIndex: _index,
      onDestinationSelected: (i) => setState(() => _index = i),
      brand: 'Brindlemere parking permits',
      action: CivicShellAction(
        icon: LucideIcons.plus,
        label: 'Apply for a permit',
        accent: true,
        onPressed: (_) {},
      ),
      child: CivicScreen(
        skipLinkLabel: 'Skip to main content',
        // The service is named once, over its places from 1024 wide; the bar
        // names the place, as the gallery's own app does.
        topBar: CivicTopBar(title: _places[_index].label),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text('Find your zone', style: text.headingXL),
            ),
            const SizedBox(height: CivicSpacing.s16),
            const Text(
              'A page stands in its reading column with the page\'s margins, '
              'and scrolls when it is long. The places stay beside it: along '
              'the foot of a phone, the act at the end; down the start from '
              '600 wide, the act at their foot.',
            ),
            const SizedBox(height: CivicSpacing.s32),
            CivicInput(
              labelText: 'Your street',
              hintText: 'For example, Harbour Row',
              onChanged: (_) {},
            ),
            const SizedBox(height: CivicSpacing.s48),
            CivicButton.label('Find my zone', onPressed: () {}),
          ],
        ),
      ),
    );
  }
}
