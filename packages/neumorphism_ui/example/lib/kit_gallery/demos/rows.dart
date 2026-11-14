/// The rows a list is built from, and the figures that say where things stand.
library;

import 'package:flutter/material.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

import '../kit.dart';

Widget kitRowsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Rows, lists and figures',
  sections: [
    kitSection('A row with an action', children: [kitSpecimenActionRow()]),
    kitSection('A label and its value', children: [kitSpecimenKvRow()]),
    kitSection('Timed steps', children: [kitSpecimenStepRow()]),
    kitSection('Who', children: [kitSpecimenWhoRow()]),
    kitSection('A thing to do', children: [kitSpecimenTodoRow()]),
    kitSection('A thing with a level', children: [kitSpecimenLevelRow()]),
    kitSection('Small figures', children: [kitSpecimenStats()]),
    kitSection('A big figure', children: [kitSpecimenFigure()]),
    kitSection('A nudge', children: [kitSpecimenNudge()]),
    kitSection('A line of a form', children: [kitSpecimenFormGroup()]),
    kitSection('Nothing here yet', children: [kitSpecimenEmpty()]),
  ],
);

Widget kitSpecimenActionRow() => NeumorphicColumn(
  children: [
    NeumorphicListTile(
      isFirst: true,
      title: 'A title',
      note: 'A small line',
      leading: const NeumorphicIconWell(NeumorphicGlyphs.lock, live: true),
      trailing: const NeumorphicStatus('Held'),
      // The open one, as a list beside its detail shows it.
      selected: true,
      onPressed: () {},
    ),
    NeumorphicListTile(
      title: 'Another title',
      note: 'With a button at its end',
      action: NeumorphicButton('Open', onPressed: () {}),
    ),
    NeumorphicListTile(
      title: 'A third',
      note: 'With a switch',
      trailing: NeumorphicSwitch(
        label: 'A third',
        value: true,
        onChanged: (_) {},
      ),
    ),
  ],
);

Widget kitSpecimenKvRow() => const NeumorphicList(
  children: [
    NeumorphicKvRow('A label', 'A value', isFirst: true),
    NeumorphicKvRow('A live one', 'Active', live: true),
    NeumorphicTotalRow('Total', '1,204'),
  ],
);

Widget kitSpecimenStepRow() => const NeumorphicWell(
  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
  child: NeumorphicList(
    children: [
      NeumorphicStepRow(
        time: '06:30',
        title: 'A step that has gone',
        value: '20.5',
        isFirst: true,
      ),
      NeumorphicStepRow(
        time: '19:45',
        title: 'A step, now',
        value: '21.5',
        state: NeumorphicStepStatus.live,
      ),
      NeumorphicStepRow(
        time: '22:30',
        title: 'A step to come',
        value: '17.0',
        state: NeumorphicStepStatus.next,
      ),
    ],
  ),
);

Widget kitSpecimenWhoRow() => const NeumorphicList(
  children: [
    NeumorphicWhoRow(
      initials: 'AB',
      name: 'A person',
      note: 'Here since 17:40',
      led: true,
      isFirst: true,
    ),
    NeumorphicWhoRow(
      initials: 'CD',
      name: 'Another person',
      note: 'Joined in June',
    ),
  ],
);

Widget kitSpecimenTodoRow() => NeumorphicList(
  children: [
    NeumorphicTodoRow(
      title: 'A thing to do',
      note: 'Due today',
      live: true,
      isFirst: true,
      onChanged: (_) {},
    ),
    NeumorphicTodoRow(
      title: 'A thing done',
      note: 'Done 11:52',
      value: true,
      onChanged: (_) {},
    ),
  ],
);

Widget kitSpecimenLevelRow() => NeumorphicList(
  children: [
    NeumorphicLevelRow(
      icon: NeumorphicGlyphs.fan,
      title: 'A thing',
      state: 'Off, was 80%',
      value: false,
      isFirst: true,
      onChanged: (_) {},
    ),
    NeumorphicLevelRow(
      icon: NeumorphicGlyphs.lamp,
      title: 'Another',
      state: 'On, 30%',
      value: true,
      level: .3,
      figure: '30%',
      onChanged: (_) {},
      onLevel: (_) {},
    ),
  ],
);

Widget kitSpecimenStats() => const NeumorphicStats([
  NeumorphicStat('Using now', '1.8', 'a day'),
  NeumorphicStat('Returned', '3.0'),
  NeumorphicStat('Cost', '4.22'),
]);

Widget kitSpecimenFigure() => const NeumorphicFigure(
  '17.8',
  unit: 'units used',
  delta: '9% below yesterday',
  icon: NeumorphicGlyphs.trendingDown,
);

Widget kitSpecimenNudge() => NeumorphicNudge(
  title: 'This has been on since 16:10.',
  note: 'Nobody is using it.',
  icon: NeumorphicGlyphs.lamp,
  action: NeumorphicButton.filled(
    'Turn off',
    icon: NeumorphicGlyphs.power,
    onPressed: () {},
  ),
);

Widget kitSpecimenFormGroup() => const NeumorphicFormGroup(
  label: 'A name',
  help: 'A short help line.',
  child: NeumorphicTextField(hint: 'A name'),
);

Widget kitSpecimenEmpty() => const NeumorphicEmptyState(
  title: 'Nothing here yet',
  body: 'It will show up here when the first one comes in.',
);
