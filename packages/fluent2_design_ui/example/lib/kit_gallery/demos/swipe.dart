/// Fluent 2's swipe actions, as a mail app's message rows: a chat row stood
/// open on its trailing acts (Delete in danger, Flag in warning), one
/// open on its leading act (Archive in success), and a live list whose
/// rows open to either side and do their first act on a full swipe.
library;

import 'package:flutter/material.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';

import '../kit.dart';

/// Holds a live value for a specimen: [builder] draws the control with the
/// value and the setter it hands the control.
class _Live<T> extends StatefulWidget {
  const _Live(this.initial, this.builder);

  final T initial;
  final Widget Function(T value, ValueChanged<T> set) builder;

  @override
  State<_Live<T>> createState() => _LiveState<T>();
}

class _LiveState<T> extends State<_Live<T>> {
  late T _value = widget.initial;

  @override
  Widget build(BuildContext context) =>
      widget.builder(_value, (v) => setState(() => _value = v));
}

Widget kitSwipeDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Swipe actions',
  sections: [
    kitSection('Trailing, stood open', children: [kitSpecimenSwipeTrailing()]),
    kitSection('Leading, stood open', children: [kitSpecimenSwipeLeading()]),
    kitSection('Swipe a row', children: [kitSpecimenSwipeLive()]),
  ],
);

/// A chat row on the card's surface, opaque so the panes show only in the
/// gap it leaves.
Widget _row(String name, String line) => Builder(
  builder: (context) => ColoredBox(
    color: context.fluent2Theme.surface,
    child: Fluent2ListItem(
      leading: Fluent2Avatar(name: name, color: Fluent2AvatarColor.colorful),
      title: name,
      subtitle: line,
      onTap: () {},
    ),
  ),
);

List<Fluent2SwipeAction> _trailing() => [
  Fluent2SwipeAction(
    label: 'Delete',
    icon: Fluent2Icons.delete,
    tone: Fluent2Tone.danger,
    onPressed: () {},
  ),
  Fluent2SwipeAction(
    label: 'Flag',
    icon: Fluent2Icons.flag,
    tone: Fluent2Tone.warning,
    onPressed: () {},
  ),
];

List<Fluent2SwipeAction> _leading() => [
  Fluent2SwipeAction(
    label: 'Archive',
    icon: Fluent2Icons.archive,
    tone: Fluent2Tone.success,
    onPressed: () {},
  ),
];

// --- Specimens --------------------------------------------------------------

Widget kitSpecimenSwipeTrailing() => Fluent2SwipeActions(
  initiallyOpen: true,
  trailing: _trailing(),
  child: _row('Kai Tanaka', 'Can we move the review to 3?'),
);

Widget kitSpecimenSwipeLeading() => Fluent2SwipeActions(
  initiallyOpen: true,
  leading: _leading(),
  child: _row('Mara Okafor', 'Brand guidelines are up'),
);

Widget kitSpecimenSwipeLive() => _Live<List<(String, String)>>(
  _chats,
  (chats, set) => Fluent2ListGroup(
    children: [
      for (final (i, (name, line)) in chats.indexed)
        Fluent2SwipeActions(
          key: ValueKey(name),
          fullSwipe: true,
          leading: [
            Fluent2SwipeAction(
              label: 'Archive',
              icon: Fluent2Icons.archive,
              tone: Fluent2Tone.success,
              onPressed: () => set([...chats]..removeAt(i)),
            ),
          ],
          trailing: [
            Fluent2SwipeAction(
              label: 'Delete',
              icon: Fluent2Icons.delete,
              tone: Fluent2Tone.danger,
              onPressed: () => set([...chats]..removeAt(i)),
            ),
            Fluent2SwipeAction(
              label: 'Pin',
              icon: Fluent2Icons.pin,
              tone: Fluent2Tone.brand,
              onPressed: () {},
            ),
          ],
          child: _row(name, line),
        ),
    ],
  ),
);

const List<(String, String)> _chats = [
  ('Tomas Lindqvist', 'Offsite photos are in the folder'),
  ('Priya Raman', 'Notes from the standup'),
  ('Noor Haddad', 'Who is booking the room?'),
];
