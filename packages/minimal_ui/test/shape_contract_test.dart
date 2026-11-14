// The shape contract (shapes.md §1, §2 and §4; polish round 3, §1 and §2), read back from what the parts paint:
//
// - under every corner family the gallery's Customize offers, each framed part draws its role's step of the scale,
//   and its press wash and focus ring take that exact outline;
// - every exported widget is either in that list or named, with its reason, as drawing no frame of its own: a new
//   widget in neither fails the test, so it can't slip through;
// - a nested outline is the outer one moved by one constant distance, measured on the path;
// - no text falls back to Flutter's unstyled double underline;
// - a hovering pointer changes nothing on the new parts, and every pressable shows the click cursor;
// - in the state matrix every pressed, disabled and error cell differs from idle pixel for pixel at idle's size (an
//   error may add its message below), a part with a chosen face pressed on its chosen item as well as off;
// - labels in a row of controls share one centre line.
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

final MinimalThemeData _look = MinimalThemeData.preset(
  'standard',
  Brightness.light,
);

/// The corner scales the example's Customize panel reaches: the look's own,
/// a rounder radius, and square.
final Map<String, MinimalShapes> _families = {
  'as drawn': MinimalShapes.look,
  'rounded 12': const MinimalShapes(radius: 12),
  'square': const MinimalShapes(radius: 0),
};

void _tap() {}

const Key _part = Key('part');

Widget _host(Widget child, MinimalThemeData theme) => MaterialApp(
  builder: (context, navigator) => MinimalHost(
    light: theme,
    dark: theme,
    brightness: Brightness.light,
    child: navigator!,
  ),
  home: Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: KeyedSubtree(key: _part, child: child),
      ),
    ),
  ),
);

/// A decoration's outline, as one comparable line: its kind and its four
/// corners (a side and a fill aside).
String _outline(Object? shape) {
  String corners(BorderRadiusGeometry g) {
    final r = g.resolve(TextDirection.ltr);
    return [r.topLeft, r.topRight, r.bottomRight, r.bottomLeft]
        .map(
          (c) => c.x == c.y
              ? c.x.toStringAsFixed(1)
              : '${c.x.toStringAsFixed(1)}/${c.y.toStringAsFixed(1)}',
        )
        .join(' ');
  }

  return switch (shape) {
    BoxDecoration(shape: BoxShape.circle) => 'circle',
    BoxDecoration(:final borderRadius) =>
      'rounded ${corners(borderRadius ?? BorderRadius.zero)}',
    ShapeDecoration(:final shape) => _outline(shape),
    CircleBorder() => 'circle',
    StadiumBorder() => 'capsule',
    RoundedRectangleBorder(:final borderRadius) =>
      'rounded ${corners(borderRadius)}',
    RoundedSuperellipseBorder(:final borderRadius) =>
      'squircle ${corners(borderRadius)}',
    BeveledRectangleBorder(:final borderRadius) =>
      'bevel ${corners(borderRadius)}',
    ContinuousRectangleBorder(:final borderRadius) =>
      'continuous ${corners(borderRadius)}',
    Decoration d when _shapeIn(d) != null => _outline(_shapeIn(d)),
    _ => '${shape.runtimeType}',
  };
}

/// The outline a decoration of the look's own (the keyboard's ring, drawn
/// past a band of the ground) names in its diagnostics.
ShapeBorder? _shapeIn(Decoration decoration) {
  for (final p in decoration.toDiagnosticsNode().getProperties()) {
    if (p.name == 'shape' && p.value is ShapeBorder) {
      return p.value as ShapeBorder;
    }
  }
  return null;
}

/// Every outline the part paints behind its content (and, with [rim], the
/// rims it draws over it).
List<String> _frames(WidgetTester tester, {bool rim = false}) => [
  for (final box in tester.widgetList<DecoratedBox>(
    find.descendant(
      of: find.byKey(_part),
      matching: find.byWidgetPredicate(
        (w) =>
            w is DecoratedBox &&
            (rim || w.position == DecorationPosition.background),
      ),
    ),
  ))
    _outline(box.decoration),
];

/// The outline of the part's first press wash and focus ring.
String _highlight(WidgetTester tester) {
  final pressable = find
      .descendant(
        of: find.byKey(_part),
        matching: find.byType(MinimalPressable),
      )
      .first;
  final face = tester.widget<AnimatedContainer>(
    find
        .descendant(of: pressable, matching: find.byType(AnimatedContainer))
        .first,
  );
  return _outline(face.foregroundDecoration);
}

/// One framed part: how to build it, the step its role draws, whether its
/// first pressable's highlight takes that same outline, and whether the
/// outline is a rim drawn over its cells (a split button's).
typedef _Framed = ({
  Widget Function() build,
  OutlinedBorder Function(MinimalShapes s) step,
  bool highlight,
  bool rim,
});

_Framed _f(
  Widget Function() build,
  OutlinedBorder Function(MinimalShapes s) step, {
  bool highlight = false,
  bool rim = false,
}) => (build: build, step: step, highlight: highlight, rim: rim);

OutlinedBorder _mark(MinimalShapes s) => s.mark;
OutlinedBorder _small(MinimalShapes s) => s.small;
OutlinedBorder _medium(MinimalShapes s) => s.medium;
OutlinedBorder _large(MinimalShapes s) => s.large;
OutlinedBorder _pill(MinimalShapes s) => s.pill;
OutlinedBorder _hairInside(MinimalShapes s) => MinimalShapes.inset(s.small, 1);
OutlinedBorder _round(MinimalShapes s) => const CircleBorder();

final Map<String, _Framed> _framed = {
  'MinimalButton': _f(
    () => const MinimalButton('Save', onPressed: _tap),
    _small,
    highlight: true,
  ),
  'MinimalIconButton': _f(
    () => const MinimalIconButton(
      LucideIcons.x,
      label: 'Close',
      onPressed: _tap,
      variant: MinimalIconButtonVariant.outline,
    ),
    _small,
    highlight: true,
  ),
  'MinimalChip': _f(
    () => const MinimalChip('Open', onPressed: _tap),
    _pill,
    highlight: true,
  ),
  'MinimalFilter': _f(
    () =>
        const MinimalFilter('Open', count: 2, selected: true, onPressed: _tap),
    _hairInside,
    highlight: true,
  ),
  'MinimalPropertyPill': _f(
    () => const MinimalPropertyPill(
      icon: LucideIcons.calendar,
      label: 'Today',
      onPressed: _tap,
    ),
    _hairInside,
    highlight: true,
  ),
  'MinimalCheckbox': _f(
    () => MinimalCheckbox(value: true, onChanged: (_) {}),
    _mark,
    highlight: true,
  ),
  'MinimalCheckMark': _f(() => const MinimalCheckMark(value: true), _mark),
  'MinimalRadio': _f(
    () => const MinimalRadio(selected: true, onPressed: _tap, label: 'Pro'),
    _round,
    highlight: true,
  ),
  'MinimalSwitch': _f(
    () => MinimalSwitch(value: true, label: 'Alerts', onChanged: (_) {}),
    _pill,
    highlight: true,
  ),
  'MinimalCard': _f(
    () => const MinimalCard(onPressed: _tap, child: Text('Plan')),
    _medium,
    highlight: true,
  ),
  'MinimalTextField': _f(() => const MinimalTextField(label: 'Name'), _small),
  'MinimalTextArea': _f(() => const MinimalTextArea(label: 'Notes'), _small),
  'MinimalSearchField': _f(
    () => const MinimalSearchField(hint: 'Search'),
    _small,
  ),
  'MinimalSegmentedButton': _f(
    () => MinimalSegmentedButton<int>(
      segments: const [
        MinimalButtonSegment(0, 'Day'),
        MinimalButtonSegment(1, 'Week'),
      ],
      value: 0,
      label: 'Range',
      onChanged: (_) {},
    ),
    _small,
  ),
  'MinimalNumberField': _f(
    () => MinimalNumberField(
      value: 2,
      min: 0,
      max: 9,
      label: 'Guests',
      onChanged: (_) {},
    ),
    _small,
  ),
  'MinimalDatePicker': _f(
    () => MinimalDatePicker(
      label: 'Due',
      value: DateTime(2026, 11, 9, 9, 30),
      onChanged: (_) {},
    ),
    _hairInside,
    highlight: true,
  ),
  'MinimalButtonGroup': _f(
    () => MinimalButtonGroup(
      items: const [
        MinimalButtonGroupItem(label: 'Day', onPressed: _tap),
        MinimalButtonGroupItem(label: 'Week', onPressed: _tap),
      ],
    ),
    _small,
  ),
  'MinimalPagination': _f(
    () => MinimalPagination(page: 2, pageCount: 9, onPageChanged: (_) {}),
    _small,
    highlight: true,
  ),
  'MinimalPageDots': _f(
    () => const MinimalPageDots(count: 3, selectedIndex: 1),
    _pill,
  ),
  'MinimalStepProgress': _f(
    () => const MinimalStepProgress(steps: ['Cart', 'Pay', 'Done'], current: 1),
    _round,
  ),
  'MinimalTag': _f(() => const MinimalTag('Draft'), _mark),
  'MinimalStatusBadge': _f(() => const MinimalStatusBadge('Done'), _mark),
  'MinimalKbd': _f(() => const MinimalKbd('K'), _mark),
  'MinimalIconTile': _f(() => const MinimalIconTile(LucideIcons.bell), _mark),
  'MinimalBadge': _f(() => const MinimalBadge(count: 3), _pill),
  'MinimalMeter': _f(
    () => const MinimalMeter(label: 'Storage', value: 0.5),
    _pill,
  ),
  'MinimalSkeleton': _f(() => const MinimalSkeleton(width: 120), _mark),
  'MinimalAvatar': _f(() => const MinimalAvatar('Ana Ruiz'), _round),
  'MinimalMedia': _f(
    () => const MinimalMedia(
      MinimalPlaceholderImage(MinimalMediaKind.food, 1),
      width: 64,
      height: 48,
    ),
    _small,
  ),
  'MinimalSnackBar': _f(() => const MinimalSnackBar('Saved'), _medium),
  'MinimalBanner': _f(() => const MinimalBanner(title: 'Heads up'), _medium),
  'MinimalDialog': _f(() => const MinimalDialog(title: 'Delete?'), _large),
  'MinimalStat': _f(
    () => const MinimalStat(label: 'Revenue', value: r'$4.2k'),
    _medium,
  ),
  'MinimalStatRow': _f(
    () => const MinimalStatRow.joined(
      children: [
        MinimalStat(label: 'Open', value: '12'),
        MinimalStat(label: 'Closed', value: '30'),
      ],
    ),
    _medium,
  ),
  'MinimalActionBar': _f(
    () =>
        const MinimalActionBar(label: 'Save', onPressed: _tap, floating: true),
    _medium,
  ),
  'MinimalCodeBlock': _f(() => const MinimalCodeBlock('print(1);'), _small),
  // The B rows, painted on ui_core's behaviours (11-10).
  'MinimalToggleGroup': _f(
    () => MinimalToggleGroup<String>(
      label: 'View',
      selected: const {'list'},
      onChanged: (_) {},
      items: const [
        MinimalToggleItem('list', label: 'List'),
        MinimalToggleItem('board', label: 'Board'),
      ],
    ),
    _small,
  ),
  'MinimalSplitButton': _f(
    () => const MinimalSplitButton(
      'Save',
      onPressed: _tap,
      actions: [MinimalMenuItem('Save as…', onPressed: _tap)],
    ),
    _small,
    rim: true,
  ),
  'MinimalInputGroup': _f(
    () => const SizedBox(
      width: 320,
      child: MinimalInputGroup(label: 'Website', prefixText: 'https://'),
    ),
    _small,
  ),
  'MinimalPasswordField': _f(
    () => const SizedBox(
      width: 320,
      child: MinimalPasswordField(label: 'Password'),
    ),
    _small,
  ),
  'MinimalCombobox': _f(
    () => SizedBox(
      width: 320,
      child: MinimalCombobox<String>(
        label: 'City',
        options: const ['Lisbon', 'London'],
        displayString: (c) => c,
        onSelected: (_) {},
      ),
    ),
    _small,
  ),
  'MinimalMultiSelect': _f(
    () => SizedBox(
      width: 320,
      child: MinimalMultiSelect<String>(
        label: 'Labels',
        values: const ['Bug'],
        options: const ['Bug', 'Docs'],
        displayString: (l) => l,
        onChanged: (_) {},
      ),
    ),
    _small,
  ),
  'MinimalColorPicker': _f(
    () => SizedBox(
      width: 300,
      child: MinimalColorPicker(
        value: const Color(0xFF2563EB),
        onChanged: (_) {},
      ),
    ),
    _small,
  ),
  'MinimalCalendar': _f(
    () => SizedBox(
      width: 320,
      child: MinimalCalendar(
        firstDate: DateTime(2026),
        lastDate: DateTime(2027),
        today: DateTime(2026, 3, 12),
        onChanged: (_) {},
      ),
    ),
    _hairInside,
  ),
  'MinimalDateRangePicker': _f(
    () => SizedBox(
      width: 320,
      child: MinimalDateRangePicker(
        label: 'Stay',
        firstDate: DateTime(2026),
        lastDate: DateTime(2027),
        onChanged: (_) {},
      ),
    ),
    _small,
  ),
  'MinimalMenuBar': _f(
    () => const MinimalMenuBar(
      menus: [
        MinimalMenuEntry(
          'File',
          children: [MinimalMenuEntry('New', onPressed: _tap)],
        ),
      ],
    ),
    _small,
  ),
};

/// Every exported widget that draws no frame of its own, and why.
const Map<String, String> _frameless = {
  'MinimalGap': 'space',
  'MinimalIcon': 'a glyph',
  'MinimalTheme': 'installs the theme',
  'MinimalGroundScope': 'carries the ground',
  'MinimalHost': 'the app host',
  'MinimalPreview': 'a page preview host',
  'MinimalScaffold': 'page layout around its bar and body',
  'MinimalShell': 'the tab shell around pages',
  'MinimalReveal': 'an entrance motion',
  'MinimalHitTarget': 'pads a hit area',
  'MinimalPressable': 'the highlight itself: checked through every case',
  'MinimalAppBar': 'a full-bleed bar; its buttons are icon buttons',
  'MinimalNavigationBar': 'a full-bleed bar; its create square is a button',
  'MinimalNavigationRail': 'full-bleed; its press wash is shapes.small',
  'MinimalNavigationDrawer': 'full-bleed; its press wash is shapes.small',
  'MinimalTabBar': 'an underline indicator; its focus ring is shapes.mark',
  'MinimalBreadcrumb': 'words; each crumb is a pressable on shapes.mark',
  'MinimalLink': 'words; its pressable is shapes.mark',
  'MinimalButtonGroupItem': 'a button group cell',
  'MinimalChipRow': 'lays out chips',
  'MinimalFilterBar': 'lays out filters',
  'MinimalPropertyBar': 'lays out property pills',
  'MinimalListTile': 'a full-bleed row; a section clips it',
  'MinimalListSection': 'a list section: its inset form is a MinimalCard',
  'MinimalSection': 'a titled band',
  'MinimalSectionHeader': 'a heading',
  'MinimalFormSection': 'a titled form band',
  'MinimalFormRow': 'a form row',
  'MinimalInputRow': 'a form row around a field',
  'MinimalMetaRow': 'a line of metadata',
  'MinimalDescriptionList': 'term and value rows',
  'MinimalProperty': 'a property row',
  'MinimalTimeline': 'a list with a rule',
  'MinimalActivity': 'a timeline row',
  'MinimalAvatarGroup': 'overlapping avatars (each round)',
  'MinimalStatusIcon': 'a glyph',
  'MinimalPriorityIcon': 'a glyph',
  'MinimalCounter': 'a figure',
  'MinimalDivider': 'a hairline',
  'MinimalDisclosure': 'a full-bleed row and its body',
  'MinimalLinearProgressIndicator': 'clips to shapes.pill: its own test below',
  'MinimalCircularProgressIndicator': 'a ring, round by meaning',
  'MinimalSlider': 'paints shapes.pill and a round thumb itself',
  'MinimalRating': 'painted stars',
  'MinimalBarChart': 'a chart: data marks',
  'MinimalSparkline': 'a chart line',
  'MinimalHeatmap': 'a chart: data cells',
  'MinimalLineChart': 'a chart: its readout card is shapes.small',
  'MinimalAreaChart': 'a chart: its readout card is shapes.small',
  'MinimalPieChart': 'a chart: a ring',
  'MinimalSegmentBar': 'a data bar of day cells',
  'MinimalWeekDots': 'data dots',
  'MinimalStat': 'a cell of the KPI strip',
  'MinimalStatRow': 'lays out stat tiles',
  'MinimalLoadingState': 'a centred state',
  'MinimalErrorState': 'a centred state',
  'MinimalEmptyState': 'a centred state',
  'MinimalStatusView': 'the four centred states by name',
  'MinimalTooltip': 'an overlay: its body is shapes.small',
  'MinimalMenu': 'opens a menu card on shapes.medium',
  'MinimalCommand': 'a palette of rows on shapes.small',
  'MinimalBottomSheet': 'a sheet on shapes.large',
  'MinimalSheetFooter': 'the sheet footer band',
  'MinimalActionSheet': 'a floating sheet on shapes.large',
  'MinimalSelect': 'a full-bleed form row that opens a menu or a sheet',
  'MinimalSelectionList': 'rows of a select sheet',
  'MinimalChoiceRow': 'a selectable row',
  'MinimalSelectionGroup': 'lays out choice rows',
  'MinimalRadioGroup': 'lays out radios',
  'MinimalTimePicker': 'the date picker in time mode',
  'MinimalFileUpload': 'a dashed outline on shapes.medium',
  'MinimalSearchEntry': 'a search row on shapes.small',
  'MinimalComposer': 'a message box on shapes.small',
  'MinimalComposerAction': 'a composer button',
  'MinimalComposerLayout': 'lays out a composer',
  'MinimalSignInButton': 'a provider button',
  'MinimalSignInStack': 'lays out sign-in buttons',
  'MinimalTable': 'rows and columns',
  'MinimalSwipeActions': 'a row with actions behind it',
  'MinimalDismissible': 'a row that swipes away',
  'MinimalMediaImage': 'the picture inside MinimalMedia',
  'MinimalInputOtp': 'cells of shapes.small, each group split like a strip',
  'MinimalRangeSlider': 'paints shapes.pill and round thumbs itself',
  'MinimalFormField': 'a label, help and error round a field',
  'MinimalForm': 'checks the fields inside it',
  'MinimalDataTable': 'rows and columns; its checkboxes are shapes.mark',
  'MinimalCarouselView': 'clips each slide to shapes.medium',
  'MinimalReorderableListView': 'rows; a lifted row is shapes.small',
  'MinimalRefreshIndicator': 'a bare mark over a list, no frame',
  'MinimalTreeView': 'rows; the press wash is shapes.small',
  'MinimalSheet': 'a side panel: shapes.large on its inner corners only',
  'MinimalPopover': 'an overlay: its card is shapes.medium',
  'MinimalHoverCard': 'an overlay: its card is shapes.medium',
  'MinimalScrollArea': 'a scroll region; its focus ring is shapes.small',
  'MinimalResizable': 'two panes and a divider; its grip is shapes.mark',
  'MinimalToaster': 'hosts the toasts; each is a MinimalSnackBar',
  'MinimalInventoryGallery': 'lists the inventory',
};

/// Every public widget class the library declares, outside its internals.
Set<String> _declared() {
  final declared = RegExp(
    r'^class (Minimal\w+)(?:<[^>]*>)? extends '
    r'(?:StatelessWidget|StatefulWidget|SingleChildRenderObjectWidget)\b',
    multiLine: true,
  );
  final root = Directory('lib/src/minimal');
  // Internals, and the sections the host app composes beside the look
  // (patterns, kit parts), which the package does not export.
  final skip = ['internal', 'patterns', 'kit_parts'];
  return {
    for (final file in root.listSync(recursive: true).whereType<File>())
      if (file.path.endsWith('.dart') &&
          !skip.any(
            (dir) => file.path.contains(
              '${Platform.pathSeparator}$dir${Platform.pathSeparator}',
            ),
          ))
        for (final m in declared.allMatches(file.readAsStringSync()))
          m.group(1)!,
  };
}

/// Every text span under [root] whose style is Flutter's fallback.
List<String> _fallbackText(RenderObject root) {
  final found = <String>[];
  void visit(RenderObject r) {
    if (r is RenderParagraph) {
      r.text.visitChildren((span) {
        final style = span.style;
        if (style != null &&
            style.decorationStyle == TextDecorationStyle.double &&
            (style.decoration?.contains(TextDecoration.underline) ?? false)) {
          found.add(span.toPlainText());
        }
        return true;
      });
    }
    r.visitChildren(visit);
  }

  visit(root);
  return found;
}

/// What a box paints, as lines: the canvas calls and every text's words
/// and colour.
List<String> _record(RenderObject root) {
  final canvas = TestRecordingCanvas();
  root.paint(TestRecordingPaintingContext(canvas), Offset.zero);
  String describe(Object? v) => v is Path ? '${v.getBounds()}' : '$v';
  final out = <String>[
    for (final i in canvas.invocations)
      '${i.invocation.memberName}'
          '(${i.invocation.positionalArguments.map(describe).join(', ')})',
  ];
  void visit(RenderObject r) {
    if (r is RenderParagraph) {
      out.add('text ${r.text.toPlainText()} ${r.text.style?.color}');
    }
    r.visitChildren(visit);
  }

  visit(root);
  return out;
}

/// How far in from [from], stepping by [step], [path] begins.
double _enters(Path path, Offset from, Offset step) {
  for (var i = 0; i < 2000; i++) {
    if (path.contains(from + step * (i * 0.02))) return i * 0.02;
  }
  return double.nan;
}

/// A part of the review's state matrix, switched by its own controls:
/// [build] with `enabled: false` is its disabled cell and with an `error`
/// its error cell. [press] is where a finger lands for its pressed cell
/// (null: no pressed look of its own, as text you type into, which a press
/// focuses; [slides]: the press is a held drag, as a slider's thumb's);
/// [disables] and [errs] say whether it has those cells at all.
typedef _Stated = ({
  Widget Function({bool enabled, String? error}) build,
  Offset Function(WidgetTester tester, Finder part)? press,
  bool slides,
  bool disables,
  bool errs,
});

_Stated _stated(
  Widget Function({bool enabled, String? error}) build, {
  Offset Function(WidgetTester tester, Finder part)? press = _centre,
  bool slides = false,
  bool disables = true,
  bool errs = false,
}) => (
  build: build,
  press: press,
  slides: slides,
  disables: disables,
  errs: errs,
);

Offset _centre(WidgetTester tester, Finder part) => tester.getCenter(part);

/// A press on the item of the part that reads [text] (the chosen one).
Offset Function(WidgetTester tester, Finder part) _onText(String text) =>
    (tester, part) =>
        tester.getCenter(find.descendant(of: part, matching: find.text(text)));

/// What the part under [_part] paints, pixel for pixel, and its size.
Future<({Size size, int width, List<int> rgba})> _pixels(
  WidgetTester tester,
) async {
  final box = tester.renderObject<RenderRepaintBoundary>(
    find
        .descendant(
          of: find.byKey(_part),
          matching: find.byType(RepaintBoundary),
        )
        .first,
  );
  final shot = await tester.runAsync(() async {
    final image = await box.toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final width = image.width;
    image.dispose();
    return (width: width, rgba: data!.buffer.asUint8List().toList());
  });
  return (size: box.size, width: shot!.width, rgba: shot.rgba);
}

bool _same(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Geist's cap height over its em: the capitals Minimal centres a line by.
const double _capHeight = 0.710;

/// Where the capitals of the line under [root] (its editable, or its
/// paragraph) are drawn, their middle in global coordinates: the baseline on
/// the whole logical pixel the engine puts it on, the capitals' height above
/// it, wherever the line is painted (a cap label moves what it paints).
double _capitalsMiddle(RenderObject root) {
  RenderBox? line;
  void visit(RenderObject node) {
    if (line != null) return;
    if (node is RenderEditable || node is RenderParagraph) {
      line = node as RenderBox;
      return;
    }
    node.visitChildren(visit);
  }

  visit(root);
  final box = line!;
  // The size the first words are set in, the spans' styles merged down to
  // them (an empty line's own style's), as ui_core reads it.
  double? sizeOf(InlineSpan? span, [TextStyle? inherited]) {
    if (span == null) return null;
    final own = inherited == null ? span.style : inherited.merge(span.style);
    if (span is TextSpan) {
      if (span.text?.isNotEmpty ?? false) return own?.fontSize;
      for (final child in span.children ?? const <InlineSpan>[]) {
        final found = sizeOf(child, own);
        if (found != null) return found;
      }
    }
    return inherited == null ? own?.fontSize : null;
  }

  final (size, scaler) = switch (box) {
    final RenderParagraph p => (sizeOf(p.text), p.textScaler),
    final RenderEditable e => (sizeOf(e.text), e.textScaler),
    _ => (null, TextScaler.noScaling),
  };
  final fontSize = scaler.scale(size ?? 14);
  final laid = box.getDryBaseline(box.constraints, TextBaseline.alphabetic)!;
  final baseline = (laid + 0.5).floorToDouble();
  return box.localToGlobal(Offset(0, baseline - _capHeight * fontSize / 2)).dy;
}

void main() {
  test('every exported widget is in the shape contract', () {
    final declared = _declared();
    expect(declared, isNotEmpty);
    final listed = {..._framed.keys, ..._frameless.keys};
    expect(
      declared.difference(listed).toList()..sort(),
      isEmpty,
      reason:
          'a new widget goes in _framed with the step its role draws, or in '
          '_frameless with the reason it draws no frame',
    );
  });

  for (final MapEntry(key: family, value: shapes) in _families.entries) {
    group('under $family corners', () {
      final theme = _look.copyWith(shapes: shapes);
      for (final MapEntry(key: name, value: c) in _framed.entries) {
        testWidgets('$name draws its step', (tester) async {
          await tester.pumpWidget(_host(c.build(), theme));
          await tester.pump(const Duration(milliseconds: 300));
          final want = _outline(c.step(shapes));
          expect(_frames(tester, rim: c.rim), contains(want), reason: name);
          if (c.highlight) {
            expect(_highlight(tester), want, reason: '$name highlight');
          }
          expect(tester.takeException(), isNull);
        });
      }

      testWidgets('MinimalLinearProgressIndicator clips to the pill', (
        tester,
      ) async {
        await tester.pumpWidget(
          _host(
            const SizedBox(
              width: 200,
              child: MinimalLinearProgressIndicator(value: 0.4, label: 'Up'),
            ),
            theme,
          ),
        );
        final clip = tester.widget<ClipPath>(
          find.descendant(
            of: find.byKey(_part),
            matching: find.byType(ClipPath),
          ),
        );
        expect(
          _outline((clip.clipper! as ShapeBorderClipper).shape),
          _outline(shapes.pill),
        );
      });
    });
  }

  group('a nested outline is its frame moved by one distance', () {
    for (final MapEntry(key: family, value: shapes) in _families.entries) {
      for (final (step, outer) in [
        ('mark', shapes.mark),
        ('small', shapes.small),
        ('medium', shapes.medium),
        ('large', shapes.large),
        ('pill', shapes.pill),
      ]) {
        for (final d in const [2.0, 4.0]) {
          test('$family $step, $d px in', () {
            const rect = Rect.fromLTWH(0, 0, 160, 44);
            final inner = MinimalShapes.inset(outer, d);
            final a = outer.getOuterPath(rect);
            final b = inner.getOuterPath(rect.deflate(d));
            final edge =
                _enters(b, rect.topCenter, const Offset(0, 1)) -
                _enters(a, rect.topCenter, const Offset(0, 1));
            expect(edge, closeTo(d, 0.5), reason: 'at the middle of an edge');
            final r = MinimalShapes.radiusOf(outer).clamp(0.0, rect.height / 2);
            if (r > d) {
              // Around a round corner the gap holds along the diagonal too.
              const step = Offset(1, 1);
              final diagonal =
                  (_enters(b, rect.topLeft, step) -
                      _enters(a, rect.topLeft, step)) *
                  math.sqrt2;
              expect(diagonal, closeTo(d, 0.5), reason: 'along the diagonal');
            } else {
              expect(
                MinimalShapes.radiusOf(inner),
                MinimalShapes.radiusOf(outer) == MinimalShapes.fullRadius
                    ? MinimalShapes.fullRadius
                    : 0,
                reason: 'a square corner stays square',
              );
            }
          });
        }
      }
    }
  });

  group('no text falls back to the unstyled underline', () {
    testWidgets('every framed part under a bare WidgetsApp', (tester) async {
      for (final MapEntry(key: name, value: c) in _framed.entries) {
        await tester.pumpWidget(
          WidgetsApp(
            color: const Color(0xFFFFFFFF),
            pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
              settings: settings,
              pageBuilder: (context, _, _) => builder(context),
            ),
            builder: (context, navigator) =>
                MinimalTheme(data: _look, child: navigator!),
            home: Center(child: c.build()),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));
        tester.takeException();
        expect(
          _fallbackText(tester.renderObject(find.byType(WidgetsApp))),
          isEmpty,
          reason: name,
        );
      }
    });

    testWidgets('every overlay a part opens', (tester) async {
      late BuildContext at;
      await tester.pumpWidget(
        _host(
          Builder(
            builder: (context) {
              at = context;
              return const MinimalTooltip(
                message: 'Archive',
                child: MinimalIconButton(
                  LucideIcons.archive,
                  label: 'Archive',
                  onPressed: _tap,
                ),
              );
            },
          ),
          _look,
        ),
      );
      Future<void> check(String what) async {
        await tester.pumpAndSettle();
        expect(
          _fallbackText(tester.renderObject(find.byType(MaterialApp))),
          isEmpty,
          reason: what,
        );
      }

      await tester.longPress(find.byType(MinimalIconButton));
      await check('tooltip');
      showMinimalSnackBar(at, 'Saved');
      await check('toast');
      showMinimalBottomSheet<void>(
        at,
        title: 'Sheet',
        builder: (_) => const Text('Body'),
      );
      await check('sheet');
      Navigator.of(at).pop();
      await tester.pumpAndSettle();
      showMinimalActionSheet(
        at,
        title: 'Photo',
        actions: [MinimalActionSheetAction('Share', onPressed: () {})],
      );
      await check('action sheet');
      // The toast and the tooltip time out.
      await tester.pump(const Duration(seconds: 10));
      await tester.pumpAndSettle();
    });
  });

  group('a hovering pointer changes nothing', () {
    final parts = <String, Widget>{
      for (final name in const [
        'MinimalChip',
        'MinimalFilter',
        'MinimalPropertyPill',
        'MinimalCheckbox',
        'MinimalRadio',
        'MinimalSwitch',
        'MinimalSegmentedButton',
        'MinimalDatePicker',
        'MinimalButtonGroup',
        'MinimalPagination',
        'MinimalToggleGroup',
        'MinimalSplitButton',
        'MinimalColorPicker',
        'MinimalCalendar',
        'MinimalDateRangePicker',
        'MinimalMenuBar',
      ])
        name: _framed[name]!.build(),
      'MinimalLink': const MinimalLink('Docs', onPressed: _tap),
      'MinimalPageDots': MinimalPageDots(
        count: 3,
        selectedIndex: 1,
        onChanged: (_) {},
      ),
      'MinimalDisclosure': const SizedBox(
        width: 300,
        child: MinimalDisclosure(title: 'Advanced', child: Text('More')),
      ),
      'MinimalBanner': MinimalBanner(title: 'Heads up', onDismissed: () {}),
      'MinimalDataTable': SizedBox(
        width: 400,
        child: MinimalDataTable<String>(
          rows: const ['Ana Souza', 'Ben Okafor'],
          columns: [MinimalDataColumn<String>('Customer', value: (r) => r)],
        ),
      ),
      'MinimalTreeView': SizedBox(
        width: 300,
        child: MinimalTreeView<String>(
          roots: const ['lib', 'test'],
          childrenOf: (n) => n == 'lib' ? const ['main.dart'] : const [],
          labelOf: (n) => n,
          initiallyExpanded: const ['lib'],
        ),
      ),
      'MinimalReorderableListView': SizedBox(
        width: 300,
        child: MinimalReorderableListView<String>(
          items: const ['Warm up', 'Stretch'],
          labelOf: (s) => s,
          onReorder: (_, _) {},
          itemBuilder: (context, s) => Text(s),
        ),
      ),
      'MinimalCarouselView': const SizedBox(
        width: 300,
        child: MinimalCarouselView(
          height: 120,
          children: [Text('One'), Text('Two')],
        ),
      ),
    };
    for (final MapEntry(key: name, value: part) in parts.entries) {
      testWidgets(name, (tester) async {
        await tester.pumpWidget(_host(RepaintBoundary(child: part), _look));
        await tester.pump(const Duration(milliseconds: 300));
        final box = tester.renderObject(
          find
              .descendant(
                of: find.byKey(_part),
                matching: find.byType(RepaintBoundary),
              )
              .first,
        );
        final idle = _record(box);
        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await mouse.addPointer(location: Offset.zero);
        addTearDown(mouse.removePointer);
        await mouse.moveTo(tester.getCenter(find.byKey(_part)));
        await tester.pump(const Duration(milliseconds: 300));
        expect(_record(box), idle);
      });
    }
  });

  // coverage4 (11-10 05:30): a disabled part reads as disabled, a pressed one
  // as pressed and a wrong one as wrong, and none moves the layout.
  group('a state cell shows its state, at idle\'s size', () {
    Widget sized(Widget child) => SizedBox(width: 156, child: child);
    final parts = <String, _Stated>{
      for (final v in MinimalButtonVariant.values)
        'MinimalButton ${v.name}': _stated(
          ({enabled = true, error}) => MinimalButton(
            'Save',
            variant: v,
            onPressed: enabled ? _tap : null,
          ),
        ),
      for (final v in MinimalIconButtonVariant.values)
        'MinimalIconButton ${v.name}': _stated(
          ({enabled = true, error}) => MinimalIconButton(
            LucideIcons.x,
            label: 'Close',
            variant: v,
            onPressed: enabled ? _tap : null,
          ),
        ),
      'MinimalChip': _stated(
        ({enabled = true, error}) =>
            MinimalChip('Open', onPressed: enabled ? _tap : null),
      ),
      'MinimalFilter': _stated(
        ({enabled = true, error}) =>
            MinimalFilter('Open', count: 2, onPressed: enabled ? _tap : null),
      ),
      'MinimalCheckbox': _stated(
        ({enabled = true, error}) => MinimalCheckbox(
          value: false,
          label: 'Agree',
          onChanged: enabled ? (_) {} : null,
        ),
      ),
      'MinimalRadio': _stated(
        ({enabled = true, error}) => MinimalRadio(
          selected: false,
          enabled: enabled,
          label: 'Pro',
          onPressed: _tap,
        ),
      ),
      'MinimalSwitch': _stated(
        ({enabled = true, error}) => MinimalSwitch(
          value: false,
          label: 'Alerts',
          onChanged: enabled ? (_) {} : null,
        ),
      ),
      'MinimalSegmentedButton': _stated(
        ({enabled = true, error}) => sized(
          MinimalSegmentedButton<int>(
            segments: const [
              MinimalButtonSegment(0, 'Day'),
              MinimalButtonSegment(1, 'Wk'),
              MinimalButtonSegment(2, 'Mo'),
            ],
            value: 0,
            label: 'Range',
            onChanged: enabled ? (_) {} : null,
          ),
        ),
      ),
      'MinimalTabBar': _stated(
        ({enabled = true, error}) => sized(
          MinimalTabBar(
            tabs: const ['Open', 'Done', 'All'],
            selectedIndex: 0,
            onChanged: enabled ? (_) {} : null,
          ),
        ),
      ),
      'MinimalTextField': _stated(
        ({enabled = true, error}) => sized(
          MinimalTextField(
            label: 'Name',
            hint: 'Ana Ruiz',
            enabled: enabled,
            error: error,
          ),
        ),
        press: null,
        errs: true,
      ),
      'MinimalSelect': _stated(
        ({enabled = true, error}) => sized(
          MinimalSelect<String>(
            label: 'Plan',
            value: 'pro',
            options: const [
              MinimalSelectOption('free', 'Free'),
              MinimalSelectOption('pro', 'Pro'),
            ],
            onChanged: enabled ? (_) {} : null,
          ),
        ),
      ),
      'MinimalNumberField': _stated(
        ({enabled = true, error}) => MinimalNumberField(
          value: 2,
          min: 0,
          max: 9,
          label: 'Guests',
          onChanged: enabled ? (_) {} : null,
        ),
        // On its + button: the value between the buttons takes no press.
        press: (tester, part) => tester.getCenter(
          find
              .descendant(of: part, matching: find.byType(MinimalPressable))
              .last,
        ),
      ),
      'MinimalSlider': _stated(
        ({enabled = true, error}) => sized(
          MinimalSlider(
            label: 'Volume',
            value: 0.5,
            onChanged: enabled ? (_) {} : null,
          ),
        ),
      ),
      'MinimalDatePicker': _stated(
        ({enabled = true, error}) => sized(
          MinimalDatePicker(
            label: 'Due',
            value: DateTime(2026, 11, 9, 9, 30),
            onChanged: enabled ? (_) {} : null,
          ),
        ),
      ),
      'MinimalRating': _stated(
        ({enabled = true, error}) => MinimalRating(
          value: 2,
          label: 'Rating',
          onChanged: enabled ? (_) {} : null,
        ),
        // With no onChanged a rating is a score shown, not a control
        // switched off: it has no disabled cell.
        disables: false,
      ),
      'MinimalLink': _stated(
        ({enabled = true, error}) =>
            MinimalLink('Terms', onPressed: enabled ? _tap : null),
      ),
      'MinimalListTile': _stated(
        ({enabled = true, error}) => sized(
          MinimalListTile(
            title: 'Inbox',
            chevron: true,
            enabled: enabled,
            onTap: _tap,
          ),
        ),
      ),
      'MinimalToggleGroup': _stated(
        ({enabled = true, error}) => MinimalToggleGroup<String>(
          label: 'Text style',
          multiple: true,
          allowEmpty: true,
          selected: const {},
          onChanged: enabled ? (_) {} : null,
          items: const [
            MinimalToggleItem('b', label: 'B'),
            MinimalToggleItem('i', label: 'I'),
            MinimalToggleItem('u', label: 'U'),
          ],
        ),
      ),
      // Pressed while chosen (round 4). Every part above is pressed while it
      // is off, so a chosen fill that swallowed the press went through: the
      // review's "ToggleGroup on" row showed a pressed bold item equal to
      // idle (its press had landed on the seam between two items). Each of
      // these presses the chosen item itself.
      'MinimalToggleGroup on': _stated(
        ({enabled = true, error}) => MinimalToggleGroup<String>(
          label: 'Text style',
          multiple: true,
          allowEmpty: true,
          selected: const {'b'},
          onChanged: enabled ? (_) {} : null,
          items: const [
            MinimalToggleItem('b', label: 'B'),
            MinimalToggleItem('i', label: 'I'),
          ],
        ),
        press: _onText('B'),
      ),
      'MinimalChip chosen': _stated(
        ({enabled = true, error}) => MinimalChip(
          'Open',
          selected: true,
          onPressed: enabled ? _tap : null,
        ),
      ),
      'MinimalFilter chosen': _stated(
        ({enabled = true, error}) => MinimalFilter(
          'Open',
          count: 2,
          selected: true,
          onPressed: enabled ? _tap : null,
        ),
      ),
      'MinimalSegmentedButton chosen': _stated(
        ({enabled = true, error}) => sized(
          MinimalSegmentedButton<int>(
            segments: const [
              MinimalButtonSegment(0, 'Day'),
              MinimalButtonSegment(1, 'Wk'),
              MinimalButtonSegment(2, 'Mo'),
            ],
            value: 0,
            label: 'Range',
            onChanged: enabled ? (_) {} : null,
          ),
        ),
        press: _onText('Day'),
      ),
      'MinimalTabBar chosen': _stated(
        ({enabled = true, error}) => sized(
          MinimalTabBar(
            tabs: const ['Open', 'Done', 'All'],
            selectedIndex: 0,
            onChanged: enabled ? (_) {} : null,
          ),
        ),
        press: _onText('Open'),
      ),
      'MinimalCheckbox on': _stated(
        ({enabled = true, error}) => MinimalCheckbox(
          value: true,
          label: 'Agree',
          onChanged: enabled ? (_) {} : null,
        ),
      ),
      'MinimalRadio on': _stated(
        ({enabled = true, error}) => MinimalRadio(
          selected: true,
          enabled: enabled,
          label: 'Pro',
          onPressed: _tap,
        ),
      ),
      'MinimalSwitch on': _stated(
        ({enabled = true, error}) => MinimalSwitch(
          value: true,
          label: 'Alerts',
          onChanged: enabled ? (_) {} : null,
        ),
      ),
      'MinimalListTile selected': _stated(
        ({enabled = true, error}) => sized(
          MinimalListTile(
            title: 'Inbox',
            chevron: true,
            selected: true,
            enabled: enabled,
            onTap: _tap,
          ),
        ),
      ),
      'MinimalSplitButton': _stated(
        ({enabled = true, error}) => MinimalSplitButton(
          'Save',
          onPressed: enabled ? _tap : null,
          actions: enabled
              ? const [MinimalMenuItem('Save as…', onPressed: _tap)]
              : const [],
        ),
      ),
      'MinimalInputGroup': _stated(
        ({enabled = true, error}) => sized(
          MinimalInputGroup(
            hint: 'site',
            prefixText: 'https://',
            enabled: enabled,
            error: error,
          ),
        ),
        press: null,
        errs: true,
      ),
      'MinimalPasswordField': _stated(
        ({enabled = true, error}) => sized(
          MinimalPasswordField(
            hint: 'Password',
            enabled: enabled,
            error: error,
          ),
        ),
        press: null,
        errs: true,
      ),
      'MinimalInputOtp': _stated(
        ({enabled = true, error}) => MinimalInputOtp(
          length: 4,
          label: 'Code',
          enabled: enabled,
          error: error,
        ),
        press: null,
        errs: true,
      ),
      'MinimalCombobox': _stated(
        ({enabled = true, error}) => sized(
          MinimalCombobox<String>(
            options: const ['Lisbon', 'London'],
            hint: 'City',
            enabled: enabled,
            error: error,
            onSelected: (_) {},
          ),
        ),
        press: null,
        errs: true,
      ),
      'MinimalRangeSlider': _stated(
        ({enabled = true, error}) => sized(
          MinimalRangeSlider(
            label: 'Price',
            showLabel: false,
            values: const DesignRangeValues(0.2, 0.7),
            onChanged: enabled ? (_) {} : null,
          ),
        ),
        // On the start thumb (its 44 px target's centre runs 22 px in from
        // either end), held in a drag: ui_core presses a thumb while it is
        // dragged.
        press: (tester, part) {
          final r = tester.getRect(part);
          return Offset(r.left + 22 + 0.2 * (r.width - 44), r.center.dy);
        },
        slides: true,
      ),
      // A card without onPressed is static, not switched off.
      'MinimalCard': _stated(
        ({enabled = true, error}) => const SizedBox(
          width: 140,
          child: MinimalCard(onPressed: _tap, child: Text('Plan')),
        ),
        disables: false,
      ),
    };

    // Both appearances: a wash that reads on a light face can vanish on the
    // dark appearance's pale one.
    final looks = {
      'light': _look,
      'dark': MinimalThemeData.preset('standard', Brightness.dark),
    };
    for (final MapEntry(key: name, value: part) in parts.entries) {
      for (final MapEntry(key: appearance, value: look) in looks.entries) {
        testWidgets('$name, $appearance', (tester) async {
          Future<({Size size, int width, List<int> rgba})> cell(
            Widget child,
          ) async {
            await tester.pumpWidget(const SizedBox());
            await tester.pumpWidget(_host(RepaintBoundary(child: child), look));
            await tester.pump(const Duration(milliseconds: 400));
            return _pixels(tester);
          }

          final idle = await cell(part.build());
          final press = part.press;
          if (press != null) {
            final finger = await tester.startGesture(
              press(tester, find.byKey(_part)),
            );
            if (part.slides) {
              // Past the slop and back: a drag that leaves the value as it was.
              await finger.moveBy(const Offset(kTouchSlop + 4, 0));
              await tester.pump();
              await finger.moveBy(const Offset(-(kTouchSlop + 4), 0));
            }
            await tester.pump(const Duration(milliseconds: 150));
            await tester.pump(const Duration(milliseconds: 400));
            final pressed = await _pixels(tester);
            await finger.cancel();
            expect(
              pressed.size,
              idle.size,
              reason: 'pressed keeps idle\'s size',
            );
            expect(
              _same(pressed.rgba, idle.rgba),
              isFalse,
              reason: 'pressed looks pressed',
            );
          }
          if (part.disables) {
            final off = await cell(part.build(enabled: false));
            expect(off.size, idle.size, reason: 'disabled keeps idle\'s size');
            expect(
              _same(off.rgba, idle.rgba),
              isFalse,
              reason: 'disabled looks disabled',
            );
          }
          if (part.errs) {
            final wrong = await cell(part.build(error: 'Required'));
            // The part keeps its width and its place; its message adds below.
            expect(wrong.size.width, idle.size.width, reason: 'error width');
            expect(
              wrong.size.height,
              greaterThanOrEqualTo(idle.size.height),
              reason: 'an error only adds below',
            );
            expect(
              _same(wrong.rgba.sublist(0, idle.rgba.length), idle.rgba),
              isFalse,
              reason: 'the part itself looks wrong, not just its message',
            );
          }
        }, tags: 'goldens');
      }
    }
  });

  testWidgets('every pressable shows the click cursor', (tester) async {
    for (final MapEntry(key: name, value: c) in _framed.entries) {
      if (!c.highlight) continue;
      await tester.pumpWidget(_host(c.build(), _look));
      final detector = tester.widget<FocusableActionDetector>(
        find
            .descendant(
              of: find.byKey(_part),
              matching: find.byType(FocusableActionDetector),
            )
            .first,
      );
      expect(detector.mouseCursor, SystemMouseCursors.click, reason: name);
    }
  });

  group('labels in a row share one centre line', () {
    double centre(WidgetTester tester, String text) =>
        _capitalsMiddle(tester.renderObject(find.text(text)));

    testWidgets('an action row', (tester) async {
      await tester.pumpWidget(
        _host(
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              MinimalButton(
                'Cancel',
                variant: MinimalButtonVariant.secondary,
                onPressed: _tap,
              ),
              MinimalGap(MinimalSpacing.s8),
              MinimalButton('Save', onPressed: _tap),
            ],
          ),
          _look,
        ),
      );
      expect(centre(tester, 'Cancel'), closeTo(centre(tester, 'Save'), 0.5));
      expect(
        tester.getSize(find.byType(MinimalButton).first).height,
        tester.getSize(find.byType(MinimalButton).last).height,
      );
    });

    testWidgets('a button group', (tester) async {
      await tester.pumpWidget(
        _host(_framed['MinimalButtonGroup']!.build(), _look),
      );
      final group = tester.getRect(find.byType(MinimalButtonGroup));
      expect(centre(tester, 'Day'), closeTo(centre(tester, 'Week'), 0.5));
      expect(centre(tester, 'Day'), closeTo(group.center.dy, 1));
    });

    testWidgets('a segmented control', (tester) async {
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 240,
            child: _framed['MinimalSegmentedButton']!.build(),
          ),
          _look,
        ),
      );
      final track = tester.getRect(find.byType(MinimalSegmentedButton<int>));
      expect(centre(tester, 'Day'), closeTo(centre(tester, 'Week'), 0.5));
      expect(centre(tester, 'Day'), closeTo(track.center.dy, 1));
    });

    testWidgets('a tab bar', (tester) async {
      await tester.pumpWidget(
        _host(
          MinimalTabBar(
            tabs: const ['Open', 'Closed', 'All'],
            selectedIndex: 0,
            onChanged: (_) {},
          ),
          _look,
        ),
      );
      expect(centre(tester, 'Open'), closeTo(centre(tester, 'Closed'), 0.5));
      expect(centre(tester, 'Open'), closeTo(centre(tester, 'All'), 0.5));
    });

    testWidgets('pagination', (tester) async {
      await tester.pumpWidget(
        _host(
          SizedBox(width: 480, child: _framed['MinimalPagination']!.build()),
          _look,
        ),
      );
      expect(centre(tester, '1'), closeTo(centre(tester, '3'), 0.5));
      expect(centre(tester, '3'), closeTo(centre(tester, '9'), 0.5));
    });
  });
}
