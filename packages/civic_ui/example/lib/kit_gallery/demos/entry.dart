// Boxes to write in: a text field sized for its answer, a paragraph with
// its count, a security code, a number stepped by one, a date as three
// boxes, a file to send, and a fieldset over an address.
import 'package:material_ui/material_ui.dart';
import 'package:civic_ui/civic_ui.dart';

import '../kit.dart';

Widget kitEntryDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Text, numbers, codes & files',
  intro:
      'A label above, help under it, the error in words above the box. A box '
      'is as wide as what it takes.',
  sections: const [
    _Fields(),
    _Paragraph(),
    _Password(),
    _Code(),
    _Number(),
    _Dates(),
    _Files(),
  ],
);

class _Paragraph extends StatefulWidget {
  const _Paragraph();

  @override
  State<_Paragraph> createState() => _ParagraphState();
}

class _ParagraphState extends State<_Paragraph> {
  final _reason = TextEditingController(
    text: 'My mother visits twice a week to help with the children.',
  );
  final _long = TextEditingController(
    text:
        'We share a driveway with the house next door, and on weekdays it is '
        'used by their carer from eight in the morning until six.',
  );

  @override
  void dispose() {
    _reason.dispose();
    _long.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => KitSection(
    title: 'Text area',
    caption:
        'A paragraph with a live count. Past the limit, the count turns to '
        'the error colour and says how many characters too many.',
    spacing: CivicSpacing.s32,
    children: [
      CivicTextArea(
        labelText: 'Why do you need a visitor permit?',
        helperText: 'Do not include personal or financial information.',
        maxLength: 200,
        controller: _reason,
      ),
      CivicTextArea(
        labelText: 'Tell us about the parking on your street',
        maxLength: 100,
        minLines: 3,
        controller: _long,
      ),
    ],
  );
}

class _Code extends StatefulWidget {
  const _Code();

  @override
  State<_Code> createState() => _CodeState();
}

class _CodeState extends State<_Code> {
  final _code = RawOtpController(length: 6);
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => KitSection(
    title: 'Security code',
    caption: 'One well of places, the caret at the next one.',
    children: [
      CivicCodeField(
        labelText: 'Security code',
        helperText: 'We sent a 6 digit code to 07700 900 123.',
        errorText: _error,
        controller: _code,
        onCompleted: (code) => setState(
          () => _error = code == '482613' ? null : 'The code is not right',
        ),
      ),
    ],
  );
}

class _Number extends StatefulWidget {
  const _Number();

  @override
  State<_Number> createState() => _NumberState();
}

class _NumberState extends State<_Number> {
  double? _days = 3;

  @override
  Widget build(BuildContext context) => KitSection(
    title: 'Number field',
    caption: 'Typed, or stepped by the buttons either side.',
    children: [
      CivicNumberField(
        labelText: 'How many visitor days do you need?',
        helperText: 'From 1 to 30 days.',
        value: _days,
        min: 1,
        max: 30,
        onChanged: (days) => setState(() => _days = days),
      ),
    ],
  );
}

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
            'Enter an email address in the right form, like ana@example.com',
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
