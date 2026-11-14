/// The page group's demo: a live route stack of `ExpressivePage`s on a
/// plain `Navigator` — a journal's root, an entry pushed off it, and a note
/// pushed off the entry — so the platform's push and back can be felt: on
/// Android
/// the fade-forwards push and predictive back, on iOS the Cupertino slide
/// and its edge swipe.
library;

import 'package:flutter/material.dart';

import '../kit.dart';
import '../kit_stack.dart';

/// The page group's demo, in [brightness].
Widget kitPageDemo(Brightness brightness) =>
    KitStack(brightness: brightness, page: _page);

/// The journal's entries: a title and a first line each.
const List<(String, String, String)> _entries = <(String, String, String)>[
  (
    'tide-pools',
    'Tide pools at low water',
    'Anemones folded shut, a crab backing into the kelp.',
  ),
  (
    'first-frost',
    'First frost on the allotment',
    'The chard held; the last courgettes did not.',
  ),
  (
    'night-train',
    'The night train north',
    'Two stations of fog, then the lake under a full moon.',
  ),
];

/// The page `/`, `/entry/<id>` or `/entry/<id>/note` stands for.
Page<void> _page(String location, LocalKey key) {
  final parts = location.split('/').where((part) => part.isNotEmpty).toList();
  final Widget child = switch (parts) {
    ['entry', final id] => _Entry(id: id),
    ['entry', final id, 'note'] => _Note(id: id),
    _ => const _Journal(),
  };
  return kitRoutePage(key, child);
}

/// What the push and the back gesture are on [platform].
({String push, String back}) _behaviourOf(TargetPlatform platform) =>
    platform == TargetPlatform.iOS || platform == TargetPlatform.macOS
    ? (
        push:
            'Cupertino slide: the page slides in from the trailing edge, '
            'the page beneath trails a third of the way.',
        back:
            'Edge swipe: drag from the leading edge; the page follows '
            'your finger and settles either way on release.',
      )
    : (
        push:
            'Fade-forwards: the page travels 96dp and fades in while the '
            'page beneath travels 96dp the other way.',
        back:
            'Predictive back: swipe from either edge; the page shrinks '
            'to 90 %, shifts and rounds its corners, then commits or '
            'springs home.',
      );

class _Journal extends StatelessWidget {
  const _Journal();

  @override
  Widget build(BuildContext context) {
    final behaviour = _behaviourOf(Theme.of(context).platform);
    return KitPage(
      title: 'Journal',
      children: <Widget>[
        kitSection(
          'Push',
          children: <Widget>[
            Text(behaviour.push),
            for (final (id, title, _) in _entries)
              KitAction(
                title,
                onTap: () => KitStack.push(context, '/entry/$id'),
              ),
          ],
        ),
        kitSection(
          'Back',
          children: <Widget>[
            Text(behaviour.back),
            const Text(
              'The root page is the stack’s floor: there is nothing to go '
              'back to from here.',
            ),
          ],
        ),
      ],
    );
  }
}

(String, String, String) _entryOf(String id) =>
    _entries.firstWhere((entry) => entry.$1 == id, orElse: () => _entries[0]);

class _Entry extends StatelessWidget {
  const _Entry({required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    final (_, title, line) = _entryOf(id);
    final behaviour = _behaviourOf(Theme.of(context).platform);
    return KitPage(
      title: title,
      children: <Widget>[
        Text(line),
        kitSection(
          'Go deeper',
          children: <Widget>[
            KitAction(
              'Open the margin note',
              onTap: () => KitStack.push(context, '/entry/$id/note'),
            ),
          ],
        ),
        kitSection(
          'Back',
          children: <Widget>[
            Text(behaviour.back),
            KitAction(
              'Back to the journal',
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ],
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    final (_, title, _) = _entryOf(id);
    return KitPage(
      title: 'Margin note',
      children: <Widget>[
        Text('Pinned to “$title”.'),
        const Text(
          'Three pages deep: each back returns one page, and the page '
          'beneath is exactly where you left it.',
        ),
        kitSection(
          'Back',
          children: <Widget>[
            KitAction(
              'Back to the entry',
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ],
    );
  }
}
