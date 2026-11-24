// Arranging a page's things: a region that scrolls with a scrollbar always
// in sight, two panes and the grip between them, a list put in order three
// ways, rows with actions a swipe away and in sight, and a tree of places.
import 'package:material_ui/material_ui.dart';
import 'package:civic_ui/civic_ui.dart';

import '../kit.dart';

Widget kitArrangeDemo(Brightness brightness) =>
    kitApp(brightness: brightness, home: const _Arrange());

class _Arrange extends StatefulWidget {
  const _Arrange();

  @override
  State<_Arrange> createState() => _ArrangeState();
}

class _ArrangeState extends State<_Arrange> {
  final _terms = ScrollController();
  final _documents = ['Proof of address', 'Vehicle logbook', 'Photo ID'];
  final _services = RawTreeController<String>(
    roots: const ['Parking', 'Bins', 'Council tax'],
    childrenOf: (s) => _under[s] ?? const [],
    expanded: const ['Parking', 'Permits'],
  )..select('Resident');
  String _done = '';
  bool _recordOpen = false;

  static const _under = {
    'Parking': ['Permits', 'Fines'],
    'Permits': ['Resident', 'Visitor', 'Business'],
    'Bins': ['Collections', 'New bins'],
  };

  @override
  void dispose() {
    _terms.dispose();
    _services.dispose();
    super.dispose();
  }

  void _say(String words) => setState(() => _done = words);

  @override
  Widget build(BuildContext context) => CivicScaffold(
    topBar: const CivicTopBar(title: 'Civic', emblem: KitEmblem()),
    body: CivicPageBody(
      title: 'Scrolling, panes, ordering & trees',
      maxWidth: CivicLayout.maxContentWidth,
      children: [
        KitSection(
          title: 'Scroll area',
          caption: 'Its scrollbar stays in sight; the keys scroll it too.',
          children: [
            SizedBox(
              height: 160,
              child: CivicScrollArea(
                controller: _terms,
                focusable: true,
                semanticLabel: 'Terms of the permit',
                child: SingleChildScrollView(
                  controller: _terms,
                  child: const Padding(
                    padding: EdgeInsetsDirectional.only(end: CivicSpacing.s24),
                    child: Text(
                      'The permit is for the vehicle named on it. Show it on '
                      'the windscreen, where a warden can read it.\n\n'
                      'It lets the vehicle park in its zone\'s permit bays at '
                      'any time. It does not let it park on a yellow line, in '
                      'a disabled bay or in a bay for loading.\n\n'
                      'Tell us within 14 days if the vehicle changes, or if '
                      'you move out of the zone. We may cancel a permit used '
                      'for another vehicle.',
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: CivicSpacing.s48),
        KitSection(
          title: 'Split view',
          caption:
              'Drag the grip, or focus it and use the arrow keys. Below 600 '
              'it shows the list, then the record with a way back.',
          children: [
            // Each pane scrolls, as an app's list and record do; the view
            // grows with the reader's text.
            SizedBox(
              height: MediaQuery.textScalerOf(context).scale(200),
              child: CivicSplitView(
                minFirst: 120,
                minSecond: 160,
                initialFraction: 0.4,
                showSecond: _recordOpen,
                onBack: () => setState(() => _recordOpen = false),
                first: ColoredBox(
                  color: context.civicTheme.background,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(CivicSpacing.s16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: CivicSpacing.s8,
                      children: [
                        const Text('Your applications'),
                        CivicLink(
                          onPressed: () => setState(() => _recordOpen = true),
                          child: const Text('Resident permit, Zone B'),
                        ),
                      ],
                    ),
                  ),
                ),
                second: ColoredBox(
                  color: context.civicTheme.background,
                  child: const SingleChildScrollView(
                    padding: EdgeInsets.all(CivicSpacing.s16),
                    child: Text('Resident permit, Zone B: in review.'),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: CivicSpacing.s48),
        KitSection(
          title: 'Reorderable list',
          caption: 'Drag a grip, press Alt with an arrow, or the words.',
          children: [
            CivicReorderableList<String>(
              items: _documents,
              labelOf: (d) => d,
              onReorder: (from, to) => setState(
                () => _documents.insert(to, _documents.removeAt(from)),
              ),
            ),
          ],
        ),
        const SizedBox(height: CivicSpacing.s48),
        KitSection(
          title: 'Swipe actions',
          caption: 'A swipe is a shortcut: the same actions are in the menu.',
          spacing: 0,
          children: [
            for (final (title, ref) in const [
              ('Resident permit, Zone B', 'BRM-4821-K'),
              ('Visitor permits, 10 days', 'BRM-3307-A'),
            ])
              CivicSwipeActions(
                menuLabel: 'Actions for $title',
                initiallyOpen: ref == 'BRM-4821-K',
                endActions: [
                  CivicSwipeAction(
                    label: 'Archive',
                    onPressed: () => _say('Archived $ref'),
                  ),
                  CivicSwipeAction(
                    label: 'Withdraw',
                    isDestructiveAction: true,
                    onPressed: () => _say('Withdrew $ref'),
                  ),
                ],
                child: CivicListRow(title: Text(title), subtitle: Text(ref)),
              ),
            if (_done.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: CivicSpacing.s16),
                child: Text(_done),
              ),
          ],
        ),
        const SizedBox(height: CivicSpacing.s48),
        KitSection(
          title: 'Tree',
          caption: 'One tab stop; the arrows open, shut and move.',
          children: [
            CivicTree<String>(
              controller: _services,
              labelOf: (s) => s,
              semanticLabel: 'Council services',
            ),
          ],
        ),
      ],
    ),
  );
}
