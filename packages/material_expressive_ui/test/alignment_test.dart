// Alignment, measured (shapes.md §7): on every example page and in every
// overlay, under each corner family,
// - a button's or chip's icon sits on its label's centre line;
// - a row of up to two lines centres its icons and controls on its text;
// - a field's icons sit on its input line;
// - the parts of a button group or action row are one height on one line;
// - a tab bar's and nav bar's labels share one baseline, their icons one
//   centre line, and each label is centred on its icon;
// - an app bar's icons, and a title on their row, share one centre line.
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

// ignore_for_file: avoid_relative_lib_imports
import '../example/lib/main.dart';
import '../example/lib/kit_gallery/kit.dart';
import '../example/lib/kit_gallery/trip.dart';
import 'gallery_support.dart';
import 'overlay_fixtures.dart';

/// Half a pixel either way of a device pixel's rounding.
const _tolerance = 1.0;

String _name(Widget w) => w.runtimeType.toString().split('<').first;

const _buttons = {
  'ExpressiveButton',
  'ExpressiveToggleButton',
  'ExpressiveChip',
  'ExpressiveSplitLeadingButton',
};
const _rows = {
  'ExpressiveListTile',
  'ExpressiveCheckboxRow',
  'ExpressiveSwitchRow',
  'ExpressiveRadioRow',
  'ExpressiveChoiceTile',
  'ExpressiveMenuItem',
  'ExpressiveMenuCheckItem',
  'ExpressiveMenuRadioItem',
};
const _fields = {
  'ExpressiveTextField',
  'ExpressiveSearchField',
  'ExpressiveSelect',
};
const _groups = {
  'ExpressiveButtonGroup',
  'ExpressiveSegmentedButton',
  'ExpressiveMultiChoiceSegmentedButton',
  'ExpressiveSplitButton',
};
const _bars = {'ExpressiveTabBar', 'ExpressiveNavigationBar'};
const _rails = {'ExpressiveNavigationRail'};
const _appBars = {'ExpressiveAppBar'};

/// Parts whose insides belong to them, not to a part around them.
const _boundaries = {
  ..._buttons,
  ..._rows,
  ..._fields,
  ..._groups,
  ..._bars,
  ..._rails,
  ..._appBars,
  'ExpressiveBadge',
  'ExpressiveIconButton',
  'ExpressiveSearchBar',
  'ExpressiveCheckbox',
  'ExpressiveSwitch',
  'ExpressiveRadio',
  'ExpressiveAvatar',
  'ExpressiveIcon',
  'Icon',
};

typedef _Box = ({Element element, Rect rect});

Rect? _rectOf(Element e) {
  final box = e.renderObject;
  if (box is! RenderBox || !box.hasSize || !box.attached || box.size.isEmpty) {
    return null;
  }
  // The box as painted: a turned chevron keeps its centre.
  return MatrixUtils.transformRect(
    box.getTransformTo(null),
    Offset.zero & box.size,
  );
}

/// What [part] holds of its own: [match]ing elements not inside a nested
/// part (a badge on a nav icon, a chip in a row).
List<_Box> _own(Element part, bool Function(Element) match) {
  final out = <_Box>[];
  void visit(Element e) {
    if (match(e)) {
      if (_rectOf(e) case final rect?) out.add((element: e, rect: rect));
      return;
    }
    if (_boundaries.contains(_name(e.widget))) return;
    e.visitChildElements(visit);
  }

  part.visitChildElements(visit);
  return out;
}

/// Whether anything of [e] shows: not faded out, not offstage.
bool _shows(Element e) {
  for (RenderObject? r = e.renderObject; r != null; r = r.parent) {
    if (r is RenderOpacity && r.opacity == 0 ||
        r is RenderAnimatedOpacity && r.opacity.value == 0 ||
        r is RenderOffstage && r.offstage) {
      return false;
    }
  }
  return true;
}

/// Every descendant of [e] that [match]es, nested parts included.
List<_Box> _all(Element e, bool Function(Element) match) {
  final out = <_Box>[];
  void visit(Element c) {
    if (match(c)) {
      if (_rectOf(c) case final rect?) out.add((element: c, rect: rect));
    }
    c.visitChildElements(visit);
  }

  e.visitChildElements(visit);
  return out;
}

bool _isSurface(Element e) =>
    e.widget.runtimeType.toString() == '_SurfacePaint';

/// A member's painted body: its first surface, or its own box.
Rect _body(_Box member) =>
    _all(member.element, _isSurface).firstOrNull?.rect ?? member.rect;

bool _isIcon(Element e) =>
    (e.widget is ExpressiveIcon || e.widget is Icon) && _shows(e);

bool _isText(Element e) =>
    e.widget is RichText &&
    _shows(e) &&
    (e.renderObject! as RenderParagraph).text.toPlainText().trim().isNotEmpty;

bool _isControl(Element e) =>
    e.widget is ExpressiveCheckbox ||
    e.widget is ExpressiveSwitch ||
    e.widget is ExpressiveRadio;

int _lines(_Box text) {
  final p = text.element.renderObject! as RenderParagraph;
  return p
      .getBoxesForSelection(
        TextSelection(baseOffset: 0, extentOffset: p.text.toPlainText().length),
      )
      .map((b) => b.top.round())
      .toSet()
      .length;
}

/// The paragraph's first alphabetic baseline, laid out as it was.
double _baseline(_Box text) {
  final p = text.element.renderObject! as RenderParagraph;
  final painter = TextPainter(
    text: p.text,
    textAlign: p.textAlign,
    textDirection: p.textDirection,
    textScaler: p.textScaler,
    maxLines: p.maxLines,
    strutStyle: p.strutStyle,
    textWidthBasis: p.textWidthBasis,
    textHeightBehavior: p.textHeightBehavior,
  )..layout(maxWidth: p.size.width);
  final baseline = painter.computeDistanceToActualBaseline(
    TextBaseline.alphabetic,
  );
  painter.dispose();
  return text.rect.top + baseline;
}

/// How many pairs each rule measured, so no rule passes by measuring
/// nothing.
final measured = <String, int>{};

bool _near(double a, double b, String rule) {
  measured[rule] = (measured[rule] ?? 0) + 1;
  return (a - b).abs() <= _tolerance;
}

List<String> checkAlignment(WidgetTester tester, String where) {
  final failures = <String>[];
  void fail(Element part, String what) =>
      failures.add('$where: ${_name(part.widget)} $what');

  for (final part
      in find
          .byWidgetPredicate((w) => _boundaries.contains(_name(w)))
          .evaluate()) {
    if (_rectOf(part) == null) continue;
    final name = _name(part.widget);
    final icons = _own(part, _isIcon);
    final texts = _own(part, _isText);

    if (_buttons.contains(name)) {
      final label = texts.where((t) => _lines(t) == 1).firstOrNull;
      if (label == null) continue;
      for (final icon in icons) {
        if (!_near(icon.rect.center.dy, label.rect.center.dy, 'button')) {
          fail(
            part,
            'icon centre ${icon.rect.center.dy} off its label '
            '${label.rect.center.dy}',
          );
        }
      }
    }

    if (_rows.contains(name)) {
      if (texts.isEmpty || texts.fold(0, (n, t) => n + _lines(t)) > 2) {
        continue;
      }
      final block = texts
          .map((t) => t.rect)
          .reduce((a, b) => a.expandToInclude(b));
      for (final mark in [...icons, ..._own(part, _isControl)]) {
        if (!_near(mark.rect.center.dy, block.center.dy, 'row')) {
          fail(
            part,
            '${_name(mark.element.widget)} centre ${mark.rect.center.dy} '
            'off its text ${block.center.dy} '
            '(${[for (final t in texts) (t.element.widget as RichText).text.toPlainText()]})',
          );
        }
      }
    }

    if (_fields.contains(name)) {
      final input = _own(
        part,
        (e) =>
            e.widget is EditableText &&
            (e.widget as EditableText).maxLines == 1,
      ).firstOrNull;
      if (input == null) continue;
      // Icons centre on the field's container (Material's text field: the
      // input line sits below centre, under the floating label). The
      // container is the field's box less its supporting text: where the
      // field takes a tap.
      final field = _all(
        part,
        (e) => e.renderObject.runtimeType.toString() == '_RenderField',
      ).firstOrNull;
      if (field == null) continue;
      final render = field.element.renderObject! as RenderBox;
      var bottom = 0.0;
      while (bottom < render.size.height &&
          ((render as dynamic).hitTestSelf(
            Offset(render.size.width / 2, bottom + .25),
          ) as bool)) {
        bottom += .5;
      }
      final container = Rect.fromLTWH(
        field.rect.left,
        field.rect.top,
        field.rect.width,
        bottom,
      );
      for (final icon in icons) {
        if (!_near(icon.rect.center.dy, container.center.dy, 'field')) {
          fail(
            part,
            'icon centre ${icon.rect.center.dy} off its container '
            '${container.center.dy} (${container.size})',
          );
        }
      }
    }

    if (_groups.contains(name)) {
      final members = _own(
        part,
        (e) =>
            e.widget is ExpressivePressable ||
            const {
              ..._buttons,
              'ExpressiveIconButton',
              'ExpressiveIconToggleButton',
              'ExpressiveSplitTrailingButton',
            }.contains(_name(e.widget)),
      ).map((m) => (element: m.element, rect: _body(m))).toList();
      if (members.length < 2) continue;
      // Members on one line: those whose centre is on the first's row.
      final row = members
          .where((m) => (m.rect.top - members.first.rect.top).abs() < 8)
          .toList();
      final height = row.first.rect.height;
      final centre = row.first.rect.center.dy;
      for (final m in row.skip(1)) {
        if (!_near(m.rect.height, height, 'group') ||
            !_near(m.rect.center.dy, centre, 'group')) {
          fail(
            part,
            'members differ: ${_name(m.element.widget)} ${m.rect.height} '
            'high at ${m.rect.center.dy} beside '
            '${_name(row.first.element.widget)} $height at $centre',
          );
        }
      }
    }

    if (_bars.contains(name) || _rails.contains(name)) {
      final labels = texts.where((t) => _lines(t) == 1).toList();
      if (_bars.contains(name)) {
        // One row of items: labels on one baseline, icons on one line.
        final iconRow = icons.where(
          (i) =>
              _near(i.rect.center.dy, icons.first.rect.center.dy, 'bar icons'),
        );
        if (iconRow.length != icons.length) {
          fail(part, 'icons on ${icons.map((i) => i.rect.center.dy).toSet()}');
        }
        final stacked = labels
            .where((l) => icons.any((i) => l.rect.top >= i.rect.bottom - 1))
            .toList();
        if (stacked.isNotEmpty &&
            stacked.any(
              (l) =>
                  !_near(_baseline(l), _baseline(stacked.first), 'bar labels'),
            )) {
          fail(part, 'labels on baselines ${stacked.map(_baseline).toSet()}');
        }
      }
      for (final icon in icons) {
        final under = labels.where(
          (l) =>
              l.rect.left <= icon.rect.center.dx &&
              l.rect.right >= icon.rect.center.dx &&
              l.rect.top >= icon.rect.bottom - 1,
        );
        final beside = labels.where(
          (l) =>
              l.rect.left >= icon.rect.right - 1 &&
              l.rect.top < icon.rect.bottom &&
              l.rect.bottom > icon.rect.top,
        );
        if (under.firstOrNull case final l?
            when !_near(l.rect.center.dx, icon.rect.center.dx, 'item label')) {
          fail(
            part,
            'label "${(l.element.widget as RichText).text.toPlainText()}" '
            'centre ${l.rect.center.dx} off its icon ${icon.rect.center.dx}',
          );
        }
        if (under.isEmpty) {
          if (beside.firstOrNull case final l?
              when !_near(
                l.rect.center.dy,
                icon.rect.center.dy,
                'item label',
              )) {
            fail(
              part,
              'label beside its icon at ${l.rect.center.dy}, icon at '
              '${icon.rect.center.dy}',
            );
          }
        }
      }
    }

    if (_appBars.contains(name)) {
      final buttons = _own(part, (e) => e.widget is ExpressiveIconButton);
      final marks = [...buttons, ...icons];
      if (marks.isEmpty) continue;
      // The top row: everything level with the first icon's row.
      final top = marks
          .map((m) => m.rect.center.dy)
          .reduce((a, b) => a < b ? a : b);
      final row = marks.where((m) => (m.rect.center.dy - top).abs() < 12);
      for (final m in row) {
        if (!_near(m.rect.center.dy, top, 'app bar icons')) {
          fail(part, 'icons on ${row.map((m) => m.rect.center.dy).toSet()}');
          break;
        }
      }
      // Halfway through a collapse both titles show, the big one fading:
      // a transition, not a resting layout.
      final words = [
        for (final t in texts)
          (t.element.widget as RichText).text.toPlainText(),
      ];
      if (words.toSet().length < words.length) continue;
      // The title block on the icons' row (a title, or a title over its
      // subtitle) is centred on them.
      final onRow = texts
          .where((t) => (t.rect.center.dy - top).abs() < 24)
          .map((t) => t.rect);
      if (onRow.isNotEmpty) {
        final block = onRow.reduce((a, b) => a.expandToInclude(b));
        if (!_near(block.center.dy, top, 'app bar title')) {
          fail(
            part,
            'title block centre ${block.center.dy} off its icons $top '
            '(${[for (final t in texts) '"${(t.element.widget as RichText).text.toPlainText()}" ${t.rect}'].join(', ')})',
          );
        }
      }
    }
  }
  return failures;
}

void main() {
  setUpAll(loadExpressiveFonts);
  tearDown(() => kitShownTheme = null);

  testWidgets('every page and overlay is aligned', (tester) async {
    final failures = <String>[];
    for (final page in galleryExamplePages) {
      await pumpGalleryPage(tester, page, 'baseline', Brightness.light);
      expect(tester.takeException(), isNull, reason: page.id);
      failures.addAll(checkAlignment(tester, page.id));
    }
    await forEachOverlay(
      tester,
      ExpressiveThemeData.preset('baseline', Brightness.light),
      (name) => failures.addAll(checkAlignment(tester, 'overlay $name')),
    );
    expect(failures.toSet().toList(), isEmpty);
    // ignore: avoid_print
    print('measured: $measured');
    for (final rule in const [
      'button',
      'row',
      'field',
      'group',
      'bar icons',
      'bar labels',
      'item label',
      'app bar icons',
      'app bar title',
    ]) {
      expect(
        measured[rule] ?? 0,
        greaterThan(0),
        reason: '$rule measured nothing',
      );
    }
    measured.clear();
  });

  // The column's edges (shapes.md §7; the coordinator's 11-08 review): on
  // the trip planner's screens, at a phone's width and a desktop's,
  // - the app bar's title starts on the content column's start edge (a
  //   screen whose bar leads with a close or back button excepted);
  // - a flush checkbox row's box starts on its lane's start edge, as the
  //   fields do (the box sits 2dp inside its own box, Compose's
  //   CheckboxDefaultPadding);
  // - a list section's container runs from its lane's start edge to its
  //   end edge.
  const markInset = 2.0;
  for (final width in [390.0, 1440.0]) {
    testWidgets('${width.round()}: rows, sections and the title keep '
        'the column edges', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 2400);
      addTearDown(tester.view.reset);
      final failures = <String>[];
      void near(double actual, double expected, String what) {
        if ((actual - expected).abs() > _tolerance) {
          failures.add(
            '$what at ${actual.toStringAsFixed(1)}, '
            'the edge at ${expected.toStringAsFixed(1)}',
          );
        }
      }

      var checked = 0;
      for (final id in TripScreens.all) {
        final page = galleryExamplePages.firstWhere((p) => p.id == id);
        await tester.pumpWidget(
          KeyedSubtree(
            key: ValueKey('$id/$width'),
            child: page.build(Brightness.light),
          ),
        );
        await settle(tester);
        expect(tester.takeException(), isNull, reason: id);
        final column = tester.getRect(
          find.byKey(const ValueKey('trip-column')),
        );
        final where = '$id ${width.round()}';
        Finder of(Element e) => find.byElementPredicate((x) => identical(x, e));
        // A part's lane: the page column, or the column of a side-by-side
        // split (an Expanded in a Row) it sits in.
        Rect lane(Element e) {
          final splits = find
              .ancestor(of: of(e), matching: find.byType(Expanded))
              .evaluate()
              .map((x) => tester.getRect(of(x)))
              .where(
                (r) =>
                    r.width < column.width - _tolerance &&
                    r.left >= column.left - _tolerance &&
                    r.right <= column.right + _tolerance,
              );
          return splits.isEmpty ? column : splits.first;
        }

        if (id != TripScreens.plan) {
          near(
            tester
                .getRect(
                  find
                      .descendant(
                        of: find.byType(ExpressiveAppBar),
                        matching: find.text(TripScreens.title(id)),
                      )
                      .first,
                )
                .left,
            column.left,
            '$where: the app bar title',
          );
          checked++;
        }
        for (final e in find.byType(ExpressiveCheckboxRow).evaluate()) {
          final box = find.descendant(
            of: of(e),
            matching: find.byType(ExpressiveCheckbox),
          );
          near(
            tester.getRect(box).left + markInset,
            lane(e).left,
            '$where: a checkbox box',
          );
          checked++;
        }
        for (final e in find.byType(ExpressiveListSection).evaluate()) {
          // A pane of a list beside its detail is its own lane.
          if (find
              .ancestor(of: of(e), matching: find.byType(ExpressiveResizable))
              .evaluate()
              .isNotEmpty) {
            continue;
          }
          final r = tester.getRect(of(e));
          near(r.left, lane(e).left, '$where: a list section start');
          near(r.right, lane(e).right, '$where: a list section end');
          checked += 2;
        }
      }
      expect(failures, isEmpty, reason: failures.join('\n'));
      expect(checked, greaterThan(10));
    });
  }
}
