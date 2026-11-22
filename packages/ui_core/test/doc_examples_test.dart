// Every doc example in lib, compiled and run. Each `/// Example:` (a fenced
// dart block in the package) is written out below as the body of an entry,
// so an example that stops compiling fails analysis; the first test fails
// when lib has an example this file lacks; the rest build each widget
// example (and push each route, run each call) in a bare app.
//
// An example may name `controller` or `focusNode`: the caller's own, which
// its entry makes first, as the docs say the caller does.
// DesignRadioGroup and DesignTooltip are deprecated in the package, which
// keeps their tests for their one last release.
// ignore_for_file: deprecated_member_use_from_same_package
import 'package:material_ui/material_ui.dart'
    show DefaultMaterialLocalizations, Material, TextField;
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';
import 'package:ui_core/host.dart';
import 'package:ui_core/inventory.dart';
// 0.3.0 routes
// 0.3.0 routes end

import 'behaviour_harness.dart';
import 'doc_examples.dart';

/// What the caller made for an example, disposed once its tree is gone.
final List<VoidCallback> _disposers = [];

T _own<T extends ChangeNotifier>(T value) {
  _disposers.add(value.dispose);
  return value;
}

final Map<String, DocExample> _examples = {
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
  'DefaultRawWidgetsLocalizations': (context) =>
      const DefaultRawWidgetsLocalizations().carouselSlideLabel(0, 3),
  'RawPopover': (context) => RawPopover(
    anchorBuilder: (context, anchor) =>
        GestureDetector(onTap: anchor.toggle, child: const Text('More')),
    overlayBuilder: (context, info) => const Text('Details'),
  ),
  'RawContextMenu': (context) => RawContextMenu(
    menuChildren: [RawMenuEntry(label: 'Copy', onPressed: () {})],
    itemBuilder: (context, entry, level, states) => Text(entry.label),
    surfaceBuilder: (context, info, items) =>
        Column(mainAxisSize: MainAxisSize.min, children: items),
    child: const Text('Report.pdf'),
  ),
  'DesignTooltip': (context) => DesignTooltip(
    message: 'Save the report',
    tooltipBuilder: (context, info) => const Text('Save the report'),
    child: const Text('Save'),
  ),
  'designShortcutKeys': (context) => designShortcutKeys(
    context,
    const SingleActivator(LogicalKeyboardKey.keyN, meta: true, shift: true),
  ),
  'designShortcutLabel': (context) => designShortcutLabel(
    context,
    const SingleActivator(LogicalKeyboardKey.keyS, control: true),
  ),
  'RawPopoverPadding': (context) => const RawPopoverPadding(
    padding: EdgeInsetsDirectional.only(start: 280),
    child: Text('A page beside the side bar'),
  ),
  'RawCalendarDatePicker': (context) {
    final controller = _own(
      RawCalendarController(
        firstDate: DateTime(2026),
        lastDate: DateTime(2027),
      ),
    );
    return RawCalendarDatePicker(
      controller: controller,
      dayBuilder: (context, day, states) => Text('${day.date.day}'),
    );
  },
  'RawCalendarController': (context) => _own(
    RawCalendarController(firstDate: DateTime(2026), lastDate: DateTime(2027)),
  ),
  'RawCarousel': (context) => RawCarousel(
    itemCount: 3,
    itemBuilder: (context, index) => Text('Slide $index'),
  ),
  'RawColorArea': (context) {
    final controller = _own(RawColorController());
    return RawColorArea(
      controller: controller,
      builder: (context, area) => const SizedBox.expand(),
      thumbBuilder: (context, area) => const SizedBox(width: 16, height: 16),
    );
  },
  'RawColorController': (context) =>
      _own(RawColorController(const Color(0xFF3366FF))),
  'RawColorPicker': (context) {
    final controller = _own(RawColorController());
    return RawColorPicker(
      controller: controller,
      areaBuilder: (context, area) => const SizedBox.expand(),
      areaThumbBuilder: (context, area) =>
          const SizedBox(width: 16, height: 16),
      trackBuilder: (context, channel, color) => const SizedBox(height: 8),
      thumbBuilder: (context, states) => const SizedBox(width: 16, height: 16),
    );
  },
  'RawColorSlider': (context) {
    final controller = _own(RawColorController());
    return RawColorSlider(
      controller: controller,
      channel: RawColorChannel.hue,
      trackBuilder: (context, channel, color) => const SizedBox(height: 8),
      thumbBuilder: (context, states) => const SizedBox(width: 16, height: 16),
    );
  },
  'RawCombobox': (context) => RawCombobox<String>(
    options: const ['Apple', 'Pear'],
    fieldBuilder: (context, field) => EditableText(
      controller: field.controller,
      focusNode: field.focusNode,
      style: const TextStyle(),
      cursorColor: const Color(0xFF000000),
      backgroundCursorColor: const Color(0xFF808080),
      onEditingComplete: field.submit,
    ),
    optionBuilder: (context, option, states) => Text(option),
  ),
  'RawSearchError': (context) =>
      RawSearchError(error: StateError('offline'), retry: () {}),
  'RawCommandPalette': (context) => RawCommandPalette(
    commands: const [RawCommand(label: 'New file')],
    fieldBuilder: (context, field) => EditableText(
      controller: field.controller,
      focusNode: field.focusNode,
      style: const TextStyle(),
      cursorColor: const Color(0xFF000000),
      backgroundCursorColor: const Color(0xFF808080),
      onEditingComplete: field.submit,
    ),
    itemBuilder: (context, command, states) => Text(command.label),
  ),
  'RawCommandShortcut': (context) =>
      RawCommandShortcut(onOpen: () {}, child: const SizedBox()),
  'RawDataTable': (context) {
    final controller = _own(
      RawDataTableController<String>(
        rows: const ['a', 'b'],
        columns: [
          RawDataColumn<String>(
            id: 'name',
            label: 'Name',
            sortKey: (row) => row,
          ),
        ],
      ),
    );
    return RawDataTable<String>(
      controller: controller,
      headerBuilder: (context, column, sort, states) => Text(column.label),
      cellBuilder: (context, row, column) => Text(row),
      rowBuilder: (context, row, cells) => Row(children: cells),
    );
  },
  'RawDataTableController': (context) => _own(
    RawDataTableController<String>(
      rows: const ['a', 'b'],
      columns: [
        RawDataColumn<String>(id: 'name', label: 'Name', sortKey: (row) => row),
      ],
    ),
  ),
  'RawInputDecorator': (context) => RawInputDecorator(
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
  'RawMenuBar': (context) => RawMenuBar(
    menus: [
      RawMenuEntry(
        label: 'File',
        children: [RawMenuEntry(label: 'New', onPressed: () {})],
      ),
    ],
    itemBuilder: (context, entry, level, states) => Text(entry.label),
    surfaceBuilder: (context, info, items) =>
        Column(mainAxisSize: MainAxisSize.min, children: items),
  ),
  'RawOtpField': (context) => RawOtpField(
    length: 4,
    slotBuilder: (context, slot) => Text(slot.character),
  ),
  'RawOtpController': (context) => _own(RawOtpController(length: 6)),
  'RawPasswordReveal': (context) => RawPasswordReveal(
    builder: (context, password) => Text(password.toggleLabel),
  ),
  'RawPasswordController': (context) =>
      _own(RawPasswordController(obscured: false)),
  'designSwipeBack': (context) => designSwipeBack({
    TargetPlatform.iOS: const FadeUpwardsPageTransitionsBuilder(),
  }),
  'SwipeBackPageTransitionsBuilder': (context) =>
      const SwipeBackPageTransitionsBuilder(
        FadeUpwardsPageTransitionsBuilder(),
      ),
  'RawButton': (context) => RawButton(
    onPressed: () {},
    semanticLabel: 'Save',
    builder: (context, states, child) => Opacity(
      opacity: states.contains(WidgetState.pressed) ? 0.6 : 1,
      child: const Text('Save'),
    ),
  ),
  'DesignSpacing': (context) {
    const app = Text('App');
    return const DesignSpacingScope(
      spacing: DesignSpacing(grid: 2),
      child: app,
    );
  },
  'DesignTapTargetScope': (context) {
    const app = Text('App');
    return const DesignTapTargetScope(
      targets: DesignTapTargets(touch: Size.square(48)),
      child: app,
    );
  },
  'TapTargetPadding, on its start edge': (context) {
    void onPressed() {}
    Widget face(BuildContext context, Set<WidgetState> states, Widget? child) =>
        const Text('Add');
    return TapTargetPadding(
      alignment: AlignmentDirectional.centerStart,
      child: RawButton(onPressed: onPressed, builder: face),
    );
  },
  'RawButton, a small icon in its tap target': (context) {
    void play() {}
    return TapTargetPadding(
      child: RawButton(
        semanticLabel: 'Play',
        onPressed: play,
        builder: (context, states, _) => const SizedBox.square(dimension: 16),
      ),
    );
  },
  'TapTargetPadding': (context) {
    void onPressed() {}
    Widget face(BuildContext context, Set<WidgetState> states, Widget? child) =>
        const Text('Add');
    return TapTargetPadding(
      child: RawButton(onPressed: onPressed, builder: face),
    );
  },
  'DesignStyle': (context) {
    final style = DesignStyle(
      fill: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.pressed)
            ? const Color(0xFF1D4ED8)
            : const Color(0xFF2563EB),
      ),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 20),
      ),
    );
    const themed = DesignStyle();
    const states = <WidgetState>{};
    final forwarded = DesignStyle.layered([style, themed]);
    final fill =
        DesignStyle.first([style, themed], (s) => s.fill, states) ??
        const Color(0xFFFFFFFF);
    return ColoredBox(
      color: fill,
      child: SizedBox(height: forwarded.isEmpty ? 0 : 40),
    );
  },
  'DesignStyleOf': (context) {
    const style = DesignStyle();
    const themed = DesignStyle();
    const states = <WidgetState>{};
    final look = const DesignStyleOf([style, themed], states);
    final fill = look.fill ?? const Color(0xFFFFFFFF);
    return ColoredBox(color: fill);
  },
  'DesignDensity': (context) {
    final height = DesignDensity.compact.height(44); // 36
    return SizedBox(height: height, child: const Text('Row'));
  },
  'RawRefreshIndicator': (context) => RawRefreshIndicator(
    onRefresh: () async {},
    indicatorBuilder: (context, details) => const SizedBox(height: 40),
    child: ListView(),
  ),
  'RawRangeSlider': (context) => RawRangeSlider(
    values: const RawRangeValues(20, 80),
    max: 100,
    onChanged: (values) {},
    trackBuilder: (context, track) => const SizedBox(height: 4),
    thumbBuilder: (context, index, states) =>
        const SizedBox(width: 20, height: 20),
  ),
  'RawReorderableList': (context) => RawReorderableList<String>(
    items: const ['a', 'b'],
    onReorder: (from, to) {},
    labelOf: (item) => item,
    itemBuilder: (context, item, reorder) => reorder.handle(Text(item)),
  ),
  'RawScrollArea': (context) {
    final controller = _own(ScrollController());
    return RawScrollArea(
      controller: controller,
      thumbBuilder: (context, thumb) =>
          const ColoredBox(color: Color(0x66000000)),
      child: SingleChildScrollView(
        controller: controller,
        child: const Text('Terms'),
      ),
    );
  },
  'RawSideSheetRoute': (context) => RawSideSheetRoute<void>(
    builder: (context, sheet) => const SizedBox(width: 320),
  ),
  'RawSplitButton': (context) => RawSplitButton(
    label: 'Save',
    onPressed: () {},
    actions: [RawSplitAction(label: 'Save as', onPressed: () {})],
    buttonBuilder: (context, part, states, open) => Text(part.name),
    itemBuilder: (context, action, states) => Text(action.label),
    surfaceBuilder: (context, info, items) =>
        Column(mainAxisSize: MainAxisSize.min, children: items),
  ),
  'RawSplitView': (context) => RawSplitView(
    first: const SizedBox(),
    second: const SizedBox(),
    dividerBuilder: (context, states, axis) =>
        const ColoredBox(color: Color(0xFFDDDDDD)),
  ),
  'RawSwipeActions': (context) => RawSwipeActions(
    endActions: [
      RawSwipeAction(label: 'Delete', onPressed: () {}, destructive: true),
    ],
    actionBuilder: (context, action, details) => Text(action.label),
    child: const Text('Message'),
  ),
  'RawTagInput': (context) => RawTagInput<String>(
    values: const ['red'],
    onChanged: (values) {},
    onCreate: (text) => text,
    fieldBuilder: (context, field) => EditableText(
      controller: field.controller,
      focusNode: field.focusNode,
      style: const TextStyle(),
      cursorColor: const Color(0xFF000000),
      backgroundCursorColor: const Color(0xFF808080),
      onEditingComplete: field.submit,
    ),
    optionBuilder: (context, option, states) => Text(option),
    tagBuilder: (context, value, tag) => Text(value),
  ),
  'RawToaster': (context) => RawToaster(
    toastBuilder: (context, details) => Text(details.toast.message),
    child: const SizedBox(),
  ),
  'DesignRadioGroup': (context) {
    var chosen = 'Day';
    void choose(String value) => chosen = value;
    return DesignRadioGroup<String>(
      options: const ['Day', 'Week'],
      value: chosen,
      onChanged: choose,
      itemBuilder: (context, option, node, select) => RawButton(
        focusNode: node,
        onPressed: select,
        checked: option == chosen,
        inMutuallyExclusiveGroup: true,
        builder: (context, states, _) => Text(option),
      ),
    );
  },
  'RawTooltipFocusFix': (context) => RawTooltip(
    semanticsTooltip: 'Save the report',
    tooltipBuilder: (context, animation) => const Text('Save the report'),
    child: const RawTooltipFocusFix(child: Focus(child: Text('Save'))),
  ),
  'RawTooltipPlacement': (context) => RawTooltipPlacement(
    builder: (context, positionDelegate) => RawTooltip(
      semanticsTooltip: 'Save the report',
      positionDelegate: positionDelegate,
      tooltipBuilder: (context, animation) =>
          Text('Save the report, ${RawTooltipPlacement.sideOf(context)}'),
      child: const Text('Save'),
    ),
  ),
  'RadioGroupKeyboardFix': (context) {
    String? chosen = 'Day';
    void choose(String? value) => chosen = value;
    const dayRadio = LookRadio<String>(value: 'Day');
    const weekRadio = LookRadio<String>(value: 'Week');
    return RadioGroup<String>(
      groupValue: chosen,
      onChanged: choose,
      child: const RadioGroupKeyboardFix<String>(
        child: Column(children: [dayRadio, weekRadio]),
      ),
    );
  },
  'RadioGroupKeyboardFix, a look\'s radio': (context) {
    final focusNode = _own(FocusNode());
    Widget radioFace(Set<WidgetState> states, bool chosen) =>
        Text(chosen ? 'Day, chosen' : 'Day');
    return RadioGroup<String>(
      groupValue: 'Day',
      onChanged: (value) {},
      child: RadioGroupKeyboardFix<String>(
        // Inside the group, where RadioGroup.maybeOf finds it.
        child: Builder(
          builder: (context) => MergeSemantics(
            child: RawRadio<String>(
              value: 'Day',
              mouseCursor: WidgetStateMouseCursor.clickable,
              toggleable: false,
              focusNode: focusNode, // the caller's, else one its State owns
              autofocus: false,
              groupRegistry: RadioGroup.maybeOf<String>(context),
              enabled: true,
              builder: (context, radio) => Semantics(
                label: 'Day',
                child: ExcludeSemantics(
                  child: radioFace({
                    ...radio.states,
                    if (radio.downPosition != null) WidgetState.pressed,
                  }, radio.value ?? false),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  },
  'RawSegmentedButton': (context) => RawSegmentedButton<String>(
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
      DefaultRawWidgetsLocalizations.delegate,
      DefaultWidgetsLocalizations.delegate,
    ],
    child: Builder(
      builder: (context) =>
          Text(RawWidgetsLocalizations.of(context).carouselLabel),
    ),
  ),
  'MediaSlotImage': (context) => const MediaSlotImage(
    slotId: 'hero',
    fallback: ColoredBox(color: Color(0xFFDDDDDD)),
  ),
  'designReduceMotionOf': (context) => designReduceMotionOf(context)
      ? Duration.zero
      : const Duration(milliseconds: 200),
  'DesignMotionPolicy': (context) {
    final controller = AnimationController(vsync: const TestVSync());
    _disposers.add(controller.dispose);
    return controller.springTo(
      1,
      DesignMotionPolicy.of(context).spatial(dampingRatio: 0.6, stiffness: 800),
    );
  },
  'PreviewFrame': (context) => const PreviewFrame(
    platform: PreviewPlatform.ios,
    brightness: Brightness.dark,
    child: Text('App'),
  ),
  'PreviewStage': (context) => PreviewStage(
    route: (context, page) => PageRouteBuilder<void>(
      pageBuilder: (context, animation, secondary) => page,
    ),
    child: const Text('Details'),
  ),
  'DesignKeylineRegion': (context) => const DesignKeylineRegion(
    label: 'Settings',
    indents: [40],
    child: Text('Settings'),
  ),
  'DesignKeylineFace': (context) =>
      const DesignKeylineFace(child: SizedBox(width: 120, height: 40)),
  'DesignCapCenter': (context) =>
      const DesignCapCenter(capHeightFactor: 0.711, child: Text('Save')),
  // 0.3.0 values
  'DesignHaptics': (context) {
    DesignHaptics.of(context).selectionChanged?.call();
    return null;
  },
  'DesignHapticsScope': (context) => const DesignHapticsScope(
    haptics: DesignHaptics.silent(),
    child: Text('Quiet'),
  ),
  'RawPickerColumn': (context) => RawPickerColumn(
    itemCount: 12,
    itemLabel: (index) => 'Month ${index + 1}',
    semanticLabel: 'Month',
  ),
  'RawPicker': (context) => RawPicker(
    columns: (selection) => [
      RawPickerColumn(
        itemCount: 24,
        itemLabel: (index) => '$index',
        semanticLabel: 'Hour',
        looping: true,
      ),
    ],
    selection: const [9],
    onChanged: (selection) {},
    itemExtent: 40,
    itemBuilder: (context, details) => Center(child: Text(details.label)),
  ),
  'RawTimeOfDay': (context) => Text(
    RawWidgetsLocalizations.of(context)
        .formatTimeOfDay(const RawTimeOfDay(hour: 15, minute: 5)),
  ),
  'RawDateField': (context) => RawDateField(
    value: DateTime(2026, 11, 16),
    onChanged: (day) {},
    segmentBuilder: (context, details) => Text(details.text),
  ),
  'RawTimeField': (context) => RawTimeField(
    value: const RawTimeOfDay(hour: 9, minute: 30),
    onChanged: (time) {},
    segmentBuilder: (context, details) => Text(details.text),
  ),
  'RawNumberField': (context) => RawNumberField(
    value: 2,
    onChanged: (value) {},
    min: 0,
    fieldBuilder: (context, field) => EditableText(
      controller: field.controller,
      focusNode: field.focusNode,
      keyboardType: field.keyboardType,
      inputFormatters: field.inputFormatters,
      onEditingComplete: field.onEditingComplete,
      style: const TextStyle(),
      cursorColor: const Color(0xFF000000),
      backgroundCursorColor: const Color(0xFF808080),
    ),
    buttonBuilder: (context, button) => Text(button.isIncrement ? '+' : '−'),
  ),
  'RawRating': (context) => RawRating(
    value: 3,
    onChanged: (value) {},
    itemBuilder: (context, item) => Text(item.fill >= 1 ? '★' : '☆'),
  ),
  'DesignScale': (context) =>
      const DesignLinearScale(min: 0, max: 100, start: 0, end: 300).map(50),
  'DesignLinearScale': (context) =>
      DesignLinearScale.nice(min: 3, max: 97, start: 300, end: 0),
  'DesignTimeScale': (context) => DesignTimeScale(
    min: DateTime(2026),
    max: DateTime(2026, 12),
    start: 0,
    end: 300,
  ),
  'DesignBandScale': (context) => const DesignBandScale(
    count: 4,
    start: 0,
    end: 400,
    labels: ['Q1', 'Q2', 'Q3', 'Q4'],
  ).map(2),
  'DesignChartValueFormat': (context) =>
      const DesignChartValueFormat(suffix: ' h')
          .format(4, RawWidgetsLocalizations.of(context)),
  'DesignScaleTick.widestLabel': (context) => DesignChart(
    semanticLabel: 'Hours',
    series: const [
      DesignChartSeries(label: 'Hours', points: [DesignChartPoint(0, 4)]),
    ],
    builder: (context, details) => Text(
      '${DesignScaleTick.widestLabel(details.yTicks, style: const TextStyle(fontSize: 12), textScaler: MediaQuery.textScalerOf(context))}',
    ),
  ),
  'DesignComboboxField.isOpen': (context) {
    final field = DesignComboboxField(
      controller: _own(TextEditingController()),
      focusNode: _own(FocusNode()),
      submit: () {},
      isOpen: true,
    );
    return Semantics(
      expanded: field.isOpen,
      child: EditableText(
        controller: field.controller,
        focusNode: field.focusNode,
        onEditingComplete: field.submit,
        style: const TextStyle(),
        cursorColor: const Color(0xFF000000),
        backgroundCursorColor: const Color(0xFF808080),
      ),
    );
  },
  'RawToasterKeepClear': (context) => const Column(
    children: [
      Expanded(child: Text('Messages')),
      RawToasterKeepClear(
        child: SafeArea(
          top: false,
          child: SizedBox(height: 56, child: Text('Composer')),
        ),
      ),
    ],
  ),
  'RawActionBar': (context) => const RawActionBar(
    children: [Text('Cancel'), Text('Discard'), Text('Save changes')],
  ),
  'DesignChart': (context) => DesignChart(
    semanticLabel: 'Revenue',
    series: const [
      DesignChartSeries(
        label: 'Revenue',
        points: [DesignChartPoint(0, 820), DesignChartPoint(1, 1240)],
      ),
    ],
    builder: (context, chart) => CustomPaint(size: chart.size),
  ),
  'DesignPieChart': (context) => DesignPieChart(
    semanticLabel: 'Spending',
    slices: const [
      DesignPieSlice(label: 'Rent', value: 1200),
      DesignPieSlice(label: 'Food', value: 600),
    ],
    builder: (context, pie) => CustomPaint(size: pie.size),
  ),
  'DesignChartTable': (context) => DesignChartTable(
    series: const [
      DesignChartSeries(label: 'Revenue', points: [DesignChartPoint(0, 820)]),
    ],
    cellBuilder: (context, cell) => Text(cell.text),
  ),
  // 0.3.0 values end
  // 0.3.0 routes
  'DesignDialogRoute': (context) => DesignDialogRoute<bool>(
    isAlert: true,
    builder: (context, details) => RawAlertDialog(
      title: 'Delete the draft?',
      content: const Text('It cannot be brought back.'),
      actions: [
        RawDialogAction(
          label: 'Cancel',
          onPressed: () => Navigator.of(context).pop(false),
        ),
        RawDialogAction(
          label: 'Delete',
          isDestructiveAction: true,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
      actionBuilder: (context, action, details) => Text(action.label),
    ),
  ),
  'RawAlertDialog': (context) => RawAlertDialog(
    title: 'Discard changes?',
    content: const Text('Your edits to this note will be lost.'),
    actions: [
      RawDialogAction(label: 'Keep editing', onPressed: () {}),
      RawDialogAction(
        label: 'Discard',
        isDestructiveAction: true,
        onPressed: () {},
      ),
    ],
    actionBuilder: (context, action, details) => Text(action.label),
    frameBuilder: (context, details, child) => DecoratedBox(
      decoration: const BoxDecoration(color: Color(0xFFFFFFFF)),
      child: child,
    ),
  ),
  'RawSheetRoute': (context) =>
      RawSheetRoute<void>(builder: (context) => const Text('Edit recording')),
  'RawBottomSheetRoute': (context) => RawBottomSheetRoute<void>(
    snapSizes: const [0.5, 1],
    builder: (context, details) => ListView(
      controller: details.scrollController,
      children: [for (var i = 0; i < 30; i++) Text('Row $i')],
    ),
  ),
  'RawBottomSheetDragHandle': (context) => RawBottomSheetDragHandle(
    builder: (context, states) => const SizedBox(width: 32, height: 4),
  ),
  'RawSwipeActionsController': (context) {
    final controller = _own(RawSwipeActionsController());
    return RawSwipeActions(
      controller: controller,
      endActions: [
        RawSwipeAction(label: 'Archive', onPressed: controller.close),
      ],
      actionBuilder: (context, action, details) => Text(action.label),
      child: const Text('Message'),
    );
  },
  'RawTabBar': (context) {
    const vsync = TestVSync();
    final controller = _own(RawTabController(length: 2, vsync: vsync));
    return Column(
      children: [
        RawTabBar(
          controller: controller,
          tabs: const [
            RawTab(label: 'Inbox'),
            RawTab(label: 'Sent'),
          ],
          tabBuilder: (context, tab, details) => Text(tab.label),
        ),
        Expanded(
          child: RawTabBarView(
            controller: controller,
            children: const [Text('Inbox'), Text('Sent')],
          ),
        ),
      ],
    );
  },
  'RawRovingFocusIntent': (context) {
    const vsync = TestVSync();
    final controller = _own(RawTabController(length: 2, vsync: vsync));
    return Actions(
      actions: {RawRovingFocusIntent: DoNothingAction(consumesKey: false)},
      child: RawTabBar(
        controller: controller,
        tabs: const [
          RawTab(label: 'Inbox'),
          RawTab(label: 'Sent'),
        ],
        tabBuilder: (context, tab, details) => Text(tab.label),
      ),
    );
  },
  'RawRovingFocusGroup': (context) {
    final focusNode = _own(FocusNode());
    return RawRovingFocusGroup(
      orientation: Axis.horizontal,
      child: Row(
        children: [
          RawRovingFocusItem(
            focusNode: focusNode,
            selected: true,
            onMovedTo: () {},
            child: RawButton(
              focusNode: focusNode,
              onPressed: () {},
              builder: (context, states, _) => const Text('Bold'),
            ),
          ),
        ],
      ),
    );
  },
  'RawRovingFocusItem': (context) {
    final focusNode = _own(FocusNode());
    return RawRovingFocusItem(
      focusNode: focusNode,
      onMovedTo: () {},
      child: RawButton(
        focusNode: focusNode,
        onPressed: () {},
        builder: (context, states, _) => const Text('Bold'),
      ),
    );
  },
  'RawTabGroup': (context) => RawTabGroup<String>(
    groupValue: 'overview',
    onChanged: (value) {},
    child: Row(
      children: [
        RawTabGroupTab(
          value: 'overview',
          builder: (context, states, _) => const Text('Overview'),
        ),
        const Text('·'),
        RawTabGroupTab(
          value: 'reviews',
          builder: (context, states, _) => const Text('Reviews'),
        ),
      ],
    ),
  ),
  'RawTabGroupTab': (context) => RawTabGroup<String>(
    groupValue: 'overview',
    child: RawTabGroupTab(
      value: 'overview',
      builder: (context, states, _) => const Text('Overview'),
    ),
  ),
  'DesignWindowSizeClass': (context) => DesignWindowSizeClass.fromWidth(900),
  'DesignAdaptiveShell': (context) => DesignAdaptiveShell(
    destinations: const [
      DesignNavigationDestination(label: 'Home', icon: IconData(0xe318)),
      DesignNavigationDestination(label: 'Mail', icon: IconData(0xe158)),
    ],
    selectedIndex: 0,
    onDestinationSelected: (index) {},
    destinationBuilder: (context, destination, details) =>
        Text(destination.label),
    navigationBuilder: (context, details) =>
        Row(children: details.destinations),
    body: const Text('Home'),
  ),
  'DesignAdaptiveShell.branches': (context) => DesignAdaptiveShell.branches(
    destinations: const [
      DesignNavigationDestination(label: 'Home', icon: IconData(0xe318)),
      DesignNavigationDestination(label: 'Mail', icon: IconData(0xe158)),
    ],
    selectedIndex: 0,
    onDestinationSelected: (index) {},
    destinationBuilder: (context, destination, details) =>
        Text(destination.label),
    navigationBuilder: (context, details) =>
        Row(children: details.destinations),
    branches: [
      (context) => const Text('Home'),
      (context) => const Text('Mail'),
    ],
  ),
  'DesignListDetail': (context) => DesignListDetail<String>(
    selectedItem: null,
    onSelectedItemChanged: (item) {},
    listBuilder: (context) => const Text('Inbox'),
    detailBuilder: (context, item) => Text(item),
    detailRouteBuilder: (builder) => PageRouteBuilder<void>(
      pageBuilder: (context, _, _) => builder(context),
    ),
  ),
  // 0.3.0 routes end
};

/// The host app's own layer (its router, its app chrome and its
/// manifest's annotations), which the package leaves out with its examples.
const Set<String> _hostAppOnly = {
  'routing.dart',
  'chrome.dart',
  'annotations.dart',
  // 0.3.0 tooling: the checks' examples are ui_core_test's
  // (checks_doc_examples_test.dart) and the review's ui_core_review's
  // (review_doc_examples_test.dart); drip's kit still holds the files.
  ..._checksFiles,
};

/// The checks' files, which ui_core_test and ui_core_review carry.
const Set<String> _checksFiles = {
  'alignment.dart',
  'checkable_check.dart',
  'cursor_check.dart',
  'dialog_actions_check.dart',
  'field_nodes_check.dart',
  'field_semantics_check.dart',
  'field_words_check.dart',
  'list_side_check.dart',
  'overflow_check.dart',
  'overlay_check.dart',
  'radio_group_check.dart',
  'shadow_clip_check.dart',
  'tap_target_check.dart',
  'text_field_name_check.dart',
  'tooltip_node_check.dart',
  'reading.dart',
  'shape.dart',
  'drawn_pixels.dart',
  'review.dart',
  'alignment_matrix.dart',
  'field_parts_check.dart',
  'keyline_check.dart',
  'row_check.dart',
  'spacing_check.dart',
  'width_check.dart',
};

/// A look's radio, as RadioGroupKeyboardFix's example names it: a [RawRadio]
/// on the group's registry, its face drawn in its builder.
class LookRadio<T> extends StatefulWidget {
  const LookRadio({super.key, required this.value});

  final T value;

  @override
  State<LookRadio<T>> createState() => _LookRadioState<T>();
}

class _LookRadioState<T> extends State<LookRadio<T>> {
  final _node = FocusNode();

  @override
  void dispose() {
    _node.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RawRadio<T>(
    value: widget.value,
    mouseCursor: WidgetStateMouseCursor.clickable,
    toggleable: false,
    focusNode: _node,
    autofocus: false,
    groupRegistry: RadioGroup.maybeOf<T>(context),
    enabled: true,
    builder: (context, state) => Text('${widget.value}'),
  );
}

void main() {
  tearDown(() {
    for (final dispose in _disposers) {
      dispose();
    }
    _disposers.clear();
  });

  testDocExamples(
    self: 'test/doc_examples_test.dart',
    examples: _examples,
    wrap: harness,
    skip: _hostAppOnly,
  );
}
