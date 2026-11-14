/// Lists that do more than show: steps put in order by a drag, an inbox
/// refreshed by a pull, and a project's files as a tree, live.
library;

import 'package:flutter/material.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

Widget kitListBehavioursDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Reorder, refresh, tree',
  sections: [
    kitSection(
      'Reorder',
      children: [
        const _Steps(),
        kitNote('Drag a grip, or Alt ↑ ↓ from the keyboard.'),
      ],
    ),
    kitSection(
      'Pull to refresh',
      children: [
        const _Inbox(),
        kitNote('Pull past the top and let go; a screen reader gets Refresh.'),
      ],
    ),
    kitSection(
      'Tree',
      children: [
        const _Files(),
        kitNote(
          '↑ ↓ move, → opens or steps in, ← closes or steps out, * opens the '
          'siblings.',
        ),
      ],
    ),
  ],
);

const List<String> _run = [
  'Warm up for ten minutes',
  'Four intervals at tempo',
  'Easy jog home',
  'Stretch',
];

class _Steps extends StatefulWidget {
  const _Steps();

  @override
  State<_Steps> createState() => _StepsState();
}

class _StepsState extends State<_Steps> {
  final List<String> _steps = [..._run];

  @override
  Widget build(BuildContext context) => MinimalCard(
    padding: EdgeInsets.zero,
    child: MinimalReorderableListView<String>(
      items: _steps,
      labelOf: (s) => s,
      onReorder: (from, to) => setState(() {
        final s = _steps.removeAt(from);
        _steps.insert(to, s);
      }),
      itemBuilder: (context, s) => Text(s),
    ),
  );
}

class _Inbox extends StatefulWidget {
  const _Inbox();

  @override
  State<_Inbox> createState() => _InboxState();
}

class _InboxState extends State<_Inbox> {
  int _fresh = 0;

  Future<void> _reload() async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (mounted) setState(() => _fresh += 1);
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 240,
    child: MinimalCard(
      padding: EdgeInsets.zero,
      child: MinimalRefreshIndicator(
        onRefresh: _reload,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            for (var i = 0; i < _fresh; i++)
              MinimalListTile(
                title: 'New message ${_fresh - i}',
                subtitle: 'Just now',
                icon: LucideIcons.mail,
              ),
            const MinimalListTile(
              title: 'Ana Souza',
              subtitle: 'The draft is in your folder',
              icon: LucideIcons.mail,
            ),
            const MinimalListTile(
              title: 'Ben Okafor',
              subtitle: 'Moved the review to Thursday',
              icon: LucideIcons.mail,
            ),
            const MinimalListTile(
              title: 'Chen Wei',
              subtitle: 'Invoice 1042 paid',
              icon: LucideIcons.mail,
            ),
            // Enough mail to fill the box and run under its foot, as an
            // inbox does: three rows had left a third of it empty.
            const MinimalListTile(
              title: 'Dana Pike',
              subtitle: 'Lunch moved to one',
              icon: LucideIcons.mail,
            ),
            const MinimalListTile(
              title: 'Eli Brooks',
              subtitle: 'Shared the autumn plan',
              icon: LucideIcons.mail,
            ),
          ],
        ),
      ),
    ),
  );
}

class _Node {
  const _Node(this.name, [this.children = const []]);

  final String name;
  final List<_Node> children;
}

const List<_Node> _tree = [
  _Node('lib', [
    _Node('app', [_Node('router.dart'), _Node('theme.dart')]),
    _Node('pages', [_Node('today.dart'), _Node('habit.dart')]),
    _Node('main.dart'),
  ]),
  _Node('test', [_Node('widget_test.dart')]),
  _Node('pubspec.yaml'),
];

IconData _iconOf(_Node n, bool open) => n.children.isEmpty
    ? LucideIcons.file
    : open
    ? LucideIcons.folderOpen
    : LucideIcons.folder;

class _Files extends StatelessWidget {
  const _Files();

  @override
  Widget build(BuildContext context) => MinimalCard(
    padding: const EdgeInsets.all(MinimalSpacing.s4),
    child: MinimalTreeView<_Node>(
      label: 'Files',
      roots: _tree,
      childrenOf: (n) => n.children,
      labelOf: (n) => n.name,
      initiallyExpanded: [_tree.first],
      iconOf: _iconOf,
      onActivate: (n) => showMinimalSnackBar(context, n.name),
    ),
  );
}

// --- catalog specimens -------------------------------------------------------

/// Four steps, each with its grip.
Widget kitSpecimenReorderableList() => Padding(
  padding: const EdgeInsets.all(MinimalSpacing.s16),
  child: MinimalCard(
    padding: EdgeInsets.zero,
    child: MinimalReorderableListView<String>(
      items: _run,
      labelOf: (s) => s,
      onReorder: (from, to) {},
      itemBuilder: (context, s) => Text(s),
    ),
  ),
);

/// A project's files, its first folder open.
Widget kitSpecimenTreeView() => Padding(
  padding: const EdgeInsets.all(MinimalSpacing.s16),
  child: MinimalCard(
    padding: const EdgeInsets.all(MinimalSpacing.s4),
    child: MinimalTreeView<_Node>(
      label: 'Files',
      roots: _tree,
      childrenOf: (n) => n.children,
      labelOf: (n) => n.name,
      initiallyExpanded: [_tree.first],
      iconOf: _iconOf,
    ),
  ),
);
