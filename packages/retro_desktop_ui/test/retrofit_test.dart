import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

Widget _host(Widget child, {TextDirection direction = TextDirection.ltr}) =>
    MaterialApp(
      home: RetroDesktopTheme(
        data: RetroDesktopThemeData.classic(),
        child: Directionality(
          textDirection: direction,
          child: Center(child: SizedBox(width: 320, child: child)),
        ),
      ),
    );

void main() {
  for (final kind in ['act', 'line', 'quiet', 'danger']) {
    for (final intrinsic in [false, true]) {
      testWidgets('wide button fits a row, kind=$kind intrinsic=$intrinsic', (
        tester,
      ) async {
        var pressed = 0;
        final button = switch (kind) {
          'act' => RetroDesktopButton(
            'Start',
            isDefaultAction: true,
            wide: true,
            onPressed: () => pressed++,
          ),
          'line' => RetroDesktopButton(
            'Start',
            wide: true,
            onPressed: () => pressed++,
          ),
          'quiet' => RetroDesktopButton.text(
            'Start',
            wide: true,
            onPressed: () => pressed++,
          ),
          _ => RetroDesktopButton(
            'Start',
            isDefaultAction: true,
            isDestructiveAction: true,
            wide: true,
            onPressed: () => pressed++,
          ),
        };
        await tester.pumpWidget(
          _host(
            Row(
              children: [
                const Text('Route'),
                intrinsic ? IntrinsicWidth(child: button) : button,
              ],
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Start'));
        expect(pressed, 1);
      });
    }
  }

  testWidgets('activating the selected segment does not report a change', (
    tester,
  ) async {
    final values = <String>[];
    await tester.pumpWidget(
      _host(
        RetroDesktopSegmentedButton<String>(
          label: 'Travel mode',
          value: 'drive',
          segments: const [
            RetroDesktopButtonSegment('drive', 'Drive'),
            RetroDesktopButtonSegment('cycle', 'Cycle'),
          ],
          onChanged: values.add,
        ),
      ),
    );
    await tester.tap(find.text('Cycle'));
    await tester.tap(find.text('Drive'));
    expect(values, ['cycle']);
  });

  testWidgets('a narrow field can edit and activate its wrapped suffix', (
    tester,
  ) async {
    final controller = TextEditingController(text: 'Draft');
    addTearDown(controller.dispose);
    var cleared = 0;
    await tester.pumpWidget(
      _host(
        Center(
          child: SizedBox(
            width: 120,
            child: RetroDesktopTextField(
              label: 'Document',
              leading: const Icon(Icons.search),
              controller: controller,
              trailing: RetroDesktopButton(
                'Clear',
                onPressed: () {
                  controller.clear();
                  cleared++;
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(EditableText), 'New draft');
    expect(controller.text, 'New draft');
    await tester.tap(find.text('Clear'));
    await tester.pump();
    expect(cleared, 1);
    expect(controller.text, isEmpty);
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.all());

  testWidgets(
    'checkbox cycles false, true, mixed and false with one named node',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        bool? value = false;
        await tester.pumpWidget(
          _host(
            StatefulBuilder(
              builder: (context, change) => RetroDesktopCheckbox(
                label: 'Choice',
                value: value,
                onChanged: (next) => change(() => value = next),
              ),
            ),
          ),
        );
        for (final expected in <bool?>[true, null, false]) {
          await tester.tap(find.bySemanticsLabel('Choice'));
          await tester.pump();
          expect(value, expected);
          expect(find.bySemanticsLabel('Choice'), findsOneWidget);
        }
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets(
    'password reveal preserves editing focus and the controlled value',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        final focus = FocusNode();
        final controller = TextEditingController(text: 'letters');
        addTearDown(focus.dispose);
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          _host(
            RetroDesktopTextField(
              label: 'Password',
              password: true,
              focusNode: focus,
              controller: controller,
            ),
          ),
        );
        expect(
          tester.widget<EditableText>(find.byType(EditableText)).obscureText,
          isTrue,
        );
        await tester.tap(find.bySemanticsLabel('Show password'));
        await tester.pump();
        expect(
          tester.widget<EditableText>(find.byType(EditableText)).obscureText,
          isFalse,
        );
        expect(controller.text, 'letters');
        expect(focus.hasFocus, isTrue);
        await tester.tap(find.bySemanticsLabel('Hide password'));
        await tester.pump();
        expect(
          tester.widget<EditableText>(find.byType(EditableText)).obscureText,
          isTrue,
        );
        expect(focus.hasFocus, isTrue);
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets(
    'busy button keeps its face until showBusy and suppresses activation',
    (tester) async {
      var calls = 0;
      final focus = FocusNode();
      addTearDown(focus.dispose);
      Widget app(bool busy, bool shown) => _host(
        RetroDesktopButton(
          'Save',
          isDefaultAction: true,
          busy: busy,
          showBusy: shown,
          focusNode: focus,
          onPressed: () => calls++,
        ),
      );
      await tester.pumpWidget(app(false, false));
      focus.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(calls, 1);
      await tester.pumpWidget(app(true, false));
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.tap(find.byType(RetroDesktopButton));
      expect(calls, 1);
      expect(focus.hasFocus, isTrue);
      expect(find.byIcon(RetroDesktopGlyphs.hourglass), findsNothing);
      await tester.pumpWidget(app(true, true));
      expect(find.byIcon(RetroDesktopGlyphs.hourglass), findsOneWidget);
    },
  );

  testWidgets('chip selection and deletion remain separate named controls', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      var pressed = 0, deleted = 0;
      await tester.pumpWidget(
        _host(
          RetroDesktopChip(
            'Inbox',
            selected: true,
            onPressed: () => pressed++,
            onDeleted: () => deleted++,
            deleteLabel: 'Remove Inbox',
          ),
        ),
      );
      await tester.tap(find.bySemanticsLabel('Remove Inbox'));
      expect(deleted, 1);
      expect(pressed, 0);
      await tester.tap(find.bySemanticsLabel('Inbox'));
      expect(pressed, 1);
      expect(deleted, 1);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('numeric stepper clamps both directions and disables the bound', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      var value = 5;
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (context, change) => RetroDesktopNumberField(
              label: 'Quantity',
              unit: 'items',
              value: value,
              min: 4,
              max: 6,
              onChanged: (next) => change(() => value = next),
            ),
          ),
        ),
      );
      await tester.tap(find.bySemanticsLabel('More'));
      await tester.pump();
      expect(value, 6);
      await tester.tap(find.bySemanticsLabel('More'));
      expect(value, 6);
      await tester.tap(find.bySemanticsLabel('Less'));
      await tester.pump();
      await tester.tap(find.bySemanticsLabel('Less'));
      await tester.pump();
      expect(value, 4);
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });

  for (final direction in TextDirection.values) {
    testWidgets(
      'tab arrows choose views in $direction without a required panel',
      (tester) async {
        var index = 1;
        await tester.pumpWidget(
          _host(
            StatefulBuilder(
              builder: (context, change) => RetroDesktopTabBar(
                tabs: const ['First', 'Second', 'Third'],
                selectedIndex: index,
                onChanged: (next) => change(() => index = next),
              ),
            ),
            direction: direction,
          ),
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pump();
        expect(index, direction == TextDirection.ltr ? 2 : 0);
        await tester.sendKeyEvent(LogicalKeyboardKey.home);
        await tester.pump();
        expect(index, 0);
        await tester.sendKeyEvent(LogicalKeyboardKey.end);
        await tester.pump();
        expect(index, 2);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
