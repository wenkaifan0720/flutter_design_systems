import 'package:comic_ui/comic_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

// Comic's own words in French, and the words every look shares, translated as the README says: by extending
// DefaultDesignLocalizations.
class _Words extends ComicLocalizationsEn {
  const _Words();
  @override
  String get dismiss => 'Masquer';
}

class _SharedWords extends DefaultDesignLocalizations {
  const _SharedWords();
  @override
  String get closeButtonLabel => 'Fermer';
}

class _Delegate extends LocalizationsDelegate<ComicLocalizations> {
  const _Delegate();
  @override
  bool isSupported(Locale locale) => true;
  @override
  Future<ComicLocalizations> load(Locale locale) =>
      SynchronousFuture(const _Words());
  @override
  bool shouldReload(_Delegate old) => false;
}

class _SharedDelegate extends LocalizationsDelegate<DesignLocalizations> {
  const _SharedDelegate();
  @override
  bool isSupported(Locale locale) => true;
  @override
  Future<DesignLocalizations> load(Locale locale) =>
      SynchronousFuture(const _SharedWords());
  @override
  bool shouldReload(_SharedDelegate old) => false;
}

Widget _host(
  Widget child, {
  bool still = false,
  bool accessible = false,
  TextDirection direction = TextDirection.ltr,
  double scale = 1,
}) => MaterialApp(
  localizationsDelegates: const [_Delegate(), _SharedDelegate()],
  builder: (context, home) => ComicTheme(
    data: ComicThemeData.offset(),
    child: MediaQuery(
      data: MediaQuery.of(context).copyWith(
        disableAnimations: still,
        accessibleNavigation: accessible,
        textScaler: TextScaler.linear(scale),
      ),
      child: Directionality(textDirection: direction, child: home!),
    ),
  ),
  home: Scaffold(body: child),
);

void main() {
  setUpAll(loadComicFonts);

  for (final sheet in [false, true]) {
    testWidgets(
      '${sheet ? 'sheet' : 'dialog'} captures theme, labels and direction; Escape returns focus',
      (tester) async {
        final focus = FocusNode();
        addTearDown(focus.dispose);
        String? theme;
        TextDirection? direction;
        String? close;
        Future<Object?>? result;
        await tester.pumpWidget(
          _host(
            ComicTheme(
              data: ComicThemeData.pulp(),
              child: Builder(
                builder: (context) => ComicPressable(
                  label: 'Open',
                  focusNode: focus,
                  autofocus: true,
                  child: const Text('Open'),
                  onPressed: () {
                    Widget builder(BuildContext context) {
                      theme = ComicTheme.of(context).id;
                      direction = Directionality.of(context);
                      close = DesignLocalizations.of(context).closeButtonLabel;
                      return sheet
                          ? const ComicBottomSheet(
                              title: 'Details',
                              child: Text('The issue'),
                            )
                          : const ComicDialog(
                              title: 'Details',
                              message: 'The issue',
                            );
                    }

                    result = sheet
                        ? showComicBottomSheet<Object>(
                            context,
                            builder: builder,
                          )
                        : showComicDialog<Object>(context, builder: builder);
                  },
                ),
              ),
            ),
            direction: TextDirection.rtl,
          ),
        );
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(theme, 'pulp');
        expect(direction, TextDirection.rtl);
        expect(close, 'Fermer');
        expect(focus.hasFocus, isFalse);
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(await result, isNull);
        expect(focus.hasFocus, isTrue);
        expect(find.text('Details'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('dialog returns an action value and announces its title once', (
    tester,
  ) async {
    Future<bool?>? result;
    await tester.pumpWidget(
      _host(
        Builder(
          builder: (context) => ComicButton(
            'Open',
            onPressed: () {
              result = showComicDialog<bool>(
                context,
                builder: (context) => ComicDialog(
                  title: 'Keep this issue?',
                  actions: [
                    ComicButton(
                      'Keep',
                      onPressed: () => Navigator.pop(context, true),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.tap(find.text('OPEN'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Keep this issue?'), findsOneWidget);
    await tester.tap(find.text('KEEP'));
    await tester.pumpAndSettle();
    expect(await result, isTrue);
  });

  testWidgets('scrim respects dismissibility while Escape always closes', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        Builder(
          builder: (context) => ComicButton(
            'Open',
            onPressed: () {
              showComicDialog<void>(
                context,
                barrierDismissible: false,
                builder: (_) => const ComicDialog(title: 'Stay'),
              );
            },
          ),
        ),
      ),
    );
    await tester.tap(find.text('OPEN'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(2, 2));
    await tester.pumpAndSettle();
    expect(find.text('Stay'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Stay'), findsNothing);
  });

  testWidgets('a combobox says so when nothing fits, and takes nothing', (
    tester,
  ) async {
    String? taken;
    await tester.pumpWidget(
      _host(
        ComicCombobox<String>(
          label: 'City',
          options: const ['Lisbon', 'Porto'],
          onSelected: (city) => taken = city,
        ),
      ),
    );
    await tester.showKeyboard(find.byType(EditableText));
    await tester.enterText(find.byType(EditableText), 'Zzz');
    await tester.pumpAndSettle();
    expect(find.text('No results'), findsOneWidget);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(taken, isNull);
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).controller.text,
      'Zzz',
    );
    await tester.enterText(find.byType(EditableText), 'Lis');
    await tester.pumpAndSettle();
    expect(find.text('No results'), findsNothing);
    expect(find.text('Lisbon'), findsOneWidget);
  });

  testWidgets('menu arrows skip disabled choices and Enter returns a value', (
    tester,
  ) async {
    Future<String?>? result;
    await tester.pumpWidget(
      _host(
        Builder(
          builder: (context) => ComicButton(
            'Open',
            onPressed: () {
              result = showComicMenu<String>(
                context,
                anchor: const Rect.fromLTWH(100, 20, 60, 40),
                items: const [
                  ComicMenuItem('a', 'First'),
                  ComicMenuItem('b', 'Unavailable', enabled: false),
                  ComicMenuItem('c', 'Last'),
                ],
              );
            },
          ),
        ),
      ),
    );
    await tester.tap(find.text('OPEN'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(await result, 'c');
  });

  for (final direction in TextDirection.values) {
    testWidgets('long menu reveals keyboard focus in ${direction.name}', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 400);
      addTearDown(tester.view.reset);
      Future<int?>? result;
      await tester.pumpWidget(
        _host(
          Builder(
            builder: (context) => ComicButton(
              'Open',
              onPressed: () => result = showComicMenu<int>(
                context,
                anchor: const Rect.fromLTWH(20, 20, 160, 48),
                items: [
                  for (var i = 0; i < 20; i++)
                    ComicMenuItem(i, 'Choice ${i + 1}'),
                ],
              ),
            ),
          ),
          direction: direction,
          scale: 1.3,
        ),
      );
      await tester.tap(find.text('OPEN'));
      await tester.pumpAndSettle();
      final last = find.ancestor(
        of: find.text('Choice 20'),
        matching: find.byType(ComicPressable),
      );
      final first = find.ancestor(
        of: find.text('Choice 1'),
        matching: find.byType(ComicPressable),
      );
      final viewport = tester.getRect(find.byType(Scrollable));
      expect(tester.getRect(last).bottom, greaterThan(viewport.bottom));
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pumpAndSettle();
      expect(tester.widget<ComicPressable>(last).focusNode!.hasFocus, isTrue);
      expect(
        tester.getRect(last).bottom,
        lessThanOrEqualTo(viewport.bottom + .01),
        reason: 'The complete focused target stays inside the menu viewport',
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pumpAndSettle();
      expect(tester.widget<ComicPressable>(first).focusNode!.hasFocus, isTrue);
      expect(
        tester.getRect(first).top,
        greaterThanOrEqualTo(viewport.top - .01),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(await result, 19);
    });
  }

  testWidgets('tooltip keeps focus and closes idempotently', (tester) async {
    final focus = FocusNode();
    addTearDown(focus.dispose);
    ComicRaised? handle;
    await tester.pumpWidget(
      _host(
        Builder(
          builder: (context) => ComicPressable(
            label: 'Explain',
            focusNode: focus,
            autofocus: true,
            child: const Text('Explain'),
            onPressed: () {
              handle = showComicTooltip(
                context,
                message: 'A helpful note',
                anchor: const Rect.fromLTWH(20, 40, 80, 40),
              );
            },
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(focus.hasFocus, isTrue);
    expect(find.byType(ComicTooltipFace), findsOneWidget);
    handle!.dismiss();
    handle!.dismiss();
    await tester.pumpAndSettle();
    await handle!.closed;
    expect(find.byType(ComicTooltipFace), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('snack bar action remains available for accessible navigation', (
    tester,
  ) async {
    var calls = 0;
    ComicRaised? handle;
    await tester.pumpWidget(
      _host(
        Builder(
          builder: (context) => ComicButton(
            'Open',
            onPressed: () {
              handle = showComicSnackBar(
                context,
                'Saved',
                actionLabel: 'Undo',
                duration: const Duration(milliseconds: 50),
                onAction: () => calls++,
              );
            },
          ),
        ),
        accessible: true,
      ),
    );
    await tester.tap(find.text('OPEN'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 5));
    expect(find.text('Saved'), findsOneWidget);
    await tester.tap(find.text('UNDO'));
    await tester.pumpAndSettle();
    await handle!.closed;
    expect(calls, 1);
    expect(find.text('Saved'), findsNothing);
  });

  testWidgets('the toast stack queues and each handle closes its own', (
    tester,
  ) async {
    late BuildContext source;
    await tester.pumpWidget(
      _host(
        Builder(
          builder: (context) {
            source = context;
            return const Text('Page');
          },
        ),
      ),
    );
    final first = showComicSnackBar(
      source,
      'First',
      duration: const Duration(seconds: 10),
    );
    await tester.pumpAndSettle();
    final second = showComicSnackBar(
      source,
      'Second',
      duration: const Duration(milliseconds: 500),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('First'), findsOneWidget);
    expect(find.text('Second'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    await second.closed;
    expect(find.text('Second'), findsNothing);
    expect(find.text('First'), findsOneWidget);
    first.dismiss();
    await tester.pumpAndSettle();
    await first.closed;
    expect(find.byType(ComicSnackBar), findsNothing);
  });

  for (final width in [390.0, 768.0, 1024.0, 1440.0]) {
    for (final direction in TextDirection.values) {
      testWidgets(
        'raised panels fit $width ${direction.name} at 2x without motion',
        (tester) async {
          tester.view.physicalSize = Size(width, 844);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          late BuildContext source;
          await tester.pumpWidget(
            _host(
              Builder(
                builder: (context) {
                  source = context;
                  return const Text('Page');
                },
              ),
              direction: direction,
              scale: 2,
              still: true,
            ),
          );
          showComicDialog<void>(
            source,
            builder: (_) => ComicDialog(
              title: 'A longer title for this issue',
              message: List.filled(30, 'A line of explanation.').join(' '),
              actions: [ComicButton('Keep this issue', onPressed: () {})],
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(tester.hasRunningAnimations, isFalse);
          await tester.sendKeyEvent(LogicalKeyboardKey.escape);
          await tester.pumpAndSettle();
          showComicBottomSheet<void>(
            source,
            builder: (_) => const ComicBottomSheet(
              title: 'Issue details',
              child: Text(
                'The sheet can hold a long description and wraps its words.',
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(tester.hasRunningAnimations, isFalse);
          await tester.sendKeyEvent(LogicalKeyboardKey.escape);
          await tester.pumpAndSettle();
        },
      );
    }
  }
}
