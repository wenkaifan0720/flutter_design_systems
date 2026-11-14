/// The sheet group's demo: a field-notes app on a plain `Navigator` with every
/// sheet the family draws, live — the trail log raised as a modal bottom
/// sheet at its partial anchor (drag it up to expand, down to dismiss, or
/// tap the scrim), a short sheet that rests at its own height, an action
/// sheet raised from code, and a full-screen dialog. On Android the system
/// back gesture shrinks the sheet (predictive back); on iOS the sheet is
/// swiped down.
library;

import 'package:flutter/material.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/material_expressive_host.dart';

import '../kit.dart';
import '../kit_stack.dart';

/// The sheet group's demo, in [brightness]: a static sheet opens with the
/// trail log raised at its partial anchor; the live example opens on the
/// notes, the trail log a tap away.
Widget kitSheetDemo(Brightness brightness) => KitStack(
  brightness: brightness,
  page: _page,
  initial: const <String>['/', '/trail'],
);

/// The page `/` or one of its sheets (`/trail`, `/share`, `/tinted`,
/// `/new`) stands for.
Page<void> _page(String location, LocalKey key) => switch (location) {
  '/trail' => ExpressiveSheetPage<void>(key: key, child: const _TrailLog()),
  '/share' => ExpressiveSheetPage<void>(key: key, child: const _ShareNote()),
  '/tinted' => ExpressiveSheetPage<void>(
    key: key,
    theme: _tintedTheme,
    themeListenable: _tint,
    child: const _TintedSheet(),
  ),
  '/new' => ExpressiveFullScreenDialogPage<void>(
    key: key,
    child: const _NewObservation(),
  ),
  _ => ExpressivePage<void>(key: key, child: const _Notes()),
};

/// The trail log's entries: a time, a place and what was seen.
const List<(String, String, String)> _log = <(String, String, String)>[
  ('06:12', 'Trailhead car park', 'Frost on the gate; two wrens.'),
  ('06:40', 'Beech hanger', 'Fresh badger spoil under the roots.'),
  ('07:05', 'Stream crossing', 'Dipper working the riffle.'),
  ('07:31', 'Old quarry', 'Peregrine on the north face, calling.'),
  ('07:58', 'Heath edge', 'Stonechat pair on the gorse.'),
  ('08:20', 'Dew pond', 'Palmate newts, at least six.'),
  ('08:47', 'Ridge path', 'Skylarks up all along the ridge.'),
  ('09:15', 'Trig point', 'Red kite drifting over the valley.'),
  ('09:40', 'Hazel coppice', 'A dormouse nest, woven and empty.'),
  ('10:02', 'Chalk bank', 'First early purple orchids open.'),
  ('10:26', 'Sunken lane', 'Slow-worm basking on the verge.'),
  ('10:51', 'Water meadow', 'Snipe flushed from the rushes.'),
  ('11:14', 'Mill race', 'Kingfisher, a blue streak downstream.'),
  ('11:38', 'Churchyard yews', 'Goldcrests feeding high in the yews.'),
  ('12:02', 'Back at the gate', 'Brimstone butterfly, the first this year.'),
];

/// What the back gesture does on [platform].
String _backOf(TargetPlatform platform) =>
    platform == TargetPlatform.iOS || platform == TargetPlatform.macOS
    ? 'Swipe the sheet down to dismiss it.'
    : 'The system back gesture shrinks the sheet as you swipe (predictive '
          'back); an expanded sheet settles to half height first.';

class _Notes extends StatefulWidget {
  const _Notes();

  @override
  State<_Notes> createState() => _NotesState();
}

class _NotesState extends State<_Notes> {
  String _routeChosen = 'Nothing chosen yet.';

  Future<void> _raiseSheet() async {
    final chosen = await showExpressiveBottomSheet<String>(
      context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (final (icon, label) in const <(IconData, String)>[
            (ExpressiveSymbols.map, 'Show the route on the map'),
            (ExpressiveSymbols.addAPhoto, 'Add a photo of the crossing'),
            (ExpressiveSymbols.share, 'Share the route'),
          ])
            ExpressiveListTile(
              leading: ExpressiveIcon(icon),
              title: Text(label),
              onTap: () => Navigator.of(context).pop(label),
            ),
        ],
      ),
    );
    if (!mounted) return;
    setState(
      () => _routeChosen = chosen == null ? 'Dismissed.' : 'Chose: $chosen',
    );
  }

  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;
    return KitPage(
      title: 'Field notes',
      children: <Widget>[
        kitSection(
          'Modal bottom sheet',
          children: <Widget>[
            const Text(
              'A long sheet rises to half the screen. Drag it up to expand '
              'it, down to dismiss it, or tap the scrim.',
            ),
            KitAction(
              'Open the trail log',
              onTap: () => KitStack.push(context, '/trail'),
            ),
            const Text(
              'A short sheet rests at its own height, on the bottom edge.',
            ),
            KitAction(
              'Share this note',
              onTap: () => KitStack.push(context, '/share'),
            ),
            const Text(
              'Raised from code rather than a route: the same scrim and '
              'sheet, closed with the row chosen.',
            ),
            KitAction('The route, from code', onTap: _raiseSheet),
            Text(_routeChosen),
          ],
        ),
        kitSection(
          'Standard bottom sheet',
          children: <Widget>[
            const Text(
              'The same sheet standing in a region of the page rather than '
              'over it: no scrim, dragged between half and full height.',
            ),
            const _Embedded(),
          ],
        ),
        kitSection(
          'Tinted sheet',
          children: <Widget>[
            const Text(
              'A sheet page may wear a theme of its own on the whole sheet — '
              'container, handle and content — as a player wears the colours '
              'of the playing artwork. Swap the tint and the sheet '
              'cross-fades on the effects spring.',
            ),
            KitAction(
              'Open the tinted sheet',
              onTap: () => KitStack.push(context, '/tinted'),
            ),
          ],
        ),
        kitSection(
          'Full-screen dialog',
          children: <Widget>[
            const Text(
              'A focused task that covers the screen, closed explicitly.',
            ),
            KitAction(
              'New observation',
              onTap: () => KitStack.push(context, '/new'),
            ),
          ],
        ),
        kitSection('Back', children: <Widget>[Text(_backOf(platform))]),
      ],
    );
  }
}

/// An [ExpressiveBottomSheet] in a 320dp stage of the page: the tide
/// table, resting at half the stage.
class _Embedded extends StatelessWidget {
  const _Embedded();

  static const List<(String, String)> _tides = <(String, String)>[
    ('Low water', '05:48 · 0.9 m'),
    ('High water', '11:57 · 4.6 m'),
    ('Low water', '18:10 · 1.1 m'),
    ('High water', '00:21 · 4.4 m'),
  ];

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    const margin = ExpressiveChromeMetrics.margin;
    final shape = t.shapes.large;
    // The stage is the page (its surface) inside a frame: on a grey stage
    // the sheet's lower container read as a notch, not raised (11-13).
    return SizedBox(
      height: ExpressiveSpacing.s64 * 5,
      child: ExpressiveSurface(
        shape: shape,
        color: t.colors.surface,
        child: DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: ShapeDecoration(
            shape: shape.copyWith(
              side: BorderSide(color: t.colors.outlineVariant),
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              ExpressiveBottomSheet(
                initialValue: ExpressiveSheetValue.partiallyExpanded,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(margin, 0, margin, margin),
                  children: <Widget>[
                    Text(
                      'Tide table · Mill race',
                      style: t.type.titleMedium.copyWith(
                        color: t.colors.onSurface,
                      ),
                    ),
                    for (final (tide, time) in _tides)
                      Padding(
                        padding: const EdgeInsets.only(top: margin),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                tide,
                                style: t.type.bodyLarge.copyWith(
                                  color: t.colors.onSurface,
                                ),
                              ),
                            ),
                            Text(
                              time,
                              style: t.type.bodyMedium.copyWith(
                                color: t.colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A tall sheet: its list fills the screen, so the sheet rests at half
/// height and expands under a drag.
class _TrailLog extends StatelessWidget {
  const _TrailLog();

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    const margin = ExpressiveChromeMetrics.margin;
    return ListView(
      padding: const EdgeInsets.fromLTRB(margin, 0, margin, margin),
      children: <Widget>[
        Text(
          'Trail log · 14 March',
          style: t.type.titleLarge.copyWith(color: t.colors.onSurface),
        ),
        Text(
          '${_log.length} sightings on the ridge loop',
          style: t.type.bodyMedium.copyWith(color: t.colors.onSurfaceVariant),
        ),
        for (final (time, place, seen) in _log)
          Padding(
            padding: const EdgeInsets.only(top: margin),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(
                  width: ExpressiveSpacing.s56,
                  child: Text(
                    time,
                    style: t.type.labelLarge.copyWith(color: t.colors.primary),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        place,
                        style: t.type.bodyLarge.copyWith(
                          color: t.colors.onSurface,
                        ),
                      ),
                      Text(
                        seen,
                        style: t.type.bodyMedium.copyWith(
                          color: t.colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// How far the tinted sheet has faded from slate's colours to bloom's.
final ValueNotifier<double> _tint = ValueNotifier<double>(0);

/// The tinted sheet's theme: the navigator's, its colours [_tint] of the
/// way from slate's to bloom's (`ExpressiveColorScheme.lerp`).
ExpressiveThemeData _tintedTheme(BuildContext context) {
  final theme = context.expressiveTheme;
  ExpressiveColorScheme colors(String preset) =>
      ExpressiveThemeData.preset(preset, theme.brightness).colors;
  return theme.copyWith(
    colors: ExpressiveColorScheme.lerp(
      colors('slate'),
      colors('bloom'),
      _tint.value,
    ),
  );
}

/// A sheet that wears [_tintedTheme] on its whole surface, and springs
/// [_tint] between its two ends.
class _TintedSheet extends StatefulWidget {
  const _TintedSheet();

  @override
  State<_TintedSheet> createState() => _TintedSheetState();
}

class _TintedSheetState extends State<_TintedSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fade = AnimationController.unbounded(
    vsync: this,
    value: _tint.value,
  )..addListener(() => _tint.value = _fade.value);

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  void _swap() => _fade.springTo(
    _fade.value < 0.5 ? 1 : 0,
    ExpressiveMotion.of(context).spring(ExpressiveMotionKey.defaultEffects),
  );

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    const margin = ExpressiveChromeMetrics.margin;
    return Padding(
      padding: const EdgeInsets.fromLTRB(margin, 0, margin, margin),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const ExpressiveText.title('Dawn chorus · Beech hanger'),
          const SizedBox(height: ExpressiveSpacing.s4),
          Text(
            'Recorded 05:52, 14 minutes',
            style: t.type.bodyMedium.copyWith(color: t.colors.onSurfaceVariant),
          ),
          const SizedBox(height: ExpressiveSpacing.s16),
          ExpressiveFilledButton.tonal('Swap the tint', onPressed: _swap),
        ],
      ),
    );
  }
}

/// The ways to share a note.
const List<(IconData, String)> _shareActions = <(IconData, String)>[
  (ExpressiveSymbols.link, 'Copy link'),
  (ExpressiveSymbols.group, 'Send to the survey group'),
  (ExpressiveSymbols.description, 'Export as a PDF'),
];

/// A short sheet resting at its own height: the note's title and its share
/// actions as list rows (Material's action sheet is a bottom sheet of list
/// items); choosing one closes the sheet.
class _ShareNote extends StatelessWidget {
  const _ShareNote();

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(
            ExpressiveSpacing.s24,
            ExpressiveSpacing.s8,
            ExpressiveSpacing.s24,
            ExpressiveSpacing.s8,
          ),
          child: Text(
            'Share “Dipper at the stream crossing”',
            style: t.type.titleMedium.copyWith(color: t.colors.onSurface),
          ),
        ),
        for (final (icon, label) in _shareActions)
          ExpressiveListTile(
            leading: ExpressiveIcon(icon),
            title: Text(label),
            onTap: () => Navigator.of(context).pop(),
          ),
        const SizedBox(height: ExpressiveSpacing.s8),
      ],
    );
  }
}

/// A full-screen dialog's page: its own close and save (the screen family
/// derives these once it lands) over the task.
class _NewObservation extends StatelessWidget {
  const _NewObservation();

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    const margin = ExpressiveChromeMetrics.margin;
    Widget field(String label, String value) => Padding(
      padding: const EdgeInsets.only(top: margin),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: t.type.labelMedium.copyWith(color: t.colors.primary),
          ),
          Text(
            value,
            style: t.type.bodyLarge.copyWith(color: t.colors.onSurface),
          ),
        ],
      ),
    );
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Semantics(
                button: true,
                label: 'Close',
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.of(context).pop(),
                  child: SizedBox.square(
                    dimension: ExpressiveSpacing.s48,
                    child: Icon(
                      ExpressiveSymbols.close,
                      color: t.colors.onSurface,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'New observation',
                  style: t.type.titleLarge.copyWith(color: t.colors.onSurface),
                ),
              ),
              Semantics(
                button: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.of(context).pop(),
                  child: Padding(
                    padding: const EdgeInsets.all(margin),
                    child: Text(
                      'Save',
                      style: t.type.labelLarge.copyWith(
                        color: t.colors.primary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(margin, 0, margin, margin),
              children: <Widget>[
                field('Species', 'Grey wagtail'),
                field('Where', 'Mill race, below the weir'),
                field('When', 'Today, 11:20'),
                field('Count', '2 — a pair, carrying food'),
                field(
                  'Notes',
                  'Feeding young under the footbridge; nest in the wall.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Catalog specimens (docs/architecture/component-catalog.md).

/// A sheet resting half open over the page, a tide table on it.
Widget kitSpecimenBottomSheetTides() => Builder(
  builder: (context) {
    final t = context.expressiveTheme;
    const margin = ExpressiveChromeMetrics.margin;
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        ColoredBox(color: t.colors.surfaceContainerHighest),
        ExpressiveBottomSheet(
          initialValue: ExpressiveSheetValue.partiallyExpanded,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(margin, 0, margin, margin),
            children: <Widget>[
              Text(
                'Tide table · Mill race',
                style: t.type.titleMedium.copyWith(color: t.colors.onSurface),
              ),
              for (final (tide, time) in const <(String, String)>[
                ('Low water', '05:48 · 0.9 m'),
                ('High water', '11:57 · 4.6 m'),
                ('Low water', '18:10 · 1.1 m'),
              ])
                ExpressiveListTile(title: Text(tide), subtitle: Text(time)),
            ],
          ),
        ),
      ],
    );
  },
);
