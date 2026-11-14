import 'dart:ui' show Tristate;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';
import 'package:fluent2_design_ui/fluent2_design_host.dart';
import 'package:fluent2_design_ui/src/fluent2_design/components/input/field_core.dart'
    show Fluent2FieldFrame;
import 'package:fluent2_design_ui/src/fluent2_design/internal/well.dart'
    show fluent2WellDisabled;

Widget _host(Widget child, {Brightness brightness = Brightness.light}) =>
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (BuildContext context, Widget? page) =>
          Fluent2Host(brightness: brightness, child: page!),
      home: Center(child: child),
    );

final _light = Fluent2ThemeData.preset('lapis', Brightness.light);

void _nothing() {}

/// The fill and stroke of the button box under [finder].
BoxDecoration _face(WidgetTester t, Finder finder) =>
    t
            .widget<DecoratedBox>(
              find
                  .descendant(
                    of: find.descendant(
                      of: finder,
                      matching: find.byType(Fluent2ButtonBox),
                    ),
                    matching: find.byType(DecoratedBox),
                  )
                  .first,
            )
            .decoration
        as BoxDecoration;

void main() {
  setUp(
    () =>
        TestWidgetsFlutterBinding.ensureInitialized()
            .platformDispatcher
            .accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
          disableAnimations: true,
        ),
  );
  tearDown(
    () => TestWidgetsFlutterBinding.ensureInitialized().platformDispatcher
        .clearAccessibilityFeaturesTestValue(),
  );

  group('styling knobs', () {
    Widget themed(Fluent2ThemeData theme, Widget child) => MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (BuildContext context, Widget? page) =>
          Fluent2Host(light: theme, brightness: Brightness.light, child: page!),
      home: Center(child: child),
    );

    ShapeDecoration shaped(WidgetTester t, Finder finder) =>
        t
                .widget<DecoratedBox>(
                  find
                      .descendant(
                        of: find.descendant(
                          of: finder,
                          matching: find.byType(Fluent2ButtonBox),
                        ),
                        matching: find.byType(DecoratedBox),
                      )
                      .first,
                )
                .decoration
            as ShapeDecoration;

    testWidgets('style: wins over the theme, slot by slot', (t) async {
      const red = Color(0xFFC50F1F);
      await t.pumpWidget(
        themed(
          _light.copyWith(
            secondaryButtonTheme: const Fluent2Style(
              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
            ),
          ),
          Fluent2Button(
            'Send',
            key: const ValueKey('b'),
            onPressed: _nothing,
            style: const Fluent2Style(
              fill: WidgetStatePropertyAll(red),
              shape: WidgetStatePropertyAll(StadiumBorder()),
            ),
          ),
        ),
      );
      final face = shaped(t, find.byKey(const ValueKey('b')));
      expect(face.color, red);
      expect(face.shape, isA<StadiumBorder>());
    });

    testWidgets(
      "the density reaches a button; Fluent's corner and stroke stand",
      (t) async {
        await t.pumpWidget(
          themed(
            _light.copyWith(density: Fluent2Density.compact),
            Fluent2Button(
              'Save',
              key: const ValueKey('b'),
              onPressed: _nothing,
            ),
          ),
        );
        // An unstyled face draws a box: Fluent's medium corner, its thin
        // stroke all round.
        final face =
            t
                    .widget<DecoratedBox>(
                      find
                          .descendant(
                            of: find.descendant(
                              of: find.byKey(const ValueKey('b')),
                              matching: find.byType(Fluent2ButtonBox),
                            ),
                            matching: find.byType(DecoratedBox),
                          )
                          .first,
                    )
                    .decoration
                as BoxDecoration;
        expect(face.borderRadius, BorderRadius.circular(Fluent2Radius.medium));
        expect((face.border! as Border).top.width, Fluent2Stroke.thin);
        expect(
          t
              .getSize(
                find.descendant(
                  of: find.byKey(const ValueKey('b')),
                  matching: find.byType(Fluent2ButtonBox),
                ),
              )
              .height,
          // Under a finger every face stands the 48 target.
          defaultTargetPlatform == TargetPlatform.android ? 48 : 24,
        );
      },
      variant: TargetPlatformVariant(const {
        TargetPlatform.android,
        TargetPlatform.macOS,
      }),
    );

    testWidgets('an appearance theme styles its buttons only', (t) async {
      const ink = Color(0xFF5C2E91);
      await t.pumpWidget(
        themed(
          _light.copyWith(
            primaryButtonTheme: const Fluent2Style(
              fill: WidgetStatePropertyAll(ink),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Fluent2Button(
                'Go',
                key: const ValueKey('p'),
                appearance: Fluent2ButtonAppearance.primary,
                onPressed: _nothing,
              ),
              Fluent2Button(
                'Back',
                key: const ValueKey('s'),
                onPressed: _nothing,
              ),
            ],
          ),
        ),
      );
      expect(_face(t, find.byKey(const ValueKey('p'))).color, ink);
      expect(
        _face(t, find.byKey(const ValueKey('s'))).color,
        _light.colors.neutralBackground1,
      );
    });

    testWidgets(
      'a field takes the medium step and the density on a desk, its 48 line '
      'under a finger',
      (t) async {
        await t.pumpWidget(
          themed(
            _light.copyWith(density: Fluent2Density.compact),
            const SizedBox(
              width: 240,
              child: Fluent2TextField(label: 'Name', key: ValueKey('f')),
            ),
          ),
        );
        final frame = find.descendant(
          of: find.byKey(const ValueKey('f')),
          matching: find.byType(Fluent2FieldFrame),
        );
        // Under a finger the frame is the 48 target overall, its hairlines
        // drawn over its line's edges.
        expect(
          t.getSize(frame).height,
          defaultTargetPlatform == TargetPlatform.android ? 48 : 24,
        );
      },
      variant: TargetPlatformVariant(const {
        TargetPlatform.windows,
        TargetPlatform.android,
      }),
    );

    testWidgets('density never moves the target: 48 on touch, 44 on a desk', (
      t,
    ) async {
      Future<int> pressesAt(TargetPlatform platform) async {
        var presses = 0;
        debugDefaultTargetPlatformOverride = platform;
        await t.pumpWidget(
          themed(
            _light.copyWith(density: Fluent2Density.compact),
            Fluent2IconButton(
              Fluent2Icons.add,
              key: const ValueKey('i'),
              label: 'Add',
              size: Fluent2ButtonSize.small,
              onPressed: () => presses++,
            ),
          ),
        );
        // 23 off the centre: inside a 48 target, outside a 44 one.
        await t.tapAt(
          t.getCenter(find.byKey(const ValueKey('i'))) + const Offset(23, 0),
        );
        await t.pump(const Duration(milliseconds: 300));
        debugDefaultTargetPlatformOverride = null;
        return presses;
      }

      expect(await pressesAt(TargetPlatform.android), 1);
      expect(await pressesAt(TargetPlatform.iOS), 1);
      expect(await pressesAt(TargetPlatform.macOS), 0);
    });

    testWidgets('the default theme draws Fluent\'s own corners', (t) async {
      await t.pumpWidget(
        _host(
          Fluent2Button('Save', key: const ValueKey('b'), onPressed: _nothing),
        ),
      );
      final face = _face(t, find.byKey(const ValueKey('b')));
      expect(face.borderRadius, BorderRadius.circular(4));
    });
  });

  group('Fluent2Button', () {
    testWidgets(
      "stands at Fluent's three heights with a pointer, the 48 "
      'target under a finger, even with room to grow',
      (t) async {
        final touch = defaultTargetPlatform == TargetPlatform.android;
        for (final (size, height) in const [
          (Fluent2ButtonSize.small, 24.0),
          (Fluent2ButtonSize.medium, 32.0),
          (Fluent2ButtonSize.large, 40.0),
        ]) {
          await t.pumpWidget(
            _host(Fluent2Button('Save', size: size, onPressed: () {})),
          );
          expect(
            t.getSize(find.byType(Fluent2ButtonBox)).height,
            touch ? 48.0 : height,
          );
        }
      },
      variant: TargetPlatformVariant(const {
        TargetPlatform.android,
        TargetPlatform.macOS,
      }),
    );

    testWidgets('keeps its minimum width (96 at medium)', (t) async {
      await t.pumpWidget(_host(Fluent2Button('OK', onPressed: () {})));
      expect(t.getSize(find.byType(Fluent2ButtonBox)).width, 96);
    });

    testWidgets('primary is the brand fill with the words on brand', (t) async {
      await t.pumpWidget(
        _host(
          Fluent2Button(
            'Send',
            appearance: Fluent2ButtonAppearance.primary,
            onPressed: () {},
          ),
        ),
      );
      final face = _face(t, find.byType(Fluent2Button));
      expect(face.color, _light.colors.brandBackground);
      expect(
        t.widget<Text>(find.text('Send')).style!.color,
        _light.colors.neutralForegroundOnBrand,
      );
      expect(face.borderRadius, BorderRadius.circular(4));
    });

    testWidgets('secondary is the surface inside the 1 stroke', (t) async {
      await t.pumpWidget(_host(Fluent2Button('Cancel', onPressed: () {})));
      final face = _face(t, find.byType(Fluent2Button));
      expect(face.color, _light.colors.neutralBackground1);
      expect((face.border! as Border).top.color, _light.colors.neutralStroke1);
    });

    testWidgets('disabled draws the disabled face and does nothing', (t) async {
      await t.pumpWidget(_host(const Fluent2Button('Send', onPressed: null)));
      final face = _face(t, find.byType(Fluent2Button));
      // Fluent's disabled grey, laid as a step from the ground under it.
      expect(face.color, fluent2WellDisabled(_light));
      final node = t.getSemantics(find.bySemanticsLabel('Send'));
      expect(node.flagsCollection.isEnabled, Tristate.isFalse);
      expect(node.flagsCollection.isButton, isTrue);
    });

    testWidgets('a 32 button answers a tap just outside its edge', (t) async {
      var taps = 0;
      await t.pumpWidget(_host(Fluent2Button('Save', onPressed: () => taps++)));
      final box = t.getRect(find.byType(Fluent2ButtonBox));
      await t.tapAt(Offset(box.center.dx, box.top - 5));
      expect(taps, 1);
    }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

    testWidgets('the keyboard reaches it and Enter presses it', (t) async {
      var taps = 0;
      await t.pumpWidget(_host(Fluent2Button('Save', onPressed: () => taps++)));
      await t.sendKeyEvent(LogicalKeyboardKey.tab);
      await t.pump();
      await t.sendKeyEvent(LogicalKeyboardKey.enter);
      await t.pump();
      expect(taps, 1);
    });

    testWidgets('the shapes round at 4, the pill, and none', (t) async {
      for (final (shape, radius) in const [
        (Fluent2ButtonShape.rounded, 4.0),
        (Fluent2ButtonShape.circular, 16.0),
        (Fluent2ButtonShape.square, 0.0),
      ]) {
        await t.pumpWidget(
          _host(Fluent2Button('Save', shape: shape, onPressed: () {})),
        );
        final face = _face(t, find.byType(Fluent2Button));
        // A square face paints no radius at all: Flutter refuses a radius,
        // even zero, on a stroke of fewer than four sides (a split half).
        expect(
          (face.borderRadius as BorderRadius?)?.topLeft.x ?? 0,
          closeTo(radius, 0.01),
          reason: shape.name,
        );
      }
    }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));
  });

  group('the other buttons', () {
    testWidgets(
      'an icon button is its height square and names itself',
      (t) async {
        await t.pumpWidget(
          _host(
            Fluent2IconButton(
              Fluent2Icons.moreHorizontal,
              label: 'More options',
              onPressed: () {},
            ),
          ),
        );
        // Under a finger the 48 target, square.
        final side = defaultTargetPlatform == TargetPlatform.android
            ? 48.0
            : 32.0;
        expect(t.getSize(find.byType(Fluent2ButtonBox)), Size(side, side));
        expect(find.bySemanticsLabel('More options'), findsOneWidget);
      },
      variant: TargetPlatformVariant(const {
        TargetPlatform.android,
        TargetPlatform.macOS,
      }),
    );

    testWidgets('a selected icon button wears its filled glyph', (t) async {
      await t.pumpWidget(
        _host(
          Fluent2IconButton(
            Fluent2Icons.star,
            label: 'Favourite',
            selected: true,
            filled: Fluent2Icons.starFilled,
            onPressed: () {},
          ),
        ),
      );
      expect(find.byIcon(Fluent2Icons.starFilled), findsOneWidget);
      final node = t.getSemantics(find.bySemanticsLabel('Favourite'));
      expect(node.flagsCollection.isToggled, Tristate.isTrue);
    });

    testWidgets('a toggle button asks for the other state', (t) async {
      bool? asked;
      await t.pumpWidget(
        _host(
          Fluent2ToggleButton(
            'Mic',
            value: true,
            icon: Fluent2Icons.mic,
            checkedIcon: Fluent2Icons.micFilled,
            onChanged: (v) => asked = v,
          ),
        ),
      );
      expect(find.byIcon(Fluent2Icons.micFilled), findsOneWidget);
      await t.tap(find.text('Mic'));
      expect(asked, isFalse);
    });

    testWidgets('a compound button carries its second line', (t) async {
      await t.pumpWidget(
        _host(
          Fluent2CompoundButton(
            'New meeting',
            secondary: 'Schedule a call',
            onPressed: () {},
          ),
        ),
      );
      expect(find.text('Schedule a call'), findsOneWidget);
      final second = t.widget<Text>(find.text('Schedule a call'));
      expect(second.style!.fontSize, 12);
    });

    testWidgets('a menu button wears the chevron after its words', (t) async {
      await t.pumpWidget(_host(Fluent2MenuButton('Sort', onPressed: () {})));
      final words = t.getRect(find.text('Sort'));
      final chevron = t.getRect(find.byType(Icon).last);
      expect(chevron.left, greaterThan(words.right));
    });

    testWidgets("a split button's two halves act apart; its menu runs a "
        'choice and closes', (t) async {
      var main = 0;
      var all = 0;
      await t.pumpWidget(
        _host(
          Fluent2SplitButton(
            'Reply',
            onPressed: () => main++,
            actions: [
              Fluent2SplitAction('Reply all', onPressed: () => all++),
              const Fluent2SplitAction('Forward', onPressed: null),
            ],
          ),
        ),
      );
      await t.tap(find.text('Reply'));
      expect(main, 1);
      expect(find.text('Reply all'), findsNothing);
      await t.tap(find.byType(Icon).last);
      await t.pumpAndSettle();
      expect(find.text('Reply all'), findsOneWidget);
      await t.tap(find.text('Forward'));
      await t.pumpAndSettle();
      expect(find.text('Forward'), findsOneWidget, reason: 'disabled stays');
      await t.tap(find.text('Reply all'));
      await t.pumpAndSettle();
      expect((main, all), (1, 1));
      expect(find.text('Reply all'), findsNothing);
    });

    testWidgets('Down on the main half opens the menu, Escape closes it', (
      t,
    ) async {
      await t.pumpWidget(
        _host(
          const Fluent2SplitButton(
            'Reply',
            onPressed: _nothing,
            actions: [Fluent2SplitAction('Reply all', onPressed: _nothing)],
          ),
        ),
      );
      await t.sendKeyEvent(LogicalKeyboardKey.tab);
      await t.pump();
      await t.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await t.pumpAndSettle();
      expect(find.text('Reply all'), findsOneWidget);
      await t.sendKeyEvent(LogicalKeyboardKey.escape);
      await t.pumpAndSettle();
      expect(find.text('Reply all'), findsNothing);
    });
  });

  group('people', () {
    test("initials are Fluent's", () {
      expect(fluent2Initials('Ines Duarte'), 'ID');
      expect(fluent2Initials('Kai'), 'K');
      expect(fluent2Initials('mara de la cruz okafor'), 'MO');
      expect(fluent2Initials('Ines Duarte', single: true), 'I');
      expect(fluent2Initials('  '), '');
    });

    testWidgets('an avatar shows its initials and says its presence', (
      t,
    ) async {
      await t.pumpWidget(
        _host(
          const Fluent2Avatar(
            name: 'Ines Duarte',
            presence: Fluent2Presence.available,
          ),
        ),
      );
      expect(find.text('ID'), findsOneWidget);
      expect(find.bySemanticsLabel('Ines Duarte, available'), findsOneWidget);
      expect(t.getSize(find.byType(Fluent2Avatar)), const Size(32, 32));
    });

    testWidgets('the colourful hue is the name\'s, the same each time', (
      t,
    ) async {
      final hue = fluent2AvatarHue(_light, 'Kai Tanaka');
      expect(fluent2AvatarHue(_light, 'Kai Tanaka'), hue);
      expect(hue.$1, isNot(_light.colors.neutralBackground6));
      await t.pumpWidget(
        _host(
          const Fluent2Avatar(
            name: 'Kai Tanaka',
            color: Fluent2AvatarColor.colorful,
          ),
        ),
      );
      expect(
        find.byWidgetPredicate((w) => w is ColoredBox && w.color == hue.$1),
        findsOneWidget,
      );
      expect(t.widget<Text>(find.text('KT')).style!.color, hue.$2);
      expect(
        Fluent2ThemeData.contrast(hue.$2, hue.$1),
        greaterThanOrEqualTo(4.5),
      );
    });

    testWidgets('a group draws four and the overflow', (t) async {
      await t.pumpWidget(
        _host(
          const Fluent2AvatarGroup(
            people: [
              Fluent2AvatarPerson('Ines Duarte'),
              Fluent2AvatarPerson('Kai Tanaka'),
              Fluent2AvatarPerson('Mara Okafor'),
              Fluent2AvatarPerson('Tomas Lindqvist'),
              Fluent2AvatarPerson('Priya Raman'),
              Fluent2AvatarPerson('Noor Haddad'),
            ],
          ),
        ),
      );
      expect(find.text('+3'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'and 3 more$')), findsOneWidget);
    });

    testWidgets('a persona reads as one, its lines in quieter inks', (t) async {
      await t.pumpWidget(
        _host(
          const Fluent2Persona(
            name: 'Mara Okafor',
            secondary: 'Product designer',
            tertiary: 'In a meeting',
            size: 56,
            presence: Fluent2Presence.busy,
          ),
        ),
      );
      expect(find.text('Product designer'), findsOneWidget);
      expect(
        t.widget<Text>(find.text('Product designer')).style!.color,
        _light.colors.neutralForeground2,
      );
      final node = t.getSemantics(find.byType(Fluent2Persona));
      expect(node.label, contains('Mara Okafor'));
      expect(node.label, contains('busy'));
    });

    testWidgets('every presence draws its badge', (t) async {
      for (final p in Fluent2Presence.values) {
        await t.pumpWidget(_host(Fluent2PresenceBadge(p, size: 16)));
        // The disc of 16 on its 1 ring of the surface.
        expect(
          t.getSize(find.byType(Fluent2PresenceBadge)),
          const Size(18, 18),
        );
        expect(t.takeException(), isNull);
      }
    });
  });

  group('Fluent2Spinner', () {
    testWidgets('stands still while motion is off and says its words', (
      t,
    ) async {
      await t.pumpWidget(_host(const Fluent2Spinner(label: 'Loading files')));
      await t.pumpAndSettle();
      expect(find.bySemanticsLabel('Loading files'), findsWidgets);
      expect(
        t.getSize(
          find
              .descendant(
                of: find.byType(Fluent2Spinner),
                matching: find.byType(CustomPaint),
              )
              .first,
        ),
        const Size(32, 32),
      );
    });
  });
}
