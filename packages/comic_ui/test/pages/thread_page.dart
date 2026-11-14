// A conversation told as a comic. The star is `ComicSpeech`: a head and a `ComicBalloon` whose tail finds it, under a free
// `ComicCaption` that narrates the time. Beside it what's pending and who's in it, so the column carries the page;
// `ComicVoicePanel`s hold what's worth keeping and `ComicReply` stands at the foot. Copy it for a thread, a feed of what
// people said, the comments under something.
import 'package:material_ui/material_ui.dart';
import 'package:comic_ui/comic_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

// The demo art is the example's; a test or page that draws it reads it from there.
// ignore: avoid_relative_lib_imports
import '../../example/lib/demo_art.dart';

const _you = ComicPerson(
  initials: 'YO',
  portrait: ComicPortrait(ComicBust.puff, cropped: true),
  isCurrentUser: true,
  size: 44,
);
const _sam = ComicPerson(
  initials: 'SD',
  portrait: ComicPortrait(ComicBust.bob, cropped: true),
  size: 48,
);
const _lee = ComicPerson(
  initials: 'LB',
  portrait: ComicPortrait(ComicBust.quiff, cropped: true),
  size: 48,
);
const _ola = ComicPerson(
  initials: 'OK',
  portrait: ComicPortrait(ComicBust.topknot, cropped: true),
  size: 48,
);

class ThreadPage extends StatelessWidget {
  const ThreadPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context);
    return ComicScaffold(
      topBar: ComicAppBar(
        title: 'The long weekend',
        leading: ComicAppBar.autoLeading(context),
      ),
      body: ComicSections(
        children: [
          ComicTier(
            spans: const [8, 4],
            phone: ComicTierLayout.stack,
            children: [
              ComicPanel(
                child: ComicColumn(
                  gap: 12,
                  children: [
                    const ComicCaption(
                      'Last night, a little after nine',
                      free: true,
                    ),
                    const ComicSpeech(
                      person: _sam,
                      text: "It's booked for the fourth! Free to move it till Friday if the vote says otherwise.",
                      author: 'Sam · 21:16',
                    ),
                    const ComicSpeech(
                      person: _lee,
                      text: "I'll do Friday's dinner.",
                      author: 'Lee · 21:20',
                    ),
                    const ComicCaption('This morning', free: true),
                    const ComicSpeech(
                      person: _ola,
                      text: 'I can drive. Four seats, dibs on the music.',
                      author: 'Ola · 09:41',
                    ),
                    ComicReply(
                      person: _you,
                      hint: 'Say something…',
                      icon: LucideIcons.send,
                      onSend: () {},
                    ),
                  ],
                ),
              ),
              ComicPanelStack(
                children: [
                  ComicPanel(
                    caption: 'Thinking it over',
                    captionIcon: LucideIcons.messageCircle,
                    child: ComicColumn(
                      gap: 10,
                      children: [
                        const Center(
                          heightFactor: 1,
                          child: ComicThought('Hmm', trailEnd: true),
                        ),
                        Text(
                          'Kit hasn\'t said anything yet.',
                          style: t.type.body,
                        ),
                      ],
                    ),
                  ),
                  ComicPanel(
                    caption: 'In this thread',
                    captionIcon: LucideIcons.users,
                    child: ComicList(
                      children: [
                        for (final (i, (bust, initials, name, said)) in const [
                          (ComicBust.bob, 'SD', 'Sam', 'Said 21:16'),
                          (ComicBust.quiff, 'LB', 'Lee', 'Said 21:20'),
                          (ComicBust.topknot, 'OK', 'Ola', 'Said 09:41'),
                          (ComicBust.beanie, 'KT', 'Kit', 'Read, not yet said'),
                        ].indexed)
                          ComicRuled(
                            rule: i > 0,
                            child: ComicBeside(
                              gap: 12,
                              object: ComicPerson(
                                initials: initials,
                                portrait: ComicPortrait(bust, cropped: true),
                                size: 36,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(name, style: t.type.title),
                                  Text(said, style: t.type.small),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const ComicSectionHeader('Worth keeping', note: '2 things said'),
          const ComicTier(
            phone: ComicTierLayout.stack,
            children: [
              ComicVoicePanel(
                words: 'Best weekend in years, and nobody got lost.',
                name: 'Sam',
                time: 'Last year',
                portrait: ComicPortrait(ComicBust.bob),
              ),
              ComicVoicePanel(
                words: 'Somebody got a little bit lost.',
                name: 'Lee',
                time: 'Last year',
                portrait: ComicPortrait(ComicBust.quiff),
                warm: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
