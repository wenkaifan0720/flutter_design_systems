// Right to left: each everyday part mirrors. Pumped left to right and then
// right to left, two of its pieces swap sides (a button's glyph and words, a
// row's glyph and title, a dialog's two acts); a switch's knob, a slider's
// fill and the side bar run from the reading start; chevrons turn; a figure,
// and a sum typed after its sign, stay left to right inside a right-to-left
// page.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_ui/ledger_ui.dart';
import 'package:ledger_ui/ledger_host.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

const Size _phone = Size(390, 844);
const Size _desktop = Size(1440, 900);

const List<LedgerNavItem> _tabs = [
  LedgerNavItem(LucideIcons.house, 'Home'),
  LedgerNavItem(LucideIcons.scrollText, 'Register'),
  LedgerNavItem(LucideIcons.settings, 'Settings'),
];

/// Pumps [child] reading [direction]: in a page's padded column, or whole
/// as the page when [page] is set.
Future<void> _pump(
  WidgetTester t,
  Widget child, {
  required TextDirection direction,
  Size size = _phone,
  bool page = false,
}) async {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, home) => Directionality(
        textDirection: direction,
        child: LedgerHost(child: home!),
      ),
      home: page
          ? child
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: child,
            ),
    ),
  );
  await t.pump();
}

/// Pumps [child] left to right, then right to left, and expects [a] and [b]
/// to change sides.
Future<void> _flips(
  WidgetTester t,
  Widget child,
  Finder a,
  Finder b, {
  Size size = _phone,
  bool page = false,
}) async {
  Future<double> order(TextDirection direction) async {
    await _pump(t, child, direction: direction, size: size, page: page);
    return t.getCenter(a.first).dx - t.getCenter(b.first).dx;
  }

  final ltr = await order(TextDirection.ltr);
  final rtl = await order(TextDirection.rtl);
  expect(ltr.abs(), greaterThan(1), reason: 'apart left to right');
  expect(rtl.sign, -ltr.sign, reason: 'swapped right to left');
  expect(t.takeException(), isNull);
}

void main() {
  setUpAll(_stillMotion);
  tearDownAll(_movingMotion);

  testWidgets('a button: its glyph and its words', (t) async {
    await _flips(
      t,
      LedgerButton('Add money', icon: LucideIcons.plus, onPressed: () {}),
      find.byIcon(LucideIcons.plus),
      find.text('Add money'),
    );
  });

  testWidgets('a chip: its words and its count', (t) async {
    await _flips(
      t,
      LedgerChip('Groceries', count: 12, onTap: () {}),
      find.text('Groceries'),
      find.text('12'),
    );
  });

  testWidgets('a segmented control: its first and last options', (t) async {
    await _flips(
      t,
      LedgerSegmentedControl(
        options: const ['1M', '3M', '1Y', 'All'],
        value: '1Y',
        onChanged: (_) {},
      ),
      find.text('1M'),
      find.text('All'),
    );
  });

  testWidgets('a checkbox: its box and its words', (t) async {
    await _flips(
      t,
      LedgerCheckbox(
        value: true,
        label: 'Email me a receipt',
        onChanged: (_) {},
      ),
      find.byIcon(LucideIcons.check),
      find.text('Email me a receipt'),
    );
  });

  testWidgets('a radio: its dot and its words', (t) async {
    await _flips(
      t,
      LedgerRadio<int>(
        value: 1,
        groupValue: 1,
        label: 'By lamplight',
        onChanged: (_) {},
      ),
      find.text('By lamplight'),
      find.byType(LedgerRadio<int>),
    );
  });

  testWidgets("a field: its label at the reading start; a sum typed after "
      "its sign reads left to right", (t) async {
    const field = LedgerTextField(label: 'Amount', prefix: r'$', hint: '0.00');
    Future<(Rect, Rect, Rect, Rect)> parts(TextDirection direction) async {
      await _pump(t, field, direction: direction);
      return (
        t.getRect(find.byType(LedgerTextField)),
        t.getRect(find.text('AMOUNT')),
        t.getRect(find.text(r'$')),
        t.getRect(find.text('0.00')),
      );
    }

    final (lBox, lLabel, lSign, lSum) = await parts(TextDirection.ltr);
    final (rBox, rLabel, rSign, rSum) = await parts(TextDirection.rtl);
    expect(lLabel.left - lBox.left, closeTo(rBox.right - rLabel.right, 0.5));
    expect(lSign.right, lessThan(lSum.left), reason: r'$ before the figures');
    expect(rSign.right, lessThan(rSum.left), reason: r'$ before the figures');
    expect(rSign.left - rBox.left, closeTo(lSign.left - lBox.left, 0.5));
    expect(t.takeException(), isNull);
  });

  testWidgets("a setting row: its glyph and its title; the chevron turns", (
    t,
  ) async {
    final row = LedgerSettingRow(
      icon: LucideIcons.gauge,
      title: 'Monthly limit',
      value: r'$2,000',
      onTap: () {},
    );
    await _flips(
      t,
      row,
      find.byIcon(LucideIcons.gauge),
      find.text('Monthly limit'),
    );
    expect(find.byIcon(LucideIcons.chevronLeft), findsOneWidget);
    expect(find.byIcon(LucideIcons.chevronRight), findsNothing);
  });

  testWidgets('tabs: the first and the last', (t) async {
    await _flips(
      t,
      LedgerTabs(
        tabs: const ['Overview', 'Entries', 'Notes'],
        selectedIndex: 0,
        onSelected: (_) {},
      ),
      find.text('Overview'),
      find.text('Notes'),
    );
  });

  testWidgets("a stepper: its lower and its raise", (t) async {
    await _flips(
      t,
      LedgerStepper(value: 250, label: 'Monthly budget', onChanged: (_) {}),
      find.byIcon(LucideIcons.minus),
      find.byIcon(LucideIcons.plus),
    );
  });

  testWidgets("a dialog: its two acts", (t) async {
    await _flips(
      t,
      Center(
        child: LedgerDialog(
          title: 'Delete this entry?',
          type: LedgerDialogType.destructive,
          confirmLabel: 'Delete',
          onConfirmPressed: () {},
          onCancelPressed: () {},
        ),
      ),
      find.text('Cancel'),
      find.text('Delete'),
      size: _desktop,
      page: true,
    );
  });

  testWidgets("a sheet: its title and its close", (t) async {
    await _flips(
      t,
      LedgerSheetShell(
        title: 'Add money',
        onClose: () {},
        children: const [Text('From checking')],
      ),
      find.text('Add money'),
      find.byIcon(LucideIcons.x),
      page: true,
    );
  });

  testWidgets('the tab bar: its first and last destinations', (t) async {
    await _flips(
      t,
      LedgerNavigationFrame(
        destinations: _tabs,
        selectedIndex: 0,
        onDestinationSelected: (_) {},
        body: const SizedBox.expand(),
      ),
      find.text('Home'),
      find.text('Settings'),
      page: true,
    );
  });

  testWidgets('the side bar stands at the reading start', (t) async {
    await _flips(
      t,
      LedgerNavigationFrame(
        destinations: _tabs,
        selectedIndex: 0,
        onDestinationSelected: (_) {},
        brand: 'Quill',
        body: const Center(child: Text('The page')),
      ),
      find.byType(LedgerSideBar),
      find.text('The page'),
      size: _desktop,
      page: true,
    );
  });

  testWidgets("back points to the reading start", (t) async {
    await _pump(t, LedgerBack(onPressed: () {}), direction: TextDirection.rtl);
    expect(find.byIcon(LucideIcons.chevronRight), findsOneWidget);
    expect(find.byIcon(LucideIcons.chevronLeft), findsNothing);
  });

  testWidgets("a switch's knob is on at the reading end", (t) async {
    Iterable<double> scales() => t
        .widgetList<Transform>(
          find.descendant(
            of: find.byType(LedgerSwitch),
            matching: find.byType(Transform),
          ),
        )
        .map((w) => w.transform.storage[0]);
    final on = LedgerSwitch(
      value: true,
      semanticLabel: 'Bills',
      onChanged: (_) {},
    );
    await _pump(t, on, direction: TextDirection.ltr);
    expect(scales(), isNot(contains(-1.0)));
    await _pump(t, on, direction: TextDirection.rtl);
    expect(scales(), contains(-1.0));
  });

  testWidgets("a slider runs from the reading start", (t) async {
    double? got;
    await _pump(
      t,
      StatefulBuilder(
        builder: (context, setState) => LedgerSlider(
          label: 'Budget',
          showLabel: false,
          value: 50,
          max: 100,
          onChanged: (v) => got = v,
        ),
      ),
      direction: TextDirection.rtl,
    );
    final box = t.getRect(find.byType(LedgerSlider));
    await t.tapAt(Offset(box.right - 2, box.center.dy));
    expect(got, isNotNull);
    expect(got!, lessThan(10), reason: 'its right end is its least');
  });

  testWidgets('a figure stays left to right in a right-to-left page', (
    t,
  ) async {
    await _pump(t, const LedgerAmount(-84.25), direction: TextDirection.rtl);
    final words = t.widget<RichText>(
      find.descendant(
        of: find.byType(LedgerAmount),
        matching: find.byType(RichText),
      ),
    );
    expect(words.textDirection, TextDirection.ltr);
  });
}

/// Reduced motion on, as a reader who asked for it has it: every Ledger
/// change lands at once, so a test reads the settled frame.
void _stillMotion() =>
    TestWidgetsFlutterBinding.ensureInitialized()
        .platformDispatcher
        .accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
      disableAnimations: true,
    );

/// The platform's own motion back.
void _movingMotion() => TestWidgetsFlutterBinding.instance.platformDispatcher
    .clearAccessibilityFeaturesTestValue();
