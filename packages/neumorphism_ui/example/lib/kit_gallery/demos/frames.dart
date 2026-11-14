/// The material: a slab raised out of the wall, a well pressed into it, and what happens when one stands inside the other. One painter draws them all, and a state still reads with its shadows gone.
library;

import 'package:flutter/material.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

import '../kit.dart';

Widget kitFramesDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Slabs, wells and heads',
  sections: [
    kitSection('A card', children: [kitSpecimenCard()]),
    kitSection('A slab with no head', children: [kitSpecimenSlab()]),
    kitSection('A well', children: [kitSpecimenWell()]),
    kitSection(
      'A well inside a slab, a well inside a well',
      children: [
        const NeumorphicSlab(
          child: NeumorphicWell(
            child: NeumorphicWell(
              small: true,
              child: Text('The inner one is a floor: no second inset.'),
            ),
          ),
        ),
      ],
    ),
    kitSection(
      'A state with no shadow at all',
      children: [
        NeumorphicFlatScope(
          child: NeumorphicColumn(
            gap: 12,
            children: [
              NeumorphicLatchGroup(
                options: const [
                  NeumorphicLatch('Day'),
                  NeumorphicLatch('Week'),
                  NeumorphicLatch('Month'),
                ],
                value: 'Day',
                onChanged: (_) {},
              ),
              Wrap(
                spacing: 16,
                children: [
                  NeumorphicSwitch(
                    value: false,
                    label: 'Off',
                    onChanged: (_) {},
                  ),
                  NeumorphicSwitch(value: true, label: 'On', onChanged: (_) {}),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
    kitSection('A set on the wall', children: [kitSpecimenWallSet()]),
    kitSection('A section head', children: [kitSpecimenSectionHead()]),
    kitSection('A smaller head', children: [kitSpecimenSubHead()]),
    kitSection('A page head', children: [kitSpecimenPageHead()]),
    kitSection('An eyebrow', children: [kitSpecimenEyebrow()]),
    kitSection('A state', children: [kitSpecimenState()]),
    kitSection('A tag', children: [kitSpecimenTag()]),
  ],
);

Widget kitSpecimenCard() => const NeumorphicCard(
  title: 'A card',
  subtitle: 'Its meta',
  children: [
    NeumorphicList(
      children: [
        NeumorphicKvRow('A label', 'A value', isFirst: true),
        NeumorphicKvRow('Another', '12'),
      ],
    ),
  ],
);

Widget kitSpecimenSlab() => const NeumorphicSlab(
  child: NeumorphicKvRow('A label', 'A value', isFirst: true),
);

Widget kitSpecimenWell() => const NeumorphicWell(
  child: NeumorphicKvRow('A label', 'A value', isFirst: true),
);

Widget kitSpecimenWallSet() => const NeumorphicWallSet(
  title: 'A set',
  subtitle: 'Its meta',
  child: NeumorphicGridOf(
    columns: 3,
    gap: 8,
    children: [
      NeumorphicGauge(value: 72, figure: '72', name: 'First', live: true),
      NeumorphicGauge(value: 45, figure: '45', name: 'Second'),
      NeumorphicGauge(value: 18, figure: '18', name: 'Third'),
    ],
  ),
);

Widget kitSpecimenSectionHead() =>
    const NeumorphicSectionHeader(title: 'A section', subtitle: 'Its meta');

Widget kitSpecimenSubHead() =>
    const NeumorphicSubHead('A smaller head', subtitle: 'Its meta');

Widget kitSpecimenPageHead() => const NeumorphicPageHead(
  overline: 'Today, 13:05',
  title: 'A page',
  subtitle: '4 items',
);

Widget kitSpecimenEyebrow() => const NeumorphicEyebrow('A few words');

Widget kitSpecimenState() => const Wrap(
  spacing: 16,
  runSpacing: 8,
  children: [NeumorphicStatus('On, 30%', live: true), NeumorphicStatus('Off')],
);

Widget kitSpecimenTag() => const NeumorphicTag('New');
