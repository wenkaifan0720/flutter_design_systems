// Track opening, closing and focus restoration across window widths, themes and text directions.
// Set STUDIO_TRANSITION_FRAMES to save the frames from each transition.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_ui/studio_ui.dart';

Future<void> _loadFonts() async {
  final manifest = json.decode(
    await rootBundle.loadString('FontManifest.json'),
  ) as List<dynamic>;
  for (final entry in manifest.cast<Map<String, dynamic>>()) {
    final family = entry['family'] as String;
    final loader = FontLoader(
      family.startsWith('packages/') ? family : studioRegisteredFamily(family),
    );
    for (final font
        in (entry['fonts'] as List<dynamic>).cast<Map<String, dynamic>>()) {
      loader.addFont(rootBundle.load(font['asset'] as String));
    }
    await loader.load();
  }
}

final String? _out = Platform.environment['STUDIO_TRANSITION_FRAMES'];

Future<void> _shot(WidgetTester tester, String name) async {
  final out = _out;
  if (out == null) return;
  final view = tester.binding.renderViews.first;
  final layer = view.debugLayer! as OffsetLayer;
  final size = view.size;
  await tester.runAsync(() async {
    final image = await layer.toImage(Offset.zero & size);
    try {
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      Directory(out).createSync(recursive: true);
      File('$out/$name.png').writeAsBytesSync(png!.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  });
}

const _places = [
  StudioDestination(icon: Icon(LucideIcons.house), label: 'Home'),
  StudioDestination(icon: Icon(LucideIcons.library), label: 'Library'),
  StudioDestination(icon: Icon(LucideIcons.mic), label: 'Record'),
];

// The bench: an app with its places, and on its page the keys that open
// each part, the tabs, a wheel, a rating and a search field.
class _Bench extends StatefulWidget {
  const _Bench();

  @override
  State<_Bench> createState() => _BenchState();
}

class _BenchState extends State<_Bench> {
  int place = 0;
  int tab = 0;
  int takes = 2;
  int stars = 3;
  StudioTime time = const StudioTime(hour: 19, minute: 30);

  @override
  Widget build(BuildContext context) => StudioScaffold(
    destinations: _places,
    selectedIndex: place,
    onDestinationSelected: (i) => setState(() => place = i),
    appBar: StudioAppBar(
      title: 'Bench',
      bottom: StudioTabBar(
        tabs: const ['Notes', 'Chapters', 'Transcript'],
        selectedIndex: tab,
        onChanged: (i) => setState(() => tab = i),
      ),
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          StudioButton(
            'Dialog',
            onPressed: () => showStudioDialog<void>(
              context: context,
              isAlert: true,
              builder: (context) => StudioDialog(
                title: 'Discard this take?',
                content: const Text('The 7 minutes you recorded will be gone.'),
                actions: [
                  StudioButton(
                    'Keep',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  StudioButton.lit(
                    'Discard',
                    isDestructiveAction: true,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ),
          StudioButton(
            'Sheet',
            onPressed: () => showStudioBottomSheet<void>(
              context: context,
              title: 'Export',
              builder: (context) => const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('MP3, 128 kbps'),
              ),
            ),
          ),
          StudioButton(
            'Actions',
            onPressed: () => showStudioActionSheet<String>(
              context: context,
              title: 'Take 3',
              actions: const [
                StudioSheetAction(label: 'Rename', value: 'rename'),
                StudioSheetAction(
                  label: 'Delete',
                  value: 'delete',
                  isDestructiveAction: true,
                ),
              ],
            ),
          ),
          StudioButton(
            'Side',
            onPressed: () => showStudioSideSheet<void>(
              context: context,
              title: 'Details',
              builder: (context) => const Text('Recorded 12 May'),
            ),
          ),
          StudioTooltip(
            message: 'Add a marker',
            child: StudioIconButton(
              icon: const Icon(LucideIcons.bookmarkPlus),
              tooltip: 'Marker',
              onPressed: () {},
            ),
          ),
          StudioRating(
            value: stars,
            semanticLabel: 'Your rating',
            onChanged: (v) => setState(() => stars = v),
          ),
          StudioWheelPicker<int>(
            items: const [1, 2, 3, 4, 5],
            value: takes,
            labelOf: (n) => 'Take $n',
            semanticLabel: 'Takes',
            onChanged: (n) => setState(() => takes = n),
          ),
          StudioTimePicker(
            value: time,
            onChanged: (t) => setState(() => time = t),
          ),
          SizedBox(
            width: 280,
            child: StudioCombobox<String>(
              labelText: 'Show',
              labelOf: (s) => s,
              search: (query) async {
                await Future<void>.delayed(const Duration(milliseconds: 400));
                throw StateError('offline');
              },
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _app(Brightness brightness, TextDirection direction) => MaterialApp(
  debugShowCheckedModeBanner: false,
  localizationsDelegates: const [
    StudioLocalizations.delegate,
    RawWidgetsLocalizations.delegate,
  ],
  builder: (context, page) => Directionality(
    textDirection: direction,
    child: StudioHost(brightness: brightness, child: page!),
  ),
  home: const _Bench(),
);

typedef _Step = Future<void> Function(WidgetTester tester);

void main() {
  setUpAll(_loadFonts);

  // Each part: how it opens, what shows it is open, how it closes.
  final parts = <String, (_Step, Finder, _Step)>{
    'dialog': (
      (t) => t.tap(find.text('Dialog')),
      find.text('Discard this take?'),
      (t) => t.tap(find.text('Keep')),
    ),
    'sheet': (
      (t) => t.tap(find.text('Sheet')),
      find.text('MP3, 128 kbps'),
      (t) => t.sendKeyEvent(LogicalKeyboardKey.escape),
    ),
    'actions': (
      (t) => t.tap(find.text('Actions')),
      find.text('Rename'),
      (t) => t.tap(find.text('Rename')),
    ),
    'side': (
      (t) => t.tap(find.text('Side')),
      find.text('Recorded 12 May'),
      (t) => t.sendKeyEvent(LogicalKeyboardKey.escape),
    ),
    'tooltip': (
      (t) async {
        final mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
        addTearDown(mouse.removePointer);
        await mouse.addPointer(location: Offset.zero);
        await mouse.moveTo(t.getCenter(find.byType(StudioIconButton)));
        await t.pump(const Duration(milliseconds: 600));
      },
      find.text('Add a marker'),
      (t) => t.sendKeyEvent(LogicalKeyboardKey.escape),
    ),
    'search': (
      (t) async {
        await t.enterText(find.byType(EditableText).last, 'Room');
        await t.pump(const Duration(milliseconds: 100));
      },
      find.text("Couldn't load results"),
      (t) => t.sendKeyEvent(LogicalKeyboardKey.escape),
    ),
  };

  for (final width in const [390.0, 1440.0]) {
    for (final brightness in Brightness.values) {
      for (final direction in TextDirection.values) {
        final tag = '${width.toInt()}_${brightness.name}_${direction.name}';
        for (final MapEntry(key: name, value: (open, shown, close))
            in parts.entries) {
          testWidgets('$name opens and closes at $tag', (tester) async {
            tester.view.physicalSize = Size(width, width < 600 ? 844 : 900);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.reset);
            await tester.pumpWidget(_app(brightness, direction));
            await tester.pumpAndSettle();
            await open(tester);
            await tester.pump();
            await _shot(tester, '${name}_${tag}_1-first');
            await tester.pump(const Duration(milliseconds: 100));
            await _shot(tester, '${name}_${tag}_2-opening');
            await tester.pumpAndSettle();
            expect(shown, findsWidgets, reason: '$name stands open');
            await _shot(tester, '${name}_${tag}_3-open');
            await close(tester);
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 100));
            await _shot(tester, '${name}_${tag}_4-closing');
            await tester.pumpAndSettle();
            expect(shown, findsNothing, reason: '$name closed');
            await _shot(tester, '${name}_${tag}_5-closed');
          });
        }

        testWidgets('tabs, places, wheels and the rating move at $tag', (
          tester,
        ) async {
          tester.view.physicalSize = Size(width, width < 600 ? 844 : 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(_app(brightness, direction));
          await tester.pumpAndSettle();
          await _shot(tester, 'values_${tag}_1-rest');
          await tester.tap(find.text('Chapters'));
          await tester.tap(find.text('Library'));
          final rating = tester.getRect(find.byType(StudioRating));
          final fifth = direction == TextDirection.rtl ? 0.5 : 4.5;
          await tester.tapAt(
            Offset(rating.left + rating.width / 5 * fifth, rating.center.dy),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 60));
          await _shot(tester, 'values_${tag}_2-moving');
          await tester.pumpAndSettle();
          await _shot(tester, 'values_${tag}_3-moved');
          // The keyboard: one Tab to the places, the arrows along them, F6
          // to the page.
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pumpAndSettle();
          await _shot(tester, 'values_${tag}_4-focus');
          await tester.sendKeyEvent(LogicalKeyboardKey.f6);
          await tester.pumpAndSettle();
          await _shot(tester, 'values_${tag}_5-f6');
        });
      }
    }
  }
}
