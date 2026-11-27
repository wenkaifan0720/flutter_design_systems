// A public service moves the focus to its error summary on every send that
// fails, not only the first: a second send with the same problems, sent
// from the form's foot, takes the focus back to the summary and brings it
// into view, as one with other problems does. A rebuild that is no new send
// (the reader typing) leaves the focus where it is.
import 'package:civic_ui/civic_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

// A form: the summary at its top, a field, a long way down, its Save.
class _Form extends StatefulWidget {
  const _Form({required this.problems});

  // The problems each send finds.
  final List<String> Function(int send) problems;

  @override
  State<_Form> createState() => _FormState();
}

class _FormState extends State<_Form> {
  final field = FocusNode(debugLabel: 'field');
  int sends = 0;
  List<String> errors = const [];

  void send() => setState(() {
    sends++;
    errors = widget.problems(sends);
  });

  @override
  void dispose() {
    field.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Material(
    child: SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 200),
          if (errors.isNotEmpty)
            CivicErrorSummary(
              title: 'There is a problem',
              submission: sends,
              errors: [
                for (final e in errors)
                  CivicErrorSummaryItem(text: e, onPressed: field.requestFocus),
              ],
            ),
          CivicTextField(labelText: 'Title', focusNode: field),
          const SizedBox(height: 2000),
          CivicButton(onPressed: send, child: const Text('Save book')),
        ],
      ),
    ),
  );
}

Future<_FormState> _pump(
  WidgetTester tester,
  List<String> Function(int send) problems,
) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => CivicHost(child: child!),
      home: _Form(problems: problems),
    ),
  );
  return tester.state<_FormState>(find.byType(_Form));
}

// Sends from the foot, after the reader has gone back to the field.
Future<void> _sendFromFoot(WidgetTester tester, _FormState form) async {
  form.field.requestFocus();
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(
    find.text('Save book'),
    400,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Save book'));
  await tester.pumpAndSettle();
}

bool _summaryFocused(WidgetTester tester) =>
    FocusManager.instance.primaryFocus?.context
        ?.findAncestorWidgetOfExactType<CivicErrorSummary>() !=
    null;

void _inView(WidgetTester tester) {
  final top = tester.getRect(find.byType(CivicErrorSummary)).top;
  expect(top, inInclusiveRange(0, 844 - 100), reason: 'the summary is in view');
}

void main() {
  for (final (name, problems) in [
    ('the same problems', (int _) => const ['Enter the book’s title']),
    (
      'other problems',
      (int send) => [
        if (send > 1) 'Enter the author',
        'Enter the book’s title',
      ],
    ),
  ]) {
    testWidgets('a second send with $name takes the focus back to the '
        'summary and brings it into view', (tester) async {
      final form = await _pump(tester, problems);
      await _sendFromFoot(tester, form);
      expect(_summaryFocused(tester), isTrue, reason: 'first send');
      _inView(tester);
      await _sendFromFoot(tester, form);
      expect(_summaryFocused(tester), isTrue, reason: 'second send');
      _inView(tester);
    });
  }

  testWidgets('a rebuild that is no new send leaves the focus in the field', (
    tester,
  ) async {
    final form = await _pump(tester, (_) => const ['Enter the book’s title']);
    await _sendFromFoot(tester, form);
    form.field.requestFocus();
    await tester.pumpAndSettle();
    // The reader types: the page rebuilds, the send is the same.
    // ignore: invalid_use_of_protected_member
    form.setState(() {});
    await tester.pumpAndSettle();
    expect(form.field.hasFocus, isTrue);
  });
}
