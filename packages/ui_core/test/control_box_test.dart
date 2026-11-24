import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

import 'behaviour_harness.dart';

// A line exactly as tall as the type, so the numbers are the box's.
const _field = TextStyle(fontSize: 16, height: 1, color: Color(0xFF000000));

Widget _app(Widget child, {TextDirection direction = TextDirection.ltr}) =>
    MaterialApp(
      home: Directionality(
        textDirection: direction,
        child: Material(
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(width: 200, child: child),
          ),
        ),
      ),
    );

Rect _rect(WidgetTester tester, Finder finder) => tester.getRect(finder);

final _renderEditable = find.byWidgetPredicate(
  (widget) => widget.runtimeType.toString() == '_Editable',
);

void main() {
  group('RawControlBox', () {
    final content = find.byKey(const Key('content'));
    const small = SizedBox(key: Key('content'), width: 20, height: 16);

    testWidgets('is its minimum height, its content centred, and takes no '
        'more of its parent than that', (tester) async {
      await tester.pumpWidget(
        harness(
          const Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 300,
              height: 200,
              child: Align(
                alignment: Alignment.topLeft,
                child: RawControlBox(minHeight: 40, child: small),
              ),
            ),
          ),
        ),
      );
      expect(tester.getSize(find.byType(RawControlBox)), const Size(20, 40));
      expect(_rect(tester, content).top, 12);
    });

    testWidgets('a taller child grows it', (tester) async {
      await tester.pumpWidget(
        harness(
          const Align(
            alignment: Alignment.topLeft,
            child: RawControlBox(
              minHeight: 40,
              child: SizedBox(width: 20, height: 60),
            ),
          ),
        ),
      );
      expect(tester.getSize(find.byType(RawControlBox)).height, 60);
    });

    testWidgets('alignment places the child by the reading direction', (
      tester,
    ) async {
      Widget box() => const Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 200,
          child: RawControlBox(
            minHeight: 40,
            alignment: AlignmentDirectional.centerStart,
            child: small,
          ),
        ),
      );
      await tester.pumpWidget(harness(box()));
      expect(_rect(tester, content).left, 0);
      await tester.pumpWidget(harness(box(), textDirection: TextDirection.rtl));
      expect(_rect(tester, content).right, 200);
    });

    testWidgets('gives its text even leading and keeps the rest of the '
        'behaviour above it', (tester) async {
      late TextHeightBehavior seen;
      await tester.pumpWidget(
        harness(
          DefaultTextHeightBehavior(
            textHeightBehavior: const TextHeightBehavior(
              applyHeightToFirstAscent: false,
            ),
            child: RawControlBox(
              minHeight: 40,
              child: Builder(
                builder: (context) {
                  seen = DefaultTextHeightBehavior.of(context);
                  return const SizedBox();
                },
              ),
            ),
          ),
        ),
      );
      expect(seen.leadingDistribution, TextLeadingDistribution.even);
      expect(seen.applyHeightToFirstAscent, isFalse);
      expect(seen.applyHeightToLastDescent, isTrue);
    });
  });

  group('RawTextEntryBox', () {
    late TextEditingController controller;
    setUp(() => controller = TextEditingController());
    tearDown(() => controller.dispose());

    Widget bare({
      double minHeight = 40,
      int? maxLines = 1,
      TextStyle hintStyle = _field,
      FocusNode? focusNode,
    }) => RawTextEntryBox(
      minHeight: minHeight,
      controller: controller,
      hint: Text('HINT', style: hintStyle),
      maxLines: maxLines,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        style: _field,
        maxLines: maxLines,
        decoration: null,
      ),
    );

    final box = find.byType(RawTextEntryBox);
    final editable = find.byType(EditableText);

    // The second form: the decoration draws its own hint.
    InputDecoration pinned(String hint) => InputDecoration(
      isCollapsed: true,
      isDense: false,
      contentPadding: EdgeInsets.zero,
      hintText: hint,
      hintStyle: _field,
      filled: false,
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      disabledBorder: InputBorder.none,
      errorBorder: InputBorder.none,
      focusedErrorBorder: InputBorder.none,
      visualDensity: VisualDensity.standard,
      constraints: const BoxConstraints(),
    );

    testWidgets('is its minimum height with one line centred', (tester) async {
      await tester.pumpWidget(_app(bare()));
      expect(tester.getSize(box), const Size(200, 40));
      expect(_rect(tester, editable).top, 12);
      expect(_rect(tester, editable).height, 16);
    });

    testWidgets('the hint shows while empty, and typing does not move the '
        'box', (tester) async {
      await tester.pumpWidget(_app(bare()));
      expect(find.text('HINT'), findsOneWidget);
      controller.text = 'TEXT';
      await tester.pump();
      expect(find.text('HINT'), findsNothing);
      expect(tester.getSize(box), const Size(200, 40));
      controller.clear();
      await tester.pump();
      expect(find.text('HINT'), findsOneWidget);
    });

    testWidgets('a hint of another size stands on the typed baseline', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(bare(hintStyle: _field.copyWith(fontSize: 10))),
      );
      const alphabetic = TextBaseline.alphabetic;
      double line(RenderBox box) =>
          box.localToGlobal(Offset.zero).dy +
          box.getDryBaseline(box.constraints, alphabetic)!;
      expect(
        line(tester.renderObject<RenderParagraph>(find.text('HINT'))),
        line(tester.renderObject<RenderEditable>(_renderEditable)),
      );
    });

    testWidgets('a row aligned by baseline reads the typed text\'s', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(child: bare()),
              const Text('LABEL', style: _field),
            ],
          ),
        ),
      );
      expect(
        tester.getTopLeft(find.text('LABEL')).dy,
        tester.getTopLeft(editable).dy,
      );
    });

    testWidgets('around a decoration that draws its hint, draws no second', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          RawTextEntryBox(
            minHeight: 40,
            child: TextField(
              controller: controller,
              style: _field,
              decoration: pinned('HINT'),
            ),
          ),
        ),
      );
      expect(find.text('HINT'), findsOneWidget);
      expect(tester.getSize(box).height, 40);
      expect(_rect(tester, editable).top, 12);
    });

    testWidgets('several lines start where one stands, and grow the box', (
      tester,
    ) async {
      await tester.pumpWidget(_app(bare(maxLines: 3)));
      expect(_rect(tester, editable).top, 12);
      expect(_rect(tester, editable).height, 48);
      expect(tester.getSize(box).height, 72);
    });

    testWidgets('larger text grows it past its minimum', (tester) async {
      await tester.pumpWidget(
        _app(
          MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(3)),
            child: bare(),
          ),
        ),
      );
      expect(tester.getSize(box).height, 48);
      expect(_rect(tester, editable).top, 0);
    });

    testWidgets('a press above the line reaches the editable', (tester) async {
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);
      await tester.pumpWidget(_app(bare(focusNode: focusNode)));
      expect(focusNode.hasFocus, isFalse);
      await tester.tapAt(tester.getTopLeft(box) + const Offset(30, 2));
      await tester.pump();
      expect(focusNode.hasFocus, isTrue);
    });

    testWidgets('the hint is drawn only: a screen reader does not hear it '
        'from the box', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(_app(bare()));
      expect(find.bySemanticsLabel('HINT'), findsNothing);
      semantics.dispose();
    });

    testWidgets('right to left, the hint starts at the right', (tester) async {
      await tester.pumpWidget(_app(bare(), direction: TextDirection.rtl));
      expect(
        tester.getTopRight(find.text('HINT')).dx,
        tester.getTopRight(box).dx,
      );
    });

    testWidgets('answers dry and intrinsic layout as it lays out', (
      tester,
    ) async {
      await tester.pumpWidget(_app(bare(maxLines: 3)));
      final entry = tester.renderObject<RenderBox>(
        find.descendant(
          of: box,
          matching: find.byWidgetPredicate(
            (w) => w.runtimeType.toString() == '_TextEntryLayout',
          ),
        ),
      );
      const constraints = BoxConstraints(maxWidth: 200);
      expect(entry.getDryLayout(constraints), const Size(200, 72));
      expect(entry.getMinIntrinsicHeight(200), 72);
      expect(entry.getMaxIntrinsicHeight(200), 72);
      expect(entry.getMinIntrinsicWidth(72), greaterThanOrEqualTo(0));
      expect(entry.getMaxIntrinsicWidth(72), greaterThanOrEqualTo(0));
      final inner = tester.renderObject<RenderEditable>(_renderEditable);
      const alphabetic = TextBaseline.alphabetic;
      expect(
        entry.getDryBaseline(constraints, alphabetic),
        12 + inner.getDryBaseline(inner.constraints, alphabetic)!,
      );
    });

    testWidgets('a change of height, lines or direction lays it out again', (
      tester,
    ) async {
      await tester.pumpWidget(_app(bare()));
      await tester.pumpWidget(_app(bare(minHeight: 60)));
      expect(tester.getSize(box).height, 60);
      expect(_rect(tester, editable).top, 22);
      await tester.pumpWidget(_app(bare(minHeight: 60, maxLines: 2)));
      expect(tester.getSize(box).height, 76);
      await tester.pumpWidget(
        _app(bare(minHeight: 60, maxLines: 2), direction: TextDirection.rtl),
      );
      expect(
        tester.getTopRight(find.text('HINT')).dx,
        tester.getTopRight(box).dx,
      );
    });

    test('a hint needs the controller that says when it shows', () {
      expect(
        () => RawTextEntryBox(
          minHeight: 40,
          hint: const SizedBox(),
          child: const SizedBox(),
        ),
        throwsAssertionError,
      );
    });
  });
}
