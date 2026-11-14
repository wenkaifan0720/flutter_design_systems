// A shelf of things with pictures. Star: NeumorphicPictureCard in a NeumorphicGridOf: a picture in a pressed well, its words on the raised slab under it,
// latches to narrow it. A piece with no photograph is drawn by its glyph on a raised cap, not left a hole; one keeps its slot to show the missing
// state, the look's mark in the same well, dark at night. Copy it for a catalogue, a library, a set of places.
import 'package:flutter/widgets.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

// A slot, or the piece's glyph when it has no photograph.
const _items = <(String?, IconData?, String, String, String)>[
  (null, NeumorphicGlyphs.lamp, 'A first piece', 'A short line', '€48'),
  (
    null,
    NeumorphicGlyphs.armchair,
    'A second piece with a longer name',
    'A short line',
    '€62',
  ),
  (
    'third',
    null,
    'A third piece',
    'A longer line about where it is from',
    '€30',
  ),
  (null, NeumorphicGlyphs.clock3, 'A fourth piece', 'A short line', '€115'),
  (null, NeumorphicGlyphs.flower2, 'A fifth piece', 'A short line', '€27'),
  (null, NeumorphicGlyphs.bookOpen, 'A sixth piece', 'A short line', '€74'),
];
const _saved = [
  NeumorphicGlyphs.coffee,
  NeumorphicGlyphs.gem,
  NeumorphicGlyphs.watch,
];

class ShelfPage extends StatelessWidget {
  const ShelfPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    const head = NeumorphicPageHead(
      title: 'The shelf',
      subtitle: '24 pieces, 6 new',
    );
    final narrow = NeumorphicLatchGroup(
      options: const [
        NeumorphicLatch('All'),
        NeumorphicLatch('New'),
        NeumorphicLatch('Saved'),
      ],
      value: 'All',
      onChanged: (_) {},
    );
    return NeumorphicScaffold(
      rail: const [
        NeumorphicRailSet(
          label: 'Kinds',
          gap: 4,
          children: [
            NeumorphicRailLink(label: 'All', figure: '24', selected: true),
            NeumorphicRailLink(label: 'A first kind', figure: '12'),
            NeumorphicRailLink(label: 'A second kind', figure: '8'),
            NeumorphicRailLink(label: 'A third kind', figure: '4'),
          ],
        ),
      ],
      actions: [
        NeumorphicRoundButton(
          NeumorphicGlyphs.search,
          label: 'Search',
          onPressed: () {},
        ),
      ],
      body: NeumorphicSections(
        children: [
          if (t.desk)
            NeumorphicRow(
              spans: const [7, 5],
              children: [
                head,
                Align(alignment: Alignment.bottomCenter, child: narrow),
              ],
            )
          else
            NeumorphicColumn(gap: 14, children: [head, narrow]),
          NeumorphicGridOf(
            columns: t.desk ? 3 : 2,
            gap: t.desk ? 28 : 14,
            runGap: t.desk ? 28 : 14,
            children: [
              for (final (slot, glyph, title, meta, figure) in _items)
                NeumorphicPictureCard(
                  slotId: slot,
                  glyph: glyph,
                  title: title,
                  subtitle: meta,
                  figure: figure,
                  onPressed: () {},
                ),
            ],
          ),
          const NeumorphicSectionHeader(title: 'Saved', subtitle: '3'),
          NeumorphicList(
            children: [
              for (var i = 0; i < 3; i++)
                NeumorphicListTile(
                  isFirst: i == 0,
                  leading: NeumorphicMedia(
                    glyph: _saved[i],
                    aspect: 1,
                    width: 56,
                    label: 'A saved piece',
                  ),
                  title: 'A saved piece ${i + 1}',
                  note: 'Kept this week',
                  trailing: const NeumorphicStatus('€40'),
                  onPressed: () {},
                ),
            ],
          ),
        ],
      ),
    );
  }
}
