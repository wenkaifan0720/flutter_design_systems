// Every example in the package's docs, compiled here (an example that stops
// compiling fails analysis) and run (testDocExamples, ui_core's template in
// doc_examples.dart). An example added to lib fails the first test until it
// is written out here; the names the examples assume are in
// doc_example_stubs.dart, or made first in their entry. A call that shows a
// route waits a frame; loading a font and an app's main are compiled, not
// run.
// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, prefer_const_declarations, unnecessary_lambdas, avoid_redundant_argument_values, unused_local_variable, unused_element, unnecessary_import, unawaited_futures, discarded_futures, inference_failure_on_instance_creation, inference_failure_on_untyped_parameter, inference_failure_on_function_invocation
// The parts library's example is this file's own imports:
// lib/ui/my_card.dart, copied from package:frosted_ui/src/frosted/... and renamed.
import 'package:flutter/widgets.dart';
import 'package:frosted_ui/frosted_parts.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart' show FontLoader, LogicalKeyboardKey;
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_host.dart';
import 'package:frosted_ui/frosted_ui.dart';

import 'doc_example_stubs.dart';
import 'doc_examples.dart';

void main() {
  tearDown(disposeOwned);
  testDocExamples(
    self: 'test/doc_examples_test.dart',
    wrap: (child) => MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, child) =>
          FrostedHost(brightness: Brightness.light, child: child!),
      home: Material(child: child),
    ),
    size: const Size(480, 600),
    examples: {
      'FrostedButton': (context) => FrostedButton(
        'Save',
        onPressed: save,
        style: FrostedStyle(
          fill: WidgetStatePropertyAll(Color(0xFF1F6FEB)),
          shape: WidgetStatePropertyAll(StadiumBorder()),
        ),
      ),
      'FrostedThemeData.opal': (context) {
        final theme = FrostedThemeData.opal().copyWith(
          components: const FrostedComponentThemes(
            card: FrostedStyle(
              padding: WidgetStatePropertyAll(EdgeInsets.all(24)),
            ),
          ),
        );
        return null;
      },
      'FrostedAccount': (context) => FrostedAccount(
        name: 'Maren Holt',
        initials: 'MH',
        meta: 'Profile and settings',
        unread: 1,
        onProfile: (context) => Navigator.of(context).pushNamed('/profile'),
      ),
      'FrostedAccountScope': (context) =>
          FrostedAccountScope(account: account, child: child),
      'FrostedAccountMarks': (context) => FrostedAccountMarks(
        account: const FrostedAccount(name: 'Maya Chen', initials: 'MC'),
      ),
      'FrostedBell': (context) => FrostedBell(
        unread: 1,
        onPressed: () => Navigator.of(context).pushNamed('/notifications'),
      ),
      'FrostedActionBar': (context) => FrostedActionBar(
        summary: '\$500.00',
        detail: 'To Maren Holt · arrives Thursday',
        label: 'Transfer',
        onPressed: transfer,
      ),
      'FrostedButtonGroup': (context) => FrostedButtonGroup(
        items: [
          FrostedButtonGroupItem(
            label: 'Undo',
            icon: FrostedGlyphs.back,
            showLabel: false,
            onPressed: undo,
          ),
          FrostedButtonGroupItem(
            label: 'Redo',
            icon: FrostedGlyphs.forward,
            showLabel: false,
            onPressed: redo,
          ),
        ],
      ),
      'FrostedKbd': (context) => FrostedKbd('Esc'),
      'FrostedKbd.combo': (context) =>
          FrostedKbd.combo(['⌘', 'K'], semanticsLabel: 'Command K'),
      'FrostedAvatar': (context) => FrostedAvatar(
        'MH',
        name: 'Profile and settings',
        onPressed: () => Navigator.of(context).pushNamed('/profile'),
      ),
      'FrostedAvatar 2': (context) => FrostedAvatar(
        'MS',
        style: const FrostedStyle(
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
          ),
        ),
      ),
      'FrostedProfileHero': (context) => FrostedProfileHero(
        initials: 'MH',
        name: 'Maren Holt',
        meta: 'Member since October 2023',
        contact: const ['maren.holt@example.com', '+1 (415) 555-0142'],
        counts: const [
          FrostedProfileCount(5, 'Accounts'),
          FrostedProfileCount(2, 'Cards'),
          FrostedProfileCount(3, 'Goals'),
        ],
      ),
      'FrostedAvatarGroup': (context) => FrostedAvatarGroup(const [
        'Maren Holt',
        'Jonas Reyes',
        'Ines Park',
      ], total: 7),
      'FrostedButton 2': (context) =>
          FrostedButton('Review transfer', expand: true, onPressed: review),
      'FrostedButton.glass': (context) => FrostedButton.glass(
        'Clear filters',
        icon: FrostedGlyphs.close,
        onPressed: clear,
      ),
      'FrostedButton.glass 2': (context) => FrostedButton.glass(
        'See all',
        size: FrostedButtonSize.small,
        onPressed: seeAll,
      ),
      'FrostedButton.glass 3': (context) => FrostedButton.glass(
        'Save',
        onPressed: save,
        style: FrostedStyle(
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ),
      'FrostedButtonRow': (context) => FrostedButtonRow(
        children: [
          FrostedButton.glass('Cancel', onPressed: cancel),
          FrostedButton(
            'Freeze',
            icon: FrostedGlyphs.snowflake,
            onPressed: freeze,
          ),
        ],
      ),
      'FrostedButtonRow 2': (context) => FrostedButtonRow(
        columns: 2,
        children: [FrostedButton.glass('Report a problem', onPressed: report)],
      ),
      'FrostedLink': (context) => FrostedLink(
        'at Blue Fern Café in October, \$6.48 a visit',
        link: 'Blue Fern Café',
        onPressed: openCategory,
      ),
      'FrostedLink 2': (context) => FrostedLink(
        'Change these any time in Profile.',
        link: 'Profile',
        onPressed: openProfile,
      ),
      'FrostedCalendar': (context) => FrostedCalendar(
        firstDate: DateTime(2026),
        lastDate: DateTime(2027, 12, 31),
        value: due,
        onChanged: (d) => setState(() => due = d),
      ),
      'FrostedDateRangePicker': (context) => FrostedDateRangePicker(
        firstDate: DateTime(2026),
        lastDate: DateTime(2027, 12, 31),
        value: trip,
        onChanged: (r) => setState(() => trip = r),
      ),
      'FrostedCreditCard': (context) => FrostedCreditCard(
        balance: 1326.44,
        limit: 4000,
        mask: '4821',
        brand: 'Harbor',
        note: 'Autopay · due Nov 12',
        onPressed: openCards,
      ),
      'FrostedOrbits': (context) => FrostedOrbits(),
      'FrostedCardGlow': (context) => FrostedCardGlow(),
      'FrostedFrost': (context) => FrostedFrost(radius: 16),
      'FrostedDebitCard': (context) => FrostedDebitCard(mask: '3907'),
      'FrostedCardNumber': (context) => FrostedCardNumber(
        number: '4242424242427730',
        expires: '09/29',
        cvc: '317',
        name: 'Maren Holt',
      ),
      'FrostedGoalCard': (context) => FrostedGoalCard(
        name: 'Lisbon in May',
        subtitle: 'by May 2027',
        icon: FrostedGlyphs.plane,
        hue: t.hues.sunset,
        saved: 2840,
        target: 4000,
        status: FrostedGoalStatus.behind,
        onPressed: open,
      ),
      'FrostedGoalRow': (context) => FrostedGoalRow(
        name: 'Lisbon in May',
        icon: FrostedGlyphs.plane,
        hue: t.hues.sunset,
        saved: 2840,
        target: 4000,
        by: 'May 2027',
        status: FrostedGoalStatus.behind,
        first: true,
        onPressed: open,
      ),
      'FrostedNewGoal': (context) => FrostedNewGoal(onPressed: startGoal),
      'FrostedPane': (context) => FrostedPane(
        name: 'Groceries',
        hue: t.hues.orchid,
        spent: 412.36,
        budget: 450,
        variant: FrostedPaneVariant.featured,
        meta: '8% less than Sep',
        onPressed: open,
      ),
      'FrostedMosaic': (context) => FrostedMosaic(
        title: 'October',
        panes: [
          FrostedPane.rent(
            name: 'Rent & home',
            hue: t.hues.periwinkle,
            spent: 1150,
            budget: 1150,
            ticket: Text('Linden Court'),
            paid: 'Paid Oct 1',
            nextDue: 'Due Nov 1',
          ),
          FrostedPane(
            name: 'Groceries',
            hue: t.hues.orchid,
            spent: 412.36,
            budget: 450,
          ),
        ],
      ),
      'FrostedAxisMark': (context) =>
          FrostedAxisMark(27, 'Today', current: true),
      'FrostedBarSeries': (context) =>
          FrostedBarSeries(theme.hues.azure, emergencyByMonth),
      'FrostedDayBars': (context) => FrostedDayBars(
        values: diningByDay,
        daysInMonth: 31,
        hue: theme.hues.coral,
        marks: octoberAxis,
        label: 'Dining out, each day in October',
      ),
      'FrostedDayBars.months': (context) => FrostedDayBars.months(
        values: interestByMonth,
        months: shortMonths,
        hue: theme.hues.seafoam,
        label: 'Interest earned each month',
      ),
      'FrostedDayBars.stacked': (context) => FrostedDayBars.stacked(
        series: [
          FrostedBarSeries(theme.hues.azure, emergencyByMonth),
          FrostedBarSeries(theme.hues.sunset, lisbonByMonth),
        ],
        months: shortMonths,
        lines: 4,
        label: 'Put away each month',
      ),
      'FrostedFanEnd': (context) => FrostedFanEnd(
        amount: 400,
        hue: theme.hues.azure,
        title: 'Emergency fund',
        subtitle: 'Auto-save · Sun, Nov 1',
        onPressed: openGoal,
      ),
      'FrostedFan': (context) => FrostedFan(
        flows: scheduled,
        source: theme.hues.cyan,
        label: 'What leaves Everyday on its own in November',
      ),
      'FrostedLineChart': (context) => FrostedLineChart(
        label: 'Visitors',
        labels: const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
        series: const [
          FrostedChartSeries('This week', [120, 180, 150, 210, 240]),
        ],
      ),
      'FrostedAreaChart': (context) => FrostedAreaChart(
        label: 'Storage used',
        labels: months,
        series: const [
          FrostedChartSeries('Photos', [2, 3, 3.5, 5, 6.2]),
        ],
        format: (v) => '${v.toStringAsFixed(1)} GB',
      ),
      'FrostedBarChart': (context) => FrostedBarChart(
        label: 'Steps',
        labels: const ['M', 'T', 'W', 'T', 'F'],
        current: 4,
        series: const [
          FrostedChartSeries('Steps', [6200, 8400, 7100, 9900, 4300]),
        ],
      ),
      'FrostedPieChart': (context) => FrostedPieChart(
        label: 'Time spent',
        center: Text('38 h'),
        slices: const [
          FrostedPieSlice('Focus', 18),
          FrostedPieSlice('Meetings', 12),
          FrostedPieSlice('Email', 8),
        ],
      ),
      'FrostedSparkline': (context) => FrostedSparkline(const [
        3,
        5,
        4,
        7,
        6,
        9,
      ], label: 'Sign-ups this week'),
      'FrostedStep': (context) => FrostedStep(12, 1326.44, 'Credit card'),
      'FrostedStepsChart': (context) => FrostedStepsChart(
        steps: const [
          FrostedStep(1, 1150, 'Rent'),
          FrostedStep(12, 1326.44, 'Credit card'),
        ],
        daysInMonth: 30,
        marks: novemberAxis,
        label: 'November bills, added up through the month',
      ),
      'FrostedChartNote': (context) => FrostedChartNote(9, 'Paycheck'),
      'FrostedTrailChart': (context) => FrostedTrailChart(
        values: netWorthByMonth,
        months: const [
          'Nov',
          'Dec',
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
        ],
        label: 'Net worth over the last 12 months',
      ),
      'FrostedTrailChart.days': (context) => FrostedTrailChart.days(
        values: valueByDay,
        daysInMonth: 31,
        marks: octoberAxis,
        label: 'Investing value through October',
      ),
      'FrostedTrailChart.steps': (context) => FrostedTrailChart.steps(
        values: closingByDay,
        start: 2479.82,
        daysInMonth: 31,
        notes: const [FrostedChartNote(9, 'Paycheck')],
        marks: octoberAxis,
        label: 'Everyday balance through October',
      ),
      'FrostedSpendChart': (context) => FrostedSpendChart(
        spent: spentByDay,
        budget: 2700,
        daysInMonth: 31,
        firstNote: 'Rent',
        marks: octoberAxis,
        label: 'October spending against the budget pace',
      ),
      'FrostedGoalChart': (context) => FrostedGoalChart(
        saved: savedByMonth,
        projection: ahead,
        target: 4000,
        endDate: DateTime(2027, 5),
        hue: theme.hues.sunset,
        marks: goalAxis,
        label: 'Lisbon in May: saved, and where it is headed',
      ),
      'FrostedKey': (context) =>
          FrostedKey(FrostedKeySwatch.pace, 'Budget pace'),
      'FrostedChartKey': (context) => FrostedChartKey(
        keys: const [
          FrostedKey(FrostedKeySwatch.line, 'Spent', figure: '\$2,486.12'),
          FrostedKey(FrostedKeySwatch.pace, 'Budget pace'),
        ],
      ),
      'FrostedRadioGroup': (context) => FrostedRadioGroup<String>(
        label: 'Plan',
        value: plan,
        onChanged: setPlan,
        options: const [
          FrostedRadio('free', 'Free'),
          FrostedRadio('pro', 'Pro', note: 'Billed yearly'),
        ],
      ),
      'FrostedRadio': (context) => FrostedRadioGroup<String>(
        label: 'Pay with',
        value: 'card',
        options: [
          FrostedRadio(
            'card',
            'Card',
            style: const FrostedStyle(
              edge: WidgetStatePropertyAll(Color(0xFF5B5BD6)),
            ),
          ),
        ],
      ),
      'FrostedRadioGroup 2': (context) => FrostedRadioGroup<String>(
        label: 'Delivery',
        value: speed,
        onChanged: (v) => setState(() => speed = v),
        options: const [
          FrostedRadio('standard', 'Standard', note: '3 to 5 days'),
          FrostedRadio('express', 'Express', note: 'Tomorrow'),
        ],
      ),
      'FrostedChip': (context) => FrostedChip(
        'Vegetarian',
        selected: veg,
        onPressed: () => setState(() => veg = !veg),
      ),
      'FrostedChip 2': (context) => FrostedChip(
        'ines@park.studio',
        icon: FrostedGlyphs.email,
        onDeleted: () => remove(email),
      ),
      'FrostedChip 3': (context) => FrostedChip(
        'Vegetarian',
        selected: veg,
        onPressed: toggle,
        style: const FrostedStyle(
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
          ),
        ),
      ),
      'FrostedRating': (context) => FrostedRating(
        value: stars,
        label: 'Your rating',
        onChanged: (v) => setState(() => stars = v),
      ),
      'FrostedRating 2': (context) => FrostedRating(
        value: 4.5,
        label: 'Average',
        allowHalf: true,
        size: 16,
      ),
      'FrostedFileUpload': (context) => FrostedFileUpload(
        label: 'Attachments',
        hint: 'PDF or images, up to 10 MB',
        onPressed: pick,
        files: files,
        onRemoved: (f) => setState(() => files.remove(f)),
      ),
      'FrostedCheckRow': (context) => FrostedCheckRow(
        label: 'Email me a receipt',
        note: 'Sent to the address on file',
        value: receipt,
        onChanged: (v) => setState(() => receipt = v ?? false),
      ),
      'FrostedChoices': (context) => FrostedChoices<String>(
        label: 'Size',
        options: const [
          FrostedSelectOption('s', 'Small'),
          FrostedSelectOption('m', 'Medium'),
          FrostedSelectOption('l', 'Large'),
        ],
        value: size,
        onChanged: (v) => setState(() => size = v),
      ),
      'FrostedColorPicker': (context) => FrostedColorPicker(
        value: tint,
        onChanged: (c) => setState(() => tint = c),
      ),
      'FrostedCombobox': (context) => FrostedCombobox<String>(
        label: 'Country',
        options: countries,
        value: country,
        onSelected: (v) => setState(() => country = v),
      ),
      'FrostedMultiSelect': (context) => FrostedMultiSelect<String>(
        label: 'Tags',
        options: tags,
        values: chosen,
        onChanged: (v) => setState(() => chosen = v),
      ),
      'FrostedMenuBar': (context) => FrostedMenuBar(
        menus: [
          DesignMenuEntry(
            label: 'File',
            children: [
              DesignMenuEntry(label: 'New', shortcut: '⌘N', onPressed: create),
              DesignMenuEntry.divider(),
              DesignMenuEntry(label: 'Close', onPressed: close),
            ],
          ),
        ],
      ),
      'FrostedContextMenu': (context) => FrostedContextMenu(
        items: [
          DesignMenuEntry(label: 'Copy', onPressed: copy),
          DesignMenuEntry.divider(),
          DesignMenuEntry(label: 'Delete', onPressed: delete),
        ],
        child: card,
      ),
      'frostedShortcutLabel': (context) => DesignMenuEntry(
        label: 'Redo',
        shortcut: frostedShortcutLabel(
          context,
          const SingleActivator(
            LogicalKeyboardKey.keyZ,
            meta: true,
            shift: true,
          ),
        ),
        onPressed: redo,
      ),
      'FrostedCommand.show': (context) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          FrostedCommand.show(
            context,
            commands: [
              DesignCommand(
                label: 'New payment',
                group: 'Money',
                shortcut: '⌘P',
                onPressed: pay,
              ),
              DesignCommand(label: 'Settings', onPressed: openSettings),
            ],
          );
        });
        return null;
      },
      'FrostedComposer': (context) => FrostedComposer(
        hint: 'Message Maren',
        onSend: send,
        onAttach: attach,
      ),
      'FrostedFilterChipGroup': (context) => FrostedFilterChipGroup(
        options: const [
          FrostedFilterOption('all', 'All'),
          FrostedFilterOption('in', 'Money in'),
          FrostedFilterOption('out', 'Money out'),
        ],
        value: scope,
        onChanged: (v) => setState(() => scope = v),
      ),
      'FrostedSegmentedButton': (context) => FrostedSegmentedButton(
        segments: const [
          FrostedButtonSegment('1m', '1M'),
          FrostedButtonSegment('3m', '3M'),
          FrostedButtonSegment('1y', '1Y'),
          FrostedButtonSegment('all', 'All'),
        ],
        value: range,
        onChanged: (v) => setState(() => range = v),
        label: 'Range',
      ),
      'FrostedSegmentedButton 2': (context) => FrostedSegmentedButton(
        segments: segments,
        value: range,
        onChanged: setRange,
        label: 'Range',
        style: const FrostedStyle(
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
          ),
        ),
      ),
      'FrostedSwitch': (context) => FrostedSwitch(
        value: faceId,
        onChanged: (v) => setState(() => faceId = v),
        label: 'Face ID',
      ),
      'FrostedSwitch 2': (context) => FrostedSwitch(
        value: on,
        onChanged: setOn,
        label: 'Face ID',
        style: FrostedStyle(
          fill: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? const Color(0xFF2F7D5B)
                : null,
          ),
        ),
      ),
      'FrostedMonthSwitch': (context) {
        const months = [
          FrostedMenuItem(9, 'September'),
          FrostedMenuItem(10, 'October'),
        ];
        return FrostedMonthSwitch(
          month: 'October 2026',
          previous: 'September',
          onEarlier: back,
          onLater: null,
          onOpen: (anchor) => FrostedMenu.show<int>(
            anchor,
            items: months,
            title: 'Spent each month',
            anchor: anchor,
          ),
        );
      },
      'FrostedQuickActions': (context) => FrostedQuickActions([
        FrostedQuickAction(
          FrostedGlyphs.arrowLeftRight,
          'Transfer',
          onPressed: transfer,
        ),
        FrostedQuickAction(
          FrostedGlyphs.receipt,
          'Pay a bill',
          onPressed: bills,
        ),
        FrostedQuickAction(
          FrostedGlyphs.piggyBank,
          'Add to goal',
          onPressed: goal,
        ),
        FrostedQuickAction(FrostedGlyphs.split, 'Split', onPressed: split),
      ]),
      'FrostedActionTiles': (context) => FrostedActionTiles([
        FrostedActionTile(
          FrostedGlyphs.arrowLeftRight,
          'Transfer',
          note: 'Your accounts',
          onPressed: transfer,
        ),
        FrostedActionTile(
          FrostedGlyphs.receipt,
          'Pay a bill',
          note: '6 in November',
          tail: r'$2,541.40',
          onPressed: bills,
        ),
      ], label: 'Ways to move money'),
      'FrostedQuickAmounts': (context) {
        num? amount = 580;
        return FrostedQuickAmounts(
          options: const [
            FrostedQuickAmount(100, 'A month'),
            FrostedQuickAmount(200, 'Two months'),
            FrostedQuickAmount(1160, 'The rest'),
          ],
          value: amount,
          onChanged: (v) => setState(() => amount = v),
        );
      },
      'FrostedIconPicker': (context) => FrostedIconPicker(
        icons: const [
          FrostedIconChoice(FrostedGlyphs.plane, 'Plane'),
          FrostedIconChoice(FrostedGlyphs.bike, 'Bike'),
          FrostedIconChoice(FrostedGlyphs.house, 'Home'),
        ],
        value: icon,
        onChanged: (v) => setState(() => icon = v),
      ),
      'FrostedDataTable': (context) =>
          FrostedDataTable<({String payee, int cents})>(
            controller: DesignTableController(
              rows: payments,
              pageSize: 10,
              columns: [
                DesignTableColumn(
                  id: 'who',
                  label: 'Payee',
                  sortKey: (p) => p.payee,
                ),
                DesignTableColumn(
                  id: 'sum',
                  label: 'Amount',
                  numeric: true,
                  sortKey: (p) => p.cents,
                ),
              ],
            ),
            cellBuilder: (context, p, column) =>
                Text(column.id == 'who' ? p.payee : money(p.cents)),
          ),
      'FrostedTreeView': (context) => FrostedTreeView<String>(
        controller: DesignTreeController(
          roots: const ['Bills', 'Trips'],
          childrenOf: (f) => folders[f] ?? const <String>[],
        ),
        labelOf: (f) => f,
        onActivate: open,
      ),
      'FrostedDialog': (context) => FrostedDialog(
        title: 'Freeze this card?',
        message: 'Payments stop until you unfreeze it.',
        confirmLabel: 'Freeze',
        cancelLabel: 'Cancel',
        onConfirm: freeze,
        onCancel: close,
      ),
      'FrostedDialog 2': (context) => FrostedDialog(
        title: 'Leave the group?',
        style: const FrostedStyle(
          padding: WidgetStatePropertyAll(EdgeInsets.all(32)),
        ),
      ),
      'FrostedPasswordField': (context) => FrostedPasswordField(
        label: 'Password',
        value: password,
        onChanged: (v) => setState(() => password = v),
      ),
      'FrostedInputGroup': (context) => FrostedInputGroup(
        label: 'Website',
        prefix: Text('https://'),
        suffix: Text('.com'),
        value: site,
        onChanged: (v) => setState(() => site = v),
      ),
      'FrostedInputOtp': (context) =>
          FrostedInputOtp(label: 'Code from your text', onCompleted: verify),
      'FrostedFormField': (context) => FrostedFormField(
        label: 'Notify me',
        helper: 'Pick at least one',
        mergeSemantics: false,
        child: Row(children: [chipA, chipB]),
      ),
      'FrostedTextField': (context) => FrostedTextField(
        label: 'Name',
        hint: 'What are you saving for?',
        value: name,
        onChanged: (v) => setState(() => name = v),
      ),
      'FrostedTextField 2': (context) => FrostedTextField(
        label: 'Name',
        value: name,
        onChanged: setName,
        style: FrostedStyle(
          edge: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.focused)
                ? const Color(0xFF5B5BD6)
                : null,
          ),
        ),
      ),
      'FrostedTextArea': (context) => FrostedTextArea(
        label: 'Notes',
        hint: 'Anything the team should know',
        value: notes,
        onChanged: (v) => setState(() => notes = v),
      ),
      'FrostedAmountField': (context) => FrostedAmountField(
        label: 'Amount',
        value: amount,
        onChanged: (v) => setState(() => amount = v),
      ),
      'FrostedSearchField': (context) => FrostedSearchField(
        hint: 'Search activity',
        value: query,
        onChanged: (v) => setState(() => query = v),
      ),
      'FrostedSearchLink': (context) => FrostedSearchLink(
        hint: 'Search activity',
        onPressed: () => Navigator.of(context).pushNamed('/activity/search'),
      ),
      'FrostedPickerRow': (context) => FrostedPickerRow(
        label: 'From',
        title: 'Everyday',
        subtitle: 'Checking ·· 4821',
        leading: FrostedIconMark(FrostedGlyphs.wallet, hue: t.hues.cyan),
        trailing: const FrostedAmount(6248.30, signed: false),
        onPressed: pickFrom,
      ),
      'FrostedSwapButton': (context) => FrostedSwapButton(),
      'FrostedNumberField': (context) => FrostedNumberField(
        value: budget,
        onChanged: (v) => setState(() => budget = v),
        label: 'the budget',
        step: 10,
        note: 'a month',
      ),
      'FrostedSelect': (context) => FrostedSelect<String>(
        label: 'Room',
        options: const [
          FrostedSelectOption('k', 'Kitchen'),
          FrostedSelectOption('s', 'Study'),
        ],
        value: room,
        onChanged: (v) => setState(() => room = v),
      ),
      'FrostedSwitchRow': (context) => FrostedSwitchRow(
        label: 'Face ID',
        note: 'To open the app and approve payments',
        value: faceId,
        onChanged: (v) => setState(() => faceId = v),
      ),
      'FrostedValueRow': (context) => FrostedValueRow(
        title: 'Monthly spending limit',
        subtitle: r'$1,259.82 spent in October',
        value: r'$2,000',
        onPressed: openLimit,
      ),
      'FrostedSettingsGroup': (context) => FrostedSettingsGroup(
        title: 'Security',
        children: [
          FrostedSwitchRow(
            label: 'Face ID',
            note: 'To open the app and approve payments',
            value: faceId,
            onChanged: setFaceId,
          ),
          FrostedValueRow(title: 'Change passcode', onPressed: openPasscode),
        ],
      ),
      'FrostedFormRow': (context) => FrostedFormRow(
        label: 'Currency',
        value: 'USD',
        onPressed: pickCurrency,
      ),
      'FrostedFieldPair': (context) => FrostedFieldPair(
        FrostedAmountField(
          label: 'Target',
          size: FrostedAmountFieldSize.small,
          value: target,
          onChanged: setTarget,
        ),
        FrostedTextField(
          label: 'Date',
          hint: 'Month and year',
          value: date,
          onChanged: setDate,
        ),
      ),
      'FrostedFormSection': (context) {
        const name = Text('Name');
        const target = Text('Target');
        const date = Text('Date');
        return FrostedFormSection(
          title: 'New goal',
          children: [name, FrostedFieldPair(target, date), icons],
        );
      },
      'FrostedSurface': (context) => FrostedSurface(
        material: FrostedMaterial.sheer,
        borderRadius: BorderRadius.circular(20),
        padding: const EdgeInsets.all(16),
        child: Text('Balance'),
      ),
      'Positioned.fill': (context) =>
          Stack(children: [Positioned.fill(child: FrostedBackdropView())]),
      'FrostedDivider': (context) => FrostedDivider(),
      'FrostedDivider 2': (context) => FrostedDivider(height: 24, indent: 16),
      'FrostedDivider.vertical': (context) =>
          FrostedDivider.vertical(width: 16),
      'FrostedBadge': (context) =>
          FrostedBadge(3, child: Icon(FrostedGlyphs.notifications)),
      'FrostedBadge.dot': (context) => FrostedBadge.dot(
        label: 'New',
        child: FrostedAvatar('IP', name: 'Ines Park'),
      ),
      'FrostedBadge 2': (context) => FrostedBadge(12),
      'FrostedBadge 3': (context) => FrostedBadge(
        3,
        style: const FrostedStyle(
          fill: WidgetStatePropertyAll(Color(0xFF5B5BD6)),
        ),
        child: inboxIcon,
      ),
      'FrostedDisclosure': (context) => FrostedDisclosure(
        title: 'What does the plan include?',
        child: Text(answer),
      ),
      'FrostedDisclosure 2': (context) {
        var open = false;
        return FrostedDisclosure(
          title: 'Advanced',
          meta: '3 settings',
          expanded: open,
          onExpansionChanged: (v) => setState(() => open = v),
          child: settings,
        );
      },
      'FrostedTimeline': (context) => FrostedTimeline(
        entries: const [
          FrostedTimelineEntry(title: 'Order placed', time: '9:02'),
          FrostedTimelineEntry(title: 'Packed', time: '11:40', current: true),
          FrostedTimelineEntry(title: 'Out for delivery'),
        ],
      ),
      'FrostedTable': (context) => FrostedTable(
        columns: const [
          FrostedTableColumn('Item'),
          FrostedTableColumn('Qty', numeric: true),
          FrostedTableColumn('Price', numeric: true),
        ],
        rows: const [
          ['Notebook', '2', '\$12.00'],
          ['Pens', '10', '\$8.50'],
        ],
      ),
      'MaterialApp.router': (context) {
        Widget app() => MaterialApp.router(
          routerConfig: router,
          builder: (context, child) => FrostedHost(child: child!),
        );
        return app;
      },
      'FrostedHost.navigatorOf': (context) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          FrostedHost.navigatorOf(context).push(route);
        });
        return null;
      },
      'FrostedMediaGround': (context) =>
          FrostedMediaGround(child: FrostedAppBar(title: 'Clips')),
      'FrostedIconButton': (context) => FrostedIconButton(
        FrostedGlyphs.chevronLeft,
        label: 'Back to Home',
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      'FrostedIconButton 2': (context) => FrostedIconButton(
        FrostedGlyphs.bell,
        label: 'Notifications',
        onPressed: open,
        style: const FrostedStyle(
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
        ),
      ),
      'FrostedBadgeDot': (context) => FrostedBadgeDot(),
      'FrostedMedia': (context) => FrostedMedia(
        image: NetworkImage(cover),
        seed: 'Lisbon in May',
        aspect: 16 / 9,
        label: 'Lisbon in May',
      ),
      'FrostedMedia 2': (context) => FrostedMedia(
        seed: 'Harbor Transit',
        aspect: 1,
        radius: FrostedCorners.r10,
      ),
      'FrostedLightField': (context) => FrostedLightField(),
      'FrostedMonogram': (context) => FrostedMonogram(
        'Blue Fern Café',
        hue: context.frostedTheme.hues.coral,
      ),
      'FrostedIconMark': (context) => FrostedIconMark(
        FrostedGlyphs.wallet,
        hue: context.frostedTheme.hues.cyan,
        label: 'Everyday',
      ),
      'FrostedDateBlock': (context) => FrostedDateBlock(DateTime(2026, 11, 1)),
      'FrostedDateBlock 2': (context) => FrostedDateBlock(
        DateTime(2026, 11, 1),
        soon: true,
        hue: context.frostedTheme.hues.periwinkle,
      ),
      'FrostedTransactionMark.purchase': (context) =>
          FrostedTransactionMark.purchase(
            'Blue Fern Café',
            hue: context.frostedTheme.hues.coral,
          ),
      'FrostedTransactionMark.move': (context) => FrostedTransactionMark.move(),
      'FrostedTag': (context) => FrostedTag(
        'On track',
        icon: FrostedGlyphs.check,
        tone: FrostedTone.success,
      ),
      'FrostedTag 2': (context) => FrostedTag(
        '·',
        lead: '\$1,259.82',
        figure: '0.53%',
        icon: FrostedGlyphs.arrowUpRight,
        tone: FrostedTone.success,
      ),
      'FrostedTag 3': (context) =>
          FrostedTag('Credit', variant: FrostedTagVariant.glass),
      'FrostedSwatch': (context) =>
          FrostedSwatch(context.frostedTheme.hues.orchid),
      'FrostedPerson': (context) => FrostedPerson(
        'Jonah Reyes',
        selected: picked == 'jonah',
        onChanged: (_) => pick('jonah'),
      ),
      'FrostedPeople': (context) => FrostedPeople(
        children: [FrostedPerson('Jonah Reyes'), FrostedPerson('Ines Park')],
      ),
      'FrostedCheckbox': (context) => FrostedCheckbox(
        value: kept,
        label: 'Walk 5,000 steps',
        onChanged: (v) => setState(() => kept = v!),
      ),
      'FrostedCheckbox 2': (context) => FrostedCheckbox(
        value: kept,
        label: 'Walk 5,000 steps',
        onChanged: keep,
        style: const FrostedStyle(
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(6)),
            ),
          ),
        ),
      ),
      'FrostedOption': (context) => FrostedOption(
        label: 'Dining out',
        hue: t.hue(2).a,
        selected: true,
        onPressed: () => Navigator.of(context).pop('dining'),
      ),
      'FrostedOption 2': (context) => FrostedOption(
        label: 'Weekly',
        selected: true,
        onPressed: pick,
        style: const FrostedStyle(
          fill: WidgetStatePropertyAll(Color(0xFF2F7D5B)),
        ),
      ),
      'FrostedHueDot': (context) => FrostedHueDot(t.hue(0).a),
      'Builder': (context) async {
        const months = [
          FrostedMenuItem('sep', 'September'),
          FrostedMenuItem('oct', 'October'),
        ];
        return Builder(
          builder: (anchor) => FrostedButton.glass(
            'October 2026',
            onPressed: () async {
              final month = await FrostedMenu.show<String>(
                anchor,
                title: 'Spent each month',
                items: months,
              );
            },
          ),
        );
      },
      'FrostedBand': (context) =>
          FrostedBand(412.36, hue: t.hues.orchid, name: 'Groceries'),
      'FrostedSegmentLabel': (context) => FrostedSegmentLabel('You', '\$14.00'),
      'FrostedPaceTick': (context) => FrostedPaceTick(height: 20),
      'FrostedScale': (context) => FrostedScale(
        start: Text('\$0'),
        paceAt: 212,
        paceLabel: 'Budget \$250',
      ),
      'FrostedTrack': (context) => FrostedTrack(
        bands: [
          FrostedBand(20860, hue: t.hues.azure, name: 'Emergency fund'),
          FrostedBand(5460, variant: FrostedBandVariant.left, name: 'to go'),
        ],
      ),
      'FrostedLegendEntry': (context) => FrostedLegendEntry(
        'Emergency fund',
        hue: t.hues.azure,
        amount: 20860,
      ),
      'FrostedLegend': (context) => FrostedLegend(
        variant: FrostedLegendVariant.threeColumns,
        children: [
          FrostedLegendEntry(
            'Emergency fund',
            hue: t.hues.azure,
            amount: 20860,
          ),
        ],
      ),
      'FrostedBar': (context) => FrostedBar(0.71, hue: t.hues.sunset),
      'FrostedMeter': (context) => FrostedMeter(0.92, hue: t.hues.orchid),
      'FrostedBudgetBar': (context) =>
          FrostedBudgetBar(spent: 286.40, budget: 250, hue: t.hues.coral),
      'FrostedCompareRow': (context) => FrostedCompareRow(
        name: 'September',
        amount: 263.10,
        fraction: 0.92,
        hue: t.hues.coral,
        tick: 0.87,
      ),
      'FrostedCompareBars': (context) => FrostedCompareBars(
        children: [
          FrostedCompareRow(
            name: 'September',
            amount: 263.10,
            fraction: 263.10 / 286.40,
            hue: hue,
          ),
          FrostedCompareRow(
            name: 'October so far',
            amount: 241.80,
            fraction: 241.80 / 286.40,
            hue: hue,
          ),
        ],
      ),
      'FrostedMerchant': (context) => FrostedMerchant(
        name: 'Blue Fern Café',
        subtitle: '13 visits',
        amount: 84.25,
        fraction: 1,
        hue: t.hues.coral,
        onPressed: open,
      ),
      'FrostedMerchantBars': (context) => FrostedMerchantBars(
        children: [
          FrostedMerchant(
            name: 'Blue Fern Café',
            subtitle: '13 visits',
            amount: 84.25,
            fraction: 1,
            hue: hue,
          ),
          FrostedMerchant(
            name: 'Northside Market',
            subtitle: '6 visits',
            amount: 52.40,
            fraction: .62,
            hue: hue,
          ),
        ],
      ),
      'FrostedInOut': (context) => FrostedInOut(
        moneyIn: 6825,
        spent: 2486.12,
        bands: [
          FrostedBand(1150, hue: t.hues.periwinkle, name: 'Rent'),
          FrostedBand(412.36, hue: t.hues.orchid, name: 'Groceries'),
        ],
      ),
      'FrostedShare': (context) => FrostedShare('Jonah', 14),
      'FrostedSplitBar': (context) => FrostedSplitBar(
        hue: t.hues.lemon,
        shares: [FrostedShare('You', 14), FrostedShare('Jonah', 14)],
      ),
      'FrostedStatementTimeline': (context) => FrostedStatementTimeline(
        paid: DateTime(2026, 10, 12),
        closed: DateTime(2026, 10, 28),
        due: DateTime(2026, 11, 12),
        paidAmount: 1180.22,
        closedAmount: 1326.44,
      ),
      'FrostedVisitStrip': (context) => FrostedVisitStrip(
        month: DateTime(2026, 9),
        visits: [DateTime(2026, 9, 29)],
        current: DateTime(2026, 9, 29),
        hue: t.hues.coral,
      ),
      'FrostedDueLine': (context) => FrostedDueLine(
        hue: t.hues.periwinkle,
        start: 'Paid Oct 1',
        end: 'Next due Nov 1',
      ),
      'FrostedBalanceChange': (context) => FrostedBalanceChange(
        name: 'Everyday',
        icon: FrostedGlyphs.wallet,
        hue: t.hues.cyan,
        before: 6248.30,
        after: 5748.30,
      ),
      'FrostedBalanceChanges': (context) => FrostedBalanceChanges(
        children: [
          FrostedBalanceChange(
            name: 'Everyday',
            icon: FrostedGlyphs.wallet,
            hue: t.hues.cyan,
            before: 6248.30,
            after: 5748.30,
          ),
          FrostedBalanceChange(
            name: 'Savings',
            icon: FrostedGlyphs.wallet,
            hue: t.hues.mint,
            before: 12400,
            after: 12900,
          ),
        ],
      ),
      'FrostedRoute': (context) => FrostedRoute(
        fromName: 'Everyday',
        fromIcon: FrostedGlyphs.wallet,
        fromHue: t.hues.cyan,
        toName: 'Savings',
        toIcon: FrostedGlyphs.landmark,
        toHue: t.hues.seafoam,
      ),
      'FrostedDoneMark': (context) => FrostedDoneMark(),
      'FrostedMoney': (context) => FrostedMoney(48210.66),
      'FrostedMoney 2': (context) =>
          FrostedMoney(286.40, size: FrostedMoneySize.regular),
      'FrostedAmount': (context) => FrostedAmount(-10.99),
      'FrostedAmount 2': (context) => FrostedAmount(6248.30, signed: false),
      'FrostedNumberText': (context) => FrostedNumberText('4,000'),
      'FrostedPercent': (context) => FrostedPercent(115),
      'FrostedPercent 2': (context) =>
          FrostedPercent(71, size: FrostedPercentSize.small),
      'FrostedFigure': (context) => FrostedFigure(3214.09, caption: 'Spent'),
      'FrostedFigure 2': (context) =>
          FrostedFigure(6825, caption: 'In', flow: FrostedMoneyFlow.inflow),
      'FrostedStats': (context) => FrostedStats(
        children: [
          FrostedFigure(3214.09, caption: 'Spent'),
          FrostedFigure(285.91, caption: 'Left'),
        ],
      ),
      'FrostedCounter': (context) {
        final balance = 6248.30;
        return FrostedCounter(balance, size: FrostedMoneySize.regular);
      },
      'FrostedNavigationRail': (context) => FrostedNavigationRail(
        items: tabs,
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
      ),
      'FrostedBreadcrumb': (context) => FrostedBreadcrumb(
        items: [
          FrostedBreadcrumbItem('Home', onPressed: home),
          FrostedBreadcrumbItem('Projects', onPressed: projects),
          FrostedBreadcrumbItem('Lighthouse'),
        ],
      ),
      'FrostedPagination': (context) => FrostedPagination(
        pageCount: 12,
        selectedIndex: page,
        onChanged: (p) => setState(() => page = p),
      ),
      'FrostedStepProgress': (context) =>
          FrostedStepProgress(count: 4, currentStep: 1, name: 'Your details'),
      'FrostedPageDots': (context) {
        final controller = own(PageController());
        return FrostedPageDots(
          count: 4,
          selectedIndex: page,
          label: 'Welcome',
          onChanged: (i) => controller.animateToPage(i, duration: d, curve: c),
        );
      },
      'FrostedNavItem': (context) => FrostedNavItem(
        FrostedGlyphs.chartPie,
        'Spending',
        ValueKey('open-spending'),
      ),
      'FrostedNavItem.action': (context) => FrostedNavItem.action(
        FrostedGlyphs.arrowRightLeft,
        'Move',
        actionLabel: 'Move money',
      ),
      'FrostedNavigationBar': (context) => FrostedNavigationBar(
        items: tabs,
        selectedIndex: 0,
        onDestinationSelected: select,
      ),
      'FrostedNavigationBar 2': (context) => FrostedNavigationBar(
        items: tabs,
        style: const FrostedStyle(
          fill: WidgetStatePropertyAll(Color(0xF2FFFFFF)),
        ),
      ),
      'FrostedNavAction': (context) => FrostedNavAction(
        icon: FrostedGlyphs.arrowRightLeft,
        label: 'Move',
        selected: true,
        onPressed: openMove,
      ),
      'FrostedTime': (context) => const FrostedTime(hour: 9, minute: 30),
      'FrostedWheelPicker': (context) => FrostedWheelPicker<int>(
        label: 'Guests',
        options: [for (var n = 1; n <= 12; n++) FrostedSelectOption(n, '$n')],
        value: guests,
        onChanged: (v) => setState(() => guests = v),
      ),
      'FrostedTimePicker': (context) => FrostedTimePicker(
        value: alarm,
        onChanged: (v) => setState(() => alarm = v),
      ),
      'showFrostedTimePicker': (context) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          final time = await showFrostedTimePicker(context, initialTime: alarm);
        });
        return null;
      },
      'FrostedDatePicker': (context) => FrostedDatePicker(
        value: due,
        first: DateTime(2026),
        last: DateTime(2027, 12, 31),
        onChanged: (d) => setState(() => due = d),
      ),
      'showFrostedDatePicker': (context) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          final day = await showFrostedDatePicker(
            context,
            initialDate: due,
            first: DateTime(2026),
            last: DateTime(2027, 12, 31),
          );
        });
        return null;
      },
      'FrostedPopover': (context) => FrostedPopover(
        label: 'Filter',
        builder: (context, controller, _) => FrostedButton.glass(
          'Filter',
          onPressed: () =>
              controller.isOpen ? controller.close() : controller.open(),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FrostedSwitchRow(
              label: 'Only unread',
              value: unread,
              onChanged: setUnread,
            ),
          ],
        ),
      ),
      'FrostedHoverCard': (context) => FrostedHoverCard(
        content: Text('Maya Chen · Design lead'),
        child: FrostedLink('@maya', link: '@maya', onPressed: openProfile),
      ),
      'FrostedPressable': (context) => FrostedPressable(
        onPressed: open,
        label: 'Everyday account',
        radius: 18,
        child: card,
      ),
      'FrostedFocusRing': (context) =>
          FrostedFocusRing(shown: focused, radius: 12, child: face),
      'FrostedPreview': (context) => FrostedPreview(
        presentation: FrostedPresentation.pushed,
        child: const AccountPage(),
      ),
      'FrostedLinearProgressIndicator': (context) =>
          FrostedLinearProgressIndicator(value: 0.6, label: 'Uploading'),
      'FrostedCircularProgressIndicator': (context) =>
          FrostedCircularProgressIndicator(value: 0.25, label: 'Syncing'),
      'FrostedSkeleton': (context) => TickerMode(
        enabled: false,
        child: FrostedSkeleton(width: 120, height: 16),
      ),
      'FrostedSkeleton.text': (context) =>
          TickerMode(enabled: false, child: FrostedSkeleton.text(lines: 3)),
      'FrostedSkeleton.circle': (context) =>
          TickerMode(enabled: false, child: FrostedSkeleton.circle(size: 40)),
      'showFrostedDialog': (context) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          final ok = await showFrostedDialog<bool>(
            context,
            builder: (context) => FrostedDialog(
              title: 'Delete this note?',
              confirmLabel: 'Delete',
              cancelLabel: 'Cancel',
              destructive: true,
              onConfirm: () => Navigator.pop(context, true),
              onCancel: () => Navigator.pop(context, false),
            ),
          );
        });
        return null;
      },
      'Builder 2': (context) => Builder(
        builder: (anchor) => FrostedIconButton(
          FrostedGlyphs.more,
          label: 'More',
          onPressed: () async {
            final v = await showFrostedMenu<String>(
              anchor,
              items: const [
                FrostedMenuItem('rename', 'Rename'),
                FrostedMenuItem('delete', 'Delete'),
              ],
            );
          },
        ),
      ),
      'showFrostedSnackBar': (context) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showFrostedSnackBar(
            context,
            'Saved to Drafts',
            actionLabel: 'Undo',
            onAction: undo,
          );
        });
        return null;
      },
      'showFrostedActionSheet': (context) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showFrostedActionSheet<void>(
            context,
            builder: (context) => FrostedActionSheet(
              title: 'This photo',
              actions: [
                FrostedActionSheetAction('Share', onPressed: share),
                FrostedActionSheetAction(
                  'Delete',
                  destructive: true,
                  onPressed: delete,
                ),
              ],
            ),
          );
        });
        return null;
      },
      'showFrostedActionSheet 2': (context) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          final pick = await showFrostedActionSheet<String>(
            context,
            builder: (context) => FrostedActionSheet<String>(
              actions: const [
                FrostedActionSheetAction('Camera', value: 'camera'),
                FrostedActionSheetAction('Library', value: 'library'),
              ],
            ),
          );
        });
        return null;
      },
      'FrostedTooltip': (context) => FrostedTooltip(
        message: 'Copy link',
        child: FrostedIconButton(
          FrostedGlyphs.share,
          label: 'Copy link',
          onPressed: copy,
        ),
      ),
      'FrostedTooltip 2': (context) => FrostedTooltip(
        message: 'Copy the link',
        style: const FrostedStyle(
          fill: WidgetStatePropertyAll(Color(0xFF26215C)),
        ),
        child: copyButton,
      ),
      'Navigator': (context) => Navigator(
        pages: [FrostedPage<void>(name: 'account', child: AccountPage())],
        onDidRemovePage: (page) {},
      ),
      'FrostedScaffold': (context) => FrostedScaffold(
        topBar: const FrostedAppBar(title: 'Spending', caption: 'October 2026'),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: tiles,
        ),
      ),
      'FrostedScrollArea': (context) {
        final scroll = own(ScrollController());
        return FrostedScrollArea(
          controller: scroll,
          child: ListView(controller: scroll, children: rows),
        );
      },
      'FrostedResizable': (context) => FrostedResizable(
        first: list,
        second: detail,
        initialFraction: .35,
        minFirst: 240,
      ),
      'FrostedCarouselView': (context) => FrostedCarouselView(
        height: 200,
        children: [for (final p in photos) Image.asset(p)],
      ),
      'FrostedReorderableListView': (context) =>
          FrostedReorderableListView<String>(
            items: tasks,
            labelOf: (t) => t,
            onReorder: (from, to) =>
                setState(() => tasks.insert(to, tasks.removeAt(from))),
            itemBuilder: (context, t) => Text(t),
          ),
      'FrostedRefreshIndicator': (context) => FrostedRefreshIndicator(
        onRefresh: reload,
        child: ListView(children: rows),
      ),
      'FrostedSheetHead': (context) => FrostedSheetHead(
        title: 'Category',
        close: FrostedIconButton(
          FrostedGlyphs.close,
          label: DesignLocalizations.of(context).closeButtonLabel,
          size: FrostedIconButtonSize.small,
          onPressed: close,
        ),
      ),
      'FrostedSheetShell': (context) {
        const amount = Text('Amount');
        return FrostedSheetShell(
          title: 'Add money',
          foot: [FrostedButton('Add \$250', onPressed: add)],
          children: [amount, chips, from],
        );
      },
      'FrostedSheetCard': (context) => FrostedSheetCard(
        child: FrostedSheetShell(title: 'Category', children: options),
      ),
      'FrostedSheet.show': (context) {
        const options = Text('Groceries');
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          final picked = await FrostedSheet.show<String>(
            context,
            title: 'Category',
            builder: (context) => [options],
          );
        });
        return null;
      },
      'FrostedSheet.showSide': (context) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          FrostedSheet.showSide<void>(
            context,
            title: 'Filters',
            builder: (context) => [
              FrostedSwitchRow(
                label: 'Only unread',
                value: unread,
                onChanged: setUnread,
              ),
            ],
          );
        });
        return null;
      },
      'showFrostedBottomSheet': (context) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showFrostedBottomSheet<void>(
            context,
            builder: (context) => FrostedBottomSheet(
              title: 'Share',
              actions: [FrostedButton('Copy link', onPressed: copy)],
              child: shareTargets,
            ),
          );
        });
        return null;
      },
      'showFrostedBottomSheet 2': (context) {
        const options = Text('Newest first');
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          final choice = await showFrostedBottomSheet<String>(
            context,
            builder: (context) =>
                FrostedBottomSheet(title: 'Sort by', child: options),
          );
        });
        return null;
      },
      'Navigator 2': (context) => Navigator(
        pages: [
          FrostedSheetPage<void>(
            name: 'goal-new',
            drawer: true,
            child: NewGoalPage(),
          ),
        ],
        onDidRemovePage: (page) {},
      ),
      'FrostedNavigationDrawer': (context) => FrostedNavigationDrawer(
        items: tabs,
        selectedIndex: 0,
        onDestinationSelected: select,
        brand: 'Harbor',
      ),
      'FrostedSidebarAction': (context) => FrostedSidebarAction(
        icon: FrostedGlyphs.arrowRightLeft,
        label: 'Move money',
        onPressed: openMove,
      ),
      'FrostedSignInButton': (context) =>
          FrostedSignInButton('apple', onPressed: signInWithApple),
      'FrostedSignInButton 2': (context) => FrostedSignInButton(
        'email',
        emphasis: true,
        onPressed: signInWithEmail,
      ),
      'FrostedSignInStack': (context) => FrostedSignInStack(const [
        'apple',
        'google',
        'email',
      ], onPressed: signIn),
      'FrostedRangeSlider': (context) => FrostedRangeSlider(
        values: const DesignRangeValues(20, 80),
        max: 100,
        onChanged: (v) => setState(() => price = v),
        startLabel: 'Lowest price',
        endLabel: 'Highest price',
      ),
      'FrostedSlider': (context) => FrostedSlider(
        value: alertAt,
        min: 0,
        max: 100,
        divisions: 20,
        label: 'Alert at',
        semanticFormatterCallback: (v) => '\${v.round()}% of budget',
        onChanged: setAlertAt,
        onChangeEnd: saveAlertAt,
      ),
      'FrostedSlider 2': (context) => FrostedSlider(
        value: volume,
        onChanged: setVolume,
        label: 'Volume',
        style: const FrostedStyle(
          fill: WidgetStatePropertyAll(Color(0xFF5B5BD6)),
        ),
      ),
      'FrostedLoadingState': (context) => TickerMode(
        enabled: false,
        child: FrostedLoadingState(message: 'Loading your accounts'),
      ),
      'FrostedErrorState': (context) => FrostedErrorState(
        title: "Couldn't load your accounts",
        message: 'Check your connection, then try again.',
        onRetry: reload,
      ),
      'FrostedStatusView.loading': (context) => TickerMode(
        enabled: false,
        child: FrostedStatusView.loading(message: 'Loading your files'),
      ),
      'FrostedStatusView.error': (context) => FrostedStatusView.error(
        title: "Couldn't load your files",
        message: 'Check your connection, then try again.',
        onRetry: reload,
      ),
      'FrostedStatusView.success': (context) => FrostedStatusView.success(
        title: 'Sent',
        message: 'Ines will see it in her inbox.',
        action: FrostedButton('Done', onPressed: close),
      ),
      'FrostedEmptyState': (context) => FrostedEmptyState(
        title: 'No results for “sushi”',
        body: 'Only money that came in is searched while Money in is on.',
        actionLabel: 'Clear filters',
        actionIcon: FrostedGlyphs.close,
        onAction: clear,
      ),
      'FrostedSpectrumArt': (context) => FrostedSpectrumArt(),
      'FrostedListSection': (context) => FrostedListSection(
        title: 'Transactions',
        aside: '32 in October',
        rows: [FrostedDayHead('Today', first: true), row, row],
      ),
      'FrostedCard': (context) => FrostedCard(child: Text('On pace')),
      'FrostedCard.record': (context) =>
          FrostedCard.record(hue: t.hues.cyan, child: body),
      'FrostedCard 2': (context) => FrostedCard(
        style: const FrostedStyle(
          padding: WidgetStatePropertyAll(EdgeInsets.all(24)),
        ),
        child: Text('On pace'),
      ),
      'FrostedCardHeader': (context) => FrostedCardHeader(
        'Transactions',
        trailing: Text('32 in October', style: t.textTheme.bodySmall),
      ),
      'FrostedSectionHeader': (context) =>
          FrostedSectionHeader('Accounts', aside: '5 accounts'),
      'FrostedListTile': (context) => FrostedListTile(
        leading: FrostedMonogram('Blue Fern Café', hue: t.hues.coral),
        title: 'Blue Fern Café',
        meta: 'Dining out · 8:12 AM',
        trailing: const FrostedAmount(-6.75),
        onPressed: open,
      ),
      'FrostedListTile 2': (context) => FrostedListTile(
        title: 'Notifications',
        style: const FrostedStyle(
          padding: WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 10)),
        ),
      ),
      'FrostedRowEnd': (context) => FrostedRowEnd(
        amount: const FrostedAmount(-6.75),
        note: 'Pending',
        noteIcon: FrostedGlyphs.clock,
      ),
      'FrostedTransactionRow': (context) => FrostedTransactionRow(
        mark: FrostedTransactionMark.purchase(
          'Blue Fern Café',
          hue: t.hues.coral,
        ),
        title: 'Blue Fern Café',
        subtitle: 'Dining out · 8:12 AM',
        amount: -6.75,
        pending: true,
        account: 'Harbor Card',
        accountIcon: FrostedGlyphs.creditCard,
        onPressed: open,
      ),
      'FrostedDayHead': (context) =>
          FrostedDayHead('Today', net: -9.65, first: true),
      'FrostedRowGroup': (context) => FrostedRowGroup(
        children: [FrostedDayHead('Today', first: true), row, row],
      ),
      'FrostedMonthDivider': (context) => FrostedMonthDivider('September 2026'),
      'FrostedKeyValue': (context) => FrostedKeyValue(
        label: 'Held in',
        value: 'Savings ·· 9015',
        onPressed: openSavings,
      ),
      'FrostedDescriptionList': (context) => FrostedDescriptionList(
        children: [
          FrostedKeyValue(label: 'Status', value: 'Pending'),
          FrostedKeyValue(label: 'Card', value: 'Harbor Card ·· 7730'),
        ],
      ),
      'FrostedRecordHero': (context) => FrostedRecordHero(
        mark: FrostedIconMark(FrostedGlyphs.wallet, hue: everyday),
        title: 'Everyday',
        subtitle: 'Checking ·· 4821',
        amount: 6248.30,
        of: 'Available now',
        hue: everyday,
      ),
      'FrostedRecordHero.centred': (context) => FrostedRecordHero.centred(
        mark: FrostedTransactionMark.purchase(
          'Mesa Taqueria',
          hue: dining,
          size: FrostedMarkSize.large,
        ),
        title: 'Mesa Taqueria',
        subtitle: 'Dining out · Harbor Card',
        amount: -38.40,
        chips: [const FrostedTag('Posted', icon: FrostedGlyphs.check)],
        hue: dining,
      ),
      'FrostedRecordChart': (context) => FrostedRecordChart(
        head: Text('Balance through October', style: t.textTheme.bodySmall),
        chart: FrostedTrailChart.steps(
          values: balance,
          start: opening,
          daysInMonth: 31,
          marks: axis,
          label: 'Everyday balance through October',
        ),
      ),
      'FrostedInsight': (context) => FrostedInsight(
        icon: FrostedGlyphs.utensils,
        kind: 'Insight · Dining out',
        title: r'$36.40 over budget',
        body: r'13 visits to Blue Fern Café came to **$84.25**.',
        hue: t.hues.coral,
        visits: 13,
        onPressed: open,
      ),
      'FrostedSuggestion': (context) => FrostedSuggestion(
        icon: FrostedGlyphs.sparkles,
        title: r'Suggested $275',
        subtitle: 'Your September and October average',
        hue: t.hues.coral,
      ),
      'FrostedNote': (context) => FrostedNote(
        lead: FrostedTransactionMark.income('Northwind Studio'),
        title: 'Paycheck landed',
        body: r'+$3,412.50 from Northwind Studio.',
        when: 'Fri, Oct 23 · 6:31 AM',
        onPressed: open,
      ),
      'FrostedNoteHero': (context) => FrostedNoteHero(
        mark: const FrostedIconMark(
          FrostedGlyphs.receipt,
          size: FrostedMarkSize.large,
        ),
        when: 'New · Today · 9:00 AM',
        title: 'Rent is due in 4 days',
        body: r'$1,150.00 to Linden Court Apartments on Nov 1.',
        action: 'See your bills',
        onPressed: openBills,
      ),
      'FrostedNudge': (context) => FrostedNudge(
        r'Add $110 to stay on track.',
        action: FrostedButton(
          r'Add $110',
          size: FrostedButtonSize.small,
          onPressed: add,
        ),
      ),
      'FrostedNudge 2': (context) =>
          FrostedNudge(r'On track for next October at $100 a month.', ok: true),
      'FrostedBanner': (context) => FrostedBanner(
        icon: FrostedGlyphs.snowflake,
        title: 'Your card is frozen',
        body: 'New purchases and cash withdrawals are declined.',
      ),
      'FrostedBrowseCard': (context) => FrostedBrowseCard(
        icon: FrostedGlyphs.house,
        hue: t.hues.periwinkle,
        title: 'Rent & home',
        subtitle: r'$1,150.00',
        onPressed: open,
      ),
      'FrostedAccountCard': (context) => FrostedAccountCard(
        icon: FrostedGlyphs.wallet,
        hue: t.hues.cyan,
        name: 'Everyday',
        kind: 'Checking',
        mask: '•• 4821',
        balance: 6248.30,
        onPressed: open,
      ),
      'FrostedTicket': (context) => FrostedTicket(
        name: 'Linden Court Apartments',
        title: 'Linden Court Apartments',
        subtitle: 'One payment from Everyday',
        hue: t.hues.periwinkle,
        chip: 'Autopay',
        chipIcon: FrostedGlyphs.check,
      ),
      'FrostedSwipeActions': (context) => FrostedSwipeActions(
        trailing: [
          FrostedSwipeAction(
            label: 'Delete',
            icon: FrostedGlyphs.delete,
            tone: FrostedSwipeTone.destructive,
            onPressed: delete,
          ),
        ],
        fullSwipe: true,
        child: row,
      ),
      'FrostedTabBar': (context) => FrostedTabBar(
        tabs: const ['Spending', 'Income', 'Transfers'],
        selectedIndex: tab,
        expand: true,
        onChanged: setTab,
      ),
      'FrostedTabBar 2': (context) => FrostedTabBar(
        tabs: const ['Overview', 'Activity'],
        selectedIndex: tab,
        onChanged: setTab,
        style: FrostedStyle(
          fill: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? const Color(0xFFE8E6FF)
                : null,
          ),
        ),
      ),
      'FrostedToast.show': (context) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          FrostedToast.show(
            context,
            'Moved to Groceries',
            actionLabel: 'Undo',
            onAction: undo,
          );
        });
        return null;
      },
      'FrostedSnackBar': (context) => FrostedSnackBar(
        'Moved to Groceries',
        actionLabel: 'Undo',
        onAction: undo,
      ),
      'FrostedSnackBar 2': (context) => FrostedSnackBar(
        'Saved',
        style: const FrostedStyle(
          fill: WidgetStatePropertyAll(Color(0xFF1E2A3A)),
        ),
      ),
      'FrostedToggleGroup': (context) => FrostedToggleGroup<String>(
        label: 'Text style',
        multiple: true,
        segments: const [
          FrostedButtonSegment('b', 'Bold'),
          FrostedButtonSegment('i', 'Italic'),
        ],
        selected: styles,
        onChanged: (v) => setState(() => styles = v),
      ),
      'FrostedSplitButton': (context) => FrostedSplitButton(
        label: 'Save',
        onPressed: save,
        actions: [
          FrostedSplitAction(label: 'Save as…', onPressed: saveAs),
          FrostedSplitAction(label: 'Save all', onPressed: saveAll),
        ],
      ),
      'FrostedBack': (context) => FrostedBack(
        label: 'Activity',
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      'FrostedAppBar': (context) =>
          FrostedAppBar(title: 'Spending', caption: 'October 2026'),
      'FrostedAppBar 2': (context) =>
          FrostedAppBar(title: 'Account', backLabel: 'Home'),
      'FrostedAppBar.greeting': (context) => FrostedAppBar.greeting(
        title: FrostedFormat.greeting('Maren', now: now),
        subtitle: FrostedFormat.longDate(now),
      ),
      'FrostedWeekStrip': (context) => FrostedWeekStrip(
        start: DateTime(2026, 10, 26),
        days: const [
          FrostedDayStatus.complete,
          FrostedDayStatus.complete,
          FrostedDayStatus.missed,
          FrostedDayStatus.current,
          FrostedDayStatus.upcoming,
          FrostedDayStatus.upcoming,
          FrostedDayStatus.upcoming,
        ],
        onChanged: toggle,
      ),
      'FrostedWordmark': (context) => FrostedWordmark('Harbor'),
      'FrostedWordmark 2': (context) =>
          FrostedWordmark('Northlight', glyph: FrostedGlyphs.sparkles),
      'FrostedMark': (context) => FrostedMark(glyph: FrostedGlyphs.triangle),
      'TextField': (context) => TextField(
        selectionControls: FrostedTextSelectionControls.of(
          defaultTargetPlatform,
        ),
      ),
      'TextField 2': (context) =>
          TextField(contextMenuBuilder: FrostedTextContextMenu.editable),
      'FontLoader': (context) {
        Future<void> load() async {
          final loader = FontLoader(frostedFontFamily('DMSans'))
            ..addFont(bytes);
          await loader.load();
        }

        return load;
      },
      'Future': (context) {
        Future<void> main() async {
          WidgetsFlutterBinding.ensureInitialized();
          await frostedLoadFonts();
          runApp(const MyApp());
        }

        return main;
      },
      'Text': (context) =>
          Text(FrostedFormat.money(-1326.44), style: t.textTheme.amount),
      'FrostedIconButton 3': (context) =>
          FrostedIconButton(FrostedGlyphs.back, label: 'Back', onPressed: pop),
      'FrostedScaffold 2': (context) => FrostedScaffold(
        scroll: false,
        topBar: const FrostedAppBar(title: 'Inventory'),
        body: const FrostedInventoryGallery(),
      ),
      'FrostedThemeData.opal 2': (context) {
        final theme = FrostedThemeData.opal().copyWith(
          density: FrostedDensity.compact,
        );
        return null;
      },
      'FrostedThemeData.opal 3': (context) {
        final theme = FrostedThemeData.opal().copyWith(
          typeface: const FrostedTypeface(display: 'DMSans'),
        );
        return null;
      },
      'MaterialApp': (context) {
        const home = SizedBox();
        return MaterialApp(
          localizationsDelegates: const [
            FrostedLocalizations.delegate,
            DesignLocalizations.delegate,
          ],
          home: home,
        );
      },
      'FrostedMotion.of': (context) {
        final motion = FrostedMotion.of(context);
        AnimatedOpacity(
          opacity: shown ? 1 : 0,
          duration: motion.base,
          curve: motion.curve,
          child: child,
        );
        return null;
      },
      'Column': (context) =>
          Column(children: [title, const FrostedGap(FrostedSpacing.s12), body]),
      'FrostedTheme': (context) => FrostedTheme(
        data: FrostedThemeData(density: FrostedDensity.compact),
        child: app,
      ),
      'FrostedThemeData.from': (context) {
        final theme = FrostedThemeData.from(accent: const Color(0xFF0A7CFF));
        return null;
      },
      'FrostedThemeData.opal 4': (context) {
        final theme = FrostedThemeData.opal().copyWith(
          colorScheme: FrostedThemeData.opal().colorScheme.copyWith(
            accent: const Color(0xFF3A5BD9),
          ),
          density: FrostedDensity.compact,
        );
        return null;
      },
      'MaterialApp 2': (context) {
        const home = SizedBox();
        return MaterialApp(
          builder: (context, child) =>
              FrostedTheme(data: FrostedThemeData.opal(), child: child!),
          home: home,
        );
      },
      'MaterialApp 3': (context) {
        const home = SizedBox();
        return MaterialApp(
          theme: ThemeData(
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: frostedPageTransitions,
            ),
          ),
          builder: (context, child) =>
              FrostedTheme(data: FrostedThemeData.opal(), child: child!),
          home: home,
        );
      },
      'AnimatedFrostedTheme': (context) {
        const page = SizedBox();
        return AnimatedFrostedTheme(
          data: FrostedThemeData.opal(
            dark ? Brightness.dark : Brightness.light,
          ),
          child: page,
        );
      },
    },
  );
}
