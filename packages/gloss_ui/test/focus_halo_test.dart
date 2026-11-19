// Keyboard focus lights a soft halo of jade round the glazed part, as Aqua
// did: no ring stands apart from it. The focused pixels read at 3:1 or more
// against the same pixels unfocused over at least a 2 px perimeter of the
// part, by day and by night, on a phone and a wide screen, in both
// directions; the halo stays within its reach of the part and never crosses
// its words.
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
            // The part on the page it stands on, with room round it for its
            // halo.
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

  /// The part, whose outline the halo follows.
  final Type type;

  /// Its words, which the halo never crosses.
  final String? words;

  /// Whether it is a checkbox's socket, painted within its box.
  final bool socket;
}

void _none() {}

// The outline the focus follows, and its corners' radius (null for a
// capsule): the focused face, else the halo's own shape, else the part.
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
  final halo = find.descendant(
    of: find.byKey(_frame),
    matching: find.byWidgetPredicate((w) => w is GlossFocusHalo && w.focused),
  );
  if (halo.evaluate().isNotEmpty) {
    final w = tester.widget<GlossFocusHalo>(halo.first);
    return (tester.getRect(halo.first).deflate(w.inset), w.radius);
  }
  final box = tester.getRect(find.byType(part.type).first);
  if (part.socket) {
    // The socket, centred in its tap target.
    return (
      Rect.fromCenter(center: box.center, width: 24, height: 24),
      GlossMetrics.socketRadius,
    );
  }
  return (box, 12);
}

void main() {
  setUpAll(_loadFonts);

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
      words: 'Day',
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
            'a focused ${part.name} shows a halo by ${brightness.name} '
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
              var lit = 0, onWords = 0, far = 0;
              // The halo's own reach round the outline it follows.
              final near = rect.inflate(GlossMetrics.focusReach + 1);
              for (var i = 0; i + 3 < before.length; i += 4) {
                final at = Offset(
                  (i ~/ 4) % stride / 2,
                  (i ~/ 4) ~/ stride / 2,
                );
                final r = _ratio(_luminance(before, i), _luminance(after, i));
                if (r >= 3) {
                  lit++;
                  if (words != null && words.deflate(1).contains(at)) onWords++;
                }
                if (r >= 1.2 && !near.contains(at)) far++;
              }
              // A 2 px band round the outline, its corners rounded: four device
              // pixels to a logical one at 2x.
              final corner = math.min(
                radius ?? double.infinity,
                rect.shortestSide / 2,
              );
              final perimeter =
                  2 * (rect.width + rect.height) - (8 - 2 * math.pi) * corner;
              expect(
                lit,
                greaterThanOrEqualTo(2 * perimeter * 4),
                reason: '${part.name}: $lit lit for a perimeter of $perimeter',
              );
              expect(onWords, 0, reason: 'the halo crossed the words');
              expect(far, 0, reason: 'focus changed what is beyond the part');
            },
          );
        }
      }
    }
  }
}
