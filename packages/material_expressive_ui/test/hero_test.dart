/// The hero: the scope hero widgets assert, no nesting, and the per-page
/// count the expression budget's lint reads.
library;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

/// Stands in for a hero widget (an XL button, a shaped image).
class _HeroWidget extends StatelessWidget {
  const _HeroWidget();

  @override
  Widget build(BuildContext context) {
    assert(ExpressiveHeroMoment.debugCheck(context, 'A hero widget'));
    return const SizedBox.square(dimension: 10);
  }
}

void main() {
  testWidgets('a hero widget inside an ExpressiveHeroMoment renders', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ExpressiveHeroMoment(label: 'primary action', child: _HeroWidget()),
    );
    expect(tester.takeException(), isNull);
    expect(
      ExpressiveHeroMoment.isInside(tester.element(find.byType(_HeroWidget))),
      isTrue,
    );
  });

  testWidgets('a hero widget outside one asserts', (tester) async {
    await tester.pumpWidget(const _HeroWidget());
    final error = tester.takeException();
    expect(error, isA<FlutterError>());
    expect('$error', contains('outside an ExpressiveHeroMoment'));
  });

  testWidgets('heroes do not nest', (tester) async {
    await tester.pumpWidget(
      const ExpressiveHeroMoment(
        child: ExpressiveHeroMoment(child: SizedBox()),
      ),
    );
    expect('${tester.takeException()}', contains('inside another'));
  });

  testWidgets('counts the hero moments on each page', (tester) async {
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        home: const Column(
          children: <Widget>[
            ExpressiveHeroMoment(label: 'cover', child: _HeroWidget()),
            _HeroWidget2(),
          ],
        ),
      ),
    );
    final home = ModalRoute.of(tester.element(find.byType(Column)))!;
    expect(ExpressiveHeroMoment.countOn(home), 2);
    expect(ExpressiveHeroMoment.labelsOn(home), <String?>['cover', null]);

    navigator.currentState!.push(
      MaterialPageRoute<void>(builder: (_) => const SizedBox()),
    );
    await tester.pumpAndSettle();
    final pushed = ModalRoute.of(tester.element(find.byType(SizedBox).last))!;
    expect(ExpressiveHeroMoment.countOn(pushed), 0);
    expect(ExpressiveHeroMoment.countOn(home), 2);

    await tester.pumpWidget(const SizedBox());
    expect(ExpressiveHeroMoment.countOn(home), 0);
  });
}

class _HeroWidget2 extends StatelessWidget {
  const _HeroWidget2();

  @override
  Widget build(BuildContext context) =>
      const ExpressiveHeroMoment(child: _HeroWidget());
}
