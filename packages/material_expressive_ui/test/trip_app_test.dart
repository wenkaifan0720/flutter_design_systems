// The trip planner, the example's own app: what each screen does through its
// own navigation, and how each one holds at a phone's, a tablet's and a
// desktop's width in light and dark (no overflow, no page scrolling across,
// no words under 11 px, no card in a card, the content across the body or
// at its stated measure, the phone's primary across the column or in a
// bottom bar).
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

// ignore_for_file: avoid_relative_lib_imports
import '../example/lib/main.dart';
import '../example/lib/kit_gallery/kit.dart';
import '../example/lib/kit_gallery/trip.dart';
import 'gallery_support.dart';

Future<void> _open(
  WidgetTester tester,
  String screen, {
  double width = 390,
  double height = 900,
  Brightness brightness = Brightness.light,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, height);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    GalleryApp(
      key: ValueKey('$screen/$width/${brightness.name}'),
      initialPage: screen,
      initialBrightness: brightness,
    ),
  );
  await settle(tester);
  expect(tester.takeException(), isNull);
}

Finder _key(String key) => find.byKey(ValueKey(key));

Future<void> _tap(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await settle(tester);
  await tester.tap(target);
  await settle(tester);
  expect(tester.takeException(), isNull);
}

String _text(WidgetTester tester, Finder f) => tester.widget<Text>(f).data!;

/// The app bar's menu button, which holds the way back to the gallery.
final Finder _menu = find.byWidgetPredicate(
  (w) =>
      w is ExpressiveIconButton &&
      (w.semanticLabel == 'Show menu' || w.semanticLabel == 'More options'),
);

/// The screens' stated measures (DECISIONS.md): a form beside its summary,
/// the basket beside its total, and the settings' column.
const _measures = {
  TripScreens.plan: 960.0,
  TripScreens.kit: 1120.0,
  TripScreens.preferences: 720.0,
};

void main() {
  setUpAll(loadExpressiveFonts);
  tearDown(() {
    kitShownTheme = null;
    kitShownPreset = 'baseline';
  });

  testWidgets('Home leads with the days to go; packing an item moves its '
      'progress', (tester) async {
    await _open(tester, TripScreens.home);
    expect(
      find.descendant(of: _key('trip-days'), matching: find.text('31')),
      findsOneWidget,
    );
    expect(find.text('8 of 12 packed'), findsOneWidget);
    expect(find.byType(ExpressiveFabMenu), findsOneWidget);
    await _tap(tester, _key('trip-todo-packing'));
    // The packing list, pushed over Shared with you: the bar yields.
    expect(_key('shared-detail-packing'), findsOneWidget);
    await _tap(tester, _key('packing-Headlamps'));
    await _tap(
      tester,
      find.byWidgetPredicate(
        (w) =>
            w is ExpressiveIconButton &&
            w.semanticLabel == 'Back to Shared with you',
      ),
    );
    expect(find.text('9 of 12 packed'), findsOneWidget);
    await _tap(tester, _key('trip-tab-home'));
    expect(find.text('9 of 12 packed'), findsOneWidget);
  });

  testWidgets('the navigation adapts: the bar on a phone, the rail on a '
      'tablet, the expanded rail on a desktop', (tester) async {
    for (final (width, bar, expanded) in <(double, bool, bool)>[
      (390, true, false),
      (768, false, false),
      (1440, false, true),
    ]) {
      await _open(tester, TripScreens.home, width: width);
      expect(
        find.byType(ExpressiveNavigationBar),
        bar ? findsOneWidget : findsNothing,
        reason: '$width',
      );
      if (!bar) {
        expect(
          tester
              .widget<ExpressiveNavigationRail>(
                find.byType(ExpressiveNavigationRail),
              )
              .expanded,
          expanded,
          reason: '$width',
        );
        // "Add to this trip" stands in the rail's header, not as a menu.
        expect(find.byType(ExpressiveFabMenu), findsNothing);
      }
    }
  });

  testWidgets('Edit trip: the dates sit side by side and open the calendar; '
      'Save returns Home with the change', (tester) async {
    await _open(tester, TripScreens.plan);
    final leave = tester.getRect(_key('plan-leave'));
    final back = tester.getRect(_key('plan-back'));
    expect(leave.top, back.top);
    expect(leave.right, lessThan(back.left));
    // On a phone the one primary spans the column.
    final form = tester.getRect(_key('plan-form'));
    expect(tester.getRect(_key('plan-save')).width, closeTo(form.width, 1));
    await _tap(tester, _key('plan-back'));
    expect(find.text('December 2026'), findsOneWidget);
    await _tap(tester, find.text('14').last);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await settle(tester);
    expect(find.text('Mon 14 Dec'), findsOneWidget);
    await tester.enterText(
      find.descendant(
        of: _key('plan-name'),
        matching: find.byType(EditableText),
      ),
      'Big Sur long weekend',
    );
    await _tap(tester, _key('plan-save'));
    expect(find.text('Big Sur long weekend'), findsOneWidget);
    expect(
      find.text('Fri 11 – Mon 14 Dec · Maya, Sam and you'),
      findsOneWidget,
    );
    expect(find.text('Trip saved'), findsOneWidget);
  });

  testWidgets('Edit trip on a desktop keeps a summary beside the form', (
    tester,
  ) async {
    await _open(tester, TripScreens.plan, width: 1440);
    final form = tester.getRect(_key('plan-form'));
    final summary = tester.getRect(_key('plan-summary'));
    expect(summary.left, greaterThan(form.right));
    expect(summary.top, form.top);
    // From 600dp the primary stands at the form's end edge, its own width.
    final save = tester.getRect(_key('plan-save'));
    expect(save.right, closeTo(form.right, 1));
    expect(save.width, lessThan(form.width / 2));
  });

  testWidgets('Shared with you: headed groups, the search bar finds an item, '
      'a row opens its detail', (tester) async {
    await _open(tester, TripScreens.shared);
    for (final group in ['Bookings', 'Lists', 'Guides']) {
      expect(_key('shared-group-$group'), findsOneWidget);
    }
    await _tap(tester, find.byType(ExpressiveSearchBar));
    await tester.enterText(find.byType(EditableText).last, 'pack');
    await settle(tester);
    await _tap(tester, find.text('Packing list').last);
    expect(_key('shared-detail-packing'), findsOneWidget);
    expect(find.text('Tent'), findsOneWidget);
  });

  testWidgets('Shared with you on a desktop: the list beside its detail', (
    tester,
  ) async {
    await _open(tester, TripScreens.shared, width: 1440);
    expect(find.byType(ExpressiveResizable), findsOneWidget);
    expect(_key('shared-detail-car'), findsOneWidget);
    final list = tester.getRect(_key('shared-car'));
    await _tap(tester, _key('shared-eat'));
    final detail = tester.getRect(_key('shared-detail-eat'));
    expect(detail.left, greaterThan(list.right));
    expect(find.text('Nepenthe, for the view'), findsOneWidget);
  });

  testWidgets('Kit totals its basket, delivery and promo code, and the order '
      'lands on Home', (tester) async {
    await _open(tester, TripScreens.kit);
    // On a phone the total and the order stand in the bar over the
    // navigation.
    expect(_key('checkout-bar'), findsOneWidget);
    expect(_key('checkout-summary'), findsNothing);
    String total() => _text(tester, _key('checkout-total'));
    expect(total(), r'$82.00');
    await _tap(tester, _key('checkout-express'));
    expect(total(), r'$91.00');
    await tester.enterText(
      find.descendant(
        of: _key('checkout-promo'),
        matching: find.byType(EditableText),
      ),
      'trail10',
    );
    await _tap(tester, _key('checkout-apply'));
    expect(total(), r'$82.80');
    // The field and its button: their tops on one line.
    expect(
      tester.getRect(_key('checkout-apply')).top,
      closeTo(tester.getRect(_key('checkout-promo')).top, 1),
    );
    await _tap(tester, _key('checkout-change-card'));
    expect(
      tester.getRect(_key('card-expiry')).top,
      tester.getRect(_key('card-code')).top,
    );
    await tester.enterText(
      find.descendant(
        of: _key('card-number'),
        matching: find.byType(EditableText),
      ),
      '4111 1111 1111 1111',
    );
    await _tap(tester, find.text('Use card'));
    expect(find.text('Visa ending 1111'), findsOneWidget);
    await _tap(tester, _key('checkout-place'));
    expect(find.text('Order placed'), findsOneWidget);
    await _tap(tester, find.text('Done'));
    await _tap(tester, _key('trip-tab-home'));
    expect(find.text('Hike kit ordered'), findsOneWidget);
  });

  testWidgets('Kit on a desktop: the summary beside the basket, the order '
      'in it', (tester) async {
    await _open(tester, TripScreens.kit, width: 1440);
    expect(_key('checkout-bar'), findsNothing);
    final summary = tester.getRect(_key('checkout-summary'));
    expect(
      summary.left,
      greaterThan(tester.getRect(_key('checkout-map')).right),
    );
    expect(_text(tester, _key('checkout-total')), r'$82.00');
    final place = tester.getRect(_key('checkout-place'));
    expect(summary.contains(place.center), isTrue);
  });

  testWidgets('Preferences: three headed groups; the digest, its frequency, '
      'the detail and a reset that asks first', (tester) async {
    await _open(tester, TripScreens.preferences);
    for (final group in ['Notifications', 'Display', 'Sound']) {
      expect(find.text(group), findsOneWidget);
    }
    expect(find.text('Send the digest'), findsOneWidget);
    // On the rows' surfaceContainer the filled group's unchosen segment
    // would be the row's own colour: the choices are tonal.
    for (final key in ['prefs-frequency', 'prefs-density']) {
      expect(
        tester.widget<ExpressiveSegmentedButton<String>>(_key(key)).kind,
        ExpressiveToggleButtonKind.tonal,
      );
    }
    await _tap(tester, _key('prefs-digest'));
    expect(find.text('Send the digest'), findsNothing);
    await _tap(tester, _key('prefs-digest'));
    await _tap(tester, find.text('Daily'));
    expect(
      tester
          .widget<ExpressiveSegmentedButton<String>>(_key('prefs-frequency'))
          .value,
      'daily',
    );
    expect(find.text('The day before you travel.'), findsOneWidget);
    await _tap(tester, find.text('Compact'));
    expect(find.text('The day before you travel.'), findsNothing);
    await _tap(tester, _key('prefs-reset'));
    expect(find.text('Reset preferences?'), findsOneWidget);
    await _tap(tester, find.text('Reset'));
    expect(
      tester
          .widget<ExpressiveSegmentedButton<String>>(_key('prefs-frequency'))
          .value,
      'weekly',
    );
    expect(find.text('The day before you travel.'), findsOneWidget);
  });

  testWidgets('the gallery opens the trip planner, whose menu turns it dark '
      'and leads back', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 900);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const GalleryApp());
    await settle(tester);
    await _tap(tester, _key('overview/trip'));
    expect(find.text('Big Sur weekend'), findsOneWidget);
    await _tap(tester, _menu.first);
    await _tap(tester, find.text('Dark theme'));
    expect(
      tester.element(find.text('Big Sur weekend')).expressiveTheme.brightness,
      Brightness.dark,
    );
    await _tap(tester, _menu.first);
    await _tap(tester, find.text('Back to the gallery'));
    expect(find.text('Material 3 Expressive'), findsOneWidget);
  });

  // wide5: every screen, designed at each width, in light and dark.
  for (final screen in TripScreens.all) {
    for (final width in [390.0, 768.0, 1440.0]) {
      for (final mode in Brightness.values) {
        testWidgets('$screen ${width.round()} ${mode.name} holds its layout', (
          tester,
        ) async {
          await _open(tester, screen, width: width, brightness: mode);
          final failures = <String>[];
          // No page scrolls across.
          for (final s in tester.stateList<ScrollableState>(
            find.byType(Scrollable),
          )) {
            if (s.position.axis == Axis.horizontal &&
                s.position.maxScrollExtent > 0) {
              failures.add('a page scrolls across: ${s.widget.key}');
            }
          }
          // No words under 11 px.
          for (final e in find.byType(RichText).evaluate()) {
            final paragraph = e.renderObject! as RenderParagraph;
            void visit(InlineSpan span, double inherited) {
              final size = span.style?.fontSize ?? inherited;
              if (span is TextSpan &&
                  (span.text?.trim().isNotEmpty ?? false) &&
                  size < 11) {
                failures.add('"${span.text}" at $size px');
              }
              if (span is TextSpan) {
                for (final child in span.children ?? const <InlineSpan>[]) {
                  visit(child, size);
                }
              }
            }

            visit(paragraph.text, 14);
          }
          // No card in a card.
          for (final e in find.byType(ExpressiveCard).evaluate()) {
            final inner = find.byElementPredicate((x) => identical(x, e));
            if (find
                .ancestor(of: inner, matching: find.byType(ExpressiveCard))
                .evaluate()
                .isNotEmpty) {
              failures.add('a card inside a card');
            }
          }
          // The content spans the body, or its stated measure.
          final column = tester.getRect(
            find.byKey(const ValueKey('trip-column')),
          );
          final scaffold = tester.getRect(
            find.byType(ExpressiveScaffold).first,
          );
          final margin = scaffold.width >= 600 ? 24.0 : 16.0;
          final available = scaffold.width - 2 * margin;
          final measure = _measures[screen] ?? available;
          final expected = measure < available ? measure : available;
          if (column.width < expected - 1) {
            failures.add(
              'the column is ${column.width.round()} of ${expected.round()}',
            );
          }
          // At a desktop's width the content reaches the column's end.
          if (width == 1440 && screen != TripScreens.preferences) {
            final reach = find
                .descendant(
                  of: find.byKey(const ValueKey('trip-column')),
                  matching: find.byWidgetPredicate(
                    (w) =>
                        w is ExpressiveListSection ||
                        w is ExpressiveCard ||
                        w is ExpressiveSurface ||
                        w is ExpressiveTextField ||
                        w is ExpressiveSearchBar,
                  ),
                )
                .evaluate()
                .map(
                  (e) => tester
                      .getRect(find.byElementPredicate((x) => identical(x, e)))
                      .right,
                )
                .fold(0.0, (a, b) => a > b ? a : b);
            if (reach < column.right - 1) {
              failures.add(
                'the content ends at ${reach.round()}, '
                'the column at ${column.right.round()}',
              );
            }
          }
          // Every width keeps the screen's primary (at 768 the kit's total
          // and order follow the basket: no bar beside a rail).
          for (final (on, key) in [
            (TripScreens.plan, 'plan-save'),
            (TripScreens.kit, 'checkout-place'),
            (TripScreens.kit, 'checkout-total'),
          ]) {
            if (screen == on &&
                find.byKey(ValueKey(key)).evaluate().length != 1) {
              failures.add(
                '$key: ${find.byKey(ValueKey(key)).evaluate().length}',
              );
            }
          }
          // On a phone the primary spans the column or stands in a bar.
          if (width == 390 && screen == TripScreens.plan) {
            final save = tester.getRect(_key('plan-save'));
            if (save.width < tester.getRect(_key('plan-form')).width - 1) {
              failures.add('Save trip is ${save.width.round()} wide');
            }
          }
          if (width == 390 && screen == TripScreens.kit) {
            expect(
              find.descendant(
                of: _key('checkout-bar'),
                matching: _key('checkout-place'),
              ),
              findsOneWidget,
            );
          }
          expect(failures, isEmpty, reason: failures.join('\n'));
        });
      }
    }
  }

  // The coordinator's read of 11-11 (3be1f47691): each destination centred
  // its own measure, so going through the rail moved the title and the
  // content's edge by up to 227 px at 1440. One frame for every
  // destination: its bar title and its column start on one x.
  for (final width in [768.0, 1440.0]) {
    testWidgets('one page frame at ${width.round()}: every destination '
        "starts its title and its column on one edge", (tester) async {
      final titles = <String, double>{};
      final columns = <String, double>{};
      for (final screen in TripScreens.all) {
        if (screen == TripScreens.plan) continue; // a step, not a destination
        await _open(tester, screen, width: width);
        titles[screen] = tester
            .getRect(
              find
                  .descendant(
                    of: find.byType(ExpressiveAppBar),
                    matching: find.text(TripScreens.title(screen)),
                  )
                  .first,
            )
            .left;
        columns[screen] = tester.getRect(_key('trip-column')).left;
      }
      final title = titles[TripScreens.home]!;
      final column = columns[TripScreens.home]!;
      for (final screen in titles.keys) {
        expect(
          (titles[screen]! - title).abs(),
          lessThanOrEqualTo(0.5),
          reason: '$screen: title at ${titles[screen]}, Home at $title',
        );
        expect(
          (columns[screen]! - column).abs(),
          lessThanOrEqualTo(0.5),
          reason: '$screen: column at ${columns[screen]}, Home at $column',
        );
      }
      expect(
        (title - column).abs(),
        lessThanOrEqualTo(0.5),
        reason: 'the title at $title, the column at $column',
      );
    });
  }

  // The coordinator's read of e8b2ebfea8: Kit's Delivery words stood 8px
  // right of the Basket's and Payment's (a 40dp radio slot beside 32dp
  // tiles). Every row's words in the column start on one x, read from the
  // words, at a phone's width and a desktop's, at both densities.
  for (final width in [390.0, 1440.0]) {
    testWidgets(
      "Kit at ${width.round()}: every row's words start on one x",
      (tester) async {
        await _open(tester, TripScreens.kit, width: width, height: 1400);
        final xs = <String, double>{
          for (final words in [
            'Trail map',
            'Standard',
            'Express',
            'Visa ending',
          ])
            words: tester.getRect(find.textContaining(words).first).left,
        };
        final first = xs.values.first;
        for (final MapEntry(key: words, value: x) in xs.entries) {
          expect(
            (x - first).abs(),
            lessThanOrEqualTo(0.5),
            reason: '"$words" starts at $x; "Trail map" at $first ($xs)',
          );
        }
      },
      variant: TargetPlatformVariant(const {
        TargetPlatform.android,
        TargetPlatform.macOS,
      }),
    );
  }
}
