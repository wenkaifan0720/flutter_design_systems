// The swipe actions, on ui_core's swipe: each row lays out on a phone and at
// desktop width in both appearances, opens and shuts on a drag, acts and
// closes, and offers every act to a screen reader.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_ui/ledger_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

const Size _phone = Size(390, 844);
const Size _desktop = Size(1440, 900);

/// A page's column: the gutter at its sides, the widget as wide as the
/// column, free to grow down.
Widget _host(Widget child, Brightness brightness) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, page) => LedgerHost(brightness: brightness, child: page!),
  home: Scaffold(
    body: Builder(
      builder: (context) => SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: LedgerLayout.gutter(context),
          vertical: 24,
        ),
        child: child,
      ),
    ),
  ),
);

Future<void> _pump(
  WidgetTester t,
  Widget child, {
  Size size = _phone,
  Brightness brightness = Brightness.light,
}) async {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(_host(child, brightness));
  await t.pump();
}

/// Pumps [child] on a phone and at desktop width, light and dark: each lays
/// out clean.
Future<void> _everywhere(WidgetTester t, Widget child) async {
  for (final size in const [_phone, _desktop]) {
    for (final brightness in Brightness.values) {
      await _pump(t, child, size: size, brightness: brightness);
      expect(
        t.takeException(),
        isNull,
        reason: '${size.width.round()} wide, ${brightness.name}',
      );
    }
  }
}

void main() {
  setUpAll(_stillMotion);
  tearDownAll(_movingMotion);

  group('swipe actions', () {
    Widget row({
      bool open = false,
      VoidCallback? onDelete,
      VoidCallback? onDone,
    }) => LedgerSwipeActions(
      initiallyOpen: open,
      leading: [
        LedgerSwipeAction(
          'Done',
          icon: LucideIcons.check,
          tone: LedgerSwipeTone.accent,
          onPressed: onDone ?? () {},
        ),
      ],
      trailing: [
        LedgerSwipeAction('Snooze', icon: LucideIcons.clock, onPressed: () {}),
        LedgerSwipeAction(
          'Delete',
          icon: LucideIcons.trash2,
          tone: LedgerSwipeTone.destructive,
          onPressed: onDelete ?? () {},
        ),
      ],
      child: const LedgerRow(
        title: 'Studio rent',
        value: LedgerAmount(1240),
        subtitle: 'Due Nov 1',
      ),
    );

    testWidgets('lay out everywhere, shut and open', (t) async {
      await _everywhere(t, row());
      await _everywhere(t, row(open: true));
    });

    testWidgets(
      'an open row shows its acts and an act closes the row as it acts',
      (t) async {
        var deleted = 0;
        await _pump(t, row(open: true, onDelete: () => deleted++));
        await t.pumpAndSettle();
        expect(find.text('DELETE'), findsOneWidget);
        await t.tap(find.text('DELETE'));
        await t.pumpAndSettle();
        expect(deleted, 1);
        expect(find.text('DELETE'), findsNothing);
      },
    );

    testWidgets('a drag past a third opens it and a drag back shuts it', (
      t,
    ) async {
      await _pump(t, row());
      expect(find.text('DELETE'), findsNothing);
      await t.drag(find.text('Studio rent'), const Offset(-200, 0));
      await t.pumpAndSettle();
      expect(find.text('DELETE'), findsOneWidget);
      await t.drag(find.byType(LedgerRow), const Offset(150, 0));
      await t.pumpAndSettle();
      expect(find.text('DELETE'), findsNothing);
    });

    testWidgets('an open row is cut at its own edges, not the gutter', (
      t,
    ) async {
      await _pump(t, row(open: true));
      await t.pumpAndSettle();
      final area = t.getRect(find.byType(LedgerSwipeActions));
      final clip = find.descendant(
        of: find.byType(LedgerSwipeActions),
        matching: find.byType(ClipRect),
      );
      expect(clip, findsWidgets);
      expect(t.getRect(clip.first), area);
      // The row itself has slid past the area's start: the clip is what
      // keeps it off the gutter.
      expect(t.getRect(find.byType(LedgerRow)).left, lessThan(area.left));
    });

    testWidgets('offers every act as a custom action on the row', (t) async {
      final semantics = t.ensureSemantics();
      await _pump(t, row());
      // The row's own node: its words, its press and its acts, one node.
      final data = t.getSemantics(find.text('Studio rent')).getSemanticsData();
      expect(data.customSemanticsActionIds, hasLength(3));
      semantics.dispose();
    });
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
