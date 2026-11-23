/// Make it yours, without leaving the look: a brand colour pulled to
/// 4.5:1, every primary button restyled from the theme, one button
/// restyled on its own, the box lines heavy, and a part of your own drawn
/// with Terminal's primitives (`TermFramePainter`, `TermBracketFace`,
/// `TermCellFace`, `TermMenuRow`).
library;

import 'package:material_ui/material_ui.dart';
import 'package:terminal_ui/terminal_ui.dart';

import '../kit.dart';

Widget kitPrimitivesDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'make it yours',
  sections: [
    kitSection(
      'a brand colour, held to 4.5:1',
      children: [
        Builder(
          builder: (context) {
            final base = TermTheme.of(context);
            // A brand's green, pulled until it reads on the background.
            final brand = termReadable(
              const Color(0xFF0A7D4F),
              on: base.palette.background,
            );
            final data = base.brightness == Brightness.dark
                ? TermThemeData.dark(accent: brand)
                : TermThemeData.light(accent: brand);
            return TermTheme(data: data, child: const _Sample());
          },
        ),
      ],
    ),
    kitSection(
      'every primary button',
      children: [
        Builder(
          builder: (context) {
            final base = TermTheme.of(context);
            final magenta = TermAnsi.magenta.of(base.palette);
            return TermTheme(
              data: base.copyWith(
                filledButtonStyle: TermStyle(
                  fill: WidgetStatePropertyAll(magenta),
                  edge: WidgetStatePropertyAll(magenta),
                ),
              ),
              child: const _Sample(),
            );
          },
        ),
      ],
    ),
    kitSection(
      'one button',
      children: [
        Builder(
          builder: (context) {
            final theme = TermTheme.of(context);
            return kitRow([
              TermButton(label: 'deploy', onPressed: () {}),
              TermButton(
                label: 'roll back',
                onPressed: () {},
                style: TermStyle(
                  foreground: WidgetStatePropertyAll(theme.warning),
                  edge: WidgetStatePropertyAll(theme.warning),
                ),
              ),
            ]);
          },
        ),
      ],
    ),
    kitSection(
      'the box lines heavy',
      children: [
        Builder(
          builder: (context) => TermTheme(
            data: TermTheme.of(context).copyWith(stroke: TermStroke.heavy),
            child: const _Sample(),
          ),
        ),
      ],
    ),
    kitSection('a part of your own', children: const [_Own()]),
  ],
);

/// A pane, a filled button, a bracketed one, a chip and a bar: enough of
/// the look to see a setting land.
class _Sample extends StatelessWidget {
  const _Sample();

  @override
  Widget build(BuildContext context) => TermPane(
    title: 'atlas-api',
    trailing: '✓ healthy',
    child: Builder(
      builder: (context) {
        final grid = context.termGrid;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: grid.lineHeight / 2),
            kitRow([
              TermButton(label: 'logs', onPressed: () {}),
              TermButton.filled(label: 'deploy', onPressed: () {}),
              TermChip(label: 'failed', selected: true, onSelected: (_) {}),
            ]),
            SizedBox(height: grid.lineHeight / 2),
            const TermProgressBar(value: 0.62, semanticLabel: 'deploying'),
          ],
        );
      },
    ),
  );
}

/// A deploy target's card, drawn with the primitives: a box-drawn frame
/// with its name cut into the top line, a choice of cells and a
/// bracketed action, all on the grid.
class _Own extends StatelessWidget {
  const _Own();

  @override
  Widget build(BuildContext context) {
    final theme = TermTheme.of(context);
    final grid = context.termGrid;
    const name = 'eu-west';
    final at = grid.cellWidth * 2;
    return CustomPaint(
      painter: TermFramePainter(
        grid: grid,
        color: theme.accent,
        stroke: termStrokeWidth(theme, grid),
        textDirection: Directionality.of(context),
        topGaps: [
          (
            start: at - grid.cellWidth / 2,
            end: at + grid.widthOf(name) + grid.cellWidth / 2,
          ),
        ],
      ),
      child: Stack(
        children: [
          PositionedDirectional(
            top: 0,
            start: at,
            child: Text(name, style: theme.boldStyle),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              grid.cols(2),
              grid.lines(1.5),
              grid.cols(2),
              grid.lines(1),
            ),
            child: Wrap(
              spacing: grid.cellWidth,
              runSpacing: grid.lineHeight / 2,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: const [
                TermCellFace(
                  label: '2 replicas',
                  on: true,
                  enabled: true,
                  press: 0,
                  focus: 0,
                ),
                TermCellFace(
                  label: '4',
                  on: false,
                  enabled: true,
                  press: 0,
                  focus: 0,
                ),
                TermBracketFace(
                  label: 'scale',
                  enabled: true,
                  press: 0,
                  focus: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
