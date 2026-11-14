// Money and counts, drawn. The star is `ComicFlow`: ribbons true to their amounts into one burst. A `ComicClaim` on your dots says where
// you stand first, `ComicShares` splits a total, `ComicUnits` counts by month and `ComicBarList` ranks. Copy it for a dashboard, a budget
// or any page whose data is who owes, who did and how much.
import 'package:material_ui/material_ui.dart';
import 'package:comic_ui/comic_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

// The demo art is the example's; a test or page that draws it reads it from there.
// ignore: avoid_relative_lib_imports
import '../../example/lib/demo_art.dart';

const _sam = ComicPerson(
  initials: 'SD',
  portrait: ComicPortrait(ComicBust.bob, cropped: true),
  size: 34,
);
const _you = ComicPerson(
  initials: 'YO',
  portrait: ComicPortrait(ComicBust.puff, cropped: true),
  isCurrentUser: true,
  size: 34,
);
const _lee = ComicPerson(
  initials: 'LB',
  portrait: ComicPortrait(ComicBust.quiff, cropped: true),
  size: 34,
);
const _ola = ComicPerson(
  initials: 'OK',
  portrait: ComicPortrait(ComicBust.topknot, cropped: true),
  size: 34,
);

class LedgerPage extends StatelessWidget {
  const LedgerPage({super.key});

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
                caption: 'Where you stand',
                captionIcon: LucideIcons.wallet,
                captionTone: ComicSpeaker.currentUser,
                ground: ComicPanelFill.currentUserDots,
                child: ComicColumn(
                  gap: 12,
                  children: [
                    const ComicClaim(
                      before: 'You owe Sam',
                      figure: '€19',
                      note: 'Your share of the month, less what you paid.',
                      person: ComicPerson(
                        initials: 'SD',
                        portrait: ComicPortrait(ComicBust.bob, cropped: true),
                        size: 56,
                      ),
                    ),
                    const ComicFigures([
                      ('€114', 'You paid'),
                      ('€133', 'Your share'),
                    ]),
                    const ComicGrow(child: SizedBox.shrink()),
                    ComicButton.filled(
                      'Settle it',
                      icon: LucideIcons.handCoins,
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
              ComicPanel(
                caption: 'Three payments settle it',
                captionIcon: LucideIcons.handCoins,
                child: ComicColumn(
                  children: [
                    const ComicPanelHead('Everybody pays Sam'),
                    const ComicFlow(
                      perUnit: .8,
                      into: 'Sam',
                      intoFigure: '+€120',
                      intoPerson: ComicPerson(
                        initials: 'SD',
                        portrait: ComicPortrait(ComicBust.bob, cropped: true),
                        size: 56,
                      ),
                      from: [
                        ComicFlowFrom(
                          'You',
                          19,
                          figure: '€19',
                          person: _you,
                          isCurrentUser: true,
                        ),
                        ComicFlowFrom('Lee', 37, figure: '€37', person: _lee),
                        ComicFlowFrom('Ola', 64, figure: '€64', person: _ola),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text('Ribbons are drawn to scale.', style: t.type.small),
                  ],
                ),
              ),
            ],
          ),
          const ComicSectionHeader('The month', note: '€870 in all'),
          ComicTier(
            spans: const [7, 5],
            phone: ComicTierLayout.stack,
            children: [
              const ComicPanel(
                caption: 'Where it went',
                child: ComicShares(
                  stamp: 'Biggest',
                  scaleStart: '€0',
                  scaleEnd: '€870',
                  parts: [
                    ComicShare('Rooms', 540, figure: '€540'),
                    ComicShare(
                      'Food',
                      190,
                      figure: '€190',
                      ink: ComicShareFill.dots,
                    ),
                    ComicShare(
                      'Getting there',
                      140,
                      figure: '€140',
                      ink: ComicShareFill.denseDots,
                    ),
                  ],
                ),
              ),
              ComicPanel(
                caption: 'Spent',
                child: ComicColumn(
                  children: [
                    const ComicLedgerRow(
                      date: 'Tue 10',
                      title: 'Two nights',
                      subtitle: 'Sam paid · €90 each',
                      value: '€540',
                      isFirst: true,
                    ),
                    const ComicLedgerRow(
                      date: 'Sun 8',
                      title: 'A late breakfast',
                      subtitle: 'You paid · €19 each',
                      value: '€114',
                      isCurrentUser: true,
                    ),
                    const ComicTotalRow('Each share', '€133'),
                    const SizedBox(height: 6),
                    Text('Nothing paid since Sunday.', style: t.type.small),
                  ],
                ),
              ),
            ],
          ),
          const ComicSectionHeader('So far', note: 'this year'),
          const ComicTier(
            phone: ComicTierLayout.stack,
            children: [
              ComicPanel(
                caption: 'By month',
                child: ComicColumn(
                  children: [
                    ComicPanelHead('Twelve, one panel each'),
                    ComicUnits([
                      ComicUnitColumn('Jul', 1),
                      ComicUnitColumn('Aug', 3),
                      ComicUnitColumn('Sep', 2),
                      ComicUnitColumn('Oct', 2),
                      ComicUnitColumn('Nov', 4, now: true),
                    ]),
                  ],
                ),
              ),
              ComicPanel(
                caption: 'Who came',
                child: ComicColumn(
                  children: [
                    ComicPanelHead('Most often'),
                    ComicBarList(
                      of: 12,
                      labelWidth: 60,
                      entries: [
                        ComicBarEntry('Lee', 11, leading: _lee),
                        ComicBarEntry(
                          'You',
                          10,
                          leading: _you,
                          isCurrentUser: true,
                        ),
                        ComicBarEntry('Sam', 8, leading: _sam),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
