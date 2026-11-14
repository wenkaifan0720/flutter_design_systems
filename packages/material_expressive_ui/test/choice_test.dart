/// Choice tiles (components/choice.dart): a single group reports the tap at
/// once with radio semantics, a multi group toggles with checkbox
/// semantics, a selected tile fills with primaryContainer, morphs its
/// corners toward full and raises its title's weight, a disabled option
/// takes no tap, and a tile stays at least the list's two-line height and
/// never overflows at text scale 1.3.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/material_expressive_host.dart';

final ExpressiveThemeData _theme = ExpressiveThemeData.preset(
  'baseline',
  Brightness.light,
);

Widget _app(Widget child, {double textScale = 1}) => ExpressiveHost(
  light: _theme,
  brightness: Brightness.light,
  child: Directionality(
    textDirection: TextDirection.ltr,
    child: MediaQuery(
      data: MediaQueryData(
        size: const Size(320, 640),
        textScaler: TextScaler.linear(textScale),
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    ),
  ),
);

const List<ExpressiveChoiceOption<String>> _options =
    <ExpressiveChoiceOption<String>>[
      ExpressiveChoiceOption<String>(
        value: 'cuff',
        title: 'Bluetooth arm cuff',
        supportingText: 'Readings arrive on their own',
        icon: ExpressiveSymbols.sync,
      ),
      ExpressiveChoiceOption<String>(
        value: 'hand',
        title: 'Enter by hand',
        supportingText: 'Type each reading after you measure',
        icon: ExpressiveSymbols.edit,
      ),
      ExpressiveChoiceOption<String>(
        value: 'later',
        title: 'Decide later',
        enabled: false,
      ),
    ];

Finder _tile(String title) => find.ancestor(
  of: find.text(title),
  matching: find.byType(ExpressiveChoiceTile),
);

ExpressiveSurface _surface(WidgetTester tester, String title) =>
    tester.widget<ExpressiveSurface>(
      find.descendant(
        of: _tile(title),
        matching: find.byType(ExpressiveSurface),
      ),
    );

void main() {
  testWidgets('choice groups support intrinsic-height scrolling parents', (
    tester,
  ) async {
    for (final density in [
      ExpressiveDensity.standard,
      ExpressiveDensity.comfortable,
      ExpressiveDensity.compact,
    ]) {
      for (final width in [120.0, 240.0, 390.0]) {
        for (final scale in [1.0, 1.3]) {
          for (final direction in TextDirection.values) {
            await tester.pumpWidget(
              ExpressiveHost(
                light: _theme.copyWith(density: density),
                brightness: Brightness.light,
                child: Directionality(
                  textDirection: direction,
                  child: MediaQuery(
                    data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: SizedBox(
                        width: width,
                        height: 520,
                        child: CustomScrollView(
                          slivers: [
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: Column(
                                children: [
                                  const Expanded(child: SizedBox()),
                                  ExpressiveChoiceGroup<String>.single(
                                    options: _options,
                                    value: 'hand',
                                    onChanged: (_) {},
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
              ),
            );
            await tester.pumpAndSettle();
            expect(
              tester.takeException(),
              isNull,
              reason: '$density $width $scale $direction',
            );
          }
        }
      }
    }
  });

  testWidgets('a single group reports the tap at once, as one of a radio '
      'group', (tester) async {
    final semantics = tester.ensureSemantics();
    final chosen = <String>[];
    await tester.pumpWidget(
      _app(
        ExpressiveChoiceGroup<String>.single(
          options: _options,
          value: 'hand',
          onChanged: chosen.add,
          semanticLabel: 'How readings arrive',
        ),
      ),
    );
    await tester.tap(_tile('Bluetooth arm cuff'));
    // Reported on the tap itself: a first-run step advances on it.
    expect(chosen, <String>['cuff']);
    expect(
      tester.getSemantics(_tile('Enter by hand')),
      isSemantics(
        label: 'Enter by hand\nType each reading after you measure',
        hasCheckedState: true,
        isChecked: true,
        isInMutuallyExclusiveGroup: true,
        hasTapAction: true,
      ),
    );
    expect(
      tester.getSemantics(_tile('Bluetooth arm cuff')),
      isSemantics(isChecked: false, isInMutuallyExclusiveGroup: true),
    );
    // The disabled option takes no tap.
    await tester.tap(_tile('Decide later'), warnIfMissed: false);
    expect(chosen, <String>['cuff']);
    semantics.dispose();
  });

  testWidgets('a multi group toggles one option at a time, as checkboxes', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    var rooms = <String>{'hand'};
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) => _app(
          ExpressiveChoiceGroup<String>.multi(
            options: _options,
            values: rooms,
            onChanged: (next) => setState(() => rooms = next),
          ),
        ),
      ),
    );
    await tester.tap(_tile('Bluetooth arm cuff'));
    await tester.pumpAndSettle();
    expect(rooms, <String>{'hand', 'cuff'});
    await tester.tap(_tile('Enter by hand'));
    await tester.pumpAndSettle();
    expect(rooms, <String>{'cuff'});
    final node = tester.getSemantics(_tile('Bluetooth arm cuff'));
    expect(
      node,
      isSemantics(
        hasCheckedState: true,
        isChecked: true,
        isInMutuallyExclusiveGroup: false,
      ),
    );
    semantics.dispose();
  });

  testWidgets('selected fills with primaryContainer, rounds its corners and '
      'raises its title\'s weight', (tester) async {
    var value = 'hand';
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) => _app(
          ExpressiveChoiceGroup<String>.single(
            options: _options,
            value: value,
            onChanged: (next) => setState(() => value = next),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      _surface(tester, 'Enter by hand').color,
      _theme.colors.primaryContainer,
    );
    expect(
      _surface(tester, 'Enter by hand').shape,
      _theme.shapes.extraLargeIncreased,
    );
    expect(
      _surface(tester, 'Bluetooth arm cuff').color,
      _theme.colors.surfaceContainerHigh,
    );
    expect(_surface(tester, 'Bluetooth arm cuff').shape, _theme.shapes.large);
    FontWeight? weight(String title) =>
        tester.widget<Text>(find.text(title)).style?.fontWeight;
    expect(
      weight('Enter by hand'),
      _theme.type.titleMediumEmphasized.fontWeight,
    );
    expect(weight('Bluetooth arm cuff'), _theme.type.titleMedium.fontWeight);
    // A selected tile also carries a check, so the choice never reads from
    // colour alone.
    expect(
      find.descendant(
        of: _tile('Enter by hand'),
        matching: find.byWidgetPredicate(
          (w) => w is ExpressiveIcon && w.icon == ExpressiveSymbols.checkCircle,
        ),
      ),
      findsOneWidget,
    );

    await tester.tap(_tile('Bluetooth arm cuff'));
    await tester.pump();
    // Mid-morph, then settled on the new choice.
    await tester.pumpAndSettle();
    expect(
      _surface(tester, 'Bluetooth arm cuff').color,
      _theme.colors.primaryContainer,
    );
    expect(_surface(tester, 'Enter by hand').shape, _theme.shapes.large);
    expect(
      weight('Bluetooth arm cuff'),
      _theme.type.titleMediumEmphasized.fontWeight,
    );
  });

  testWidgets('at least the list\'s two-line height, and no overflow at text '
      'scale 1.3', (tester) async {
    await tester.pumpWidget(
      _app(
        ExpressiveChoiceGroup<String>.single(
          options: _options,
          value: 'cuff',
          onChanged: (_) {},
        ),
        textScale: 1.3,
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    for (final option in _options) {
      expect(
        tester.getSize(_tile(option.title)).height,
        greaterThanOrEqualTo(72),
      );
    }
  });
}
