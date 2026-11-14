// A collection, and finding something in it. The star is `ComicMarkPanel` in a `ComicTier` that makes a strip on a phone: a wall of
// things, each a panel of a comic. A search and `ComicChip`s stand first, and `ComicPictureCard`s hold whatever has a picture. One
// tier leans (`slanted`), once on the page. Copy it for a gallery, a shelf or search results.
import 'package:material_ui/material_ui.dart';
import 'package:comic_ui/comic_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

// The demo art is the example's; a test or page that draws it reads it from there.
// ignore: avoid_relative_lib_imports
import '../../example/lib/demo_art.dart';

class WallPage extends StatefulWidget {
  const WallPage({super.key});

  @override
  State<WallPage> createState() => _WallPageState();
}

class _WallPageState extends State<WallPage> {
  var _kind = 'All';

  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context);
    return ComicScaffold(
      topBar: const ComicAppBar(),
      body: ComicSections(
        children: [
          ComicPanel(
            caption: 'Find something',
            captionIcon: LucideIcons.search,
            child: ComicColumn(
              gap: 10,
              children: [
                const ComicTextField(
                  hint: 'Search the wall',
                  leading: Icon(LucideIcons.search, size: 18),
                ),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final kind in const ['All', 'Out', 'In', 'Away'])
                      ComicChip(
                        kind,
                        selected: kind == _kind,
                        onPressed: () => setState(() => _kind = kind),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const ComicSectionHeader('This month', note: '3 things'),
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
          const ComicSectionHeader('Last month', note: '2 things'),
          const ComicTier(
            slanted: true,
            phone: ComicTierLayout.strip,
            children: [
              ComicMarkPanel(
                date: '21–23',
                leading: ComicMark(ComicMarks.tent, onNight: true),
                ground: 4,
                sfx: 'Snap!',
                title: 'A night outdoors',
                words: 'Slept under the stars anyway.',
              ),
              ComicMarkPanel(
                date: 'Sat 25',
                leading: ComicMark(ComicMarks.guitar),
                ground: 3,
                sfx: 'Boom boom',
                title: 'A loud evening',
                words: 'Front row, all of us.',
              ),
            ],
          ),
          const ComicSectionHeader('With pictures', note: '3 things'),
          ComicTier(
            phone: ComicTierLayout.strip,
            children: [
              ComicPictureCard(
                slotId: 'wall-1',
                title: 'The first one',
                subtitle: 'Saved in June',
                trailing: const ComicTag('New'),
                onPressed: () {},
              ),
              ComicPictureCard(
                slotId: 'wall-2',
                title: 'The second one',
                subtitle: 'Saved in May',
                onPressed: () {},
              ),
              ComicPictureCard(
                slotId: 'wall-3',
                title: 'The third one',
                subtitle: 'Saved in April',
                onPressed: () {},
              ),
            ],
          ),
          Text('That\'s everything so far.', style: t.type.small),
        ],
      ),
    );
  }
}
