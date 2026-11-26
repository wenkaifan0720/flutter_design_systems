/// Terminal's foundations: its six palettes ([TermThemeData.preset]), the
/// sixteen colours of the night and paper palettes ([TermPalette]) and the roles [TermThemeData] draws from them,
/// the cell grid ([TermGrid]) every size is counted in, the faces
/// ([termFontFamily], [termFallbackFontFamily]), and a part's own overrides
/// ([TermStyle]).
library;

import 'package:material_ui/material_ui.dart';
import 'package:terminal_ui/terminal_ui.dart';

import '../kit.dart';

Widget kitFoundationsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'foundations',
  sections: [
    kitSection('six palettes', children: [const _Presets()]),
    kitSection('palette', children: [const _Palette()]),
    kitSection('roles', children: [const _Roles()]),
    kitSection('the grid', children: [const _Grid()]),
    kitSection('type', children: [const _Type()]),
    kitSection('a part of your own', children: [const _Styled()]),
  ],
);

/// Terminal's six palettes ([TermThemeData.preset]), each by night and by
/// day: a prompt in its words, the cursor in its accent and its four tones
/// (one, in a palette of one ink).
class _Presets extends StatelessWidget {
  const _Presets();

  static const Map<String, String> _about = {
    'standard': 'night and paper, a cyan accent',
    'harbor': 'a navy screen, a blue accent',
    'dusk': 'a plum screen, a magenta accent',
    'mono': 'one ink: states by shape alone',
    'phosphor': 'one green ink, as a P1 tube',
    'amber': 'one amber ink, as a P3 tube',
  };

  @override
  Widget build(BuildContext context) {
    final theme = TermTheme.of(context);
    final grid = context.termGrid;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final id in TermThemeData.presets) ...[
          Text(id, style: theme.boldStyle),
          Text(_about[id] ?? '', style: theme.dimStyle),
          // A palette's night and day together, a line before the next.
          Wrap(
            spacing: grid.cellWidth,
            children: [for (final b in Brightness.values) _PresetTile(id, b)],
          ),
          SizedBox(height: grid.lineHeight),
        ],
      ],
    );
  }
}

/// One palette in one appearance.
class _PresetTile extends StatelessWidget {
  const _PresetTile(this.id, this.brightness);

  final String id;
  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    final grid = context.termGrid;
    final t = TermThemeData.preset(id, brightness);
    final night = brightness == Brightness.dark;
    Widget swatch(Color c) => Container(
      width: grid.cols(2),
      height: grid.fontSize,
      margin: EdgeInsetsDirectional.only(end: grid.cellWidth),
      color: c,
    );
    return Semantics(
      label: '$id, ${night ? 'night' : 'day'}',
      container: true,
      excludeSemantics: true,
      child: Container(
        width: grid.cols(22),
        padding: EdgeInsets.symmetric(
          horizontal: grid.cellWidth,
          vertical: grid.lineHeight / 4,
        ),
        decoration: BoxDecoration(
          color: t.background,
          border: Border.all(color: t.rule),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: '${night ? 'night' : 'day'} \$ '),
                  // The cursor, in the accent.
                  TextSpan(
                    text: '\u{2588}',
                    style: TextStyle(color: t.accent),
                  ),
                ],
              ),
              style: t.textStyle.copyWith(color: t.foreground),
            ),
            Row(
              children: [
                // A palette of one ink has one tone.
                for (final c in {t.accent, t.success, t.warning, t.danger})
                  swatch(c),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Palette extends StatelessWidget {
  const _Palette();

  @override
  Widget build(BuildContext context) {
    final theme = TermTheme.of(context);
    final grid = context.termGrid;
    const names = [
      'black',
      'red',
      'green',
      'yellow',
      'blue',
      'magenta',
      'cyan',
      'white',
      'bright black',
      'bright red',
      'bright green',
      'bright yellow',
      'bright blue',
      'bright magenta',
      'bright cyan',
      'bright white',
    ];
    final TermPalette palette = theme.palette;
    return Wrap(
      spacing: grid.cols(3),
      runSpacing: 0,
      children: [
        for (var i = 0; i < 16; i++)
          SizedBox(
            // The swatch, a gap and the longest name, "15 bright magenta".
            width: grid.cols(21),
            child: Row(
              children: [
                ExcludeSemantics(
                  // Framed in the rule, so black on the night's ground and
                  // white on the day's still show.
                  child: Container(
                    width: grid.cols(3),
                    height: grid.fontSize,
                    decoration: BoxDecoration(
                      color: palette.ansi[i],
                      border: Border.all(color: theme.rule),
                    ),
                  ),
                ),
                SizedBox(width: grid.cellWidth),
                Expanded(
                  child: Text(
                    '${i.toString().padLeft(2)} ${names[i]}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Roles extends StatelessWidget {
  const _Roles();

  @override
  Widget build(BuildContext context) {
    final TermThemeData theme = TermTheme.of(context);
    final roles = [
      ('foreground', theme.foreground, 'the words'),
      ('dim', theme.dim, 'what is said about them'),
      ('rule', theme.rule, 'frames and rules, 3:1 on the ground'),
      ('accent', theme.accent, 'focus, the one primary action'),
      ('success', theme.success, '✓ passed'),
      ('danger', theme.danger, '✗ failed, destroy'),
      ('warning', theme.warning, '! look at it'),
      ('info', theme.info, 'i worth knowing'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (name, color, use) in roles)
          Row(
            children: [
              SizedBox(
                width: context.termGrid.cols(12),
                child: Text(
                  name,
                  style: theme.textStyle.copyWith(color: color),
                ),
              ),
              Expanded(child: Text(use, style: theme.dimStyle)),
            ],
          ),
      ],
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid();

  @override
  Widget build(BuildContext context) {
    final TermGrid grid = context.termGrid;
    final theme = TermTheme.of(context);
    return TermPane(
      title:
          '${grid.cellWidth.toStringAsFixed(0)} × ${grid.lineHeight.toStringAsFixed(0)} cells',
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: grid.lineHeight),
        child: Text(
          'every width is whole cells, every height whole lines.\n'
          'a target is one line under a pointer, two under a finger.\n'
          'the text grows the grid: at 200% a cell is twice the size.',
          style: theme.textStyle,
        ),
      ),
    );
  }
}

class _Type extends StatelessWidget {
  const _Type();

  @override
  Widget build(BuildContext context) {
    final theme = TermTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('slipway', style: theme.displayStyle),
        Text('$termFontFamily, the words', style: theme.textStyle),
        Text('bold, a title', style: theme.boldStyle),
        Text('dim, what is said about it', style: theme.dimStyle),
        Text('עברית: $termFallbackFontFamily', style: theme.textStyle),
      ],
    );
  }
}

class _Styled extends StatelessWidget {
  const _Styled();

  @override
  Widget build(BuildContext context) {
    final theme = TermTheme.of(context);
    return kitRow([
      TermButton(
        label: 'magenta',
        onPressed: () {},
        style: TermStyle(edge: WidgetStatePropertyAll(theme.palette.magenta)),
      ),
      TermButton.filled(
        label: 'green',
        onPressed: () {},
        style: TermStyle(fill: WidgetStatePropertyAll(theme.palette.green)),
      ),
    ]);
  }
}
