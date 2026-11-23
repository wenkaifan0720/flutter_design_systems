// A control in a form field changes state through a tap or a step on the
// semantics tree (a screen reader's, or a click on the web with semantics
// on): a spin button, a slider, a range slider, a switch, a checkbox, a
// rating and a rating display. One control is one node with the field's
// label; a spin button's entry and steppers and a range slider's thumbs
// keep their own nodes, and nothing the field adds takes a click meant for
// a stepper. The label is read once, and ui_core's DesignFieldSemanticsCheck
// holds each. An entry beside a button of its own keeps a node as large as
// its frame, and an info label leaves the label's words to the field.
import 'package:fluent2_design_ui/fluent2_design_host.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core_test/ui_core_test.dart';

import 'gallery_support.dart' show loadFluent2TestFonts;

const _field = 'Field label';

// The control as an app gives it to a field: placed, not wrapped (a
// builder round it would hide what it is from the field).
Widget _app(
  StatefulWidgetBuilder control, {
  bool? merge,
  String label = _field,
  String? info,
}) => WidgetsApp(
  color: const Color(0xFF000000),
  localizationsDelegates: const [
    RawWidgetsLocalizations.delegate,
    Fluent2Localizations.delegate,
  ],
  builder: (context, child) => Fluent2Host(child: child!),
  onGenerateRoute: (settings) => PageRouteBuilder<void>(
    settings: settings,
    pageBuilder: (context, _, _) => Align(
      alignment: AlignmentDirectional.topStart,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: 360,
          child: StatefulBuilder(
            builder: (context, set) => Fluent2FormField(
              labelText: label,
              info: info,
              helperText: 'Some help',
              mergeSemantics: merge,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: control(context, set),
              ),
            ),
          ),
        ),
      ),
    ),
  ),
);

SemanticsNode _root(WidgetTester tester) =>
    tester.binding.renderViews.first.owner!.semanticsOwner!.rootSemanticsNode!;

// Every node with its rect on the screen.
List<(SemanticsNode, Rect)> _nodes(WidgetTester tester) {
  final out = <(SemanticsNode, Rect)>[];
  void visit(SemanticsNode node, Matrix4 toScreen) {
    final here = node.transform == null
        ? toScreen
        : (toScreen.clone()..multiply(node.transform!));
    out.add((node, MatrixUtils.transformRect(here, node.rect)));
    node.visitChildren((child) {
      visit(child, here);
      return true;
    });
  }

  visit(_root(tester), Matrix4.identity());
  return out;
}

// The deepest node at [point] that takes [action].
SemanticsNode? _takes(
  WidgetTester tester,
  Offset point,
  SemanticsAction action,
) {
  SemanticsNode? found;
  for (final (node, rect) in _nodes(tester)) {
    if (rect.contains(point) &&
        node.getSemanticsData().hasAction(action) &&
        !node.isMergedIntoParent) {
      found = node;
    }
  }
  return found;
}

int _saidTimes(WidgetTester tester, String words) {
  var n = 0;
  for (final (node, _) in _nodes(tester)) {
    if (node.isMergedIntoParent) continue;
    final data = node.getSemanticsData();
    n += words.allMatches(data.label).length;
  }
  return n;
}

void _act(WidgetTester tester, SemanticsNode node, SemanticsAction action) =>
    tester.binding.renderViews.first.owner!.semanticsOwner!.performAction(
      node.id,
      action,
    );

// ui_core's check over the field: a node for each control, no node over a
// stepper's button that takes its tap, the label read once.
void _holds(WidgetTester tester) =>
    const DesignFieldSemanticsCheck(look: 'Fluent 2')
        .check(tester.element(find.byType(Fluent2FormField)))
        .verify();

void main() {
  setUpAll(loadFluent2TestFonts);

  Future<void> pump(
    WidgetTester tester,
    StatefulWidgetBuilder control, {
    bool? merge,
  }) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(control, merge: merge));
    await tester.pumpAndSettle();
  }

  testWidgets('a spin button steps through its own node, and a click on a '
      'stepper reaches the stepper', (tester) async {
    final semantics = tester.ensureSemantics();
    var value = 45;
    await pump(
      tester,
      (context, set) => Fluent2SpinButton(
        value: value,
        min: 0,
        max: 600,
        step: 15,
        onChanged: (v) => set(() => value = v.toInt()),
      ),
    );
    final spin = tester.getRect(find.byType(Fluent2SpinButton));
    final entry = tester.getCenter(
      find.descendant(
        of: find.byType(Fluent2SpinButton),
        matching: find.byType(EditableText),
      ),
    );
    final node = _takes(tester, entry, SemanticsAction.increase);
    expect(node, isNotNull);
    _act(tester, node!, SemanticsAction.increase);
    await tester.pumpAndSettle();
    expect(value, 60);
    // On the web a click on a node that takes a tap goes to that node: the
    // up stepper's place must not be under one, or the click focuses the
    // editor and steps nothing.
    final up = Offset(spin.right - 12, spin.top + 6);
    final under = _takes(tester, up, SemanticsAction.tap);
    expect(under, isNull, reason: '${under?.getSemanticsData()}');
    expect(_saidTimes(tester, _field), 1);
    _holds(tester);
    semantics.dispose();
  });

  testWidgets('a slider steps through its own node', (tester) async {
    final semantics = tester.ensureSemantics();
    var value = 40.0;
    await pump(
      tester,
      (context, set) => Fluent2Slider(
        label: 'level',
        value: value,
        step: 10,
        onChanged: (v) => set(() => value = v),
      ),
    );
    final at = tester.getRect(find.byType(Fluent2Slider)).center;
    final node = _takes(tester, at, SemanticsAction.increase);
    expect(node, isNotNull);
    _act(tester, node!, SemanticsAction.increase);
    await tester.pumpAndSettle();
    expect(value, greaterThan(40));
    expect(_saidTimes(tester, _field), 1);
    expect(_saidTimes(tester, 'level'), 1);
    _holds(tester);
    semantics.dispose();
  });

  testWidgets('a range slider steps each thumb through its own node', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    var values = const RawRangeValues(20, 60);
    await pump(
      tester,
      (context, set) => SizedBox(
        width: 300,
        child: Fluent2RangeSlider(
          label: 'window',
          values: values,
          divisions: 10,
          onChanged: (v) => set(() => values = v),
        ),
      ),
    );
    final steps = _nodes(tester)
        .where(
          (n) =>
              !n.$1.isMergedIntoParent &&
              n.$1.getSemanticsData().hasAction(SemanticsAction.increase),
        )
        .toList();
    expect(steps, hasLength(2));
    _act(tester, steps.first.$1, SemanticsAction.increase);
    await tester.pumpAndSettle();
    expect(values, isNot(const RawRangeValues(20, 60)));
    expect(_saidTimes(tester, _field), 1);
    _holds(tester);
    semantics.dispose();
  });

  for (final kind in ['switch', 'checkbox']) {
    testWidgets('a $kind toggles through its own node', (tester) async {
      final semantics = tester.ensureSemantics();
      var on = false;
      await pump(
        tester,
        (context, set) => kind == 'switch'
            ? Fluent2Switch(
                semanticLabel: kind,
                value: on,
                onChanged: (v) => set(() => on = v),
              )
            : Fluent2Checkbox(
                semanticLabel: kind,
                value: on,
                onChanged: (v) => set(() => on = v),
              ),
      );
      final at = tester
          .getRect(
            find.byType(kind == 'switch' ? Fluent2Switch : Fluent2Checkbox),
          )
          .center;
      final node = _takes(tester, at, SemanticsAction.tap);
      expect(node, isNotNull);
      _act(tester, node!, SemanticsAction.tap);
      await tester.pumpAndSettle();
      expect(on, isTrue);
      expect(_saidTimes(tester, _field), 1);
      expect(_saidTimes(tester, kind), 1);
      _holds(tester);
      semantics.dispose();
    });
  }

  testWidgets('a rating takes a choice through its own nodes', (tester) async {
    final semantics = tester.ensureSemantics();
    var value = 2.0;
    await pump(
      tester,
      (context, set) => Fluent2Rating(
        label: 'stars',
        value: value,
        onChanged: (v) => set(() => value = v),
      ),
    );
    final at = tester.getRect(find.byType(Fluent2Rating)).center;
    final node =
        _takes(tester, at, SemanticsAction.tap) ??
        _takes(tester, at, SemanticsAction.increase);
    expect(node, isNotNull);
    _act(
      tester,
      node!,
      node.getSemanticsData().hasAction(SemanticsAction.tap)
          ? SemanticsAction.tap
          : SemanticsAction.increase,
    );
    await tester.pumpAndSettle();
    expect(value, isNot(2.0));
    expect(_saidTimes(tester, _field), 1);
    _holds(tester);
    semantics.dispose();
  });

  testWidgets('a rating display says its value with the label', (tester) async {
    final semantics = tester.ensureSemantics();
    await pump(
      tester,
      (context, set) => const Fluent2RatingDisplay(value: 4, count: 12),
    );
    final at = tester.getRect(find.byType(Fluent2RatingDisplay)).center;
    final said = [
      for (final (node, rect) in _nodes(tester))
        if (!node.isMergedIntoParent && rect.contains(at))
          node.getSemanticsData().label,
    ].join('\n');
    expect(said, contains('4'));
    expect(said, contains('12'));
    expect(_saidTimes(tester, _field), 1);
    _holds(tester);
    semantics.dispose();
  });

  testWidgets("a password field with a message keeps its entry's node the "
      "frame's size beside the reveal button's", (tester) async {
    final semantics = tester.ensureSemantics();
    await pump(
      tester,
      (context, set) => Fluent2PasswordField(
        label: 'New password',
        value: 'abc',
        onChanged: (_) {},
        validationMessage: 'Use at least 8 characters',
      ),
    );
    final entry = _nodes(tester).where(
      (n) =>
          !n.$1.isMergedIntoParent &&
          n.$1.getSemanticsData().flagsCollection.isTextField,
    );
    expect(entry, hasLength(1));
    // A medium field's frame is 32 tall; its line of words is 20.
    expect(entry.single.$2.height, greaterThanOrEqualTo(32));
    expect(_saidTimes(tester, 'New password'), 1);
    semantics.dispose();
  });

  testWidgets("a field's info label leaves the label to the field and says "
      'its button', (tester) async {
    final semantics = tester.ensureSemantics();
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _app(
        (context, set) => Fluent2TextField(value: '30', onChanged: (_) {}),
        label: 'Keep deleted files',
        info: 'After this many days, files in the bin are gone.',
      ),
    );
    await tester.pumpAndSettle();
    // The field's node, and the button "Information about" it.
    expect(_saidTimes(tester, 'Keep deleted files'), 2);
    expect(
      _nodes(tester).where(
        (n) =>
            !n.$1.isMergedIntoParent &&
            n.$1.getSemanticsData().label.startsWith('Keep deleted files'),
      ),
      hasLength(1),
    );
    _holds(tester);
    semantics.dispose();
  });

  testWidgets('mergeSemantics true makes one node of the child, false keeps '
      "each control's", (tester) async {
    final semantics = tester.ensureSemantics();
    var values = const RawRangeValues(20, 60);
    Widget range(BuildContext context, StateSetter set) => SizedBox(
      width: 300,
      child: Fluent2RangeSlider(
        label: 'window',
        values: values,
        divisions: 10,
        onChanged: (v) => set(() => values = v),
      ),
    );
    int steppers() => _nodes(tester)
        .where(
          (n) =>
              !n.$1.isMergedIntoParent &&
              n.$1.getSemanticsData().hasAction(SemanticsAction.increase),
        )
        .length;
    await pump(tester, range, merge: true);
    expect(steppers(), 1);

    // A new app: the route the first one built would keep its control.
    await tester.pumpWidget(const SizedBox.shrink());
    var on = false;
    await pump(
      tester,
      (context, set) => Fluent2Switch(
        semanticLabel: 'switch',
        value: on,
        onChanged: (v) => set(() => on = v),
      ),
      merge: false,
    );
    final at = tester.getRect(find.byType(Fluent2Switch)).center;
    final node = _takes(tester, at, SemanticsAction.tap)!;
    expect(node.getSemanticsData().label, isNot(contains(_field)));
    expect(_saidTimes(tester, _field), 1);
    semantics.dispose();
  });
}
