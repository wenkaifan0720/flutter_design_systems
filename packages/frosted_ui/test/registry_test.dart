// The shared inventory as Frosted answers it: every row answered, each live
// specimen a Frosted class of the row's name that builds without throwing,
// and the one gap with its reason.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:frosted_ui/frosted_host.dart';

/// [home] in an app under Frosted's host, as a page gets it.
Widget _app(Widget home) => MaterialApp(
  debugShowCheckedModeBanner: false,
  localizationsDelegates: const [FrostedLocalizations.delegate],
  builder: (BuildContext context, Widget? page) =>
      FrostedHost(brightness: Brightness.light, child: page!),
  home: home,
);

void main() {
  testWidgets('answers every row, each specimen of its own class', (t) async {
    late BuildContext context;
    await t.pumpWidget(
      _app(
        Builder(
          builder: (c) {
            context = c;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    frostedInventory.verify();
    expect(frostedInventory.look, 'Frosted');
    for (final row in DesignInventoryRow.all) {
      final specimen = frostedInventory
          .entryFor(row.id)
          ?.builder
          ?.call(context);
      if (specimen == null) continue;
      expect(
        specimen.runtimeType.toString().split('<').first,
        'Frosted${row.id}',
        reason: "${row.id}'s specimen",
      );
    }
  });

  test('the one gap gives its reason', () {
    final gaps = [
      for (final row in DesignInventoryRow.all)
        if (!(frostedInventory.entryFor(row.id)?.isPresent ?? false)) row.id,
    ];
    expect(gaps, ['FloatingActionButton']);
    expect(
      frostedInventory.entryFor('FloatingActionButton')!.absentReason,
      contains('FrostedNavAction'),
    );
  });

  group('each live specimen builds', () {
    for (final row in DesignInventoryRow.all) {
      final entry = frostedInventory.entryFor(row.id);
      final build = entry?.builder;
      if (build == null) continue;
      for (final size in const [Size(390, 844), Size(1280, 900)]) {
        testWidgets('${row.id} at ${size.width.round()} wide', (t) async {
          t.view.physicalSize = size;
          t.view.devicePixelRatio = 1;
          addTearDown(t.view.reset);
          await t.pumpWidget(
            _app(
              Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 640),
                    child: Builder(builder: build),
                  ),
                ),
              ),
            ),
          );
          await t.pump(const Duration(milliseconds: 600));
          expect(t.takeException(), isNull);
          // Gone again: whatever it started stops with it.
          await t.pumpWidget(const SizedBox.shrink());
          await t.pump(const Duration(seconds: 10));
        });
      }
    }
  });
}
