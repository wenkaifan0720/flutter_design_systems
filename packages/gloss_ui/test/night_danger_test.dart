// By night a destructive pearl key differs in hue from a neutral key at a
// glance (its words plainly rose and far from the neutral key's), reads at
// 4.5:1, and stays a pearl: a grey face, not the ruby gel of a screen's
// destructive action, a touch lighter than the dialog it stands on, at
// rest, hovered, focused and pressed; by day it is unchanged. The danger
// words had been lightened to a pale rose (about #FFD4D7) that read nearly
// white beside 'Keep'; then the key was moulded in ruby, the same as the
// ruby gel beside it.
// GlossScaffold is deprecated (GlossAppShell replaces it); tested until 0.7.0 removes it.
// ignore_for_file: deprecated_member_use_from_same_package
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gloss_ui/gloss_ui.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

double _ratio(Color a, Color b) {
  final x = a.computeLuminance(), y = b.computeLuminance();
  return (math.max(x, y) + .05) / (math.min(x, y) + .05);
}

// CIE L*a*b* (D65) of an sRGB colour.
List<double> _lab(Color c) {
  double lin(double v) =>
      v <= .04045 ? v / 12.92 : math.pow((v + .055) / 1.055, 2.4).toDouble();
  final r = lin(c.r), g = lin(c.g), b = lin(c.b);
  final x = (.4124 * r + .3576 * g + .1805 * b) / .95047;
  final y = .2126 * r + .7152 * g + .0722 * b;
  final z = (.0193 * r + .1192 * g + .9505 * b) / 1.08883;
  double f(double t) => t > 216 / 24389
      ? math.pow(t, 1 / 3).toDouble()
      : (24389 / 27 * t + 16) / 116;
  return [116 * f(y) - 16, 500 * (f(x) - f(y)), 200 * (f(y) - f(z))];
}

double _chroma(Color c) {
  final l = _lab(c);
  return math.sqrt(l[1] * l[1] + l[2] * l[2]);
}

double _deltaE(Color a, Color b) {
  final x = _lab(a), y = _lab(b);
  return math.sqrt(
    math.pow(x[0] - y[0], 2) +
        math.pow(x[1] - y[1], 2) +
        math.pow(x[2] - y[2], 2),
  );
}

final _shot = GlobalKey();

Future<Color Function(Offset)> _picture(WidgetTester tester) async {
  final boundary =
      _shot.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final (width, data) = (await tester.runAsync<(int, ByteData)>(() async {
    final image = await boundary.toImage();
    final bytes = (await image.toByteData())!;
    final width = image.width;
    image.dispose();
    return (width, bytes);
  }))!;
  return (Offset at) {
    final i = 4 * (at.dy.floor() * width + at.dx.floor());
    return Color.fromARGB(
      data.getUint8(i + 3),
      data.getUint8(i),
      data.getUint8(i + 1),
      data.getUint8(i + 2),
    );
  };
}

Color _words(WidgetTester tester, String words) => tester
    .renderObject<RenderParagraph>(
      find.descendant(of: find.text(words), matching: find.byType(RichText)),
    )
    .text
    .style!
    .color!;

// The least contrast the words make with the face round them, sampled
// just past each end of the words, at their top, middle and foot.
double _least(Color Function(Offset) at, WidgetTester tester, String words) {
  final ink = _words(tester, words);
  final box = tester.getRect(find.text(words));
  var least = double.infinity;
  for (final x in [box.left - 3, box.right + 3]) {
    for (final y in [box.top + 2, box.center.dy, box.bottom - 2]) {
      least = math.min(least, _ratio(ink, at(Offset(x, y))));
    }
  }
  return least;
}

Future<void> _dialog(WidgetTester tester, Brightness brightness) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final page = GlobalKey();
  await tester.pumpWidget(
    RepaintBoundary(
      key: _shot,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        builder: (context, navigator) => GlossHost(
          theme: GlossThemeData.light(),
          darkTheme: GlossThemeData.dark(),
          brightness: brightness,
          child: navigator!,
        ),
        home: GlossScaffold(body: SizedBox.expand(key: page)),
      ),
    ),
  );
  unawaited(
    showGlossDialog<void>(
      context: page.currentContext!,
      builder: (_) => GlossDialog(
        title: 'Remove this recipe?',
        content: const Text('It leaves Thursday and your shopping list.'),
        actions: [
          GlossDialogAction(label: 'Keep', onPressed: () {}),
          GlossDialogAction(
            label: 'Remove recipe',
            onPressed: () {},
            isDestructiveAction: true,
          ),
        ],
      ),
    ),
  );
  await tester.pumpAndSettle();
}

bool _focused(String words) {
  final focus = FocusManager.instance.primaryFocus?.context;
  if (focus == null) return false;
  return find
      .descendant(
        of: find.byElementPredicate((e) => e == focus),
        matching: find.text(words),
      )
      .evaluate()
      .isNotEmpty;
}

void main() {
  const danger = 'Remove recipe';
  final states = <String, Future<void> Function(WidgetTester)>{
    'at rest': (tester) async {},
    'hovered': (tester) async {
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(find.text(danger)));
      await tester.pumpAndSettle();
    },
    'focused': (tester) async {
      for (var i = 0; i < 6 && !_focused(danger); i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
      }
      expect(_focused(danger), isTrue);
    },
    'pressed': (tester) async {
      final finger = await tester.startGesture(
        tester.getCenter(find.text(danger)),
      );
      addTearDown(finger.up);
      await tester.pumpAndSettle();
    },
  };
  for (final MapEntry(key: state, value: act) in states.entries) {
    testWidgets('by night the destructive key is plainly apart, $state', (
      tester,
    ) async {
      await _dialog(tester, Brightness.dark);
      await act(tester);
      final at = await _picture(tester);
      final rose = _words(tester, danger);
      final keep = _words(tester, 'Keep');
      // Each key's face just before its words, and the dialog just above
      // the destructive key.
      Color face(String words) {
        final box = tester.getRect(find.text(words));
        return at(Offset(box.left - 6, box.center.dy));
      }

      // The key: the nearest box round its words that is plainly taller.
      final words = tester.getRect(find.text(danger));
      final key = find
          .ancestor(
            of: find.text(danger),
            matching: find.byWidgetPredicate((_) => true),
          )
          .evaluate()
          .map((e) => e.renderObject)
          .whereType<RenderBox>()
          .where((b) => b.hasSize)
          .map(
            (b) => MatrixUtils.transformRect(
              b.getTransformTo(null),
              Offset.zero & b.size,
            ),
          )
          .firstWhere((r) => r.height >= words.height + 12);
      final panel = at(Offset(key.center.dx, key.top - 4));
      final smoked = face(danger);
      // Its words plainly rose, far from the neutral key's.
      expect(
        _chroma(rose) >= 40 && _deltaE(rose, keep) >= 40,
        isTrue,
        reason:
            'words $rose against $keep '
            '(chroma ${_chroma(rose).toStringAsFixed(1)}, '
            'dE ${_deltaE(rose, keep).toStringAsFixed(1)})',
      );
      // A pearl's grey face, not the ruby gel's.
      expect(
        _chroma(smoked),
        lessThan(12),
        reason: 'face $smoked (chroma ${_chroma(smoked).toStringAsFixed(1)})',
      );
      // Its words read on it.
      expect(
        _least(at, tester, danger),
        greaterThanOrEqualTo(4.5),
        reason: '$rose',
      );
      // A raised key standing off the dialog, not a slot sunk in it.
      expect(
        _ratio(smoked, panel),
        greaterThanOrEqualTo(1.1),
        reason: 'face $smoked on the dialog $panel',
      );
    });
  }

  testWidgets('by day the destructive key is unchanged: ruby words', (
    tester,
  ) async {
    await _dialog(tester, Brightness.light);
    expect(_words(tester, danger), GlossThemeData.light().colors.danger);
  });
}
