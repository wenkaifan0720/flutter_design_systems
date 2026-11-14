import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_ui.dart';

const _shot = ValueKey('styled-shot');
const _red = Color(0xffd01020), _green = Color(0xff10a040);

class _Case {
  const _Case(this.build, this.face, this.theme, this.at);
  final Widget Function(ComicStyle?) build;
  final Finder Function() face;
  final ComicThemeData Function(ComicThemeData, ComicStyle) theme;
  final Offset at;
}

Finder _painted(String type) => find
    .byWidgetPredicate(
      (w) => w is CustomPaint && w.painter?.runtimeType.toString() == type,
    )
    .first;
Finder _in(Type part, Type face) =>
    find.descendant(of: find.byType(part), matching: find.byType(face)).first;
final _cases = <String, _Case>{
  'act': _Case(
    (s) => ComicButton.filled('Go', onPressed: () {}, style: s),
    () => _in(ComicButton, DecoratedBox),
    (t, s) => t.copyWith(filledButtonTheme: s),
    const Offset(0.5, 0.15),
  ),
  'line': _Case(
    (s) => ComicButton('Go', onPressed: () {}, style: s),
    () => _in(ComicButton, DecoratedBox),
    (t, s) => t.copyWith(buttonTheme: s),
    const Offset(0.5, 0.15),
  ),
  'quiet': _Case(
    (s) => ComicButton.text('Later', onPressed: () {}, style: s),
    () => _in(ComicButton, DecoratedBox),
    (t, s) => t.copyWith(textButtonTheme: s),
    const Offset(0.5, 0.1),
  ),
  'icon': _Case(
    (s) => ComicIconButton(
      ComicGlyphs.search,
      label: 'Search',
      onPressed: () {},
      style: s,
    ),
    () => _in(ComicIconButton, DecoratedBox),
    (t, s) => t.copyWith(iconButtonTheme: s),
    const Offset(0.2, 0.5),
  ),
  'send': _Case(
    (s) => ComicSendButton(onPressed: () {}, style: s),
    () => _in(ComicSendButton, DecoratedBox),
    (t, s) => t.copyWith(iconButtonTheme: s),
    const Offset(0.2, 0.5),
  ),
  'checkbox': _Case(
    (s) => ComicCheckbox(
      label: 'Keep issue',
      value: false,
      onChanged: (_) {},
      style: s,
    ),
    () => _in(ComicCheckbox, DecoratedBox),
    (t, s) => t.copyWith(checkboxTheme: s),
    const Offset(0.5, 0.5),
  ),
  'radio': _Case(
    (s) => ComicRadioGroup<int>(
      label: 'Copy',
      options: const [ComicRadio(1, 'One'), ComicRadio(2, 'Two')],
      onChanged: (_) {},
      style: s,
    ),
    () => _in(ComicRadioGroup<int>, Container),
    (t, s) => t.copyWith(radioTheme: s),
    const Offset(0.5, 0.5),
  ),
  'switch': _Case(
    (s) => ComicSwitch(value: true, onChanged: (_) {}, style: s),
    () => _painted('_SwitchPainter'),
    (t, s) => t.copyWith(switchTheme: s),
    const Offset(0.2, 0.5),
  ),
  'field': _Case(
    (s) => ComicTextField(hint: 'Name', style: s),
    () => _in(ComicTextField, DecoratedBox),
    (t, s) => t.copyWith(textFieldTheme: s),
    const Offset(0.9, 0.5),
  ),
  'chip': _Case(
    (s) => ComicChip('Paper', onPressed: () {}, style: s),
    () => _in(ComicChip, DecoratedBox),
    (t, s) => t.copyWith(chipTheme: s),
    const Offset(0.1, 0.5),
  ),
  'slider': _Case(
    (s) => ComicSlider(label: 'Level', value: .7, onChanged: (_) {}, style: s),
    () => _painted('_SliderInk'),
    (t, s) => t.copyWith(sliderTheme: s),
    const Offset(0.25, 0.5),
  ),
  'segments': _Case(
    (s) => ComicSegmentedButton<int>(
      label: 'View',
      value: 1,
      segments: const [
        ComicButtonSegment(1, 'Day'),
        ComicButtonSegment(2, 'Week'),
      ],
      onChanged: (_) {},
      style: s,
    ),
    () => _in(ComicSegmentedButton<int>, DecoratedBox),
    (t, s) => t.copyWith(segmentedButtonTheme: s),
    const Offset(0.5, 0.1),
  ),
  'card': _Case(
    (s) => ComicCard(
      title: 'Issue',
      style: s,
      children: const [SizedBox(height: 40)],
    ),
    () => _in(ComicCard, DecoratedBox),
    (t, s) => t.copyWith(cardTheme: s),
    const Offset(0.5, 0.9),
  ),
  'dialog': _Case(
    (s) => ComicDialog(
      title: 'Issue',
      content: const [SizedBox(height: 40)],
      style: s,
    ),
    () => _in(ComicDialog, DecoratedBox),
    (t, s) => t.copyWith(dialogTheme: s),
    const Offset(0.5, 0.9),
  ),
  'picture card': _Case(
    (s) => ComicPictureCard(
      slotId: 'unused-with-supplied-image',
      image: const SizedBox.expand(),
      title: 'Issue',
      style: s,
    ),
    () => _in(ComicPictureCard, DecoratedBox),
    (t, s) => t.copyWith(cardTheme: s),
    const Offset(0.5, 0.15),
  ),
  'sheet': _Case(
    (s) => ComicBottomSheet(
      showClose: false,
      style: s,
      child: const SizedBox(height: 100),
    ),
    () => _in(ComicBottomSheet, DecoratedBox),
    (t, s) => t.copyWith(sheetTheme: s),
    const Offset(0.5, 0.6),
  ),
  'menu': _Case(
    (s) => ComicMenu<String>(
      items: const [ComicMenuItem('a', 'Share')],
      onSelected: (_) {},
      style: s,
    ),
    () => _in(ComicMenu<String>, DecoratedBox),
    (t, s) => t.copyWith(menuTheme: s),
    const Offset(0.015, 0.5),
  ),
  'snack': _Case(
    (s) => ComicSnackBar('Saved', style: s),
    () => _in(ComicSnackBar, DecoratedBox),
    (t, s) => t.copyWith(snackBarTheme: s),
    const Offset(0.02, 0.5),
  ),
  'tooltip': _Case(
    (s) => ComicTooltipFace(message: 'Save this issue', style: s),
    () => _painted('_BalloonPainter'),
    (t, s) => t.copyWith(tooltipTheme: s),
    const Offset(0.5, 0.15),
  ),
  'badge': _Case(
    (s) => ComicBadge(5, style: s),
    () => _in(ComicBadge, Container),
    (t, s) => t.copyWith(badgeTheme: s),
    const Offset(0.2, 0.5),
  ),
  'avatar': _Case(
    (s) => ComicAvatar('AB', style: s),
    () => _in(ComicAvatar, DecoratedBox),
    (t, s) => t.copyWith(avatarTheme: s),
    const Offset(0.5, 0.82),
  ),
  'option': _Case(
    (s) => ComicChoiceBox(
      onPressed: () {},
      style: s,
      child: const SizedBox(width: 100, height: 40),
    ),
    () => _in(ComicChoiceBox, DecoratedBox),
    (t, s) => t.copyWith(optionTheme: s),
    const Offset(0.5, 0.5),
  ),
  'stepper': _Case(
    (s) => ComicNumberField(value: 3, onChanged: (_) {}, style: s),
    () => _in(ComicNumberField, DecoratedBox),
    (t, s) => t.copyWith(stepperTheme: s),
    // The trough's fill above the count: from 600 up the stepper keeps to its count (11-12), so a fifth of its width
    // falls on the minus glyph.
    const Offset(0.5, 0.12),
  ),
  'date': _Case(
    (s) => ComicDatePicker(
      value: DateTime(2026, 11, 6),
      currentDate: DateTime(2026, 11, 6),
      onChanged: (_) {},
      style: s,
    ),
    () => find
        .descendant(
          of: find.byWidgetPredicate(
            (w) => w is ComicPressable && w.label == 'November 1, 2026',
          ),
          matching: find.byType(Container),
        )
        .first,
    (t, s) => t.copyWith(datePickerTheme: s),
    const Offset(0.15, 0.3),
  ),
  'time': _Case(
    (s) => ComicTimePicker(
      value: const ComicTime(12, 0),
      onChanged: (_) {},
      style: s,
    ),
    () => _in(ComicTimePicker, DecoratedBox),
    (t, s) => t.copyWith(timePickerTheme: s),
    const Offset(0.5, 0.1),
  ),
};
Widget _host(ComicThemeData theme, Widget child) => MaterialApp(
  localizationsDelegates: const [ComicLocalizations.delegate],
  home: ComicTheme(
    data: theme,
    child: Center(
      child: RepaintBoundary(
        key: _shot,
        child: ColoredBox(
          color: theme.colors.background,
          child: SizedBox(width: 360, child: Center(child: child)),
        ),
      ),
    ),
  ),
);
Future<Color> _pixel(WidgetTester tester, Finder face, Offset at) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_shot),
  );
  final box = tester.renderObject<RenderBox>(face);
  final p =
      box.localToGlobal(
        Offset(box.size.width * at.dx, box.size.height * at.dy),
      ) -
      boundary.localToGlobal(Offset.zero);
  final bytes = await tester.runAsync(() async {
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    return bytes!;
  });
  final i = (p.dy.floor() * boundary.size.width.round() + p.dx.floor()) * 4;
  return Color.fromARGB(
    bytes!.getUint8(i + 3),
    bytes.getUint8(i),
    bytes.getUint8(i + 1),
    bytes.getUint8(i + 2),
  );
}

Matcher _near(Color color) => predicate<Color>(
  (c) =>
      (c.r - color.r).abs() < .02 &&
      (c.g - color.g).abs() < .02 &&
      (c.b - color.b).abs() < .02,
  'near $color',
);
void main() {
  final base = ComicThemeData.offset();
  const red = ComicStyle(
    fill: WidgetStatePropertyAll(_red),
    overlay: WidgetStatePropertyAll(Color(0x00000000)),
  );
  const green = ComicStyle(
    fill: WidgetStatePropertyAll(_green),
    overlay: WidgetStatePropertyAll(Color(0x00000000)),
  );
  for (final direction in TextDirection.values) {
    for (final radius in [4.0, 12.0, 24.0]) {
      testWidgets(
        'panel content stays inside its $radius corner in $direction',
        (tester) async {
          const content = ValueKey('bleeding-content');
          await tester.pumpWidget(
            _host(
              base,
              Directionality(
                textDirection: direction,
                child: ComicPanel(
                  bleed: true,
                  style: ComicStyle(
                    shape: WidgetStatePropertyAll(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(radius),
                      ),
                    ),
                  ),
                  child: const SizedBox(
                    key: content,
                    height: 100,
                    child: ColoredBox(color: _red),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final clip = _in(ComicPanel, ClipPath);
          final widget = tester.widget<ClipPath>(clip);
          final path = widget.clipper!.getClip(tester.getSize(clip));
          final origin = tester.getTopLeft(clip);
          final body = tester.getRect(find.byKey(content)).shift(-origin);
          for (final point in [
            body.topCenter + const Offset(0, 2),
            body.bottomCenter - const Offset(0, 2),
            body.centerLeft + const Offset(2, 0),
            body.centerRight - const Offset(2, 0),
          ]) {
            expect(
              path.contains(point),
              isTrue,
              reason: '$point outside $radius',
            );
          }
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  for (final MapEntry(key: name, value: part) in _cases.entries) {
    testWidgets(
      '$name resolves widget style before component theme before defaults',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        Future<Color> read(ComicThemeData theme, ComicStyle? style) async {
          await tester.pumpWidget(_host(theme, part.build(style)));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          return _pixel(tester, part.face(), part.at);
        }

        final own = await read(base, null);
        expect(own, isNot(_near(_red)));
        expect(own, isNot(_near(_green)));
        expect(await read(part.theme(base, green), null), _near(_green));
        expect(await read(part.theme(base, green), red), _near(_red));
        expect(await read(base, red), _near(_red));
        final pressedOnly = ComicStyle(
          fill: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.pressed) ? _red : null,
          ),
        );
        expect(
          await read(part.theme(base, green), pressedOnly),
          _near(_green),
          reason: 'A null state value must preserve the component theme',
        );
        expect(
          await read(base, pressedOnly),
          _near(own),
          reason: 'A null state value must preserve the component default',
        );
        expect(
          await read(part.theme(base, const ComicStyle()), null),
          _near(own),
        );
      },
      // The fill is read from the drawn pixels: the rasterizer's, as a golden's (Linux CI leaves it to macOS).
      tags: 'goldens',
    );
  }
  for (final name in ['act', 'line', 'chip', 'option']) {
    final part = _cases[name]!;
    testWidgets('$name reads pressed state and returns to its rest fill', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final style = ComicStyle(
        fill: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.pressed) ? _red : _green,
        ),
        overlay: const WidgetStatePropertyAll(Color(0x00000000)),
      );
      await tester.pumpWidget(_host(base, part.build(style)));
      await tester.pumpAndSettle();
      expect(await _pixel(tester, part.face(), part.at), _near(_green));
      final gesture = await tester.startGesture(tester.getCenter(part.face()));
      await tester.pumpAndSettle();
      expect(await _pixel(tester, part.face(), part.at), _near(_red));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(await _pixel(tester, part.face(), part.at), _near(_green));
    }, tags: 'goldens'); // the drawn fill
  }
  testWidgets(
    'a state shape animates then lands exactly and reduce motion cuts',
    (tester) async {
      const rest = RoundedRectangleBorder(),
          pressed = RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          );
      final style = ComicStyle(
        shape: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.pressed) ? pressed : rest,
        ),
        overlay: const WidgetStatePropertyAll(Color(0x00000000)),
      );
      await tester.pumpWidget(
        _host(base, ComicChip('Press', onPressed: () {}, style: style)),
      );
      await tester.pumpAndSettle();
      final face = _in(ComicChip, DecoratedBox);
      RoundedRectangleBorder outline() =>
          (tester.widget<DecoratedBox>(face).decoration as ShapeDecoration)
                  .shape
              as RoundedRectangleBorder;
      expect((outline().borderRadius as BorderRadius).topLeft.x, 0);
      final gesture = await tester.startGesture(tester.getCenter(face));
      await tester.pump();
      // Frame by frame, as a screen draws it: the face's decoration follows the shape as it moves.
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(
        (outline().borderRadius as BorderRadius).topLeft.x,
        greaterThan(0),
      );
      expect((outline().borderRadius as BorderRadius).topLeft.x, lessThan(16));
      await tester.pumpAndSettle();
      expect((outline().borderRadius as BorderRadius).topLeft.x, 16);
      await gesture.up();
      await tester.pumpAndSettle();
      expect((outline().borderRadius as BorderRadius).topLeft.x, 0);
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: ComicTheme(
              data: base,
              child: ComicChip('Press', onPressed: () {}, style: style),
            ),
          ),
        ),
      );
      final cut = await tester.startGesture(
        tester.getCenter(find.byType(ComicChip)),
      );
      await tester.pump();
      expect((outline().borderRadius as BorderRadius).topLeft.x, 16);
      await cut.up();
    },
  );
  // A button stands a field's height at every density (the user, 11-11 16:34: a button beside a field as tall as it), and
  // a field never stands under the least target. So compact lowers the drawn face where a pointer reaches it, and where
  // a touch does the face keeps the touch target.
  testWidgets(
    'compact density lowers the drawn face for a pointer, never under a touch target',
    (tester) async {
      Future<(double, double)> heights(
        ComicThemeData theme,
        MaterialTapTargetSize reach,
      ) async {
        await tester.pumpWidget(
          _host(
            theme,
            Theme(
              data: ThemeData(materialTapTargetSize: reach),
              child: ComicButton('Go', onPressed: () {}),
            ),
          ),
        );
        await tester.pumpAndSettle();
        return (
          tester.getSize(_in(ComicButton, DecoratedBox)).height,
          tester.getSize(find.byType(ComicButton)).height,
        );
      }

      final compact = base.copyWith(density: ComicDensity.compact);
      const pointer = MaterialTapTargetSize.shrinkWrap,
          touch = MaterialTapTargetSize.padded;
      final (own, _) = await heights(base, pointer);
      final (lower, _) = await heights(compact, pointer);
      expect(lower, lessThan(own));
      final (face, whole) = await heights(compact, touch);
      expect(face, greaterThanOrEqualTo(48));
      expect(whole, greaterThanOrEqualTo(48));
    },
  );
  for (final name in ['icon', 'checkbox']) {
    testWidgets('$name honors a larger style face in a tall row', (
      tester,
    ) async {
      final part = _cases[name]!;
      const style = ComicStyle(
        minimumSize: WidgetStatePropertyAll(Size(72, 60)),
      );
      await tester.pumpWidget(
        _host(
          base,
          SizedBox(
            height: 180,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [part.build(style), const SizedBox(width: 20)],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(tester.getSize(part.face()), const Size(72, 60));
    });
  }
}
