// One thing, whole, step by step. The star is `ComicStepPanel` in tiers: numbered panels with a drawn object and a sound effect, one of
// them `long` where the wait is. A compact `ComicSplash` opens it and `ComicFigures` give the times. Copy it for a how-to, a recipe, a
// setup, any detail page that has an order to it.
import 'package:material_ui/material_ui.dart';
import 'package:comic_ui/comic_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

// The demo art is the example's; a test or page that draws it reads it from there.
// ignore: avoid_relative_lib_imports
import '../../example/lib/demo_art.dart';

class MethodPage extends StatefulWidget {
  const MethodPage({super.key});

  @override
  State<MethodPage> createState() => _MethodPageState();
}

class _MethodPageState extends State<MethodPage> {
  var _serves = 4;
  final _have = <String>{'A big pan'};

  @override
  Widget build(BuildContext context) {
    return ComicScaffold(
      topBar: ComicAppBar(
        leading: ComicAppBar.autoLeading(context),
        actions: [
          ComicIconButton(
            LucideIcons.bookmark,
            label: 'Save',
            onPressed: () {},
          ),
        ],
      ),
      body: ComicSections(
        children: [
          ComicTier(
            spans: const [8, 4],
            phone: ComicTierLayout.stack,
            children: [
              const ComicSplash(
                compact: true,
                layout: ComicSplashLayout.titleHigh,
                title: 'One big\npot',
                caption: "Tonight's plan",
                captionIcon: LucideIcons.flame,
                figure: Center(child: ComicMark(ComicMarks.pan, size: 150)),
                sfx: 'Sizzle!',
                burst: ComicCoverBurst('1 h', over: 'Ready in', under: 'or so'),
                factsCentred: true,
                facts: [
                  ('Easy', 'one pot'),
                  ('4.7', 'by 300 people'),
                  ('6', 'steps'),
                ],
                heroSize: 72,
              ),
              ComicPanelStack(
                children: [
                  const ComicPanel(
                    caption: 'Time',
                    captionIcon: LucideIcons.timer,
                    child: ComicFigures([
                      ('20 min', 'Prep'),
                      ('40 min', 'Cook'),
                      ('1 h', 'Total'),
                    ], highlightLast: true),
                  ),
                  ComicPanel(
                    caption: "You'll need",
                    child: ComicColumn(
                      gap: 8,
                      children: [
                        ComicNumberField(
                          value: _serves,
                          unit: 'people',
                          onChanged: (next) => setState(() => _serves = next),
                          min: 1,
                        ),
                        for (final thing in const [
                          'A big pan',
                          'Something to stir with',
                        ])
                          ComicBeside(
                            object: ComicCheckbox(
                              value: _have.contains(thing),
                              label: thing,
                              onChanged: (on) => setState(
                                () => on == true
                                    ? _have.add(thing)
                                    : _have.remove(thing),
                              ),
                            ),
                            child: Text(
                              thing,
                              style: ComicTheme.of(context).type.title,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const ComicSectionHeader('The steps', note: '6 of them'),
          const ComicSegments(
            [8, 5, 2, 5, 25, 5],
            long: 4,
            labels: ['1', '2', '3', '4', '5', '6'],
            scaleStart: '0',
            scaleEnd: '50 min',
          ),
          const ComicTier(
            phone: ComicTierLayout.stack,
            children: [
              ComicStepPanel(
                number: '1',
                leading: ComicMark(ComicMarks.pan),
                sfx: 'Sizzle!',
                words: 'Warm the pan and soften what goes in first.',
              ),
              ComicStepPanel(
                number: '2',
                leading: ComicMark(ComicMarks.pepper),
                ground: 2,
                sfx: 'Slump.',
                words: 'Add the next thing and let it give up.',
              ),
              ComicStepPanel(
                number: '3',
                leading: ComicMark(ComicMarks.jars),
                ground: 3,
                sfx: 'Toast!',
                words: 'Stir the dry things through for a minute.',
              ),
            ],
          ),
          const ComicTier(
            spans: [3, 6, 3],
            phone: ComicTierLayout.stack,
            children: [
              ComicStepPanel(
                number: '4',
                leading: ComicMark(ComicMarks.pour),
                ground: 2,
                sfx: 'Glug',
                words: 'Pour in the rest and bring it up.',
              ),
              ComicStepPanel(
                long: true,
                number: '5',
                leading: ComicMark(ComicMarks.simmer, onNight: true),
                ground: 4,
                sfx: 'Blub… blub…',
                words: 'Turn it down, lid ajar, and leave it. This is the long part, and the part that does the work.',
              ),
              ComicStepPanel(
                number: '6',
                leading: ComicMark(ComicMarks.bar),
                sfx: 'Plop!',
                words: 'Finish it, taste it, and call everyone.',
              ),
            ],
          ),
          ComicTier(
            spans: const [5, 7],
            phone: ComicTierLayout.stack,
            children: [
              const ComicPanel(
                caption: 'What it adds up to',
                child: ComicPieChart(
                  centre: '420',
                  unit: 'kcal',
                  slices: [
                    ComicSlice('First part', 200, figure: '200', share: '48%'),
                    ComicSlice('Second part', 120, figure: '120', share: '29%'),
                    ComicSlice('The rest', 100, figure: '100', share: '23%'),
                  ],
                ),
              ),
              ComicPanel(
                caption: 'Per serving',
                child: ComicColumn(
                  children: const [
                    ComicKvRow(
                      'First part',
                      '50 g',
                      share: '19%',
                      isFirst: true,
                    ),
                    ComicKvRow('Second part', '19 g', share: '38%'),
                    ComicKvRow(
                      'The good part',
                      '21 g',
                      share: '70%',
                      selected: true,
                    ),
                    ComicKvRow('The rest', '11 g', share: '16%'),
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
