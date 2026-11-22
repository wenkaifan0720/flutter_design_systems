// RenderDesignSemanticsProxy: the one public type of every render object
// ui_core puts round a control only to add semantics (round a labelled
// RawButton's face, a RawInputDecorator's control, a RawTabGroup's tabs),
// so a layout that looks through such proxies by type (css_box hosts
// nested flows through them) names one type for all.
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

import 'behaviour_harness.dart';

List<RenderDesignSemanticsProxy> _proxies(WidgetTester tester, Finder at) {
  final found = <RenderDesignSemanticsProxy>[];
  void visit(RenderObject node) {
    if (node is RenderDesignSemanticsProxy) found.add(node);
    node.visitChildren(visit);
  }

  visit(tester.renderObject(at));
  return found;
}

const _face = ValueKey('face');

void main() {
  testWidgets('a labelled button puts one round its face: it lays out as its '
      "face, and the face's own words are heard once", (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      harness(
        Center(
          child: RawButton(
            semanticLabel: 'Save',
            semanticValue: 'Draft',
            onPressed: () {},
            builder: (context, states, _) => const SizedBox(
              key: _face,
              width: 80,
              height: 32,
              child: Text('Save'),
            ),
          ),
        ),
      ),
    );
    final proxy = _proxies(tester, find.byType(RawButton)).single;
    expect(proxy, isA<RenderProxyBox>());
    expect(proxy.size, tester.getSize(find.byKey(_face)));
    expect(
      tester.getSemantics(find.byType(RawButton)),
      matchesSemantics(
        label: 'Save',
        value: 'Draft',
        isButton: true,
        hasTapAction: true,
        hasFocusAction: true,
        isFocusable: true,
        hasEnabledState: true,
        isEnabled: true,
      ),
    );
    semantics.dispose();
  });

  testWidgets('a button with no words of its own puts none', (tester) async {
    await tester.pumpWidget(
      harness(
        Center(
          child: RawButton(
            onPressed: () {},
            builder: (context, states, _) => const Text('Save'),
          ),
        ),
      ),
    );
    expect(_proxies(tester, find.byType(RawButton)), isEmpty);
  });

  testWidgets('new words update it in place', (tester) async {
    final semantics = tester.ensureSemantics();
    Widget button(String label) => harness(
      Center(
        child: RawButton(
          semanticLabel: label,
          onPressed: () {},
          builder: (context, states, _) => Text(label),
        ),
      ),
    );
    await tester.pumpWidget(button('Save'));
    final first = _proxies(tester, find.byType(RawButton)).single;
    await tester.pumpWidget(button('Saved'));
    expect(_proxies(tester, find.byType(RawButton)).single, same(first));
    expect(
      tester.getSemantics(find.byType(RawButton)).getSemanticsData().label,
      'Saved',
    );
    semantics.dispose();
  });

  testWidgets("a field puts one round its control, the size of the field's "
      'parts', (tester) async {
    await tester.pumpWidget(
      harness(
        Center(
          child: RawInputDecorator(
            labelText: 'Email',
            builder: (context, parts) => parts.control,
            child: const SizedBox(key: _face, width: 120, height: 24),
          ),
        ),
      ),
    );
    final proxy = _proxies(tester, find.byType(RawInputDecorator)).single;
    expect(proxy.size, tester.getSize(find.byKey(_face)));
  });

  testWidgets("a tab group's node is one, the size of the caller's row", (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        Center(
          child: RawTabGroup<int>(
            groupValue: 0,
            onChanged: (_) {},
            child: Row(
              key: _face,
              mainAxisSize: MainAxisSize.min,
              children: [
                RawTabGroupTab(
                  value: 0,
                  builder: (context, states, _) => const Text('Overview'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    final proxy = _proxies(tester, find.byType(RawTabGroup<int>)).first;
    expect(proxy.size, tester.getSize(find.byKey(_face)));
  });
}
