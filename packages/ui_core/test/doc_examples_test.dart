// Every doc example in lib, compiled and run. Each `/// Example:` (a fenced
// dart block in the package) is written out below as the body of an entry,
// so an example that stops compiling fails analysis; the first test fails
// when lib has an example this file lacks; the rest build each widget
// example (and push each route, run each call) in a bare app.
//
// An example may name `controller` or `focusNode`: the caller's own, which
// its entry makes first, as the docs say the caller does.
import 'dart:io';

import 'package:flutter/material.dart'
    show DefaultMaterialLocalizations, Material, TextField;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/alignment.dart';
import 'package:ui_core/ui_core.dart';
import 'package:ui_core/host.dart';
import 'package:ui_core/inventory.dart';

import 'behaviour_harness.dart';

/// What the caller made for an example, disposed once its tree is gone.
final List<VoidCallback> _disposers = [];

T _own<T extends ChangeNotifier>(T value) {
  _disposers.add(value.dispose);
  return value;
}

typedef _Example = Object? Function(BuildContext context);

final Map<String, _Example> _examples = {
  'DesignControlBox': (context) =>
      const DesignControlBox(minHeight: 40, child: Text('Save')),
  'DesignTextEntryBox': (context) {
    final controller = _own(TextEditingController());
    return Localizations(
      locale: const Locale('en'),
      delegates: const [
        DefaultMaterialLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
      child: Material(
        child: DesignTextEntryBox(
          minHeight: 40,
          controller: controller,
          hint: const Text('Search'),
          child: TextField(controller: controller, decoration: null),
        ),
      ),
    );
  },
  'DefaultDesignLocalizations': (context) =>
      const DefaultDesignLocalizations().carouselSlideLabel(0, 3),
  'DesignAnchoredOverlay': (context) => DesignAnchoredOverlay(
    anchorBuilder: (context, anchor) =>
        GestureDetector(onTap: anchor.toggle, child: const Text('More')),
    overlayBuilder: (context, info) => const Text('Details'),
  ),
  'DesignCalendar': (context) {
    final controller = _own(
      DesignCalendarController(
        firstDate: DateTime(2026),
        lastDate: DateTime(2027),
      ),
    );
    return DesignCalendar(
      controller: controller,
      dayBuilder: (context, day, states) => Text('${day.date.day}'),
    );
  },
  'DesignCalendarController': (context) => _own(
    DesignCalendarController(
      firstDate: DateTime(2026),
      lastDate: DateTime(2027),
    ),
  ),
  'DesignCarousel': (context) => DesignCarousel(
    itemCount: 3,
    itemBuilder: (context, index) => Text('Slide $index'),
  ),
  'DesignColorArea': (context) {
    final controller = _own(DesignColorController());
    return DesignColorArea(
      controller: controller,
      builder: (context, area) => const SizedBox.expand(),
      thumbBuilder: (context, area) => const SizedBox(width: 16, height: 16),
    );
  },
  'DesignColorController': (context) =>
      _own(DesignColorController(const Color(0xFF3366FF))),
  'DesignColorPicker': (context) {
    final controller = _own(DesignColorController());
    return DesignColorPicker(
      controller: controller,
      areaBuilder: (context, area) => const SizedBox.expand(),
      areaThumbBuilder: (context, area) =>
          const SizedBox(width: 16, height: 16),
      trackBuilder: (context, channel, color) => const SizedBox(height: 8),
      thumbBuilder: (context, states) => const SizedBox(width: 16, height: 16),
    );
  },
  'DesignColorSlider': (context) {
    final controller = _own(DesignColorController());
    return DesignColorSlider(
      controller: controller,
      channel: DesignColorChannel.hue,
      trackBuilder: (context, channel, color) => const SizedBox(height: 8),
      thumbBuilder: (context, states) => const SizedBox(width: 16, height: 16),
    );
  },
  'DesignCombobox': (context) => DesignCombobox<String>(
    options: const ['Apple', 'Pear'],
    fieldBuilder: (context, field) => EditableText(
      controller: field.controller,
      focusNode: field.focusNode,
      style: const TextStyle(),
      cursorColor: const Color(0xFF000000),
      backgroundCursorColor: const Color(0xFF808080),
      onSubmitted: (_) => field.submit(),
    ),
    optionBuilder: (context, option, states) => Text(option),
  ),
  'DesignCommandPalette': (context) => DesignCommandPalette(
    commands: const [DesignCommand(label: 'New file')],
    fieldBuilder: (context, field) => EditableText(
      controller: field.controller,
      focusNode: field.focusNode,
      style: const TextStyle(),
      cursorColor: const Color(0xFF000000),
      backgroundCursorColor: const Color(0xFF808080),
    ),
    itemBuilder: (context, command, states) => Text(command.label),
  ),
  'DesignCommandShortcut': (context) =>
      DesignCommandShortcut(onOpen: () {}, child: const SizedBox()),
  'DesignDataTable': (context) {
    final controller = _own(
      DesignTableController<String>(
        rows: const ['a', 'b'],
        columns: [
          DesignTableColumn<String>(
            id: 'name',
            label: 'Name',
            sortKey: (row) => row,
          ),
        ],
      ),
    );
    return DesignDataTable<String>(
      controller: controller,
      headerBuilder: (context, column, sort, states) => Text(column.label),
      cellBuilder: (context, row, column) => Text(row),
      rowBuilder: (context, row, cells) => Row(children: cells),
    );
  },
  'DesignTableController': (context) => _own(
    DesignTableController<String>(
      rows: const ['a', 'b'],
      columns: [
        DesignTableColumn<String>(
          id: 'name',
          label: 'Name',
          sortKey: (row) => row,
        ),
      ],
    ),
  ),
  'DesignField': (context) => DesignField(
    labelText: 'Email',
    builder: (context, parts) =>
        Column(children: [?parts.label, parts.control]),
    child: const Text('field'),
  ),
  'DesignForm': (context) =>
      DesignForm(onSubmit: () {}, child: const SizedBox()),
  'DesignFormField': (context) => DesignFormField<String>(
    validator: (value) => (value ?? '').isEmpty ? 'Required' : null,
    builder: (field) => Text(field.errorText ?? ''),
  ),
  'DesignInputGroup': (context) {
    final focusNode = _own(FocusNode());
    return DesignInputGroup(
      focusNode: focusNode,
      builder: (context, states, child) => child,
      child: const Text('kg'),
    );
  },
  'DesignInventory': (context) => const DesignInventory(
    look: 'Comic',
    entries: [
      DesignInventoryEntry.absent(
        'FloatingActionButton',
        'A floating action button is Material vocabulary',
      ),
    ],
  ),
  'DesignInventoryEntry': (context) =>
      DesignInventoryEntry.present('Link', (context) => const Text('Terms')),
  'DesignMenuBar': (context) => DesignMenuBar(
    menus: [
      DesignMenuEntry(
        label: 'File',
        children: [DesignMenuEntry(label: 'New', onPressed: () {})],
      ),
    ],
    itemBuilder: (context, entry, level, states) => Text(entry.label),
    surfaceBuilder: (context, info, items) =>
        Column(mainAxisSize: MainAxisSize.min, children: items),
  ),
  'DesignOtpField': (context) => DesignOtpField(
    length: 4,
    slotBuilder: (context, slot) => Text(slot.character),
  ),
  'DesignOtpController': (context) => _own(DesignOtpController(length: 6)),
  'DesignPasswordReveal': (context) => DesignPasswordReveal(
    builder: (context, password) => Text(password.toggleLabel),
  ),
  'DesignPasswordController': (context) =>
      _own(DesignPasswordController(obscured: false)),
  'DesignPressable': (context) => DesignPressable(
    onPressed: () {},
    semanticLabel: 'Save',
    builder: (context, states, child) => Opacity(
      opacity: states.contains(WidgetState.pressed) ? 0.6 : 1,
      child: const Text('Save'),
    ),
  ),
  'DesignPullToRefresh': (context) => DesignPullToRefresh(
    onRefresh: () async {},
    indicatorBuilder: (context, details) => const SizedBox(height: 40),
    child: ListView(),
  ),
  'DesignRangeSlider': (context) => DesignRangeSlider(
    values: const DesignRangeValues(20, 80),
    max: 100,
    onChanged: (values) {},
    trackBuilder: (context, track) => const SizedBox(height: 4),
    thumbBuilder: (context, index, states) =>
        const SizedBox(width: 20, height: 20),
  ),
  'DesignReorderableList': (context) => DesignReorderableList<String>(
    items: const ['a', 'b'],
    onReorder: (from, to) {},
    labelOf: (item) => item,
    itemBuilder: (context, item, reorder) => reorder.handle(Text(item)),
  ),
  'DesignScrollArea': (context) {
    final controller = _own(ScrollController());
    return DesignScrollArea(
      controller: controller,
      thumbBuilder: (context, thumb) =>
          const ColoredBox(color: Color(0x66000000)),
      child: SingleChildScrollView(
        controller: controller,
        child: const Text('Terms'),
      ),
    );
  },
  'DesignSideSheetRoute': (context) => DesignSideSheetRoute<void>(
    builder: (context, sheet) => const SizedBox(width: 320),
  ),
  'DesignSplitButton': (context) => DesignSplitButton(
    label: 'Save',
    onPressed: () {},
    actions: [DesignSplitAction(label: 'Save as', onPressed: () {})],
    buttonBuilder: (context, part, states, open) => Text(part.name),
    itemBuilder: (context, action, states) => Text(action.label),
    surfaceBuilder: (context, info, items) =>
        Column(mainAxisSize: MainAxisSize.min, children: items),
  ),
  'DesignSplitView': (context) => DesignSplitView(
    first: const SizedBox(),
    second: const SizedBox(),
    dividerBuilder: (context, states, axis) =>
        const ColoredBox(color: Color(0xFFDDDDDD)),
  ),
  'DesignSwipeActions': (context) => DesignSwipeActions(
    endActions: [
      DesignSwipeAction(label: 'Delete', onPressed: () {}, destructive: true),
    ],
    actionBuilder: (context, action, details) => Text(action.label),
    child: const Text('Message'),
  ),
  'DesignTagInput': (context) => DesignTagInput<String>(
    values: const ['red'],
    onChanged: (values) {},
    onCreate: (text) => text,
    fieldBuilder: (context, field) => EditableText(
      controller: field.controller,
      focusNode: field.focusNode,
      style: const TextStyle(),
      cursorColor: const Color(0xFF000000),
      backgroundCursorColor: const Color(0xFF808080),
      onSubmitted: (_) => field.submit(),
    ),
    optionBuilder: (context, option, states) => Text(option),
    tagBuilder: (context, value, tag) => Text(value),
  ),
  'DesignToaster': (context) => DesignToaster(
    toastBuilder: (context, details) => Text(details.toast.message),
    child: const SizedBox(),
  ),
  'DesignToggleGroup': (context) => DesignToggleGroup<String>(
    options: const ['day', 'week'],
    selected: const {'day'},
    onSelectionChanged: (next) {},
    itemBuilder: (context, value, states) => Text(value),
  ),
  'DesignTree': (context) {
    final controller = _own(
      DesignTreeController<String>(
        roots: const ['src'],
        childrenOf: (node) => const [],
      ),
    );
    return DesignTree<String>(
      controller: controller,
      labelOf: (node) => node,
      rowBuilder: (context, item) => Text(item.row.node),
    );
  },
  'DesignTreeController': (context) => _own(
    DesignTreeController<String>(
      roots: const ['src'],
      childrenOf: (node) => const [],
    ),
  ),
  'DesignValueHandle': (context) => DesignValueHandle(
    value: 0.5,
    onChanged: (value) {},
    semanticLabel: 'Volume',
    builder: (context, states) => const SizedBox(width: 20, height: 20),
  ),
  'DisplayFormat': (context) => Text(DisplayFormat.money(129900)),
  'Localizations': (context) => Localizations(
    locale: const Locale('en'),
    delegates: const [
      DefaultDesignLocalizations.delegate,
      DefaultWidgetsLocalizations.delegate,
    ],
    child: Builder(
      builder: (context) => Text(DesignLocalizations.of(context).carouselLabel),
    ),
  ),
  'MediaSlotImage': (context) => const MediaSlotImage(
    slotId: 'hero',
    fallback: ColoredBox(color: Color(0xFFDDDDDD)),
  ),
  'DesignMotionPolicy': (context) {
    final controller = AnimationController(vsync: const TestVSync());
    _disposers.add(controller.dispose);
    return controller.springTo(
      1,
      DesignMotionPolicy.of(context).spatial(dampingRatio: 0.6, stiffness: 800),
    );
  },
  'PreviewFrame': (context) => PreviewFrame(
    platform: PreviewPlatform.ios,
    brightness: Brightness.dark,
    child: const Text('App'),
  ),
  'PreviewStage': (context) => PreviewStage(
    route: (context, page) => PageRouteBuilder<void>(
      pageBuilder: (context, animation, secondary) => page,
    ),
    child: const Text('Details'),
  ),
  'DesignKeylineRegion': (context) => DesignKeylineRegion(
    label: 'Settings',
    indents: const [40],
    child: const Text('Settings'),
  ),
  'DesignKeylineFace': (context) =>
      const DesignKeylineFace(child: SizedBox(width: 120, height: 40)),
  'DesignCapCenter': (context) =>
      const DesignCapCenter(capHeightFactor: 0.711, child: Text('Save')),
};

/// [DesignAlignmentMatrix.check]'s example: it takes a tester, so it is
/// compiled here and run by alignment_test.dart.
Future<void> _alignmentCheck(
  WidgetTester tester,
  DesignAlignmentMatrix matrix,
) async {
  final report = await matrix.check(
    pump: tester.pumpWidget,
    runAsync: tester.runAsync,
  );
  report.verify();
}

/// The screen [DesignKeylineCheck]'s example checks.
class SettingsScreen extends StatelessWidget {
  /// A screen.
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox();
}

/// [DesignKeylineCheck]'s example: it takes a tester, so it is compiled
/// here and run by keyline_test.dart.
Future<void> _keylineCheck(WidgetTester tester) async {
  final report = await const DesignKeylineCheck(look: 'Comic').check(
    tester.element(find.byType(SettingsScreen)),
    runAsync: tester.runAsync,
  );
  report.verify();
}

/// [DesignLabelCheck]'s example: it takes a tester, so it is compiled
/// here and run by label_check_test.dart.
Future<void> _labelCheck(WidgetTester tester) async {
  final report = await const DesignLabelCheck(look: 'Comic').check(
    tester.element(find.byType(SettingsScreen)),
    runAsync: tester.runAsync,
  );
  report.verify();
}

/// [DesignRowCheck]'s example, run by row_check_test.dart's shape.
Future<void> _rowCheck(WidgetTester tester) async {
  final report = await const DesignRowCheck(look: 'Comic').check(
    tester.element(find.byType(SettingsScreen)),
    runAsync: tester.runAsync,
  );
  report.verify();
}

/// [DesignWidthCheck]'s example, run by width_check_test.dart's shape.
Future<void> _widthCheck(WidgetTester tester, Key fieldKey) async {
  const widths = DesignWidthCheck(look: 'Comic');
  (await widths.check(
    tester.element(find.byType(SettingsScreen)),
    runAsync: tester.runAsync,
  )).verify();
  (await widths.checkList(
    tester.element(find.byKey(fieldKey)),
    runAsync: tester.runAsync,
  )).verify();
}

/// [DesignWordBreakCheck]'s and [DesignClipCheck]'s examples, run by
/// fit_check_test.dart's shape.
void _fitChecks(WidgetTester tester) {
  const DesignWordBreakCheck(look: 'Comic')
      .check(tester.element(find.byType(SettingsScreen)))
      .verify();
  const DesignClipCheck(look: 'Comic')
      .check(tester.element(find.byType(SettingsScreen)))
      .verify();
}

/// [DesignLabelCheck.checkDensities]'s example, run by
/// label_check_test.dart.
Future<void> _labelDensities(
  WidgetTester tester,
  Map<String, DesignAlignmentTheme> densities,
) async {
  final report = await const DesignLabelCheck(look: 'Comic').checkDensities(
    densities: densities,
    screen: (context) => const SettingsScreen(),
    pump: tester.pumpWidget,
    runAsync: tester.runAsync,
  );
  report.verify();
}

/// The image settling that [DesignLabelCheck]'s and [DesignKeylineCheck]'s
/// docs ask for before a check, run by keyline_test.dart.
Future<void> _settleImages(WidgetTester tester) async {
  await tester.runAsync(
    () => Future.wait([
      for (final e in find.byType(Image).evaluate())
        precacheImage((e.widget as Image).image, e),
    ]),
  );
  await tester.pump();
}

/// Code with its layout gone: no whitespace, no trailing comma.
String _bare(String code) =>
    code.replaceAll(RegExp(r'\s+'), '').replaceAll(RegExp(r',(?=[)\]}])'), '');

/// The host app's own layer (its router, its app chrome and its
/// manifest's annotations), which the package leaves out with its examples.
const Set<String> _hostAppOnly = {
  'routing.dart',
  'chrome.dart',
  'annotations.dart',
};

/// Each example in lib: a `/// Example:` line, or a fenced dart block.
List<String> _libExamples() {
  final out = <String>[];
  final files = Directory('lib').listSync(recursive: true).whereType<File>();
  for (final file in files) {
    if (!file.path.endsWith('.dart')) continue;
    if (_hostAppOnly.contains(file.uri.pathSegments.last)) continue;
    final lines = file.readAsLinesSync().map((l) => l.trim()).toList();
    for (var i = 0; i < lines.length; i++) {
      if (lines[i].startsWith('/// Example: ')) {
        out.add(lines[i].substring('/// Example: '.length));
      } else if (lines[i] == '/// ```dart') {
        final code = <String>[];
        while (lines[++i] != '/// ```') {
          code.add(lines[i].replaceFirst(RegExp(r'^///'), ''));
        }
        out.add(code.join('\n'));
      }
    }
  }
  return out;
}

/// Runs [example] once, in the tree, and shows it when it is a widget.
class _Once extends StatefulWidget {
  const _Once(this.example);

  final _Example example;

  @override
  State<_Once> createState() => _OnceState();
}

class _OnceState extends State<_Once> {
  Object? _made;
  bool _ran = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ran) return;
    _ran = true;
    _made = widget.example(context);
    final made = _made;
    if (made is Route<void>) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).push(made).ignore();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final made = _made;
    return made is Widget ? made : const SizedBox();
  }
}

void main() {
  tearDown(() {
    for (final dispose in _disposers) {
      dispose();
    }
    _disposers.clear();
  });

  test('every example in lib is compiled here', () {
    expect(_alignmentCheck, isNotNull);
    expect(_keylineCheck, isNotNull);
    expect(_labelCheck, isNotNull);
    expect(_labelDensities, isNotNull);
    expect(_settleImages, isNotNull);
    expect(_rowCheck, isNotNull);
    expect(_widthCheck, isNotNull);
    expect(_fitChecks, isNotNull);
    final here = _bare(File('test/doc_examples_test.dart').readAsStringSync());
    final examples = _libExamples();
    expect(examples, isNotEmpty);
    expect(
      [
        for (final example in examples)
          if (!here.contains(_bare(example))) example,
      ],
      isEmpty,
      reason: 'each example in lib is written out in this file',
    );
  });

  for (final MapEntry(key: name, value: example) in _examples.entries) {
    testWidgets('$name\'s example runs', (tester) async {
      await tester.pumpWidget(
        harness(
          Center(
            child: SizedBox(width: 480, height: 480, child: _Once(example)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
