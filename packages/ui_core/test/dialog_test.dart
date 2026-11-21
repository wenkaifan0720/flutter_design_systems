import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

import 'behaviour_contract.dart';
import 'behaviour_harness.dart';

const _frame = ValueKey('frame');

// The bare reference painter: a white frame, plain words, grey actions.
Widget _action(RawDialogAction action, RawDialogActionDetails details) =>
    Container(
      key: ValueKey('action ${action.label}'),
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      color: details.states.contains(WidgetState.focused)
          ? const Color(0xFF9E9E9E)
          : const Color(0xFFE0E0E0),
      child: Text(action.label),
    );

RawAlertDialog _alert({
  String? title = 'Delete the draft?',
  Widget? content = const Text('It cannot be brought back.'),
  List<RawDialogAction>? actions,
  ValueChanged<RawAlertDialogFrameDetails>? onFrame,
  ScrollController? scrollController,
}) => RawAlertDialog(
  title: title,
  content: content,
  scrollController: scrollController,
  actions:
      actions ??
      [
        RawDialogAction(label: 'Cancel', onPressed: () {}),
        RawDialogAction(
          label: 'Delete',
          isDestructiveAction: true,
          onPressed: () {},
        ),
      ],
  actionBuilder: (context, action, details) => _action(action, details),
  frameBuilder: (context, details, child) {
    onFrame?.call(details);
    return Container(
      key: _frame,
      color: const Color(0xFFFFFFFF),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  },
);

extension on RawAlertDialog {
  RawAlertDialog copyWithSpacing(double spacing) => RawAlertDialog(
    title: title,
    content: content,
    actions: actions,
    actionBuilder: actionBuilder,
    frameBuilder: frameBuilder,
    actionSpacing: spacing,
    stackedActionSpacing: 8,
  );
}

// An opener that pushes [route] when pressed.
Widget _opener(Route<Object?> Function() route) => Builder(
  builder: (context) => Center(
    child: RawButton(
      semanticLabel: 'Open',
      excludeSemantics: true,
      minimumSize: const Size(44, 44),
      onPressed: () => Navigator.of(context).push(route()),
      builder: (context, states, _) => const Text('open'),
    ),
  ),
);

Future<void> _openByKeys(WidgetTester tester) async {
  await tester.sendKeyEvent(LogicalKeyboardKey.tab);
  await tester.sendKeyEvent(LogicalKeyboardKey.enter);
  await tester.pumpAndSettle();
}

bool _focusedOn(String label) {
  final focused = FocusManager.instance.primaryFocus?.context;
  if (focused == null) return false;
  var found = false;
  void look(Element e) {
    if (found) return;
    final w = e.widget;
    if (w is Text && w.data == label) found = true;
    e.visitChildElements(look);
  }

  look(focused as Element);
  return found;
}

void main() {
  testWidgets(
    'widget actions share a phone row, keep their own semantics, and stack when their words grow',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      var pressed = 0;
      final actions = [
        for (final text in ['Keep', 'Discard'])
          RawButton(
            key: ValueKey(text),
            semanticLabel: text,
            onPressed: () => pressed++,
            autofocus: text == 'Keep',
            builder: (_, _, _) =>
                Padding(padding: const EdgeInsets.all(8), child: Text(text)),
          ),
      ];
      Future<void> show(double scale) => tester.pumpWidget(
        harness(
          RawAlertDialog(title: 'Changes', actionWidgets: actions),
          textDirection: TextDirection.rtl,
          textScale: scale,
        ),
      );
      await show(1);
      await tester.pumpAndSettle();
      Rect box(String label) => tester.getRect(find.byKey(ValueKey(label)));
      expect(box('Keep').width, box('Discard').width);
      expect(box('Keep').left, greaterThan(box('Discard').left));
      expect(box('Keep').center.dy, box('Discard').center.dy);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(pressed, 1);
      await show(2);
      await tester.pumpAndSettle();
      expect(box('Discard').bottom, lessThanOrEqualTo(box('Keep').top));
      expect(tester.takeException(), isNull);
    },
  );

  behaviourContract(
    'DesignDialogRoute',
    build: (c) => _opener(
      () => DesignDialogRoute<bool>(
        isAlert: true,
        semanticLabel: 'Delete draft',
        builder: (context, details) => _alert(),
      ),
    ),
    open: _openByKeys,
    node: () => find.bySemanticsLabel('Delete draft'),
    // A route of its own, an alert: it scopes what a screen reader reaches,
    // and names it.
    semantics: isSemantics(
      label: 'Delete draft',
      scopesRoute: true,
      namesRoute: true,
    ),
    role: SemanticsRole.alertDialog,
    noDisabledState:
        'a dialog has no disabled state; its actions do (a null onPressed)',
    root: () => find.byKey(_frame),
    keyboard: (p) async {
      expect(
        _focusedOn('Cancel'),
        isTrue,
        reason: 'with a destructive action, focus opens on the safe one',
      );
      await p.tab();
      expect(_focusedOn('Delete'), isTrue);
      await p.tab();
      expect(_focusedOn('Cancel'), isTrue, reason: 'Tab stays inside');
      await p.key(LogicalKeyboardKey.escape);
      expect(find.byKey(_frame), findsNothing, reason: 'Escape closes it');
      expect(
        p.tester.getSemantics(find.bySemanticsLabel('Open')),
        isSemantics(isFocused: true),
        reason: 'focus goes back to what opened it',
      );
    },
    rtl: (p) async {
      final cancel = p.tester.getRect(
        find.byKey(const ValueKey('action Cancel')),
      );
      final delete = p.tester.getRect(
        find.byKey(const ValueKey('action Delete')),
      );
      expect(
        delete.right,
        lessThan(cancel.left),
        reason: 'right to left, the actions read from the right',
      );
    },
    motion: (p) async {
      await p.tester.tap(find.text('Cancel'));
      await p.key(LogicalKeyboardKey.escape);
      await p.tester.pump();
    },
  );

  group('RawAlertDialog.safeActionIndex', () {
    RawDialogAction a(
      String label, {
      bool destructive = false,
      bool isDefault = false,
      bool enabled = true,
    }) => RawDialogAction(
      label: label,
      onPressed: enabled ? () {} : null,
      isDestructiveAction: destructive,
      isDefaultAction: isDefault,
    );

    test('a destructive action: the first enabled one that is not', () {
      expect(
        RawAlertDialog.safeActionIndex([
          a('Off', enabled: false),
          a('Keep'),
          a('Delete', destructive: true),
        ]),
        1,
      );
      expect(
        RawAlertDialog.safeActionIndex([a('Delete', destructive: true)]),
        isNull,
        reason: 'no safe action: nothing takes focus by itself',
      );
    });

    test('else the default action, else the first enabled', () {
      expect(
        RawAlertDialog.safeActionIndex([
          a('Cancel'),
          a('Save', isDefault: true),
        ]),
        1,
      );
      expect(
        RawAlertDialog.safeActionIndex([a('Off', enabled: false), a('OK')]),
        1,
      );
      expect(
        RawAlertDialog.safeActionIndex([a('Off', enabled: false)]),
        isNull,
      );
      expect(RawAlertDialog.safeActionIndex(const []), isNull);
    });
  });

  testWidgets('it opens on a spring: an underdamped token overshoots in '
      'the details, the route itself stays within 0 and 1', (tester) async {
    final seen = <double>[];
    late DesignDialogRoute<void> route;
    await tester.pumpWidget(
      harness(
        _opener(
          () => route = DesignDialogRoute<void>(
            dampingRatio: 0.4,
            stiffness: 600,
            builder: (context, details) => AnimatedBuilder(
              animation: details.animation,
              builder: (context, _) {
                seen.add(details.animation.value);
                return _alert();
              },
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    final routeValues = <double>[];
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      routeValues.add(route.animation!.value);
    }
    expect(seen.reduce((a, b) => a > b ? a : b), greaterThan(1.02));
    expect(routeValues.every((v) => v >= 0 && v <= 1), isTrue);
    await tester.pumpAndSettle();
    expect(seen.last, 1);
  });

  testWidgets('under Reduce Motion the details stand still and the route '
      'fades', (tester) async {
    final seen = <double>[];
    await tester.pumpWidget(
      harness(
        _opener(
          () => DesignDialogRoute<void>(
            dampingRatio: 0.4,
            builder: (context, details) {
              seen.add(details.animation.value);
              return _alert();
            },
          ),
        ),
        reduceMotion: true,
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    expect(seen, everyElement(1.0));
    final fade = tester.widget<FadeTransition>(
      find
          .ancestor(
            of: find.byKey(_frame),
            matching: find.byType(FadeTransition),
          )
          .first,
    );
    expect(fade.opacity.value, lessThan(1), reason: 'it fades in');
    await tester.pumpAndSettle();
  });

  testWidgets('a barrier tap closes a dialog, not an alert; Escape closes '
      'both', (tester) async {
    for (final alert in [false, true]) {
      await tester.pumpWidget(
        harness(
          _opener(
            () => DesignDialogRoute<void>(
              isAlert: alert,
              builder: (context, details) => _alert(),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(
        find.byKey(_frame),
        alert ? findsOneWidget : findsNothing,
        reason: alert ? 'an alert waits for an answer' : 'a dialog closes',
      );
      if (alert) {
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(find.byKey(_frame), findsNothing, reason: 'Escape closes it');
      }
    }
  });

  testWidgets('a PopScope refuses Escape, the barrier and close(); the app '
      'is told and may pop after asking', (tester) async {
    var asked = 0;
    late VoidCallback close;
    await tester.pumpWidget(
      harness(
        _opener(
          () => DesignDialogRoute<void>(
            builder: (context, details) {
              close = details.close;
              return PopScope<void>(
                canPop: false,
                onPopInvokedWithResult: (didPop, _) {
                  if (!didPop) asked++;
                },
                child: _alert(),
              );
            },
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    close();
    await tester.pumpAndSettle();
    expect(find.byKey(_frame), findsOneWidget);
    expect(asked, 3);
  });

  testWidgets('focus goes back to the opener quietly as it closes, and the '
      'answer comes back from the push', (tester) async {
    Object? answer;
    await tester.pumpWidget(
      harness(
        Builder(
          builder: (context) => Center(
            child: RawButton(
              semanticLabel: 'Open',
              minimumSize: const Size(44, 44),
              onPressed: () async {
                answer = await Navigator.of(context).push(
                  DesignDialogRoute<bool>(
                    builder: (context, details) => _alert(
                      actions: [
                        RawDialogAction(
                          label: 'No',
                          onPressed: () => Navigator.of(context).pop(false),
                        ),
                        RawDialogAction(
                          label: 'Yes',
                          isDefaultAction: true,
                          onPressed: () => Navigator.of(context).pop(true),
                        ),
                      ],
                    ),
                  ),
                );
              },
              builder: (context, states, _) => const Text('open'),
            ),
          ),
        ),
      ),
    );
    await _openByKeys(tester);
    expect(_focusedOn('Yes'), isTrue, reason: 'the default action, first');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(answer, isTrue);
    expect(_focusedOn('open'), isTrue);
  });

  testWidgets('its title names the route when the route has no label; '
      'without a title, the words for an alert do', (tester) async {
    final semantics = tester.ensureSemantics();
    for (final title in <String?>['Delete the draft?', null]) {
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        harness(
          _opener(
            () => DesignDialogRoute<void>(
              isAlert: true,
              builder: (context, details) => _alert(title: title),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      final name = title ?? 'Alert';
      expect(
        tester.getSemantics(find.bySemanticsLabel(name).last),
        isSemantics(label: name, namesRoute: true, isHeader: title != null),
      );
    }
    semantics.dispose();
  });

  testWidgets('long words scroll under actions that stay put; the frame is '
      'told it overflows and, once scrolled, that it is', (tester) async {
    tester.view.physicalSize = const Size(390, 500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    RawAlertDialogFrameDetails? frame;
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    await tester.pumpWidget(
      harness(
        _opener(
          () => DesignDialogRoute<void>(
            builder: (context, details) => _alert(
              scrollController: scroll,
              content: Column(
                children: [for (var i = 0; i < 60; i++) Text('Line $i')],
              ),
              onFrame: (d) => frame = d,
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    final cancel = tester.getRect(find.byKey(const ValueKey('action Cancel')));
    expect(cancel.bottom, lessThanOrEqualTo(500 - 24));
    expect(frame!.overflows, isTrue);
    expect(frame!.scrolled, isFalse);
    scroll.jumpTo(200);
    await tester.pumpAndSettle();
    expect(frame!.scrolled, isTrue);
    expect(
      tester.getRect(find.byKey(const ValueKey('action Cancel'))),
      cancel,
      reason: 'the actions do not move',
    );
  });

  testWidgets('actions sit side by side at the end while they fit, and '
      'stack, the last on top, when they do not', (tester) async {
    Future<(Rect, Rect, bool)> show(double width, {double scale = 1}) async {
      tester.view.physicalSize = Size(width, 700);
      tester.view.devicePixelRatio = 1;
      var stacked = false;
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(
            size: Size(width, 700),
            textScaler: TextScaler.linear(scale),
          ),
          child: harness(
            _opener(
              () => DesignDialogRoute<void>(
                builder: (context, details) => _alert(
                  actions: [
                    RawDialogAction(label: 'Keep editing', onPressed: () {}),
                    RawDialogAction(
                      label: 'Discard the changes',
                      isDestructiveAction: true,
                      onPressed: () {},
                    ),
                  ],
                  onFrame: (d) => stacked = d.stacked,
                ),
              ),
            ),
            textScale: scale,
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      final keep = tester.getRect(
        find.byKey(const ValueKey('action Keep editing')),
      );
      final discard = tester.getRect(
        find.byKey(const ValueKey('action Discard the changes')),
      );
      return (keep, discard, stacked);
    }

    addTearDown(tester.view.reset);
    final (keep, discard, stacked) = await show(800);
    expect(stacked, isFalse);
    expect(keep.top, discard.top, reason: 'side by side');
    expect(keep.right, lessThan(discard.left));
    final frame = tester.getRect(find.byKey(_frame));
    expect(discard.right, frame.right - 16, reason: 'at the end');

    final (keep2, discard2, stacked2) = await show(320, scale: 2);
    expect(stacked2, isTrue);
    expect(
      discard2.bottom,
      lessThanOrEqualTo(keep2.top),
      reason: 'last on top',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('it stands clear of the on-screen keyboard', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(800, 600),
          viewInsets: EdgeInsets.only(bottom: 300),
        ),
        child: harness(
          _opener(
            () => DesignDialogRoute<void>(
              builder: (context, details) => _alert(),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(
      tester.getRect(find.byKey(_frame)).bottom,
      lessThanOrEqualTo(600 - 300 - 24),
    );
  });

  testWidgets('the look paints the title, the action bar and the barrier', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        _opener(
          () => DesignDialogRoute<void>(
            barrierBuilder: (context, animation) => const ColoredBox(
              key: ValueKey('screen'),
              color: Color(0x33000000),
            ),
            builder: (context, details) => RawAlertDialog(
              title: 'Rename',
              titleBuilder: (context, title) => Text('[$title]'),
              actions: [RawDialogAction(label: 'OK', onPressed: () {})],
              actionBuilder: (context, action, details) =>
                  _action(action, details),
              actionsBuilder: (context, details, child) =>
                  Container(key: const ValueKey('bar'), child: child),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('[Rename]'), findsOneWidget);
    expect(find.byKey(const ValueKey('bar')), findsOneWidget);
    expect(find.byKey(const ValueKey('screen')), findsOneWidget);
    final route =
        ModalRoute.of(tester.element(find.text('[Rename]')))!
            as DesignDialogRoute<void>;
    expect(route.barrierColor, isNull);
    expect(route.barrierLabel, 'Dismiss');
    expect(route.transitionDuration, isNot(Duration.zero));
  });

  testWidgets('its action bar answers intrinsic and dry layout as it lays '
      'out, and follows a change of spacing or direction', (tester) async {
    Widget bar({double spacing = 8, TextDirection dir = TextDirection.ltr}) =>
        harness(
          Center(
            child: SizedBox(
              width: 300,
              child: _alert(
                actions: [
                  RawDialogAction(label: 'No', onPressed: () {}),
                  RawDialogAction(label: 'Yes', onPressed: () {}),
                ],
              ).copyWithSpacing(spacing),
            ),
          ),
          textDirection: dir,
        );
    await tester.pumpWidget(bar());
    final render = tester.renderObject<RenderBox>(
      find
          .ancestor(
            of: find.byKey(const ValueKey('action No')),
            matching: find.byWidgetPredicate(
              (w) => w.runtimeType.toString() == '_ActionBar',
            ),
          )
          .first,
    );
    // Side by side: 'No' and 'Yes' at 52 and 66 wide, 8 apart.
    expect(render.getMaxIntrinsicWidth(double.infinity), 52 + 8 + 66);
    expect(render.getMinIntrinsicWidth(double.infinity), 66);
    expect(render.getMinIntrinsicHeight(400), 44);
    expect(render.getMaxIntrinsicHeight(60), 44 + 8 + 44, reason: 'stacked');
    expect(render.getDryLayout(const BoxConstraints(maxWidth: 400)).height, 44);
    expect(render.getDryLayout(const BoxConstraints(maxWidth: 60)).height, 96);
    final yes = tester.getRect(find.byKey(const ValueKey('action Yes')));
    await tester.pumpWidget(bar(spacing: 20));
    expect(
      tester.getRect(find.byKey(const ValueKey('action No'))).right,
      yes.left - 20,
    );
    await tester.pumpWidget(bar(spacing: 20, dir: TextDirection.rtl));
    expect(
      tester.getRect(find.byKey(const ValueKey('action No'))).left,
      greaterThan(
        tester.getRect(find.byKey(const ValueKey('action Yes'))).right,
      ),
    );
  });

  test('its properties for the inspector', () {
    final dialog = _alert();
    final text = dialog.toDiagnosticsNode().toStringDeep();
    expect(text, contains('title: "Delete the draft?"'));
    expect(text, contains('actions:'));
    expect(text, contains('constraints:'));
  });

  // Every size, direction and text size: nothing overflows, the actions
  // stay on screen, and they stack exactly where they cannot fit.
  group('sweep', () {
    for (final size in const [
      Size(390, 844),
      Size(768, 1024),
      Size(1440, 900),
    ]) {
      for (final direction in TextDirection.values) {
        for (final scale in const [1.0, 2.0]) {
          testWidgets('${size.width.toInt()} ${direction.name} x$scale', (
            tester,
          ) async {
            tester.view.physicalSize = size;
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.reset);
            await tester.pumpWidget(
              harness(
                _opener(
                  () => DesignDialogRoute<void>(
                    isAlert: true,
                    builder: (context, details) => _alert(
                      content: Column(
                        children: [
                          for (var i = 0; i < 30; i++)
                            Text('A long line of words, number $i'),
                        ],
                      ),
                      actions: [
                        RawDialogAction(label: 'Not now', onPressed: () {}),
                        RawDialogAction(
                          label: 'Turn on notifications',
                          isDefaultAction: true,
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                ),
                textDirection: direction,
                textScale: scale,
              ),
            );
            await tester.tap(find.text('open'));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            final screen = Offset.zero & size;
            for (final label in ['Not now', 'Turn on notifications']) {
              final r = tester.getRect(find.byKey(ValueKey('action $label')));
              expect(
                screen.contains(r.topLeft) &&
                    screen.contains(r.bottomRight - const Offset(1, 1)),
                isTrue,
                reason: label,
              );
            }
          }, tags: 'sweep');
        }
      }
    }
  });
}
