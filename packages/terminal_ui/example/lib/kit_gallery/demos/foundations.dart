/// Terminal's foundations: the sixteen colours of the night and paper
/// palettes ([TermPalette]) and the roles [TermThemeData] draws from them,
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
    kitSection('palette', children: [const _Palette()]),
    kitSection('roles', children: [const _Roles()]),
    kitSection('the grid', children: [const _Grid()]),
    kitSection('type', children: [const _Type()]),
    kitSection('a part of your own', children: [const _Styled()]),
  ],
);

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
      spacing: grid.cellWidth,
      runSpacing: 0,
      children: [
        for (var i = 0; i < 16; i++)
          SizedBox(
            width: grid.cols(18),
            child: Row(
              children: [
                ExcludeSemantics(
                  child: Container(
                    width: grid.cols(3),
                    height: grid.fontSize,
                    color: palette.ansi[i],
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
