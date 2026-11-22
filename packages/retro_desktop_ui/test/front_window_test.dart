// Only the front window is active (the stacking law): under an alert the window behind draws its title bar inactive and its
// default button quiet, a window behind shows its chosen row in grey, and nothing the look raises covers the menu bar.
// A held close box turns in. Papers, the look's own application, as the example opens it.
// ignore_for_file: avoid_relative_lib_imports — the example app's pages are what this test checks; example/ is not a dependency of the package.
import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

import '../example/lib/kit_gallery/demos/papers.dart';

import 'support.dart';
// The demo art is the example's; a test or page that draws it reads it from there.
import '../example/lib/demo_art.dart';

Future<void> _pump(
  WidgetTester tester,
  KitPapersWindow front, {
  required double width,
  double height = 900,
  double text = 1,
  KitPapersMoment moment = KitPapersMoment.none,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final base = RetroDesktopThemeData.preset('classic', Brightness.light);
  await tester.pumpWidget(
    MaterialApp(
      key: ValueKey('$front/$width/$text/$moment'),
      debugShowCheckedModeBanner: false,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(text)),
        child: RetroDesktopTheme(
          data: base.atWidth(MediaQuery.sizeOf(context).width),
          child: child!,
        ),
      ),
      home: KitPapers(front: front, moment: moment),
    ),
  );
  await tester.pumpAndSettle();
}

// The striped title bars on screen: an active window's.
int _stripes(WidgetTester tester) => find
    .byWidgetPredicate(
      (w) =>
          w is RetroDesktopPixelPaint &&
          w.painter.runtimeType.toString() == '_Stripes',
    )
    .evaluate()
    .length;

// Each default button's label and whether it is drawn quiet.
Map<String, bool> _defaults(WidgetTester tester) => {
  for (final e
      in find
          .byWidgetPredicate(
            (w) => w.runtimeType.toString() == '_DefaultButton',
          )
          .evaluate())
    '${(e.widget as dynamic).label} in ${_windowOf(e)}':
        (e.widget as dynamic).quiet as bool,
};

// The striped runs in the title bar of the window called [title].
int _stripesIn(WidgetTester tester, String title) => find
    .descendant(
      of: find.byWidgetPredicate(
        (w) => w is RetroDesktopWindow && w.title == title,
      ),
      matching: find.byWidgetPredicate(
        (w) =>
            w is RetroDesktopPixelPaint &&
            w.painter.runtimeType.toString() == '_Stripes',
      ),
    )
    .evaluate()
    .length;

// An alert raised from the front window (or from [at]), as an order that failed raises it.
Future<bool?> _alert(WidgetTester tester, {Finder? at}) =>
    showRetroDesktopDialog<bool>(
      tester.element(at ?? find.byType(RetroDesktopWindow).last),
      builder: (context) => const RetroDesktopDialog(
        title: 'The order wasn’t sent',
        message: 'Papers couldn’t reach the print shop.',
        tone: RetroDesktopTone.danger,
        actions: [
          RetroDesktopDialogAction('Cancel', value: false),
          RetroDesktopDialogAction(
            'Try again',
            value: true,
            isDefaultAction: true,
          ),
        ],
      ),
    );

// Whether the focus is in the alert's route.
bool _focusInAlert(WidgetTester tester) {
  final focus = FocusManager.instance.primaryFocus?.context;
  if (focus == null) return false;
  final alert = ModalRoute.of(tester.element(find.byType(RetroDesktopDialog)));
  return alert != null && identical(ModalRoute.of(focus), alert);
}

String _windowOf(Element e) {
  var name = 'the alert';
  e.visitAncestorElements((a) {
    if (a.widget is RetroDesktopWindow) {
      name = (a.widget as RetroDesktopWindow).title;
      return false;
    }
    return true;
  });
  return name;
}

void main() {
  setUpAll(loadRetroDesktopFonts);

  testWidgets('under an alert the window behind is inactive and its default '
      'quiet; closing the alert gives the front back', (tester) async {
    await _pump(
      tester,
      KitPapersWindow.details,
      width: 1440,
      moment: KitPapersMoment.unsaved,
    );
    expect(find.text('Save the changes to your details?'), findsOneWidget);
    expect(_stripes(tester), 0, reason: 'no window is active under the alert');
    final under = _defaults(tester);
    expect(under['Save in the alert'], isFalse, reason: '$under');
    expect(under['Save in Your details'], isTrue, reason: '$under');
    expect(under.entries.where((d) => !d.value).map((d) => d.key), [
      'Save in the alert',
    ], reason: 'one default answers Return: $under');
    await tester.tap(find.text('Cancel').last);
    await tester.pumpAndSettle();
    expect(find.text('Save the changes to your details?'), findsNothing);
    expect(_stripes(tester), 2, reason: 'the front window\'s two runs');
    final after = _defaults(tester);
    expect(after.entries.where((d) => !d.value).map((d) => d.key), [
      'Save in Your details',
    ], reason: 'the front window\'s default: $after');
  });

  testWidgets('a menu leaves the window it drops from active', (tester) async {
    await _pump(tester, KitPapersWindow.details, width: 1440);
    expect(_stripes(tester), 2);
    await tester.tap(find.text('File'));
    await tester.pumpAndSettle();
    expect(find.text('Close window'), findsOneWidget);
    expect(_stripes(tester), 2);
  });

  testWidgets('an alert stands below the menu bar, at twice the text size on '
      'a phone', (tester) async {
    await _pump(
      tester,
      KitPapersWindow.details,
      width: 390,
      height: 844,
      text: 2,
      moment: KitPapersMoment.unsaved,
    );
    final bar = tester.getRect(find.byType(RetroDesktopMenuBar));
    final window = tester.getRect(
      find
          .descendant(
            of: find.byType(RetroDesktopDialog),
            matching: find.byType(SingleChildScrollView),
          )
          .first,
    );
    expect(
      window.top,
      greaterThanOrEqualTo(bar.bottom),
      reason: 'the alert ($window) over the bar ($bar)',
    );
    expect(window.bottom, lessThanOrEqualTo(844));
    expect(tester.takeException(), isNull);
  });

  testWidgets('an alert on a desk stands where it stood, centred', (
    tester,
  ) async {
    await _pump(
      tester,
      KitPapersWindow.details,
      width: 1440,
      moment: KitPapersMoment.unsaved,
    );
    final window = tester.getRect(
      find
          .descendant(
            of: find.byType(RetroDesktopDialog),
            matching: find.byType(SingleChildScrollView),
          )
          .first,
    );
    expect(window.center.dy, closeTo(450, 1));
  });

  testWidgets('a menu bar further down the screen (inside a window) leaves '
      'an alert where it stands', (tester) async {
    tester.view
      ..physicalSize = const Size(1440, 900)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final base = RetroDesktopThemeData.preset('classic', Brightness.light);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        builder: (context, child) =>
            RetroDesktopTheme(data: base.atWidth(1440), child: child!),
        home: Padding(
          padding: const EdgeInsets.only(top: 300),
          child: Align(
            alignment: Alignment.topCenter,
            child: RetroDesktopMenuBar(
              menus: [
                RawMenuEntry(
                  label: 'File',
                  children: [RawMenuEntry(label: 'New', onPressed: () {})],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    unawaited(_alert(tester, at: find.byType(RetroDesktopMenuBar)));
    await tester.pumpAndSettle();
    final window = tester.getRect(
      find
          .descendant(
            of: find.byType(RetroDesktopDialog),
            matching: find.byType(SingleChildScrollView),
          )
          .first,
    );
    expect(window.center.dy, closeTo(450, 1));
  });

  testWidgets('an alert that opens closes the menu bar\'s open menu and '
      'keeps the focus', (tester) async {
    await _pump(tester, KitPapersWindow.details, width: 1440);
    await tester.tap(find.text('File'));
    await tester.pumpAndSettle();
    expect(find.text('Close window'), findsOneWidget);
    // An alert that arrives while the menu is down (an order that failed).
    final alert = _alert(tester);
    await tester.pumpAndSettle();
    expect(find.text('The order wasn’t sent'), findsOneWidget);
    expect(find.text('Close window'), findsNothing, reason: 'the menu closed');
    expect(
      _focusInAlert(tester),
      isTrue,
      reason: '${FocusManager.instance.primaryFocus}',
    );
    await tester.tap(find.text('Cancel').last);
    await tester.pumpAndSettle();
    expect(await alert, isFalse);
    expect(find.text('Close window'), findsNothing);
    expect(_stripes(tester), 2);
  });

  testWidgets('an alert that opens closes a menu a button dropped', (
    tester,
  ) async {
    await _pump(tester, KitPapersWindow.details, width: 1440);
    final at = tester.element(find.byType(RetroDesktopWindow).last);
    final menu = showRetroDesktopMenu<String>(
      at,
      anchor: const Rect.fromLTWH(400, 300, 120, 24),
      items: const [
        RetroDesktopMenuItem('open', 'Open in a window'),
        RetroDesktopMenuItem('print', 'Print'),
      ],
    );
    await tester.pumpAndSettle();
    expect(find.text('Open in a window'), findsOneWidget);
    unawaited(_alert(tester));
    await tester.pumpAndSettle();
    expect(find.text('Open in a window'), findsNothing);
    expect(await menu, isNull, reason: 'closed as if dismissed');
    expect(
      _focusInAlert(tester),
      isTrue,
      reason: '${FocusManager.instance.primaryFocus}',
    );
    await tester.tap(find.text('Cancel').last);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  for (final side in [false, true]) {
    testWidgets('under a ${side ? 'side' : 'bottom'} sheet the window behind '
        'is inactive, at twice the text size on a phone', (tester) async {
      await _pump(
        tester,
        KitPapersWindow.details,
        width: 390,
        height: 844,
        text: 2,
      );
      expect(_stripesIn(tester, 'Your details'), greaterThan(0));
      final at = tester.element(find.byType(RetroDesktopWindow).last);
      Widget body(BuildContext context) => const Text('Two copies, bound');
      unawaited(
        side
            ? showRetroDesktopSheet<void>(at, title: 'Order', builder: body)
            : showRetroDesktopBottomSheet<void>(
                at,
                builder: (context) => RetroDesktopBottomSheet(
                  title: 'Order',
                  child: body(context),
                ),
              ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Two copies, bound'), findsOneWidget);
      expect(_stripesIn(tester, 'Your details'), 0);
      expect(_defaults(tester)['Save in Your details'], isTrue);
      if (side) {
        // It stands below the menu bar (two rows at this size), as an alert does.
        final bar = tester.getRect(find.byType(RetroDesktopMenuBar));
        final sheet = tester.getRect(find.byType(RetroDesktopSheet));
        expect(sheet.top, greaterThanOrEqualTo(bar.bottom), reason: '$sheet');
      }
      expect(tester.takeException(), isNull);
    });
  }

  for (final width in [390.0, 1440.0]) {
    testWidgets('a bottom sheet is a window at ${width.toInt()}: a striped '
        'title bar and a close box, given no onClose', (tester) async {
      await _pump(tester, KitPapersWindow.details, width: width, height: 844);
      unawaited(
        showRetroDesktopBottomSheet<void>(
          tester.element(find.byType(RetroDesktopWindow).last),
          builder: (context) => const RetroDesktopBottomSheet(
            title: 'Order',
            child: Text('Two copies, bound'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final sheet = find.byType(RetroDesktopBottomSheet);
      expect(
        find.descendant(of: sheet, matching: find.text('Order')),
        findsOneWidget,
      );
      bool striped(Widget w) =>
          w is RetroDesktopPixelPaint &&
          w.painter.runtimeType.toString() == '_Stripes';
      expect(
        find.descendant(of: sheet, matching: find.byWidgetPredicate(striped)),
        findsNWidgets(2),
        reason: 'the front window\'s bar',
      );
      final close = find.descendant(
        of: sheet,
        matching: find.byWidgetPredicate(
          (w) => w is RetroDesktopPressable && w.label == 'Close',
        ),
      );
      expect(close, findsOneWidget);
      await tester.tap(close);
      await tester.pumpAndSettle();
      expect(find.text('Two copies, bound'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('an action sheet is a panel: no empty title bar or close box '
      'beside its Cancel', (tester) async {
    await _pump(tester, KitPapersWindow.details, width: 390, height: 844);
    unawaited(
      showRetroDesktopActionSheet(
        tester.element(find.byType(RetroDesktopWindow).last),
        title: 'Print',
        actions: [
          RetroDesktopActionSheetAction('Two copies', onPressed: () {}),
        ],
      ),
    );
    await tester.pumpAndSettle();
    final sheet = find.byType(RetroDesktopBottomSheet);
    expect(find.descendant(of: sheet, matching: find.text('Cancel')), findsOne);
    expect(
      find.descendant(
        of: sheet,
        matching: find.byWidgetPredicate(
          (w) => w is RetroDesktopPressable && w.label == 'Close',
        ),
      ),
      findsNothing,
    );
    expect(_stripes(tester), 0, reason: 'the window behind is inactive');
    expect(tester.takeException(), isNull);
  });

  testWidgets('desk icon names read whole at twice the text size, broken '
      'only between words', (tester) async {
    await _pump(tester, KitPapersWindow.details, width: 1440, text: 2);
    for (final name in ['Documents', 'Project notes', 'Bin']) {
      final texts = find
          .descendant(
            of: find.byWidgetPredicate(
              (w) => w is RetroDesktopDeskIcon && w.name == name,
            ),
            matching: find.byType(Text),
          )
          .evaluate()
          .toList();
      final lines = [for (final e in texts) (e.widget as Text).data!];
      expect(lines.join(' '), name, reason: '$lines');
      for (final e in texts) {
        expect((e.widget as Text).maxLines, 1, reason: 'a line a Text');
        final drawn = e.renderObject! as RenderBox;
        expect(
          drawn.getMaxIntrinsicWidth(double.infinity),
          lessThanOrEqualTo(drawn.size.width + .5),
          reason: '"${(e.widget as Text).data}" whole on its line',
        );
      }
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('a desk icon name too long for two lines stands on one, cut in '
      'its middle', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: RetroDesktopTheme(
          data: RetroDesktopThemeData.classic(),
          child: const Center(
            child: RetroDesktopDeskIcon(
              'Quarterly accounts reconciliation',
              art: RetroDesktopDeskArt(RetroDesktopDeskMark.disk),
            ),
          ),
        ),
      ),
    );
    final lines = find
        .descendant(
          of: find.byType(RetroDesktopDeskIcon),
          matching: find.byType(Text),
        )
        .evaluate()
        .map((e) => (e.widget as Text).data!)
        .toList();
    expect(lines, hasLength(1));
    expect(lines.single, startsWith('Qu'));
    expect(lines.single, contains('…'));
    expect(lines.single, endsWith('n'));
    expect(
      find.bySemanticsLabel('Quarterly accounts reconciliation'),
      findsOne,
      reason: 'a screen reader reads it whole',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Your details hugs its form on a desk', (tester) async {
    await _pump(tester, KitPapersWindow.details, width: 1440);
    final window = tester.getRect(
      find.byWidgetPredicate(
        (w) => w is RetroDesktopWindow && w.title == 'Your details',
      ),
    );
    final save = tester.getRect(
      find.widgetWithText(RetroDesktopButton, 'Save'),
    );
    expect(window.bottom - save.bottom, lessThan(32), reason: '$window $save');
  });

  testWidgets('a held close box turns in', (tester) async {
    await _pump(tester, KitPapersWindow.settings, width: 1440);
    bool held() => find
        .byWidgetPredicate(
          (w) =>
              w is RetroDesktopPixelPaint &&
              w.painter.runtimeType.toString() == '_BoxPainter' &&
              (w.painter as dynamic).pressed == true,
        )
        .evaluate()
        .isNotEmpty;
    expect(held(), isFalse);
    // The front window's (the last drawn) close box.
    final close = find
        .byWidgetPredicate(
          (w) => w is RetroDesktopPressable && w.label == 'Close',
        )
        .last;
    final gesture = await tester.startGesture(tester.getCenter(close));
    await tester.pump();
    expect(held(), isTrue);
    await gesture.cancel();
    await tester.pump();
    expect(held(), isFalse);
  });
}
