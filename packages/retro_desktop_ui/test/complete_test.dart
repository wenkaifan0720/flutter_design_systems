import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

import 'support.dart';

Widget _host(
  Widget child, {
  double scale = 1,
  TextDirection direction = TextDirection.ltr,
}) => retroDesktopApp(
  SingleChildScrollView(
    child: Padding(padding: const EdgeInsets.all(20), child: child),
  ),
  scale: scale,
  direction: direction,
);

void main() {
  setUpAll(loadRetroDesktopFonts);
  testWidgets(
    'search clear preserves editor focus and notifies the owner once',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        final controller = TextEditingController(text: 'search');
        final focus = FocusNode();
        addTearDown(controller.dispose);
        addTearDown(focus.dispose);
        final changes = <String>[];
        await tester.pumpWidget(
          _host(
            RetroDesktopSearchField(
              hint: 'Find',
              controller: controller,
              focusNode: focus,
              onChanged: changes.add,
            ),
          ),
        );
        // ui_core's shared word (DesignLocalizations.clearButtonTooltip).
        await tester.tap(find.bySemanticsLabel('Clear'));
        await tester.pump();
        expect(controller.text, isEmpty);
        expect(changes, ['']);
        expect(focus.hasFocus, isTrue);
        await tester.pumpWidget(const SizedBox());
        controller.text = 'external controller still works';
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    },
  );
  testWidgets('code editor filters a pasted value and exposes OTP autofill', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _host(
        RetroDesktopInputOtp(
          label: 'Verification',
          length: 4,
          controller: controller,
        ),
      ),
    );
    await tester.enterText(find.byType(EditableText), '1x23!456');
    expect(controller.text, '1234');
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).autofillHints,
      contains(AutofillHints.oneTimeCode),
    );
  });
  testWidgets(
    'select chooses an enabled typed value through the keyboard menu',
    (tester) async {
      String? selected;
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (context, change) => RetroDesktopSelect<String>(
              label: 'Delivery',
              value: selected,
              options: const [
                RetroDesktopOption('slow', 'Post'),
                RetroDesktopOption('off', 'Unavailable', enabled: false),
                RetroDesktopOption('fast', 'Courier'),
              ],
              onChanged: (value) => change(() => selected = value),
            ),
          ),
        ),
      );
      // The face, not the select's middle: from 600 up the face hugs its
      // value at the start, under its label.
      await tester.tap(
        find
            .descendant(
              of: find.byType(RetroDesktopSelect<String>),
              matching: find.byType(RetroDesktopPressable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      // Opened by a click with no value, no row is lit: the first arrow
      // lights the first, the next steps over the unavailable one.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(selected, 'fast');
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('switch has one toggled semantic control and supports Space', (
    tester,
  ) async {
    var value = false;
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (context, change) => RetroDesktopSwitchRow(
              label: 'Synchronize',
              value: value,
              onChanged: (next) => change(() => value = next),
            ),
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(value, isTrue);
      expect(find.bySemanticsLabel('Synchronize'), findsOneWidget);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Synchronize')),
        matchesSemantics(
          label: 'Synchronize',
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          isFocused: true,
          hasToggledState: true,
          isToggled: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
    } finally {
      semantics.dispose();
    }
  });
  testWidgets('radio arrows skip disabled choices and follow RTL', (
    tester,
  ) async {
    var value = 1;
    await tester.pumpWidget(
      _host(
        StatefulBuilder(
          builder: (context, change) => RetroDesktopRadioGroup<int>(
            label: 'Grade',
            value: value,
            options: const [
              RetroDesktopRadio(1, 'First'),
              RetroDesktopRadio(2, 'Disabled', enabled: false),
              RetroDesktopRadio(3, 'Third'),
            ],
            onChanged: (next) => change(() => value = next),
          ),
        ),
        direction: TextDirection.rtl,
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(value, 3);
    await tester.sendKeyEvent(LogicalKeyboardKey.home);
    await tester.pump();
    expect(value, 1);
  });
  testWidgets('segments retain typed values and keyboard selection', (
    tester,
  ) async {
    var value = 'a';
    await tester.pumpWidget(
      _host(
        StatefulBuilder(
          builder: (context, change) => RetroDesktopSegmentedButton<String>(
            label: 'View',
            value: value,
            segments: const [
              RetroDesktopButtonSegment('a', 'List'),
              RetroDesktopButtonSegment('b', 'Grid'),
            ],
            onChanged: (next) => change(() => value = next),
          ),
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(value, 'b');
  });
  testWidgets(
    'slider snaps pointer movement and settles the actual final value',
    (tester) async {
      var value = 0.0;
      final ends = <double>[];
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (context, change) => RetroDesktopSlider(
              label: 'Volume',
              value: value,
              divisions: 4,
              onChanged: (next) => change(() => value = next),
              onChangeEnd: ends.add,
            ),
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(value, .25);
      expect(ends, [.25]);
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pump();
      expect(value, 1);
      final track = find
          .descendant(
            of: find.byType(RetroDesktopSlider),
            matching: find.byType(CustomPaint),
          )
          .first;
      await tester.dragFrom(
        tester.getCenter(track),
        Offset(tester.getSize(track).width / 2, 0),
      );
      await tester.pump();
      expect(ends.last, value);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('calendar keyboard crosses months and obeys its range', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      var value = DateTime(2026, 11, 30);
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (context, change) => RetroDesktopDatePicker(
              value: value,
              first: DateTime(2026, 11, 1),
              last: DateTime(2026, 12, 2),
              onChanged: (next) => change(() => value = next),
            ),
          ),
        ),
      );
      await tester.tap(find.bySemanticsLabel('November 30, 2026'));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(value, DateTime(2026, 12, 1));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(value, DateTime(2026, 12, 2));
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });
  test('time values are neutral, immutable and format noon/midnight', () {
    expect(const RetroDesktopTime(0, 5).format(use24Hour: false), '12:05 AM');
    expect(const RetroDesktopTime(12, 15).format(use24Hour: false), '12:15 PM');
    expect(
      const RetroDesktopTime(23, 59).copyWith(minute: 0),
      const RetroDesktopTime(23, 0),
    );
  });
  testWidgets('date dialog returns its confirmed controlled value', (
    tester,
  ) async {
    DateTime? result;
    await tester.pumpWidget(
      _host(
        Builder(
          builder: (context) => RetroDesktopButton(
            'Open',
            onPressed: () async => result = await showRetroDesktopDatePicker(
              context,
              value: DateTime(2026, 11, 6),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose'));
    await tester.pumpAndSettle();
    expect(result, DateTime(2026, 11, 6));
  });
  testWidgets('page marks use roving focus and wrap their arrow selection', (
    tester,
  ) async {
    var selected = 0;
    await tester.pumpWidget(
      _host(
        StatefulBuilder(
          builder: (context, change) => RetroDesktopPageDots(
            count: 3,
            selectedIndex: selected,
            label: 'Introduction',
            onChanged: (next) => change(() => selected = next),
          ),
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(selected, 2);
  });
  for (final width in [390.0, 768.0, 1024.0, 1440.0]) {
    for (final direction in TextDirection.values) {
      testWidgets('new controls fit 2x at $width $direction', (tester) async {
        tester.view.physicalSize = Size(width, 2000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          _host(
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                RetroDesktopSearchField(
                  hint: 'Search this collection',
                  onChanged: (_) {},
                ),
                const RetroDesktopInputOtp(label: 'Verification code'),
                RetroDesktopSelect<int>(
                  label: 'Delivery method',
                  options: const [RetroDesktopOption(1, 'Courier delivery')],
                  onChanged: (_) {},
                ),
                RetroDesktopSwitchRow(
                  label: 'Automatically synchronize all folders',
                  value: true,
                  onChanged: (_) {},
                ),
                RetroDesktopRadioGroup<int>(
                  label: 'Grade',
                  options: const [
                    RetroDesktopRadio(1, 'The first available grade'),
                  ],
                  onChanged: (_) {},
                ),
                RetroDesktopSegmentedButton<int>(
                  label: 'View',
                  segments: const [
                    RetroDesktopButtonSegment(1, 'List'),
                    RetroDesktopButtonSegment(2, 'Grid'),
                  ],
                  onChanged: (_) {},
                ),
                RetroDesktopSlider(
                  label: 'Maximum volume',
                  value: .5,
                  onChanged: (_) {},
                ),
                RetroDesktopDatePicker(
                  value: DateTime(2026, 11, 6),
                  onChanged: (_) {},
                ),
                RetroDesktopTimePicker(
                  value: const RetroDesktopTime(15, 45),
                  onChanged: (_) {},
                ),
                RetroDesktopButton.text('More information', onPressed: () {}),
                RetroDesktopButton(
                  'Delete this folder',
                  isDefaultAction: true,
                  isDestructiveAction: true,
                  onPressed: () {},
                ),
                RetroDesktopLink('Read the documentation', onPressed: () {}),
                RetroDesktopPageDots(
                  count: 3,
                  selectedIndex: 0,
                  label: 'Pages',
                  onChanged: (_) {},
                ),
                const RetroDesktopStepProgress(
                  count: 4,
                  currentStep: 1,
                  name: 'Getting started',
                ),
              ],
            ),
            scale: 2,
            direction: direction,
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
      });
    }
  }
}
