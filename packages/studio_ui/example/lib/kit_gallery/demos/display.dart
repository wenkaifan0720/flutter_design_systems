import 'package:material_ui/material_ui.dart';
import 'package:studio_ui/studio_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

/// Plates, portholes and glass: what shows and does not press.
Widget kitDisplayDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Plates, portholes and glass',
  sections: [
    const KitSection(
      title: 'Tags',
      note: 'Small engraved plates; a lamp lit for something live, red for something wrong.',
      children: [
        KitRow(
          children: [
            StudioTag('Draft'),
            StudioTag('On air', tone: StudioTagTone.lit),
            StudioTag('Upload failed', tone: StudioTagTone.danger),
          ],
        ),
      ],
    ),
    const KitSection(
      title: 'Avatars',
      note: 'Portholes of dark glass in a metal bezel; initials glow when there is no picture.',
      children: [
        KitRow(
          children: [
            StudioAvatar(name: 'Noor Haddad', size: 56),
            StudioAvatar(name: 'Teo Park'),
            StudioAvatar(name: 'Ama Boateng', size: 28),
            StudioAvatarGroup(
              names: [
                'Noor Haddad',
                'Teo Park',
                'Ama Boateng',
                'Lis Varga',
                'Ike Moss',
                'Rui Sato',
              ],
            ),
          ],
        ),
      ],
    ),
    const KitSection(
      title: 'Badges',
      note: 'A count in a small readout, or a lamp alone.',
      children: [
        KitRow(
          children: [
            StudioBadge(count: 3, child: Icon(LucideIcons.bell, size: 24)),
            StudioBadge(count: 128, child: Icon(LucideIcons.inbox, size: 24)),
            StudioBadge(child: Icon(LucideIcons.download, size: 24)),
          ],
        ),
      ],
    ),
    const KitSection(
      title: 'Media',
      note: 'A picture behind glass; a glyph stands in while it loads.',
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: SizedBox(
            width: 360,
            child: StudioMedia(image: null, semanticLabel: 'The cover'),
          ),
        ),
      ],
    ),
    const KitSection(
      title: 'Disclosure',
      note: 'A row that opens to show more; the wedge turns and lights.',
      children: [
        StudioDisclosure(
          title: 'Show notes',
          initiallyExpanded: true,
          child: Text(
            'Recorded in one take, at night, with the window open. The traffic is real.',
          ),
        ),
        StudioDisclosure(
          title: 'Transcript',
          child: Text('00:00 Noor: Welcome back to Night Desk.'),
        ),
      ],
    ),
    const KitSection(
      title: 'Description list',
      note: 'A spec plate: terms as legends, values beside them (under them when narrow).',
      children: [
        StudioDescriptionList(
          entries: [
            StudioDescription('Length', '42 min 10 s'),
            StudioDescription('Format', 'Stereo, 48 kHz, 24 bit'),
            StudioDescription('Published', 'Thursday 19 November, 09:00'),
          ],
        ),
      ],
    ),
    const KitSection(
      title: 'Table',
      note: 'Rows of words on glass; figures to the end, tabular.',
      children: [
        StudioTable(
          columns: [
            StudioTableColumn('Episode', flex: 3),
            StudioTableColumn('Length', numeric: true),
            StudioTableColumn('Plays', numeric: true),
          ],
          rows: [
            ['Pilot', '38:02', '1,204'],
            ['The long table', '51:40', '864'],
            ['Field notes from the coast', '44:15', '702'],
          ],
        ),
      ],
    ),
    const KitSection(
      title: 'Timeline',
      note: 'Lamps down an engraved line, lit as far as things have happened.',
      children: [
        StudioTimeline(
          entries: [
            StudioTimelineEntry(
              title: 'Recorded',
              time: 'Mon 14:00',
              detail: 'Three takes, 1 h 52 min.',
              done: true,
            ),
            StudioTimelineEntry(title: 'Edited', time: 'Tue 10:00', done: true),
            StudioTimelineEntry(title: 'Mastered', time: 'Wed 16:30'),
            StudioTimelineEntry(title: 'Published', time: 'Thu 09:00'),
          ],
        ),
      ],
    ),
  ],
);
