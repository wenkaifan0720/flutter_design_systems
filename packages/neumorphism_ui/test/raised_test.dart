import 'dart:ui' show PointerDeviceKind, Tristate;

import 'package:flutter/foundation.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

import 'support.dart';

Widget _app(
  Widget child, {
  bool reduce = false,
  double scale = 1,
  String preset = 'porcelain',
  Brightness brightness = Brightness.light,
  TextDirection direction = TextDirection.ltr,
  bool accessible = false,
}) => WidgetsApp(
  color: const Color(0xffeeeeee),
  pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
    settings: settings,
    pageBuilder: (context, _, _) => builder(context),
  ),
  builder: (context, child) => NeumorphicTheme(
    data: NeumorphicThemeData.preset(preset, brightness),
    child: MediaQuery(
      data: MediaQuery.of(context).copyWith(
        disableAnimations: reduce,
        accessibleNavigation: accessible,
        textScaler: TextScaler.linear(scale),
      ),
      child: Directionality(textDirection: direction, child: child!),
    ),
  ),
  home: child,
);

Future<BuildContext> _mount(
  WidgetTester tester, {
  Widget? child,
  bool reduce = false,
  double scale = 1,
  String preset = 'porcelain',
  Brightness brightness = Brightness.light,
  TextDirection direction = TextDirection.ltr,
  bool accessible = false,
}) async {
  late BuildContext host;
  await tester.pumpWidget(
    _app(
      Builder(
        builder: (context) {
          host = context;
          return Center(child: child ?? const Text('Page beneath'));
        },
      ),
      reduce: reduce,
      scale: scale,
      preset: preset,
      brightness: brightness,
      direction: direction,
      accessible: accessible,
    ),
  );
  return host;
}

const _items = <NeumorphicMenuItem<String>>[
  NeumorphicMenuItem('apple', 'Apple'),
  NeumorphicMenuItem('banana', 'Banana', enabled: false),
  NeumorphicMenuItem.divider(),
  NeumorphicMenuItem('cherry', 'Cherry', selected: true),
  NeumorphicMenuItem('date', 'Date'),
];

class _Words extends NeumorphicLocalizationsEn {
  const _Words();
  @override
  String get close => 'Close from nested words';
}

class _WordsDelegate extends LocalizationsDelegate<NeumorphicLocalizations> {
  const _WordsDelegate();
  @override
  bool isSupported(Locale locale) => true;
  @override
  Future<NeumorphicLocalizations> load(Locale locale) =>
      SynchronousFuture(const _Words());
  @override
  bool shouldReload(_WordsDelegate old) => false;
}

void main() {
  setUpAll(loadNeumorphicFonts);

  testWidgets('dialog returns a value, traps Tab, and restores opener focus', (
    tester,
  ) async {
    final opener = FocusNode();
    addTearDown(opener.dispose);
    late BuildContext host;
    String? result;
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) {
            host = context;
            return Center(
              child: NeumorphicTap(
                focusNode: opener,
                onPressed: () {
                  showNeumorphicDialog<String>(
                    host,
                    builder: (context) => NeumorphicDialog(
                      title: 'Keep changes?',
                      actions: [
                        NeumorphicButton(
                          'Keep',
                          onPressed: () => Navigator.of(context).pop('kept'),
                        ),
                        NeumorphicButton(
                          'Cancel',
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ).then((value) => result = value);
                },
                child: const Text('Open'),
              ),
            );
          },
        ),
      ),
    );
    opener.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    for (var i = 0; i < 5; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(opener.hasFocus, isFalse);
      final owner = FocusManager.instance.primaryFocus?.context;
      expect(
        owner?.findAncestorWidgetOfExactType<NeumorphicDialog>(),
        isNotNull,
      );
    }
    await tester.tap(find.text('Keep'));
    await tester.pumpAndSettle();
    expect(result, 'kept');
    expect(opener.hasFocus, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'a root route carries nested theme, direction, words and text scale',
    (tester) async {
      final nested = NeumorphicThemeData.tyrian(Brightness.dark);
      late BuildContext host;
      await tester.pumpWidget(
        _app(
          NeumorphicTheme(
            data: nested,
            child: Builder(
              builder: (context) => Localizations.override(
                context: context,
                delegates: const [_WordsDelegate()],
                child: MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: const TextScaler.linear(2)),
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Builder(
                      builder: (context) {
                        host = context;
                        return const Text('Nested page');
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      late BuildContext raised;
      showNeumorphicBottomSheet<void>(
        host,
        builder: (context) {
          raised = context;
          return const NeumorphicBottomSheet(
            title: 'Nested sheet',
            child: Text('Contents'),
          );
        },
      );
      await tester.pumpAndSettle();
      expect(NeumorphicTheme.of(raised).colors, nested.colors);
      expect(Directionality.of(raised), TextDirection.rtl);
      expect(MediaQuery.textScalerOf(raised).scale(10), 20);
      expect(
        NeumorphicLocalizations.of(raised).close,
        'Close from nested words',
      );
      final close = tester.widget<NeumorphicRoundButton>(
        find.byType(NeumorphicRoundButton),
      );
      expect(close.label, 'Close from nested words');
      await tester.tap(find.byType(NeumorphicRoundButton));
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'menu exposes disabled and selected states, notice is a live region',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        final host = await _mount(tester);
        showNeumorphicMenu<String>(
          host,
          anchor: const Rect.fromLTWH(20, 50, 120, 48),
          items: _items,
        );
        await tester.pumpAndSettle();
        final disabled = tester
            .getSemantics(
              find.byWidgetPredicate(
                (w) => w is NeumorphicTap && w.label == 'Banana',
              ),
            )
            .getSemanticsData();
        expect(disabled.hasAction(SemanticsAction.tap), isFalse);
        final selected = tester
            .getSemantics(
              find.byWidgetPredicate(
                (w) => w is NeumorphicTap && w.label == 'Cherry',
              ),
            )
            .getSemanticsData();
        expect(selected.flagsCollection.isSelected, Tristate.isTrue);
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        final notice = showNeumorphicSnackBar(host, message: 'Saved');
        await tester.pumpAndSettle();
        final data = tester
            .getSemantics(find.byType(NeumorphicSnackBar))
            .getSemanticsData();
        expect(data.flagsCollection.isLiveRegion, isTrue);
        notice.dismiss();
        await tester.pumpAndSettle();
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets('Escape closes one layer, then the dialog, then nothing', (
    tester,
  ) async {
    final host = await _mount(tester);
    late BuildContext dialog;
    showNeumorphicDialog<void>(
      host,
      builder: (context) {
        dialog = context;
        return const NeumorphicDialog(title: 'Question');
      },
    );
    await tester.pumpAndSettle();
    final tip = showNeumorphicTooltip(
      dialog,
      message: 'Help',
      anchor: const Rect.fromLTWH(50, 100, 48, 48),
    );
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    await tip.closed;
    expect(find.text('Help'), findsNothing);
    expect(find.text('Question'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Question'), findsNothing);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    expect(tester.takeException(), isNull);
  });

  testWidgets('new route takes Escape ahead of an older notice', (
    tester,
  ) async {
    final host = await _mount(tester);
    final notice = showNeumorphicSnackBar(
      host,
      message: 'Saved',
      duration: const Duration(minutes: 1),
    );
    await tester.pumpAndSettle();
    showNeumorphicDialog<void>(
      host,
      builder: (_) => const NeumorphicDialog(title: 'Question'),
    );
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Question'), findsNothing);
    expect(find.text('Saved'), findsOneWidget);
    notice.dismiss();
    await tester.pumpAndSettle();
  });

  testWidgets('barrier opt-out blocks the scrim but system back still closes', (
    tester,
  ) async {
    final host = await _mount(tester);
    showNeumorphicDialog<void>(
      host,
      barrierDismissible: false,
      builder: (_) => const NeumorphicDialog(title: 'Question'),
    );
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(2, 2));
    await tester.pumpAndSettle();
    expect(find.text('Question'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Question'), findsNothing);
  });

  testWidgets('sheet closes by its button and by dragging the grip', (
    tester,
  ) async {
    final host = await _mount(tester);
    void open() => showNeumorphicBottomSheet<void>(
      host,
      builder: (_) => const NeumorphicBottomSheet(
        title: 'Filters',
        child: SizedBox(height: 250, child: Text('Contents')),
      ),
    );
    open();
    await tester.pumpAndSettle();
    await tester.tap(find.byType(NeumorphicRoundButton));
    await tester.pumpAndSettle();
    expect(find.text('Filters'), findsNothing);
    open();
    await tester.pumpAndSettle();
    final rect = tester.getRect(find.byType(NeumorphicBottomSheet));
    await tester.dragFrom(
      Offset(rect.center.dx, rect.top + 20),
      const Offset(0, 300),
    );
    await tester.pumpAndSettle();
    expect(find.text('Filters'), findsNothing);
  });

  testWidgets(
    'menu skips disabled items and dividers, wraps, and returns a choice',
    (tester) async {
      final host = await _mount(tester);
      final selected = showNeumorphicMenu<String>(
        host,
        anchor: const Rect.fromLTWH(20, 50, 120, 48),
        items: _items,
      );
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(await selected, 'cherry');
      expect(tester.takeException(), isNull);
    },
  );

  for (final (key, result) in [
    (LogicalKeyboardKey.home, 'apple'),
    (LogicalKeyboardKey.end, 'date'),
    (LogicalKeyboardKey.keyD, 'date'),
  ]) {
    testWidgets('menu ${key.keyLabel} selects $result', (tester) async {
      final host = await _mount(tester);
      final selected = showNeumorphicMenu<String>(
        host,
        anchor: const Rect.fromLTWH(20, 50, 120, 48),
        items: _items,
      );
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(
        key,
        character: key == LogicalKeyboardKey.keyD ? 'd' : null,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(await selected, result);
    });
  }

  testWidgets('tooltip hover, focus, hold and owner disposal clean up', (
    tester,
  ) async {
    final focus = FocusNode();
    addTearDown(focus.dispose);
    await _mount(
      tester,
      child: NeumorphicTooltip(
        message: 'Helpful words',
        child: NeumorphicTap(
          focusNode: focus,
          onPressed: () {},
          child: const Text('Control'),
        ),
      ),
    );
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(0, 0));
    await mouse.moveTo(tester.getCenter(find.text('Control')));
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pumpAndSettle();
    expect(find.byType(NeumorphicTooltipFace), findsOneWidget);
    await mouse.moveTo(const Offset(0, 0));
    await tester.pumpAndSettle();
    expect(find.byType(NeumorphicTooltipFace), findsNothing);
    await mouse.removePointer();
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(
      () => FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.automatic,
    );
    focus.requestFocus();
    await tester.pumpAndSettle();
    expect(find.byType(NeumorphicTooltipFace), findsOneWidget);
    focus.unfocus();
    await tester.pumpAndSettle();
    final hold = await tester.startGesture(
      tester.getCenter(find.text('Control')),
    );
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(find.byType(NeumorphicTooltipFace), findsOneWidget);
    await hold.up();
    await tester.pumpAndSettle();
    expect(find.byType(NeumorphicTooltipFace), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'timeout leaves page focus alone; focused action restores its opener',
    (tester) async {
      final first = FocusNode(), second = FocusNode();
      addTearDown(first.dispose);
      addTearDown(second.dispose);
      final host = await _mount(
        tester,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            NeumorphicTap(
              focusNode: first,
              onPressed: () {},
              child: const Text('First'),
            ),
            NeumorphicTap(
              focusNode: second,
              onPressed: () {},
              child: const Text('Second'),
            ),
          ],
        ),
      );
      first.requestFocus();
      await tester.pump();
      showNeumorphicSnackBar(
        host,
        message: 'Saved',
        duration: const Duration(seconds: 1),
      );
      await tester.pumpAndSettle();
      second.requestFocus();
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(second.hasFocus, isTrue);
      expect(find.text('Saved'), findsNothing);
      var undone = 0;
      final notice = showNeumorphicSnackBar(
        host,
        message: 'Saved again',
        actionLabel: 'Undo',
        onAction: () => undone++,
      );
      await tester.pumpAndSettle();
      Focus.of(tester.element(find.text('Undo'))).requestFocus();
      await tester.pump();
      await tester.pump(const Duration(seconds: 10));
      expect(
        find.text('Saved again'),
        findsOneWidget,
        reason: 'focus pauses timeout',
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      await notice.closed;
      expect(undone, 1);
      expect(second.hasFocus, isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'action notice persists for accessible navigation and replacements close old handles',
    (tester) async {
      final host = await _mount(tester, accessible: true);
      final first = showNeumorphicSnackBar(
        host,
        message: 'Saved',
        actionLabel: 'Undo',
        onAction: () {},
        duration: const Duration(milliseconds: 10),
      );
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 10));
      expect(find.text('Saved'), findsOneWidget);
      final second = showNeumorphicSnackBar(
        host,
        message: 'Replaced',
        duration: const Duration(minutes: 1),
      );
      await tester.pumpAndSettle();
      await first.closed;
      expect(find.text('Saved'), findsNothing);
      expect(find.text('Replaced'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await second.closed;
      second.dismiss();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('reduce motion cuts opening and closing all five surfaces', (
    tester,
  ) async {
    final host = await _mount(tester, reduce: true);
    for (final open in <VoidCallback>[
      () {
        showNeumorphicDialog<void>(
          host,
          builder: (_) => const NeumorphicDialog(title: 'Dialog'),
        );
      },
      () {
        showNeumorphicBottomSheet<void>(
          host,
          builder: (_) =>
              const NeumorphicBottomSheet(title: 'Sheet', child: Text('Body')),
        );
      },
      () {
        showNeumorphicMenu<String>(
          host,
          anchor: const Rect.fromLTWH(20, 50, 120, 48),
          items: _items,
        );
      },
      () {
        showNeumorphicTooltip(
          host,
          message: 'Help',
          anchor: const Rect.fromLTWH(20, 50, 120, 48),
        );
      },
      () {
        showNeumorphicSnackBar(host, message: 'Saved');
      },
    ]) {
      open();
      await tester.pump();
      await tester.pump();
      expect(tester.hasRunningAnimations, isFalse);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      await tester.pump();
      expect(tester.hasRunningAnimations, isFalse);
    }
    expect(tester.takeException(), isNull);
  });

  for (final preset in ['porcelain', 'pompeii', 'verona', 'siena', 'tyrian']) {
    for (final brightness in Brightness.values) {
      for (final width in [390.0, 768.0, 1024.0, 1440.0]) {
        testWidgets(
          'raised surfaces $preset ${brightness.name} @$width RTL 2x',
          (tester) async {
            tester.view.physicalSize = Size(width, 540);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.reset);
            final host = await _mount(
              tester,
              preset: preset,
              brightness: brightness,
              direction: TextDirection.rtl,
              scale: 2,
              reduce: true,
            );
            showNeumorphicDialog<void>(
              host,
              builder: (context) => NeumorphicDialog(
                title: longLine,
                message: longLine,
                actions: [NeumorphicButton.filled('Confirm', onPressed: () {})],
              ),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            await tester.sendKeyEvent(LogicalKeyboardKey.escape);
            await tester.pumpAndSettle();
            showNeumorphicBottomSheet<void>(
              host,
              builder: (_) => NeumorphicBottomSheet(
                title: longLine,
                actions: [NeumorphicButton.filled('Confirm', onPressed: () {})],
                child: const Text(longLine),
              ),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            await tester.sendKeyEvent(LogicalKeyboardKey.escape);
            await tester.pumpAndSettle();
            showNeumorphicMenu<String>(
              host,
              anchor: Rect.fromLTWH(width - 70, 480, 50, 40),
              items: [const NeumorphicMenuItem('long', longLine), ..._items],
            );
            await tester.pumpAndSettle();
            final menu = tester.getRect(find.byType(NeumorphicMenu<String>));
            expect(menu.left, greaterThanOrEqualTo(0));
            expect(menu.right, lessThanOrEqualTo(width));
            expect(menu.top, greaterThanOrEqualTo(0));
            expect(menu.bottom, lessThanOrEqualTo(540));
            expect(tester.takeException(), isNull);
            await tester.sendKeyEvent(LogicalKeyboardKey.escape);
            await tester.pumpAndSettle();
            final tip = showNeumorphicTooltip(
              host,
              message: longLine,
              anchor: const Rect.fromLTWH(4, 4, 48, 48),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            tip.dismiss();
            await tester.pumpAndSettle();
            final notice = showNeumorphicSnackBar(
              host,
              message: longLine,
              title: longLine,
              actionLabel: 'Undo',
              onAction: () {},
              duration: const Duration(minutes: 1),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            notice.dismiss();
            await tester.pumpAndSettle();
          },
        );
      }
    }
  }
}
