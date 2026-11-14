// The theme API, held to Material's: a theme value with copyWith, lerp and
// value equality; knobs (shapes, strokes, density, typeface, component
// themes, motion) that reach the parts; one InheritedTheme that mounts under
// a MaterialApp, a CupertinoApp or a bare WidgetsApp.
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';

void main() {
  group('FrostedThemeData', () {
    test('FrostedThemeData() is opal, light, with the look\'s knobs', () {
      final t = FrostedThemeData();
      expect(t, FrostedThemeData.opal());
      expect(t.id, 'opal');
      expect(t.isDark, isFalse);
      expect(t.density, FrostedDensity.standard);
      expect(t.typeface, FrostedTypeface.look);
      expect(t.components, const FrostedComponentThemes());
      expect(FrostedMotion.look, FrostedMotion.look);
    });

    test('every named preset is its preset', () {
      final named = <String, FrostedThemeData Function(Brightness)>{
        'opal': FrostedThemeData.opal,
        'quartz': FrostedThemeData.quartz,
        'garnet': FrostedThemeData.garnet,
        'glacier': FrostedThemeData.glacier,
        'cobalt': FrostedThemeData.cobalt,
        'jade': FrostedThemeData.jade,
        'copper': FrostedThemeData.copper,
      };
      expect(named.keys, FrostedThemeData.presets);
      named.forEach((id, make) {
        for (final b in Brightness.values) {
          expect(identical(make(b), FrostedThemeData.preset(id, b)), isTrue);
        }
      });
    });

    test('copyWith with nothing named is an equal value', () {
      final t = FrostedThemeData.garnet();
      final copy = t.copyWith();
      expect(identical(copy, t), isFalse);
      expect(copy, t);
      expect(copy.hashCode, t.hashCode);
    });

    test('copyWith changes what it names and nothing else', () {
      final t = FrostedThemeData.opal();
      final c = t.copyWith(
        colorScheme: t.colorScheme.copyWith(accent: const Color(0xFF0A7CFF)),
        density: FrostedDensity.compact,
      );
      expect(c.colorScheme.accent, const Color(0xFF0A7CFF));
      expect(c.density, FrostedDensity.compact);
      expect(c.colorScheme.background, t.colorScheme.background);
      expect(c.textTheme.titleMedium, t.textTheme.titleMedium);
      expect(c, isNot(t));
    });

    test('lerp lands on either end and blends between', () {
      final a = FrostedThemeData.opal();
      final b = FrostedThemeData.cobalt();
      expect(identical(a.lerp(b, 0), a), isTrue);
      expect(identical(a.lerp(b, 1), b), isTrue);
      expect(a.lerp(null, .5), a);
      final mid = a.lerp(b, .5);
      expect(
        mid.colorScheme.background,
        Color.lerp(a.colorScheme.background, b.colorScheme.background, .5),
      );
      expect(
        FrostedCorners.r18,
        closeTo((FrostedCorners.r18 + FrostedCorners.r18) / 2, .01),
      );
      expect(
        mid.shadows.tile,
        BoxShadow.lerpList(a.shadows.tile, b.shadows.tile, .5),
      );
      expect(mid.id, b.id);
      expect(a.lerp(b, .4).id, a.id);
    });

    test('debugFillProperties names every knob', () {
      final text = FrostedThemeData.opal().toDiagnosticsNode().toStringDeep(
        minLevel: DiagnosticLevel.info,
      );
      for (final name in [
        'colorScheme',
        'textTheme',
        'shadows',
        'glass',
        'pearl',
        'toast',
        'density',
        'typeface',
        'components',
        'accent',
        'background',
      ]) {
        expect(text, contains(name));
      }
    });

    test('the corners are the look\'s tokens', () {
      expect(
        FrostedCorners.extraSmall,
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      );
      expect(
        FrostedCorners.small,
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      );
      expect(
        FrostedCorners.medium,
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      );
      expect(
        FrostedCorners.large,
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      );
      expect(FrostedCorners.full, const StadiumBorder());
    });

    test('a new typeface sets every type slot in its faces', () {
      final t = FrostedThemeData.opal();
      final face = t.copyWith(
        typeface: const FrostedTypeface.app(display: 'Fraunces', text: 'Inter'),
      );
      expect(face.textTheme.titleMedium.fontFamily, 'Inter');
      expect(face.textTheme.labelMedium.fontFamily, 'Inter');
      expect(face.textTheme.headlineSmall.fontFamily, 'Fraunces');
      expect(face.textTheme.displayMedium.fontFamily, 'Fraunces');
      expect(
        face.textTheme.titleMedium.fontSize,
        t.textTheme.titleMedium.fontSize,
      );
      expect(face.textTheme.titleMedium.height, t.textTheme.titleMedium.height);
      expect(
        face.textTheme.titleMedium.fontWeight,
        t.textTheme.titleMedium.fontWeight,
      );
      // Back again: the look's faces at the look's sizes.
      final back = face.copyWith(typeface: FrostedTypeface.look);
      expect(
        back.textTheme.titleMedium.fontFamily,
        t.textTheme.titleMedium.fontFamily,
      );
      expect(
        back.textTheme.titleMedium.fontSize,
        closeTo(t.textTheme.titleMedium.fontSize!, 1e-9),
      );
      // A text theme given with the typeface keeps what it is given.
      final own = t.copyWith(
        typeface: const FrostedTypeface.app(display: 'A', text: 'B'),
        textTheme: t.textTheme.copyWith(
          titleMedium: const TextStyle(fontFamily: 'C'),
        ),
      );
      expect(own.textTheme.titleMedium.fontFamily, 'C');
    });

    test('from(accent) settles every word to read on its ground', () {
      for (final b in Brightness.values) {
        for (final accent in const [
          Color(0xFF0A7CFF),
          Color(0xFFFFD60A),
          Color(0xFF34C759),
          Color(0xFF8E8E93),
        ]) {
          final t = FrostedThemeData.from(
            accent: accent,
            brightness: b,
            danger: const Color(0xFFFF3B30),
          );
          expect(t.id, 'custom');
          expect(t.brightness, b);
          for (final ground in [
            t.colorScheme.background,
            t.colorScheme.surface,
          ]) {
            for (final ink in [
              t.colorScheme.textPrimary,
              t.colorScheme.textSecondary,
              t.colorScheme.accentText,
              t.colorScheme.over,
            ]) {
              expect(
                FrostedThemeData.contrast(ink, ground),
                greaterThanOrEqualTo(4.5),
                reason: '$accent ${b.name}: $ink on $ground',
              );
            }
          }
          expect(
            FrostedThemeData.contrast(
              t.colorScheme.onButton,
              t.colorScheme.buttonBottom,
            ),
            greaterThanOrEqualTo(4.5),
            reason: '$accent ${b.name}: the act\'s words',
          );
        }
      }
    });

    test('the dark twin wears the knobs', () {
      final t = FrostedThemeData.jade().copyWith(
        density: FrostedDensity.compact,
      );
      final night = t.darkTwin;
      expect(night.isDark, isTrue);
      expect(night.id, 'jade');
      expect(night.density, FrostedDensity.compact);
      expect(identical(t.darkTwin, night), isTrue);
      final dark = FrostedThemeData.jade(Brightness.dark);
      expect(identical(dark.darkTwin, dark), isTrue);
    });
  });

  group('the knobs', () {
    test('each knob copies, lerps and compares by value', () {
      expect(
        FrostedDensity.lerp(
          FrostedDensity.standard,
          FrostedDensity.compact,
          .5,
        ),
        FrostedDensity.comfortable,
      );
      expect(FrostedDensity.compact.height(44), 36);
      expect(FrostedDensity.compact.height(20), 16);
      expect(
        FrostedMotion.lerp(FrostedMotion.look, FrostedMotion.still, .5).base,
        const Duration(milliseconds: 100),
      );
      expect(
        const FrostedTypeface().copyWith(display: 'Fraunces'),
        const FrostedTypeface(display: 'Fraunces'),
      );
    });

    test('density follows the platform until set', () {
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      for (final (platform, density) in [
        (TargetPlatform.android, FrostedDensity.standard),
        (TargetPlatform.iOS, FrostedDensity.standard),
        (TargetPlatform.macOS, FrostedDensity.compact),
        (TargetPlatform.windows, FrostedDensity.compact),
        (TargetPlatform.linux, FrostedDensity.compact),
      ]) {
        debugDefaultTargetPlatformOverride = platform;
        expect(FrostedThemeData.opal().density, density, reason: '$platform');
        expect(
          FrostedThemeData.opal()
              .copyWith(density: FrostedDensity.comfortable)
              .density,
          FrostedDensity.comfortable,
        );
      }
    });

    test('a style layers slot by slot, the first that answers wins', () {
      const widget = FrostedStyle(
        fill: WidgetStatePropertyAll(Color(0xFF000001)),
      );
      final theme = FrostedStyle(
        fill: const WidgetStatePropertyAll(Color(0xFF000002)),
        foreground: WidgetStateProperty.resolveWith(
          (s) =>
              s.contains(WidgetState.pressed) ? const Color(0xFF000003) : null,
        ),
      );
      final layered = FrostedStyle.layered([widget, null, theme]);
      expect(layered.fill!.resolve({}), const Color(0xFF000001));
      expect(layered.foreground!.resolve({}), isNull);
      expect(
        layered.foreground!.resolve({WidgetState.pressed}),
        const Color(0xFF000003),
      );
      expect(
        FrostedStyle.first<Color>(
          [null, widget, theme],
          (s) => s.foreground,
          {WidgetState.pressed},
        ),
        const Color(0xFF000003),
      );
      expect(const FrostedStyle().isEmpty, isTrue);
      expect(widget.merge(theme).fill, widget.fill);
      expect(widget.merge(theme).foreground, theme.foreground);
      final mid = FrostedStyle.lerp(
        const FrostedStyle(iconSize: WidgetStatePropertyAll(10)),
        const FrostedStyle(iconSize: WidgetStatePropertyAll(20)),
        .5,
      );
      expect(mid!.iconSize!.resolve({}), 15);
    });

    test('component themes copy, lerp and compare by value', () {
      const a = FrostedComponentThemes(
        card: FrostedStyle(padding: WidgetStatePropertyAll(EdgeInsets.all(8))),
      );
      expect(
        a,
        const FrostedComponentThemes(
          card: FrostedStyle(
            padding: WidgetStatePropertyAll(EdgeInsets.all(8)),
          ),
        ),
      );
      final b = a.copyWith(
        button: const FrostedStyle(
          minimumSize: WidgetStatePropertyAll(Size(64, 40)),
        ),
      );
      expect(b.card, a.card);
      expect(b.button.minimumSize!.resolve({}), const Size(64, 40));
      final mid = FrostedComponentThemes.lerp(
        a,
        const FrostedComponentThemes(
          card: FrostedStyle(
            padding: WidgetStatePropertyAll(EdgeInsets.all(16)),
          ),
        ),
        .5,
      );
      expect(mid.card.padding!.resolve({}), const EdgeInsets.all(12));
    });
  });

  group('FrostedTheme', () {
    Widget probe(void Function(BuildContext) read) => Builder(
      builder: (context) {
        read(context);
        return const SizedBox();
      },
    );

    testWidgets('mounts under a MaterialApp', (tester) async {
      final data = FrostedThemeData.glacier();
      late BuildContext seen;
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => FrostedTheme(data: data, child: child!),
          home: probe((c) => seen = c),
        ),
      );
      expect(FrostedTheme.of(seen), data);
      expect(seen.frostedTheme, data);
      expect(
        DefaultTextStyle.of(seen).style.fontFamily,
        data.textTheme.titleMedium.fontFamily,
      );
      expect(IconTheme.of(seen).color, data.colorScheme.textPrimary);
      expect(FrostedTheme.darkOf(seen).isDark, isTrue);
    });

    testWidgets('mounts under a CupertinoApp, with a working text field', (
      tester,
    ) async {
      await tester.pumpWidget(
        CupertinoApp(
          builder: (context, child) =>
              FrostedTheme(data: FrostedThemeData.opal(), child: child!),
          home: const Center(
            child: SizedBox(width: 200, child: EditableTextProbe()),
          ),
        ),
      );
      await tester.enterText(find.byType(EditableText), 'glass');
      expect(find.text('glass'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('mounts under a bare WidgetsApp', (tester) async {
      late BuildContext seen;
      await tester.pumpWidget(
        WidgetsApp(
          color: const Color(0xFFFFFFFF),
          builder: (context, child) => FrostedTheme(
            data: FrostedThemeData.copper(Brightness.dark),
            child: probe((c) => seen = c),
          ),
        ),
      );
      expect(FrostedTheme.of(seen).id, 'copper');
      expect(
        Localizations.of<MaterialLocalizations>(seen, MaterialLocalizations),
        isNotNull,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('of throws a helpful error with no theme; maybeOf is null', (
      tester,
    ) async {
      late BuildContext seen;
      await tester.pumpWidget(probe((c) => seen = c));
      expect(FrostedTheme.maybeOf(seen), isNull);
      expect(
        () => FrostedTheme.of(seen),
        throwsA(
          isA<FlutterError>().having(
            (e) => e.toString(),
            'message',
            contains('No FrostedTheme in scope'),
          ),
        ),
      );
    });

    testWidgets('InheritedTheme.capture carries it into a route', (
      tester,
    ) async {
      final data = FrostedThemeData.jade();
      late BuildContext inside;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: FrostedTheme(
            data: data,
            child: Builder(
              builder: (context) => InheritedTheme.capture(
                from: context,
                to: null,
              ).wrap(probe((c) => inside = c)),
            ),
          ),
        ),
      );
      expect(FrostedTheme.of(inside), data);
    });

    testWidgets('AnimatedFrostedTheme passes through the lerp', (tester) async {
      final a = FrostedThemeData.opal();
      final b = FrostedThemeData.cobalt();
      late BuildContext seen;
      Widget at(FrostedThemeData data) => Directionality(
        textDirection: TextDirection.ltr,
        child: AnimatedFrostedTheme(
          data: data,
          duration: const Duration(milliseconds: 200),
          curve: Curves.linear,
          child: probe((c) => seen = c),
        ),
      );
      await tester.pumpWidget(at(a));
      await tester.pumpWidget(at(b));
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        FrostedTheme.of(seen).colorScheme.background,
        Color.lerp(a.colorScheme.background, b.colorScheme.background, .5),
      );
      await tester.pumpAndSettle();
      expect(FrostedTheme.of(seen), b);
    });

    testWidgets('motion is the look\'s, and still under Reduce Motion', (
      tester,
    ) async {
      late BuildContext seen;
      Widget at({required bool reduce}) => MediaQuery(
        data: MediaQueryData(disableAnimations: reduce),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: FrostedTheme(
            data: FrostedThemeData.opal(),
            child: probe((c) => seen = c),
          ),
        ),
      );
      await tester.pumpWidget(at(reduce: false));
      expect(FrostedMotion.of(seen), FrostedMotion.look);
      await tester.pumpWidget(at(reduce: true));
      expect(FrostedMotion.of(seen), FrostedMotion.still);
      expect(FrostedMotion.of(seen).moves, isFalse);
    });

    testWidgets('a nested theme re-themes its subtree only', (tester) async {
      late BuildContext outer, inner;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: FrostedTheme(
            data: FrostedThemeData.opal(),
            child: Column(
              children: [
                probe((c) => outer = c),
                FrostedTheme(
                  data: FrostedThemeData.opal(Brightness.dark),
                  child: probe((c) => inner = c),
                ),
              ],
            ),
          ),
        ),
      );
      expect(FrostedTheme.of(outer).isDark, isFalse);
      expect(FrostedTheme.of(inner).isDark, isTrue);
    });
  });
}

/// A plain editable line, as a field under a CupertinoApp stands.
class EditableTextProbe extends StatefulWidget {
  const EditableTextProbe({super.key});

  @override
  State<EditableTextProbe> createState() => _EditableTextProbeState();
}

class _EditableTextProbeState extends State<EditableTextProbe> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    return EditableText(
      controller: _controller,
      focusNode: _focus,
      style: t.textTheme.titleMedium,
      cursorColor: t.colorScheme.accent,
      backgroundCursorColor: t.colorScheme.textTertiary,
    );
  }
}
