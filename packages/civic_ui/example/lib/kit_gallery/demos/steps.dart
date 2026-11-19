// Where a reader is: the steps of a form, the page marks under slides, and
// the carousel that turns only when the reader turns it.
import 'package:material_ui/material_ui.dart';
import 'package:civic_ui/civic_ui.dart';

import '../kit.dart';
import 'people.dart' show kitZoneMap;

Widget kitStepsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Steps, page marks & carousels',
  sections: [
    const KitSection(
      title: 'Step indicator',
      caption: 'Below 600 wide the count says the step in words.',
      children: [
        CivicStepIndicator(
          steps: ['Your vehicle', 'Your details', 'Proof of address', 'Check'],
          current: 0,
        ),
        CivicStepIndicator(
          steps: ['Your vehicle', 'Your details', 'Proof of address', 'Check'],
          current: 2,
        ),
      ],
    ),
    const KitSection(title: 'Page marks', children: [_Marks()]),
    KitSection(
      title: 'Carousel',
      caption: 'Worded Previous and Next; it never turns on its own.',
      children: [
        CivicCarousel(
          semanticLabel: 'Pictures of Zone B',
          itemCount: 3,
          itemBuilder: (context, index) => switch (index) {
            0 => Image(image: kitZoneMap, fit: BoxFit.cover),
            _ => Center(
              child: Text(
                const ['', 'Bays on Mill Lane', 'The river path'][index],
                style: context.civicText.headingS,
              ),
            ),
          },
        ),
      ],
    ),
  ],
);

class _Marks extends StatefulWidget {
  const _Marks();

  @override
  State<_Marks> createState() => _MarksState();
}

class _MarksState extends State<_Marks> {
  int _page = 1;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: CivicSpacing.s8,
    children: [
      CivicPageDots(
        count: 5,
        index: _page,
        onChanged: (p) => setState(() => _page = p),
      ),
      const CivicPageDots(count: 3, index: 0),
    ],
  );
}
