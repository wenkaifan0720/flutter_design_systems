import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';
import 'package:neumorphism_ui/neumorphism_host.dart';

import 'support.dart';

void main() {
  setUpAll(loadNeumorphicFonts);
  testWidgets('notice meanings have distinct marks and default headings', (
    tester,
  ) async {
    await tester.pumpWidget(
      neumorphicApp(
        SingleChildScrollView(
          child: Column(
            children: [
              for (final tone in NeumorphicTone.values)
                NeumorphicBanner('Message', tone: tone),
            ],
          ),
        ),
      ),
    );
    for (final label in ['Information', 'Success', 'Warning', 'Error']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(
      tester
          .widgetList<Icon>(find.byType(Icon))
          .map((w) => w.icon)
          .toSet()
          .length,
      4,
    );
  });
  testWidgets(
    'progress has spoken values and stops scheduling under reduced motion',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        Widget content() => const Column(
          children: [
            NeumorphicCircularProgressIndicator(),
            NeumorphicLinearProgressIndicator(label: 'Waiting'),
            NeumorphicSkeleton.lines(2),
          ],
        );
        await tester.pumpWidget(neumorphicApp(content()));
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.binding.transientCallbackCount, greaterThan(0));
        await tester.pumpWidget(
          neumorphicApp(
            MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: content(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.binding.transientCallbackCount, 0);
        await tester.pumpWidget(
          neumorphicApp(
            const NeumorphicLinearProgressIndicator(
              value: .4,
              label: 'Uploading',
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          tester.getSemantics(find.bySemanticsLabel('Uploading')).value,
          '40',
        );
        expect(tester.binding.transientCallbackCount, 0);
      } finally {
        semantics.dispose();
      }
    },
  );
  testWidgets('badge caps visually but speaks the full count and hides zero', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(neumorphicApp(const NeumorphicBadge(120)));
      expect(find.text('99+'), findsOneWidget);
      expect(find.bySemanticsLabel('120'), findsOneWidget);
      await tester.pumpWidget(
        neumorphicApp(const NeumorphicBadge(0, child: Text('Inbox'))),
      );
      expect(find.text('Inbox'), findsOneWidget);
      expect(find.text('0'), findsNothing);
    } finally {
      semantics.dispose();
    }
  });
  testWidgets('host preserves two-times system text scaling', (tester) async {
    double? scaled;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: NeumorphicHost(
            child: Builder(
              builder: (context) {
                scaled = MediaQuery.textScalerOf(context).scale(16);
                return const Text('Scaled');
              },
            ),
          ),
        ),
      ),
    );
    expect(scaled, 32);
  });
  check(
    'long notices',
    () => NeumorphicBanner(
      longLine,
      title: longLine,
      tone: NeumorphicTone.warning,
      onDismiss: () {},
      action: NeumorphicButton(long, onPressed: () {}),
    ),
  );
  check(
    'long task progress',
    () => const NeumorphicLinearProgressIndicator(
      value: .7,
      label: longLine,
      note: long,
    ),
  );
  check(
    'success state',
    () => NeumorphicSuccessState(
      title: long,
      message: longLine,
      action: NeumorphicButton('Continue', onPressed: () {}),
    ),
  );
  check(
    'badge at large type',
    () => const NeumorphicBadge(1234, child: Icon(NeumorphicGlyphs.bell)),
  );
  check(
    'skeleton shapes',
    () => const Column(
      children: [
        NeumorphicSkeleton.lines(3),
        NeumorphicSkeleton.row(),
        NeumorphicSkeleton.box(),
      ],
    ),
  );
}
