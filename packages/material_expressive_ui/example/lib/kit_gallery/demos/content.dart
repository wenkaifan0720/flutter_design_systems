/// The content group's demo: text in the 30 type styles, Material Symbols
/// icons in both fills and four sizes, the stat and its counter, amounts,
/// keyboard keys, a timeline, a description list, the rating, the bar and
/// line chart, and a message thread — with one hero moment (emphasized
/// headline and a lead number).
library;

import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

import '../kit.dart';

/// The content group's demo, in [brightness].
Widget kitContentDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Content',
  sections: const <Widget>[
    _TypeScale(),
    _Emphasis(),
    _Icons(),
    _Stats(),
    _Amounts(),
    _Timeline(),
    _Details(),
    _Ratings(),
    _Charts(),
    _Thread(),
  ],
);

class _TypeScale extends StatelessWidget {
  const _TypeScale();

  static String _name(ExpressiveTextRole role, ExpressiveTextSize size) {
    final r = role.name;
    return '${r[0].toUpperCase()}${r.substring(1)} ${size.name}';
  }

  @override
  Widget build(BuildContext context) => kitSection(
    'Text · the type scale',
    children: <Widget>[
      for (final role in ExpressiveTextRole.values)
        for (final size in ExpressiveTextSize.values)
          ExpressiveText(_name(role, size), role: role, size: size),
    ],
  );
}

class _Emphasis extends StatelessWidget {
  const _Emphasis();

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    return kitSection(
      'Text · emphasized',
      children: <Widget>[
        const ExpressiveText.title(
          'Unread: Tide tables for May',
          emphasized: true,
        ),
        const ExpressiveText.body(
          'Selected: Harbour walk, 6 km',
          emphasized: true,
        ),
        const ExpressiveText.label('PRIMARY LABEL', emphasized: true),
        ExpressiveHeroMoment(
          label: 'weekly summary',
          child: ExpressiveSurface(
            shape: t.shapes.extraLarge,
            color: t.colors.primaryContainer,
            contentColor: t.colors.onPrimaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(ExpressiveSpacing.s24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: ExpressiveSpacing.s12,
                children: <Widget>[
                  ExpressiveText.headline(
                    'Your best reading week yet',
                    emphasized: true,
                    color: t.colors.onPrimaryContainer,
                  ),
                  const ExpressiveStat(
                    label: 'Minutes read',
                    value: 318,
                    size: ExpressiveStatSize.large,
                    emphasized: true,
                    supporting: '+64 on last week',
                    trend: ExpressiveTrend.up,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Icons extends StatefulWidget {
  const _Icons();

  @override
  State<_Icons> createState() => _IconsState();
}

class _IconsState extends State<_Icons> {
  final Set<int> _on = <int>{1};

  static const List<(IconData, String)> _glyphs = <(IconData, String)>[
    (ExpressiveSymbols.favorite, 'Favourite'),
    (ExpressiveSymbols.bookmark, 'Save'),
    (ExpressiveSymbols.star, 'Star'),
    (ExpressiveSymbols.home, 'Home'),
    (ExpressiveSymbols.person, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    return kitSection(
      'Icon · outlined, filled (tap to toggle) · s m l xl',
      children: <Widget>[
        Wrap(
          spacing: ExpressiveSpacing.s4,
          children: <Widget>[
            for (var i = 0; i < _glyphs.length; i++)
              ExpressivePressable(
                shapes: ExpressivePressShapes.all(t.shapes.full),
                motion: ExpressiveMotionKey.fastSpatial,
                color: t.colors.surface,
                contentColor: t.colors.onSurfaceVariant,
                role: ExpressivePressRole.toggle,
                selected: _on.contains(i),
                semanticLabel: _glyphs[i].$2,
                onPressed: () => setState(
                  () => _on.contains(i) ? _on.remove(i) : _on.add(i),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(ExpressiveSpacing.s8),
                  child: ExpressiveIcon(
                    _glyphs[i].$1,
                    selected: _on.contains(i),
                    color: _on.contains(i)
                        ? t.colors.primary
                        : t.colors.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
        Wrap(
          spacing: ExpressiveSpacing.s16,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            for (final size in ExpressiveIconSize.values)
              ExpressiveIcon(
                ExpressiveSymbols.eco,
                size: size.dimension,
                opticalSize: size.dimension,
              ),
            for (final size in ExpressiveIconSize.values)
              ExpressiveIcon(
                ExpressiveSymbols.eco,
                size: size.dimension,
                opticalSize: size.dimension,
                selected: true,
                color: t.colors.tertiary,
              ),
          ],
        ),
      ],
    );
  }
}

class _Stats extends StatefulWidget {
  const _Stats();

  @override
  State<_Stats> createState() => _StatsState();
}

class _StatsState extends State<_Stats> {
  int _pages = 42;

  @override
  Widget build(BuildContext context) => kitSection(
    'Stat · s m · counts on a spring',
    children: <Widget>[
      Wrap(
        spacing: ExpressiveSpacing.s24,
        runSpacing: ExpressiveSpacing.s16,
        children: <Widget>[
          ExpressiveStat(
            label: 'Pages this week',
            value: _pages,
            icon: ExpressiveSymbols.book,
            supporting: '+${_pages - 36} on last week',
            trend: ExpressiveTrend.up,
          ),
          const ExpressiveStat(
            label: 'Streak',
            value: 12,
            icon: ExpressiveSymbols.bolt,
            format: _days,
            supporting: 'Same as your best',
            trend: ExpressiveTrend.flat,
          ),
          const ExpressiveStat(
            label: 'Avg. session',
            value: 18.5,
            icon: ExpressiveSymbols.timer,
            fractionDigits: 1,
            size: ExpressiveStatSize.small,
            supporting: '−2.5 min',
            trend: ExpressiveTrend.down,
          ),
        ],
      ),
      KitAction('Log 7 pages', onTap: () => setState(() => _pages += 7)),
    ],
  );
}

String _days(num value) => '${value.round()} days';

class _Ratings extends StatefulWidget {
  const _Ratings();

  @override
  State<_Ratings> createState() => _RatingsState();
}

class _RatingsState extends State<_Ratings> {
  int _mine = 3;

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    return kitSection(
      'Rating · display s m · input l',
      children: <Widget>[
        Wrap(
          spacing: ExpressiveSpacing.s8,
          runSpacing: ExpressiveSpacing.s8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            const ExpressiveRating(
              value: 4.5,
              size: ExpressiveRatingSize.small,
            ),
            Text(
              '4.5 · 212 reviews',
              style: t.type.bodyMedium.copyWith(
                color: t.colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const ExpressiveRating(value: 3),
        ExpressiveRating(
          value: _mine.toDouble(),
          size: ExpressiveRatingSize.large,
          onChanged: (stars) => setState(() => _mine = stars),
        ),
      ],
    );
  }
}

class _Charts extends StatefulWidget {
  const _Charts();

  @override
  State<_Charts> createState() => _ChartsState();
}

class _ChartsState extends State<_Charts> {
  bool _lastWeek = false;

  static const List<String> _days = <String>['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const List<double> _thisWeek = <double>[22, 35, 18, 41, 30, 64, 48];
  static const List<double> _before = <double>[30, 12, 26, 20, 44, 38, 52];
  static const List<double> _mood = <double>[
    3,
    4,
    3.5,
    2.5,
    3,
    4,
    4.5,
    4,
    3.5,
    4,
    4.5,
    5,
    4.5,
    4,
  ];

  @override
  Widget build(BuildContext context) {
    final week = _lastWeek ? _before : _thisWeek;
    return kitSection(
      'Bar and area chart · values spring',
      children: <Widget>[
        ExpressiveBarChart(
          points: <ExpressiveChartPoint>[
            for (var i = 0; i < _days.length; i++)
              ExpressiveChartPoint(_days[i], week[i]),
          ],
          highlight: _lastWeek ? null : 5,
          semanticLabel: 'Minutes read each day',
        ),
        KitAction(
          _lastWeek ? 'Show this week' : 'Show last week',
          onTap: () => setState(() => _lastWeek = !_lastWeek),
        ),
        ExpressiveAreaChart(
          points: <ExpressiveChartPoint>[
            for (var i = 0; i < _mood.length; i++)
              ExpressiveChartPoint('${i + 1}', _mood[i]),
          ],
          highlight: 11,
          aspectRatio: 3,
          semanticLabel: 'Mood over two weeks',
        ),
      ],
    );
  }
}

class _Thread extends StatelessWidget {
  const _Thread();

  @override
  Widget build(BuildContext context) => kitSection(
    'Message bubble · incoming, outgoing · grouped',
    children: const <Widget>[
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ExpressiveMessageBubble(
            text: 'Are we still on for the tide pools?',
            side: ExpressiveMessageSide.incoming,
            position: ExpressiveMessagePosition.first,
            author: 'Noor',
          ),
          ExpressiveMessageBubble(
            text: 'Low tide is at 7:10',
            side: ExpressiveMessageSide.incoming,
            position: ExpressiveMessagePosition.middle,
          ),
          ExpressiveMessageBubble(
            text: 'I’ll bring the flask',
            side: ExpressiveMessageSide.incoming,
            position: ExpressiveMessagePosition.last,
            timestamp: '6:02',
          ),
          ExpressiveMessageBubble(
            text: 'Yes! Meet at the steps',
            side: ExpressiveMessageSide.outgoing,
            position: ExpressiveMessagePosition.first,
          ),
          ExpressiveMessageBubble(
            text: 'Boots, not sandals this time',
            side: ExpressiveMessageSide.outgoing,
            position: ExpressiveMessagePosition.last,
            timestamp: '6:04',
            status: ExpressiveMessageStatus.read,
          ),
          ExpressiveMessageBubble(
            text: 'Running five minutes late',
            side: ExpressiveMessageSide.outgoing,
            timestamp: '6:58',
            status: ExpressiveMessageStatus.failed,
          ),
        ],
      ),
    ],
  );
}

// Catalog specimens (docs/architecture/component-catalog.md).

/// A total in the display type, landed on its value.
Widget kitSpecimenCounterTotal() => Builder(
  builder: (context) {
    final t = context.expressiveTheme;
    return Center(
      child: ExpressiveCounter(
        1284,
        style: t.type.displayMedium.copyWith(color: t.colors.onSurface),
        semanticsLabel: '1,284 steps',
      ),
    );
  },
);

/// Minutes read this week, rising.
Widget kitSpecimenStatWeek() => const ExpressiveStat(
  label: 'Minutes read',
  value: 318,
  icon: ExpressiveSymbols.book,
  supporting: '+64 on last week',
  trend: ExpressiveTrend.up,
);

/// Four and a half stars out of five.
Widget kitSpecimenRatingHalf() =>
    const Center(child: ExpressiveRating(value: 4.5));

class _Amounts extends StatelessWidget {
  const _Amounts();

  @override
  Widget build(BuildContext context) =>
      kitSection('Amounts', children: <Widget>[kitSpecimenAmount()]);
}

/// A balance at display size, a price marked down, and money out inline.
Widget kitSpecimenAmount() => Builder(
  builder: (context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      const ExpressiveAmount(r'$12,480.52', size: ExpressiveAmountSize.display),
      const SizedBox(height: ExpressiveSpacing.s16),
      const ExpressiveAmount(
        r'$1,299.00',
        size: ExpressiveAmountSize.title,
        was: r'$1,499.00',
      ),
      const SizedBox(height: ExpressiveSpacing.s16),
      ExpressiveAmount(r'−$3.50', color: context.expressiveTheme.colors.error),
    ],
  ),
);

class _Timeline extends StatefulWidget {
  const _Timeline();

  @override
  State<_Timeline> createState() => _TimelineState();
}

class _TimelineState extends State<_Timeline> {
  int _at = 1;

  @override
  Widget build(BuildContext context) => kitSection(
    'Timeline · dots and glyphs, the current one in primary',
    children: <Widget>[
      ExpressiveTimeline(entries: _orderEntries(_at), currentStep: _at),
      KitAction(
        _at < _orderSteps.length - 1 ? 'Next step' : 'Start over',
        onTap: () =>
            setState(() => _at = _at < _orderSteps.length - 1 ? _at + 1 : 0),
      ),
    ],
  );
}

const List<(String, String, String, IconData)>
_orderSteps = <(String, String, String, IconData)>[
  (
    'Order placed',
    '09:12',
    'Two items, paid by card.',
    ExpressiveSymbols.check,
  ),
  ('Packed', '11:40', 'At the Leeds warehouse.', ExpressiveSymbols.inventory2),
  ('Shipped', '14:05', 'Tracking 4821 0093.', ExpressiveSymbols.localShipping),
  ('Delivered', 'Tomorrow', 'Before 6 pm.', ExpressiveSymbols.home),
];

List<ExpressiveTimelineEntry> _orderEntries(int at) =>
    <ExpressiveTimelineEntry>[
      for (var i = 0; i < _orderSteps.length; i++)
        ExpressiveTimelineEntry(
          title: _orderSteps[i].$1,
          time: _orderSteps[i].$2,
          description: _orderSteps[i].$3,
          icon: i <= at ? _orderSteps[i].$4 : null,
        ),
    ];

/// An order's progress, the second step current.
Widget kitSpecimenTimeline() =>
    ExpressiveTimeline(entries: _orderEntries(1), currentStep: 1);

class _Details extends StatelessWidget {
  const _Details();

  @override
  Widget build(BuildContext context) => kitSection(
    'Description list · term over value, beside it from 600dp',
    children: <Widget>[kitSpecimenDescriptionList()],
  );
}

/// An order's details.
Widget kitSpecimenDescriptionList() => const ExpressiveDescriptionList(
  items: <ExpressiveDescriptionItem>[
    ExpressiveDescriptionItem('Order', '#4821'),
    ExpressiveDescriptionItem('Placed', '14 March, 09:12'),
    ExpressiveDescriptionItem('Ship to', 'Ada Park, 12 Mill Lane, Leeds'),
    ExpressiveDescriptionItem('Total', r'$1,299.00'),
  ],
);
