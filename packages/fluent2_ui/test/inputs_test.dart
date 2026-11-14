import 'package:material_ui/material_ui.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluent2_ui/fluent2_ui.dart';
import 'package:fluent2_ui/fluent2_host.dart';

/// The controls and inputs group: every public control pumps under a
/// Fluent2Host, says its role, value and state to a screen reader, answers
/// a press (or a key) through its callback, and is inert when disabled;
/// the colour pairs the group adds hold Fluent's floors in every preset.
void main() {
  setUp(
    () =>
        TestWidgetsFlutterBinding.ensureInitialized()
            .platformDispatcher
            .accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
          disableAnimations: true,
        ),
  );
  tearDown(
    () => TestWidgetsFlutterBinding.ensureInitialized().platformDispatcher
        .clearAccessibilityFeaturesTestValue(),
  );

  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    Size size = const Size(390, 844),
    double textScale = 1,
  }) async {
    tester.view.physicalSize = size * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        builder: (c, home) => MediaQuery(
          data: MediaQuery.of(c)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: Fluent2Host(child: home!),
        ),
        home: Builder(
          builder: (context) => ColoredBox(
            color: context.fluent2Theme.background,
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  const desktop = Size(1280, 800);
  final stars = find.descendant(
    of: find.byType(Fluent2Rating),
    matching: find.byType(Row),
  );

  group('checkbox', () {
    testWidgets('toggles, says checked and mixed, disabled is inert', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      bool? value = false;
      await pump(
        tester,
        StatefulBuilder(
          builder: (context, set) => Column(
            children: [
              Fluent2Checkbox(
                value: value,
                label: 'Email me',
                onChanged: (v) => set(() => value = v),
              ),
              const Fluent2Checkbox(
                value: null,
                label: 'Mixed',
                onChanged: null,
              ),
            ],
          ),
        ),
      );
      await tester.tap(find.text('Email me'));
      await tester.pump();
      expect(value, isTrue);
      expect(
        tester.getSemantics(find.byType(Fluent2Checkbox).first),
        isSemantics(
          label: 'Email me',
          hasCheckedState: true,
          isChecked: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );
      expect(
        tester.getSemantics(find.byType(Fluent2Checkbox).last),
        isSemantics(isCheckStateMixed: true, isEnabled: false),
      );
      await tester.tap(find.text('Mixed'));
      await tester.pump();
      expect(tester.takeException(), isNull);
      handle.dispose();
    });

    testWidgets('mixed goes to checked', (tester) async {
      bool? got;
      await pump(
        tester,
        Fluent2Checkbox(value: null, label: 'All', onChanged: (v) => got = v),
      );
      await tester.tap(find.text('All'));
      expect(got, isTrue);
    });

    testWidgets('completion check reports and toggles', (tester) async {
      bool? got;
      await pump(
        tester,
        Column(
          children: [
            Fluent2CompletionCheck(
              value: false,
              label: 'Send the deck',
              onChanged: (v) => got = v,
            ),
            const Fluent2CompletionCheck(
              value: true,
              label: 'Reported',
              readOnly: true,
            ),
          ],
        ),
      );
      await tester.tap(find.byType(Fluent2CompletionCheck).first);
      expect(got, isTrue);
      await tester.tap(find.byType(Fluent2CompletionCheck).last);
      expect(tester.takeException(), isNull);
    });
  });

  group('radio', () {
    testWidgets('chooses, skips the disabled, says the group', (tester) async {
      final handle = tester.ensureSemantics();
      var value = 'daily';
      await pump(
        tester,
        StatefulBuilder(
          builder: (context, set) => Fluent2RadioGroup<String>(
            label: 'Digest',
            value: value,
            onChanged: (v) => set(() => value = v),
            options: const [
              Fluent2Radio('daily', 'Daily'),
              Fluent2Radio('weekly', 'Weekly'),
              Fluent2Radio('live', 'Live', enabled: false),
            ],
          ),
        ),
      );
      await tester.tap(find.text('Weekly'));
      await tester.pump();
      expect(value, 'weekly');
      await tester.tap(find.text('Live'));
      await tester.pump();
      expect(value, 'weekly');
      expect(
        tester.getSemantics(find.byType(Fluent2Radio<String>).at(1)),
        isSemantics(
          label: 'Weekly',
          isInMutuallyExclusiveGroup: true,
          isChecked: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('horizontal layout fits the phone at text scale 1.3', (
      tester,
    ) async {
      await pump(
        tester,
        Fluent2RadioGroup<String>(
          label: 'Who can see this file',
          value: 'team',
          onChanged: (_) {},
          layout: Fluent2RadioLayout.horizontal,
          options: const [
            Fluent2Radio('me', 'Only me'),
            Fluent2Radio('team', 'Northwind'),
            Fluent2Radio('link', 'Anyone with the link'),
          ],
        ),
        textScale: 1.3,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('switch', () {
    testWidgets('toggles and says toggled; disabled is inert', (tester) async {
      final handle = tester.ensureSemantics();
      var on = false;
      await pump(
        tester,
        StatefulBuilder(
          builder: (context, set) => Column(
            children: [
              Fluent2Switch(
                value: on,
                label: 'Away',
                onChanged: (v) => set(() => on = v),
              ),
              const Fluent2Switch(
                value: true,
                label: 'Locked',
                onChanged: null,
              ),
            ],
          ),
        ),
      );
      await tester.tap(find.text('Away'));
      await tester.pump();
      expect(on, isTrue);
      expect(
        tester.getSemantics(find.byType(Fluent2Switch).first),
        isSemantics(label: 'Away', hasToggledState: true, isToggled: true),
      );
      expect(
        tester.getSemantics(find.byType(Fluent2Switch).last),
        isSemantics(isEnabled: false, hasTapAction: false),
      );
      handle.dispose();
    });
  });

  group('segmented', () {
    testWidgets('chooses a segment, says selected; disabled is inert', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      var view = 'day';
      const segments = [
        Fluent2ButtonSegment('day', 'Day'),
        Fluent2ButtonSegment('week', 'Week'),
        Fluent2ButtonSegment('month', 'Month'),
      ];
      await pump(
        tester,
        StatefulBuilder(
          builder: (context, set) => Column(
            children: [
              Fluent2SegmentedButton<String>(
                label: 'View',
                segments: segments,
                value: view,
                onChanged: (v) => set(() => view = v),
              ),
              const Fluent2SegmentedButton<String>(
                label: 'Locked view',
                segments: segments,
                value: 'day',
                onChanged: null,
              ),
            ],
          ),
        ),
      );
      await tester.tap(find.text('Month').first);
      await tester.pump();
      expect(view, 'month');
      expect(
        tester.getSemantics(find.text('Month').first),
        isSemantics(label: 'Month', isSelected: true),
      );
      await tester.tap(find.text('Week').last);
      await tester.pump();
      expect(view, 'month');
      handle.dispose();
    });
  });

  group('slider', () {
    testWidgets('says its value, steps by the reader and the keys', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      var value = 50.0;
      await pump(
        tester,
        StatefulBuilder(
          builder: (context, set) => Column(
            children: [
              Fluent2Slider(
                label: 'Volume',
                value: value,
                step: 10,
                onChanged: (v) => set(() => value = v),
              ),
              const Fluent2Slider(label: 'Muted', value: 20, onChanged: null),
            ],
          ),
        ),
      );
      expect(
        tester.getSemantics(find.byType(Fluent2Slider).first),
        isSemantics(label: 'Volume', isSlider: true, hasIncreaseAction: true),
      );
      tester.semantics.performAction(
        find.semantics.byLabel('Volume'),
        SemanticsAction.increase,
      );
      await tester.pump();
      expect(value, 60);
      expect(
        tester.getSemantics(find.byType(Fluent2Slider).last),
        isSemantics(hasIncreaseAction: false),
      );
      handle.dispose();
    });

    testWidgets('a drag sets the value', (tester) async {
      double? got;
      await pump(
        tester,
        Fluent2Slider(label: 'Volume', value: 0, onChanged: (v) => got = v),
      );
      final box = tester.getRect(find.byType(Fluent2Slider));
      await tester.tapAt(Offset(box.right - 4, box.center.dy));
      expect(got, greaterThan(90));
    });
  });

  group('spin button', () {
    testWidgets('steps, stops at its bounds, takes typed numbers', (
      tester,
    ) async {
      num value = 49;
      await pump(
        tester,
        StatefulBuilder(
          builder: (context, set) => Fluent2SpinButton(
            label: 'Seats',
            value: value,
            min: 1,
            max: 50,
            onChanged: (v) => set(() => value = v),
          ),
        ),
      );
      await tester.tap(find.byIcon(Fluent2Icons.chevronUp16));
      await tester.pump();
      expect(value, 50);
      await tester.tap(find.byIcon(Fluent2Icons.chevronUp16));
      await tester.pump();
      expect(value, 50);
      await tester.tap(find.byIcon(Fluent2Icons.chevronDown16));
      await tester.pump();
      expect(value, 49);
      await tester.enterText(find.byType(TextField), '12');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(value, 12);
    });

    testWidgets('disabled is inert', (tester) async {
      await pump(
        tester,
        const Fluent2SpinButton(label: 'Seats', value: 3, onChanged: null),
      );
      await tester.tap(find.byIcon(Fluent2Icons.chevronUp16));
      expect(tester.takeException(), isNull);
      expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
    });
  });

  group('rating', () {
    testWidgets('a press sets the score; says "3 of 5"; disabled inert', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      var score = 3.0;
      await pump(
        tester,
        StatefulBuilder(
          builder: (context, set) => Column(
            children: [
              Fluent2Rating(
                label: 'Rate',
                value: score,
                onChanged: (v) => set(() => score = v),
              ),
              const Fluent2Rating(label: 'Locked', value: 2, onChanged: null),
            ],
          ),
        ),
      );
      expect(
        tester.getSemantics(stars.first),
        isSemantics(label: 'Rate', value: '3 of 5'),
      );
      final row = tester.getRect(stars.first);
      await tester.tapAt(Offset(row.left + row.width * 0.7, row.center.dy));
      await tester.pump();
      expect(score, 4);
      tester.semantics.performAction(
        find.semantics.byLabel('Rate'),
        SemanticsAction.increase,
      );
      await tester.pump();
      expect(score, 5);
      expect(
        tester.getSemantics(stars.last),
        isSemantics(hasIncreaseAction: false),
      );
      handle.dispose();
    });

    testWidgets('halves', (tester) async {
      double? got;
      await pump(
        tester,
        Fluent2Rating(
          label: 'Rate',
          value: 1,
          allowHalf: true,
          onChanged: (v) => got = v,
        ),
      );
      final row = tester.getRect(stars);
      final star = row.width / 5;
      await tester.tapAt(Offset(row.left + star * 2 + 3, row.center.dy));
      expect(got, 2.5);
    });

    testWidgets('display reads as one image', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(
        tester,
        const Column(
          children: [
            Fluent2RatingDisplay(value: 4.5, count: 1160),
            Fluent2RatingDisplay(value: 4, compact: true),
          ],
        ),
      );
      expect(find.text('4.5 · 1,160', findRichText: true), findsOneWidget);
      expect(
        find.bySemanticsLabel('Rated 4.5 out of 5, 1,160 ratings'),
        findsOneWidget,
      );
      handle.dispose();
    });
  });

  group('input', () {
    testWidgets('types, names itself, disabled without a callback', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      String? got;
      await pump(
        tester,
        Column(
          children: [
            Fluent2TextField(
              label: 'Project name',
              hint: 'Northwind launch',
              onChanged: (v) => got = v,
            ),
            const Fluent2TextField(label: 'Workspace', value: 'Northwind'),
          ],
        ),
      );
      await tester.enterText(find.byType(TextField).first, 'Launch');
      expect(got, 'Launch');
      expect(
        tester.getSemantics(find.byType(TextField).first),
        isSemantics(label: 'Project name\nNorthwind launch', isTextField: true),
      );
      expect(
        tester.widget<TextField>(find.byType(TextField).last).enabled,
        isFalse,
      );
      handle.dispose();
    });

    testWidgets('password hides and reveals', (tester) async {
      await pump(
        tester,
        Fluent2TextField(
          label: 'Password',
          value: 'secret',
          password: true,
          onChanged: (_) {},
        ),
      );
      expect(
        tester.widget<TextField>(find.byType(TextField)).obscureText,
        isTrue,
      );
      await tester.tap(find.byIcon(Fluent2Icons.eye));
      await tester.pump();
      expect(
        tester.widget<TextField>(find.byType(TextField)).obscureText,
        isFalse,
      );
    });

    testWidgets("a generated app's hint, obscure and error", (tester) async {
      await pump(
        tester,
        Fluent2TextField(
          label: 'Password',
          hint: 'At least 8 characters',
          obscureText: true,
          validationMessage: 'Too short',
          onChanged: (_) {},
        ),
      );
      expect(find.text('At least 8 characters'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).obscureText,
        isTrue,
      );
      expect(find.text('Too short'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('takes its field label and error', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(
        tester,
        Fluent2FormField(
          label: 'Email',
          required: true,
          helper: 'We send the invite here.',
          validationMessage: 'Enter an email address.',
          child: Fluent2TextField(onChanged: (_) {}),
        ),
      );
      expect(find.text('We send the invite here.'), findsOneWidget);
      expect(find.text('Enter an email address.'), findsOneWidget);
      expect(
        tester.getSemantics(find.byType(TextField)),
        isSemantics(label: 'Email, required', isTextField: true),
      );
      handle.dispose();
    });

    testWidgets('textarea grows with its words', (tester) async {
      String? got;
      await pump(
        tester,
        Fluent2TextArea(label: 'Notes', onChanged: (v) => got = v),
      );
      final before = tester.getSize(find.byType(Fluent2TextArea)).height;
      await tester.enterText(find.byType(TextField), 'one\ntwo\nthree\nfour');
      await tester.pump();
      expect(got, 'one\ntwo\nthree\nfour');
      expect(
        tester.getSize(find.byType(Fluent2TextArea)).height,
        greaterThan(before),
      );
    });

    testWidgets('search box clears', (tester) async {
      var value = '';
      await pump(
        tester,
        StatefulBuilder(
          builder: (context, set) => Fluent2SearchBox(
            value: value,
            hint: 'Search files',
            onChanged: (v) => set(() => value = v),
          ),
        ),
      );
      expect(find.bySemanticsLabel('Clear search'), findsNothing);
      await tester.enterText(find.byType(TextField), 'deck');
      await tester.pump();
      expect(value, 'deck');
      await tester.tap(find.byIcon(Fluent2Icons.dismiss));
      await tester.pump();
      expect(value, '');
    });

    testWidgets('search entry opens search', (tester) async {
      final handle = tester.ensureSemantics();
      var opened = 0;
      var filtered = 0;
      await pump(
        tester,
        Fluent2SearchEntry(
          hint: 'Search Northwind',
          onPressed: () => opened++,
          onFilter: () => filtered++,
        ),
      );
      await tester.tap(find.text('Search Northwind'));
      expect(opened, 1);
      await tester.tap(find.byIcon(Fluent2Icons.filter));
      expect(filtered, 1);
      expect(
        tester.getSemantics(find.text('Search Northwind')),
        isSemantics(isButton: true, hint: 'Opens search'),
      );
      handle.dispose();
    });
  });

  group('dropdown', () {
    const options = [
      Fluent2Option('general', 'General'),
      Fluent2Option('design', 'Design'),
      Fluent2Option('archive', 'Archive', enabled: false),
    ];

    for (final size in const [Size(390, 844), desktop]) {
      testWidgets('chooses an option at ${size.width.toInt()}', (tester) async {
        String? value;
        await pump(
          tester,
          StatefulBuilder(
            builder: (context, set) => Fluent2Select<String>(
              label: 'Channel',
              prompt: 'Choose a channel',
              options: options,
              value: value,
              onChanged: (v) => set(() => value = v),
            ),
          ),
          size: size,
        );
        await tester.tap(find.text('Choose a channel'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Archive').last);
        await tester.pumpAndSettle();
        expect(value, isNull);
        await tester.tap(find.text('Design').last);
        await tester.pumpAndSettle();
        expect(value, 'design');
        expect(find.text('Design'), findsOneWidget);
      });
    }

    testWidgets('disabled does not open', (tester) async {
      await pump(
        tester,
        const Fluent2Select<String>(
          label: 'Channel',
          options: options,
          value: 'general',
          onChanged: null,
        ),
        size: desktop,
      );
      await tester.tap(find.text('General'));
      await tester.pumpAndSettle();
      expect(find.text('Design'), findsNothing);
    });

    testWidgets('combobox filters what is typed', (tester) async {
      String? value;
      await pump(
        tester,
        StatefulBuilder(
          builder: (context, set) => Fluent2Combobox<String>(
            label: 'Room',
            options: const [
              Fluent2Option('fjord', 'Fjord room'),
              Fluent2Option('harbor', 'Harbor room'),
            ],
            value: value,
            onChanged: (v) => set(() => value = v),
          ),
        ),
        size: desktop,
      );
      await tester.enterText(find.byType(TextField), 'har');
      await tester.pumpAndSettle();
      expect(find.text('Fjord room'), findsNothing);
      await tester.tap(find.text('Harbor room'));
      await tester.pumpAndSettle();
      expect(value, 'harbor');
    });

    testWidgets('says so when no option fits the words', (tester) async {
      await pump(
        tester,
        Fluent2Combobox<String>(
          label: 'Room',
          options: const [Fluent2Option('fjord', 'Fjord room')],
          value: null,
          onChanged: (_) {},
        ),
        size: desktop,
      );
      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pumpAndSettle();
      expect(find.text('Fjord room'), findsNothing);
      expect(find.text('No results'), findsOneWidget);
    });
  });

  group('tag picker', () {
    testWidgets('adds, removes by press and by Backspace', (tester) async {
      var picked = <String>['Kai'];
      await pump(
        tester,
        StatefulBuilder(
          builder: (context, set) => Fluent2MultiSelect<String>(
            label: 'Invite',
            options: const [
              Fluent2Option('Kai', 'Kai Tanaka'),
              Fluent2Option('Mara', 'Mara Okafor'),
              Fluent2Option('Noor', 'Noor Haddad'),
            ],
            selected: picked,
            onChanged: (v) => set(() => picked = v),
          ),
        ),
        size: desktop,
      );
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();
      expect(find.text('Kai Tanaka'), findsOneWidget);
      await tester.tap(find.text('Mara Okafor'));
      await tester.pumpAndSettle();
      expect(picked, ['Kai', 'Mara']);
      await tester.tap(find.text('Kai Tanaka'));
      await tester.pumpAndSettle();
      expect(picked, ['Mara']);
      // Backspace in the empty input steps onto the last tag; a second
      // takes it away and hands the keyboard back to the input.
      await tester.tap(find.byType(TextField));
      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pumpAndSettle();
      expect(picked, ['Mara']);
      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pumpAndSettle();
      expect(picked, isEmpty);
    });

    testWidgets('each tag is a remove button with a Remove action', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pump(
        tester,
        Fluent2MultiSelect<String>(
          label: 'Invite',
          options: const [Fluent2Option('Kai', 'Kai Tanaka')],
          selected: const ['Kai'],
          onChanged: (_) {},
        ),
        size: desktop,
      );
      expect(
        tester.getSemantics(find.text('Kai Tanaka')),
        isSemantics(label: 'Remove Kai Tanaka', isButton: true),
      );
      handle.dispose();
    });

    testWidgets('disabled is inert', (tester) async {
      await pump(
        tester,
        const Fluent2MultiSelect<String>(
          label: 'Owners',
          options: [Fluent2Option('Ines', 'Ines Duarte')],
          selected: ['Ines'],
          onChanged: null,
        ),
      );
      await tester.tap(find.text('Ines Duarte'));
      await tester.pumpAndSettle();
      expect(find.text('Ines Duarte'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('link', () {
    testWidgets('is a link, follows on a press, disabled inert', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      var opened = 0;
      await pump(
        tester,
        Column(
          children: [
            Fluent2Link('Open the brief', onPressed: () => opened++),
            const Fluent2Link('Archived', onPressed: null),
          ],
        ),
      );
      await tester.tap(find.text('Open the brief'));
      expect(opened, 1);
      expect(
        tester.getSemantics(find.text('Open the brief')),
        isSemantics(label: 'Open the brief', isLink: true, hasTapAction: true),
      );
      expect(
        tester.getSemantics(find.text('Archived')),
        isSemantics(isLink: true, hasTapAction: false),
      );
      handle.dispose();
    });
  });

  group('field', () {
    testWidgets('label, required, info, validation states', (tester) async {
      await pump(
        tester,
        Column(
          children: [
            Fluent2FormField(
              label: 'Retention',
              info: 'Files in the bin are deleted after 30 days.',
              validationMessage: 'Already taken.',
              validationState: Fluent2ValidationState.warning,
              child: Fluent2TextField(onChanged: (_) {}),
            ),
            const Fluent2Label('Email', required: true),
          ],
        ),
        size: desktop,
      );
      expect(find.text('Already taken.'), findsOneWidget);
      expect(find.byIcon(Fluent2Icons.warningFilled), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Information about Retention'));
      await tester.pumpAndSettle();
      expect(
        find.text('Files in the bin are deleted after 30 days.'),
        findsOneWidget,
      );
    });

    testWidgets('horizontal falls back to vertical on a phone at 1.3', (
      tester,
    ) async {
      await pump(
        tester,
        Fluent2FormSection(
          title: 'Notifications',
          description: 'How Northwind reaches you about files and chats.',
          children: [
            Fluent2FormField(
              label: 'A long display name label for the workspace',
              orientation: Fluent2FieldOrientation.horizontal,
              child: Fluent2TextField(onChanged: (_) {}),
            ),
            const Fluent2InfoLabel('Retention', info: 'Thirty days.'),
          ],
        ),
        textScale: 1.3,
      );
      expect(find.text('Notifications'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('date', () {
    final today = DateTime(2026, 11, 4);

    testWidgets('calendar chooses a day, steps months, keeps its range', (
      tester,
    ) async {
      DateTime? value;
      await pump(
        tester,
        StatefulBuilder(
          builder: (context, set) => Fluent2Calendar(
            value: value,
            today: today,
            firstDate: today,
            onChanged: (d) => set(() => value = d),
          ),
        ),
      );
      expect(find.text('November 2026'), findsOneWidget);
      await tester.tap(find.text('12').first);
      await tester.pump();
      expect(value, DateTime(2026, 11, 12));
      await tester.tap(find.text('3').first);
      await tester.pump();
      expect(value, DateTime(2026, 11, 12));
      await tester.tap(find.bySemanticsLabel('Next month'));
      await tester.pump();
      expect(find.text('December 2026'), findsOneWidget);
    });

    testWidgets('calendar is one tab stop the arrows walk', (tester) async {
      DateTime? value = DateTime(2026, 11, 12);
      await pump(
        tester,
        StatefulBuilder(
          builder: (context, set) => Fluent2Calendar(
            value: value,
            today: today,
            onChanged: (d) => set(() => value = d),
          ),
        ),
      );
      for (var i = 0; i < 4; i++) {
        if (FocusManager.instance.primaryFocus?.debugLabel ==
            'DesignCalendar') {
          break;
        }
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
      }
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'DesignCalendar');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(value, DateTime(2026, 11, 20));
      await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
      await tester.pump();
      expect(find.text('December 2026'), findsOneWidget);
    });

    for (final size in const [Size(390, 844), desktop]) {
      testWidgets('date picker opens and chooses at ${size.width.toInt()}', (
        tester,
      ) async {
        DateTime? value;
        await pump(
          tester,
          StatefulBuilder(
            builder: (context, set) => Fluent2DatePicker(
              label: 'Due date',
              value: value,
              today: today,
              onChanged: (d) => set(() => value = d),
            ),
          ),
          size: size,
        );
        await tester.tap(find.text('Select a date...'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('20').last);
        await tester.pumpAndSettle();
        expect(value, DateTime(2026, 11, 20));
        expect(find.text('Nov 20, 2026'), findsOneWidget);
        expect(find.text('November 2026'), findsNothing);
      });
    }

    testWidgets('date picker disabled does not open', (tester) async {
      await pump(
        tester,
        Fluent2DatePicker(label: 'Due', value: today, onChanged: null),
        size: desktop,
      );
      await tester.tap(find.text('Nov 4, 2026'));
      await tester.pumpAndSettle();
      expect(find.text('November 2026'), findsNothing);
    });
  });

  group('composer', () {
    testWidgets('sends the draft and clears; empty send is disabled', (
      tester,
    ) async {
      final sent = <String>[];
      await pump(
        tester,
        Fluent2Composer(onSend: sent.add, onAttach: () {}, onEmoji: () {}),
      );
      await tester.tap(find.bySemanticsLabel('Send'));
      expect(sent, isEmpty);
      await tester.enterText(find.byType(TextField), '  See you at ten  ');
      await tester.pump();
      await tester.tap(find.byIcon(Fluent2Icons.sendFilled));
      await tester.pump();
      expect(sent, ['See you at ten']);
      expect(find.text('See you at ten'), findsNothing);
    });

    testWidgets('Enter sends on a desktop', (tester) async {
      final sent = <String>[];
      await pump(tester, Fluent2Composer(onSend: sent.add), size: desktop);
      await tester.enterText(find.byType(TextField), 'Ship it');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(sent, ['Ship it']);
    });

    testWidgets('assistant style and disabled', (tester) async {
      await pump(
        tester,
        const Column(
          children: [
            Fluent2Composer(
              style: Fluent2ComposerAppearance.assistant,
              onSend: null,
              label: 'Ask',
            ),
          ],
        ),
      );
      expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
    });
  });

  testWidgets('the whole group fits the phone at text scale 1.3', (
    tester,
  ) async {
    await pump(
      tester,
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          Fluent2Checkbox(
            value: true,
            label: 'Share with every team in the Northwind workspace',
            onChanged: (_) {},
          ),
          Fluent2Switch(
            value: true,
            label: 'Mute the Design channel for an hour',
            labelPosition: Fluent2LabelPosition.before,
            onChanged: (_) {},
          ),
          Fluent2SegmentedButton<String>(
            label: 'Files',
            segments: const [
              Fluent2ButtonSegment(
                'all',
                'All files',
                icon: Fluent2Icons.document,
              ),
              Fluent2ButtonSegment(
                'shared',
                'Shared with me',
                icon: Fluent2Icons.people,
              ),
              Fluent2ButtonSegment(
                'starred',
                'Starred',
                icon: Fluent2Icons.star,
              ),
            ],
            value: 'all',
            onChanged: (_) {},
          ),
          Fluent2Slider(
            label: 'Keep deleted files',
            value: 30,
            valueLabel: (v) => '${v.round()} days',
            onChanged: (_) {},
          ),
          Fluent2SpinButton(label: 'Seats', value: 6, onChanged: (_) {}),
          Fluent2Rating(label: 'Rate', value: 3, onChanged: (_) {}),
          const Fluent2RatingDisplay(
            value: 4.5,
            count: 1160,
            size: Fluent2RatingSize.extraLarge,
          ),
          Fluent2TextField(
            label: 'Email',
            password: true,
            value: 'x',
            onChanged: (_) {},
          ),
          Fluent2SearchEntry(
            hint: 'Search Northwind',
            query: 'launch deck review notes',
            onPressed: () {},
            onFilter: () {},
          ),
          Fluent2Select<String>(
            label: 'Room',
            options: const [
              Fluent2Option('h', 'Harbor room, third floor, east wing'),
            ],
            value: 'h',
            onChanged: (_) {},
          ),
          Fluent2MultiSelect<String>(
            label: 'Invite',
            options: const [
              Fluent2Option('a', 'Tomas Lindqvist'),
              Fluent2Option('b', 'Priya Raman'),
              Fluent2Option('c', 'Noor Haddad'),
            ],
            selected: const ['a', 'b', 'c'],
            onChanged: (_) {},
          ),
          Fluent2DatePicker(
            label: 'Due',
            value: DateTime(2026, 11, 4),
            onChanged: (_) {},
          ),
          Fluent2Calendar(
            value: DateTime(2026, 11, 12),
            today: DateTime(2026, 11, 4),
            onChanged: (_) {},
          ),
          Fluent2Composer(onSend: (_) {}, onAttach: () {}, onEmoji: () {}),
        ],
      ),
      textScale: 1.3,
    );
    expect(tester.takeException(), isNull);
  });

  test('the group\'s colour pairs hold the floors in every preset', () {
    final failures = <String>[];
    for (final id in Fluent2ThemeData.presets) {
      for (final b in Brightness.values) {
        final t = Fluent2ThemeData.preset(id, b);
        final c = t.colors;
        final s = t.sharedColors;
        final pairs = <(String, Color, Color, double)>[
          for (final (g, ground) in [
            ('surface', t.surface),
            ('page', t.background),
          ]) ...[
            ('underline placeholder on $g', c.neutralForeground3, ground, 4.5),
            ('error words on $g', s.paletteRedForeground1, ground, 4.5),
            ('required mark on $g', s.paletteRedForeground1, ground, 4.5),
            ('warning glyph on $g', s.paletteDarkOrangeForeground1, ground, 3),
            ('success glyph on $g', s.paletteGreenForeground1, ground, 3),
            ('error stroke on $g', s.paletteRedBorder2, ground, 3),
            ('field bottom on $g', c.neutralStrokeAccessible, ground, 3),
            ('brand underline on $g', c.compoundBrandStroke, ground, 3),
            ('link on $g', c.brandForegroundLink, ground, 4.5),
            ('subtle link on $g', c.neutralForeground2Link, ground, 4.5),
            ('rating neutral on $g', c.neutralForeground1, ground, 3),
            ('rating brand on $g', c.brandForeground1, ground, 3),
            ('switch rest edge on $g', c.neutralStrokeAccessible, ground, 3),
            ('checked box on $g', c.compoundBrandBackground, ground, 3),
          ],
          (
            'marigold star or its edge on surface',
            Fluent2ThemeData.contrast(
                      s.paletteMarigoldBorderActive,
                      t.surface,
                    ) >=
                    3
                ? s.paletteMarigoldBorderActive
                : s.paletteMarigoldForeground2,
            t.surface,
            3,
          ),
          (
            'placeholder on outline',
            c.neutralForeground4,
            c.neutralBackground1,
            4.5,
          ),
          (
            'placeholder on filled darker',
            c.neutralForeground4,
            c.neutralBackground3,
            4.5,
          ),
          (
            'segment words on track',
            c.neutralForeground2,
            c.neutralBackground3,
            4.5,
          ),
          (
            'chosen segment words',
            c.neutralForegroundOnBrand,
            c.brandBackground,
            4.5,
          ),
          ('chosen day words', c.brandForeground2, c.brandBackground2, 4.5),
          ('today words', c.neutralForegroundOnBrand, c.brandBackground, 4.5),
          ('tag words', c.neutralForeground2, c.neutralBackground3, 4.5),
          (
            'check and thumb on the brand',
            c.neutralForegroundInverted,
            c.compoundBrandBackground,
            3,
          ),
          (
            'check on the brand hovered',
            c.neutralForegroundInverted,
            c.compoundBrandBackgroundHover,
            3,
          ),
          (
            'option words on popover',
            c.neutralForeground1,
            c.neutralBackground1,
            4.5,
          ),
        ];
        for (final (label, ink, ground, floor) in pairs) {
          final ratio = Fluent2ThemeData.contrast(ink, ground);
          if (ratio < floor) {
            failures.add(
              '$id ${b.name}: $label ${ratio.toStringAsFixed(2)} < $floor',
            );
          }
        }
      }
    }
    expect(failures, isEmpty, reason: failures.join('\n'));
  });
}
