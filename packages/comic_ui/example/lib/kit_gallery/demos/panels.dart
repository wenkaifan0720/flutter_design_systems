/// Each is a ComicPanel already laid out, on plain data: a page stands them in a ComicTier and doesn't write their insides.
library;

import 'package:material_ui/material_ui.dart';
import 'package:comic_ui/comic_ui.dart';

import '../kit.dart';
// The demo art is the example's; a test or page that draws it reads it from there.
// ignore: avoid_relative_lib_imports
import '../../demo_art.dart';

Widget kitPanelsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Panels that carry something',
  sections: [
    kitSection('An art band', children: [kitSpecimenArtBand()]),
    kitSection('Something coming up', children: [kitSpecimenEventPanel()]),
    kitSection('A memory', children: [kitSpecimenMarkPanel()]),
    kitSection('A numbered step', children: [kitSpecimenStepPanel()]),
    kitSection('A voice in a strip', children: [kitSpecimenVoicePanel()]),
    kitSection('A chapter', children: [kitSpecimenChapterPanel()]),
    kitSection('Someone says', children: [kitSpecimenSay()]),
    kitSection('A reply', children: [kitSpecimenReply()]),
    kitSection('A claim', children: [kitSpecimenClaim()]),
    kitSection('A row of figures', children: [kitSpecimenFigures()]),
    kitSection('An amount and its thing', children: [kitSpecimenAmountRow()]),
    kitSection('A dated line', children: [kitSpecimenLedgerRow()]),
  ],
);

Widget kitSpecimenArtBand() => Builder(
  builder: (context) => SizedBox(
    height: 128,
    child: ComicArtBand(
      ground: 2,
      leading: ComicMark(ComicMarks.peak),
      sfx: kitSay(context, 'Crunch!'),
      caption: kitSay(context, 'A date'),
    ),
  ),
);

Widget kitSpecimenEventPanel() => Builder(
  builder: (context) => ComicTier(
    phone: ComicTierLayout.stack,
    children: [
      ComicEventPanel(
        when: kitSay(context, 'Sat 14 Nov'),
        title: kitSay(context, 'A morning walk'),
        // A no-break space keeps the duration whole.
        where: kitSay(context, 'From the station · about 4 hours'),
        leading: ComicMark(ComicMarks.peak),
        ground: 2,
        people: [
          ComicPerson(initials: 'AB', size: 24),
          ComicPerson(initials: 'CD', size: 24, fillIndex: 1),
        ],
        tally: kitSay(context, '5 in'),
      ),
      ComicEventPanel(
        when: kitSay(context, 'Fri 4 – Sun 6 Dec'),
        title: kitSay(context, 'The long weekend'),
        count: '23',
        countWord: kitSay(context, 'days to go'),
        big: true,
        leading: ComicMark(ComicMarks.cabin, onNight: true),
        ground: 4,
      ),
    ],
  ),
);

Widget kitSpecimenMarkPanel() => Builder(
  builder: (context) => ComicTier(
    children: [
      ComicMarkPanel(
        date: kitSay(context, 'Sun 8 Nov'),
        leading: ComicMark(ComicMarks.mug),
        sfx: kitSay(context, 'Munch!'),
        title: kitSay(context, 'A slow brunch'),
        words: kitSay(context, 'Two breakfasts. Both for one.'),
      ),
      ComicMarkPanel(
        date: kitSay(context, 'Sat 7 Nov'),
        leading: ComicMark(ComicMarks.pumpkin),
        ground: 3,
        sfx: kitSay(context, 'Scoop!'),
        title: kitSay(context, 'Something in the kitchen'),
        words: kitSay(context, 'Six tries, five faces.'),
      ),
    ],
  ),
);

Widget kitSpecimenStepPanel() => Builder(
  builder: (context) => ComicStepPanel(
    number: '1',
    leading: const ComicMark(ComicMarks.pan),
    sfx: kitSay(context, 'Sizzle!'),
    words: kitSay(context, 'Soften the onions in the oil over a medium heat.'),
    action: ComicButton(
      kitSay(context, '8 min'),
      size: ComicButtonSize.small,
      onPressed: () => kitFeedback(context, 'Eight-minute timer started.'),
    ),
  ),
);

Widget kitSpecimenVoicePanel() => Builder(
  builder: (context) => ComicTier(
    children: [
      ComicVoicePanel(
        time: kitSay(context, 'Tue 21:16'),
        words: kitSay(context, 'Booked for the fourth.'),
        name: kitSay(context, 'Sam'),
        portrait: ComicPortrait(ComicBust.bob),
      ),
      ComicVoicePanel(
        time: kitSay(context, 'Tue 21:20'),
        words: kitSay(context, 'I can bring the soup.'),
        name: kitSay(context, 'Robin'),
        portrait: ComicPortrait(ComicBust.topknot),
        warm: true,
      ),
    ],
  ),
);

Widget kitSpecimenChapterPanel() => Builder(
  builder: (context) => ComicChapterPanel(
    caption: kitSay(context, 'Chapter 1'),
    title: kitSay(context, 'The drive north'),
    art: ComicArtBand(ground: 2, leading: ComicMark(ComicMarks.cabin)),
    children: [
      ComicTimedRow(
        '16:00',
        title: kitSay(context, 'Leave'),
        isFirst: true,
        inset: 14,
      ),
      ComicTimedRow(
        '18:40',
        title: kitSay(context, 'Arrive'),
        selected: true,
        inset: 14,
      ),
    ],
  ),
);

Widget kitSpecimenSay() => Builder(
  builder: (context) => ComicColumn(
    gap: 12,
    children: [
      ComicSpeech(
        person: ComicPerson(initials: 'SA', size: 48),
        text: kitSay(
          context,
          'A line of chat, wrapping as it needs to, with its tail at the head.',
        ),
        author: kitSay(context, 'Sam · 21:20'),
      ),
      ComicSpeech(
        person: ComicPerson(initials: 'RO', size: 48, fillIndex: 1),
        text: kitSay(context, 'Short.'),
        author: kitSay(context, 'Robin · 21:22'),
      ),
    ],
  ),
);

Widget kitSpecimenReply() => Builder(
  builder: (context) => _ReplyDemo(
    builder: (controller, send) => ComicReply(
      person: const ComicPerson(initials: 'Me', size: 44, fillIndex: 2),
      hintText: kitSay(context, 'Say something…'),
      controller: controller,
      onSend: send,
      onSubmitted: (_) => send(),
    ),
  ),
);

class _ReplyDemo extends StatefulWidget {
  const _ReplyDemo({required this.builder});
  final Widget Function(TextEditingController, VoidCallback) builder;
  @override
  State<_ReplyDemo> createState() => _ReplyDemoState();
}

class _ReplyDemoState extends State<_ReplyDemo> {
  final controller = TextEditingController();
  void send() {
    if (controller.text.trim().isEmpty) {
      kitFeedback(context, 'Write a message first.');
    } else {
      controller.clear();
      kitFeedback(context, 'Reply sent.');
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(controller, send);
}

Widget kitSpecimenClaim() => Builder(
  builder: (context) => ComicClaim(
    before: kitSay(context, 'You owe Sam'),
    figure: '19',
    note: kitSay(context, 'Your share of Saturday.'),
    person: ComicPerson(initials: 'SD', size: 56),
  ),
);

Widget kitSpecimenFigures() => Builder(
  builder: (context) => ComicFigures([
    (kitSay(context, '20 min'), kitSay(context, 'First')),
    (kitSay(context, '1 h 10'), kitSay(context, 'Then')),
    (kitSay(context, '1 h 30'), kitSay(context, 'In all')),
  ], highlightLast: true),
);

Widget kitSpecimenAmountRow() => Builder(
  builder: (context) => ComicColumn(
    children: [
      ComicAmountRow(
        kitSay(context, '2 tsp'),
        kitSay(context, 'smoked paprika'),
        isFirst: true,
      ),
      ComicAmountRow(
        kitSay(context, '3 × 400 g'),
        kitSay(context, 'tins of something,'),
        note: kitSay(context, 'drained'),
      ),
    ],
  ),
);

Widget kitSpecimenLedgerRow() => Builder(
  builder: (context) => ComicColumn(
    children: [
      ComicLedgerRow(
        date: kitSay(context, 'Tue 10 Nov'),
        title: kitSay(context, 'The first'),
        subtitle: kitSay(context, 'One line'),
        value: '540',
        isFirst: true,
      ),
      ComicLedgerRow(
        date: kitSay(context, 'Sun 8 Nov'),
        title: kitSay(context, 'The second'),
        subtitle: kitSay(context, 'Yours'),
        value: '114',
        isCurrentUser: true,
      ),
    ],
  ),
);
