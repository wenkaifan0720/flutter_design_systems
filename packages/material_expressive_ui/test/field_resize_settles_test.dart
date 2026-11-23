/// Every field settles as its window is resized, from 320 to 1920 at 1x, 2x
/// and 3x text: after the frame that lays it out at the new width, no other
/// frame is scheduled. 0.3.1 decided a read-only value's lines from widths
/// its entry reported as it was laid out; a select from 600 lays its field
/// out twice a frame (as given, then as wide as its widest option), so a
/// value too long for the first width and short enough for the second
/// flipped its lines twice a frame and rebuilt every frame without end
/// (Stint's task detail, its Project select, after the window widened from
/// 390 to 1440).
///
/// Such a select's field is 280 wide as it is first laid out, as Compose's
/// is, and 320 once widened, so its values here are the prefixes of one
/// long label a character apart: some fall between the two widths at every
/// text scale.
library;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/material_expressive_host.dart';

final ExpressiveThemeData _theme = ExpressiveThemeData.preset(
  'baseline',
  Brightness.light,
);

const _projects = <ExpressiveSelectOption<String>>[
  ExpressiveSelectOption('studio', 'Open studio'),
  ExpressiveSelectOption('guide', 'Field guide'),
  ExpressiveSelectOption('workshops', 'Workshop series for the spring term'),
];

class _Fields extends StatefulWidget {
  const _Fields();

  @override
  State<_Fields> createState() => _FieldsState();
}

class _FieldsState extends State<_Fields> {
  final _typed = TextEditingController(text: 'Proof the studio map');
  final _date = TextEditingController(text: 'Friday, 20 November 2026');
  final _notes = TextEditingController(
    text: 'Walk the route once more before the guide goes to print.',
  );
  final _password = TextEditingController(text: 'correct horse');
  final _assignee = TextEditingController(text: 'Noor Haddad');
  final _code = TextEditingController(text: '123456');
  final _time = ExpressiveTimePickerController(hour: 9, minute: 30);
  var _guests = 3;

  @override
  void dispose() {
    for (final c in [_typed, _date, _notes, _password, _assignee, _code]) {
      c.dispose();
    }
    _time.dispose();
    super.dispose();
  }

  Widget _select(String value, {bool leading = false, bool outlined = false}) =>
      ExpressiveSelect<String>(
        labelText: 'Project',
        value: value,
        kind: outlined
            ? ExpressiveTextFieldKind.outlined
            : ExpressiveTextFieldKind.filled,
        leading: leading
            ? const ExpressiveIcon(ExpressiveSymbols.folder)
            : null,
        options: _projects,
        onChanged: (_) {},
      );

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 16,
    children: [
      // Stint's: a short value beside a folder, a long option.
      _select('studio', leading: true),
      // The widest option itself, as filled and as outlined.
      _select('workshops'),
      _select('workshops', leading: true, outlined: true),
      ExpressiveMultiSelect<String>(
        labelText: 'Projects',
        options: _projects,
        values: const ['studio', 'workshops'],
        onChanged: (_) {},
      ),
      ExpressiveCombobox<String>(
        labelText: 'Assignee',
        controller: _assignee,
        options: const [
          ExpressiveSelectOption('noor', 'Noor Haddad'),
          ExpressiveSelectOption('sam', 'Sam Okafor'),
        ],
        onSelected: (_) {},
      ),
      ExpressiveTextField(labelText: 'Title', controller: _typed),
      // A read-only value that opens something, as a date field's.
      ExpressiveTextField(
        labelText: 'Due',
        controller: _date,
        readOnly: true,
        onTap: () {},
        trailing: const ExpressiveIcon(ExpressiveSymbols.event),
      ),
      // One that asks its row's intrinsic height.
      IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 8,
          children: [
            Expanded(
              child: ExpressiveTextField(
                labelText: 'Starts',
                controller: _date,
                readOnly: true,
                onTap: () {},
                kind: ExpressiveTextFieldKind.outlined,
              ),
            ),
            const Expanded(child: SizedBox()),
          ],
        ),
      ),
      ExpressiveTextArea(labelText: 'Notes', controller: _notes),
      ExpressivePasswordField(labelText: 'Password', controller: _password),
      ExpressiveNumberField(
        labelText: 'Guests',
        value: _guests,
        min: 1,
        max: 8,
        onChanged: (v) => setState(() => _guests = v),
      ),
      ExpressiveSearchField(hintText: 'Search tasks', onChanged: (_) {}),
      ExpressiveInputOtp(controller: _code),
      ExpressiveTimeInput(controller: _time),
    ],
  );
}

/// The widest option, and the values' words.
const _long = 'Open studio and the field guide for the spring workshop series';

/// A select for each prefix of [_long] from 4 to 34 characters, with and
/// without a leading icon.
class _Prefixes extends StatelessWidget {
  const _Prefixes();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 8,
    children: [
      for (final leading in [true, false])
        for (var n = 4; n <= 34; n++)
          ExpressiveSelect<int>(
            labelText: 'Project',
            value: n,
            leading: leading
                ? const ExpressiveIcon(ExpressiveSymbols.folder)
                : null,
            options: [
              ExpressiveSelectOption(n, _long.substring(0, n)),
              const ExpressiveSelectOption(0, _long),
            ],
            onChanged: (_) {},
          ),
    ],
  );
}

Widget _app(double scale, {Widget fields = const _Fields()}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, app) =>
      ExpressiveHost(theme: _theme, brightness: Brightness.light, child: app!),
  // At 1x, the platform's own scaler, as an app has it; and the page built
  // by a LayoutBuilder, as an adaptive app's is (Stint's).
  home: Builder(
    builder: (context) => MediaQuery(
      data: scale == 1
          ? MediaQuery.of(context)
          : MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Align(
            alignment: AlignmentDirectional.topStart,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: fields,
            ),
          ),
        ),
      ),
    ),
  ),
);

/// The window [width] wide: the frame that lays it out, then the frames that
/// follow while any is scheduled (at most [limit]).
Future<int> _resize(WidgetTester tester, double width, {int limit = 30}) async {
  tester.view.physicalSize = Size(width, 900);
  await tester.pump();
  var frames = 0;
  while (tester.binding.hasScheduledFrame && frames < limit) {
    await tester.pump(const Duration(milliseconds: 16));
    frames++;
  }
  return frames;
}

void main() {
  // Roboto Flex's own widths: the values wrap where they would in an app.
  setUpAll(expressiveLoadFonts);

  for (final scale in const [1.0, 2.0, 3.0]) {
    testWidgets('a select whose value fits only once widened to its widest '
        'option settles, at ${scale}x text', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 900);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_app(scale, fields: const _Prefixes()));
      await tester.pumpAndSettle();
      final unsettled = <double>[];
      for (final width in const <double>[
        1440,
        390,
        600,
        601,
        700,
        1024,
        1920,
        599,
      ]) {
        await _resize(tester, width, limit: 4);
        if (tester.binding.hasScheduledFrame) unsettled.add(width);
      }
      expect(tester.takeException(), isNull);
      expect(
        unsettled,
        isEmpty,
        reason: 'a frame is still scheduled 4 frames after these widths',
      );
    });
  }

  for (final scale in const [1.0, 2.0, 3.0]) {
    testWidgets('every field settles as the window widens from 390 to 1440 '
        'and is swept from 320 to 1920 and back, at ${scale}x text', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 900);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_app(scale));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      expect(
        await _resize(tester, 1440),
        lessThan(30),
        reason: 'the frames stop after 390 → 1440',
      );
      expect(tester.binding.hasScheduledFrame, isFalse);

      final unsettled = <double>[];
      for (final widths in [
        [for (var w = 320.0; w <= 1920; w += 8) w],
        [for (var w = 1920.0; w >= 320; w -= 8) w],
      ]) {
        for (final width in widths) {
          await _resize(tester, width, limit: 4);
          if (tester.binding.hasScheduledFrame) unsettled.add(width);
        }
      }
      expect(tester.takeException(), isNull);
      expect(
        unsettled,
        isEmpty,
        reason: 'a frame is still scheduled 4 frames after these widths',
      );
    });
  }
}
