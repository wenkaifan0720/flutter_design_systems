// F17: an app's own corners on a part of Clay. Clay takes one step on every
// corner, never square: an override whose corners differ (two diagonal
// cuts, one corner alone) is ignored, a square step goes to the extra-small,
// a style's shape wins over its corners, a group's rows keep concentric with
// the corners it is given, and a part whose corners change with its state
// moves there over frames.
import 'package:clay_ui/clay_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

const _part = Key('part');

ClayStyle _corners(RawCorners corners) =>
    ClayStyle(corners: WidgetStatePropertyAll(corners));

class _Habit {
  const _Habit(this.name);
  final String name;
}

// Each shaped part: its own step's radius in Clay's own scheme, how to build
// it with a style, and (for one on an overlay) the words inside its panel and
// how to open it.
typedef _Shaped = ({
  String name,
  double own,
  Widget Function(ClayStyle? style) build,
  String? inside,
  String? open,
});

final List<_Shaped> _parts = [
  (
    name: 'text field',
    own: 16,
    build: (s) => ClayTextField(labelText: 'Habit', style: s),
    inside: null,
    open: null,
  ),
  (
    name: 'select',
    own: 16,
    build: (s) => ClaySelect<String>(
      value: 'daily',
      items: const [ClaySelectItem(value: 'daily', label: 'Every day')],
      onChanged: (_) {},
      style: s,
    ),
    inside: null,
    open: null,
  ),
  (
    name: 'button group',
    own: 16,
    build: (s) => ClayButtonGroup(
      items: [
        ClayButtonGroupItem(label: 'Skip', onPressed: () {}),
        ClayButtonGroupItem(label: 'Snooze', onPressed: () {}),
      ],
      style: s,
    ),
    inside: null,
    open: null,
  ),
  (
    name: 'split button',
    own: 16,
    build: (s) => ClaySplitButton(
      label: 'Log it',
      onPressed: () {},
      actions: [ClaySplitAction(label: 'Log twice', onPressed: () {})],
      style: s,
    ),
    inside: null,
    open: null,
  ),
  (
    name: 'group',
    own: 24,
    build: (s) => ClayGroup(
      style: s,
      children: const [ClayListTile(title: 'Drink water')],
    ),
    inside: null,
    open: null,
  ),
  (
    name: 'card',
    own: 24,
    build: (s) => ClayCard(style: s, child: const Text('Twelve days')),
    inside: null,
    open: null,
  ),
  (
    name: 'button',
    own: 16,
    build: (s) => ClayButton('Save', onPressed: () {}, style: s),
    inside: null,
    open: null,
  ),
  (
    name: 'coral button',
    own: 16,
    build: (s) => ClayButton.filled('Save', onPressed: () {}, style: s),
    inside: null,
    open: null,
  ),
  (
    name: 'file drop',
    own: 24,
    build: (s) => ClayFileDrop(onChoose: () {}, style: s),
    inside: null,
    open: null,
  ),
  (
    name: 'disclosure',
    own: 24,
    build: (s) => ClayDisclosure(
      title: 'Why it matters',
      style: s,
      child: const Text('A glass before coffee.'),
    ),
    inside: null,
    open: null,
  ),
  (
    name: 'disclosure group',
    own: 24,
    build: (s) => ClayDisclosureGroup(
      style: s,
      children: const [
        ClayDisclosure(title: 'Reminders', child: Text('Each habit.')),
      ],
    ),
    inside: null,
    open: null,
  ),
  (
    name: 'table',
    own: 24,
    build: (s) => ClayTable(
      style: s,
      columns: const [ClayTableColumn('Habit'), ClayTableColumn('Streak')],
      rows: const [
        ['Read', '4'],
      ],
    ),
    inside: null,
    open: null,
  ),
  (
    name: 'media',
    own: 24,
    build: (s) => SizedBox(
      width: 200,
      child: ClayMedia(image: null, semanticLabel: 'Birches', style: s),
    ),
    inside: null,
    open: null,
  ),
  (
    name: 'banner',
    own: 24,
    build: (s) => ClayBanner(title: 'Sync failed', style: s),
    inside: null,
    open: null,
  ),
  (
    name: 'date field',
    own: 16,
    build: (s) => ClayDatePicker(
      value: DateTime(2026, 11, 20),
      firstDate: DateTime(2026),
      lastDate: DateTime(2027, 12, 31),
      onChanged: (_) {},
      style: s,
    ),
    inside: null,
    open: null,
  ),
  (
    name: 'input group',
    own: 16,
    build: (s) =>
        ClayInputGroup(labelText: 'Goal', suffixText: 'glasses', style: s),
    inside: null,
    open: null,
  ),
  (
    name: 'code field',
    own: 14,
    build: (s) => ClayOtpField(semanticLabel: 'Code', style: s),
    inside: null,
    open: null,
  ),
  (
    name: 'number field',
    own: 16,
    build: (s) => ClayNumberField(
      value: 4,
      max: 12,
      semanticLabel: 'Glasses',
      onChanged: (_) {},
      style: s,
    ),
    inside: null,
    open: null,
  ),
  (
    name: 'data table',
    own: 24,
    build: (s) => ClayDataTable<_Habit>(
      controller: ClayTableController<_Habit>(
        rows: const [_Habit('Read')],
        rowKey: (h) => h.name,
        columns: [const ClayDataColumn(id: 'name', label: 'Habit')],
      ),
      cell: (h, column) => h.name,
      style: s,
    ),
    inside: null,
    open: null,
  ),
  (
    name: 'carousel',
    own: 24,
    build: (s) => SizedBox(
      height: 320,
      child: ClayCarousel(
        itemCount: 2,
        itemBuilder: (context, i) => Text('Tip ${i + 1}'),
        style: s,
      ),
    ),
    inside: null,
    open: null,
  ),
  (
    name: 'reorderable list',
    own: 24,
    build: (s) => ClayReorderableList<String>(
      items: const ['Wake', 'Walk'],
      labelOf: (x) => x,
      onReorder: (from, to) {},
      itemBuilder: (context, x) => Text(x),
      style: s,
    ),
    inside: null,
    open: null,
  ),
  (
    name: 'command palette',
    own: 32,
    build: (s) => ClayCommandPalette(
      commands: [ClayCommand(label: 'New habit', onPressed: () {})],
      style: s,
    ),
    inside: 'New habit',
    open: null,
  ),
  (
    name: 'popover',
    own: 24,
    build: (s) => ClayPopover(
      semanticLabel: 'Streak',
      style: s,
      builder: (context, toggle, open) =>
          ClayButton('Streak', onPressed: toggle),
      content: (context, close) => const Text('Twelve days running'),
    ),
    inside: 'Twelve days running',
    open: 'Streak',
  ),
  (
    name: 'dialog',
    own: 32,
    build: (s) => Builder(
      builder: (context) => ClayButton(
        'Open',
        onPressed: () => showClayDialog<void>(
          context: context,
          builder: (context) => ClayDialog(
            title: 'Leave without saving?',
            style: s,
            content: const Text('Your changes go.'),
          ),
        ),
      ),
    ),
    inside: 'Your changes go.',
    open: 'Open',
  ),
];

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  TextDirection direction = TextDirection.ltr,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      key: UniqueKey(),
      builder: (context, app) => Directionality(
        textDirection: direction,
        child: ClayTheme(
          data: ClayThemeData.clay(Brightness.light),
          child: app!,
        ),
      ),
      home: Directionality(
        textDirection: direction,
        child: Center(
          child: SizedBox(
            width: 360,
            child: KeyedSubtree(key: _part, child: child),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

// What is drawn: an animated surface's own ClaySurface shows the face of
// the moment.
final _surfaces = find.byType(ClaySurface);

double _radiusOf(Widget w) => (w as ClaySurface).face.radius;

// The part's outline: the surface holding the words inside an overlay's
// panel, else the part's largest surface.
double _outline(WidgetTester tester, _Shaped part) {
  if (part.inside != null) {
    return _radiusOf(
      tester.widget(
        find.ancestor(of: find.text(part.inside!), matching: _surfaces).last,
      ),
    );
  }
  final found = find.descendant(of: find.byKey(_part), matching: _surfaces);
  var best = found.evaluate().first;
  for (final e in found.evaluate()) {
    final a = e.size!, b = best.size!;
    if (a.width * a.height > b.width * b.height) best = e;
  }
  return _radiusOf(best.widget);
}

Future<double> _shown(
  WidgetTester tester,
  _Shaped part,
  ClayStyle? style, {
  TextDirection direction = TextDirection.ltr,
}) async {
  await _pump(tester, part.build(style), direction: direction);
  if (part.open != null) {
    await tester.tap(find.text(part.open!));
    await tester.pumpAndSettle();
  }
  return _outline(tester, part);
}

void main() {
  setUpAll(clayLoadFonts);

  test('Clay opens one step on every corner, never square', () {
    const limits = ClayThemeData.shapeLimits;
    expect(limits.cornerFreedom, RawCornerFreedom.uniform);
    expect(limits.cornerSteps, isNot(contains(RawCorner.none)));
    expect(limits.nearestStep(RawCorner.none), RawCorner.extraSmall);
  });

  for (final part in _parts) {
    for (final direction in TextDirection.values) {
      testWidgets('a ${part.name} takes one step on every corner '
          '(${direction.name})', (tester) async {
        // The part's own corners, then one step all round: a step past its
        // own and a step short of it, in this theme's scale.
        expect(
          await _shown(tester, part, null, direction: direction),
          part.own,
        );
        expect(
          await _shown(
            tester,
            part,
            _corners(const RawCorners.all(RawCorner.extraLarge)),
            direction: direction,
          ),
          part.own == 32 ? 32 : 32,
        );
        expect(
          await _shown(
            tester,
            part,
            _corners(const RawCorners.all(RawCorner.small)),
            direction: direction,
          ),
          9,
        );
        // Two diagonal corners cut, or one corner alone: corners that differ,
        // so the part keeps its own.
        expect(
          await _shown(
            tester,
            part,
            _corners(
              const RawCorners(
                topEnd: RawCorner.none,
                bottomStart: RawCorner.none,
              ),
            ),
            direction: direction,
          ),
          part.own,
        );
        expect(
          await _shown(
            tester,
            part,
            _corners(const RawCorners.only(topStart: RawCorner.large)),
            direction: direction,
          ),
          part.own,
        );
        // Square all round goes to the extra-small step: clay holds no
        // sharp corner.
        expect(
          await _shown(
            tester,
            part,
            _corners(const RawCorners.all(RawCorner.none)),
            direction: direction,
          ),
          6,
        );
      });
    }

    testWidgets("a ${part.name}'s shape wins over its corners", (tester) async {
      final r = await _shown(
        tester,
        part,
        const ClayStyle(
          shape: WidgetStatePropertyAll(
            RoundedSuperellipseBorder(
              borderRadius: BorderRadius.all(Radius.circular(11)),
            ),
          ),
          corners: WidgetStatePropertyAll(RawCorners.all(RawCorner.small)),
        ),
      );
      expect(r, 11);
    });
  }

  testWidgets("an override follows the theme's scale", (tester) async {
    final theme = ClayThemeData.clay(Brightness.light);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: ClayTheme(
          data: theme.copyWith(
            shapeScheme: theme.shapeScheme.copyWith(
              corners: theme.shapeScheme.corners.copyWith(extraLarge: 40),
            ),
          ),
          child: Center(
            child: ClayCard(
              key: _part,
              style: _corners(const RawCorners.all(RawCorner.extraLarge)),
              child: const SizedBox(width: 200, height: 100),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(_outline(tester, _parts.firstWhere((p) => p.name == 'card')), 40);
  });

  testWidgets("a group's rows keep concentric with the corners it is given", (
    tester,
  ) async {
    double plate() => _radiusOf(
      tester.widget(
        find
            .descendant(
              of: find.byType(ClayListTile),
              matching: find.byType(ClaySurface),
            )
            .first,
      ),
    );
    final group = _parts.firstWhere((p) => p.name == 'group');
    await _pump(tester, group.build(null));
    expect(plate(), 24 - ClayListTile.plateInset);
    await _pump(
      tester,
      group.build(_corners(const RawCorners.all(RawCorner.extraLarge))),
    );
    expect(plate(), 32 - ClayListTile.plateInset);
  });

  testWidgets('corners that change with a press move there over frames', (
    tester,
  ) async {
    final style = ClayStyle(
      corners: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.pressed)
            ? const RawCorners.all(RawCorner.extraLarge)
            : null,
      ),
    );
    await _pump(tester, ClayButton('Save', onPressed: () {}, style: style));
    final button = _parts.firstWhere((p) => p.name == 'button');
    expect(_outline(tester, button), 16);
    final press = await tester.startGesture(
      tester.getCenter(find.text('Save')),
    );
    final seen = <double>[];
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      seen.add(_outline(tester, button));
    }
    expect(seen.where((r) => r > 16 && r < 32), isNotEmpty);
    expect(seen.every((r) => r >= 16 && r <= 32), isTrue);
    await press.up();
    await tester.pumpAndSettle();
    expect(_outline(tester, button), 16);
  });
}
