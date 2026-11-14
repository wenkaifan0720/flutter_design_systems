// The inventory's rows Frosted paints itself, one test each: what a page
// hands in comes back through its callback, a null callback leaves a part
// inert, and a screen reader hears what a sighted user sees.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:frosted_ui/frosted_host.dart';
import 'package:frosted_ui/src/frosted/internal/dim.dart';

/// Pumps [child] across a phone's page, 20 in from each side, on Frosted's
/// canvas; nothing may throw.
Future<void> _pump(WidgetTester t, Widget child, {bool scroll = false}) async {
  t.view.physicalSize = const Size(390, 844);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  final column = Column(
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [child],
  );
  await t.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (BuildContext context, Widget? page) =>
          FrostedHost(brightness: Brightness.light, child: page!),
      home: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: scroll ? SingleChildScrollView(child: column) : column,
      ),
    ),
  );
  expect(t.takeException(), isNull);
}

/// The node a screen reader lands on for [label].
SemanticsNode _node(WidgetTester t, String label) =>
    t.getSemantics(find.bySemanticsLabel(label));

/// The properties of the [Semantics] widget named [label].
SemanticsProperties _props(WidgetTester t, String label) => t
    .widget<Semantics>(
      find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.label == label,
      ),
    )
    .properties;

/// A part that keeps the value its callback hands back, as a page does.
class _Owner<T> extends StatefulWidget {
  const _Owner(this.initial, this.builder, {this.seen});

  final T initial;
  final Widget Function(T value, ValueChanged<T> set) builder;
  final List<T>? seen;

  @override
  State<_Owner<T>> createState() => _OwnerState<T>();
}

class _OwnerState<T> extends State<_Owner<T>> {
  late T _value = widget.initial;

  @override
  Widget build(BuildContext context) => widget.builder(_value, (v) {
    widget.seen?.add(v);
    setState(() => _value = v);
  });
}

void main() {
  group('choices', () {
    testWidgets('FrostedRadioGroup hands back the radio pressed', (t) async {
      final seen = <String?>[];
      await _pump(
        t,
        _Owner<String?>(
          'standard',
          seen: seen,
          (v, set) => FrostedRadioGroup<String>(
            label: 'Delivery',
            value: v,
            onChanged: set,
            options: const [
              FrostedRadio('standard', 'Standard'),
              FrostedRadio('express', 'Express'),
              FrostedRadio('pickup', 'Pick up', enabled: false),
            ],
          ),
        ),
      );
      await t.tap(find.text('Express'));
      await t.pumpAndSettle();
      await t.tap(find.text('Pick up'), warnIfMissed: false);
      await t.pumpAndSettle();
      expect(seen, ['express']);
    });

    testWidgets('FrostedCheckRow turns on a press anywhere on the row', (
      t,
    ) async {
      final seen = <bool?>[];
      await _pump(
        t,
        _Owner<bool?>(
          false,
          seen: seen,
          (v, set) => FrostedCheckRow(
            label: 'Email me a receipt',
            note: 'Sent to the address on file',
            value: v,
            onChanged: set,
          ),
        ),
      );
      await t.tap(find.text('Sent to the address on file'));
      await t.pumpAndSettle();
      expect(seen, [true]);
    });

    testWidgets('FrostedChoices lights the chip pressed; FrostedChip deletes '
        'through its own target', (t) async {
      final seen = <String?>[];
      var deleted = false;
      await _pump(
        t,
        Column(
          children: [
            _Owner<String?>(
              'm',
              seen: seen,
              (v, set) => FrostedChoices<String>(
                label: 'Size',
                value: v,
                onChanged: set,
                options: const [
                  FrostedSelectOption('s', 'Small'),
                  FrostedSelectOption('m', 'Medium'),
                  FrostedSelectOption('l', 'Large'),
                ],
              ),
            ),
            FrostedChip(
              'Ines Park',
              onDeleted: () => deleted = true,
              deleteLabel: 'Remove Ines Park',
            ),
          ],
        ),
      );
      await t.tap(find.text('Large'));
      await t.pumpAndSettle();
      expect(seen, ['l']);
      await t.tap(find.bySemanticsLabel('Remove Ines Park'));
      expect(deleted, isTrue);
    });

    testWidgets('FrostedRating goes up a star from the screen reader', (
      t,
    ) async {
      final seen = <double>[];
      await _pump(
        t,
        _Owner<double>(
          3,
          seen: seen,
          (v, set) =>
              FrostedRating(value: v, label: 'Your rating', onChanged: set),
        ),
      );
      _props(t, 'Your rating').onIncrease!();
      await t.pumpAndSettle();
      expect(seen, [4]);
    });
  });

  group('pickers', () {
    testWidgets('FrostedSelect drops its options and hands back the chosen', (
      t,
    ) async {
      final seen = <String?>[];
      await _pump(
        t,
        _Owner<String?>(
          null,
          seen: seen,
          (v, set) => FrostedSelect<String>(
            label: 'Room',
            value: v,
            onChanged: set,
            options: const [
              FrostedSelectOption('k', 'Kitchen'),
              FrostedSelectOption('s', 'Study'),
            ],
          ),
        ),
      );
      expect(find.text('Select'), findsOneWidget);
      await t.tap(find.text('Select'));
      await t.pumpAndSettle();
      await t.tap(find.text('Study'));
      await t.pumpAndSettle();
      expect(seen, ['s']);
      expect(find.text('Study'), findsOneWidget);
    });

    testWidgets('FrostedDatePicker chooses a day in range and turns months', (
      t,
    ) async {
      final seen = <DateTime?>[];
      await _pump(
        t,
        _Owner<DateTime?>(
          DateTime(2026, 11, 12),
          seen: seen,
          (v, set) => FrostedDatePicker(
            value: v,
            currentDate: DateTime(2026, 11, 9),
            first: DateTime(2026, 11, 3),
            last: DateTime(2026, 12, 31),
            onChanged: set,
          ),
        ),
      );
      expect(find.text('November 2026'), findsOneWidget);
      await t.tap(find.text('20'));
      await t.pumpAndSettle();
      await t.tap(find.text('2'), warnIfMissed: false);
      await t.pumpAndSettle();
      expect(seen, [DateTime(2026, 11, 20)]);
      await t.tap(find.bySemanticsLabel('Next month'));
      await t.pumpAndSettle();
      expect(find.text('December 2026'), findsOneWidget);
      await t.tap(find.bySemanticsLabel('Next month'), warnIfMissed: false);
      await t.pumpAndSettle();
      expect(find.text('December 2026'), findsOneWidget);
    });

    testWidgets('FrostedWheelPicker and FrostedTimePicker turn a row from '
        'the screen reader', (t) async {
      final guests = <int>[];
      final times = <FrostedTime>[];
      await _pump(
        t,
        scroll: true,
        Column(
          children: [
            _Owner<int>(
              2,
              seen: guests,
              (v, set) => FrostedWheelPicker<int>(
                label: 'Guests',
                value: v,
                onChanged: set,
                options: [
                  for (var n = 1; n <= 6; n++) FrostedSelectOption(n, '$n'),
                ],
              ),
            ),
            _Owner<FrostedTime>(
              const FrostedTime(hour: 9, minute: 30),
              seen: times,
              (v, set) => FrostedTimePicker(value: v, onChanged: set),
            ),
          ],
        ),
      );
      _props(t, 'Guests').onIncrease!();
      await t.pumpAndSettle();
      expect(guests, [3]);
      _props(t, 'Hour').onIncrease!();
      await t.pumpAndSettle();
      expect(times, [const FrostedTime(hour: 10, minute: 30)]);
    });

    test('FrostedTime is a value', () {
      expect(
        const FrostedTime(hour: 7, minute: 5),
        FrostedTime.fromDateTime(DateTime(2026, 1, 1, 7, 5)),
      );
      expect(
        const FrostedTime(hour: 7, minute: 5).copyWith(hour: 19),
        const FrostedTime(hour: 19, minute: 5),
      );
    });
  });

  group('charts', () {
    testWidgets('the charts read their series aloud', (t) async {
      await _pump(
        t,
        scroll: true,
        const Column(
          children: [
            FrostedLineChart(
              label: 'Visitors',
              labels: ['Mon', 'Tue', 'Wed'],
              series: [
                FrostedChartSeries('Visitors', [120, 180, 150]),
              ],
            ),
            FrostedAreaChart(
              label: 'Storage',
              series: [
                FrostedChartSeries('Photos', [2, null, 5]),
              ],
            ),
            FrostedBarChart(
              label: 'Tickets',
              labels: ['W1', 'W2'],
              current: 1,
              series: [
                FrostedChartSeries('Opened', [14, 22]),
                FrostedChartSeries('Closed', [11, 19]),
              ],
            ),
            FrostedPieChart(
              label: 'Time spent',
              slices: [
                FrostedPieSlice('Focus', 30),
                FrostedPieSlice('Email', 10),
              ],
            ),
            FrostedSparkline([3, 5, 9], label: 'Sign-ups', width: 120),
          ],
        ),
      );
      expect(
        _node(t, 'Visitors').value,
        'Visitors: 120 to 150, high 180, low 120',
      );
      expect(_node(t, 'Time spent').value, 'Focus, 75%; Email, 25%');
      expect(_node(t, 'Sign-ups').value, '3 to 9, high 9, low 3');
      expect(_node(t, 'Tickets').value, contains('Closed: 11 to 19'));
    });
  });

  group('hold and move', () {
    testWidgets('FrostedDisclosure opens on a press and says so', (t) async {
      await _pump(
        t,
        const FrostedDisclosure(title: 'Details', child: Text('Inside')),
      );
      expect(find.text('Inside'), findsNothing);
      expect(_node(t, 'Details'), isSemantics(isExpanded: false));
      await t.tap(find.text('Details'));
      await t.pumpAndSettle();
      expect(find.text('Inside'), findsOneWidget);
      expect(_node(t, 'Details'), isSemantics(isExpanded: true));
    });

    testWidgets('FrostedPagination steps on and FrostedTable stacks when '
        'narrow', (t) async {
      final seen = <int>[];
      await _pump(
        t,
        Column(
          children: [
            _Owner<int>(
              0,
              seen: seen,
              (i, set) => FrostedPagination(
                pageCount: 5,
                selectedIndex: i,
                onChanged: set,
              ),
            ),
            const SizedBox(
              width: 200,
              child: FrostedTable(
                columns: [
                  FrostedTableColumn('Name'),
                  FrostedTableColumn('Role'),
                  FrostedTableColumn('Tasks', numeric: true),
                ],
                rows: [
                  ['Ines Park', 'Design', 12],
                ],
              ),
            ),
          ],
        ),
      );
      await t.tap(find.bySemanticsLabel('Next'));
      await t.pumpAndSettle();
      expect(seen, [1]);
      expect(find.text('Ines Park'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
    });

    testWidgets('FrostedIconButton says when a toggle is on', (t) async {
      await _pump(
        t,
        FrostedIconButton(
          FrostedGlyphs.share,
          label: 'Shared',
          selected: true,
          onPressed: () {},
        ),
      );
      expect(_node(t, 'Shared'), isSemantics(isToggled: true));
    });
  });

  group('raised', () {
    testWidgets('showFrostedDialog completes with what its actions pop', (
      t,
    ) async {
      String? result;
      await _pump(
        t,
        Builder(
          builder: (context) => FrostedButton(
            'Open',
            onPressed: () async {
              result = await showFrostedDialog<String>(
                context,
                builder: (dialog) => FrostedDialog(
                  title: 'Archive this project?',
                  message: 'You can restore it later.',
                  actions: [
                    FrostedButton.glass(
                      'Keep',
                      onPressed: () => Navigator.of(dialog).pop('keep'),
                    ),
                    FrostedButton(
                      'Archive',
                      onPressed: () => Navigator.of(dialog).pop('archive'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
      await t.tap(find.text('Open'));
      await t.pumpAndSettle();
      expect(find.text('You can restore it later.'), findsOneWidget);
      await t.tap(find.text('Archive'));
      await t.pumpAndSettle();
      expect(result, 'archive');
    });

    testWidgets('showFrostedActionSheet completes with the act chosen', (
      t,
    ) async {
      String? result;
      await _pump(
        t,
        Builder(
          builder: (context) => FrostedButton(
            'Open',
            onPressed: () async {
              result = await showFrostedActionSheet<String>(
                context,
                builder: (_) => const FrostedActionSheet<String>(
                  title: 'Photo',
                  actions: [
                    FrostedActionSheetAction('Share', value: 'share'),
                    FrostedActionSheetAction('Duplicate', value: 'duplicate'),
                  ],
                ),
              );
            },
          ),
        ),
      );
      await t.tap(find.text('Open'));
      await t.pumpAndSettle();
      await t.tap(find.text('Duplicate'));
      await t.pumpAndSettle();
      expect(result, 'duplicate');
    });

    testWidgets('FrostedSnackBar sets a title over its message', (t) async {
      await _pump(
        t,
        const FrostedSnackBar(
          'Check your connection.',
          title: 'Upload paused',
          tone: FrostedTone.warning,
        ),
      );
      expect(find.text('Upload paused'), findsOneWidget);
      expect(find.text('Check your connection.'), findsOneWidget);
    });

    testWidgets('FrostedTooltip shows on a long press', (t) async {
      await _pump(
        t,
        Center(
          child: FrostedTooltip(
            message: 'Share with your team',
            child: FrostedIconButton(
              FrostedGlyphs.share,
              label: 'Share',
              onPressed: () {},
            ),
          ),
        ),
      );
      expect(find.text('Share with your team'), findsNothing);
      await t.longPress(find.bySemanticsLabel('Share'));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('Share with your team'), findsOneWidget);
      await t.pump(const Duration(seconds: 2));
      await t.pumpAndSettle();
      expect(find.text('Share with your team'), findsNothing);
    });
  });

  group('progress', () {
    testWidgets('the indicators and bones lay out and are named', (t) async {
      await _pump(
        t,
        const Column(
          children: [
            FrostedLinearProgressIndicator(label: 'Uploading', value: 0.6),
            FrostedCircularProgressIndicator(label: 'Loading'),
            FrostedSkeleton.text(lines: 2),
            FrostedStatusView.loading(message: 'Fetching'),
          ],
        ),
      );
      expect(find.bySemanticsLabel('Uploading'), findsOneWidget);
      expect(find.bySemanticsLabel('Loading'), findsOneWidget);
    });
  });

  // The inventory's tiles show each part live: a specimen built without its
  // callback stood drawn off (self-review rounds 8 and 9: the file upload,
  // the time and wheel pickers, the pagination).
  testWidgets('no specimen in the inventory stands drawn off', (t) async {
    final off = <String>[];
    for (final entry in frostedInventory.entries) {
      final build = entry.builder;
      if (build == null) continue;
      await _pump(
        t,
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 600),
          child: Builder(builder: build),
        ),
      );
      if (t.widgetList<FrostedDim>(find.byType(FrostedDim)).any((d) => d.off)) {
        off.add(entry.row);
      }
    }
    expect(off, isEmpty);
  });
}
