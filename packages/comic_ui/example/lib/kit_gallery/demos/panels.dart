/// Each is a ComicPanel already laid out, on plain data: a page stands them in a ComicTier and doesn't write their insides.
library;

import 'package:flutter/material.dart';
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

Widget kitSpecimenArtBand() => const SizedBox(
  height: 128,
  child: ComicArtBand(
    ground: 2,
    leading: ComicMark(ComicMarks.peak),
    sfx: 'Crunch!',
    caption: 'A date',
  ),
);

Widget kitSpecimenEventPanel() => const ComicTier(
  phone: ComicTierLayout.stack,
  children: [
    ComicEventPanel(
      when: 'Sat 14 Nov',
      title: 'A morning walk',
      // A no-break space keeps the duration whole.
      where: 'From the station · about 4 hours',
      leading: ComicMark(ComicMarks.peak),
      ground: 2,
      people: [
        ComicPerson(initials: 'AB', size: 24),
        ComicPerson(initials: 'CD', size: 24, fillIndex: 1),
      ],
      tally: '5 in',
    ),
    ComicEventPanel(
      when: 'Fri 4 – Sun 6 Dec',
      title: 'The long weekend',
      count: '23',
      countWord: 'days to go',
      big: true,
      leading: ComicMark(ComicMarks.cabin, onNight: true),
      ground: 4,
    ),
  ],
);

Widget kitSpecimenMarkPanel() => const ComicTier(
  children: [
    ComicMarkPanel(
      date: 'Sun 8 Nov',
      leading: ComicMark(ComicMarks.mug),
      sfx: 'Munch!',
      title: 'A slow brunch',
      words: 'Two breakfasts. Both for one.',
    ),
    ComicMarkPanel(
      date: 'Sat 7 Nov',
      leading: ComicMark(ComicMarks.pumpkin),
      ground: 3,
      sfx: 'Scoop!',
      title: 'Something in the kitchen',
      words: 'Six tries, five faces.',
    ),
  ],
);

Widget kitSpecimenStepPanel() => Builder(
  builder: (context) => ComicStepPanel(
    number: '1',
    leading: const ComicMark(ComicMarks.pan),
    sfx: 'Sizzle!',
    words: 'Soften the onions in the oil over a medium heat.',
    action: ComicButton(
      '8 min',
      size: ComicButtonSize.small,
      onPressed: () => kitFeedback(context, 'Eight-minute timer started.'),
    ),
  ),
);

Widget kitSpecimenVoicePanel() => const ComicTier(
  children: [
    ComicVoicePanel(
      time: 'Tue 21:16',
      words: 'Booked for the fourth.',
      name: 'Sam',
      portrait: ComicPortrait(ComicBust.bob),
    ),
    ComicVoicePanel(
      time: 'Tue 21:20',
      words: 'I can bring the soup.',
      name: 'Robin',
      portrait: ComicPortrait(ComicBust.topknot),
      warm: true,
    ),
  ],
);

Widget kitSpecimenChapterPanel() => const ComicChapterPanel(
  caption: 'Chapter 1',
  title: 'The drive north',
  art: ComicArtBand(ground: 2, leading: ComicMark(ComicMarks.cabin)),
  children: [
    ComicTimedRow('16:00', title: 'Leave', isFirst: true, inset: 14),
    ComicTimedRow('18:40', title: 'Arrive', selected: true, inset: 14),
  ],
);

Widget kitSpecimenSay() => const ComicColumn(
  gap: 12,
  children: [
    ComicSpeech(
      person: ComicPerson(initials: 'SA', size: 48),
      text:
          'A line of chat, wrapping as it needs to, with its tail at the head.',
      author: 'Sam · 21:20',
    ),
    ComicSpeech(
      person: ComicPerson(initials: 'RO', size: 48, fillIndex: 1),
      text: 'Short.',
      author: 'Robin · 21:22',
    ),
  ],
);

Widget kitSpecimenReply() => _ReplyDemo(
  builder: (controller, send) => ComicReply(
    person: const ComicPerson(initials: 'Me', size: 44, fillIndex: 2),
    hint: 'Say something…',
    controller: controller,
    onSend: send,
    onSubmitted: (_) => send(),
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

Widget kitSpecimenClaim() => const ComicClaim(
  before: 'You owe Sam',
  figure: '19',
  note: 'Your share of Saturday.',
  person: ComicPerson(initials: 'SD', size: 56),
);

Widget kitSpecimenFigures() => const ComicFigures([
  ('20 min', 'First'),
  ('1 h 10', 'Then'),
  ('1 h 30', 'In all'),
], highlightLast: true);

Widget kitSpecimenAmountRow() => const ComicColumn(
  children: [
    ComicAmountRow('2 tsp', 'smoked paprika', isFirst: true),
    ComicAmountRow('3 × 400 g', 'tins of something,', note: 'drained'),
  ],
);

Widget kitSpecimenLedgerRow() => const ComicColumn(
  children: [
    ComicLedgerRow(
      date: 'Tue 10 Nov',
      title: 'The first',
      subtitle: 'One line',
      value: '540',
      isFirst: true,
    ),
    ComicLedgerRow(
      date: 'Sun 8 Nov',
      title: 'The second',
      subtitle: 'Yours',
      value: '114',
      isCurrentUser: true,
    ),
  ],
);
