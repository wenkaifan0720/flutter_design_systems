// The error summary: what a page sent with problems shows first, each
// problem a link to its field, the fields saying the same words.
import 'package:material_ui/material_ui.dart';
import 'package:civic_ui/civic_ui.dart';

import '../kit.dart';

Widget kitErrorsDemo(Brightness brightness) =>
    kitApp(brightness: brightness, home: const _Errors());

class _Errors extends StatefulWidget {
  const _Errors();

  @override
  State<_Errors> createState() => _ErrorsState();
}

class _ErrorsState extends State<_Errors> {
  final FocusNode _name = FocusNode();
  final FocusNode _day = FocusNode();

  @override
  void dispose() {
    _name.dispose();
    _day.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CivicScaffold(
    topBar: const CivicTopBar(title: 'Civic', emblem: KitEmblem()),
    body: CivicPageBody(
      backLink: CivicBackLink(onPressed: () {}),
      children: [
        CivicErrorSummary(
          title: 'There is a problem',
          autofocus: false,
          errors: [
            CivicErrorSummaryItem(
              text: 'Enter your full name',
              onPressed: _name.requestFocus,
            ),
            CivicErrorSummaryItem(
              text: 'Date of birth must include a month',
              onPressed: _day.requestFocus,
            ),
          ],
        ),
        const SizedBox(height: CivicSpacing.s32),
        Semantics(
          header: true,
          child: Text('Your details', style: context.civicText.headingXL),
        ),
        const SizedBox(height: CivicSpacing.s32),
        CivicTextField(
          labelText: 'Full name',
          errorText: 'Enter your full name',
          focusNode: _name,
        ),
        const SizedBox(height: CivicSpacing.s32),
        CivicDateInput(
          labelText: 'Date of birth',
          helperText: 'For example, 27 3 1987',
          errorText: 'Date of birth must include a month',
          errorParts: const {CivicDatePart.month},
          dayLabel: 'Day',
          monthLabel: 'Month',
          yearLabel: 'Year',
          monthFocusNode: _day,
        ),
        const SizedBox(height: CivicSpacing.s40),
        CivicButton(onPressed: () {}, child: const Text('Continue')),
      ],
    ),
  );
}
