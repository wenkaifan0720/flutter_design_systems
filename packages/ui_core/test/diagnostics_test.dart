// The description every public part gives of itself in the inspector and
// in a failing test's tree: each field it is built with, a field at its
// default hidden.
// DesignRadioGroup is deprecated in the package, which keeps its tests for
// its one last release.
// ignore_for_file: deprecated_member_use_from_same_package
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';
import 'package:ui_core/host.dart';
import 'package:ui_core/inventory.dart';

// What each part, built with what it requires alone, says of itself.
final Map<String, List<Object>> _expected = {
  'RawPopover': ['has anchorBuilder', 'has overlayBuilder'],
  'RawCalendarDatePicker': [
    'controller: Instance of \'RawCalendarController\'',
    'has dayBuilder',
  ],
  'RawCarousel': ['itemCount: 3', 'has itemBuilder'],
  'RoutePresentationScope': ['presentation: sheet'],
  'ChromeGroundScope': ['ground: surface'],
  'ShellInsets': ['bottomInset: 80.0'],
  'RawColorArea': [
    startsWith('controller: RawColorController#'),
    'has builder',
    'has thumbBuilder',
  ],
  'RawColorSlider': [
    startsWith('controller: RawColorController#'),
    'channel: hue',
    'has trackBuilder',
    'has thumbBuilder',
  ],
  'RawColorPicker': [
    startsWith('controller: RawColorController#'),
    'has areaBuilder',
    'has areaThumbBuilder',
    'has trackBuilder',
    'has thumbBuilder',
  ],
  'RawCombobox': [
    'has fieldBuilder',
    'has optionBuilder',
    'has displayStringForOption',
  ],
  'RawCommandPalette': [
    'commands: []',
    'has fieldBuilder',
    'has itemBuilder',
    'has score',
  ],
  'RawCommandShortcut': ['has onOpen'],
  'DesignControlBox': ['minHeight: 48.0'],
  'DesignTextEntryBox': ['minHeight: 48.0'],
  'RawDataTable': [
    'controller: Instance of \'RawDataTableController<String>\'',
    'has headerBuilder',
    'has cellBuilder',
    'has rowBuilder',
  ],
  'RawInputDecorator': ['has builder'],
  'DesignForm': [],
  'DesignInputGroup': [startsWith('focusNode: FocusNode#'), 'has builder'],
  'RawPasswordReveal': ['has builder'],
  'DesignInventoryGallery': ['inventory: Instance of \'DesignInventory\''],
  'DesignKeylineRegion': [],
  'MediaSlotImage': ['slotId: "hero"'],
  'RawMenuBar': ['menus: []', 'has itemBuilder', 'has surfaceBuilder'],
  'RawOtpField': ['has slotBuilder'],
  'RawButton': ['has builder'],
  'PreviewFrame': [],
  'PreviewStage': ['has route'],
  'RawRefreshIndicator': ['has onRefresh', 'has indicatorBuilder'],
  'RawRangeSlider': [
    'values: RawRangeValues(0.2, 0.8)',
    'has trackBuilder',
    'has thumbBuilder',
  ],
  'RawReorderableList': [
    'items: []',
    'has onReorder',
    'has itemBuilder',
    'has labelOf',
  ],
  'RawScrollArea': [
    startsWith('controller: ScrollController#'),
    'has thumbBuilder',
  ],
  'RawSplitButton': [
    'label: "Save"',
    'actions: []',
    'has buttonBuilder',
    'has itemBuilder',
    'has surfaceBuilder',
  ],
  'RawSplitView': ['has dividerBuilder'],
  'RawSwipeActions': ['has actionBuilder'],
  'RawTagInput': [
    'values: []',
    'has onChanged',
    'has fieldBuilder',
    'has optionBuilder',
    'has tagBuilder',
    'has displayStringForOption',
  ],
  'RawToaster': ['has toastBuilder'],
  'DesignRadioGroup': [
    'options: Day, Week',
    'has onChanged',
    'has itemBuilder',
    'has focusNodeFor',
  ],
  'RawSegmentedButton': [
    'options: Day, Week',
    'selected: Day',
    'has onSelectionChanged',
    'has itemBuilder',
  ],
  'DesignTree': [
    'controller: Instance of \'DesignTreeController<String>\'',
    'has rowBuilder',
    'has labelOf',
  ],
  'DesignValueHandle': ['value: 0.5', 'has builder'],
};

// The widget classes of the package's public libraries, read from its source.
final _widgetSupers = RegExp(
  r'\b(StatelessWidget|StatefulWidget|RenderObjectWidget|'
  r'SingleChildRenderObjectWidget|LeafRenderObjectWidget|'
  r'MultiChildRenderObjectWidget|InheritedWidget|InheritedTheme|'
  r'InheritedNotifier|ProxyWidget)\b',
);

void _chose(Set<String> _) {}

void main() {
  test('every public widget describes every public field it is built with', () {
    // The whole lib: drip's kit lays it under design_kit/, the package under
    // src/.
    final lib = Directory('lib');
    final missing = <String>[];
    var widgets = 0;
    for (final file in lib.listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.dart') || file.path.contains('/internal/')) {
        continue;
      }
      final source = file.readAsStringSync();
      for (final m in RegExp(
        r'^(?:abstract |final |base )*class ([A-Z]\w*)[^{]*?'
        r'\b(?:extends|with|implements)\b([^{]*)\{',
        multiLine: true,
      ).allMatches(source)) {
        if (!_widgetSupers.hasMatch(m.group(2)!)) continue;
        final end = source.indexOf('\n}\n', m.end);
        final body = source.substring(m.end, end < 0 ? source.length : end);
        final lines = body.split('\n');
        final fields = <String>[];
        for (var i = 0; i < lines.length; i++) {
          final f = RegExp(r'^  final (.+) (\w+);$').firstMatch(lines[i]);
          if (f == null || f.group(2)!.startsWith('_')) continue;
          if (i > 0 && lines[i - 1].trim().startsWith('@Deprecated')) continue;
          final type = f.group(1)!;
          if (RegExp(r'^(Widget\??|List<Widget>)$').hasMatch(type)) continue;
          fields.add(f.group(2)!);
        }
        if (fields.isEmpty) continue;
        widgets++;
        for (final field in fields) {
          if (!body.contains("'$field'")) missing.add('${m.group(1)}.$field');
        }
      }
    }
    expect(widgets, greaterThan(40));
    expect(missing, isEmpty, reason: 'fields left out of debugFillProperties');
  });

  testWidgets('each part, built with what it requires, says so and hides its '
      'defaults', (tester) async {
    final parts = _parts();
    expect(parts.keys, unorderedEquals(_expected.keys));
    for (final MapEntry(key: name, value: part) in parts.entries) {
      expect(_description(part), _expected[name], reason: name);
    }
  });

  test('a value handle says each field set off its default', () {
    expect(
      _description(
        DesignValueHandle(
          value: .25,
          onChanged: (_) {},
          builder: _b2,
          max: 2,
          step: .25,
          divisions: 8,
          axis: Axis.vertical,
          autofocus: true,
          semanticLabel: 'Volume',
        ),
      ),
      [
        'value: 0.3',
        'has onChanged',
        'has builder',
        'max: 2.0',
        'step: 0.3',
        'divisions: 8',
        'axis: vertical',
        'semanticLabel: "Volume"',
        'autofocus',
      ],
    );
  });

  test('a pressable says its states and roles set off their defaults', () {
    expect(
      _description(
        RawButton(
          builder: _b3,
          onPressed: () {},
          selected: true,
          semanticLabel: 'Save',
          button: false,
          link: true,
          expanded: false,
        ),
      ),
      [
        'has builder',
        'has onPressed',
        'selected',
        'semanticLabel: "Save"',
        'button: false',
        'link',
        'expanded: false',
      ],
    );
  });

  group('a value out of its range asserts', () {
    final cases = <String, Object? Function()>{
      'a handle past its max': () =>
          DesignValueHandle(value: 2, onChanged: null, builder: _b2),
      'a handle whose min passes its max': () => DesignValueHandle(
        value: .5,
        min: 1,
        max: 0,
        onChanged: null,
        builder: _b2,
      ),
      'a handle of no divisions': () => DesignValueHandle(
        value: .5,
        divisions: 0,
        onChanged: null,
        builder: _b2,
      ),
      'a handle of no step': () =>
          DesignValueHandle(value: .5, step: 0, onChanged: null, builder: _b2),
      'a range whose start passes its end': () => RawRangeValues(.8, .2),
      'a range slider whose min passes its max': () => RawRangeSlider(
        values: const RawRangeValues(.2, .8),
        min: 1,
        max: 0,
        onChanged: null,
        thumbBuilder: _b3,
        trackBuilder: _b2,
      ),
      'a range slider of a negative gap': () => RawRangeSlider(
        values: const RawRangeValues(.2, .8),
        minGap: -1,
        onChanged: null,
        thumbBuilder: _b3,
        trackBuilder: _b2,
      ),
      'a carousel of fewer than no items': () =>
          RawCarousel(itemBuilder: _b2, itemCount: -1),
      'a carousel whose pages take no room': () =>
          RawCarousel(itemBuilder: _b2, itemCount: 3, viewportFraction: 0),
      'a split past its end': () => RawSplitView(
        first: _box,
        second: _box,
        dividerBuilder: _b3,
        initialFraction: 1.5,
      ),
      'a tag input that takes no tags': () => RawTagInput<String>(
        values: const [],
        onChanged: (_) {},
        fieldBuilder: _b2,
        optionBuilder: _b3,
        tagBuilder: _b3,
        maxTags: 0,
      ),
      'a toaster of no stiffness': () =>
          RawToaster(toastBuilder: _b2, stiffness: 0, child: _box),
      'an overlay of no damping': () =>
          RawPopover(anchorBuilder: _b2, overlayBuilder: _b2, dampingRatio: 0),
      'a palette of no height': () => RawCommandPalette(
        commands: const [],
        fieldBuilder: _b2,
        itemBuilder: _b3,
        maxHeight: 0,
      ),
      'a refresh that triggers at once': () => RawRefreshIndicator(
        onRefresh: () async {},
        indicatorBuilder: _b2,
        triggerDistance: 0,
        child: _box,
      ),
      'a swipe action of no width': () =>
          RawSwipeActions(actionBuilder: _b3, actionExtent: 0, child: _box),
      'a combobox list of no height': () => RawCombobox<String>(
        fieldBuilder: _b2,
        optionBuilder: _b3,
        optionsMaxHeight: 0,
      ),
    };
    for (final MapEntry(key: what, value: build) in cases.entries) {
      test(what, () => expect(build, throwsAssertionError));
    }

    test('a calendar whose week starts on an eighth day', () {
      final controller = RawCalendarController(
        firstDate: DateTime(2026),
        lastDate: DateTime(2027),
      );
      addTearDown(controller.dispose);
      expect(
        () => RawCalendarDatePicker(
          controller: controller,
          dayBuilder: _b3,
          firstWeekday: 8,
        ),
        throwsAssertionError,
      );
    });

    test('a colour area of no step and a picker of no height', () {
      final controller = RawColorController();
      addTearDown(controller.dispose);
      expect(
        () => RawColorArea(
          controller: controller,
          builder: _b2,
          thumbBuilder: _b2,
          step: 0,
        ),
        throwsAssertionError,
      );
      expect(
        () => RawColorPicker(
          controller: controller,
          areaBuilder: _b2,
          areaThumbBuilder: _b2,
          thumbBuilder: _b2,
          trackBuilder: _b3,
          areaHeight: 0,
        ),
        throwsAssertionError,
      );
    });

    test('a scroll area of no thickness', () {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      expect(
        () => RawScrollArea(
          controller: controller,
          thumbBuilder: _b2,
          thickness: 0,
          child: _box,
        ),
        throwsAssertionError,
      );
    });

    testWidgets('a range slider whose values pass its ends, as it builds', (
      tester,
    ) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: RawRangeSlider(
            values: RawRangeValues(.2, 1.5),
            onChanged: null,
            thumbBuilder: _b3,
            trackBuilder: _b2,
          ),
        ),
      );
      expect(tester.takeException(), isAssertionError);
    });
  });
}

const Widget _box = SizedBox();
Widget _b2(Object? _, Object? _) => _box;
Widget _b3(Object? _, Object? _, Object? _) => _box;
Widget _b4(Object? _, Object? _, Object? _, Object? _) => _box;

/// Every public part, built with what it requires and nothing else; the
/// controllers it needs are disposed when the test ends.
Map<String, Widget> _parts() {
  T held<T extends ChangeNotifier>(T notifier) {
    addTearDown(notifier.dispose);
    return notifier;
  }

  return {
    'RawPopover': const RawPopover(anchorBuilder: _b2, overlayBuilder: _b2),
    'RawCalendarDatePicker': RawCalendarDatePicker(
      controller: held(
        RawCalendarController(
          firstDate: DateTime(2026),
          lastDate: DateTime(2027),
        ),
      ),
      dayBuilder: _b3,
    ),
    'RawCarousel': const RawCarousel(itemBuilder: _b2, itemCount: 3),
    'RoutePresentationScope': const RoutePresentationScope(
      presentation: RoutePresentation.sheet,
      child: _box,
    ),
    'ChromeGroundScope': const ChromeGroundScope(
      ground: ChromeGround.surface,
      child: _box,
    ),
    'ShellInsets': const ShellInsets(bottomInset: 80, child: _box),
    'RawColorArea': RawColorArea(
      controller: held(RawColorController()),
      builder: _b2,
      thumbBuilder: _b2,
    ),
    'RawColorSlider': RawColorSlider(
      channel: RawColorChannel.hue,
      controller: held(RawColorController()),
      thumbBuilder: _b2,
      trackBuilder: _b3,
    ),
    'RawColorPicker': RawColorPicker(
      controller: held(RawColorController()),
      areaBuilder: _b2,
      areaThumbBuilder: _b2,
      thumbBuilder: _b2,
      trackBuilder: _b3,
    ),
    'RawCombobox': const RawCombobox<String>(
      fieldBuilder: _b2,
      optionBuilder: _b3,
    ),
    'RawCommandPalette': const RawCommandPalette(
      commands: [],
      fieldBuilder: _b2,
      itemBuilder: _b3,
    ),
    'RawCommandShortcut': RawCommandShortcut(onOpen: () {}, child: _box),
    'DesignControlBox': const DesignControlBox(minHeight: 48, child: _box),
    'DesignTextEntryBox': const DesignTextEntryBox(minHeight: 48, child: _box),
    'RawDataTable': RawDataTable<String>(
      controller: held(
        RawDataTableController<String>(rows: const [], columns: const []),
      ),
      headerBuilder: _b4,
      rowBuilder: _b3,
      cellBuilder: _b3,
    ),
    'RawInputDecorator': const RawInputDecorator(builder: _b2, child: _box),
    'DesignForm': const DesignForm(child: _box),
    'DesignInputGroup': DesignInputGroup(
      focusNode: held(FocusNode()),
      builder: _b3,
      child: _box,
    ),
    'RawPasswordReveal': const RawPasswordReveal(builder: _b2),
    'DesignInventoryGallery': const DesignInventoryGallery(
      inventory: DesignInventory(look: 'Test', entries: []),
    ),
    'DesignKeylineRegion': const DesignKeylineRegion(child: _box),
    'MediaSlotImage': const MediaSlotImage(slotId: 'hero', fallback: _box),
    'RawMenuBar': const RawMenuBar(
      menus: [],
      itemBuilder: _b4,
      surfaceBuilder: _b3,
    ),
    'RawOtpField': const RawOtpField(slotBuilder: _b2),
    'RawButton': const RawButton(builder: _b3),
    'PreviewFrame': const PreviewFrame(child: _box),
    'PreviewStage': PreviewStage(
      route: (context, page) =>
          PageRouteBuilder<void>(pageBuilder: (_, _, _) => page),
      child: _box,
    ),
    'RawRefreshIndicator': RawRefreshIndicator(
      onRefresh: () async {},
      indicatorBuilder: _b2,
      child: _box,
    ),
    'RawRangeSlider': const RawRangeSlider(
      values: RawRangeValues(.2, .8),
      onChanged: null,
      thumbBuilder: _b3,
      trackBuilder: _b2,
    ),
    'RawReorderableList': RawReorderableList<String>(
      items: const [],
      labelOf: (item) => item,
      onReorder: (_, _) {},
      itemBuilder: _b3,
    ),
    'RawScrollArea': RawScrollArea(
      controller: held(ScrollController()),
      thumbBuilder: _b2,
      child: _box,
    ),
    'RawSplitButton': const RawSplitButton(
      label: 'Save',
      onPressed: null,
      actions: [],
      buttonBuilder: _b4,
      itemBuilder: _b3,
      surfaceBuilder: _b3,
    ),
    'RawSplitView': const RawSplitView(
      first: _box,
      second: _box,
      dividerBuilder: _b3,
    ),
    'RawSwipeActions': const RawSwipeActions(actionBuilder: _b3, child: _box),
    'RawTagInput': RawTagInput<String>(
      values: const [],
      onChanged: (_) {},
      fieldBuilder: _b2,
      optionBuilder: _b3,
      tagBuilder: _b3,
    ),
    'RawToaster': const RawToaster(toastBuilder: _b2, child: _box),
    'DesignRadioGroup': DesignRadioGroup<String>(
      options: const ['Day', 'Week'],
      value: null,
      onChanged: (_) {},
      itemBuilder: _b4,
      focusNodeFor: (_) => null,
    ),
    'RawSegmentedButton': const RawSegmentedButton<String>(
      options: ['Day', 'Week'],
      selected: {'Day'},
      onSelectionChanged: _chose,
      itemBuilder: _b3,
    ),
    'DesignTree': DesignTree<String>(
      controller: held(
        DesignTreeController<String>(
          roots: const [],
          childrenOf: (_) => const [],
        ),
      ),
      labelOf: (node) => node,
      rowBuilder: _b2,
    ),
    'DesignValueHandle': const DesignValueHandle(
      value: .5,
      onChanged: null,
      builder: _b2,
    ),
  };
}

List<String> _description(Widget part) {
  final builder = DiagnosticPropertiesBuilder();
  part.debugFillProperties(builder);
  return [
    for (final p in builder.properties)
      if (!p.isFiltered(DiagnosticLevel.info)) p.toString(),
  ];
}
