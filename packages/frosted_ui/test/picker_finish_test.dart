// Frosted's pickers and grids, each item measured on 0.6.2 first:
// - A chosen day in a grid (a calendar, the date picker, a range's ends)
//   casts no drop shadow: choosing in a grid is ink in place (law 6), and the
//   shadow smudged the band beside it by day. Buttons keep theirs.
// - By night a range's band is the accent's wash laid twice: laid once it
//   read 1.13:1 on the night ground, and a range's run barely showed.
// - By night a raised slab (a dialog, a picker's card) wears its rim lit
//   from above, bright along its top and fading down its sides, not an even
//   stroke all round (law 2).
// - By night the ink act's word, and a chosen day's figure, set a cut
//   heavier where they are dark on a light pill: at the same weight they
//   read lighter than Cancel's light word on the night glass.
// - A picker's card stands on the dialog's inset (24) and its acts' gap; the
//   inset gives way, to 16, only where a month's seven columns would lose
//   the touch target.
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:frosted_ui/frosted_host.dart';
import 'package:frosted_ui/src/frosted/internal/face.dart';

const _stage = ValueKey('stage');
const _ratio = 2.0;
const _height = 900.0;
final _day = DateTime(2026, 11, 20);
final _today = DateTime(2026, 11, 18);

double _apart(Color a, Color b) =>
    [(a.r - b.r).abs(), (a.g - b.g).abs(), (a.b - b.b).abs()].reduce(math.max);

typedef _Read = Color Function(double x, double y);

Future<_Read> _shot(WidgetTester tester, double width) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_stage),
  );
  final w = (width * _ratio).round();
  final px = (await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: _ratio);
    try {
      return (await image.toByteData())!.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }))!;
  return (double x, double y) {
    final i = ((y * _ratio).floor() * w + (x * _ratio).floor()) * 4;
    return Color.fromARGB(px[i + 3], px[i], px[i + 1], px[i + 2]);
  };
}

Future<void> _pump(
  WidgetTester tester, {
  required Widget home,
  bool dark = false,
  double width = 390,
}) async {
  tester.view.devicePixelRatio = _ratio;
  tester.view.physicalSize = Size(width, _height) * _ratio;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, page) => RepaintBoundary(
        key: _stage,
        child: FrostedHost(
          brightness: dark ? Brightness.dark : Brightness.light,
          child: page!,
        ),
      ),
      home: Align(
        alignment: Alignment.topCenter,
        child: Padding(padding: const EdgeInsets.all(16), child: home),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// A button that opens [open], pressed.
Future<void> _open(
  WidgetTester tester,
  void Function(BuildContext context) open, {
  bool dark = false,
  double width = 390,
}) async {
  // A fresh tree: a route left open would stand over the button.
  await tester.pumpWidget(const SizedBox());
  await _pump(
    tester,
    dark: dark,
    width: width,
    home: Builder(
      builder: (context) =>
          FrostedButton.glass('Open', onPressed: () => open(context)),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

Iterable<FrostedFace> _faces(WidgetTester tester, Finder of) =>
    tester.widgetList<FrostedFace>(
      find.descendant(of: of, matching: find.byType(FrostedFace)),
    );

final Finder _slab = find.byWidgetPredicate(
  (w) => w is FrostedFace && w.material == FrostedMaterial.slab,
);

FontWeight? _weightOf(WidgetTester tester, String text) => tester
    .widget<RichText>(
      find.byWidgetPredicate(
        (w) => w is RichText && w.text.toPlainText() == text,
      ),
    )
    .text
    .style
    ?.fontWeight;

void main() {
  for (final dark in [false, true]) {
    final when = dark ? 'by night' : 'by day';

    testWidgets('a chosen day in a grid casts no shadow, $when', (
      tester,
    ) async {
      await _pump(
        tester,
        dark: dark,
        home: Column(
          children: [
            FrostedCalendar(
              firstDate: DateTime(2026),
              lastDate: DateTime(2027),
              value: _day,
              currentDate: _today,
              onChanged: (_) {},
            ),
            FrostedButton('Save', onPressed: () {}),
          ],
        ),
      );
      final inked = _faces(
        tester,
        find.byType(FrostedCalendar),
      ).where((f) => f.gradients.isNotEmpty).toList();
      expect(inked, isNotEmpty);
      for (final face in inked) {
        expect(face.shadows, isEmpty);
      }
      // A button is a raised act and keeps its shadow.
      expect(
        _faces(
          tester,
          find.byType(FrostedButton),
        ).any((f) => f.shadows.isNotEmpty),
        isTrue,
      );
    });

    testWidgets('the date picker\'s chosen day casts no shadow, $when', (
      tester,
    ) async {
      await _pump(
        tester,
        dark: dark,
        home: FrostedDatePicker(
          value: _day,
          firstDate: DateTime(2026),
          lastDate: DateTime(2027),
          onChanged: (_) {},
        ),
      );
      final inked = _faces(
        tester,
        find.byType(FrostedDatePicker),
      ).where((f) => f.gradients.isNotEmpty).toList();
      expect(inked, isNotEmpty);
      for (final face in inked) {
        expect(face.shadows, isEmpty);
      }
    });

    testWidgets('a range\'s ends cast no shadow, and its band is the wash '
        '${dark ? 'laid twice' : 'as it was'}, $when', (tester) async {
      await _pump(
        tester,
        dark: dark,
        home: FrostedDateRangePicker(
          firstDate: DateTime(2026),
          lastDate: DateTime(2027, 12, 31),
          value: RawDateRange(_day, DateTime(2026, 11, 24)),
          currentDate: _today,
          onChanged: (_) {},
        ),
      );
      final picker = find.byType(FrostedDateRangePicker);
      final inked = _faces(
        tester,
        picker,
      ).where((f) => f.gradients.isNotEmpty).toList();
      expect(inked, hasLength(2));
      for (final face in inked) {
        expect(face.shadows, isEmpty);
      }
      final t = tester.element(picker).frostedTheme;
      final subtle = t.colorScheme.accentSubtle;
      final band = dark ? Color.alphaBlend(subtle, subtle) : subtle;
      final bands = tester
          .widgetList<ColoredBox>(
            find.descendant(of: picker, matching: find.byType(ColoredBox)),
          )
          .map((b) => b.color)
          .toSet();
      expect(bands, contains(band));
      if (dark) {
        final ground = t.colorScheme.background.withValues(alpha: 1);
        expect(
          FrostedThemeData.contrast(Color.alphaBlend(band, ground), ground),
          greaterThan(1.3),
        );
      }
    });

    testWidgets(
      'the ink act\'s word is ${dark ? 'a cut heavier' : 'at the '
                'glass act\'s weight'}, $when',
      (tester) async {
        await _pump(
          tester,
          dark: dark,
          home: Column(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FrostedButton.glass('Cancel', onPressed: () {}),
                  FrostedButton('Freeze', onPressed: () {}),
                ],
              ),
              FrostedCalendar(
                firstDate: DateTime(2026),
                lastDate: DateTime(2027),
                value: _day,
                currentDate: _today,
                onChanged: (_) {},
              ),
            ],
          ),
        );
        final glass = _weightOf(tester, 'Cancel')!;
        expect(
          _weightOf(tester, 'Freeze'),
          dark ? FontWeight(glass.value + 100) : glass,
        );
        final chosen = _weightOf(tester, '20')!;
        final plain = _weightOf(tester, '21');
        expect(chosen, dark ? FontWeight.w700 : FontWeight.w600);
        // A day not chosen keeps its weight.
        expect(plain, FontWeight.w600);
      },
    );

    for (final (name, open) in <(String, void Function(BuildContext))>[
      (
        'a dialog',
        (context) => FrostedDialog.show(
          context,
          title: 'Freeze this card?',
          message: 'Payments stop until you unfreeze it.',
          cancelLabel: 'Cancel',
          confirmLabel: 'Freeze',
        ),
      ),
      (
        'a time picker\'s card',
        (context) => showFrostedTimePicker(
          context,
          initialTime: const FrostedTime(hour: 21, minute: 5),
        ),
      ),
    ]) {
      testWidgets(
        '$name\'s rim is ${dark ? 'lit from above' : 'the lit '
                  'hairline all round'}, $when',
        (tester) async {
          await _open(tester, open, dark: dark);
          final face = tester.widget<FrostedFace>(_slab);
          expect(face.litFromAbove, dark);
          if (!dark) return;
          final read = await _shot(tester, 390);
          final r = tester.getRect(_slab);
          final x = r.center.dx;
          final fill = read(r.left + 8, r.center.dy);
          // Along the top the rim is lit.
          expect(
            _apart(read(x, r.top + .25), read(x, r.top + 8)),
            greaterThan(.08),
          );
          // Half way down a side it has faded to a glint, not a stroke.
          expect(_apart(read(r.left + .25, r.center.dy), fill), lessThan(.04));
          // At the foot it is gone.
          expect(
            _apart(read(x, r.bottom - .25), read(x, r.bottom - 8)),
            lessThan(.02),
          );
        },
      );
    }
  }

  for (final (width, platform) in [
    (390.0, TargetPlatform.android),
    (1440.0, TargetPlatform.macOS),
  ]) {
    final at = '${width.round()} on ${platform.name}';

    testWidgets('a picker\'s card has the dialog\'s acts\' gap, $at', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = platform;
      try {
        // The two acts' pills, the dismissive one first (the page's Open
        // button stands before them).
        double pillsGap() {
          final pills = find.byType(FrostedButton);
          return tester.getRect(pills.at(2)).left -
              tester.getRect(pills.at(1)).right;
        }

        await _open(
          tester,
          (context) => FrostedDialog.show(
            context,
            title: 'Freeze this card?',
            cancelLabel: 'Cancel',
            confirmLabel: 'Freeze',
          ),
          width: width,
        );
        final dialogPills = pillsGap();
        await _open(
          tester,
          (context) => showFrostedTimePicker(
            context,
            initialTime: const FrostedTime(hour: 21, minute: 5),
          ),
          width: width,
        );
        final cardPills = pillsGap();
        expect(cardPills, moreOrLessEquals(dialogPills, epsilon: .01));
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('a picker\'s card stands on the dialog\'s inset where its '
        'grid keeps the touch target, $at', (tester) async {
      debugDefaultTargetPlatformOverride = platform;
      try {
        await _open(
          tester,
          (context) => showFrostedTimePicker(
            context,
            initialTime: const FrostedTime(hour: 21, minute: 5),
          ),
          width: width,
        );
        expect(
          tester.widget<FrostedFace>(_slab).padding,
          const EdgeInsets.all(FrostedChromeMetrics.dialogEdge),
        );
        await _open(
          tester,
          (context) => showFrostedDatePicker(
            context,
            initialDate: _day,
            first: DateTime(2026),
            last: DateTime(2027),
            currentDate: _today,
          ),
          width: width,
        );
        final face = tester.widget<FrostedFace>(_slab);
        final target = FrostedBreakpoints.hitTargetOf(tester.element(_slab));
        final card = tester.getRect(_slab).width;
        final inset = face.padding.left;
        final column =
            (card - 2 * FrostedChromeMetrics.outline - 2 * inset) / 7;
        // The dialog's inset wherever the columns hold the target; else it
        // gives way, to 16 at the least, and the columns keep the target.
        if (column >= target) {
          expect(inset, FrostedChromeMetrics.dialogEdge);
        } else {
          expect(inset, lessThan(FrostedChromeMetrics.dialogEdge));
          expect(inset, greaterThanOrEqualTo(16));
        }
        expect(column, greaterThanOrEqualTo(target));
        // At 390 the floor's seven columns (40) fit inside the dialog's
        // inset, as they do on the desktop.
        expect(inset, FrostedChromeMetrics.dialogEdge);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });
  }
}
