// A failed send brings the error summary into view with the page's heading
// over it whole. At 1440 a page scrolled a little (less than its heading's
// height) left the summary where it was, in view, and the heading cut under
// the app's bar ("Add a book" showing its lower half under the bar's rule).
import 'package:civic_ui/civic_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

class _Add extends StatefulWidget {
  const _Add();

  @override
  State<_Add> createState() => _AddState();
}

class _AddState extends State<_Add> {
  // A press of Save: the form is sent and refused.
  void send() => setState(() => sends++);

  int sends = 0;

  @override
  Widget build(BuildContext context) => CivicScreen(
    topBar: const CivicTopBar(title: 'Add'),
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: CivicSpacing.s24,
      children: [
        Semantics(
          header: true,
          child: Text('Add a book', style: context.civicText.headingXL),
        ),
        if (sends > 0)
          CivicErrorSummary(
            title: 'There is a problem',
            submission: sends,
            errors: [
              CivicErrorSummaryItem(
                text: 'Enter the book’s title',
                onPressed: () {},
              ),
            ],
          ),
        const CivicTextField(labelText: 'Title'),
        const CivicTextField(labelText: 'Author'),
        const SizedBox(height: 600),
        CivicButton(onPressed: send, child: const Text('Save book')),
      ],
    ),
  );
}

void main() {
  for (final size in const [Size(1440, 900), Size(390, 844)]) {
    for (final scrolled in [24.0, 60.0]) {
      testWidgets('the heading shows whole after a failed send '
          '(${size.width.round()}, scrolled ${scrolled.round()})', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => CivicHost(child: child!),
            home: const _Add(),
          ),
        );
        await tester.pumpAndSettle();
        final position = tester
            .state<ScrollableState>(find.byType(Scrollable).first)
            .position;
        position.jumpTo(scrolled);
        await tester.pumpAndSettle();
        tester.state<_AddState>(find.byType(_Add)).send();
        await tester.pumpAndSettle();
        final bar = tester.getRect(find.byType(CivicTopBar));
        final heading = tester.getRect(find.text('Add a book'));
        expect(
          heading.top,
          greaterThanOrEqualTo(bar.bottom),
          reason: 'the heading $heading under the bar $bar',
        );
        expect(
          tester.getRect(find.byType(CivicErrorSummary)).bottom,
          lessThanOrEqualTo(size.height),
        );
      });
    }
  }
}
