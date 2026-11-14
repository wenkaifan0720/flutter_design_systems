/// The text-fields group's demo: filled and outlined fields, Expressive's
/// rounded and tonal forms, icons, affixes, the secure field, errors, the
/// counter, disabled and read-only, the text area and the code input — each
/// empty and filled, so the label rests inside and minimizes.
library;

import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

import '../kit.dart';

/// The text-fields group's demo, in [brightness].
Widget kitTextFieldsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Text fields',
  sections: const <Widget>[
    _Styles(),
    _Expressive(),
    _Decorations(),
    _Secure(),
    _Password(),
    _Errors(),
    _Counter(),
    _Inactive(),
    _Areas(),
    _Codes(),
    _Files(),
  ],
);

/// Builds [builder] around a controller holding [text], owned here.
class _WithText extends StatefulWidget {
  const _WithText(this.text, this.builder);

  final String text;
  final Widget Function(TextEditingController controller) builder;

  @override
  State<_WithText> createState() => _WithTextState();
}

class _WithTextState extends State<_WithText> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.text,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(_controller);
}

class _Styles extends StatelessWidget {
  const _Styles();

  @override
  Widget build(BuildContext context) => kitSection(
    'Filled and outlined',
    children: <Widget>[
      for (final style in ExpressiveTextFieldKind.values) ...<Widget>[
        ExpressiveTextField(kind: style, label: 'Trip name'),
        _WithText(
          'Lisbon in spring',
          (controller) => ExpressiveTextField(
            kind: style,
            controller: controller,
            label: 'Trip name',
            helperText: 'Shown to everyone you invite',
          ),
        ),
      ],
    ],
  );
}

class _Expressive extends StatelessWidget {
  const _Expressive();

  @override
  Widget build(BuildContext context) => kitSection(
    'Expressive rounded and tonal',
    children: <Widget>[
      const ExpressiveTextField(
        rounded: true,
        label: 'Guest name',
        leading: Icon(ExpressiveSymbols.person),
      ),
      const ExpressiveTextField(
        kind: ExpressiveTextFieldKind.outlined,
        rounded: true,
        label: 'Guest name',
        leading: Icon(ExpressiveSymbols.person),
      ),
      _WithText(
        'Ines Carvalho',
        (controller) => ExpressiveTextField(
          rounded: true,
          tonal: true,
          controller: controller,
          label: 'Guest name',
          leading: const Icon(ExpressiveSymbols.person),
        ),
      ),
      const ExpressiveTextField(
        kind: ExpressiveTextFieldKind.outlined,
        rounded: true,
        tonal: true,
        hintText: 'Search your trips',
        leading: Icon(ExpressiveSymbols.search),
      ),
    ],
  );
}

class _Decorations extends StatelessWidget {
  const _Decorations();

  @override
  Widget build(BuildContext context) => kitSection(
    'Icons, prefix and suffix',
    children: <Widget>[
      _WithText(
        '240',
        (controller) => ExpressiveTextField(
          controller: controller,
          label: 'Nightly budget',
          prefix: r'$',
          suffix: 'USD',
          keyboardType: TextInputType.number,
        ),
      ),
      const ExpressiveTextField(
        kind: ExpressiveTextFieldKind.outlined,
        label: 'Luggage allowance',
        alwaysMinimizeLabel: true,
        hintText: '23',
        suffix: 'kg',
        keyboardType: TextInputType.number,
      ),
      _WithText(
        'hello@harbourhouse.example',
        (controller) => ExpressiveTextField(
          controller: controller,
          kind: ExpressiveTextFieldKind.outlined,
          label: 'Host email',
          leading: const Icon(ExpressiveSymbols.email),
          trailing: const Icon(ExpressiveSymbols.checkCircle),
          keyboardType: TextInputType.emailAddress,
        ),
      ),
    ],
  );
}

class _Secure extends StatelessWidget {
  const _Secure();

  @override
  Widget build(BuildContext context) => kitSection(
    'Secure',
    children: <Widget>[
      _WithText(
        'harbour-lights-42',
        (controller) => ExpressiveTextField(
          controller: controller,
          obscureText: true,
          label: 'Password',
          leading: const Icon(ExpressiveSymbols.lock),
          helperText: 'At least 12 characters',
        ),
      ),
      const ExpressiveTextField(
        kind: ExpressiveTextFieldKind.outlined,
        obscureText: true,
        label: 'Confirm password',
      ),
    ],
  );
}

class _Errors extends StatelessWidget {
  const _Errors();

  @override
  Widget build(BuildContext context) => kitSection(
    'Errors',
    children: <Widget>[
      _WithText(
        'maya@',
        (controller) => ExpressiveTextField(
          controller: controller,
          label: 'Email',
          errorText: 'Enter a full address, like maya@example.com',
          trailing: const Icon(ExpressiveSymbols.error),
        ),
      ),
      const ExpressiveTextField(
        kind: ExpressiveTextFieldKind.outlined,
        label: 'Check-in date',
        errorText: 'Choose a date after today',
      ),
      const ExpressiveTextField(
        rounded: true,
        tonal: true,
        label: 'Room',
        errorText: '',
      ),
      const ExpressiveFieldError('Pick at least one room type to continue'),
    ],
  );
}

class _Counter extends StatelessWidget {
  const _Counter();

  @override
  Widget build(BuildContext context) => kitSection(
    'Counter',
    children: <Widget>[
      _WithText(
        'Sea view, quiet street',
        (controller) => ExpressiveTextField(
          controller: controller,
          kind: ExpressiveTextFieldKind.outlined,
          label: 'Headline',
          helperText: 'A short line for the listing',
          maxLength: 40,
        ),
      ),
    ],
  );
}

class _Inactive extends StatelessWidget {
  const _Inactive();

  @override
  Widget build(BuildContext context) => kitSection(
    'Disabled and read-only',
    children: <Widget>[
      _WithText(
        'Harbour House',
        (controller) => ExpressiveTextField(
          controller: controller,
          label: 'Property',
          leading: const Icon(ExpressiveSymbols.home),
          enabled: false,
        ),
      ),
      const ExpressiveTextField(
        kind: ExpressiveTextFieldKind.outlined,
        label: 'Promo code',
        helperText: 'Available after your first stay',
        enabled: false,
      ),
      _WithText(
        'BK-20417',
        (controller) => ExpressiveTextField(
          controller: controller,
          kind: ExpressiveTextFieldKind.outlined,
          label: 'Booking reference',
          readOnly: true,
        ),
      ),
    ],
  );
}

class _Areas extends StatelessWidget {
  const _Areas();

  @override
  Widget build(BuildContext context) => kitSection(
    'Text area',
    children: <Widget>[
      _WithText(
        'Arriving on the late ferry, around 22:40. Could the key be left '
        'with the café next door?',
        (controller) => ExpressiveTextArea(
          controller: controller,
          label: 'Note for the host',
          maxLength: 280,
        ),
      ),
      const ExpressiveTextArea(
        kind: ExpressiveTextFieldKind.outlined,
        rounded: true,
        label: 'What made the stay special?',
        hintText: 'The view, the breakfast, the welcome…',
        minLines: 4,
      ),
    ],
  );
}

class _Codes extends StatelessWidget {
  const _Codes();

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    return kitSection(
      'Code input',
      children: <Widget>[
        Text(
          'We sent a 6-digit code to +1 415 555 0142',
          style: TextStyle(color: t.colors.onSurfaceVariant),
        ),
        const ExpressiveInputOtp(semanticLabel: 'Verification code'),
        _WithText(
          '4081',
          (controller) => ExpressiveInputOtp(
            controller: controller,
            length: 4,
            kind: ExpressiveTextFieldKind.filled,
            rounded: true,
            obscure: true,
            semanticLabel: 'PIN',
          ),
        ),
        _WithText(
          '529',
          (controller) => ExpressiveInputOtp(
            controller: controller,
            errorText: 'That code has expired. Send a new one.',
            semanticLabel: 'Verification code',
          ),
        ),
      ],
    );
  }
}

// Catalog specimens (docs/architecture/component-catalog.md).

/// A filled field with its glyph and supporting line.
Widget kitSpecimenTextFieldFilled() => const ExpressiveTextField(
  label: 'Trip name',
  leading: Icon(ExpressiveSymbols.flight),
  helperText: 'Shown to everyone you invite',
);

/// An outlined password field with its reveal control.
Widget kitSpecimenTextFieldPassword() => const ExpressiveTextField(
  kind: ExpressiveTextFieldKind.outlined,
  label: 'Password',
  obscureText: true,
);

/// A note field three lines tall.
Widget kitSpecimenTextAreaNote() => const ExpressiveTextArea(
  label: 'Note for your host',
  helperText: 'Arrival time, dietary needs, anything else',
);

/// Six boxes for a one-time code.
Widget kitSpecimenCodeInputSix() =>
    const ExpressiveInputOtp(semanticLabel: 'Verification code');

const List<ExpressiveChosenFile> _chosen = <ExpressiveChosenFile>[
  ExpressiveChosenFile('receipt-march.pdf', detail: '240 KB'),
  ExpressiveChosenFile('taxi-airport.jpg', detail: '1.8 MB'),
];

/// File inputs: at rest with two files chosen, with a drag over it, and
/// refusing a file.
class _Files extends StatefulWidget {
  const _Files();

  @override
  State<_Files> createState() => _FilesState();
}

class _FilesState extends State<_Files> {
  List<ExpressiveChosenFile> _files = _chosen;

  @override
  Widget build(BuildContext context) => kitSection(
    'File input · chosen files, a drag over it, a refused file',
    children: <Widget>[
      ExpressiveFileUpload(
        label: 'Drop receipts here',
        supportingText: 'PDF or JPG, up to 10 MB each',
        onBrowse: () {},
        files: _files,
        onRemove: (i) => setState(
          () => _files = <ExpressiveChosenFile>[..._files]..removeAt(i),
        ),
      ),
      const SizedBox(height: kitGap * 2),
      ExpressiveFileUpload(
        label: 'Release to add 3 files',
        onBrowse: () {},
        dragging: true,
      ),
      const SizedBox(height: kitGap * 2),
      ExpressiveFileUpload(
        label: 'Drop a profile photo here',
        supportingText: 'PNG or JPG',
        onBrowse: () {},
        errorText: 'That file is a PDF; choose a PNG or JPG',
      ),
    ],
  );
}

/// A file input with two files chosen.
Widget kitSpecimenFileInputChosen() => ExpressiveFileUpload(
  label: 'Drop receipts here',
  supportingText: 'PDF or JPG, up to 10 MB each',
  onBrowse: () {},
  files: _chosen,
  onRemove: (_) {},
);

class _Password extends StatelessWidget {
  const _Password();

  @override
  Widget build(BuildContext context) => kitSection(
    'Password, input group and form field',
    children: <Widget>[
      kitSpecimenPasswordField(),
      const SizedBox(height: ExpressiveSpacing.s16),
      kitSpecimenInputGroupUrl(),
      const SizedBox(height: ExpressiveSpacing.s16),
      const _Fields(),
    ],
  );
}

class _Fields extends StatefulWidget {
  const _Fields();

  @override
  State<_Fields> createState() => _FieldsState();
}

class _FieldsState extends State<_Fields> {
  bool _notify = true;
  String _name = '';

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      ExpressiveFormField(
        label: 'Notify me',
        help: 'At most once a day',
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: ExpressiveSwitch(
            value: _notify,
            onChanged: (v) => setState(() => _notify = v),
          ),
        ),
      ),
      const SizedBox(height: ExpressiveSpacing.s16),
      ExpressiveFormField(
        label: 'Display name',
        required: true,
        error: _name.trim().isEmpty ? 'Give a name others will see' : null,
        child: ExpressiveTextField(
          kind: ExpressiveTextFieldKind.outlined,
          // A placeholder that can't pass for a typed name: "Ada" did, under
          // an error that said the field was empty.
          hintText: 'Your name',
          errorText: _name.trim().isEmpty ? '' : null,
          onChanged: (v) => setState(() => _name = v),
        ),
      ),
    ],
  );
}

/// A password field, its text hidden behind the eye.
Widget kitSpecimenPasswordField() => const ExpressivePasswordField(
  kind: ExpressiveTextFieldKind.outlined,
  label: 'Password',
  helperText: 'At least 12 characters',
);

/// A web address with its scheme before it and a copy button after.
Widget kitSpecimenInputGroupUrl() => ExpressiveInputGroup(
  hintText: 'example.com',
  semanticLabel: 'Website',
  leading: <Widget>[ExpressiveInputGroup.text('https://')],
  trailing: <Widget>[
    ExpressiveIconButton(
      ExpressiveSymbols.contentCopy,
      semanticLabel: 'Copy',
      onPressed: () {},
    ),
  ],
);

/// A switch with its label above and its help under it.
Widget kitSpecimenFormFieldNotify() => ExpressiveFormField(
  label: 'Notify me',
  help: 'At most once a day',
  child: Align(
    alignment: AlignmentDirectional.centerStart,
    child: ExpressiveSwitch(value: true, onChanged: (_) {}),
  ),
);
