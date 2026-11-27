/// The rows a list is built from.
library;

import 'package:material_ui/material_ui.dart';
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
    label: kitSay(context, 'A note each week'),
    note: kitSay(context, 'Monday morning'),
    value: value,
    onChanged: change,
    isFirst: true,
  ),
);

/// Pressable rows in a group, one selected: the wash and the ring take the row's own step, inside the group's frame.
Widget kitOpenRows() => Builder(
  builder: (context) => kitState(
    1,
    (context, value, change) => ComicListSection(
      semanticLabel: kitSay(context, 'Issues'),
      children: [
        for (final (i, title, meta) in [
          (0, kitSay(context, 'The first issue'), kitSay(context, 'Read')),
          (
            1,
            kitSay(context, 'The second issue'),
            kitSay(context, 'Reading now'),
          ),
          (
            2,
            kitSay(context, 'The third issue'),
            kitSay(context, 'Out Friday'),
          ),
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
  ),
);

Widget kitSpecimenActionRow() => Builder(
  builder: (context) => ComicColumn(
    children: [
      kitState(
        false,
        (context, value, change) => ComicListTile(
          title: kitSay(context, 'Confirm the first thing'),
          subtitle: value
              ? kitSay(context, 'Confirmed')
              : kitSay(context, 'Before 15:00, it needs a yes'),
          action: ComicButton(
            value ? kitSay(context, 'Undo') : kitSay(context, 'Confirm'),
            size: ComicButtonSize.small,
            onPressed: () => change(!value),
          ),
          isFirst: true,
        ),
      ),
      kitState(
        false,
        (context, value, change) => ComicListTile(
          title: kitSay(context, 'Sign the long form for the second one'),
          subtitle: value
              ? kitSay(context, 'Signed')
              : kitSay(context, 'Two minutes'),
          leading: const ComicPerson(initials: 'AC'),
          action: ComicButton(
            value ? kitSay(context, 'Undo') : kitSay(context, 'Sign'),
            size: ComicButtonSize.small,
            onPressed: () => change(!value),
          ),
        ),
      ),
    ],
  ),
);

Widget kitSpecimenList() => Builder(
  builder: (context) => ComicList(
    children: [
      Text(kitSay(context, 'The first of a kind')),
      Text(kitSay(context, 'The second of a kind')),
    ],
  ),
);

Widget kitSpecimenKvRow() => Builder(
  builder: (context) => ComicColumn(
    children: [
      ComicKvRow(kitSay(context, 'Each'), '18.00', isFirst: true),
      ComicKvRow(
        kitSay(context, 'People'),
        '2',
        note: kitSay(context, 'Up to six'),
      ),
      ComicKvRow(
        kitSay(context, 'Lit'),
        kitSay(context, '14 of 20'),
        share: '70%',
        selected: true,
      ),
      ComicTotalRow(kitSay(context, 'In all'), '36.00'),
    ],
  ),
);

Widget kitSpecimenTimedRow() => Builder(
  builder: (context) => ComicColumn(
    children: [
      ComicTimedRow(
        '09:00',
        title: kitSay(context, 'The first thing'),
        subtitle: kitSay(context, 'Its line'),
        isFirst: true,
      ),
      ComicTimedRow(
        '10:30',
        title: kitSay(context, 'The thing that matters'),
        selected: true,
      ),
    ],
  ),
);

// The facts stand at the foot of a panel, as the part asks: the panel's contour closes them.
Widget kitSpecimenFacts() => Builder(
  builder: (context) => ComicPanel(
    bleed: true,
    shrinkWrap: true,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: ComicPanelHead(
            kitSay(context, 'The coast walk'),
            sub: kitSay(context, 'Three days, one bag'),
          ),
        ),
        ComicFacts([
          ('162', kitSay(context, 'Kilometres')),
          (kitSay(context, 'Six'), kitSay(context, 'Walkers')),
          (kitSay(context, 'Easy'), kitSay(context, 'Grade')),
        ]),
      ],
    ),
  ),
);

Widget kitSpecimenFormGroup() => Builder(
  builder: (context) => ComicFormField(
    kitSay(context, 'Your name'),
    helperText: kitSay(context, 'As it should be on the list'),
    child: ComicTextField(),
  ),
);

Widget kitSpecimenRuled() => Builder(
  builder: (context) => ComicColumn(
    children: [
      ComicRuled(child: Text(kitSay(context, 'Under a rule'))),
      ComicRuled(
        strong: true,
        child: Text(kitSay(context, 'Under a strong one')),
      ),
    ],
  ),
);
