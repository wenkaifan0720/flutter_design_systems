// Keyboard traversal changes the glaze inside the part in both reading directions.
// ignore_for_file: avoid_relative_lib_imports
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gloss_ui/gloss_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../example/lib/kit_gallery/kit.dart';

// Gloss's own faces.
Future<void> _loadFonts() async {
  final manifest = json.decode(
    await rootBundle.loadString('FontManifest.json'),
  ) as List<dynamic>;
  for (final entry in manifest.cast<Map<String, dynamic>>()) {
    final family = entry['family'] as String;
    final loader = FontLoader(
      family.startsWith('packages/') ? family : glossRegisteredFamily(family),
    );
    for (final font
        in (entry['fonts'] as List<dynamic>).cast<Map<String, dynamic>>()) {
      loader.addFont(rootBundle.load(font['asset'] as String));
    }
    await loader.load();
  }
}

final _frame = GlobalKey();

Future<void> _show(
  WidgetTester tester,
  Widget child,
  Brightness brightness,
  double width,
  TextDirection direction,
) async {
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = Size(width * 2, 1200);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    kitApp(
      brightness: brightness,
      home: Directionality(
        textDirection: direction,
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(top: 80),
            // Leave enough page visible to detect paint outside the part.
            child: RepaintBoundary(
              key: _frame,
              child: Builder(
                builder: (context) => ColoredBox(
                  color: GlossTheme.of(context).colors.page,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: child,
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
}

Future<(Uint8List, int)> _pixels(WidgetTester tester) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_frame),
  );
  return (await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      return (data!.buffer.asUint8List(), image.width);
    } finally {
      image.dispose();
    }
  }))!;
}

double _channel(int v) {
  final c = v / 255;
  return c <= 0.04045 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4) * 1.0;
}

double _luminance(Uint8List p, int i) =>
    0.2126 * _channel(p[i]) +
    0.7152 * _channel(p[i + 1]) +
    0.0722 * _channel(p[i + 2]);

double _ratio(double a, double b) =>
    (math.max(a, b) + 0.05) / (math.min(a, b) + 0.05);

void _traditionalFocus() {
  FocusManager.instance.highlightStrategy =
      FocusHighlightStrategy.alwaysTraditional;
  addTearDown(
    () => FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.automatic,
  );
}

class _Part {
  const _Part(
    this.name,
    this.child,
    this.type, {
    this.words,
    this.socket = false,
  });

  final String name;
  final Widget child;

  /// The widget that owns the face.
  final Type type;

  /// Words that must keep their ink.
  final String? words;

  /// Whether it is a checkbox's socket, painted within its box.
  final bool socket;
}

void _none() {}

// Find the visible surface, including parts painted inside a larger tap target.
(Rect, double?) _outline(WidgetTester tester, _Part part) {
  bool lit(GlossFace face) => face.focus.a > 0;
  final face = find.descendant(
    of: find.byKey(_frame),
    matching: find.byWidgetPredicate(
      (w) =>
          (w is AnimatedGlossSurface && lit(w.face)) ||
          (w is GlossSurface && lit(w.face)),
    ),
  );
  if (face.evaluate().isNotEmpty) {
    final w = tester.widget(face.first);
    final f = w is AnimatedGlossSurface ? w.face : (w as GlossSurface).face;
    return (tester.getRect(face.first), f.corners?.topLeft.x ?? f.radius);
  }
  final glaze = find.descendant(
    of: find.byKey(_frame),
    matching: find.byWidgetPredicate(
      (w) => w is GlossGlazeHighlight && w.focused,
    ),
  );
  if (glaze.evaluate().isNotEmpty) {
    final w = tester.widget<GlossGlazeHighlight>(glaze.first);
    return (tester.getRect(glaze.first).deflate(w.inset), w.radius);
  }
  final box = tester.getRect(find.byType(part.type).first);
  if (part.socket) {
    // The socket, centred in its tap target.
    return (
      Rect.fromCenter(center: box.center, width: 24, height: 24),
      GlossMetrics.socketRadius,
    );
  }
  if (part.type == GlossSwitch) {
    return (Rect.fromCenter(center: box.center, width: 52, height: 30), null);
  }
  return (box, 12);
}

void main() {
  setUpAll(_loadFonts);

  for (final brightness in Brightness.values) {
    testWidgets(
      'validation keeps the field lip and marks the checkbox in $brightness',
      (tester) async {
        final focus = FocusNode();
        addTearDown(focus.dispose);
        Future<void> show({required bool invalid}) => _show(
          tester,
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GlossTextField(
                label: 'Cooking time',
                focusNode: focus,
                error: invalid ? 'Use minutes' : null,
              ),
              SizedBox.square(
                dimension: 24,
                child: GlossCheckbox(
                  value: false,
                  isError: invalid,
                  onChanged: (_) {},
                ),
              ),
            ],
          ),
          brightness,
          390,
          TextDirection.ltr,
        );
        GlossFace face() => tester
            .widget<AnimatedGlossSurface>(
              find
                  .descendant(
                    of: find.byType(GlossTextField),
                    matching: find.byType(AnimatedGlossSurface),
                  )
                  .first,
            )
            .face;
        await show(invalid: false);
        final rest = face();
        focus.requestFocus();
        await tester.pumpAndSettle();
        final focused = face();
        await show(invalid: true);
        expect(find.text('Use minutes'), findsOneWidget);
        expect(face().edge, focused.edge);
        expect(face().focus, focused.focus);
        focus.unfocus();
        await tester.pumpAndSettle();
        expect(face().edge, rest.edge);
        expect(face().lift, lessThan(0));
        expect(find.byIcon(LucideIcons.circleAlert), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final reduced in [false, true]) {
    testWidgets('glaze focus enters and leaves with reduce motion $reduced', (
      tester,
    ) async {
      _traditionalFocus();
      final focus = FocusNode();
      addTearDown(focus.dispose);
      await tester.pumpWidget(
        kitApp(
          brightness: Brightness.light,
          home: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
              child: Center(
                child: GlossButton.filled(
                  'Save',
                  focusNode: focus,
                  onPressed: _none,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      double reflection() => tester
          .widget<GlossSurface>(
            find.descendant(
              of: find.byType(GlossButton),
              matching: find.byType(GlossSurface),
            ),
          )
          .face
          .focus
          .a;
      expect(reflection(), 0);
      focus.requestFocus();
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 35));
      expect(reflection(), reduced ? equals(1.0) : inExclusiveRange(0.0, 1.0));
      await tester.pumpAndSettle();
      expect(reflection(), 1);
      focus.unfocus();
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 35));
      expect(reflection(), reduced ? equals(0.0) : inExclusiveRange(0.0, 1.0));
      await tester.pumpAndSettle();
      expect(reflection(), 0);
    });
  }

  final parts = [
    const _Part(
      'button',
      GlossButton('Share', onPressed: _none),
      GlossButton,
      words: 'Share',
    ),
    const _Part(
      'filled button',
      GlossButton.filled('Cook this', onPressed: _none),
      GlossButton,
      words: 'Cook this',
    ),
    const _Part(
      'text button',
      GlossButton.text('Later', onPressed: _none),
      GlossButton,
      words: 'Later',
    ),
    const _Part(
      'link',
      GlossLink('See all', onPressed: _none),
      GlossLink,
      words: 'See all',
    ),
    const _Part(
      'icon button',
      GlossIconButton(
        icon: Icon(LucideIcons.heart),
        tooltip: 'Save',
        onPressed: _none,
      ),
      GlossIconButton,
    ),
    _Part(
      'checkbox',
      GlossCheckbox(value: false, semanticLabel: 'Bought', onChanged: (_) {}),
      GlossCheckbox,
      socket: true,
    ),
    _Part(
      'switch',
      GlossSwitch(value: true, semanticLabel: 'Reminders', onChanged: (_) {}),
      GlossSwitch,
    ),
    _Part(
      'chip',
      GlossChip(label: 'Quick', selected: true, onSelected: (_) {}),
      GlossChip,
      words: 'Quick',
    ),
    _Part(
      'segmented button',
      GlossSegmentedButton<String>(
        segments: const [
          GlossSegment(value: 'day', label: 'Day'),
          GlossSegment(value: 'week', label: 'Week'),
        ],
        selected: 'week',
        onChanged: (_) {},
      ),
      GlossSegmentedButton<String>,
      // Tab reaches the segments at the choice.
      words: 'Week',
    ),
    _Part(
      'chosen segment',
      GlossSegmentedButton<String>(
        segments: const [
          GlossSegment(value: 'day', label: 'Day'),
          GlossSegment(value: 'week', label: 'Week'),
        ],
        selected: 'day',
        onChanged: (_) {},
      ),
      GlossSegmentedButton<String>,
      words: 'Day',
    ),
    const _Part(
      'list row',
      SizedBox(
        width: 320,
        child: GlossWell(
          children: [
            GlossListTile(
              title: 'Lemon risotto',
              subtitle: '35 min',
              onTap: _none,
            ),
          ],
        ),
      ),
      GlossListTile,
      words: 'Lemon risotto',
    ),
    _Part(
      'menu row',
      SizedBox(
        width: 240,
        child: GlossMenuList(
          items: [GlossMenuItem(label: 'Duplicate', onPressed: () {})],
          close: () {},
        ),
      ),
      GlossMenuRow,
      words: 'Duplicate',
    ),
    _Part(
      'text field',
      SizedBox(
        width: 320,
        child: GlossTextField(hint: 'name@example.com', onChanged: (_) {}),
      ),
      GlossTextField,
    ),
    _Part(
      'tab',
      SizedBox(
        width: 240,
        child: GlossTabBar(
          tabs: const ['Today', 'Week'],
          selectedIndex: 0,
          onSelected: (_) {},
        ),
      ),
      GlossTabBar,
      words: 'Today',
    ),
    const _Part(
      'card',
      SizedBox(
        width: 240,
        child: GlossCard(onTap: _none, child: Text('Dinner')),
      ),
      GlossCard,
      words: 'Dinner',
    ),
    _Part(
      'slider',
      SizedBox(
        width: 320,
        child: GlossSlider(
          value: 0.4,
          semanticLabel: 'Spice',
          onChanged: (_) {},
        ),
      ),
      GlossSlider,
    ),
  ];

  for (final brightness in Brightness.values) {
    for (final width in [390.0, 1440.0]) {
      for (final direction in TextDirection.values) {
        for (final part in parts) {
          testWidgets(
            'a focused ${part.name} catches the light by ${brightness.name} '
            'at ${width.round()}, ${direction.name}',
            (tester) async {
              _traditionalFocus();
              await _show(tester, part.child, brightness, width, direction);
              final (before, stride) = await _pixels(tester);
              await tester.sendKeyEvent(LogicalKeyboardKey.tab);
              await tester.pumpAndSettle();
              final (after, _) = await _pixels(tester);
              final origin = tester.getTopLeft(find.byKey(_frame));
              final (shape, radius) = _outline(tester, part);
              final rect = shape.shift(-origin);
              final words = part.words == null
                  ? null
                  : tester.getRect(find.text(part.words!)).shift(-origin);
              final outline = glossOutline(rect, radius).scaleRadii();
              // A half device pixel at an antialiased edge belongs to the face.
              final edge = outline.inflate(0.5);
              var changed = 0, onWords = 0, outside = 0;
              for (var i = 0; i < before.length; i += 4) {
                if (before[i] == after[i] &&
                    before[i + 1] == after[i + 1] &&
                    before[i + 2] == after[i + 2]) {
                  continue;
                }
                final at = Offset(
                  ((i ~/ 4) % stride + 0.5) / 2,
                  ((i ~/ 4) ~/ stride + 0.5) / 2,
                );
                final ratio = _ratio(
                  _luminance(before, i),
                  _luminance(after, i),
                );
                if (!edge.contains(at)) outside++;
                if (ratio > 1.035) changed++;
                if (ratio >= 3 &&
                    words != null &&
                    words.deflate(1).contains(at)) {
                  onWords++;
                }
              }
              if (brightness == Brightness.light &&
                  {
                    'text field',
                    'list row',
                    'chip',
                    'tab',
                    'switch',
                  }.contains(part.name)) {
                // The field caret and the label occupy the middle. Sample the
                // glaze at the side of the lettering, inside the body and clear
                // of both reflected edges. On the switch, sample the pearl.
                final fraction = part.name == 'switch'
                    ? (direction == TextDirection.ltr ? 0.75 : 0.25)
                    : 0.82;
                final x = ((rect.left + rect.width * fraction) * 2).floor();
                final y = (rect.center.dy * 2).floor();
                final i = (y * stride + x) * 4;
                expect(
                  after.sublist(i, i + 3),
                  before.sublist(i, i + 3),
                  reason: 'Focus changed the neutral body of ${part.name}',
                );
              }
              expect(
                changed,
                greaterThan(16),
                reason: 'No visible reflection on ${part.name}',
              );
              expect(outside, 0, reason: 'Focus painted outside ${part.name}');
              expect(onWords, 0, reason: 'Focus obscured the words');
            },
          );
        }
      }
    }
  }
}
