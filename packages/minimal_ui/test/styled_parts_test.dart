// Per-part styles and the theme-wide knobs, read back from what each part
// paints: the look's own frames are unchanged at the defaults; a part's
// `style:` beats its component theme, which beats the knobs, which beat
// the look; and a hovering pointer changes nothing (polish round 3, §1).
import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

final MinimalThemeData _look = MinimalThemeData.preset(
  'standard',
  Brightness.light,
);

Widget _host(Widget child, [MinimalThemeData? theme]) => MaterialApp(
  builder: (context, navigator) => MinimalHost(
    light: theme ?? _look,
    dark: theme ?? _look,
    brightness: Brightness.light,
    child: navigator!,
  ),
  home: Scaffold(
    body: Center(
      child: Padding(padding: const EdgeInsets.all(24), child: child),
    ),
  ),
);

const Key _part = Key('part');

/// The [index]th background decoration a part paints: its frame first.
Finder _framed({int index = 0}) => find
    .descendant(
      of: find.byKey(_part),
      matching: find.byWidgetPredicate(
        (w) => w is DecoratedBox && w.position == DecorationPosition.background,
      ),
    )
    .at(index);

Decoration _frame(WidgetTester tester, {int index = 0}) =>
    tester.widget<DecoratedBox>(_framed(index: index)).decoration;

Color? _fill(Decoration d) => switch (d) {
  BoxDecoration(:final color) => color,
  ShapeDecoration(:final color) => color,
  _ => null,
};

/// A part's call shape for one style, and the component theme that carries
/// a style to every one like it.
typedef _Case = ({
  String name,
  Widget Function(MinimalStyle? style) build,
  MinimalComponentThemes Function(MinimalStyle style) themed,
  int frame,
});

final List<_Case> _cases = [
  (
    name: 'primary button',
    build: (s) => MinimalButton('Save', onPressed: () {}, style: s),
    themed: (s) => MinimalComponentThemes(primaryButton: s),
    frame: 0,
  ),
  (
    name: 'secondary button',
    build: (s) => MinimalButton(
      'Keep',
      onPressed: () {},
      variant: MinimalButtonVariant.secondary,
      style: s,
    ),
    themed: (s) => MinimalComponentThemes(secondaryButton: s),
    frame: 0,
  ),
  (
    name: 'danger button',
    build: (s) => MinimalButton(
      'Delete',
      onPressed: () {},
      variant: MinimalButtonVariant.destructive,
      style: s,
    ),
    themed: (s) => MinimalComponentThemes(destructiveButton: s),
    frame: 0,
  ),
  (
    name: 'icon button',
    build: (s) => MinimalIconButton(
      LucideIcons.plus,
      label: 'Add',
      onPressed: () {},
      variant: MinimalIconButtonVariant.secondary,
      style: s,
    ),
    themed: (s) => MinimalComponentThemes(iconButton: s),
    frame: 0,
  ),
  (
    name: 'chip',
    build: (s) => MinimalChip('Open', onPressed: () {}, style: s),
    themed: (s) => MinimalComponentThemes(chip: s),
    frame: 0,
  ),
  (
    name: 'text field',
    build: (s) => SizedBox(
      width: 240,
      child: MinimalTextField(hint: 'Name', fieldStyle: s),
    ),
    themed: (s) => MinimalComponentThemes(textField: s),
    frame: 0,
  ),
  (
    name: 'checkbox',
    build: (s) => MinimalCheckbox(
      value: true,
      label: 'Done',
      onChanged: (_) {},
      style: s,
    ),
    themed: (s) => MinimalComponentThemes(checkbox: s),
    frame: 0,
  ),
  (
    name: 'switch',
    build: (s) => MinimalSwitch(
      value: true,
      label: 'Reminders',
      onChanged: (_) {},
      style: s,
    ),
    themed: (s) => MinimalComponentThemes(switchTheme: s),
    frame: 0,
  ),
  (
    name: 'segmented button',
    build: (s) => SizedBox(
      width: 240,
      child: MinimalSegmentedButton<int>(
        segments: const [
          MinimalButtonSegment(0, 'Week'),
          MinimalButtonSegment(1, 'Month'),
        ],
        value: 0,
        onChanged: (_) {},
        style: s,
      ),
    ),
    themed: (s) => MinimalComponentThemes(segmentedButton: s),
    // The thumb: the strip's own fill is the well.
    frame: 1,
  ),
  (
    name: 'card',
    build: (s) => MinimalCard(style: s, child: const Text('Plan')),
    themed: (s) => MinimalComponentThemes(card: s),
    frame: 0,
  ),
  (
    name: 'list section',
    build: (s) => MinimalListSection(
      inset: true,
      style: s,
      children: const [MinimalListTile(title: 'Row')],
    ),
    themed: (s) => MinimalComponentThemes(listSection: s),
    frame: 0,
  ),
  (
    name: 'dialog',
    build: (s) => MinimalDialog(title: 'Delete?', style: s),
    themed: (s) => MinimalComponentThemes(dialog: s),
    frame: 0,
  ),
  (
    name: 'bottom sheet',
    build: (s) => MinimalBottomSheet(
      title: 'New habit',
      floating: true,
      closable: false,
      style: s,
      child: const Text('Form'),
    ),
    themed: (s) => MinimalComponentThemes(bottomSheet: s),
    frame: 0,
  ),
  (
    name: 'snack bar',
    build: (s) => MinimalSnackBar('Archived', style: s),
    themed: (s) => MinimalComponentThemes(snackBar: s),
    frame: 0,
  ),
  (
    name: 'avatar',
    build: (s) => MinimalAvatar('Hanna Berg', style: s),
    themed: (s) => MinimalComponentThemes(avatar: s),
    frame: 0,
  ),
];

const Color _byTheme = Color(0xFF00AA55);
const Color _byStyle = Color(0xFFAA0055);

MinimalStyle _filled(Color c) =>
    MinimalStyle(fill: WidgetStatePropertyAll<Color?>(c));

/// What [root] paints, as lines: each canvas call with its arguments, each
/// paragraph's words and colours, each opacity.
List<String> _record(RenderObject root) {
  final canvas = TestRecordingCanvas();
  final context = TestRecordingPaintingContext(canvas);
  root.paint(context, Offset.zero);
  String describe(Object? v) => v is Path ? '${v.getBounds()}' : '$v';
  final out = <String>[
    for (final i in canvas.invocations)
      '${i.invocation.memberName}'
          '(${i.invocation.positionalArguments.map(describe).join(', ')})',
  ];
  void visit(RenderObject r) {
    if (r is RenderParagraph) {
      out.add('text ${r.text.toPlainText()} ${r.text.style?.color}');
    } else if (r is RenderOpacity) {
      out.add('opacity ${r.opacity}');
    } else if (r is RenderAnimatedOpacity) {
      out.add('opacity ${r.opacity.value}');
    }
    r.visitChildren(visit);
  }

  visit(root);
  return out;
}

void main() {
  group('the defaults draw as before', () {
    final t = _look;
    final rim = Border.all(color: t.border, width: 1);
    final expected = <String, (Widget, Decoration, int)>{
      'primary button': (
        MinimalButton('Save', onPressed: () {}),
        BoxDecoration(color: t.primary, borderRadius: BorderRadius.circular(8)),
        0,
      ),
      'secondary button': (
        MinimalButton(
          'Keep',
          onPressed: () {},
          variant: MinimalButtonVariant.secondary,
        ),
        BoxDecoration(
          color: t.card,
          borderRadius: BorderRadius.circular(8),
          border: rim,
        ),
        0,
      ),
      'outline icon button': (
        MinimalIconButton(
          LucideIcons.plus,
          label: 'Add',
          onPressed: () {},
          variant: MinimalIconButtonVariant.outline,
        ),
        BoxDecoration(
          color: t.background,
          borderRadius: BorderRadius.circular(8),
          border: rim,
        ),
        0,
      ),
      'chip': (
        MinimalChip('Open', onPressed: () {}),
        // The theme's pill shape: a capsule.
        ShapeDecoration(
          color: t.card,
          shape: StadiumBorder(side: BorderSide(color: t.border)),
        ),
        0,
      ),
      'text field': (
        const SizedBox(width: 240, child: MinimalTextField(hint: 'Name')),
        BoxDecoration(
          color: t.card,
          borderRadius: BorderRadius.circular(8),
          border: rim,
        ),
        0,
      ),
      'checkbox': (
        MinimalCheckbox(value: false, label: 'Done', onChanged: (_) {}),
        BoxDecoration(
          color: t.card,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: t.input, width: 1),
        ),
        0,
      ),
      'large checkbox': (
        MinimalCheckbox(
          value: false,
          label: 'Agree',
          size: 20,
          onChanged: (_) {},
        ),
        BoxDecoration(
          color: t.card,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: t.input, width: 1),
        ),
        0,
      ),
      'switch': (
        MinimalSwitch(value: false, label: 'Reminders', onChanged: (_) {}),
        // The theme's pill shape: a capsule track.
        ShapeDecoration(color: t.input, shape: const StadiumBorder()),
        0,
      ),
      'segmented strip': (
        SizedBox(
          width: 240,
          child: MinimalSegmentedButton<int>(
            segments: const [
              MinimalButtonSegment(0, 'Week'),
              MinimalButtonSegment(1, 'Month'),
            ],
            value: 0,
            onChanged: (_) {},
          ),
        ),
        // A hairline track on the ground, no well.
        BoxDecoration(borderRadius: BorderRadius.circular(8), border: rim),
        0,
      ),
      'segmented thumb': (
        SizedBox(
          width: 240,
          child: MinimalSegmentedButton<int>(
            segments: const [
              MinimalButtonSegment(0, 'Week'),
              MinimalButtonSegment(1, 'Month'),
            ],
            value: 0,
            onChanged: (_) {},
          ),
        ),
        // The chosen segment is a hairline in the ink, not a raised fill.
        BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: t.foreground, width: t.rim),
        ),
        1,
      ),
      // The card's ground; its rim is drawn over its content (below).
      'card': (
        const MinimalCard(child: Text('Plan')),
        BoxDecoration(color: t.card, borderRadius: BorderRadius.circular(10)),
        0,
      ),
      'dialog': (
        const MinimalDialog(title: 'Delete?'),
        BoxDecoration(
          color: t.card,
          borderRadius: BorderRadius.circular(14),
          border: rim,
        ),
        0,
      ),
      'snack bar': (
        const MinimalSnackBar('Archived'),
        BoxDecoration(
          color: t.card,
          borderRadius: BorderRadius.circular(10),
          border: rim,
          boxShadow: t.shadowMd,
        ),
        0,
      ),
    };
    for (final MapEntry(key: name, value: (part, frame, index))
        in expected.entries) {
      testWidgets(name, (tester) async {
        await tester.pumpWidget(_host(KeyedSubtree(key: _part, child: part)));
        expect(_frame(tester, index: index), frame);
      });
    }

    testWidgets('a card draws its rim over what stands in it', (tester) async {
      await tester.pumpWidget(
        _host(
          const KeyedSubtree(
            key: _part,
            child: MinimalCard(child: Text('Plan')),
          ),
        ),
      );
      final over = tester
          .widgetList<DecoratedBox>(
            find.descendant(
              of: find.byKey(_part),
              matching: find.byWidgetPredicate(
                (w) =>
                    w is DecoratedBox &&
                    w.position == DecorationPosition.foreground,
              ),
            ),
          )
          .first;
      expect(
        over.decoration,
        BoxDecoration(borderRadius: BorderRadius.circular(10), border: rim),
      );
    });

    test('the sheet card, floating and as a drawer', () {
      expect(
        MinimalBottomSheet.card(t, floating: true),
        BoxDecoration(
          color: t.card,
          border: rim,
          borderRadius: BorderRadius.circular(14),
          boxShadow: t.shadowLg,
        ),
      );
      expect(
        MinimalBottomSheet.card(t, floating: false),
        BoxDecoration(
          color: t.card,
          border: rim,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
          boxShadow: t.shadowLg,
        ),
      );
    });
  });

  group('a style beats its component theme, which beats the look', () {
    for (final c in _cases) {
      testWidgets(c.name, (tester) async {
        Future<Color?> fill(MinimalStyle? style, MinimalThemeData theme) async {
          await tester.pumpWidget(
            _host(KeyedSubtree(key: _part, child: c.build(style)), theme),
          );
          await tester.pumpAndSettle();
          return _fill(_frame(tester, index: c.frame));
        }

        final own = await fill(null, _look);
        expect(own, isNot(anyOf(_byTheme, _byStyle)));
        final themed = _look.copyWith(components: c.themed(_filled(_byTheme)));
        expect(await fill(null, themed), _byTheme, reason: 'theme over look');
        expect(
          await fill(_filled(_byStyle), themed),
          _byStyle,
          reason: 'style over theme',
        );
        final empty = _look.copyWith(
          components: c.themed(const MinimalStyle()),
        );
        expect(await fill(null, empty), own, reason: 'an empty theme');
      });
    }
  });

  group('the knobs reach the parts', () {
    Future<Decoration> buttonFrame(
      WidgetTester tester,
      MinimalThemeData theme, {
      MinimalStyle? style,
      MinimalButtonVariant variant = MinimalButtonVariant.secondary,
    }) async {
      await tester.pumpWidget(
        _host(
          KeyedSubtree(
            key: _part,
            child: MinimalButton(
              'Keep',
              onPressed: () {},
              variant: variant,
              style: style,
            ),
          ),
          theme,
        ),
      );
      await tester.pumpAndSettle();
      return _frame(tester);
    }

    testWidgets('a corner radius rounds a button and a card', (tester) async {
      final soft = _look.copyWith(shapes: const MinimalShapes(radius: 16));
      final button = await buttonFrame(tester, soft) as BoxDecoration;
      expect(button.borderRadius, BorderRadius.circular(16));
      await tester.pumpWidget(
        _host(
          const KeyedSubtree(
            key: _part,
            child: MinimalCard(child: Text('x')),
          ),
          soft,
        ),
      );
      expect(
        (_frame(tester) as BoxDecoration).borderRadius,
        BorderRadius.circular(18),
      );
    });

    testWidgets('a style\'s shape beats the knob', (tester) async {
      final frame = await buttonFrame(
        tester,
        _look.copyWith(shapes: const MinimalShapes(radius: 16)),
        style: const MinimalStyle(
          shape: WidgetStatePropertyAll<OutlinedBorder?>(
            BeveledRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(6)),
            ),
          ),
        ),
      );
      expect((frame as ShapeDecoration).shape, isA<BeveledRectangleBorder>());
    });

    testWidgets('square corners square every framed part', (tester) async {
      final square = _look.copyWith(shapes: const MinimalShapes(radius: 0));
      final button = await buttonFrame(tester, square) as BoxDecoration;
      expect(button.borderRadius, BorderRadius.zero);
      await tester.pumpWidget(
        _host(
          KeyedSubtree(
            key: _part,
            child: MinimalChip('Open', onPressed: () {}),
          ),
          square,
        ),
      );
      expect((_frame(tester) as BoxDecoration).borderRadius, BorderRadius.zero);
    });

    testWidgets('density moves a button\'s height', (tester) async {
      Future<double> height(MinimalDensity density) async {
        await buttonFrame(tester, _look.copyWith(density: density));
        return tester.getSize(_framed()).height;
      }

      expect(await height(MinimalDensity.standard), 32);
      expect(await height(MinimalDensity.comfortable), 30);
      expect(await height(MinimalDensity.compact), 28);
      expect(await height(const MinimalDensity(vertical: 4)), 40);
    });

    testWidgets('a pressed state reaches its slot', (tester) async {
      const pressed = Color(0xFF123456);
      await buttonFrame(
        tester,
        _look,
        variant: MinimalButtonVariant.primary,
        style: MinimalStyle(
          fill: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.pressed) ? pressed : null,
          ),
        ),
      );
      expect(_fill(_frame(tester)), _look.primary);
      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(_part)),
      );
      // The face eases to the pressed fill while the finger stays down.
      await tester.pumpAndSettle();
      expect(_fill(_frame(tester)), pressed);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(_fill(_frame(tester)), _look.primary);
    });
  });

  group('a hovering pointer changes nothing', () {
    final parts = <String, Widget>{
      for (final c in _cases) c.name: c.build(null),
      'ghost button': MinimalButton(
        'More',
        onPressed: () {},
        variant: MinimalButtonVariant.ghost,
      ),
      'ghost icon button': MinimalIconButton(
        LucideIcons.x,
        label: 'Close',
        onPressed: () {},
      ),
      'tappable card': MinimalCard(onPressed: () {}, child: const Text('Plan')),
      'slider': SizedBox(
        width: 240,
        child: MinimalSlider(label: 'Volume', value: 0.4, onChanged: (_) {}),
      ),
    };
    for (final MapEntry(key: name, value: part) in parts.entries) {
      testWidgets(name, (tester) async {
        await tester.pumpWidget(
          _host(RepaintBoundary(key: _part, child: part)),
        );
        await tester.pumpAndSettle();
        final box = tester.renderObject(find.byKey(_part));
        final idle = _record(box);
        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await mouse.addPointer(location: Offset.zero);
        addTearDown(mouse.removePointer);
        await mouse.moveTo(tester.getCenter(find.byKey(_part)));
        await tester.pumpAndSettle();
        expect(_record(box), idle);
      });
    }
  });

  test('a layered style falls through state by state', () {
    const a = Color(0xFF111111);
    const b = Color(0xFF222222);
    final top = MinimalStyle(
      fill: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.pressed) ? a : null,
      ),
    );
    final under = _filled(b);
    expect(MinimalStyle.first([top, under], (s) => s.fill, {}), b);
    expect(
      MinimalStyle.first([top, under], (s) => s.fill, {WidgetState.pressed}),
      a,
    );
  });
}
