// The showcase app, Hearth, at a phone, a tablet and a desk, by day and by night (wide5, design6's proof): nothing
// overflows and nothing scrolls sideways; at 1440 the content spans the body; no text is under 11 px; no raised group
// stands inside another; at 390 the act spans the content or stands in the bottom bar; every target meets Flutter's
// tap-target guidelines. Every act leads somewhere, and one quiet way leads back to the gallery.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

// ignore: avoid_relative_lib_imports
import '../example/lib/main.dart';
// ignore: avoid_relative_lib_imports
import '../example/lib/kit_gallery/hearth.dart';
import 'gallery_support.dart' show loadBundledFonts, settle;
import 'support.dart' show loadNeumorphicFonts;

double _height(double width) => width < 600 ? 844 : (width < 1024 ? 1024 : 900);

Future<void> _pump(
  WidgetTester tester,
  String screen,
  double width, {
  bool dark = false,
}) async {
  tester.view.physicalSize = Size(width, _height(width));
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    GalleryApp(
      key: UniqueKey(),
      initialPage: screen,
      initialBrightness: dark ? Brightness.dark : Brightness.light,
    ),
  );
  await settle(tester);
}

Finder _page(String screen) => find.byKey(ValueKey('hearth-$screen'));

/// Whether [button] is a filled button: `NeumorphicButton.filled` draws the act's face.
bool _filled(Element button) {
  var filled = false;
  button.visitChildElements(
    (child) => filled = child.widget.runtimeType.toString() == '_ActButton',
  );
  return filled;
}

Rect _rect(Element element) {
  final box = element.renderObject! as RenderBox;
  return box.localToGlobal(Offset.zero) & box.size;
}

/// What a scroller belongs to, for a failure's reason: the field whose text it scrolls, and the nearest keyed widget.
String _owner(BuildContext context) {
  final names = <String>[];
  context.visitAncestorElements((e) {
    final w = e.widget;
    if (w is EditableText && names.isEmpty) {
      names.add('the field reading "${w.controller.text}"');
    }
    if (w.key is ValueKey) {
      names.add('${w.key}');
      return false;
    }
    return true;
  });
  return names.isEmpty ? 'the page' : names.join(' in ');
}

/// The smallest font size a span tree draws.
double _smallest(InlineSpan span, [double inherited = 14]) {
  final size = span.style?.fontSize ?? inherited;
  var least = span is TextSpan && (span.text?.trim().isEmpty ?? true)
      ? double.infinity
      : size;
  if (span is TextSpan) {
    for (final child in span.children ?? const <InlineSpan>[]) {
      final s = _smallest(child, size);
      if (s < least) least = s;
    }
  }
  return least;
}

void main() {
  setUpAll(() async {
    await loadNeumorphicFonts();
    await loadBundledFonts();
  });

  for (final screen in hearthScreens) {
    for (final width in [390.0, 768.0, 1440.0]) {
      for (final dark in [false, true]) {
        testWidgets(
          '${screen.id} is designed for $width ${dark ? 'by night' : 'by day'}',
          (tester) async {
            await _pump(tester, screen.id, width, dark: dark);
            expect(tester.takeException(), isNull);
            final page = _page(screen.id);
            expect(page, findsOneWidget);
            // Nothing scrolls sideways.
            for (final s in tester.stateList<ScrollableState>(
              find.descendant(of: page, matching: find.byType(Scrollable)),
            )) {
              if (s.position.axis == Axis.horizontal) {
                expect(
                  s.position.maxScrollExtent,
                  0,
                  reason:
                      'sideways scroll in ${_owner(s.context)}, '
                      '${s.position.viewportDimension} wide',
                );
              }
            }
            final texts = tester
                .widgetList<RichText>(
                  find.descendant(of: page, matching: find.byType(RichText)),
                )
                .toList();
            // No text under 11 px.
            for (final text in texts) {
              final least = _smallest(text.text);
              expect(
                least,
                greaterThanOrEqualTo(11),
                reason: '"${text.text.toPlainText()}" is $least px',
              );
            }
            // No raised group inside another.
            expect(
              find.descendant(
                of: find.descendant(
                  of: page,
                  matching: find.byType(NeumorphicSlab),
                ),
                matching: find.byType(NeumorphicSlab),
              ),
              findsNothing,
              reason: 'a card inside a card',
            );
            if (width == 1440) {
              // The content spans the body: its words reach the last quarter of what stands beside the pilaster.
              final rights = [
                for (final e
                    in find
                        .descendant(of: page, matching: find.byType(RichText))
                        .evaluate())
                  if (_rect(e).left >= 272) _rect(e).right,
              ];
              final reach = rights.reduce((a, b) => a > b ? a : b);
              expect(
                reach,
                greaterThanOrEqualTo(272 + (1440 - 272) * .75),
                reason: 'a stranded column: the words end at $reach',
              );
            }
            if (width == 390) {
              // The act (a filled button) spans the content or stands in the bottom bar; a line or text button keeps
              // its own width.
              for (final act
                  in find
                      .descendant(
                        of: page,
                        matching: find.byType(NeumorphicButton),
                      )
                      .evaluate()) {
                if (!_filled(act)) continue;
                final rect = _rect(act);
                // In the bar: pinned under the content, outside anything that scrolls.
                final inBar =
                    rect.top > _height(width) / 2 &&
                    act.findAncestorWidgetOfExactType<Scrollable>() == null;
                final spans = rect.width >= 390 - 40 - 1;
                expect(
                  inBar || spans,
                  isTrue,
                  reason: 'an act ${rect.width} wide in the content',
                );
              }
            }
          },
        );
      }
    }
    testWidgets('${screen.id} meets the tap-target guidelines', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, screen.id, 390);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });
  }

  testWidgets('the app moves between its screens with its own navigation', (
    tester,
  ) async {
    for (final (width, nav) in [
      (390.0, 'hearth-bar'),
      (768.0, 'hearth-rail'),
      (1440.0, null),
    ]) {
      await _pump(tester, 'home', width);
      if (nav != null) expect(find.byKey(Key(nav)), findsOneWidget);
      for (final screen in hearthScreens.reversed) {
        final item = nav == null
            ? find.byKey(Key('hearth-nav-${screen.id}'))
            : find.descendant(
                of: find.byKey(Key(nav)),
                matching: find.text(screen.title),
              );
        await tester.tap(item.first);
        await settle(tester);
        expect(_page(screen.id), findsOneWidget, reason: '${screen.id} $width');
      }
    }
  });

  testWidgets('the checkout pays and says when it arrives', (tester) async {
    await _pump(tester, 'checkout', 390);
    expect(find.text('£40.00'), findsWidgets);
    await tester.tap(
      find
          .descendant(
            of: find.byKey(const Key('hearth-bulbs')),
            matching: find.byIcon(NeumorphicGlyphs.plus),
          )
          .first,
    );
    await settle(tester);
    expect(find.text('£44.00'), findsWidgets);
    await tester.tap(find.byKey(const Key('hearth-pay')));
    await settle(tester);
    expect(find.text('Order placed'), findsOneWidget);
    expect(find.textContaining('3 bulbs'), findsOneWidget);
    await tester.tap(find.byKey(const Key('hearth-paid')));
    await settle(tester);
    expect(find.text('Order placed'), findsNothing);
  });

  testWidgets('a device opens beside the list on a desk, on its own page on a '
      'phone, and a new one joins', (tester) async {
    await _pump(tester, 'list', 1440);
    await tester.tap(find.byKey(const Key('hearth-device-pendants')));
    await settle(tester);
    expect(find.byKey(const Key('hearth-detail-pendants')), findsOneWidget);
    expect(find.byKey(const Key('hearth-search')), findsOneWidget);

    await _pump(tester, 'list', 390);
    await tester.tap(find.byKey(const Key('hearth-device-pendants')));
    await settle(tester);
    expect(find.byKey(const Key('hearth-detail-pendants')), findsOneWidget);
    expect(find.byKey(const Key('hearth-search')), findsNothing);
    await tester.tap(find.byType(NeumorphicBackButton));
    await settle(tester);
    expect(find.byKey(const Key('hearth-search')), findsOneWidget);

    await tester.tap(find.byKey(const Key('hearth-add')));
    await settle(tester);
    await tester.enterText(
      find.descendant(
        of: find.byKey(const Key('hearth-add-name')),
        matching: find.byType(EditableText),
      ),
      'Porch light',
    );
    await tester.tap(find.byKey(const Key('hearth-add-confirm')));
    await settle(tester);
    expect(find.text('Porch light'), findsWidgets);
  });

  testWidgets('a lamp turned off on Home is off on Devices', (tester) async {
    await _pump(tester, 'home', 390);
    await tester.tap(
      find
          .descendant(
            of: find.byKey(const Key('hearth-light-floor-lamp')),
            matching: find.byWidgetPredicate(
              (w) => w is Semantics && w.properties.toggled != null,
            ),
          )
          .first,
    );
    await settle(tester);
    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('hearth-bar')),
        matching: find.text('Devices'),
      ),
    );
    await settle(tester);
    expect(
      find.descendant(
        of: find.byKey(const Key('hearth-device-floor-lamp')),
        matching: find.text('Off'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('one quiet way leads back to the gallery, carrying day and '
      'night and Customize', (tester) async {
    await _pump(tester, 'home', 390);
    await tester.tap(find.byKey(const Key('hearth-gallery')));
    await settle(tester);
    await tester.tap(find.text('Night'));
    await settle(tester);
    expect(
      NeumorphicTheme.of(tester.element(_page('home'))).colors.dark,
      isTrue,
    );
    await tester.tap(find.byKey(const Key('hearth-gallery')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('hearth-customize')));
    await settle(tester);
    expect(find.text('Customize'), findsWidgets);
    await tester.tap(find.byKey(const Key('hearth-gallery')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('hearth-back-to-gallery')));
    await settle(tester);
    expect(find.byKey(const Key('overview-dial')), findsOneWidget);

    await _pump(tester, 'settings', 1440);
    await tester.tap(find.byKey(const Key('hearth-back-to-gallery')));
    await settle(tester);
    expect(find.byKey(const Key('overview-dial')), findsOneWidget);
  });
}
