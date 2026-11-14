// The look's home, and the one page with the whole `ComicCover`: masthead, corner boxes, one burst, the cast at its foot. Beside it a
// `ComicClaim` on your dots, then a tier of five `ComicEventPanel`s, a `ComicTally`, and a strip of `ComicMarkPanel`s. Copy it for the
// first page of a thing people share. Every other page opens on a compact panel, not this.
import 'package:material_ui/material_ui.dart';
import 'package:comic_ui/comic_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

// The demo art is the example's; a test or page that draws it reads it from there.
// ignore: avoid_relative_lib_imports
import '../../example/lib/demo_art.dart';

const _group = [
  ComicPerson(
    initials: 'YO',
    portrait: ComicPortrait(ComicBust.puff, cropped: true),
    isCurrentUser: true,
    size: 24,
  ),
  ComicPerson(
    initials: 'SD',
    portrait: ComicPortrait(ComicBust.bob, cropped: true),
    size: 24,
  ),
  ComicPerson(
    initials: 'AC',
    portrait: ComicPortrait(ComicBust.spikes, cropped: true),
    size: 24,
  ),
  ComicPerson(
    initials: 'LB',
    portrait: ComicPortrait(ComicBust.quiff, cropped: true),
    size: 24,
  ),
  ComicPerson(
    initials: 'OK',
    portrait: ComicPortrait(ComicBust.topknot, cropped: true),
    size: 24,
  ),
];

const _sam = ComicPerson(
  initials: 'SD',
  portrait: ComicPortrait(ComicBust.bob, cropped: true),
  size: 40,
);
const _lee = ComicPerson(
  initials: 'LB',
  portrait: ComicPortrait(ComicBust.quiff, cropped: true),
  size: 40,
);
const _ola = ComicPerson(
  initials: 'OK',
  portrait: ComicPortrait(ComicBust.topknot, cropped: true),
  size: 40,
);

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context);
    return ComicScaffold(
      topBar: ComicAppBar(
        actions: [
          ComicIconButton(LucideIcons.bell, label: 'Alerts', onPressed: () {}),
        ],
      ),
      body: ComicSections(
        children: [
          ComicTier(
            spans: const [8, 4],
            phone: ComicTierLayout.stack,
            children: [
              const ComicCover(
                masthead: 'Hooray!',
                subtitle: 'The whole',
                emphasis: 'crowd!',
                issue: ComicCoverBox('No. 12', 'so far'),
                price: ComicCoverBox('€8', 'to settle'),
                date: ComicCoverBox('Wed 11 Nov', 'this evening'),
                burst: ComicCoverBurst('2', over: 'Only', under: 'days!'),
                say: 'Saved you a seat by the door.',
                sayer: 2,
                cast: [
                  ComicCast(
                    'You',
                    portrait: ComicPortrait(ComicBust.puff),
                    isCurrentUser: true,
                  ),
                  ComicCast('Sam', portrait: ComicPortrait(ComicBust.bob)),
                  ComicCast('Ada', portrait: ComicPortrait(ComicBust.spikes)),
                  ComicCast('Lee', portrait: ComicPortrait(ComicBust.quiff)),
                  ComicCast('Ola', portrait: ComicPortrait(ComicBust.topknot)),
                  ComicCast('Kit', portrait: ComicPortrait(ComicBust.beanie)),
                ],
              ),
              ComicPanelStack(
                children: [
                  ComicPanel(
                    caption: 'Where you stand',
                    captionIcon: LucideIcons.wallet,
                    captionTone: ComicSpeaker.currentUser,
                    ground: ComicPanelFill.currentUserDots,
                    child: ComicColumn(
                      gap: 20,
                      children: [
                        const ComicClaim(
                          before: 'You owe Sam',
                          figure: '€8',
                          note: 'Your share of Saturday, less what you paid.',
                          person: ComicPerson(
                            initials: 'SD',
                            portrait: ComicPortrait(
                              ComicBust.bob,
                              cropped: true,
                            ),
                            size: 56,
                          ),
                        ),
                        ComicButton.filled(
                          'Settle it',
                          icon: LucideIcons.handCoins,
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                  ComicPanel(
                    caption: 'Still to answer',
                    captionIcon: LucideIcons.vote,
                    child: ComicColumn(
                      gap: 10,
                      children: [
                        const ComicGrow(
                          child: Center(
                            child: ComicThought('Hmm', trailEnd: true),
                          ),
                        ),
                        Text(
                          'Kit has one vote left to cast.',
                          style: t.type.body,
                        ),
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          widthFactor: 1,
                          heightFactor: 1,
                          child: ComicButton(
                            'Remind Kit',
                            icon: LucideIcons.send,
                            size: ComicButtonSize.small,
                            onPressed: () {},
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const ComicSectionHeader('Coming up', note: '5 things'),
          ComicTier(
            phone: ComicTierLayout.stack,
            children: [
              const ComicEventPanel(
                when: 'Tomorrow · 19:30',
                whenIcon: LucideIcons.clock,
                title: 'A night out',
                where: 'The usual place, around the corner',
                leading: ComicMark(ComicMarks.pint),
                people: _group,
                tally: '5 in',
              ),
              const ComicEventPanel(
                when: 'Sat 14 · 09:30',
                title: 'A long walk',
                where: 'From the station · 11 km',
                leading: ComicMark(ComicMarks.peak),
                ground: 2,
                people: _group,
                tally: '4 in · one maybe',
              ),
              const ComicEventPanel(
                when: 'Sun 15 · 19:00',
                title: 'A film',
                where: 'Whichever wins the vote',
                leading: ComicMark(ComicMarks.clapper),
                ground: 3,
                people: _group,
                tally: 'All in',
              ),
              const ComicEventPanel(
                when: 'Sat 21 · 19:30',
                title: 'A birthday',
                where: 'Dinner, somewhere with a big table',
                leading: ComicMark(ComicMarks.cake),
                people: _group,
                tally: 'All in',
              ),
              ComicEventPanel(
                big: true,
                when: 'Fri 4 – Sun 6',
                count: '23',
                countWord: 'days to go',
                title: 'The long weekend',
                where: 'A cabin by the water, two nights',
                leading: ComicMark(ComicMarks.cabin, onNight: true),
                ground: 4,
                people: _group,
                trailing: const ComicTag(
                  'Open it',
                  tone: ComicSpeaker.narrator,
                  icon: LucideIcons.chevronRight,
                  iconEnd: true,
                ),
                onPressed: () {},
              ),
            ],
          ),
          const ComicSectionHeader('Open question', note: '5 of 6 answered'),
          ComicTier(
            spans: const [7, 5],
            phone: ComicTierLayout.stack,
            children: [
              ComicPanel(
                caption: 'Closes Friday, 20:00',
                child: ComicTally(
                  question: 'Which weekend works?',
                  subtitle: 'Pick every one you can do',
                  of: 6,
                  options: [
                    ComicVote(
                      'The first',
                      count: 3,
                      people: _group.sublist(0, 3),
                    ),
                    const ComicVote(
                      'The second',
                      count: 5,
                      isLeading: true,
                      stamp: 'Leads',
                      people: _group,
                    ),
                    ComicVote(
                      'The third',
                      count: 2,
                      people: _group.sublist(1, 3),
                    ),
                  ],
                  waiting: 'Waiting on Kit',
                  yours: 'You picked 2',
                  yoursIcon: LucideIcons.check,
                ),
              ),
              ComicPanel(
                caption: 'Meanwhile',
                child: ComicColumn(
                  gap: 12,
                  children: [
                    const ComicSpeech(
                      person: _sam,
                      text: "I'll bring the big pan.",
                      author: 'Sam · 21:16',
                    ),
                    const ComicSpeech(
                      person: _lee,
                      text: 'Four seats in the car. Dibs on the music.',
                      author: 'Lee · 21:20',
                    ),
                    const ComicSpeech(
                      person: _ola,
                      text: 'The second one works for me.',
                      author: 'Ola · 21:34',
                    ),
                    const ComicGrow(child: SizedBox.shrink()),
                    ComicReply(
                      person: const ComicPerson(
                        initials: 'YO',
                        portrait: ComicPortrait(ComicBust.puff, cropped: true),
                        isCurrentUser: true,
                        size: 40,
                      ),
                      hint: 'Say something…',
                      icon: LucideIcons.send,
                      onSend: () {},
                    ),
                  ],
                ),
              ),
            ],
          ),
          const ComicSectionHeader('Lately', note: '3 things'),
          const ComicTier(
            spans: [4, 5, 3],
            phone: ComicTierLayout.strip,
            children: [
              ComicMarkPanel(
                date: 'Sun 8',
                leading: ComicMark(ComicMarks.mug),
                sfx: 'Munch!',
                title: 'A late breakfast',
                words: 'Two plates. Both for one.',
              ),
              ComicMarkPanel(
                date: 'Sat 7',
                leading: ComicMark(ComicMarks.dice),
                ground: 2,
                sfx: 'Clack!',
                title: 'A game night',
                words: 'Nine hours, one champion.',
              ),
              ComicMarkPanel(
                date: 'Sun 1',
                leading: ComicMark(ComicMarks.pumpkin),
                ground: 3,
                sfx: 'Scoop!',
                title: 'A bit of carving',
                words: 'Six tries at one face.',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
