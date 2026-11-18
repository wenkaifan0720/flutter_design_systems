// Boxes to write in: a text field sized for its answer, a paragraph, a
// date as three boxes, a file to send, and a fieldset over an address.
import 'package:material_ui/material_ui.dart';
import 'package:civic_ui/civic_ui.dart';

import '../kit.dart';

Widget kitEntryDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Text, dates & files',
  intro:
      'A label above, help under it, the error in words above the box. A box '
      'is as wide as what it takes.',
  sections: const [_Fields(), _Password(), _Dates(), _Files()],
);

class _Fields extends StatelessWidget {
  const _Fields();

  @override
  Widget build(BuildContext context) => const KitSection(
    title: 'Text fields',
    spacing: CivicSpacing.s24,
    children: [
      CivicTextField(
        labelText: 'Full name',
        autofillHints: [AutofillHints.name],
      ),
      CivicTextField(
        labelText: 'Postcode',
        helperText: 'For example, BR4 7QX',
        widthInCharacters: 10,
      ),
      CivicTextField(
        labelText: 'Email address',
        errorText:
            'Enter an email address in the right form, like name@example.com',
        keyboardType: TextInputType.emailAddress,
      ),
      CivicTextField(
        labelText: 'Permit fee you expect to pay',
        prefix: Text('€'),
        suffix: Text('a year'),
        widthInCharacters: 5,
      ),
      CivicTextField(
        labelText: 'Vehicle registration',
        enabled: false,
        widthInCharacters: 10,
      ),
      CivicTextField(
        labelText: 'Why do you need a second permit?',
        helperText: 'Do not include personal or financial information.',
        maxLines: 5,
        minLines: 3,
      ),
    ],
  );
}

class _Dates extends StatelessWidget {
  const _Dates();

  @override
  Widget build(BuildContext context) => const KitSection(
    title: 'Date input',
    spacing: CivicSpacing.s32,
    children: [
      CivicDateInput(
        labelText: 'What is your date of birth?',
        helperText: 'For example, 27 3 1987',
        dayLabel: 'Day',
        monthLabel: 'Month',
        yearLabel: 'Year',
      ),
      CivicDateInput(
        labelText: 'When did you move to this address?',
        errorText: 'The date you moved must include a year',
        errorParts: {CivicDatePart.year},
        dayLabel: 'Day',
        monthLabel: 'Month',
        yearLabel: 'Year',
      ),
    ],
  );
}

class _Files extends StatelessWidget {
  const _Files();

  @override
  Widget build(BuildContext context) => KitSection(
    title: 'File upload & fieldset',
    spacing: CivicSpacing.s32,
    children: [
      CivicFileUpload(
        labelText: 'Upload proof of address',
        helperText: 'A council tax bill or a tenancy agreement.',
        chooseLabel: 'Choose file',
        emptyLabel: 'No file chosen',
        onChoose: () {},
      ),
      CivicFileUpload(
        labelText: 'Upload proof of address',
        chooseLabel: 'Choose another file',
        emptyLabel: 'No file chosen',
        removeLabel: 'Remove',
        fileName: 'tenancy-agreement.pdf',
        onChoose: () {},
        onRemoved: () {},
      ),
      const CivicFieldset(
        labelText: 'What is your address?',
        children: [
          CivicTextField(
            labelText: 'Address line 1',
            autofillHints: [AutofillHints.streetAddressLine1],
          ),
          SizedBox(height: CivicSpacing.s16),
          CivicTextField(
            labelText: 'Town or city',
            autofillHints: [AutofillHints.addressCity],
          ),
          SizedBox(height: CivicSpacing.s16),
          CivicTextField(
            labelText: 'Postcode',
            widthInCharacters: 10,
            autofillHints: [AutofillHints.postalCode],
          ),
        ],
      ),
    ],
  );
}

class _Password extends StatelessWidget {
  const _Password();

  @override
  Widget build(BuildContext context) => const KitSection(
    title: 'Password',
    caption: 'Hidden as it is typed; the box under it shows it.',
    children: [
      CivicPasswordField(
        labelText: 'Create a password',
        helperText: 'At least 10 characters.',
        isNewPassword: true,
      ),
    ],
  );
}
