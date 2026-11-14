import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

import 'support.dart';

class _Counter extends StatefulWidget {
  const _Counter();

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int value = 0;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => setState(() => value++),
    child: Text('Count $value'),
  );
}

const _rounded = NeumorphicStyle(
  shape: WidgetStatePropertyAll(NeumorphicRoundedBorder(radius: 20)),
);

void main() {
  setUpAll(loadNeumorphicFonts);
  for (final customFirst in [false, true]) {
    testWidgets(
      'changing ${customFirst ? 'custom to natural' : 'natural to custom'} corners preserves card content state',
      (tester) async {
        final custom = ValueNotifier(customFirst);
        addTearDown(custom.dispose);
        await tester.pumpWidget(
          neumorphicApp(
            Builder(
              builder: (context) => ValueListenableBuilder<bool>(
                valueListenable: custom,
                builder: (context, value, _) => NeumorphicTheme(
                  data: NeumorphicTheme.of(context).copyWith(
                    cardTheme: value ? _rounded : const NeumorphicStyle(),
                  ),
                  child: const Center(
                    child: NeumorphicCard(
                      title: 'Preferences',
                      children: [_Counter()],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Count 0'));
        await tester.pumpAndSettle();
        expect(find.text('Count 1'), findsOneWidget);
        custom.value = !customFirst;
        await tester.pumpAndSettle();
        expect(find.text('Count 1'), findsOneWidget);
        await tester.tap(find.text('Count 1'));
        await tester.pumpAndSettle();
        expect(find.text('Count 2'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
  for (final still in [false, true]) {
    testWidgets(
      'custom shape ${still ? 'jumps with reduced motion' : 'retains its morph animation'}',
      (tester) async {
        final shape = ValueNotifier<OutlinedBorder>(
          const NeumorphicRoundedBorder(radius: 4),
        );
        addTearDown(shape.dispose);
        await tester.pumpWidget(
          neumorphicApp(
            Builder(
              builder: (context) => NeumorphicTheme(
                data: NeumorphicTheme.of(context),
                child: MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(disableAnimations: still),
                  child: Center(
                    child: SizedBox.square(
                      dimension: 100,
                      child: ValueListenableBuilder<OutlinedBorder>(
                        valueListenable: shape,
                        builder: (context, value, _) => AnimatedNeumorphicShape(
                          shape: value,
                          builder: (context, current) => DecoratedBox(
                            decoration: ShapeDecoration(
                              color: Colors.blue,
                              shape: current!,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        Future<List<int>> pixels() async => (await tester.runAsync(() async {
          final image = await captureImage(
            tester.element(find.byType(AnimatedNeumorphicShape)),
          );
          try {
            final bytes = (await image.toByteData())!;
            return bytes.buffer
                .asUint8List(bytes.offsetInBytes, bytes.lengthInBytes)
                .toList();
          } finally {
            image.dispose();
          }
        }))!;
        shape.value = const NeumorphicRoundedBorder(radius: 36);
        await tester.pump();
        final start = await pixels();
        await tester.pump(const Duration(milliseconds: 100));
        final middle = await pixels();
        await tester.pumpAndSettle();
        final end = await pixels();
        if (still) {
          expect(start, orderedEquals(end));
        } else {
          expect(start, isNot(orderedEquals(middle)));
          expect(middle, isNot(orderedEquals(end)));
        }
        expect(tester.takeException(), isNull);
      },
      tags: ['goldens'],
    );
  }
}
