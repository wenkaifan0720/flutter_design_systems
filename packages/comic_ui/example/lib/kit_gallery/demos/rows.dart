/// The rows a list is built from.
library;

import 'package:flutter/material.dart';
import 'package:comic_ui/comic_ui.dart';

import '../kit.dart';

Widget kitRowsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Rows, lists and figures',
  sections: [
    kitSection('A setting', children: [kitSpecimenSwitchRow()]),
    kitSection('A row with an action', children: [kitSpecimenActionRow()]),
    kitSection('Rows you can open', children: [kitOpenRows()]),
    kitSection('Rules between rows', children: [kitSpecimenList()]),
    kitSection('A label and a value', children: [kitSpecimenKvRow()]),
    kitSection('A time and a thing', children: [kitSpecimenTimedRow()]),
    kitSection('Facts in a bar', children: [kitSpecimenFacts()]),
    kitSection('A label and its field', children: [kitSpecimenFormGroup()]),
    kitSection('A rule', children: [kitSpecimenRuled()]),
  ],
);

Widget kitSpecimenSwitchRow() => kitState(
  true,
  (context, value, change) => ComicSwitchRow(
    label: 'A note each week',
    note: 'Monday morning',
    value: value,
    onChanged: change,
    isFirst: true,
  ),
);

/// Pressable rows in a group, one selected: the wash and the ring take the row's own step, inside the group's frame.
Widget kitOpenRows() => kitState(
  1,
  (context, value, change) => ComicListSection(
    label: 'Issues',
    children: [
      for (final (i, title, meta) in const [
        (0, 'The first issue', 'Read'),
        (1, 'The second issue', 'Reading now'),
        (2, 'The third issue', 'Out Friday'),
      ])
        ComicListTile(
          title: title,
          subtitle: meta,
          isFirst: i == 0,
          selected: i == value,
          trailing: const Icon(ComicGlyphs.forward),
          onPressed: () => change(i),
        ),
    ],
  ),
);

Widget kitSpecimenActionRow() => ComicColumn(
  children: [
    kitState(
      false,
      (context, value, change) => ComicListTile(
        title: 'Confirm the first thing',
        subtitle: value ? 'Confirmed' : 'Before 15:00, it needs a yes',
        action: ComicButton(
          value ? 'Undo' : 'Confirm',
          size: ComicButtonSize.small,
          onPressed: () => change(!value),
        ),
        isFirst: true,
      ),
    ),
    kitState(
      false,
      (context, value, change) => ComicListTile(
        title: 'Sign the long form for the second one',
        subtitle: value ? 'Signed' : 'Two minutes',
        leading: const ComicPerson(initials: 'AC'),
        action: ComicButton(
          value ? 'Undo' : 'Sign',
          size: ComicButtonSize.small,
          onPressed: () => change(!value),
        ),
      ),
    ),
  ],
);

Widget kitSpecimenList() => const ComicList(
  children: [Text('The first of a kind'), Text('The second of a kind')],
);

Widget kitSpecimenKvRow() => const ComicColumn(
  children: [
    ComicKvRow('Each', '18.00', isFirst: true),
    ComicKvRow('People', '2', note: 'Up to six'),
    ComicKvRow('Lit', '14 of 20', share: '70%', selected: true),
    ComicTotalRow('In all', '36.00'),
  ],
);

Widget kitSpecimenTimedRow() => const ComicColumn(
  children: [
    ComicTimedRow(
      '09:00',
      title: 'The first thing',
      subtitle: 'Its line',
      isFirst: true,
    ),
    ComicTimedRow('10:30', title: 'The thing that matters', selected: true),
  ],
);

// The facts stand at the foot of a panel, as the part asks: the panel's contour closes them.
Widget kitSpecimenFacts() => const ComicPanel(
  bleed: true,
  shrinkWrap: true,
  child: Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: EdgeInsets.all(16),
        child: ComicPanelHead('The coast walk', sub: 'Three days, one bag'),
      ),
      ComicFacts([
        ('162', 'Kilometres'),
        ('Six', 'Walkers'),
        ('Easy', 'Grade'),
      ]),
    ],
  ),
);

Widget kitSpecimenFormGroup() => const ComicFormField(
  'Your name',
  help: 'As it should be on the list',
  child: ComicTextField(),
);

Widget kitSpecimenRuled() => const ComicColumn(
  children: [
    ComicRuled(child: Text('Under a rule')),
    ComicRuled(strong: true, child: Text('Under a strong one')),
  ],
);
