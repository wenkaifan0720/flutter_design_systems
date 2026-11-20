// Flows through the showcase app, Hearth: a saved email reaches the receipt, checkout keeps an empty field focused
// until it is corrected, the thermostat's value stays in its dial, the phone's destinations keep full text size, the
// date sheet and the inline calendar share one today, and an RTL notice keeps its date and punctuation together.
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

// ignore: avoid_relative_lib_imports
import '../example/lib/main.dart';
import 'gallery_live_test.dart' show tapLive;
import 'gallery_support.dart' show loadBundledFonts, settle;
import 'support.dart' show loadNeumorphicFonts;

Finder _key(String id) => find.byKey(Key(id));

Finder _editable(String id) =>
    find.descendant(of: _key(id), matching: find.byType(EditableText));

Future<void> _open(
  WidgetTester tester,
  String page, {
  double width = 390,
  double scale = 1,
  bool rtl = false,
}) async {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    GalleryApp(
      key: UniqueKey(),
      initialPage: page,
      initialCustom: GalleryCustom(textScale: scale, rightToLeft: rtl),
    ),
  );
  await settle(tester);
}

void main() {
  setUpAll(() async {
    await loadNeumorphicFonts();
    await loadBundledFonts();
  });

  for (final rtl in [false, true]) {
    testWidgets(
      'saved email reaches the receipt and survives navigation, rtl=$rtl',
      (tester) async {
        await _open(tester, 'form', rtl: rtl);
        await tester.enterText(
          _editable('hearth-email'),
          '  sam@example.org  ',
        );
        await tapLive(tester, _key('hearth-save'));
        await tester.pump(const Duration(seconds: 5));
        await settle(tester);
        await tapLive(tester, _key('hearth-nav-checkout'));
        await tapLive(tester, _key('hearth-pay'));
        final dialog = tester.widget<NeumorphicDialog>(
          find.byType(NeumorphicDialog),
        );
        expect(
          dialog.message,
          contains(rtl ? '\u2066sam@example.org\u2069.' : 'sam@example.org.'),
        );
        await tapLive(tester, _key('hearth-paid'));
        await tapLive(tester, _key('hearth-nav-form'));
        expect(
          tester
              .widget<EditableText>(_editable('hearth-email'))
              .controller
              .text,
          'sam@example.org',
        );
      },
    );
  }

  for (final (field, error) in [
    ('street', 'Enter a street address.'),
    ('town', 'Enter a town or city.'),
    ('postcode', 'Enter a postcode.'),
  ]) {
    testWidgets('checkout keeps an empty $field focused until corrected', (
      tester,
    ) async {
      await _open(tester, 'checkout');
      final label = field[0].toUpperCase() + field.substring(1);
      final address = find.descendant(
        of: find.byWidgetPredicate(
          (w) => w is NeumorphicTextField && w.label == label,
        ),
        matching: find.byType(EditableText),
      );
      await tester.ensureVisible(address);
      await tester.enterText(address, '   ');
      await tapLive(tester, _key('hearth-pay'));
      expect(find.byType(NeumorphicDialog), findsNothing);
      expect(find.text(error), findsOneWidget);
      expect(tester.widget<EditableText>(address).focusNode.hasFocus, isTrue);
      await tester.enterText(address, '12 West');
      await settle(tester);
      expect(find.text(error), findsNothing);
      await tapLive(tester, _key('hearth-pay'));
      expect(find.text('Order placed'), findsOneWidget);
    });
  }

  testWidgets(
    'both sizes keep the thermostat value in the dial above the navigation',
    (tester) async {
      for (final scale in [1.0, 2.0]) {
        await _open(tester, 'home', scale: scale);
        final dial = find.byType(NeumorphicDial);
        final face = find.descendant(
          of: dial,
          matching: find.byWidgetPredicate(
            (w) =>
                w is CustomPaint &&
                w.painter?.runtimeType.toString() == '_DialPainter',
          ),
        );
        final figure = find.descendant(of: dial, matching: find.text('21.5°'));
        final rect = tester.getRect(figure);
        expect(
          tester.getRect(face).contains(rect.center),
          isTrue,
          reason: 'scale $scale',
        );
        expect(
          rect.bottom,
          lessThan(tester.getTopLeft(find.byType(NeumorphicNavigationBar)).dy),
        );
      }
    },
  );

  testWidgets(
    'phone destinations retain full text size and fit both reading directions',
    (tester) async {
      for (final rtl in [false, true]) {
        await _open(tester, 'home', scale: 2, rtl: rtl);
        for (final page in ['home', 'list', 'checkout', 'form', 'settings']) {
          final button = _key('hearth-nav-$page');
          final text = find
              .descendant(of: button, matching: find.byType(Text))
              .last;
          final paragraph = tester.renderObject<RenderParagraph>(text);
          final fontSize = paragraph.text.style!.fontSize!;
          expect(
            paragraph.textScaler.scale(fontSize),
            closeTo(2 * fontSize, .01),
            reason: page,
          );
          final painted = MatrixUtils.transformRect(
            paragraph.getTransformTo(null),
            Offset.zero & paragraph.size,
          );
          expect(painted.width, closeTo(paragraph.size.width, .01));
          expect(
            tester.getRect(button).inflate(.1).contains(painted.center),
            isTrue,
          );
          expect(painted.left, greaterThanOrEqualTo(0));
          expect(painted.right, lessThanOrEqualTo(390));
        }
        await tapLive(tester, _key('hearth-nav-settings'));
        expect(_key('hearth-settings'), findsOneWidget);
      }
    },
  );

  testWidgets(
    'choosing a date keeps the same today in the sheet and inline calendar',
    (tester) async {
      await _open(tester, 'pickers', scale: 2);
      final picker = find.byType(NeumorphicDatePicker);
      final today = tester.widget<NeumorphicDatePicker>(picker.first).today;
      expect(today, DateTime(2026, 11, 12));
      await tapLive(tester, _key('live-date'));
      final sheet = find.descendant(
        of: find.byType(NeumorphicBottomSheet),
        matching: picker,
      );
      expect(tester.widget<NeumorphicDatePicker>(sheet).today, today);
      await tapLive(
        tester,
        find.descendant(of: sheet, matching: find.text('15')),
      );
      await tapLive(tester, find.text('Choose'));
      expect(
        tester.widget<NeumorphicDatePicker>(picker.first).value,
        DateTime(2026, 11, 15),
      );
      expect(tester.widget<NeumorphicDatePicker>(picker.first).today, today);
    },
  );

  testWidgets(
    'the RTL renewal notice keeps the Arabic date and punctuation together',
    (tester) async {
      await _open(tester, 'feedback', rtl: true);
      expect(find.text('يتجدد اشتراكك في ١\u00a0ديسمبر.'), findsOneWidget);
    },
  );
}
