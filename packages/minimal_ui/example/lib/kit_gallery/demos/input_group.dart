/// Fields that carry more than words: add-ons before and after, a password
/// with its eye, a one-time code, and fields labelled and checked as a
/// form.
library;

import 'package:flutter/material.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

Widget kitInputGroupDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Input group & form field',
  sections: [
    kitSection(
      'Add-ons',
      children: [
        // A URL is a code: its box reads left to right on any page.
        const _Code(
          MinimalInputGroup(
            label: 'Website',
            prefixText: 'https://',
            suffixText: '.com',
            hint: 'acme',
          ),
        ),
        const MinimalInputGroup(
          label: 'Price',
          prefixText: '\$',
          suffixText: 'USD',
          mono: true,
          hint: '0.00',
          keyboardType: TextInputType.numberWithOptions(decimal: true),
        ),
        // A value the field cannot take, typed: the error says what it
        // needs. An issue id is a code, so it reads left to right too.
        _Filled(
          text: 'HAB-',
          builder: (c) => _Code(
            MinimalInputGroup(
              label: 'Blocked by',
              controller: c,
              leading: const MinimalIcon(
                LucideIcons.link,
                size: MinimalIconSize.i16,
              ),
              mono: true,
              hint: 'HAB-12',
              error: 'An issue ID ends in its number, like HAB-12.',
            ),
          ),
        ),
      ],
    ),
    kitSection(
      'Password',
      children: [
        // A password typed, so the eye has something to show.
        _Filled(
          text: 'correct horse battery',
          builder: (c) => MinimalPasswordField(
            label: 'Password',
            controller: c,
            newPassword: true,
          ),
        ),
      ],
    ),
    kitSection(
      'One-time code',
      children: [
        MinimalInputOtp(
          label: 'Code from your authenticator',
          groupSize: 3,
          onCompleted: (_) {},
        ),
        // The code takes no value from outside, so its error is the one an
        // empty code earns on Continue.
        const MinimalInputOtp(length: 4, error: 'Enter all four digits.'),
      ],
    ),
    kitSection('Form', children: const [_Form()]),
  ],
);

/// [field], whose value is a code (a URL, an issue id), reading left to
/// right on any page: its add-ons in their order and the typed text with
/// its signs where they were typed (`https://`, `HAB-`, never `//:https`).
/// Its label and message still stand on the page's start edge.
class _Code extends StatelessWidget {
  const _Code(this.field);

  final Widget field;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return DefaultTextStyle.merge(
      // The field's own words align by this, set as the page reads.
      textAlign: rtl ? TextAlign.right : TextAlign.left,
      child: Directionality(textDirection: TextDirection.ltr, child: field),
    );
  }
}

/// A field built over a controller already holding [text].
class _Filled extends StatefulWidget {
  const _Filled({required this.text, required this.builder});

  final String text;
  final Widget Function(TextEditingController controller) builder;

  @override
  State<_Filled> createState() => _FilledState();
}

class _FilledState extends State<_Filled> {
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

class _Form extends StatefulWidget {
  const _Form();

  @override
  State<_Form> createState() => _FormState();
}

class _FormState extends State<_Form> {
  final _name = TextEditingController();
  bool _tried = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MinimalForm(
    onSubmit: () => showMinimalSnackBar(context, 'Workspace created'),
    child: Builder(
      builder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MinimalFormField(
            label: 'Workspace name',
            help: 'Shown to everyone you invite.',
            required: true,
            error: _tried && _name.text.trim().isEmpty
                ? 'Give the workspace a name.'
                : null,
            child: MinimalTextField(
              controller: _name,
              hint: 'Acme',
              onChanged: (_) => setState(() {}),
            ),
          ),
          const MinimalGap(MinimalSpacing.s16),
          // The form's act stands at its end, as a dialog's and a sheet's
          // do (the create-habit form above puts its own there too).
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: MinimalButton(
              'Create workspace',
              onPressed: () {
                setState(() => _tried = true);
                MinimalForm.submit(context);
              },
            ),
          ),
        ],
      ),
    ),
  );
}

// --- catalog specimens -------------------------------------------------------

/// A field with text add-ons on both sides.
Widget kitSpecimenInputGroup() => const Padding(
  padding: EdgeInsets.all(MinimalSpacing.s16),
  child: MinimalInputGroup(
    label: 'Website',
    prefixText: 'https://',
    suffixText: '.com',
    hint: 'acme',
  ),
);

/// A six-digit code in two groups.
Widget kitSpecimenInputOtp() => const Center(
  child: MinimalInputOtp(label: 'Verification code', groupSize: 3),
);

/// A password with its show button.
Widget kitSpecimenPasswordField() => const Padding(
  padding: EdgeInsets.all(MinimalSpacing.s16),
  child: MinimalPasswordField(label: 'Password'),
);

/// A labelled, required field with its help line.
Widget kitSpecimenFormField() => const Padding(
  padding: EdgeInsets.all(MinimalSpacing.s16),
  child: MinimalFormField(
    label: 'Workspace name',
    help: 'Shown to everyone you invite.',
    required: true,
    child: MinimalTextField(hint: 'Acme'),
  ),
);
