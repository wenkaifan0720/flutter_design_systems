/// Gloss's display parts: disclosures, tables, key-value lists, timelines,
/// faces, ruby badges, tags, media, skeletons and the gauge.
library;

import 'package:material_ui/material_ui.dart';
import 'package:gloss_ui/gloss_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

/// The display page.
Widget kitDisplayDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Display',
  sections: const [
    KitSection(
      title: 'Disclosures',
      children: [
        _Narrow(
          GlossDisclosureGroup(
            children: [
              GlossDisclosure(
                title: 'Storage',
                initiallyExpanded: true,
                child: Text('Keeps three days in the fridge.'),
              ),
              GlossDisclosure(
                title: 'Freezing',
                subtitle: 'Up to a month',
                child: Text('Freeze before adding the lemon.'),
              ),
            ],
          ),
        ),
      ],
    ),
    KitSection(
      title: 'Tables and lists of terms',
      children: [
        _Narrow(
          GlossTable(
            columns: [
              GlossTableColumn('Ingredient', flex: 2),
              GlossTableColumn('Grams', numeric: true),
            ],
            rows: [
              ['Arborio rice', '320'],
              ['Parmesan', '60'],
              ['Butter', '40'],
            ],
          ),
        ),
        _Narrow(
          GlossDescriptionList(
            entries: [
              GlossDescription('Serves', '4'),
              GlossDescription('Takes', '35 min'),
              GlossDescription('Keeps', '3 days'),
            ],
          ),
        ),
      ],
    ),
    KitSection(
      title: 'A timeline',
      children: [
        _Narrow(
          GlossTimeline(
            entries: [
              GlossTimelineEntry(
                title: 'Toast the rice',
                time: '18:05',
                done: true,
              ),
              GlossTimelineEntry(
                title: 'Add the stock',
                time: '18:10',
                body: 'A ladle at a time, stirring.',
                done: true,
              ),
              GlossTimelineEntry(title: 'Stir in the lemon', time: '18:30'),
            ],
          ),
        ),
      ],
    ),
    KitSection(
      title: 'Faces, badges and tags',
      children: [
        KitRow(
          children: [
            GlossAvatar(name: 'Noa Ferreira'),
            GlossAvatar(name: 'Iko Tanaka', size: 32),
            GlossAvatarGroup(
              avatars: [
                GlossAvatar(name: 'Noa Ferreira'),
                GlossAvatar(name: 'Iko Tanaka'),
                GlossAvatar(name: 'Rui Alves'),
                GlossAvatar(name: 'Ama Owusu'),
                GlossAvatar(name: 'Lev Baran'),
              ],
            ),
          ],
        ),
        // A badge rides past its glyph's top end corner: each badged glyph
        // keeps that room clear beside it.
        KitRow(
          children: [
            Padding(
              padding: EdgeInsetsDirectional.only(
                top: GlossSpacing.small,
                end: GlossSpacing.large,
              ),
              child: GlossBadge(count: 3, child: Icon(LucideIcons.bell)),
            ),
            Padding(
              padding: EdgeInsetsDirectional.only(
                top: GlossSpacing.small,
                end: GlossSpacing.large,
              ),
              child: GlossBadge(
                count: 120,
                child: Icon(LucideIcons.shoppingBasket),
              ),
            ),
          ],
        ),
        KitRow(
          children: [
            GlossTag('Quick'),
            GlossTag('Vegetarian', tone: GlossTagTone.jade),
            GlossTag('Contains nuts', tone: GlossTagTone.danger),
          ],
        ),
      ],
    ),
    KitSection(
      title: 'Media and skeletons',
      children: [
        _Narrow(GlossMedia(image: null, semanticLabel: 'The dish')),
        _Narrow(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GlossSkeleton(width: 220, height: 20),
              SizedBox(height: GlossSpacing.small),
              GlossSkeleton(width: 160),
              SizedBox(height: GlossSpacing.small),
              GlossSkeleton(width: 260),
            ],
          ),
        ),
      ],
    ),
    KitSection(
      title: 'The gauge and the dividers',
      children: [
        _Narrow(
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GlossMeter(value: 0.62, label: 'Pantry', valueText: '62%'),
              SizedBox(height: GlossSpacing.regular),
              GlossMeter(
                value: 0.92,
                high: 0.8,
                label: 'Freezer',
                valueText: 'Nearly full',
              ),
              SizedBox(height: GlossSpacing.large),
              GlossDivider(),
              SizedBox(height: GlossSpacing.large),
              // As tall as the words, 40 at least, the rule their height.
              IntrinsicHeight(
                child: Row(
                  children: [
                    SizedBox(height: 40),
                    Flexible(child: Text('Lunch')),
                    SizedBox(width: GlossSpacing.regular),
                    GlossDivider.vertical(),
                    SizedBox(width: GlossSpacing.regular),
                    Flexible(child: Text('Dinner')),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  ],
);

class _Narrow extends StatelessWidget {
  const _Narrow(this.child);

  final Widget child;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 420),
    child: child,
  );
}
