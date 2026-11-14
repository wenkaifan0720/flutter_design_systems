// The behaviour law (looks/COMPLETE.md §2a) over Expressive. Every part that takes a callback is enumerated from the
// source, so a new one fails here until it is named in the table. Each one: Tab reaches it and its focus layer shows
// (Compose draws focus as a state layer, not a ring), Enter and Space press it, with no callback it takes no focus and
// its face is told it is disabled, a hover reaches its face's states, and under Reduce Motion a press settles and
// nothing loops. Each part lays out with no exception at 390, 768, 1024 and 1440, at text scale 2.0 and right to left
// (the pattern pages: behaviour_pages_test.dart).
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/material_expressive_host.dart';
import 'package:material_expressive_ui/src/material_expressive/internal/state_face.dart'
    show ExpressiveBareField;
import 'package:material_expressive_ui/src/material_expressive/internal/tokens/behavior.g.dart';
import 'package:material_expressive_ui/src/material_expressive/internal/tokens/list_tokens.g.dart';

/// One interactive part: [build] wires its main callback to `hit`, or none when `hit` is null.
class _Part {
  const _Part(
    this.build, {
    this.keys = true,
    this.focus = true,
    this.pressable = true,
    this.disables = true,
    this.crushes,
  });
  final Widget Function(VoidCallback? hit) build;

  /// Why a word of it stands crushed at 2.0 text on a phone, where Compose's own layout crushes it the same way.
  final String? crushes;

  /// Enter and Space on its first focus stop call its main callback.
  final bool keys;

  /// Tab stops on it. False for a part that takes no focus by design (an overlay's anchor, a transition).
  final bool focus;

  /// It stands on Expressive's pressable (Compose's indication on an [InkResponse]), so its face is handed the states.
  final bool pressable;

  /// With no callback it takes no focus (a text field still takes text, a picker still pages).
  final bool disables;
}

ValueChanged<T>? _on<T>(VoidCallback? hit) => hit == null ? null : (_) => hit();

/// A part that only lays out here: it is an overlay, a layer or a transition, and its controls are other parts.
const _layoutOnly = (
  focus: false,
  keys: false,
  pressable: false,
  disables: false,
);

final _parts = <String, _Part>{
  'ExpressivePressable': _Part(
    (hit) => Builder(
      builder: (context) {
        final t = context.expressiveTheme;
        return ExpressivePressable(
          shapes: ExpressivePressShapes.all(
            t.shapes.of(ListTokens.itemContainerShape),
          ),
          motion: ListItemBehavior.shapeMotion,
          color: t.colors.surfaceContainer,
          contentColor: t.colors.onSurface,
          semanticLabel: 'A tile',
          onPressed: hit,
          child: const Padding(
            padding: EdgeInsets.all(ExpressiveSpacing.s16),
            child: Text('A tile'),
          ),
        );
      },
    ),
  ),
  'ExpressiveButton': _Part(
    (hit) => ExpressiveFilledButton('Book', onPressed: hit),
  ),
  'ExpressiveToggleButton': _Part(
    (hit) => ExpressiveToggleButton(
      value: false,
      onChanged: _on(hit),
      label: 'Mute',
    ),
  ),
  // The first segment is not the chosen one, so its press is a change.
  'ExpressiveSegmentedButton': _Part(
    (hit) => ExpressiveSegmentedButton<String>(
      segments: const [
        ExpressiveButtonSegment('day', 'Day'),
        ExpressiveButtonSegment('week', 'Week'),
      ],
      value: 'week',
      onChanged: _on(hit),
    ),
  ),
  'ExpressiveMultiChoiceSegmentedButton': _Part(
    (hit) => ExpressiveMultiChoiceSegmentedButton<String>(
      segments: const [
        ExpressiveButtonSegment('wifi', 'Wi-Fi'),
        ExpressiveButtonSegment('pool', 'Pool'),
      ],
      value: const {'pool'},
      onChanged: _on(hit),
    ),
  ),
  'ExpressiveLink': _Part((hit) => ExpressiveLink('The menu', onPressed: hit)),
  'ExpressiveBreadcrumbItem': _Part(
    (hit) => ExpressiveBreadcrumb(
      items: [
        ExpressiveBreadcrumbItem('Orders', onPressed: hit),
        const ExpressiveBreadcrumbItem('#1042'),
      ],
    ),
  ),
  'ExpressiveFileUpload': _Part(
    (hit) => ExpressiveFileUpload(label: 'Drop a receipt here', onBrowse: hit),
  ),
  'ExpressiveIconButton': _Part(
    (hit) => ExpressiveIconButton(
      ExpressiveSymbols.favorite,
      onPressed: hit,
      semanticLabel: 'Keep',
    ),
  ),
  'ExpressiveIconToggleButton': _Part(
    (hit) => ExpressiveIconToggleButton(
      ExpressiveSymbols.favorite,
      value: false,
      onChanged: _on(hit),
      semanticLabel: 'Keep',
    ),
  ),
  // With no callback the leading half is disabled; the trailing half still opens its menu (Compose's SplitButton).
  'ExpressiveSplitButton': _Part(
    (hit) => ExpressiveSplitButton('Send', onPressed: hit),
    disables: false,
  ),
  'ExpressiveSplitLeadingButton': _Part(
    (hit) =>
        ExpressiveSplitLeadingButton(onPressed: hit, child: const Text('Send')),
  ),
  'ExpressiveSplitTrailingButton': _Part(
    (hit) => ExpressiveSplitTrailingButton(
      onPressed: hit,
      semanticLabel: 'More',
      child: const Icon(ExpressiveSymbols.keyboardArrowDown),
    ),
  ),
  'ExpressiveAppBarAction': _Part(
    (hit) => ExpressiveAppBarAction(
      ExpressiveSymbols.share,
      label: 'Share',
      onPressed: hit,
    ),
  ),
  // A floating toolbar sizes its FAB; here a 56 square stands in.
  'ExpressiveToolbarFab': _Part(
    (hit) => SizedBox.square(
      dimension: 56,
      child: ExpressiveToolbarFab(
        icon: ExpressiveSymbols.add,
        onPressed: hit,
        semanticLabel: 'Add',
      ),
    ),
  ),
  'ExpressiveFloatingActionButton': _Part(
    (hit) => ExpressiveFloatingActionButton(
      icon: ExpressiveSymbols.add,
      onPressed: hit,
      semanticLabel: 'Add',
    ),
  ),
  'ExpressiveFloatingActionButton.extended': _Part(
    (hit) => ExpressiveFloatingActionButton.extended(
      icon: ExpressiveSymbols.edit,
      label: 'Compose',
      onPressed: hit,
    ),
  ),
  // With no callback the menu still opens and closes itself, as Material's MenuAnchor.
  'ExpressiveFabMenu': _Part(
    (hit) => ExpressiveHeroMoment(
      child: ExpressiveFabMenu(
        icon: ExpressiveSymbols.add,
        semanticLabel: 'Create',
        items: [
          ExpressiveFabMenuItem(
            icon: ExpressiveSymbols.edit,
            label: 'Note',
            onPressed: (_) {},
          ),
          ExpressiveFabMenuItem(
            icon: ExpressiveSymbols.share,
            label: 'Share',
            onPressed: (_) {},
          ),
        ],
        onExpandedChanged: _on(hit),
      ),
    ),
    disables: false,
  ),
  // A shell action always does something: it asserts an action, a callback or a menu.
  'ExpressiveShellAction': _Part(
    (hit) => ExpressiveShellAction(
      icon: ExpressiveSymbols.add,
      label: 'New',
      onPressed: hit == null ? null : (_) => hit(),
    ),
    disables: false,
  ),
  'ExpressiveCard': _Part(
    (hit) => ExpressiveCard(onPressed: hit, child: const Text('Ridge trail')),
  ),
  'ExpressiveCarouselView': _Part(
    (hit) => SizedBox(
      width: 360,
      child: ExpressiveCarouselView.multiBrowse(
        itemCount: 4,
        height: 200,
        itemBuilder: (context, i) => ColoredBox(
          color: context.expressiveTheme.colors.secondaryContainer,
          child: Center(child: Text('Trip $i')),
        ),
        onItemTap: _on(hit),
      ),
    ),
  ),
  // The dots are one adjustable node (increase, decrease) a tap either side moves, not a focus stop: the pager they
  // name takes the keys.
  'ExpressivePageDots': _Part(
    (hit) =>
        ExpressivePageDots(count: 5, selectedIndex: 1, onChanged: _on(hit)),
    focus: false,
    keys: false,
    pressable: false,
    disables: false,
  ),
  'ExpressiveChip': _Part(
    (hit) => ExpressiveChip.assist('Directions', onPressed: hit),
  ),
  // Its onChanged is required: a group of choices always chooses.
  'ExpressiveChoiceGroup': _Part(
    (hit) => ExpressiveChoiceGroup<String>.single(
      options: const [
        ExpressiveChoiceOption(value: 'cuff', title: 'Arm cuff'),
        ExpressiveChoiceOption(value: 'hand', title: 'By hand'),
      ],
      value: null,
      onChanged: (_) => hit?.call(),
    ),
    disables: false,
  ),
  'ExpressiveChoiceTile': _Part(
    (hit) => ExpressiveChoiceTile(title: 'Arm cuff', onPressed: hit),
  ),
  'ExpressiveRating': _Part(
    (hit) => ExpressiveRating(value: 3, onChanged: _on(hit)),
  ),
  'ExpressiveBannerAction': _Part(
    (hit) => ExpressiveBanner(
      message: 'You are offline',
      actions: [ExpressiveBannerAction('Retry', onPressed: hit)],
    ),
  ),
  'ExpressiveErrorState': _Part(
    (hit) => ExpressiveErrorState(title: 'Could not load', onRetry: hit),
  ),
  'ExpressiveEmptyState': _Part(
    (hit) => ExpressiveEmptyState(
      icon: ExpressiveSymbols.inbox,
      title: 'Nothing here yet',
      actionLabel: 'Add one',
      onAction: hit,
    ),
  ),
  'ExpressiveSuccessState': _Part(
    (hit) => ExpressiveSuccessState(
      title: 'Table booked',
      actionLabel: 'Done',
      onAction: hit,
    ),
  ),
  'ExpressiveSnackBar': _Part(
    (hit) => ExpressiveSnackBar('Saved', actionLabel: 'Undo', onAction: hit),
  ),
  'ExpressiveListTile': _Part(
    (hit) => ExpressiveListTile(title: const Text('Wi-Fi'), onTap: hit),
  ),
  // With no callback it still opens and closes itself, as Material's ExpansionTile.
  'ExpressiveDisclosure': _Part(
    (hit) => ExpressiveDisclosure(
      title: const Text('Shipping'),
      onExpansionChanged: _on(hit),
      child: const Text('Ships in two days.'),
    ),
    disables: false,
  ),
  'ExpressiveTableRow': _Part(
    (hit) => ExpressiveTable(
      columns: const [
        ExpressiveTableColumn('Plant', flex: 2),
        ExpressiveTableColumn('Water', numeric: true),
      ],
      rows: [
        ExpressiveTableRow(const ['Fern', '200 ml'], onPressed: hit),
      ],
    ),
  ),
  'ExpressiveMenuItem': _Part(
    (hit) => ExpressiveMenuSurface(
      groups: [
        ExpressiveMenuGroup([ExpressiveMenuItem('Edit', onPressed: hit)]),
      ],
    ),
  ),
  'ExpressiveMenuCheckItem': _Part(
    (hit) => ExpressiveMenuSurface(
      groups: [
        ExpressiveMenuGroup([
          ExpressiveMenuCheckItem('Bold', value: false, onChanged: _on(hit)),
        ]),
      ],
    ),
  ),
  'ExpressiveMenuRadioItem': _Part(
    (hit) => ExpressiveMenuSurface(
      groups: [
        ExpressiveMenuGroup([
          ExpressiveMenuRadioItem('Small', selected: false, onSelected: hit),
        ]),
      ],
    ),
  ),
  // A dialog's or a sheet's action is enabled by `enabled`: with no callback it still closes with its value.
  'ExpressiveDialogAction': _Part(
    (hit) => ExpressiveDialog(
      title: 'Delete the draft?',
      actions: [
        ExpressiveDialogAction('Delete', onPressed: hit, closesDialog: false),
      ],
    ),
    disables: false,
  ),
  'ExpressiveRichTooltip': _Part(
    (hit) => ExpressiveRichTooltip(
      text: 'Saved trips live here.',
      actionLabel: 'Learn more',
      onAction: hit,
    ),
  ),
  'ExpressiveTooltip': _Part(
    (hit) => ExpressiveTooltip.rich(
      text: 'Saved trips live here.',
      actionLabel: 'Learn more',
      onAction: hit,
      child: const Icon(ExpressiveSymbols.info),
    ),
    focus: _layoutOnly.focus,
    keys: _layoutOnly.keys,
    pressable: _layoutOnly.pressable,
    disables: _layoutOnly.disables,
  ),
  'ExpressiveCoachMark': _Part(
    (hit) => ExpressiveCoachMark(
      visible: true,
      text: 'Your trips are here now.',
      actionLabel: 'Got it',
      onAction: hit,
      child: const Text('Trips'),
    ),
    focus: _layoutOnly.focus,
    keys: _layoutOnly.keys,
    pressable: _layoutOnly.pressable,
    disables: _layoutOnly.disables,
  ),
  // The pickers' first stop pages or switches mode; with no callback the days are inert but the months still page.
  'ExpressiveDatePicker': _Part(
    (hit) => ExpressiveDatePicker(currentDate: _today, onChanged: _on(hit)),
    keys: false,
    disables: false,
  ),
  'ExpressiveDateRangePicker': _Part(
    (hit) => SizedBox(
      height: 640,
      child: ExpressiveDateRangePicker(
        currentDate: _today,
        onChanged: hit == null ? null : (_, _) => hit(),
      ),
    ),
    keys: false,
    pressable: false,
    disables: false,
    crushes:
        "Compose's DateRangePickerHeadline sets the end after the start in a Row with no weight, so at 2.0 text on a "
        'phone "End date" gets what is left (call for the lead in DECISIONS.md)',
  ),
  'ExpressiveDockedDatePicker': _Part(
    (hit) => ExpressiveDockedDatePicker(
      label: 'Date',
      currentDate: _today,
      onChanged: _on(hit),
    ),
    keys: false,
    pressable: false,
    disables: false,
  ),
  'ExpressiveScrollField': _Part(
    (hit) => ExpressiveScrollField(
      itemCount: 24,
      value: 7,
      label: 'Hour',
      onChanged: _on(hit),
    ),
    keys: false,
    pressable: false,
  ),
  'ExpressiveCheckbox': _Part(
    (hit) => ExpressiveCheckbox(
      value: false,
      onChanged: _on(hit),
      semanticLabel: 'Done',
    ),
  ),
  'ExpressiveCheckboxRow': _Part(
    (hit) => ExpressiveCheckboxRow(
      label: 'Email me receipts',
      value: false,
      onChanged: _on(hit),
    ),
  ),
  'ExpressiveRadio': _Part(
    (hit) => ExpressiveRadio(
      selected: false,
      onPressed: hit,
      semanticLabel: 'Monthly',
    ),
  ),
  'ExpressiveRadioRow': _Part(
    (hit) =>
        ExpressiveRadioRow(label: 'Monthly', selected: false, onPressed: hit),
  ),
  'ExpressiveRadioGroup': _Part(
    (hit) => ExpressiveRadioGroup<String>(
      options: const [
        ExpressiveRadioOption(value: 'month', label: 'Monthly'),
        ExpressiveRadioOption(value: 'year', label: 'Yearly'),
      ],
      value: 'year',
      onChanged: _on(hit),
    ),
  ),
  'ExpressiveSwitch': _Part(
    (hit) => ExpressiveSwitch(
      value: false,
      onChanged: _on(hit),
      semanticLabel: 'Alerts',
    ),
  ),
  'ExpressiveSwitchRow': _Part(
    (hit) => ExpressiveSwitchRow(
      label: 'Wi-Fi calling',
      value: false,
      onChanged: _on(hit),
    ),
  ),
  'ExpressiveSlider': _Part(
    (hit) => ExpressiveSlider(
      value: 0.5,
      onChanged: _on(hit),
      semanticLabel: 'Volume',
    ),
    keys: false,
    pressable: false,
  ),
  'ExpressiveVerticalSlider': _Part(
    (hit) => SizedBox(
      height: 240,
      child: ExpressiveVerticalSlider(
        value: 0.5,
        onChanged: _on(hit),
        semanticLabel: 'Level',
      ),
    ),
    keys: false,
    pressable: false,
  ),
  'ExpressiveRangeSlider': _Part(
    (hit) => ExpressiveRangeSlider(
      start: 0.2,
      end: 0.8,
      onChanged: hit == null ? null : (_, _) => hit(),
    ),
    keys: false,
    pressable: false,
  ),
  'ExpressiveNumberField': _Part(
    (hit) => ExpressiveNumberField(
      value: 2,
      max: 8,
      label: 'Guests',
      onChanged: _on(hit),
    ),
  ),
  'ExpressiveBottomSheet': _Part(
    (hit) => SizedBox(
      height: 480,
      child: ExpressiveBottomSheet(
        initialValue: ExpressiveSheetValue.expanded,
        onDismissRequest: hit,
        child: const Padding(
          padding: EdgeInsets.all(ExpressiveSpacing.s16),
          child: Text('Filters'),
        ),
      ),
    ),
    focus: _layoutOnly.focus,
    keys: _layoutOnly.keys,
    pressable: _layoutOnly.pressable,
    disables: _layoutOnly.disables,
  ),
  'ExpressiveSnackBarTransition': _Part(
    (hit) =>
        ExpressiveSnackBarTransition(onExited: hit, child: const Text('Saved')),
    focus: _layoutOnly.focus,
    keys: _layoutOnly.keys,
    pressable: _layoutOnly.pressable,
    disables: _layoutOnly.disables,
  ),
  // The fields take text with or without a callback; Enter is a newline or a submit, not a press.
  'ExpressiveTextField': _Part(
    (hit) => ExpressiveTextField(label: 'Name', onChanged: _on(hit)),
    keys: false,
    pressable: false,
    disables: false,
  ),
  'ExpressiveTextArea': _Part(
    (hit) => ExpressiveTextArea(label: 'Note', onChanged: _on(hit)),
    keys: false,
    pressable: false,
    disables: false,
  ),
  'ExpressiveInputOtp': _Part(
    (hit) => ExpressiveInputOtp(length: 4, onChanged: _on(hit)),
    keys: false,
    pressable: false,
    disables: false,
  ),
  'ExpressiveSearchField': _Part(
    (hit) => ExpressiveSearchField(hintText: 'Search', onChanged: _on(hit)),
    keys: false,
    pressable: false,
    disables: false,
  ),
  'ExpressiveSearchBar': _Part(
    (hit) => ExpressiveSearchBar(hintText: 'Search', onOpen: hit),
    keys: false,
    disables: false,
  ),
  'ExpressiveSelect': _Part(
    (hit) => ExpressiveSelect<String>(
      label: 'Fruit',
      options: const [
        ExpressiveSelectOption('apple', 'Apple'),
        ExpressiveSelectOption('pear', 'Pear'),
      ],
      value: null,
      onChanged: _on(hit),
    ),
    keys: false,
    pressable: false,
    disables: false,
  ),
  'ExpressiveCombobox': _Part(
    (hit) => ExpressiveCombobox<String>(
      label: 'Fruit',
      options: const [
        ExpressiveSelectOption('apple', 'Apple'),
        ExpressiveSelectOption('pear', 'Pear'),
      ],
      onChanged: _on(hit),
    ),
    keys: false,
    pressable: false,
    disables: false,
  ),
  // Round 4's parts. Those on ui_core's behaviours paint ui_core's states on
  // their own faces (not Expressive's pressable), so they are fields: Tab
  // reaches them and they lay out everywhere; their keys and disabling are
  // ui_core's, tested in ui_core and in ui_core_rows_test.
  'ExpressiveBareField': _Part(
    (hit) => _OwnedBareField(onChanged: _on(hit)),
    keys: false,
    pressable: false,
    disables: false,
  ),
  'ExpressivePasswordField': _Part(
    (hit) => ExpressivePasswordField(label: 'Password', onChanged: _on(hit)),
    keys: false,
    pressable: false,
    disables: false,
  ),
  'ExpressiveInputGroup': _Part(
    (hit) => ExpressiveInputGroup(
      hintText: 'example.com',
      semanticLabel: 'Website',
      leading: <Widget>[ExpressiveInputGroup.text('https://')],
      onChanged: _on(hit),
    ),
    keys: false,
    pressable: false,
    disables: false,
  ),
  'ExpressiveMultiSelect': _Part(
    (hit) => ExpressiveMultiSelect<String>(
      label: 'Sizes',
      options: const [
        ExpressiveSelectOption('s', 'Small'),
        ExpressiveSelectOption('m', 'Medium'),
      ],
      values: const <String>['s'],
      onChanged: _on(hit),
    ),
    keys: false,
    pressable: false,
    disables: false,
  ),
  'ExpressiveToggleGroup': _Part(
    (hit) => ExpressiveToggleGroup<String>(
      label: 'Alignment',
      value: null,
      onChanged: _on(hit),
      segments: const [
        ExpressiveButtonSegment('start', 'Start'),
        ExpressiveButtonSegment('end', 'End'),
      ],
    ),
    keys: false,
    pressable: false,
    disables: false,
  ),
  'ExpressiveMenuBarEntry': _Part(
    (hit) => ExpressiveMenuBar(
      menus: [
        ExpressiveMenuBarEntry(
          'File',
          children: [ExpressiveMenuBarEntry('New', onPressed: hit)],
        ),
      ],
    ),
    keys: false,
    pressable: false,
    disables: false,
  ),
  'ExpressiveCalendar': _Part(
    (hit) => ExpressiveCalendar(
      firstDate: DateTime(2026),
      lastDate: DateTime(2027, 12, 31),
      currentDate: _today,
      onChanged: _on(hit),
    ),
    keys: false,
    pressable: false,
    disables: false,
  ),
  'ExpressiveColorPicker': _Part(
    (hit) => ExpressiveColorPicker(
      value: const Color(0xFF6750A4),
      onChanged: _on(hit),
    ),
    keys: false,
    pressable: false,
    disables: false,
  ),
  'ExpressiveDataTable': _Part(
    (hit) => ExpressiveDataTable<List<String>>(
      controller: _orders(),
      onActivate: _on(hit),
      cellBuilder: (context, row, column) => Text(row[int.parse(column.id)]),
    ),
    keys: false,
    pressable: false,
    disables: false,
  ),
  'ExpressiveResizable': _Part(
    (hit) => SizedBox(
      height: 200,
      child: ExpressiveResizable(
        initialFraction: 0.4,
        onChanged: _on(hit),
        first: const Center(child: Text('Folders')),
        second: const Center(child: Text('Messages')),
      ),
    ),
    keys: false,
    pressable: false,
    disables: false,
  ),
  // Drawn whole: the sheet's close and the status view's action are
  // Expressive's own buttons.
  'ExpressiveSheet': _Part(
    (hit) => SizedBox(
      width: 360,
      height: 480,
      child: ExpressiveSheet(
        title: 'Filters',
        onClose: hit,
        child: const Text('Open orders only'),
      ),
    ),
  ),
  'ExpressiveStatusView': _Part(
    (hit) => ExpressiveStatusView.error(
      title: 'Could not load',
      message: 'Check your connection',
      onRetry: hit,
    ),
  ),
};

/// A bare field owning its controller and focus, as the parts that hold one
/// do.
class _OwnedBareField extends StatefulWidget {
  const _OwnedBareField({this.onChanged});

  final ValueChanged<String>? onChanged;

  @override
  State<_OwnedBareField> createState() => _OwnedBareFieldState();
}

class _OwnedBareFieldState extends State<_OwnedBareField> {
  final _controller = TextEditingController();
  final _node = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _node.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 240,
    child: ExpressiveBareField(
      controller: _controller,
      focusNode: _node,
      hintText: 'Type a tag',
      semanticLabel: 'Tags',
      onChanged: widget.onChanged,
    ),
  );
}

DesignTableController<List<String>> _orders() =>
    DesignTableController<List<String>>(
      rows: const [
        ['#4821', 'Ada Okafor', '128.40'],
        ['#4822', 'Ben Ito', '42.00'],
      ],
      rowKey: (row) => row.first,
      columns: [
        DesignTableColumn<List<String>>(
          id: '0',
          label: 'Order',
          sortKey: (row) => row[0],
        ),
        const DesignTableColumn<List<String>>(id: '1', label: 'Customer'),
      ],
    );

final _today = DateTime(2026, 11, 4);

Set<String> _interactive() {
  final found = <String>{};
  final cls = RegExp(
    r'^(?:(?:abstract|base|final|sealed|interface) )*class (Expressive\w+)[^{]*\{(.*?)^\}',
    multiLine: true,
    dotAll: true,
  );
  final cb = RegExp(
    r'final (?:VoidCallback|ValueChanged<(?:[^<>]|<[^<>]*>)+>|void Function\([^)]*\))\? \w+',
  );
  for (final file in Directory(
    'lib/src/material_expressive',
  ).listSync(recursive: true).whereType<File>()) {
    if (!file.path.endsWith('.dart')) continue;
    for (final m in cls.allMatches(file.readAsStringSync())) {
      if (cb.hasMatch(m[2]!)) found.add(m[1]!);
    }
  }
  return found;
}

final ExpressiveThemeData _light = ExpressiveThemeData.preset(
  'baseline',
  Brightness.light,
);

Widget _host(
  Widget child, {
  bool still = false,
  double scale = 1,
  TextDirection direction = TextDirection.ltr,
}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  localizationsDelegates: const [
    DefaultDesignLocalizations.delegate,
    DefaultMaterialLocalizations.delegate,
    DefaultWidgetsLocalizations.delegate,
  ],
  builder: (context, page) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(disableAnimations: still, textScaler: TextScaler.linear(scale)),
    child: ExpressiveHost(
      light: _light,
      brightness: Brightness.light,
      child: Directionality(textDirection: direction, child: page!),
    ),
  ),
  home: SingleChildScrollView(
    child: Padding(
      padding: const EdgeInsets.all(ExpressiveSpacing.s16),
      child: Center(
        child: KeyedSubtree(key: _part, child: child),
      ),
    ),
  ),
);

Future<void> _size(
  WidgetTester tester,
  double width, [
  double height = 1000,
]) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

const _part = ValueKey('part');

bool _focusInPart(WidgetTester tester) {
  final focused = FocusManager.instance.primaryFocus?.context;
  if (focused == null) return false;
  final part = find.byKey(_part).evaluate().single;
  var inside = false;
  focused.visitAncestorElements((e) {
    if (e == part) inside = true;
    return !inside;
  });
  return inside;
}

/// Every error a build reports, each with the library line of the widget that raised it, so a failure names its
/// place rather than only the first of several.
Future<List<String>> _faults(Future<void> Function() body) async {
  final seen = <String>[];
  final before = FlutterError.onError;
  FlutterError.onError = (d) {
    final at = RegExp(r'lib/src/[\w/]+\.dart:\d+')
        .firstMatch(d.toString())
        ?.group(0);
    seen.add(
      '${d.exceptionAsString().split('\n').first} (${at ?? 'no place'})',
    );
  };
  try {
    await body();
  } finally {
    FlutterError.onError = before;
  }
  return seen;
}

/// A word's column: narrow, a word broken over three lines or more (one line clipped under a mask is not one).
List<String> _crushed(WidgetTester tester) => [
  for (final p in tester.renderObjectList<RenderParagraph>(
    find.byType(RichText, skipOffstage: false),
  ))
    if (p.text.toPlainText().trim().length >= 8 &&
        p.size.width < 72 &&
        p.size.height >= 2.5 * p.getMinIntrinsicHeight(double.infinity))
      '"${p.text.toPlainText().trim()}" ${p.size.width.toStringAsFixed(0)}x${p.size.height.toStringAsFixed(0)}',
];

/// The ink responses in the part: Expressive's pressable hands its states to one.
List<InkResponse> _inks(WidgetTester tester) => tester
    .widgetList<InkResponse>(
      find.descendant(
        of: find.byKey(_part),
        matching: find.byWidgetPredicate((w) => w is InkResponse),
      ),
    )
    .toList();

Set<WidgetState> _statesOf(InkResponse ink) =>
    ink.statesController?.value ?? const <WidgetState>{};

/// The part's first ink that takes a press (a closed menu's items stand disabled behind its button).
Finder _live() => find
    .descendant(
      of: find.byKey(_part),
      matching: find.byWidgetPredicate(
        (w) => w is InkResponse && !_statesOf(w).contains(WidgetState.disabled),
      ),
    )
    .first;

void main() {
  test('every part that takes a callback is named in the table', () {
    final found = _interactive();
    // A key names a class, or a class's named constructor (`.extended`).
    final classes = _parts.keys.map((key) => key.split('.').first).toSet();
    expect(
      found.difference(classes),
      isEmpty,
      reason: 'a new control: add it to the table',
    );
    expect(
      classes.difference(found),
      isEmpty,
      reason: 'gone from the library: take it out',
    );
  });

  test('no part keeps a press of its own: every tap stands on Expressive\'s pressable', () {
    // The gesture detectors left are drags (sliders, the sheet, the carousel, a list item's swipe, the pickers'
    // wheels), the tooltip's long press and the barriers a tap outside dismisses, none of them a press. A new one is
    // a part pressing on its own: put it on ExpressivePressable.
    const allowed = {
      'app_bar.dart': 1,
      'carousel.dart': 2,
      'chips.dart': 1,
      'fab.dart': 1,
      'lists.dart': 2,
      'menus.dart': 2,
      'overlays.dart': 1,
      'pickers.dart': 3,
      'select.dart': 1,
      'selection.dart': 1,
      'split_button.dart': 1,
      'sheet.dart': 2,
      'sliders.dart': 2,
      'text_fields.dart': 1,
    };
    for (final file in Directory(
      'lib/src/material_expressive',
    ).listSync(recursive: true).whereType<File>()) {
      final name = file.uri.pathSegments.last;
      final n = RegExp(r'GestureDetector\(')
          .allMatches(file.readAsStringSync())
          .length;
      expect(
        n,
        lessThanOrEqualTo(allowed[name] ?? 0),
        reason: '$name has $n GestureDetector(s)',
      );
    }
  });

  for (final MapEntry(key: name, value: part) in _parts.entries) {
    group(name, () {
      if (part.focus) {
        testWidgets(
          'Tab reaches it and its focus layer shows; Enter and Space press it',
          (tester) async {
            await _size(tester, 390);
            var hits = 0;
            await tester.pumpWidget(
              _host(part.build(() => hits++), still: true),
            );
            await tester.pump();
            FocusManager.instance.highlightStrategy =
                FocusHighlightStrategy.alwaysTraditional;
            addTearDown(
              () => FocusManager.instance.highlightStrategy =
                  FocusHighlightStrategy.automatic,
            );
            await tester.sendKeyEvent(LogicalKeyboardKey.tab);
            await tester.pump();
            expect(
              _focusInPart(tester),
              isTrue,
              reason: 'Tab did not reach $name',
            );
            if (part.pressable) {
              final focused = _inks(tester)
                  .where((i) => _statesOf(i).contains(WidgetState.focused));
              expect(
                focused,
                isNotEmpty,
                reason: 'the focused press was not told',
              );
              final layer = focused.first.overlayColor?.resolve(const {
                WidgetState.focused,
              });
              expect(layer?.a ?? 0, greaterThan(0), reason: 'no focus layer');
            }
            if (part.keys) {
              await tester.sendKeyEvent(LogicalKeyboardKey.enter);
              await tester.pump();
              final afterEnter = hits;
              expect(afterEnter, greaterThan(0), reason: 'Enter did nothing');
              if (_focusInPart(tester)) {
                await tester.sendKeyEvent(LogicalKeyboardKey.space);
                await tester.pump();
                expect(
                  hits,
                  greaterThan(afterEnter),
                  reason: 'Space did nothing',
                );
              }
            }
            await tester.pumpWidget(const SizedBox());
          },
        );
      }

      if (part.disables) {
        testWidgets('with no callback it takes no focus and its face is told', (
          tester,
        ) async {
          await _size(tester, 390);
          await tester.pumpWidget(_host(part.build(null), still: true));
          await tester.pump();
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pump();
          expect(
            _focusInPart(tester),
            isFalse,
            reason: 'a disabled $name took focus',
          );
          for (final ink in _inks(tester)) {
            if (ink.statesController == null) continue;
            expect(_statesOf(ink), contains(WidgetState.disabled));
          }
        });
      }

      if (part.pressable) {
        testWidgets('a hover reaches its face', (tester) async {
          await _size(tester, 390);
          await tester.pumpWidget(_host(part.build(() {}), still: true));
          await tester.pump();
          final first = _live();
          final mouse = await tester.createGesture(
            kind: PointerDeviceKind.mouse,
          );
          await mouse.addPointer(location: Offset.zero);
          addTearDown(mouse.removePointer);
          await mouse.moveTo(tester.getCenter(first));
          await tester.pump();
          expect(
            _statesOf(tester.widget<InkResponse>(first)),
            contains(WidgetState.hovered),
          );
        });
      }

      // Reduce Motion critically damps Expressive's springs (contract §2) rather than cutting them, so a press
      // still moves for a moment; what the law forbids is motion that never ends.
      testWidgets('under Reduce Motion a press settles and nothing loops', (
        tester,
      ) async {
        await _size(tester, 390);
        await tester.pumpWidget(_host(part.build(() {}), still: true));
        await tester.pump();
        if (part.pressable) {
          await tester.tap(_live(), warnIfMissed: false);
        }
        await tester.pumpAndSettle();
        expect(tester.hasRunningAnimations, isFalse);
        expect(tester.takeException(), isNull);
      });

      for (final width in const [390.0, 768.0, 1024.0, 1440.0]) {
        testWidgets('lays out at $width, at 2.0 text, and right to left', (
          tester,
        ) async {
          await _size(tester, width, 1400);
          expect(
            await _faults(() async {
              await tester.pumpWidget(_host(part.build(() {}), still: true));
              await tester.pump();
            }),
            isEmpty,
          );
          expect(
            await _faults(() async {
              await tester.pumpWidget(
                _host(part.build(() {}), still: true, scale: 2),
              );
              await tester.pump();
            }),
            isEmpty,
            reason: 'at 2.0 text',
          );
          if (part.crushes == null) {
            expect(_crushed(tester), isEmpty, reason: 'at 2.0 text');
          }
          expect(
            await _faults(() async {
              await tester.pumpWidget(
                _host(
                  part.build(() {}),
                  still: true,
                  direction: TextDirection.rtl,
                ),
              );
              await tester.pump();
            }),
            isEmpty,
            reason: 'right to left',
          );
        });
      }
    });
  }

  group('the continuous indicators hold still under Reduce Motion', () {
    final loops = <String, Widget>{
      'loading indicator': const ExpressiveLoadingIndicator(),
      'linear indeterminate': const ExpressiveLinearProgressIndicator(),
      'circular indeterminate': const ExpressiveCircularProgressIndicator(),
      'skeleton': const ExpressiveSkeleton.circle(size: 48),
    };
    for (final MapEntry(key: name, value: widget) in loops.entries) {
      testWidgets(name, (tester) async {
        await _size(tester, 390);
        await tester.pumpWidget(_host(widget, still: true));
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.hasRunningAnimations, isFalse, reason: 'it loops');
        await tester.pumpWidget(_host(widget));
        await tester.pump(const Duration(milliseconds: 100));
        expect(
          tester.hasRunningAnimations,
          isTrue,
          reason: 'with motion on it moves',
        );
        await tester.pumpWidget(const SizedBox());
      });
    }
  });
}
