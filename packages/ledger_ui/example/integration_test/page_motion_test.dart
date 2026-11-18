// The example's pages move in Ledger's motion on Flutter's own Material. The package is built on material_ui, so the
// motion LedgerTheme sets reaches material_ui's routes only; Quill is an app on Flutter's MaterialApp, whose
// MaterialPageRoute reads the app's ThemeData, and the example's carries ledgerPageTransitions (the README's line).
// On every platform, on a phone and at a desk: New entry pushes Flutter's MaterialPageRoute, laid down as a leaf
// (fading in as it rises 8 onto the page, never slid or zoomed, in 200 ms); choosing another destination from the
// tab bar, the rail or the side bar changes the page in place, whole from its first frame, and the destinations' marks
// land in that same frame: the page never stands under another destination's mark.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart' show timeDilation;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ledger_ui/ledger_ui.dart';
import 'package:ledger_ui_example/kit_gallery/quill/entry.dart';
import 'package:ledger_ui_example/kit_gallery/quill/quill.dart';
import 'package:ledger_ui_example/kit_gallery/quill/register.dart';

/// Where [page] stands and how it is drawn this frame: its top left on screen, its scale and its opacity.
({Offset at, double scale, double opacity}) _drawn(
  WidgetTester t,
  Finder page,
) {
  final box = t.renderObject<RenderBox>(page);
  final m = box.getTransformTo(null);
  var opacity = 1.0;
  for (RenderObject? r = box; r != null; r = r.parent) {
    if (r is RenderAnimatedOpacity) opacity *= r.opacity.value;
    if (r is RenderOpacity) opacity *= r.opacity;
  }
  return (
    at: MatrixUtils.transformPoint(m, Offset.zero),
    scale: m.getMaxScaleOnAxis(),
    opacity: opacity,
  );
}

/// How the destination keyed [key] is marked this frame: every fill, ring and rule drawn under it, and the ink of its
/// glyphs and words.
List<Object?> _mark(WidgetTester t, String key) {
  final item = find.byKey(ValueKey(key));
  Finder under<W extends Widget>() =>
      find.descendant(of: item, matching: find.byType(W));
  return [
    for (final c in t.widgetList<Container>(under<Container>())) c.decoration,
    for (final i in t.widgetList<Icon>(under<Icon>())) (i.icon, i.color),
    for (final w in t.widgetList<Text>(under<Text>())) w.style?.color,
  ];
}

Future<void> _open(WidgetTester t, Size size) async {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(const QuillApp(initialPage: QuillPage.home));
  await t.pumpAndSettle();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(ledgerLoadFonts);

  for (final size in const [Size(390, 844), Size(1440, 900)]) {
    final width = size.width.round();

    testWidgets(
      'at $width New entry pushes Flutter\'s MaterialPageRoute, laid down in Ledger\'s motion',
      (t) async {
        await _open(t, size);
        final page = find.byType(QuillEntryPage);
        // The frames come in real time, and a push's first frame is offstage (the hero controller's), so one frame
        // longer than the 200 ms (the tester compiling as it goes, a busy machine) would leave only rest to read. So a
        // push and its pop first, warming the page, and the push read runs at a fifth of the speed; its duration is
        // checked on the route.
        await t.tap(find.text('New entry').first);
        await t.pumpAndSettle();
        Navigator.of(t.element(page)).pop();
        await t.pumpAndSettle();
        expect(page, findsNothing);
        final frames = <({Offset at, double scale, double opacity})>[];
        timeDilation = 5;
        try {
          await t.tap(find.text('New entry').first);
          for (var i = 0; i < 240; i++) {
            await t.pump();
            if (page.evaluate().isEmpty) continue;
            final route = ModalRoute.of(t.element(page))!;
            frames.add(_drawn(t, page));
            if (route.animation!.isCompleted) break;
          }
          await t.pumpAndSettle();
        } finally {
          timeDilation = 1;
        }
        final route = ModalRoute.of(t.element(page))!;
        expect(
          route,
          isA<MaterialPageRoute<void>>(),
          reason: 'the push is Flutter\'s own MaterialPageRoute',
        );
        expect(route.transitionDuration, LedgerMotion.base);
        final rest = _drawn(t, page);
        expect(rest.opacity, 1);
        final moving = [
          for (final f in frames)
            if (f.opacity < 1 || (f.at - rest.at).distance > 0.01) f,
        ];
        expect(
          moving,
          isNotEmpty,
          reason: 'it moved: a frame between its start and its rest',
        );
        for (final f in moving) {
          final shift = f.at - rest.at;
          expect(
            shift.dx.abs(),
            lessThan(0.01),
            reason: 'no slide across: $shift',
          );
          expect(f.scale, closeTo(1, 0.001), reason: 'no zoom: ${f.scale}');
          expect(
            shift.dy,
            inInclusiveRange(-0.01, LedgerPageTransitions.rise + 0.01),
            reason: 'a rise of 8 at most',
          );
        }
        expect(
          moving.any((f) => f.opacity > 0 && f.opacity < 1),
          isTrue,
          reason: 'it fades in',
        );
      },
      variant: TargetPlatformVariant.all(),
    );
  }

  // The tab bar on a phone, the rail from 600, the side bar from 1024.
  for (final size in const [Size(390, 844), Size(800, 900), Size(1440, 900)]) {
    final width = size.width.round();

    testWidgets(
      'at $width another destination changes in place, its mark with it',
      (t) async {
        await _open(t, size);
        final registerBefore = _mark(t, 'tab-register');
        await t.tap(find.byKey(const ValueKey('tab-register')));
        await t.pump();
        final page = find.byType(QuillRegister);
        // Its route is done arriving: a transition drawn from a snapshot (the platform's zoom) moves nothing the
        // render tree shows, so the drawn reading alone could miss it.
        expect(
          ModalRoute.of(t.element(page))!.animation!.isCompleted,
          isTrue,
          reason: 'no transition brings it in',
        );
        final first = _drawn(t, page);
        final firstMarks = {
          for (final k in const ['tab-home', 'tab-register']) k: _mark(t, k),
        };
        await t.pumpAndSettle();
        final rest = _drawn(t, page);
        expect(first.opacity, 1, reason: 'whole from its first frame');
        expect(
          (first.at - rest.at).distance,
          lessThan(0.01),
          reason: 'where it rests from its first frame',
        );
        expect(first.scale, closeTo(1, 0.001));
        expect(
          _mark(t, 'tab-register'),
          isNot(equals(registerBefore)),
          reason: 'the reading sees the mark move',
        );
        for (final k in firstMarks.keys) {
          expect(
            firstMarks[k],
            equals(_mark(t, k)),
            reason: '$k is marked as it rests from the page\'s first frame',
          );
        }
      },
      variant: TargetPlatformVariant.all(),
    );
  }
}
