// DesignContrastCheck: words and icons read on what is drawn under them;
// faults under the least Material or Cupertino draws, findings under
// Material's bar.
@Tags(['goldens'])
library;

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core_test/ui_core_test.dart';

import 'package:ui_core_test/guidelines.dart';

String get _flutterRoot =>
    Platform.environment['FLUTTER_ROOT'] ??
    File(Platform.resolvedExecutable)
        .parent
        .parent
        .parent
        .parent
        .parent
        .parent
        .path;

// The Flutter SDK's Roboto and Material's icon font, so words and icons are
// drawn in a typeface, not the test's boxes.
Future<void> _loadFonts() async {
  final fonts = '$_flutterRoot/bin/cache/artifacts/material_fonts';
  final roboto = FontLoader('Roboto');
  for (final weight in ['Regular', 'Bold']) {
    final file = File('$fonts/Roboto-$weight.ttf');
    roboto.addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
  }
  await roboto.load();
  final icons = File('$fonts/MaterialIcons-Regular.otf');
  await (FontLoader('MaterialIcons')
        ..addFont(Future.value(ByteData.sublistView(icons.readAsBytesSync()))))
      .load();
}

const _white = Color(0xFFFFFFFF);
const _night = Color(0xFF121212);

TextStyle _words(Color colour, {double size = 14, bool bold = false}) =>
    TextStyle(
      fontFamily: 'Roboto',
      fontSize: size,
      height: 1.2,
      color: colour,
      fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
    );

final _key = GlobalKey();

Future<void> _pump(
  WidgetTester tester,
  Widget body, {
  Color ground = _white,
}) async {
  tester.view.physicalSize = const Size(600, 400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MediaQuery(
      data: const MediaQueryData(size: Size(600, 400)),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: RepaintBoundary(
          key: _key,
          child: ColoredBox(
            color: ground,
            child: Center(child: body),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

Future<DesignAlignmentReport> _check(
  WidgetTester tester,
  Widget body, {
  Color ground = _white,
  DesignContrastCheck check = const DesignContrastCheck(look: 'Fixture'),
}) async {
  await _pump(tester, body, ground: ground);
  return check.check(_key.currentContext!, runAsync: tester.runAsync);
}

void main() {
  setUpAll(_loadFonts);

  testWidgets('words under 2.6:1 are a fault, named with their colours', (
    tester,
  ) async {
    final report = await _check(
      tester,
      Text('Stop the timer', style: _words(const Color(0xFF1F3A68))),
      ground: _night,
    );
    expect(report.problems, [
      allOf(
        contains('words "Stop the timer" (14.0 px): #1f3a68 on #121212 reads'),
        contains('under 2.6:1'),
      ),
    ]);
    expect(report.verify, throwsA(isA<DesignAlignmentError>()));
  });

  testWidgets("words under Material's 4.5:1 are a finding, not a fault", (
    tester,
  ) async {
    // Cupertino's secondaryLabel on white: 3.43:1.
    final report = await _check(
      tester,
      Text('Fieldwork Studio', style: _words(const Color(0xFF8A8A8E))),
    );
    expect(report.problems, isEmpty);
    expect(report.advisories, [
      allOf(
        contains('words "Fieldwork Studio"'),
        contains("under Material's 4.5:1"),
      ),
    ]);
    report.verify();
  });

  testWidgets('words that read at 4.5:1 are neither', (tester) async {
    final report = await _check(
      tester,
      Text('Today', style: _words(const Color(0xFF595959))),
    );
    expect(report.problems, isEmpty);
    expect(report.advisories, isEmpty);
  });

  testWidgets('large words are held to 3:1, small ones to 4.5:1', (
    tester,
  ) async {
    const grey = Color(0xFF888888); // 3.54:1 on white
    final large = await _check(
      tester,
      Text('01:42', style: _words(grey, size: 26)),
    );
    expect(large.advisories, isEmpty);
    final bold = await _check(
      tester,
      Text('01:42', style: _words(grey, size: 19, bold: true)),
    );
    expect(bold.advisories, isEmpty);
    final small = await _check(
      tester,
      Text('01:42', style: _words(grey, size: 18)),
    );
    expect(small.advisories, [contains('words "01:42"')]);
  });

  testWidgets('an icon is a finding under 3:1 and a fault under 1.9:1', (
    tester,
  ) async {
    const chevron = IconData(0xe15f, fontFamily: 'MaterialIcons');
    final faint = await _check(
      tester,
      const Icon(chevron, size: 24, color: Color(0xFFAEAEB2)), // 2.21:1
    );
    expect(faint.problems, isEmpty);
    expect(faint.advisories, [
      allOf(contains('an icon'), contains("under Material's 3:1")),
    ]);
    final gone = await _check(
      tester,
      const Icon(chevron, size: 24, color: Color(0xFFDDDDDD)), // 1.36:1
    );
    expect(gone.problems, [
      allOf(contains('an icon'), contains('under 1.9:1')),
    ]);
  });

  testWidgets(
    'a separator alone is held as an icon is, words with it are not',
    (tester) async {
      const faint = Color(0xFFAAAAAA); // 2.32:1 on white
      final dot = await _check(
        tester,
        Text('·', style: _words(faint, size: 20)),
      );
      expect(dot.problems, isEmpty);
      expect(dot.advisories, [
        allOf(contains('a separator "·"'), contains("under Material's 3:1")),
      ]);
      final words = await _check(
        tester,
        Text('Nov 20 · Field guide', style: _words(faint)),
      );
      expect(words.problems, [contains('words "Nov 20 · Field guide"')]);
      final gone = await _check(
        tester,
        Text('/', style: _words(const Color(0xFFDDDDDD), size: 20)), // 1.36:1
      );
      expect(gone.problems, [
        allOf(contains('a separator "/"'), contains('under 1.9:1')),
      ]);
    },
  );

  testWidgets("a hint is held to 1.7:1, under Cupertino's placeholder", (
    tester,
  ) async {
    final controller = TextEditingController();
    final focus = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focus.dispose);
    Widget field(Color hint) => SizedBox(
      width: 240,
      height: 24,
      child: Stack(
        children: [
          EditableText(
            controller: controller,
            focusNode: focus,
            style: _words(const Color(0xFF000000)),
            cursorColor: const Color(0xFF000000),
            backgroundCursorColor: const Color(0xFF888888),
          ),
          IgnorePointer(child: Text('Search tasks', style: _words(hint))),
        ],
      ),
    );
    // 2.0:1: over the floor for a hint, under it for words.
    const faint = Color(0xFFB7B7B7);
    final hint = await _check(tester, field(faint));
    expect(hint.problems, isEmpty);
    expect(hint.advisories, [contains('a hint "Search tasks"')]);
    final words = await _check(
      tester,
      Text('Search tasks', style: _words(faint)),
    );
    expect(words.problems, [contains('under 2.6:1')]);
    // 1.35:1: under the floor for a hint too.
    final gone = await _check(tester, field(const Color(0xFFDDDDDD)));
    expect(gone.problems, [
      allOf(contains('a hint "Search tasks"'), contains('under 1.7:1')),
    ]);
  });

  testWidgets('words in a layer of their own read on the ground under it', (
    tester,
  ) async {
    // A list paints each row in a repaint boundary of its own, which holds
    // the words but not the page under them.
    final report = await _check(
      tester,
      SizedBox(
        width: 300,
        height: 120,
        child: ListView(
          children: [
            Text('Open studio', style: _words(const Color(0xFF191C20))),
            Text('Field guide', style: _words(const Color(0xFF44474E))),
          ],
        ),
      ),
    );
    expect(report.problems, isEmpty);
    expect(report.advisories, isEmpty);
  });

  testWidgets('a large hint is held to 3:1, as large words are', (
    tester,
  ) async {
    final controller = TextEditingController();
    final focus = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focus.dispose);
    final report = await _check(
      tester,
      SizedBox(
        width: 300,
        height: 34,
        child: Stack(
          children: [
            EditableText(
              controller: controller,
              focusNode: focus,
              style: _words(const Color(0xFF000000), size: 26),
              cursorColor: const Color(0xFF000000),
              backgroundCursorColor: const Color(0xFF888888),
            ),
            IgnorePointer(
              child: Text(
                'Amount',
                style: _words(const Color(0xFF888888), size: 26),
              ),
            ),
          ],
        ),
      ),
    );
    expect(report.problems, isEmpty);
    expect(report.advisories, isEmpty);
  });

  testWidgets('a ratio just under a level is never printed as the level', (
    tester,
  ) async {
    // 2.9958:1, which rounds to 3.00.
    final report = await _check(
      tester,
      Text('Due soon', style: _words(const Color(0xFF959595))),
    );
    expect(report.advisories, [contains('reads 2.99:1')]);
  });

  testWidgets("words in their ground's own colour are a fault, not hidden", (
    tester,
  ) async {
    final report = await _check(
      tester,
      Text('Save changes', style: _words(_white)),
    );
    expect(report.problems, [
      allOf(contains('words "Save changes"'), contains('reads 1.00:1')),
    ]);
  });

  testWidgets('words in a transparent colour are left out', (tester) async {
    final report = await _check(
      tester,
      Text('Reserved room', style: _words(const Color(0x00000000))),
    );
    expect(report.problems, isEmpty);
    expect(report.advisories, isEmpty);
  });

  testWidgets(
    'words over a ground the boundary holds translucent are left out',
    (tester) async {
      // A dialog's surface read without the page behind it.
      for (final ground in const [Color(0x00000000), Color(0xCCF2F2F2)]) {
        final report = await _check(
          tester,
          Text('Cancel', style: _words(const Color(0xFF007AFF))),
          ground: ground,
        );
        expect(report.problems, isEmpty, reason: '$ground');
        expect(report.advisories, isEmpty, reason: '$ground');
      }
    },
  );

  testWidgets("a button whose own focus can't be taken is off", (tester) async {
    const faint = Color(0xFFDDDDDD); // 1.35:1
    Widget send() => Text('Send', style: _words(faint));
    // A disabled CupertinoButton: its focus round its semantics.
    final cupertino = await _check(
      tester,
      Focus(
        canRequestFocus: false,
        child: Semantics(button: true, onTap: () {}, child: send()),
      ),
    );
    expect(cupertino.problems, isEmpty);
    expect(cupertino.advisories, isEmpty);
    // A disabled DropdownButton: its focus inside its semantics.
    final dropdown = await _check(
      tester,
      Semantics(
        button: true,
        child: Focus(canRequestFocus: false, child: send()),
      ),
    );
    expect(dropdown.problems, isEmpty);
    // A CupertinoDialogAction: a live button with no focus of its own.
    final action = await _check(
      tester,
      Semantics(button: true, onTap: () {}, child: send()),
    );
    expect(action.problems, [contains('words "Send"')]);
    // A focus that can't be taken round words, no button.
    final bare = await _check(
      tester,
      Focus(canRequestFocus: false, child: send()),
    );
    expect(bare.problems, [contains('words "Send"')]);
    // A live button in a field that takes no focus itself
    // (DropdownButtonFormField): the nearest focus says.
    final field = await _check(
      tester,
      Focus(
        canRequestFocus: false,
        child: Semantics(button: true, child: Focus(child: send())),
      ),
    );
    expect(field.problems, [contains('words "Send"')]);
    // A focus off round a semantics boundary a live button stands in.
    final page = await _check(
      tester,
      Focus(
        canRequestFocus: false,
        child: Semantics(
          explicitChildNodes: true,
          child: Semantics(button: true, onTap: () {}, child: send()),
        ),
      ),
    );
    expect(page.problems, [contains('words "Send"')]);
    // A disabled DropdownButton's arrow: beside its item's button semantics,
    // under the focus that holds them.
    final arrow = await _check(
      tester,
      Focus(
        canRequestFocus: false,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(button: true, child: send()),
            Text('▾', style: _words(faint)),
          ],
        ),
      ),
    );
    expect(arrow.problems, isEmpty);
    // Words beside live controls, under a focus that holds their focuses.
    final shortcuts = await _check(
      tester,
      Focus(
        canRequestFocus: false,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Title', style: _words(faint)),
            Semantics(button: true, child: Focus(child: send())),
          ],
        ),
      ),
    );
    expect(shortcuts.problems, [
      contains('words "Title"'),
      contains('words "Send"'),
    ]);
    // A focus off round a page: the buttons its boundary holds are not the
    // focus's own.
    final route = await _check(
      tester,
      Focus(
        canRequestFocus: false,
        child: Semantics(
          explicitChildNodes: true,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(button: true, onTap: () {}, child: send()),
              Text('Title', style: _words(faint)),
            ],
          ),
        ),
      ),
    );
    expect(route.problems, [
      contains('words "Send"'),
      contains('words "Title"'),
    ]);
  });

  test('a floor above its bar is a mistake', () {
    expect(
      () => DesignContrastCheck(look: 'Fixture', wordsFloor: 5),
      throwsAssertionError,
    );
    expect(
      () => DesignContrastCheck(look: 'Fixture', iconsFloor: 3.5),
      throwsAssertionError,
    );
    expect(
      () => DesignContrastCheck(look: 'Fixture', hintFloor: 4.6),
      throwsAssertionError,
    );
    expect(
      () => DesignContrastCheck(
        look: 'Fixture',
        wordsFloor: 1,
        largeWordsBar: 1.5,
      ),
      throwsAssertionError,
    );
  });

  testWidgets('a level is named as it is set', (tester) async {
    final report = await _check(
      tester,
      Text('Due soon', style: _words(const Color(0xFFA0A0A0))),
      check: const DesignContrastCheck(look: 'Fixture', wordsFloor: 2.65),
    );
    expect(report.problems, [contains('under 2.65:1')]);
    expect(report.problems, [contains('words outside a text entry')]);
  });

  testWidgets("one word in the test's own font gives that problem, not 1:1", (
    tester,
  ) async {
    final report = await _check(
      tester,
      const Text(
        'Cancel',
        style: TextStyle(
          fontFamily: 'NotLoaded',
          fontSize: 14,
          color: Color(0xFF007AFF),
        ),
      ),
    );
    expect(report.problems, [contains("the test's own font")]);
  });

  testWidgets("a disabled control's words are left out", (tester) async {
    final report = await _check(
      tester,
      Semantics(
        enabled: false,
        button: true,
        child: Text('Save changes', style: _words(const Color(0xFFE4E4E4))),
      ),
    );
    expect(report.problems, isEmpty);
    expect(report.advisories, isEmpty);
  });

  testWidgets('words are read through the opacity they are drawn at', (
    tester,
  ) async {
    final report = await _check(
      tester,
      Opacity(
        opacity: 0.45,
        child: Text('Later this week', style: _words(const Color(0xFF000000))),
      ),
    );
    expect(report.advisories, [contains('words "Later this week"')]);
  });

  testWidgets('words over a ground of many colours are left out', (
    tester,
  ) async {
    final report = await _check(
      tester,
      DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF000000), Color(0xFFFFFFFF), Color(0xFF0000FF)],
          ),
        ),
        child: Text('Over a picture', style: _words(const Color(0xFF777777))),
      ),
    );
    expect(report.problems, isEmpty);
    expect(report.advisories, isEmpty);
  });

  testWidgets('words painted over are left out', (tester) async {
    final report = await _check(
      tester,
      Stack(
        children: [
          Text('Hidden', style: _words(const Color(0xFFEEEEEE))),
          const Positioned.fill(child: ColoredBox(color: _white)),
        ],
      ),
    );
    expect(report.problems, isEmpty);
    expect(report.advisories, isEmpty);
  });

  testWidgets("words in the test's own font give that one problem", (
    tester,
  ) async {
    final report = await _check(
      tester,
      const Text(
        'Unloaded face',
        style: TextStyle(
          fontFamily: 'NotLoaded',
          fontSize: 14,
          color: Color(0xFFE0E0E0),
        ),
      ),
    );
    expect(report.problems, [contains("the test's own font")]);
  });

  testWidgets('sweep reads each palette by day and by night, headed', (
    tester,
  ) async {
    final shown = <String>[];
    final report = await const DesignContrastCheck(look: 'Fixture').sweep(
      show: (palette, brightness) async {
        shown.add('${palette?.name}/${brightness.name}');
        final dark = brightness == Brightness.dark;
        await _pump(
          tester,
          Text(
            'Stop',
            style: _words(
              palette?.accent ?? (dark ? _white : const Color(0xFF000000)),
            ),
          ),
          ground: dark ? _night : (palette?.neutral ?? _white),
        );
      },
      screen: () => _key.currentContext!,
      runAsync: tester.runAsync,
    );
    expect(shown, hasLength(12));
    expect(
      shown,
      containsAll(['null/light', 'null/dark', 'pastel + cream/dark']),
    );
    expect(
      report.problems,
      contains(startsWith('navy + white, night: words "Stop"')),
    );
    expect(
      report.problems.where((p) => p.startsWith('its own palette')),
      isEmpty,
    );
  });

  test('the briefs are the five palettes people name most', () {
    expect(DesignPalette.briefs, hasLength(5));
    expect(DesignPalette.briefs.map((p) => p.accent.toARGB32()), [
      0xFF1F3A68,
      0xFF2E7D32,
      0xFFC9A227,
      0xFF6D28D9,
      0xFFF4A7B9,
    ]);
    expect(DesignPalette.purple.neutral, isNull);
    expect(DesignPalette.blackAndGold.neutral, const Color(0xFF111111));
  });

  testWidgets('as a guideline it fails on faults alone', (tester) async {
    await _pump(
      tester,
      Text('Fieldwork Studio', style: _words(const Color(0xFF8A8A8E))),
    );
    await expectLater(tester, meetsGuideline(contrastFloorGuideline));
    await _pump(
      tester,
      Text('Stop', style: _words(const Color(0xFF1F3A68))),
      ground: _night,
    );
    final handle = tester.ensureSemantics();
    final result = await contrastFloorGuideline.evaluate(tester);
    handle.dispose();
    expect(result.passed, isFalse);
    expect(result.reason, contains('under 2.6:1'));
  });
}
