// A part's own corners. A style's `corners` gives one part a step per corner of Comic's scale, held to its limits
// (any of none to large, per corner): each styled part draws them exactly as it draws the same outline given as its
// `shape`, start and end mirrored right to left; a `shape` wins; a step Comic keeps for round things stands at large;
// a focused part's ring follows the corners; a pressed change of corners morphs without a jump.
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_ui.dart';
import 'package:comic_ui/src/comic/raised.dart' show ComicRaisedFrame;
import 'package:comic_ui/src/comic/styled.dart' show comicCappedShape;

const _shot = ValueKey('corners-shot');

/// A step's radius on [_rounded].
const _radii = {
  RawCorner.none: 0.0,
  RawCorner.extraSmall: 6.0,
  RawCorner.small: 8.0,
  RawCorner.medium: 12.0,
  RawCorner.large: 16.0,
};

/// Comic's corners rounded inside their bands, each step its own radius, so every step shows.
final _rounded = ComicThemeData.offset().copyWith(
  shapeScheme: comicShapeScheme.copyWith(
    corners: comicShapeScheme.corners.copyWith(
      extraSmall: _radii[RawCorner.extraSmall],
      small: _radii[RawCorner.small],
      medium: _radii[RawCorner.medium],
      large: _radii[RawCorner.large],
    ),
  ),
);

class _Part {
  const _Part(this.step, this.build, {this.held, this.quiet = false});

  /// The step of the scale the part's own corners take.
  final RawCorner step;
  final Widget Function(ComicStyle?) build;

  /// What the part makes of an outline it is given, when it holds it (a checkbox caps its corners at 7).
  final OutlinedBorder Function(OutlinedBorder)? held;

  /// No surface at rest (quiet words): its corners show in its wash, so it is drawn under a mouse.
  final bool quiet;
}

final _parts = <String, _Part>{
  'filled button': _Part(
    RawCorner.small,
    (s) => ComicButton.filled('Go', onPressed: () {}, style: s),
  ),
  'button': _Part(
    RawCorner.small,
    (s) => ComicButton('Go', onPressed: () {}, style: s),
  ),
  'text button': _Part(
    RawCorner.small,
    (s) => ComicButton.text('Later', onPressed: () {}, style: s),
    quiet: true,
  ),
  'icon button': _Part(
    RawCorner.small,
    (s) => ComicIconButton(
      ComicGlyphs.search,
      semanticLabel: 'Search',
      onPressed: () {},
      style: s,
    ),
  ),
  'checkbox': _Part(
    RawCorner.small,
    (s) => ComicCheckbox(
      semanticLabel: 'Keep issue',
      value: false,
      onChanged: (_) {},
      style: s,
    ),
    held: (shape) => comicCappedShape(shape, 7),
  ),
  'switch': _Part(
    RawCorner.extraSmall,
    (s) => ComicSwitch(value: true, onChanged: (_) {}, style: s),
  ),
  'text field': _Part(
    RawCorner.small,
    (s) => ComicTextField(hintText: 'Name', style: s),
  ),
  'select field': _Part(
    RawCorner.small,
    (s) => ComicSelectField(
      labelText: 'Account',
      value: 'Current',
      onPressed: () {},
      style: s,
    ),
  ),
  'chip': _Part(
    RawCorner.extraSmall,
    (s) => ComicChip('Paper', onPressed: () {}, style: s),
  ),
  'slider': _Part(
    RawCorner.extraSmall,
    (s) => ComicSlider(label: 'Level', value: .7, onChanged: (_) {}, style: s),
  ),
  'segmented button': _Part(
    RawCorner.extraSmall,
    (s) => ComicSegmentedButton<int>(
      semanticLabel: 'View',
      value: 1,
      segments: const [
        ComicButtonSegment(1, 'Day'),
        ComicButtonSegment(2, 'Week'),
      ],
      onChanged: (_) {},
      style: s,
    ),
  ),
  'card': _Part(
    RawCorner.medium,
    (s) => ComicCard(
      title: 'Issue',
      style: s,
      children: const [SizedBox(height: 40)],
    ),
  ),
  'dialog': _Part(
    RawCorner.large,
    (s) => ComicDialog(
      title: 'Issue',
      content: const [SizedBox(height: 40)],
      style: s,
    ),
  ),
  'bottom sheet': _Part(
    RawCorner.large,
    (s) => ComicBottomSheet(
      showClose: false,
      style: s,
      child: const SizedBox(height: 100),
    ),
  ),
  'sheet': _Part(
    RawCorner.large,
    (s) => ComicSheet(
      title: 'Filters',
      style: s,
      child: const Text('Only unread'),
    ),
  ),
  'menu': _Part(
    RawCorner.medium,
    (s) => ComicMenu<String>(
      items: const [ComicMenuItem('a', 'Share')],
      onSelected: (_) {},
      style: s,
    ),
  ),
  'snack bar': _Part(RawCorner.medium, (s) => ComicSnackBar('Saved', style: s)),
  'tooltip': _Part(
    RawCorner.medium,
    (s) => ComicTooltipFace(message: 'Save this issue', style: s),
  ),
  'badge': _Part(RawCorner.extraSmall, (s) => ComicBadge(5, style: s)),
  'choice box': _Part(
    RawCorner.small,
    (s) => ComicChoiceBox(
      onPressed: () {},
      style: s,
      child: const SizedBox(width: 100, height: 40),
    ),
  ),
  'number field': _Part(
    RawCorner.small,
    (s) => ComicNumberField(value: 3, onChanged: (_) {}, style: s),
  ),
  'date picker': _Part(
    RawCorner.small,
    (s) => ComicDatePicker(
      value: DateTime(2026, 11, 6),
      currentDate: DateTime(2026, 11, 6),
      onChanged: (_) {},
      style: s,
    ),
  ),
  'code field': _Part(
    RawCorner.small,
    (s) => ComicInputOtp(labelText: 'Code', length: 4, style: s),
  ),
  'panel': _Part(
    RawCorner.medium,
    (s) => ComicPanel(style: s, child: const SizedBox(width: 160, height: 60)),
  ),
  'well': _Part(
    RawCorner.medium,
    (s) => ComicWell(style: s, child: const Text('30 min')),
  ),
  'raised frame': _Part(
    RawCorner.medium,
    (s) => ComicRaisedFrame(
      style: s,
      child: const SizedBox(width: 160, height: 60),
    ),
  ),
  'link': _Part(
    RawCorner.small,
    (s) => ComicLink('Read the issue', onPressed: () {}, style: s),
    quiet: true,
  ),
  // The range slider takes its style from the theme's slider style.
  'range slider': _Part(
    RawCorner.extraSmall,
    (s) => Builder(
      builder: (context) => ComicTheme(
        data: ComicTheme.of(context).copyWith(sliderTheme: s),
        child: ComicRangeSlider(
          label: 'Price',
          values: const RawRangeValues(.2, .7),
          onChanged: (_) {},
        ),
      ),
    ),
  ),
  'caption': _Part(
    RawCorner.small,
    (s) => ComicCaption('Meanwhile, by the lake', style: s),
  ),
};

// A fresh app each time: no focus or shape carried over from the last drawing.
Widget _host(TextDirection direction, Widget child) => MaterialApp(
  key: UniqueKey(),
  localizationsDelegates: const [ComicLocalizations.delegate],
  home: Directionality(
    textDirection: direction,
    child: ComicTheme(
      data: _rounded,
      child: Center(
        child: RepaintBoundary(
          key: _shot,
          child: ColoredBox(
            color: _rounded.colors.background,
            child: SizedBox(width: 360, child: Center(child: child)),
          ),
        ),
      ),
    ),
  ),
);

Future<Uint8List> _drawn(
  WidgetTester tester,
  TextDirection direction,
  Widget part, {
  bool focus = false,
  bool hover = false,
}) async {
  await tester.pumpWidget(_host(direction, part));
  if (focus) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
  }
  TestGesture? mouse;
  if (hover) {
    await tester.pump();
    mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: tester.getCenter(find.byKey(_shot)));
  }
  await tester.pumpAndSettle();
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_shot),
  );
  final bytes = await tester.runAsync(() async {
    final image = await boundary.toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    return data!.buffer.asUint8List();
  });
  await mouse?.removePointer();
  return bytes!;
}

int _differ(Uint8List a, Uint8List b) {
  if (a.length != b.length) return -1;
  var n = 0;
  for (var i = 0; i < a.length; i += 4) {
    if (a[i] != b[i] ||
        a[i + 1] != b[i + 1] ||
        a[i + 2] != b[i + 2] ||
        a[i + 3] != b[i + 3]) {
      n++;
    }
  }
  return n;
}

/// [corners] on [_rounded]'s scale as a plain outline, its start and end placed for [direction].
OutlinedBorder _physical(RawCorners corners, TextDirection direction) {
  Radius at(RawCorner? step) =>
      Radius.circular(_radii[step ?? RawCorner.none]!);
  return RoundedRectangleBorder(
    borderRadius: BorderRadiusDirectional.only(
      topStart: at(corners.topStart),
      topEnd: at(corners.topEnd),
      bottomStart: at(corners.bottomStart),
      bottomEnd: at(corners.bottomEnd),
    ).resolve(direction),
  );
}

ComicStyle _corners(RawCorners corners) =>
    ComicStyle(corners: WidgetStatePropertyAll(corners));
ComicStyle _shape(OutlinedBorder shape) =>
    ComicStyle(shape: WidgetStatePropertyAll(shape));

/// Two diagonal corners rounded at the medium step, the other two square.
const _diagonal = RawCorners(
  topStart: RawCorner.medium,
  topEnd: RawCorner.none,
  bottomStart: RawCorner.none,
  bottomEnd: RawCorner.medium,
);
const _diagonalDrawn = RoundedRectangleBorder(
  borderRadius: BorderRadiusDirectional.only(
    topStart: Radius.circular(12),
    bottomEnd: Radius.circular(12),
  ),
);

/// Only the top start corner rounded, at the large step.
const _topStart = RawCorners.only(topStart: RawCorner.large);

void main() {
  for (final direction in TextDirection.values) {
    for (final MapEntry(key: name, value: part) in _parts.entries) {
      testWidgets(
        '${direction.name}: a $name draws its corners where they stand, its own at the rest',
        (tester) async {
          final own = await _drawn(
            tester,
            direction,
            part.build(null),
            hover: part.quiet,
          );
          for (final corners in [
            _diagonal,
            _topStart,
            // Only one corner named: the other three keep the part's own step.
            const RawCorners(topEnd: RawCorner.none),
          ]) {
            final given = await _drawn(
              tester,
              direction,
              part.build(_corners(corners)),
              hover: part.quiet,
            );
            // The outline those corners make, as the screen's left and right in this direction.
            final drawn = _physical(
              corners.over(RawCorners.all(part.step)),
              direction,
            );
            final shaped = await _drawn(
              tester,
              direction,
              part.build(_shape(part.held?.call(drawn) ?? drawn)),
              hover: part.quiet,
            );
            expect(
              _differ(given, shaped),
              0,
              reason: '$corners: drawn as $drawn',
            );
            expect(
              _differ(given, own),
              greaterThan(0),
              reason: '$corners: not its own corners',
            );
          }
        },
      );
    }
  }

  testWidgets('a shape wins over corners, as given', (tester) async {
    const shape = BeveledRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(6)),
    );
    for (final name in const ['filled button', 'card', 'text field']) {
      final part = _parts[name]!;
      final both = await _drawn(
        tester,
        TextDirection.ltr,
        part.build(
          _shape(shape)
              .copyWith(corners: const WidgetStatePropertyAll(_topStart)),
        ),
      );
      final alone = await _drawn(
        tester,
        TextDirection.ltr,
        part.build(_shape(shape)),
      );
      expect(_differ(both, alone), 0, reason: name);
    }
  });

  testWidgets(
    'a full or extra large corner stands at large, and debug says so once',
    (tester) async {
      final said = <String>[];
      final print = debugPrint;
      debugPrint = (message, {wrapWidth}) => said.add(message ?? '');
      final part = _parts['card']!;
      final Uint8List large;
      final asked = <RawCorner, Uint8List>{};
      try {
        large = await _drawn(
          tester,
          TextDirection.ltr,
          part.build(_corners(_topStart)),
        );
        for (final step in const [RawCorner.full, RawCorner.extraLarge]) {
          asked[step] = await _drawn(
            tester,
            TextDirection.ltr,
            part.build(_corners(RawCorners.only(topStart: step))),
          );
        }
      } finally {
        // Flutter checks its debug hooks are back before a test ends.
        debugPrint = print;
      }
      for (final MapEntry(key: step, value: drawn) in asked.entries) {
        expect(_differ(drawn, large), 0, reason: '$step');
      }
      for (final step in const ['full', 'extraLarge']) {
        expect(
          said
              .where(
                (line) => line.startsWith('Comic holds corner $step to large'),
              )
              .length,
          1,
          reason: said.join('\n'),
        );
      }
    },
  );

  testWidgets('a focused part\'s ring follows its corners', (tester) async {
    for (final name in const ['filled button', 'chip', 'icon button']) {
      final part = _parts[name]!;
      final given = await _drawn(
        tester,
        TextDirection.ltr,
        part.build(_corners(_diagonal)),
        focus: true,
      );
      final shaped = await _drawn(
        tester,
        TextDirection.ltr,
        part.build(_shape(_diagonalDrawn)),
        focus: true,
      );
      expect(_differ(given, shaped), 0, reason: name);
    }
    // Corners for focus only: the ring takes the focused state's corners.
    for (final name in const ['filled button', 'chip']) {
      final part = _parts[name]!;
      final given = await _drawn(
        tester,
        TextDirection.rtl,
        part.build(
          ComicStyle(
            corners: WidgetStateProperty.resolveWith(
              (states) =>
                  states.contains(WidgetState.focused) ? _diagonal : null,
            ),
          ),
        ),
        focus: true,
      );
      final shaped = await _drawn(
        tester,
        TextDirection.rtl,
        part.build(
          ComicStyle(
            shape: WidgetStateProperty.resolveWith(
              (states) =>
                  states.contains(WidgetState.focused) ? _diagonalDrawn : null,
            ),
          ),
        ),
        focus: true,
      );
      expect(_differ(given, shaped), 0, reason: '$name focused');
    }
  });

  testWidgets('a pressed change of corners morphs without a jump', (
    tester,
  ) async {
    final style = ComicStyle(
      corners: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.pressed) ? _topStart : null,
      ),
    );
    await tester.pumpWidget(
      _host(TextDirection.ltr, _parts['filled button']!.build(style)),
    );
    await tester.pumpAndSettle();
    double corner(Radius Function(BorderRadius) at) {
      final box = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byType(ComicButton),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      final shape =
          (box.decoration as ShapeDecoration).shape as RoundedRectangleBorder;
      return at(shape.borderRadius.resolve(TextDirection.ltr)).x;
    }

    expect(corner((r) => r.topLeft), 8);
    expect(corner((r) => r.topRight), 8);
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(ComicButton)),
    );
    final start = <double>[], end = <double>[];
    for (var i = 0; i < 40; i++) {
      start.add(corner((r) => r.topLeft));
      end.add(corner((r) => r.topRight));
      await tester.pump(const Duration(milliseconds: 8));
    }
    await gesture.up();
    await tester.pumpAndSettle();
    expect((start.last, end.last), (16.0, 0.0));
    for (final (what, frames, whole) in [
      ('top start', start, 8.0),
      ('top end', end, 8.0),
    ]) {
      for (var i = 1; i < frames.length; i++) {
        expect(
          (frames[i] - frames[i - 1]).abs(),
          lessThanOrEqualTo(whole / 2),
          reason: '$what jumped at frame $i',
        );
      }
      expect(
        frames.toSet().length,
        greaterThan(3),
        reason: '$what moved in steps: $frames',
      );
    }
  });
}
