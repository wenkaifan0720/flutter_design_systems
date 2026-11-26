// A top bar alone (anywhere but a scaffold's top band: in the page, a pane, a
// section) centres the page's frame on its own width, as the band it is: in a
// section narrower than the window its words start at that section's margin
// and its title stands on one line, in either direction, in a scaffold's page
// too; spanning the window, or as a scaffold's or a screen's top bar, its
// words start where the centred frame starts and the page's column does, as
// before. Its height can be measured (an IntrinsicHeight around it).
import 'package:civic_ui/civic_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

const _title = 'Report a fault in a street light';

Widget _bar() => CivicTopBar(
  title: _title,
  actions: [
    CivicIconButton(
      icon: LucideIcons.menu,
      semanticLabel: 'Menu',
      onPressed: () {},
    ),
  ],
);

Future<void> _show(
  WidgetTester tester,
  Widget child, {
  TextDirection direction = TextDirection.ltr,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1440, 900);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Directionality(
        textDirection: direction,
        child: CivicTheme(data: CivicThemeData.light(), child: child),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Widget _section(Widget bar) => Align(
  alignment: AlignmentDirectional.topStart,
  child: SizedBox(width: 880, child: bar),
);

void main() {
  testWidgets('spanning the window, its words start where the frame does', (
    tester,
  ) async {
    await _show(tester, Align(alignment: Alignment.topCenter, child: _bar()));
    expect(
      tester.getTopLeft(find.text(_title)).dx,
      CivicLayout.frameInset(1440),
    );
  });

  testWidgets('in a scaffold, its words start where the frame does', (
    tester,
  ) async {
    await _show(
      tester,
      CivicScaffold(topBar: _bar(), body: const SizedBox.expand()),
    );
    expect(
      tester.getTopLeft(find.text(_title)).dx,
      CivicLayout.frameInset(1440),
    );
  });

  testWidgets('alone in a narrower section, it centres on its own width', (
    tester,
  ) async {
    await _show(tester, Align(alignment: Alignment.topCenter, child: _bar()));
    final line = tester.getSize(find.text(_title)).height;
    await _show(tester, _section(_bar()));
    expect(
      tester.getTopLeft(find.text(_title)).dx,
      CivicLayout.frameInset(880),
    );
    expect(tester.getSize(find.text(_title)).height, line);
    final menu = tester.getTopRight(find.bySemanticsLabel('Menu'));
    expect(menu.dx, greaterThan(880 - CivicLayout.frameInset(880) - 1));
  });

  testWidgets('in a scaffold\'s page, it stands alone', (tester) async {
    await _show(tester, CivicScaffold(body: _section(_bar())));
    expect(
      tester.getTopLeft(find.text(_title)).dx,
      CivicLayout.frameInset(880),
    );
  });

  testWidgets('a screen\'s top bar lines up with its column in any box', (
    tester,
  ) async {
    await _show(
      tester,
      _section(CivicScreen(topBar: _bar(), body: const Text('Your permits'))),
    );
    expect(
      tester.getTopLeft(find.text(_title)).dx,
      tester.getTopLeft(find.text('Your permits')).dx,
    );
  });

  testWidgets('right to left, it centres on its own width', (tester) async {
    await _show(tester, _section(_bar()), direction: TextDirection.rtl);
    expect(
      tester.getTopRight(find.text(_title)).dx,
      1440 - CivicLayout.frameInset(880),
    );
  });

  testWidgets('its height can be measured', (tester) async {
    await _show(tester, _section(_bar()));
    final height = tester.getSize(find.byType(CivicTopBar)).height;
    await _show(tester, _section(IntrinsicHeight(child: _bar())));
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(CivicTopBar)).height, height);
  });
}
