// The star is `ComicListTile` under a compact `ComicSplash`: what's waiting on someone, then a day in `ComicTimedRow`s. Copy it
// for a day, an inbox of asks, a list of things to confirm.
import 'package:material_ui/material_ui.dart';
import 'package:comic_ui/comic_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

// The demo art is the example's; a test or page that draws it reads it from there.
// ignore: avoid_relative_lib_imports
import '../../example/lib/demo_art.dart';

class AgendaPage extends StatelessWidget {
  const AgendaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ComicScaffold(
      topBar: const ComicAppBar(),
      body: ComicSections(
        children: [
          ComicTier(
            spans: const [8, 4],
            phone: ComicTierLayout.stack,
            children: [
              ComicPanelStack(
                children: [
                  const ComicSplash(
                    compact: true,
                    layout: ComicSplashLayout.titleHigh,
                    title: 'Five things\ntoday',
                    caption: 'Wednesday the 11th',
                    captionIcon: LucideIcons.sun,
                    burst: ComicCoverBurst('2', over: 'Only', under: 'to do!'),
                    figure: Center(child: ComicMark(ComicMarks.mug, size: 150)),
                    heroSize: 72,
                  ),
                ],
              ),
              ComicPanel(
                caption: 'Waiting on you',
                captionIcon: LucideIcons.bell,
                captionTone: ComicSpeaker.currentUser,
                child: ComicList(
                  children: [
                    ComicListTile(
                      isFirst: true,
                      title: 'Say yes to the first thing',
                      subtitle: 'Before 15:00, it needs a yes',
                      action: ComicButton(
                        'Confirm',
                        size: ComicButtonSize.small,
                        onPressed: () {},
                      ),
                    ),
                    ComicListTile(
                      title: 'Sign the long form',
                      subtitle: 'Two minutes',
                      leading: const ComicPerson(initials: 'AC'),
                      action: ComicButton(
                        'Sign',
                        size: ComicButtonSize.small,
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const ComicSectionHeader('The rest of today', note: '3 more'),
          const ComicTier(
            phone: ComicTierLayout.stack,
            children: [
              ComicChapterPanel(
                caption: 'This morning',
                title: 'Getting going',
                art: ComicArtBand(
                  leading: ComicMark(ComicMarks.mug),
                  markSize: 90,
                ),
                children: [
                  ComicTimedRow(
                    '09:30',
                    title: 'The early thing',
                    subtitle: 'Room 2',
                    isFirst: true,
                    inset: 14,
                  ),
                  ComicTimedRow(
                    '11:00',
                    title: 'A call',
                    subtitle: 'Twenty minutes',
                    inset: 14,
                  ),
                ],
              ),
              ComicChapterPanel(
                caption: 'This afternoon',
                title: 'The main event',
                art: ComicArtBand(
                  ground: 2,
                  leading: ComicMark(ComicMarks.clapper),
                  markSize: 90,
                ),
                children: [
                  ComicTimedRow(
                    '14:00',
                    title: 'The one that matters',
                    subtitle: 'Main room',
                    isFirst: true,
                    selected: true,
                    inset: 14,
                  ),
                  ComicTimedRow('16:30', title: 'Wrap up', inset: 14),
                ],
              ),
              ComicChapterPanel(
                caption: 'Tonight',
                title: 'And home',
                art: ComicArtBand(
                  ground: 4,
                  leading: ComicMark(ComicMarks.moon, onNight: true),
                  markSize: 90,
                ),
                children: [
                  ComicTimedRow(
                    '19:00',
                    title: 'Supper, with someone',
                    isFirst: true,
                    inset: 14,
                  ),
                  ComicTimedRow(
                    '21:30',
                    title: 'Nothing at all',
                    subtitle: 'On purpose',
                    inset: 14,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
