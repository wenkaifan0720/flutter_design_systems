// Alignment, measured: text baselines and icon centres in rows, fields, button groups, the tab bar, the nav bar and the
// app bar; equal heights in action rows; labels in a set on one centre line. On a phone and a desktop, in light and
// with the square corner family (the families must not move a label).
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

import 'support.dart';

void _hit() {}

/// Where [text]'s alphabetic baseline sits on screen, read from its laid-out paragraph's text.
double _baseline(WidgetTester tester, Finder text) {
  final box = tester.renderObject<RenderParagraph>(text);
  final painter = TextPainter(
    text: box.text,
    textDirection: box.textDirection,
    textScaler: box.textScaler,
    maxLines: box.maxLines,
    textHeightBehavior: box.textHeightBehavior,
    strutStyle: box.strutStyle,
  )..layout(maxWidth: box.size.width + 1);
  final baseline = painter.computeDistanceToActualBaseline(
    TextBaseline.alphabetic,
  );
  painter.dispose();
  return box.localToGlobal(Offset.zero).dy + baseline;
}

/// The smallest moulded face inside [of]: a row's mark or control.
Rect _mark(WidgetTester tester, Finder of) {
  final faces =
      find
          .descendant(of: of, matching: find.byType(NeumorphicSurface))
          .evaluate()
          .map((e) {
            final box = e.renderObject! as RenderBox;
            return box.localToGlobal(Offset.zero) & box.size;
          })
          .toList()
        ..sort((a, b) => (a.width * a.height).compareTo(b.width * b.height));
  return faces.first;
}

/// The centre line of a glyph: the painted icon's box, not its target.
double _iconCentre(WidgetTester tester, IconData icon) =>
    tester.getRect(find.byIcon(icon).first).center.dy;

double _centre(WidgetTester tester, Finder f) => tester.getRect(f).center.dy;

void _same(Iterable<double> values, String what, {double tolerance = .5}) {
  final list = values.toList();
  for (final v in list) {
    expect(
      (v - list.first).abs(),
      lessThanOrEqualTo(tolerance),
      reason: '$what: $list',
    );
  }
}

void main() {
  setUpAll(loadNeumorphicFonts);

  for (final width in [390.0, 1024.0]) {
    {
      final at = '@$width';

      Future<void> pump(WidgetTester tester, Widget child) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final base = NeumorphicThemeData.porcelain();
        await tester.pumpWidget(
          MaterialApp(
            home: NeumorphicTheme(
              data: base.atWidth(width),
              child: MediaQuery(
                data: MediaQueryData(
                  size: Size(width, 900),
                  disableAnimations: true,
                ),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      testWidgets('an action row: equal heights, one baseline $at', (
        tester,
      ) async {
        await pump(
          tester,
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              NeumorphicButton.filled('Save', onPressed: _hit),
              NeumorphicButton('Share', onPressed: _hit),
              NeumorphicButton('Cancel', onPressed: _hit),
              NeumorphicButton.text('Later', onPressed: _hit),
              NeumorphicButton(
                'Delete',
                isDestructiveAction: true,
                onPressed: _hit,
              ),
            ],
          ),
        );
        final labels = ['Save', 'Share', 'Cancel', 'Later', 'Delete'];
        // Buttons on one run of the row share a baseline and a centre line.
        final runs = <int, List<String>>{};
        for (final l in labels) {
          final tap = find
              .ancestor(of: find.text(l), matching: find.byType(NeumorphicTap))
              .first;
          runs.putIfAbsent(tester.getRect(tap).top.round(), () => []).add(l);
        }
        for (final run in runs.values) {
          _same([
            for (final l in run) _baseline(tester, find.text(l)),
          ], 'button baselines $run');
          _same([
            for (final l in run) _centre(tester, find.text(l)),
          ], 'button label centres $run');
        }
        _same(
          [
            for (final l in labels)
              tester
                  .getRect(
                    find
                        .ancestor(
                          of: find.text(l),
                          matching: find.byType(NeumorphicTap),
                        )
                        .first,
                  )
                  .height,
          ],
          'button heights',
          tolerance: 0,
        );
      });

      testWidgets('a button\'s icon sits on its label\'s centre line $at', (
        tester,
      ) async {
        await pump(
          tester,
          NeumorphicButton('Add', icon: NeumorphicGlyphs.plus, onPressed: _hit),
        );
        expect(
          (_iconCentre(tester, NeumorphicGlyphs.plus) -
                  _centre(tester, find.text('Add')))
              .abs(),
          lessThanOrEqualTo(1),
        );
      });

      testWidgets('a dialog\'s actions share heights and a baseline $at', (
        tester,
      ) async {
        await pump(
          tester,
          SizedBox(
            width: 360,
            child: NeumorphicDialog(
              title: 'Save changes?',
              message: 'Choose an action',
              actions: [
                NeumorphicButton.text('Cancel', onPressed: _hit),
                NeumorphicButton.filled('Save', onPressed: _hit),
              ],
            ),
          ),
        );
        final cancel = find.text('Cancel'), save = find.text('Save');
        // Stacked actions on a narrow dialog are allowed; side by side, they share a line.
        if ((_centre(tester, cancel) - _centre(tester, save)).abs() < 20) {
          _same([
            _baseline(tester, cancel),
            _baseline(tester, save),
          ], 'dialog action baselines');
        }
        _same(
          [
            for (final f in [cancel, save])
              tester
                  .getRect(
                    find
                        .ancestor(of: f, matching: find.byType(NeumorphicTap))
                        .first,
                  )
                  .height,
          ],
          'dialog action heights',
          tolerance: 0,
        );
      });

      testWidgets('rows: the mark and the control on the label\'s centre $at', (
        tester,
      ) async {
        await pump(
          tester,
          SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                NeumorphicListTile(
                  title: 'Profile',
                  leading: const Icon(NeumorphicGlyphs.user),
                  trailing: const Icon(NeumorphicGlyphs.chevronRight),
                  onPressed: _hit,
                ),
                NeumorphicSwitchRow(
                  label: 'Alerts',
                  value: true,
                  onChanged: (_) {},
                ),
                NeumorphicCheckRow(
                  label: 'Agree',
                  value: false,
                  onChanged: (_) {},
                ),
              ],
            ),
          ),
        );
        final title = _centre(tester, find.text('Profile'));
        _same(
          [
            title,
            _iconCentre(tester, NeumorphicGlyphs.user),
            _iconCentre(tester, NeumorphicGlyphs.chevronRight),
          ],
          'list row',
          tolerance: 1,
        );
        _same(
          [
            _centre(tester, find.text('Alerts')),
            _centre(tester, find.byType(NeumorphicSwitch)),
          ],
          'switch row',
          tolerance: 1,
        );
        _same(
          [
            _centre(tester, find.text('Agree')),
            _mark(tester, find.byType(NeumorphicCheckRow)).center.dy,
          ],
          'check row',
          tolerance: 1,
        );
      });

      testWidgets('a radio group: each dot on its label\'s centre $at', (
        tester,
      ) async {
        await pump(
          tester,
          SizedBox(
            width: 360,
            child: NeumorphicRadioGroup<int>(
              label: 'Delivery',
              value: 0,
              options: const [
                NeumorphicRadio(0, 'Standard'),
                NeumorphicRadio(1, 'Express'),
              ],
              onChanged: (_) {},
            ),
          ),
        );
        for (final label in ['Standard', 'Express']) {
          final text = tester.getRect(find.text(label));
          final row = find
              .ancestor(of: find.text(label), matching: find.byType(Row))
              .first;
          final marks = find.descendant(
            of: row,
            matching: find.byType(NeumorphicSurface),
          );
          expect(marks, findsWidgets, reason: label);
          expect(
            (tester.getRect(marks.first).center.dy - text.center.dy).abs(),
            lessThanOrEqualTo(1),
            reason: label,
          );
        }
      });

      testWidgets('fields: the entry, its icons and the hint on one line $at', (
        tester,
      ) async {
        await pump(
          tester,
          const SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                NeumorphicSearchField(hint: 'Search rooms'),
                SizedBox(height: 16),
                NeumorphicTextField(
                  label: 'Email',
                  initialValue: 'ana@example.com',
                  leading: Icon(NeumorphicGlyphs.mail),
                ),
              ],
            ),
          ),
        );
        _same(
          [
            _centre(tester, find.text('Search rooms')),
            _iconCentre(tester, NeumorphicGlyphs.search),
          ],
          'search field',
          tolerance: 1,
        );
        final entry = find
            .descendant(
              // The search field is a text field too; the email field is the last.
              of: find.byType(NeumorphicTextField).last,
              matching: find.byType(EditableText),
            )
            .first;
        _same(
          [_centre(tester, entry), _iconCentre(tester, NeumorphicGlyphs.mail)],
          'text field',
          tolerance: 1,
        );
      });

      testWidgets('tabs and segments: labels on one centre line $at', (
        tester,
      ) async {
        await pump(
          tester,
          SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                NeumorphicTabBar(
                  tabs: const ['Overview', 'Activity', 'Details'],
                  onChanged: (_) {},
                ),
                const SizedBox(height: 16),
                NeumorphicSegmentedButton<int>(
                  label: 'Period',
                  value: 1,
                  segments: const [
                    NeumorphicButtonSegment(0, 'Day'),
                    NeumorphicButtonSegment(1, 'Week'),
                    NeumorphicButtonSegment(2, 'Month'),
                  ],
                  onChanged: (_) {},
                ),
              ],
            ),
          ),
        );
        _same([
          for (final l in ['Overview', 'Activity', 'Details'])
            _baseline(tester, find.text(l)),
        ], 'tab baselines');
        _same([
          for (final l in ['Day', 'Week', 'Month'])
            _baseline(tester, find.text(l)),
        ], 'segment baselines');
      });

      testWidgets('the nav bar: icons on one line, labels on one line $at', (
        tester,
      ) async {
        await pump(
          tester,
          SizedBox(
            width: 360,
            child: NeumorphicNavigationBar(
              selectedIndex: 1,
              onDestinationSelected: (_) {},
              items: const [
                NeumorphicNavItem(label: 'Home', icon: NeumorphicGlyphs.house),
                NeumorphicNavItem(
                  label: 'Rooms',
                  icon: NeumorphicGlyphs.layers,
                ),
                NeumorphicNavItem(label: 'You', icon: NeumorphicGlyphs.user),
              ],
            ),
          ),
        );
        _same([
          for (final i in [
            NeumorphicGlyphs.house,
            NeumorphicGlyphs.layers,
            NeumorphicGlyphs.user,
          ])
            _iconCentre(tester, i),
        ], 'nav icons');
        final labels = [
          for (final l in ['Home', 'Rooms', 'You'])
            if (find.text(l).evaluate().isNotEmpty) l,
        ];
        if (labels.length > 1) {
          _same([
            for (final l in labels) _baseline(tester, find.text(l)),
          ], 'nav labels');
        }
      });

      testWidgets('the app bar: back, title and actions on one line $at', (
        tester,
      ) async {
        await pump(
          tester,
          SizedBox(
            width: width - 40,
            height: 120,
            child: NeumorphicAppBar(
              title: 'Kitchen',
              leading: NeumorphicIconButton(
                NeumorphicGlyphs.back,
                label: 'Back',
                onPressed: _hit,
              ),
              actions: [
                NeumorphicIconButton(
                  NeumorphicGlyphs.settings,
                  label: 'Settings',
                  onPressed: _hit,
                ),
              ],
            ),
          ),
        );
        _same(
          [
            _centre(tester, find.text('Kitchen')),
            _iconCentre(tester, NeumorphicGlyphs.back),
            _iconCentre(tester, NeumorphicGlyphs.settings),
          ],
          'app bar',
          tolerance: 1,
        );
      });

      testWidgets('pagination and breadcrumbs: one centre line $at', (
        tester,
      ) async {
        await pump(
          tester,
          SizedBox(
            width: width - 40,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                NeumorphicPagination(count: 12, page: 5, onChanged: (_) {}),
                const SizedBox(height: 16),
                NeumorphicBreadcrumb(
                  crumbs: [
                    NeumorphicCrumb('Home', onPressed: _hit),
                    NeumorphicCrumb('Rooms', onPressed: _hit),
                    const NeumorphicCrumb('Kitchen'),
                  ],
                ),
              ],
            ),
          ),
        );
        final pager = find.byType(NeumorphicPagination);
        final centres = [
          _iconCentre(tester, NeumorphicGlyphs.chevronLeft),
          for (final e
              in find
                  .descendant(of: pager, matching: find.byType(Text))
                  .evaluate())
            tester.getRect(find.byWidget(e.widget)).center.dy,
        ];
        _same(centres, 'pagination', tolerance: 1);
        _same([
          for (final l in ['Home', 'Rooms', 'Kitchen'])
            _baseline(tester, find.text(l)),
        ], 'breadcrumb baselines');
      });
    }
  }

  // A radio option's price (design6, the checkout's delivery): on the label's baseline, at the row's end; a long label
  // wraps before it moves the price off the edge.
  for (final scale in [1.0, 1.5]) {
    testWidgets('a radio option\'s price shares its label\'s baseline @390 '
        'text $scale', (tester) async {
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      const long =
          'Next day, from the shop on the corner, by a courier on a bike';
      await tester.pumpWidget(
        neumorphicApp(
          Padding(
            padding: const EdgeInsets.all(20),
            child: NeumorphicRadioGroup<int>(
              label: 'Delivery',
              value: 0,
              onChanged: (_) {},
              options: const [
                NeumorphicRadio(
                  0,
                  'Standard',
                  note: 'Thursday',
                  trailingText: 'Free',
                ),
                NeumorphicRadio(
                  1,
                  long,
                  note: 'Tomorrow',
                  trailingText: '£6.00',
                ),
              ],
            ),
          ),
          textScale: scale,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      for (final (label, price) in [('Standard', 'Free'), (long, '£6.00')]) {
        final words = tester.getRect(find.text(label));
        final figure = tester.getRect(find.text(price));
        // The price's baseline is the label's first line's.
        expect(
          (_baseline(tester, find.text(price)) -
                  _baseline(tester, find.text(label)))
              .abs(),
          lessThan(.5),
          reason: '$price on $label\'s baseline',
        );
        expect(figure.right, lessThanOrEqualTo(390 - 20 + .5), reason: price);
        expect(figure.left, greaterThan(words.right), reason: price);
      }
      // The long label took more than one line rather than push its price.
      expect(
        tester.getRect(find.text(long)).height,
        greaterThan(tester.getRect(find.text('Standard')).height * 1.5),
      );
    });
  }
}
