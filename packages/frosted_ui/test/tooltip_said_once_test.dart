// A FrostedTooltip that says its control's own label again leaves the
// semantics, so a screen reader hears the label once: an app bar's back key
// with the tooltip "Back" is "Back", not "Back, Back" (as Material's
// IconButton says its tooltip once). A tooltip with words of its own stays
// the control's tooltip.
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_ui/material_ui.dart'
    show IconButton, Icons, MaterialApp, Scaffold;

void _none() {}

Future<SemanticsData> _node(WidgetTester tester, Widget part, Finder at) async {
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, app) => FrostedHost(child: app!),
      home: Center(child: part),
    ),
  );
  return tester.getSemantics(at).getSemanticsData();
}

void main() {
  testWidgets('a tooltip that repeats the label is heard once', (tester) async {
    final handle = tester.ensureSemantics();
    final data = await _node(
      tester,
      const FrostedTooltip(
        message: 'Back',
        child: FrostedIconButton(
          FrostedGlyphs.back,
          semanticLabel: 'Back',
          onPressed: _none,
        ),
      ),
      find.byType(FrostedIconButton),
    );
    expect(data.label, 'Back');
    expect(data.tooltip, isEmpty);
    expect(data.flagsCollection.isButton, isTrue);
    handle.dispose();
  });

  testWidgets("a tooltip's words of its own stay its tooltip", (tester) async {
    final handle = tester.ensureSemantics();
    final data = await _node(
      tester,
      const FrostedTooltip(
        message: 'Copy the link',
        child: FrostedIconButton(
          FrostedGlyphs.share,
          semanticLabel: 'Share',
          onPressed: _none,
        ),
      ),
      find.byType(FrostedIconButton),
    );
    expect(data.label, 'Share');
    expect(data.tooltip, 'Copy the link');
    handle.dispose();
  });

  testWidgets("a pushed page's top-bar Back is heard once", (tester) async {
    final handle = tester.ensureSemantics();
    addTearDown(tester.view.reset);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, app) => FrostedHost(child: app!),
        home: Builder(
          builder: (context) => FrostedScaffold(
            topBar: const FrostedAppBar(title: 'Books'),
            body: FrostedButton(
              'Open',
              onPressed: () => Navigator.of(context).push(
                PageRouteBuilder<void>(
                  pageBuilder: (context, _, _) => const FrostedScaffold(
                    topBar: FrostedAppBar(title: 'Dune'),
                    body: Text('A book'),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    final data = tester
        .getSemantics(find.bySemanticsLabel('Back'))
        .getSemanticsData();
    expect(data.label, 'Back');
    expect(data.tooltip, isEmpty);
    handle.dispose();
  });

  testWidgets("Material's IconButton says its tooltip once", (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: IconButton(
              tooltip: 'Back',
              icon: const Icon(Icons.arrow_back),
              onPressed: () {},
            ),
          ),
        ),
      ),
    );
    final data = tester
        .getSemantics(find.byType(IconButton))
        .getSemanticsData();
    // Once: the words stand in the label or the tooltip, never both.
    expect('${data.label}|${data.tooltip}', anyOf('Back|', '|Back'));
    handle.dispose();
  });
}
