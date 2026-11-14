/// Records a page reads: a timeline, terms and details, a meter, a page's status.
library;

import 'package:flutter/widgets.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

import '../kit.dart';

Widget kitRecordsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Timelines, terms, meters and status',
  sections: kitRecordsSections(),
);

List<Widget> kitRecordsSections() => [
  kitSection(
    'What happened, and what is next',
    children: [kitSpecimenTimeline()],
  ),
  kitSection(
    'Terms and their details',
    children: [kitSpecimenDescriptionList()],
  ),
  kitSection('A reading against its limits', children: [kitSpecimenMeter()]),
  kitSection('A page that is loading', children: [kitSpecimenStatusView()]),
];

Widget kitSpecimenTimeline() => const NeumorphicTimeline(
  label: 'Tonight',
  stops: [
    NeumorphicTimelineStop(
      time: '19:45',
      title: 'Lamps dim',
      body: 'The hall goes first.',
    ),
    NeumorphicTimelineStop(
      time: '22:30',
      title: 'Lights out',
      state: NeumorphicStepStatus.live,
    ),
    NeumorphicTimelineStop(
      time: '06:45',
      title: 'Slow dawn',
      state: NeumorphicStepStatus.next,
    ),
  ],
);

Widget kitSpecimenDescriptionList() => const NeumorphicDescriptionList([
  NeumorphicDescription('Lights out', '22:30'),
  NeumorphicDescription('Lamps', '2'),
  NeumorphicDescription('Warmth', '19 degrees'),
], label: 'Tonight');

Widget kitSpecimenMeter() => const NeumorphicMeter(
  label: 'Hot water',
  value: 18,
  max: 24,
  high: 20,
  valueLabel: '18 of 24 litres',
);

// It takes the height its words need, so a reader's larger text never runs out of it.
Widget kitSpecimenStatusView() => const NeumorphicStatusView.loading(
  title: 'Finding the rooms',
  message: 'This takes a moment.',
);
