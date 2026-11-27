import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';
import 'package:fluent2_design_ui/src/fluent2_design/components/input/field_core.dart'
    show Fluent2FieldButton;

Widget _host(
  Widget child, {
  double width = 390,
  double textScale = 1,
  TextDirection direction = TextDirection.ltr,
}) => MediaQuery(
  data: MediaQueryData(
    size: Size(width, 844),
    textScaler: TextScaler.linear(textScale),
  ),
  child: MaterialApp(
    debugShowCheckedModeBanner: false,
    builder: (context, page) => Directionality(
      textDirection: direction,
      child: Fluent2Host(child: page!),
    ),
    home: Builder(
      builder: (context) => ColoredBox(
        color: context.fluent2Theme.background,
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(width: double.infinity, child: child),
          ),
        ),
      ),
    ),
  ),
);

Future<void> _at(WidgetTester tester, double width) async {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Field hit targets, group labels, responsive toolbar actions, and feedback.
void main() {
  for (final width in const [390.0, 1440.0]) {
    testWidgets('a tap on a text field frame focuses it at $width', (
      tester,
    ) async {
      await _at(tester, width);
      await tester.pumpWidget(
        _host(
          width: width,
          Fluent2TextField(value: '', hintText: 'Name', onChanged: (_) {}),
        ),
      );
      final editable = find.byType(EditableText);
      expect(tester.widget<EditableText>(editable).focusNode.hasFocus, isFalse);
      // Inside the frame, past the line of words: its padding by the start.
      final frame = tester.getRect(find.byType(Fluent2TextField));
      final line = tester.getRect(editable);
      final spot = Offset(line.left + 4, frame.top + 2);
      expect(line.contains(spot), isFalse, reason: 'outside the words');
      await tester.tapAt(spot);
      await tester.pump();
      expect(tester.widget<EditableText>(editable).focusNode.hasFocus, isTrue);
    });
  }

  testWidgets('a tag picker beside its tags takes a tap over its whole box', (
    tester,
  ) async {
    await _at(tester, 390);
    await tester.pumpWidget(
      _host(
        Fluent2MultiSelect<String>(
          semanticLabel: 'Invite',
          options: const [
            Fluent2Option('kai', 'Kai Tanaka'),
            Fluent2Option('mara', 'Mara Okafor'),
          ],
          selected: const ['kai'],
          onChanged: (_) {},
        ),
      ),
    );
    final editable = find.byType(EditableText);
    final line = tester.getRect(editable);
    // Above the line of words, still inside the input's box.
    await tester.tapAt(Offset(line.center.dx, line.top - 6));
    await tester.pump();
    expect(tester.widget<EditableText>(editable).focusNode.hasFocus, isTrue);
  });

  testWidgets('a toolbar toggle group chooses one, a toolbar group names', (
    tester,
  ) async {
    var chosen = <String>{'list'};
    await tester.pumpWidget(
      _host(
        StatefulBuilder(
          builder: (context, set) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Fluent2ToolbarToggleGroup<String>(
                semanticLabel: 'Layout',
                toggles: const [
                  Fluent2ToolbarToggle(
                    'list',
                    icon: Fluent2Icons.list,
                    label: 'List',
                  ),
                  Fluent2ToolbarToggle(
                    'grid',
                    icon: Fluent2Icons.grid,
                    label: 'Grid',
                  ),
                ],
                selected: chosen,
                onSelectionChanged: (v) => set(() => chosen = v),
              ),
              Fluent2ToolbarGroup(
                semanticLabel: 'Share',
                items: [
                  Fluent2ToolbarItem.button(
                    icon: Fluent2Icons.link,
                    label: 'Copy link',
                    onPressed: () {},
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.bySemanticsLabel('Grid'));
    await tester.pumpAndSettle();
    expect(chosen, {'grid'});
    expect(find.bySemanticsLabel('Share'), findsOneWidget);
  });

  testWidgets('a hover card opens under the pointer and closes after it', (
    tester,
  ) async {
    await _at(tester, 1440);
    await tester.pumpWidget(
      _host(
        width: 1440,
        Align(
          alignment: AlignmentDirectional.topStart,
          child: Fluent2Popover(
            semanticLabel: 'Mara Okafor',
            openOnHover: true,
            trigger: (context, toggle) =>
                Fluent2Link('Mara Okafor', onPressed: toggle),
            content: const Text('Design lead'),
          ),
        ),
      ),
    );
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(find.text('Mara Okafor')));
    await tester.pump(Fluent2Popover.hoverOpenDelay);
    await tester.pumpAndSettle();
    expect(find.text('Design lead'), findsOneWidget);
    await mouse.moveTo(const Offset(1400, 800));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(find.text('Design lead'), findsNothing);
  });

  testWidgets('a ring with a value says it as a share', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(const Fluent2Spinner(label: 'Storage used', value: .62)),
    );
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(find.byType(Fluent2Spinner)),
      matchesSemantics(label: 'Storage used', value: '62%'),
    );
    handle.dispose();
  });

  testWidgets('the radio dot grows in rather than snapping', (tester) async {
    var value = 'a';
    await tester.pumpWidget(
      _host(
        StatefulBuilder(
          builder: (context, set) => Fluent2RadioGroup<String>(
            value: value,
            onChanged: (v) => set(() => value = v),
            options: const [
              Fluent2Radio('a', 'Daily'),
              Fluent2Radio('b', 'Weekly'),
            ],
          ),
        ),
      ),
    );
    // The scale each dot is drawn at now.
    List<double> drawn() => [
      for (final dot in find.byType(AnimatedScale).evaluate())
        tester
            .widget<Transform>(
              find
                  .descendant(
                    of: find.byWidget(dot.widget),
                    matching: find.byType(Transform),
                  )
                  .first,
            )
            .transform
            .entry(0, 0),
    ];
    expect(drawn(), [1, 0]);
    await tester.tap(find.text('Weekly'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    final [daily, weekly] = drawn();
    expect(daily, inExclusiveRange(0, 1));
    expect(weekly, inExclusiveRange(0, 1));
    await tester.pumpAndSettle();
    expect(drawn(), [0, 1]);
  });

  testWidgets('a form field names a radio group as a group', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(
        Fluent2FormField(
          labelText: 'Email digest',
          child: Fluent2RadioGroup<String>(
            value: 'daily',
            onChanged: (_) {},
            options: const [
              Fluent2Radio('daily', 'Daily'),
              Fluent2Radio('weekly', 'Weekly'),
            ],
          ),
        ),
      ),
    );
    // Each choice keeps a node of its own a screen reader reaches.
    expect(find.bySemanticsLabel('Daily'), findsOneWidget);
    expect(find.bySemanticsLabel('Weekly'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('a phone top bar folds its commands before its name shortens', (
    tester,
  ) async {
    await _at(tester, 390);
    Widget bar(String title, {double textScale = 2}) => _host(
      textScale: textScale,
      SizedBox(
        height: 120,
        child: Fluent2AppBar(
          title: title,
          actions: [
            Fluent2IconButton(
              Fluent2Icons.search,
              semanticLabel: 'Search',
              onPressed: () {},
            ),
            Fluent2IconButton(
              Fluent2Icons.share,
              semanticLabel: 'Share',
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
    final handle = tester.ensureSemantics();
    // At its own size the name leaves the commands their room.
    await tester.pumpWidget(bar('Files', textScale: 1));
    expect(find.bySemanticsLabel('Search'), findsOneWidget);
    expect(find.bySemanticsLabel('More'), findsNothing);
    await tester.pumpWidget(bar('Quarterly planning'));
    expect(find.bySemanticsLabel('Search'), findsNothing);
    expect(find.bySemanticsLabel('More'), findsOneWidget);
    // The menu holds what folded.
    await tester.tap(find.bySemanticsLabel('More'));
    await tester.pumpAndSettle();
    expect(find.text('Search'), findsOneWidget);
    expect(find.text('Share'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('a phone top bar keeps room round a name run to two lines', (
    tester,
  ) async {
    await _at(tester, 390);
    const name = 'Quarterly planning for the operations team';
    await tester.pumpWidget(
      _host(textScale: 2, const Fluent2AppBar(title: name)),
    );
    final bar = tester.getRect(find.byType(Fluent2AppBar));
    final words = tester.getRect(find.text(name));
    // Two lines (the name shrinks whole until it fits them), 8 clear of the
    // bar's top and bottom.
    expect(words.height, greaterThan(1.5 * 22));
    expect(words.top - bar.top, greaterThanOrEqualTo(Fluent2Spacing.s - 0.5));
    expect(
      bar.bottom - words.bottom,
      greaterThanOrEqualTo(Fluent2Spacing.s - 0.5),
    );
  });

  for (final direction in TextDirection.values) {
    testWidgets('a composer moves its commands under a draft past one line '
        '(${direction.name})', (tester) async {
      await _at(tester, 390);
      final text = TextEditingController(text: 'Ship it');
      addTearDown(text.dispose);
      await tester.pumpWidget(
        _host(
          direction: direction,
          Fluent2Composer(
            controller: text,
            onSend: (_) {},
            onAttach: () {},
            onEmoji: () {},
          ),
        ),
      );
      final frame = tester.getRect(find.byType(Fluent2Composer));
      Rect words() => tester.getRect(find.byType(EditableText));
      Rect send() => tester.getRect(find.bySemanticsLabel('Send'));
      Rect attach() => tester.getRect(find.bySemanticsLabel('Attach a file'));
      // One line: words, commands and send on one row.
      expect(send().center.dy, moreOrLessEquals(words().center.dy, epsilon: 1));
      final oneLine = words().width;
      text.text =
          'Mara, can we move the launch review to Thursday? The deck needs '
          'one more pass on the pricing slides before Kai sees it.';
      await tester.pumpAndSettle();
      // Past one line: the words take the row the commands left, the
      // commands and the send on a row under them, at its two ends.
      expect(words().width, greaterThan(oneLine + 80));
      expect(attach().top, greaterThanOrEqualTo(words().bottom - 1));
      expect(send().top, greaterThanOrEqualTo(words().bottom - 1));
      final ltr = direction == TextDirection.ltr;
      expect(
        ltr ? attach().left - frame.left : frame.right - attach().right,
        lessThan(frame.width / 4),
      );
      expect(
        ltr ? frame.right - send().right : send().left - frame.left,
        lessThan(frame.width / 8),
      );
    });
  }

  testWidgets('a section header keeps its aside whole', (tester) async {
    await tester.pumpWidget(
      _host(const Fluent2SectionHeader('Today', aside: '3 meetings')),
    );
    final rich = tester.widget<Text>(find.byType(Text).first);
    expect(rich.textSpan!.toPlainText(), contains('3 meetings'));
  });
  for (final (width, platform) in const [
    (390.0, TargetPlatform.iOS),
    (1440.0, TargetPlatform.macOS),
  ]) {
    testWidgets('a multiline message bar keeps its dismiss on the first line '
        'at $width', (tester) async {
      debugDefaultTargetPlatformOverride = platform;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      await _at(tester, width);
      await tester.pumpWidget(
        _host(
          width: width,
          SizedBox(
            width: 320,
            child: Fluent2MessageBar(
              intent: Fluent2MessageIntent.warning,
              title: 'Storage almost full',
              body:
                  '9.2 GB of 10 GB used. Files stop syncing when the space '
                  'runs out.',
              layout: Fluent2MessageLayout.multiline,
              onDismiss: () {},
            ),
          ),
        ),
      );
      final glyph = tester.getCenter(find.byType(Icon).first).dy;
      final dismiss = tester.getCenter(find.byType(Fluent2IconButton)).dy;
      final words = tester.getRect(find.byType(Text).first);
      expect(dismiss, moreOrLessEquals(glyph, epsilon: 1));
      // The first line's middle: the words' top plus half a 20 line.
      expect(words.top + 10, moreOrLessEquals(glyph, epsilon: 1));
      debugDefaultTargetPlatformOverride = null;
    });
  }
  testWidgets('a form field outlines its select at the select\'s own width '
      'on a wide page', (tester) async {
    await _at(tester, 1440);
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(
        width: 1440,
        SizedBox(
          width: 560,
          child: Fluent2FormField(
            labelText: 'Type',
            child: Fluent2Select<String>(
              options: const [
                Fluent2Option('gear', 'Equipment'),
                Fluent2Option('trip', 'Travel'),
              ],
              value: 'gear',
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );
    final outline = tester.getSemantics(find.byType(Fluent2Select<String>));
    final trigger = tester.getSize(find.byType(Fluent2FieldButton));
    expect(outline.rect.width, moreOrLessEquals(trigger.width, epsilon: 1));
    expect(outline.rect.width, lessThan(560));
    handle.dispose();
  });

  for (final direction in TextDirection.values) {
    testWidgets('a tab row outlines its first tab from the keyline, '
        '${direction.name}', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          direction: direction,
          Fluent2TabList(
            tabs: const ['Recent', 'Shared'],
            selectedIndex: 0,
            onChanged: (_) {},
          ),
        ),
      );
      // A tab says its name, then its place (ui_core's "Tab 1 of 2").
      double width(String name) => tester
          .getSemantics(find.bySemanticsLabel(RegExp('^$name\n')))
          .rect
          .width;
      double drawn(String name) => tester
          .getSize(
            find
                .ancestor(
                  of: find.text(name).last,
                  matching: find.byType(RawButton),
                )
                .first,
          )
          .width;
      // The first tab's inset (10 and the words' 2) hangs over the margin:
      // its outline starts on the keyline; the next tab's is whole.
      expect(width('Recent'), moreOrLessEquals(drawn('Recent') - 12));
      expect(width('Shared'), moreOrLessEquals(drawn('Shared')));
      handle.dispose();
    });
  }
}
