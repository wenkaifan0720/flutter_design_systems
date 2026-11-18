/// Lists and panes: [TermPane], the frame with its title in the top line,
/// [TermListTile] rows with the chosen one in inverse video, and
/// [TermSectionHeader].
library;

import 'package:material_ui/material_ui.dart';
import 'package:terminal_ui/terminal_ui.dart';

import '../kit.dart';
import '../slipway.dart';

Widget kitListsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'lists & panes',
  sections: [
    kitSection(
      'a pane',
      children: [
        const TermPane(
          title: 'atlas-api',
          trailing: 'production',
          footer: '⏎ open',
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text('last deploy 6m ago, from fix/flaky-auth.'),
          ),
        ),
      ],
    ),
    kitSection('a list in a pane', children: [const _Runs()]),
    kitSection(
      'a pane that floats',
      children: [
        const TermPane(
          title: 'note',
          raised: true,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'a raised pane casts a shade a cell across, half a line down.',
            ),
          ),
        ),
      ],
    ),
    kitSection(
      'a header',
      children: [const TermSectionHeader(title: 'recent runs', trailing: '7')],
    ),
  ],
);

class _Runs extends StatefulWidget {
  const _Runs();

  @override
  State<_Runs> createState() => _RunsState();
}

class _RunsState extends State<_Runs> {
  int _selected = 1481;

  @override
  Widget build(BuildContext context) => TermPane.list(
    title: 'runs',
    trailing: '4',
    children: [
      for (final run in slipwayRuns.take(4))
        TermListTile(
          leading: StatusGlyph(run.status),
          title: Text('#${run.number} ${run.project}'),
          subtitle: Text('${run.commit} · ${run.branch}'),
          trailing: Text(run.duration),
          selected: run.number == _selected,
          onTap: () => setState(() => _selected = run.number),
        ),
      const TermListTile(
        leading: Text('–'),
        title: Text('#376 mobile-gateway'),
        subtitle: Text('archived'),
        enabled: false,
      ),
    ],
  );
}
