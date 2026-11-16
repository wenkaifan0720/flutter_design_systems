/// The Overview: the pitch. The look at its best (a live slipway pane), one
/// sentence on what it is, slipway's screens to open, what the package
/// holds, and then the parts.
library;

import 'package:flutter/material.dart';
import 'package:terminal_ui/terminal_ui.dart';

import 'kit.dart';
import 'slipway.dart';
import 'slipway_pages.dart';

/// A part's page in the index: its id and its title.
typedef OverviewPart = ({String id, String title});

/// The Overview, in [brightness]; [onBrightness] flips night and paper,
/// [parts] and [onOpenPart] list and open the parts' pages.
class OverviewPage extends StatelessWidget {
  /// The pitch.
  const OverviewPage({
    super.key,
    this.onBrightness,
    this.parts = const [],
    this.onOpenPart,
  });

  /// Called to show the other preset; null: no switch.
  final VoidCallback? onBrightness;

  /// The parts' pages.
  final List<OverviewPart> parts;

  /// Opens a part's page.
  final ValueChanged<String>? onOpenPart;

  // An ordinary app's push: Flutter's own MaterialPageRoute, which reads the
  // app's theme (kitApp's), so it changes screens as Terminal does.
  void _study(BuildContext context, SlipwayPlace place) => Navigator.of(context)
      .push(
        MaterialPageRoute<void>(
          builder: (route) => SlipwayShell(
            place: place,
            onExit: () => Navigator.of(route).pop(),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final theme = TermTheme.of(context);
    final grid = context.termGrid;
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final dark = theme.brightness == Brightness.dark;

    final head = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(r'$ ', style: theme.displayStyle.copyWith(color: theme.dim)),
            Flexible(
              child: Semantics(
                header: true,
                child: Text('terminal_ui', style: theme.displayStyle),
              ),
            ),
            const TermCaret(),
          ],
        ),
        SizedBox(height: grid.lineHeight),
        const Text(
          'Flutter widgets drawn the way a well-made terminal program draws '
          'itself: every size whole character cells, panes in box-drawing '
          'lines, buttons in brackets, the chosen row in inverse video, and '
          'the key for every action written beside it.',
        ),
      ],
    );

    final live = TermPane.list(
      title: 'slipway · runs',
      trailing: 'live',
      footer: termKeysShown(context) ? '⏎ open · M-2 runs' : null,
      children: [
        for (final run in slipwayRuns.take(4))
          runTile(
            run,
            selected: run.number == 1481,
            onTap: () => _study(context, SlipwayPlace.run),
          ),
        Padding(
          padding: EdgeInsetsDirectional.only(
            start: grid.cellWidth,
            end: grid.cellWidth,
            top: grid.lineHeight,
            bottom: grid.lineHeight,
          ),
          child: LayoutBuilder(
            builder: (context, c) => TermProgressBar(
              value: 0.62,
              cols: (grid.colsIn(c.maxWidth) - 5).clamp(8, 48),
              semanticLabel: 'run 1482',
            ),
          ),
        ),
      ],
    );

    final studies = TermPane.list(
      title: 'the example app',
      trailing: '10 screens',
      children: [
        for (final (place, name, what) in const [
          (SlipwayPlace.home, 'home', 'projects and their last runs'),
          (SlipwayPlace.runs, 'runs', 'filters, a list; tiled at a desk'),
          (SlipwayPlace.run, 'a run', 'steps and a searchable log'),
          (SlipwayPlace.deploy, 'new deploy', 'a form, then y/N'),
          (SlipwayPlace.settings, 'config', 'settings as the file they are'),
          (SlipwayPlace.palette, 'commands', '^K: type a few letters, ⏎'),
          (SlipwayPlace.diff, 'a change', 'before and after, side by side'),
          (SlipwayPlace.search, 'no match', 'a search with nothing, offline'),
          (SlipwayPlace.confirm, 'delete', 'type the name to confirm'),
          (SlipwayPlace.desk, 'the desk', 'tiled panes; [ and ] switch'),
        ])
          TermListTile(
            leading: const ExcludeSemantics(child: Text('▸')),
            title: Text(name),
            subtitle: Text(what),
            onTap: () => _study(context, place),
          ),
      ],
    );

    Widget fact(String key, String value) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: grid.cols(9),
          child: Text(key, style: theme.boldStyle),
        ),
        Expanded(child: Text(value)),
      ],
    );
    final inside = TermPane(
      title: "what's inside",
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: grid.lineHeight),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            fact(
              'parts',
              'buttons, fields, selects, choices, rows, panes, tabs, navigation, dialogs, toasts, progress',
            ),
            fact('sizes', 'whole cells: 9 × 24 at 15 px, grown with the text'),
            fact(
              'themes',
              'night and paper, sixteen colours each; a monochrome one',
            ),
            fact(
              'access',
              'a line for a pointer, two for a finger; every glyph named for a screen reader; Reduce Motion stills the spinners',
            ),
            fact('keys', 'every action can show its key'),
          ],
        ),
      ),
    );

    final index = parts.isEmpty
        ? null
        : TermPane.list(
            title: 'parts',
            trailing: '${parts.length}',
            children: [
              for (final p in parts)
                TermListTile(
                  // Lower case, as every word on a terminal's screen is.
                  title: Text(p.title.toLowerCase()),
                  onTap: onOpenPart == null ? null : () => onOpenPart!(p.id),
                ),
            ],
          );

    final columns = wide
        ? [
            CellColumns(
              start: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  head,
                  SizedBox(height: grid.lineHeight),
                  studies,
                ],
              ),
              end: live,
            ),
            if (index == null)
              inside
            else
              CellColumns(start: inside, end: index),
          ]
        : [head, live, studies, inside, ?index];

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TermTopBar(
            title: 'terminal_ui',
            subtitle: 'overview',
            actions: [
              if (onBrightness != null)
                TermButton(
                  label: dark ? 'paper' : 'night',
                  onPressed: onBrightness,
                ),
            ],
          ),
          // A desk's whole window, as a terminal program fills its own.
          Expanded(child: PageScroll(cols: 160, children: columns)),
        ],
      ),
    );
  }
}

/// The Overview as a gallery page.
Widget overviewApp(Brightness brightness) =>
    kitApp(brightness: brightness, home: const OverviewPage());
