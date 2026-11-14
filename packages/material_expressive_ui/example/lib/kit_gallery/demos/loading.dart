/// The loading group's demo: the loading indicator plain and contained,
/// determinate at a few values, pull-to-refresh on a live inbox, and the
/// page's loading state.
library;

import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

import '../kit.dart';

/// The loading group's demo, in [brightness].
Widget kitLoadingDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Loading indicator',
  sections: const <Widget>[
    _Indicators(),
    SizedBox(height: kitGap * 3),
    _Determinate(),
    SizedBox(height: kitGap * 3),
    _Refresh(),
    SizedBox(height: kitGap * 3),
    _State(),
  ],
);

/// [child] over a label.
Widget _labelled(BuildContext context, Widget child, String label) {
  final t = context.expressiveTheme;
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      child,
      const SizedBox(height: kitGap),
      Text(
        label,
        style: t.type.labelMedium.copyWith(color: t.colors.onSurfaceVariant),
      ),
    ],
  );
}

class _Indicators extends StatelessWidget {
  const _Indicators();

  @override
  Widget build(BuildContext context) => kitSection(
    'Indeterminate',
    children: <Widget>[
      Wrap(
        spacing: kitGap * 4,
        runSpacing: kitGap * 2,
        children: <Widget>[
          _labelled(
            context,
            const ExpressiveLoadingIndicator(semanticLabel: 'Loading'),
            'Plain',
          ),
          _labelled(
            context,
            const ExpressiveLoadingIndicator(
              contained: true,
              semanticLabel: 'Loading',
            ),
            'Contained',
          ),
        ],
      ),
    ],
  );
}

class _Determinate extends StatelessWidget {
  const _Determinate();

  @override
  Widget build(BuildContext context) => kitSection(
    'Determinate',
    children: <Widget>[
      Wrap(
        spacing: kitGap * 3,
        runSpacing: kitGap * 2,
        children: <Widget>[
          for (final value in const <double>[0, 0.3, 0.6, 1])
            _labelled(
              context,
              ExpressiveLoadingIndicator(progress: value, contained: true),
              '${(value * 100).round()}%',
            ),
        ],
      ),
    ],
  );
}

/// A live inbox: pull it down, or tap Refresh, and a message arrives.
class _Refresh extends StatefulWidget {
  const _Refresh();

  @override
  State<_Refresh> createState() => _RefreshState();
}

class _RefreshState extends State<_Refresh> {
  final GlobalKey<ExpressivePullToRefreshState> _pull =
      GlobalKey<ExpressivePullToRefreshState>();
  static const List<(String, String)> _incoming = <(String, String)>[
    ('Maya', 'Trail map for Saturday attached'),
    ('Book club', 'Next pick: The Overstory'),
    ('Theo', 'Can you water the tomatoes?'),
    ('Studio', 'Your prints are ready'),
  ];
  final List<(String, String)> _messages = <(String, String)>[
    ('Grandma', 'Recipe for the plum cake'),
    ('Nils', 'Photos from the ferry'),
    ('Running club', 'Tuesday loop moved to 7 pm'),
    ('Ana', 'Thanks for the lift!'),
    ('Library', 'Two books due Friday'),
  ];
  int _next = 0;

  Future<void> _refresh() async {
    await Future<void>.delayed(const Duration(milliseconds: 1600));
    if (!mounted) return;
    setState(() {
      _messages.insert(0, _incoming[_next % _incoming.length]);
      _next += 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    return kitSection(
      'Pull to refresh',
      children: <Widget>[
        SizedBox(
          height: kitGap * 36,
          child: ClipPath(
            clipper: ShapeBorderClipper(shape: t.shapes.large),
            child: ColoredBox(
              color: t.colors.surfaceContainerLow,
              child: ExpressiveRefreshIndicator(
                key: _pull,
                onRefresh: _refresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: kitGap),
                  children: <Widget>[
                    for (final (from, subject) in _messages)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: kitGap * 2,
                          vertical: kitGap,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              from,
                              style: t.type.titleSmall.copyWith(
                                color: t.colors.onSurface,
                              ),
                            ),
                            Text(
                              subject,
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
            ),
          ),
        ),
        const SizedBox(height: kitGap),
        Wrap(
          children: <Widget>[
            ExpressiveFilledButton.tonal(
              'Refresh',
              icon: ExpressiveSymbols.refresh,
              onPressed: () => _pull.currentState?.show(),
            ),
          ],
        ),
      ],
    );
  }
}

class _State extends StatelessWidget {
  const _State();

  @override
  Widget build(BuildContext context) => kitSection(
    'Page loading state',
    children: const <Widget>[
      ExpressiveLoadingState(message: 'Loading your garden'),
    ],
  );
}

// Catalog specimens (docs/architecture/component-catalog.md).

/// The loading indicator, plain and contained.
Widget kitSpecimenLoadingIndicatorPair() => const Row(
  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  children: <Widget>[
    ExpressiveLoadingIndicator(semanticLabel: 'Loading'),
    ExpressiveLoadingIndicator(contained: true, semanticLabel: 'Loading'),
  ],
);
