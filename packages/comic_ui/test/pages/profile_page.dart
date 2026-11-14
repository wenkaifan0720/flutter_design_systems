// One person and their settings. The star is `ComicLineup`: a drawn cast shoulder to shoulder with their names on captions. `ComicFacts`
// gives their figures, `ComicSwitchRow`s and `ComicListTile`s are the settings. Copy it for a profile, an account page, a list of
// people. Busts come from `ComicBust`, or a person takes initials or a picture from `slotId`.
import 'package:material_ui/material_ui.dart';
import 'package:comic_ui/comic_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

// The demo art is the example's; a test or page that draws it reads it from there.
// ignore: avoid_relative_lib_imports
import '../../example/lib/demo_art.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  var _reminders = true;
  var _votes = true;
  var _quiet = false;

  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context);
    return ComicScaffold(
      topBar: const ComicAppBar(),
      body: ComicSections(
        children: [
          ComicTier(
            spans: const [5, 7],
            phone: ComicTierLayout.stack,
            children: [
              ComicPanel(
                caption: 'Your card',
                captionTone: ComicSpeaker.currentUser,
                child: ComicColumn(
                  gap: 12,
                  children: [
                    ComicBeside(
                      object: const ComicPerson(
                        initials: 'YO',
                        portrait: ComicPortrait(ComicBust.puff, cropped: true),
                        isCurrentUser: true,
                        size: 72,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ComicLetters('Sam Doe', style: t.type.question),
                          Text('Here since last spring', style: t.type.meta),
                        ],
                      ),
                    ),
                    const ComicFacts([
                      ('12', 'this year'),
                      ('164', 'in all'),
                      ('6', 'people'),
                    ], centred: true),
                  ],
                ),
              ),
              ComicPanel(
                caption: 'Settings',
                captionIcon: LucideIcons.settings,
                child: ComicColumn(
                  children: [
                    ComicSwitchRow(
                      isFirst: true,
                      label: 'Reminders',
                      note: 'The evening before a thing.',
                      value: _reminders,
                      onChanged: (on) => setState(() => _reminders = on),
                    ),
                    ComicSwitchRow(
                      label: 'New questions',
                      note: 'When a vote opens.',
                      value: _votes,
                      onChanged: (on) => setState(() => _votes = on),
                    ),
                    ComicSwitchRow(
                      label: 'Quiet hours',
                      note: 'Nothing after ten.',
                      value: _quiet,
                      onChanged: (on) => setState(() => _quiet = on),
                    ),
                    ComicListTile(
                      title: 'Your email',
                      subtitle: 'sam@example.com',
                      action: ComicButton(
                        'Change',
                        size: ComicButtonSize.small,
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const ComicSectionHeader('Your people', note: '6 of you'),
          ComicPanel(
            bleed: true,
            caption: 'Everyone',
            captionIcon: LucideIcons.users,
            child: ComicCoverPrint(
              child: const ComicLineup([
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
              ]),
            ),
          ),
          ComicEmptyState(
            title: 'Nothing else',
            body: 'That\'s your whole account.',
            action: ComicButton(
              'Sign out',
              icon: LucideIcons.logOut,
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }
}
