// What holds a page's things: cards (a plain one and one that is a link,
// at rest and focused), sections of guidance under "Show all sections",
// and the grid that stands cards side by side as the room allows.
import 'package:material_ui/material_ui.dart';
import 'package:civic_ui/civic_ui.dart';

import '../kit.dart';

Widget kitContainersDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Cards, accordions & grids',
  maxWidth: CivicLayout.maxContentWidth,
  sections: [
    KitSection(
      title: 'Cards',
      caption: 'A card holds one thing; a card that is a link goes one place.',
      children: [
        const CivicCard(
          title: 'Resident permit, Zone B',
          child: Text('Runs out on 3 November 2027.'),
        ),
        CivicCard(
          title: 'Visitor permits',
          onPressed: () {},
          child: const Text('8 of 10 days left this year.'),
        ),
        KitFocused(
          builder: (states) => CivicCard(
            title: 'Pay a parking fine',
            onPressed: () {},
            statesController: states,
            child: const Text('Pay within 14 days for half the fine.'),
          ),
        ),
      ],
    ),
    const KitSection(
      title: 'Accordion',
      caption: 'Sections a reader opens one at a time, or all at once.',
      children: [
        CivicAccordion(
          initiallyExpanded: {1},
          sections: [
            CivicAccordionSection(
              title: 'Who can apply',
              summary: 'Residents of a permit zone',
              child: Text(
                'Anyone who lives in a permit zone and keeps a vehicle there.',
              ),
            ),
            CivicAccordionSection(
              title: 'What it costs',
              summary: 'From €60 a year',
              child: Text(
                '€60 a year for the first vehicle, €90 for a second.',
              ),
            ),
            CivicAccordionSection(
              title: 'How long it takes',
              child: Text('We decide within 5 working days.'),
            ),
          ],
        ),
      ],
    ),
    KitSection(
      title: 'Grid',
      caption: 'One column below 600 wide, two to 1024, three from there.',
      children: [
        CivicGrid(
          children: [
            for (final (title, words) in const [
              ('Parking', 'Permits, fines and bays'),
              ('Bins', 'Collections and new bins'),
              ('Council tax', 'Pay, discounts and moving home'),
              ('Libraries', 'Join, renew and opening times'),
              ('Roads', 'Report a pothole or a broken light'),
            ])
              CivicCard(title: title, onPressed: () {}, child: Text(words)),
          ],
        ),
      ],
    ),
  ],
);
