// The package's surface as an app meets it, under a plain MaterialApp and
// Fluent2Theme with no router: the component themes' merge and blend, the
// density and the typeface, the field's context menu, the toast with a
// toaster and without, the dialog, the sheets, the action sheet and the menu.
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';

Widget _app(
  Widget home, {
  Brightness brightness = Brightness.light,
  bool toaster = false,
}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, child) => Fluent2Theme(
    data: Fluent2ThemeData.lapis(brightness),
    child: toaster ? Fluent2Toaster(child: child!) : child!,
  ),
  home: Scaffold(body: home),
);

/// A button that runs [open] with its own context.
Widget _opener(String label, void Function(BuildContext context) open) =>
    Builder(
      builder: (context) =>
          Center(child: Fluent2Button(label, onPressed: () => open(context))),
    );

void _phone(WidgetTester t) {
  t.view.physicalSize = const Size(390, 844);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
}

const _red = WidgetStatePropertyAll<Color?>(Color(0xFFFF0000));
const _blue = WidgetStatePropertyAll<Color?>(Color(0xFF0000FF));

Fluent2Style _full(WidgetStateProperty<Color?> colour, double size) =>
    Fluent2Style(
      fill: colour,
      foreground: colour,
      edge: colour,
      overlay: colour,
      side: WidgetStatePropertyAll<BorderSide?>(BorderSide(width: size)),
      shape: WidgetStatePropertyAll<OutlinedBorder?>(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(size)),
      ),
      padding: WidgetStatePropertyAll<EdgeInsetsGeometry?>(
        EdgeInsets.all(size),
      ),
      minimumSize: WidgetStatePropertyAll<Size?>(Size(size, size)),
      textStyle: WidgetStatePropertyAll<TextStyle?>(TextStyle(fontSize: size)),
      iconSize: WidgetStatePropertyAll<double?>(size),
    );

void main() {
  group('Fluent2Style', () {
    test('reads the first layer that gives a slot, else the fallback', () {
      const none = <WidgetState>{};
      expect(const Fluent2Style().isEmpty, isTrue);
      expect(const Fluent2Style(fill: _red).isEmpty, isFalse);
      expect(
        Fluent2Style.first<Color>(
          [null, const Fluent2Style(), const Fluent2Style(fill: _blue)],
          (s) => s.fill,
          none,
        ),
        const Color(0xFF0000FF),
      );
      expect(
        Fluent2Style.first<Color>([const Fluent2Style()], (s) => s.fill, none),
        isNull,
      );
      expect(
        Fluent2Style.resolve(null, none, const Color(0xFF00FF00)),
        const Color(0xFF00FF00),
      );
      expect(
        Fluent2Style.resolve(_red, none, const Color(0xFF00FF00)),
        const Color(0xFFFF0000),
      );
    });

    test('copies, merges, blends and compares slot by slot', () {
      final a = _full(_red, 2);
      final b = _full(_blue, 6);
      expect(a.copyWith(fill: _blue).fill, _blue);
      expect(a.copyWith().fill, _red);
      final merged = const Fluent2Style(fill: _blue).merge(a);
      expect(merged.fill, _blue);
      expect(merged.foreground, _red);
      expect(a.merge(null), same(a));
      expect(Fluent2Style.lerp(a, a, .5), same(a));
      final mid = Fluent2Style.lerp(a, b, .5)!;
      const states = <WidgetState>{};
      expect(
        mid.fill!.resolve(states),
        Color.lerp(_red.value, _blue.value, .5),
      );
      expect(mid.side!.resolve(states)!.width, 4);
      expect(mid.padding!.resolve(states), const EdgeInsets.all(4));
      expect(mid.minimumSize!.resolve(states), const Size(4, 4));
      expect(mid.textStyle!.resolve(states)!.fontSize, 4);
      expect(mid.iconSize!.resolve(states), 4);
      expect(mid.shape!.resolve(states), isA<RoundedRectangleBorder>());
      final half = Fluent2Style.lerp(a, const Fluent2Style(), .25)!;
      expect(half.edge!.resolve(states), const Color(0xFFFF0000));
      expect(_full(_red, 2), a);
      expect(_full(_red, 2).hashCode, a.hashCode);
      expect(a == b, isFalse);
      expect(a.toDiagnosticsNode().toStringDeep(), contains('fill'));
    });

    test('fluent2States names each state asked for', () {
      expect(fluent2States(), isEmpty);
      expect(
        fluent2States(
          enabled: false,
          hovered: true,
          focused: true,
          pressed: true,
          selected: true,
          error: true,
        ),
        {
          WidgetState.disabled,
          WidgetState.hovered,
          WidgetState.focused,
          WidgetState.pressed,
          WidgetState.selected,
          WidgetState.error,
        },
      );
    });
  });

  test('Fluent2ComponentThemes copies, blends and compares theme by theme', () {
    final s = _full(_red, 2);
    const empty = Fluent2ComponentThemes();
    expect(empty.isEmpty, isTrue);
    final all = empty.copyWith(
      primaryButton: s,
      secondaryButton: s,
      outlineButton: s,
      subtleButton: s,
      transparentButton: s,
      iconButton: s,
      checkbox: s,
      radio: s,
      switchTheme: s,
      textField: s,
      tag: s,
      slider: s,
      segmentedButton: s,
      tabList: s,
      card: s,
      listItem: s,
      dialog: s,
      bottomSheet: s,
      menu: s,
      toast: s,
      tooltip: s,
      badge: s,
      avatar: s,
    );
    expect(all.isEmpty, isFalse);
    expect(all.avatar, s);
    expect(all.copyWith(), all);
    expect(all.copyWith().hashCode, all.hashCode);
    expect(all == empty, isFalse);
    expect(Fluent2ComponentThemes.lerp(all, all, .5), same(all));
    final mid = Fluent2ComponentThemes.lerp(all, empty, .75);
    expect(mid.primaryButton.fill, isNotNull);
    expect(mid.primaryButton.fill!.resolve(const {}), isNull);
    expect(all.toDiagnosticsNode().toStringDeep(), contains('primaryButton'));
  });

  group('Fluent2Density', () {
    test('takes 4 a step off heights and 2 a step off padding', () {
      const c = Fluent2Density.compact;
      expect(Fluent2Density.standard.height(32), 32);
      expect(Fluent2Density.comfortable.height(32), 28);
      expect(c.height(32), 24);
      expect(c.height(16), 16);
      expect(c.height(16, least: 4), 8);
      const pad = EdgeInsets.fromLTRB(12, 6, 12, 6);
      expect(Fluent2Density.standard.padding(pad), pad);
      expect(c.padding(pad), const EdgeInsets.fromLTRB(8, 4, 8, 4));
      expect(
        c.padding(const EdgeInsets.all(2)),
        const EdgeInsets.fromLTRB(2, 2, 2, 2),
      );
      expect(c.heightDelta, -8);
      expect(c.paddingDelta, -4);
    });

    test('blends, compares and describes itself', () {
      const c = Fluent2Density.compact;
      expect(Fluent2Density.lerp(c, c, .5), same(c));
      expect(
        Fluent2Density.lerp(Fluent2Density.standard, c, .5),
        Fluent2Density.comfortable,
      );
      expect(
        const Fluent2Density(horizontal: -2, vertical: -2).hashCode,
        c.hashCode,
      );
      expect(c == Fluent2Density.standard, isFalse);
      expect(c.toDiagnosticsNode().toStringDeep(), contains('vertical'));
    });

    test('adaptivePlatformDensity is compact on a desktop alone', () {
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      for (final (platform, density) in [
        (TargetPlatform.macOS, Fluent2Density.compact),
        (TargetPlatform.windows, Fluent2Density.compact),
        (TargetPlatform.linux, Fluent2Density.compact),
        (TargetPlatform.android, Fluent2Density.standard),
        (TargetPlatform.iOS, Fluent2Density.standard),
        (TargetPlatform.fuchsia, Fluent2Density.standard),
      ]) {
        debugDefaultTargetPlatformOverride = platform;
        expect(Fluent2Density.adaptivePlatformDensity, density);
      }
    });
  });

  test('Fluent2Typeface sets the ramp in its face', () {
    const look = Fluent2Typeface.look;
    final style = look.style(14, 20, 600, const Color(0xFF242424));
    expect(style.fontFamily, contains('Selawik'));
    expect(style.fontSize, 14);
    expect(style.height, 20 / 14);
    expect(style.fontWeight!.value, 600);
    const inter = Fluent2Typeface.app(family: 'Inter');
    expect(inter.package, isNull);
    expect(look.copyWith(family: 'Inter').family, 'Inter');
    expect(look.copyWith(), look);
    expect(look.copyWith().hashCode, look.hashCode);
    expect(Fluent2Typeface.lerp(look, inter, .25), look);
    expect(Fluent2Typeface.lerp(look, inter, .75), inter);
    expect(look == inter, isFalse);
    expect(inter.toDiagnosticsNode().toStringDeep(), contains('Inter'));
  });

  group('Fluent2FieldContextMenu', () {
    testWidgets('names each kind of item in the app language', (t) async {
      final labels = <String>[];
      await t.pumpWidget(
        _app(
          Builder(
            builder: (context) {
              labels
                ..clear()
                ..addAll([
                  for (final type in ContextMenuButtonType.values)
                    Fluent2FieldContextMenu.labelOf(
                      context,
                      ContextMenuButtonItem(type: type, onPressed: () {}),
                    ),
                  Fluent2FieldContextMenu.labelOf(
                    context,
                    ContextMenuButtonItem(label: 'Translate', onPressed: () {}),
                  ),
                ]);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(labels, containsAll(['Cut', 'Copy', 'Paste', 'Translate']));
      expect(labels.where((l) => l.isNotEmpty).length, greaterThan(8));
    });

    for (final brightness in Brightness.values) {
      testWidgets('its rows press, ${brightness.name}', (t) async {
        _phone(t);
        var copies = 0;
        await t.pumpWidget(
          _app(
            brightness: brightness,
            Stack(
              children: [
                Fluent2FieldContextMenu(
                  anchors: const TextSelectionToolbarAnchors(
                    primaryAnchor: Offset(120, 300),
                  ),
                  items: [
                    ContextMenuButtonItem(
                      type: ContextMenuButtonType.copy,
                      onPressed: () => copies++,
                    ),
                    ContextMenuButtonItem(
                      type: ContextMenuButtonType.selectAll,
                      onPressed: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
        expect(find.text('Select all'), findsOneWidget);
        await t.tap(find.text('Copy'));
        await t.pump();
        expect(copies, 1);
        expect(t.takeException(), isNull);
      });
    }

    testWidgets('with no items it draws nothing', (t) async {
      await t.pumpWidget(
        _app(
          const Fluent2FieldContextMenu(
            anchors: TextSelectionToolbarAnchors(primaryAnchor: Offset.zero),
            items: [],
          ),
        ),
      );
      expect(find.byType(Fluent2Pressable), findsNothing);
    });
  });

  group('showFluent2Toast', () {
    testWidgets('under a toaster it queues and its handle takes it down', (
      t,
    ) async {
      _phone(t);
      late Fluent2Raised first;
      await t.pumpWidget(
        _app(
          toaster: true,
          _opener('Save', (context) {
            first = showFluent2Toast(
              context,
              'Saved to Files',
              tone: Fluent2ToastIntent.info,
            );
            showFluent2Toast(
              context,
              'Upload failed',
              title: 'Q3 plan.docx',
              tone: Fluent2ToastIntent.error,
              actionLabel: 'Retry',
              onAction: () {},
            );
          }),
        ),
      );
      await t.tap(find.text('Save'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('Saved to Files'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      first.dismiss();
      await t.pumpAndSettle();
      expect(find.text('Saved to Files'), findsNothing);
      await t.pump(const Duration(seconds: 10));
      await t.pumpAndSettle();
      expect(find.text('Upload failed'), findsNothing);
    });

    testWidgets('alone, a new one replaces the one still up', (t) async {
      _phone(t);
      var retried = 0;
      await t.pumpWidget(
        _app(
          brightness: Brightness.dark,
          _opener('Send', (context) {
            showFluent2Toast(
              context,
              'Sending',
              tone: Fluent2ToastIntent.warning,
            );
            showFluent2Toast(
              context,
              'Not sent',
              actionLabel: 'Retry',
              onAction: () => retried++,
              duration: const Duration(seconds: 2),
            );
          }),
        ),
      );
      await t.tap(find.text('Send'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('Sending'), findsNothing);
      expect(find.text('Not sent'), findsOneWidget);
      await t.tap(find.text('Retry'));
      await t.pump();
      expect(retried, 1);
      expect(find.text('Not sent'), findsNothing);
    });

    testWidgets('each intent draws on its own', (t) async {
      await t.pumpWidget(
        _app(
          Column(
            children: [
              for (final tone in Fluent2ToastIntent.values)
                Fluent2Toast(tone.name, tone: tone, title: 'Title'),
            ],
          ),
        ),
      );
      for (final tone in Fluent2ToastIntent.values) {
        expect(find.text(tone.name), findsOneWidget);
      }
    });
  });

  group('overlays without a host', () {
    testWidgets('a dialog completes with the act chosen', (t) async {
      _phone(t);
      bool? answer;
      await t.pumpWidget(
        _app(
          _opener('Delete', (context) async {
            answer = await Fluent2Dialog.confirm(
              context,
              title: 'Delete Q3 plan.docx?',
              message: 'It moves to the recycle bin.',
              confirmLabel: 'Delete it',
              cancelLabel: 'Keep it',
            );
          }),
        ),
      );
      await t.tap(find.text('Delete'));
      await t.pumpAndSettle();
      expect(find.text('It moves to the recycle bin.'), findsOneWidget);
      await t.tap(find.text('Keep it'));
      await t.pumpAndSettle();
      expect(answer, isFalse);
      await t.tap(find.text('Delete'));
      await t.pumpAndSettle();
      await t.tap(find.text('Delete it'));
      await t.pumpAndSettle();
      expect(answer, isTrue);
    });

    testWidgets('showFluent2Dialog raises the dialog it builds', (t) async {
      _phone(t);
      await t.pumpWidget(
        _app(
          brightness: Brightness.dark,
          _opener('Invite', (context) {
            showFluent2Dialog<void>(
              context,
              builder: (context) => Fluent2Dialog(
                title: 'Invite sent',
                message: 'Sam can open the folder now.',
                actions: [
                  Fluent2Button(
                    'Done',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            );
          }),
        ),
      );
      await t.tap(find.text('Invite'));
      await t.pumpAndSettle();
      expect(find.text('Sam can open the folder now.'), findsOneWidget);
      await t.tap(find.text('Done'));
      await t.pumpAndSettle();
      expect(find.text('Invite sent'), findsNothing);
    });

    testWidgets('a side sheet closes by its own close', (t) async {
      _phone(t);
      await t.pumpWidget(
        _app(
          _opener('Filters', (context) {
            showFluent2Sheet<void>(
              context,
              edge: DesignSheetEdge.start,
              builder: (context, close) => Fluent2Sheet(
                title: 'Filter files',
                onClose: close,
                child: const Text('Only shared files'),
              ),
            );
          }),
        ),
      );
      await t.tap(find.text('Filters'));
      await t.pumpAndSettle();
      expect(find.text('Only shared files'), findsOneWidget);
      await t.tap(find.bySemanticsLabel('Close'));
      await t.pumpAndSettle();
      expect(find.text('Only shared files'), findsNothing);
    });

    testWidgets('a bottom sheet shows its acts', (t) async {
      _phone(t);
      var sent = 0;
      await t.pumpWidget(
        _app(
          _opener('Share', (context) {
            showFluent2BottomSheet<void>(
              context,
              builder: (context) => Fluent2BottomSheet(
                title: 'Share Q3 plan.docx',
                onClose: () => Navigator.of(context).pop(),
                actions: [
                  Fluent2Button(
                    'Send',
                    appearance: Fluent2ButtonAppearance.primary,
                    onPressed: () => sent++,
                  ),
                ],
                child: const Text('Sam Lee, Ana Ruiz'),
              ),
            );
          }),
        ),
      );
      await t.tap(find.text('Share'));
      await t.pumpAndSettle();
      await t.tap(find.text('Send'));
      await t.pump();
      expect(sent, 1);
      await t.tap(find.bySemanticsLabel('Close'));
      await t.pumpAndSettle();
      expect(find.text('Sam Lee, Ana Ruiz'), findsNothing);
    });

    testWidgets('an action sheet completes with the action chosen', (t) async {
      _phone(t);
      String? act;
      await t.pumpWidget(
        _app(
          brightness: Brightness.dark,
          _opener('More', (context) async {
            act = await showFluent2ActionSheet<String>(
              context,
              title: 'Q3 plan.docx',
              message: 'Shared with 4 people',
              actions: const [
                Fluent2ActionSheetAction(
                  'move',
                  'Move',
                  icon: Fluent2Icons.folder,
                ),
                Fluent2ActionSheetAction('locked', 'Lock', enabled: false),
                Fluent2ActionSheetAction('delete', 'Delete', destructive: true),
              ],
            );
          }),
        ),
      );
      await t.tap(find.text('More'));
      await t.pumpAndSettle();
      expect(find.text('Shared with 4 people'), findsOneWidget);
      await t.tap(find.text('Delete'));
      await t.pumpAndSettle();
      expect(act, 'delete');
    });

    testWidgets('a menu completes with the item chosen', (t) async {
      _phone(t);
      String? picked;
      await t.pumpWidget(
        _app(
          Center(
            child: Builder(
              builder: (context) => Fluent2Button(
                'Options',
                onPressed: () async {
                  picked = await showFluent2Menu<String>(
                    context,
                    title: 'Q3 plan.docx',
                    items: const [
                      Fluent2MenuItem('rename', 'Rename'),
                      Fluent2MenuItem('copy', 'Make a copy'),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );
      await t.tap(find.text('Options'));
      await t.pumpAndSettle();
      await t.tap(find.text('Make a copy'));
      await t.pumpAndSettle();
      expect(picked, 'copy');
    });
  });
}
