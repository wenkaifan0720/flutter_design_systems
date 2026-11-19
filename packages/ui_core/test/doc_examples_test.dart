// Every doc example in lib, compiled and run. Each `/// Example:` (a fenced
// dart block in the package) is written out below as the body of an entry,
// so an example that stops compiling fails analysis; the first test fails
// when lib has an example this file lacks; the rest build each widget
// example (and push each route, run each call) in a bare app.
//
// An example may name `controller` or `focusNode`: the caller's own, which
// its entry makes first, as the docs say the caller does.
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
  'DefaultDesignLocalizations': (context) =>
      const DefaultDesignLocalizations().carouselSlideLabel(0, 3),
  'DesignAnchoredOverlay': (context) => DesignAnchoredOverlay(
    anchorBuilder: (context, anchor) =>
        GestureDetector(onTap: anchor.toggle, child: const Text('More')),
    overlayBuilder: (context, info) => const Text('Details'),
  ),
  'DesignContextMenu': (context) => DesignContextMenu(
    menuChildren: [DesignMenuEntry(label: 'Copy', onPressed: () {})],
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
  'DesignOverlayPadding': (context) => const DesignOverlayPadding(
    padding: EdgeInsetsDirectional.only(start: 280),
    child: Text('A page beside the side bar'),
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
      onEditingComplete: field.submit,
    ),
    optionBuilder: (context, option, states) => Text(option),
  ),
  'DesignSearchError': (context) =>
      DesignSearchError(error: StateError('offline'), retry: () {}),
  'DesignCommandPalette': (context) => DesignCommandPalette(
    commands: const [DesignCommand(label: 'New file')],
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
  'designSwipeBack': (context) => designSwipeBack({
    TargetPlatform.iOS: const FadeUpwardsPageTransitionsBuilder(),
  }),
  'DesignSwipeBackPageTransitionsBuilder': (context) =>
      const DesignSwipeBackPageTransitionsBuilder(
        FadeUpwardsPageTransitionsBuilder(),
      ),
  'DesignPressable': (context) => DesignPressable(
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
  'DesignTapTarget, on its start edge': (context) {
    void onPressed() {}
    Widget face(BuildContext context, Set<WidgetState> states, Widget? child) =>
        const Text('Add');
    return DesignTapTarget(
      alignment: AlignmentDirectional.centerStart,
      child: DesignPressable(onPressed: onPressed, builder: face),
    );
  },
  'DesignPressable, a small icon in its tap target': (context) {
    void play() {}
    return DesignTapTarget(
      child: DesignPressable(
        semanticLabel: 'Play',
        onPressed: play,
        builder: (context, states, _) => const SizedBox.square(dimension: 16),
      ),
    );
  },
  'DesignTapTarget': (context) {
    void onPressed() {}
    Widget face(BuildContext context, Set<WidgetState> states, Widget? child) =>
        const Text('Add');
    return DesignTapTarget(
      child: DesignPressable(onPressed: onPressed, builder: face),
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
      onEditingComplete: field.submit,
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
  'DesignWheelColumn': (context) => DesignWheelColumn(
    itemCount: 12,
    itemLabel: (index) => 'Month ${index + 1}',
    semanticLabel: 'Month',
  ),
  'DesignWheelPicker': (context) => DesignWheelPicker(
    columns: (selection) => [
      DesignWheelColumn(
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
  'DesignTimeOfDay': (context) => Text(
    DesignLocalizations.of(context)
        .formatTimeOfDay(const DesignTimeOfDay(hour: 15, minute: 5)),
  ),
  'DesignDateField': (context) => DesignDateField(
    value: DateTime(2026, 11, 16),
    onChanged: (day) {},
    segmentBuilder: (context, details) => Text(details.text),
  ),
  'DesignTimeField': (context) => DesignTimeField(
    value: const DesignTimeOfDay(hour: 9, minute: 30),
    onChanged: (time) {},
    segmentBuilder: (context, details) => Text(details.text),
  ),
  'DesignNumberField': (context) => DesignNumberField(
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
  'DesignRating': (context) => DesignRating(
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
    builder: (context, details) => DesignDialog(
      title: 'Delete the draft?',
      content: const Text('It cannot be brought back.'),
      actions: [
        DesignDialogAction(
          label: 'Cancel',
          onPressed: () => Navigator.of(context).pop(false),
        ),
        DesignDialogAction(
          label: 'Delete',
          isDestructiveAction: true,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
      actionBuilder: (context, action, details) => Text(action.label),
    ),
  ),
  'DesignDialog': (context) => DesignDialog(
    title: 'Discard changes?',
    content: const Text('Your edits to this note will be lost.'),
    actions: [
      DesignDialogAction(label: 'Keep editing', onPressed: () {}),
      DesignDialogAction(
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
  'DesignSheetPageRoute': (context) => DesignSheetPageRoute<void>(
    builder: (context) => const Text('Edit recording'),
  ),
  'DesignBottomSheetRoute': (context) => DesignBottomSheetRoute<void>(
    snapSizes: const [0.5, 1],
    builder: (context, details) => ListView(
      controller: details.scrollController,
      children: [for (var i = 0; i < 30; i++) Text('Row $i')],
    ),
  ),
  'DesignBottomSheetDragHandle': (context) => DesignBottomSheetDragHandle(
    builder: (context, states) => const SizedBox(width: 32, height: 4),
  ),
  'DesignSwipeActionsController': (context) {
    final controller = _own(DesignSwipeActionsController());
    return DesignSwipeActions(
      controller: controller,
      endActions: [
        DesignSwipeAction(label: 'Archive', onPressed: controller.close),
      ],
      actionBuilder: (context, action, details) => Text(action.label),
      child: const Text('Message'),
    );
  },
  'DesignTabBar': (context) {
    const vsync = TestVSync();
    final controller = _own(DesignTabController(length: 2, vsync: vsync));
    return Column(
      children: [
        DesignTabBar(
          controller: controller,
          tabs: const [
            DesignTab(label: 'Inbox'),
            DesignTab(label: 'Sent'),
          ],
          tabBuilder: (context, tab, details) => Text(tab.label),
        ),
        Expanded(
          child: DesignTabView(
            controller: controller,
            children: const [Text('Inbox'), Text('Sent')],
          ),
        ),
      ],
    );
  },
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
  // (checks_doc_examples_test.dart); drip's kit still holds the files.
  ..._checksFiles,
};

/// The checks' files, which ui_core_test carries.
const Set<String> _checksFiles = {
  'alignment.dart',
  'checkable_check.dart',
  'cursor_check.dart',
  'field_parts_check.dart',
  'field_semantics_check.dart',
  'radio_group_check.dart',
  'shadow_clip_check.dart',
  'spacing_check.dart',
  'tap_target_check.dart',
  'drawn_pixels.dart',
};

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
