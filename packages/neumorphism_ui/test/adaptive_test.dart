import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

import 'support.dart';

void _test(String description, WidgetTesterCallback body) =>
    testWidgets(description, body, variant: TargetPlatformVariant.all());

Iterable<ScrollPhysics> _physics(ScrollPhysics? physics) sync* {
  while (physics != null) {
    yield physics;
    physics = physics.parent;
  }
}

void main() {
  setUpAll(loadNeumorphicFonts);

  test('the library has no native or browser-only imports or channels', () {
    final forbidden = RegExp(
      r'''(?:import|export)\s+['"]dart:(?:io|html)['"]|\b(?:MethodChannel|EventChannel|BasicMessageChannel)\s*[<(]''',
    );
    for (final file
        in Directory('lib/src/neumorphism')
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) => file.path.endsWith('.dart'))) {
      expect(
        forbidden.hasMatch(file.readAsStringSync()),
        isFalse,
        reason: file.path,
      );
    }
  });

  _test('a cached palette retains the current platform behavior', (
    tester,
  ) async {
    late TargetPlatform platform;
    await tester.pumpWidget(
      neumorphicApp(
        Builder(
          builder: (context) {
            platform = Theme.of(context).platform;
            return const NeumorphicTextField(label: 'Name');
          },
        ),
      ),
    );
    expect(platform, defaultTargetPlatform);
    expect(tester.takeException(), isNull);
  });

  _test('screen scroll physics and touch and wheel input follow the platform', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      neumorphicApp(
        NeumorphicScaffold(
          scrollController: controller,
          body: Column(
            children: [
              for (var i = 0; i < 30; i++)
                SizedBox(height: 80, child: Text('Record $i')),
            ],
          ),
        ),
      ),
    );
    final physics = _physics(controller.position.physics);
    final apple =
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
    expect(physics.any((value) => value is BouncingScrollPhysics), apple);
    expect(physics.any((value) => value is ClampingScrollPhysics), !apple);
    await tester.drag(find.byType(NeumorphicScaffold), const Offset(0, -180));
    await tester.pumpAndSettle();
    expect(controller.offset, greaterThan(0));
    final before = controller.offset;
    await tester.sendEventToBinding(
      const PointerScrollEvent(
        position: Offset(195, 300),
        kind: PointerDeviceKind.mouse,
        scrollDelta: Offset(0, 120),
      ),
    );
    await tester.pumpAndSettle();
    expect(controller.offset, greaterThan(before));
    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 768.0, 1024.0, 1440.0]) {
    for (final scale in [1.0, 2.0]) {
      for (final direction in TextDirection.values) {
        _test(
          'screen at $width, text $scale, $direction keeps its footer usable',
          (tester) async {
            tester.view.physicalSize = Size(width, 800);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.reset);
            var saved = 0;
            await tester.pumpWidget(
              neumorphicApp(
                NeumorphicScaffold(
                  topBar: const NeumorphicAppBar(title: 'Details'),
                  body: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(longLine),
                      const NeumorphicTextField(
                        label: 'A descriptive record name',
                        helper: longLine,
                      ),
                      NeumorphicSegmentedButton<String>(
                        label: 'Period',
                        value: 'day',
                        segments: const [
                          NeumorphicButtonSegment('day', 'Day'),
                          NeumorphicButtonSegment('week', 'Week'),
                          NeumorphicButtonSegment('month', 'Month'),
                        ],
                        onChanged: (_) {},
                      ),
                      NeumorphicSwitchRow(
                        label: 'Send reminders',
                        note: longLine,
                        value: true,
                        onChanged: (_) {},
                      ),
                      const SizedBox(height: 500),
                    ],
                  ),
                  footer: NeumorphicButton.filled(
                    'Save changes',
                    onPressed: () => saved++,
                  ),
                ),
                direction: direction,
                textScale: scale,
              ),
            );
            await tester.pumpAndSettle();
            final footer = find.text('Save changes');
            expect(tester.getRect(footer).bottom, lessThanOrEqualTo(800));
            await tester.tap(footer);
            await tester.pumpAndSettle();
            expect(saved, 1);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }
}
