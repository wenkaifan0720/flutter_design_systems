/// More fields: `TermPasswordField`, `TermOtpField`, `TermNumberField`,
/// `TermCombobox`, `TermTagInput`, add-ons and a text area on
/// `TermTextField`, `TermFileField`, and the marks `TermChip`, `TermTag` and
/// `TermBadge`.
library;

import 'package:flutter/widgets.dart';

import '../kit.dart';

Widget kitInputsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'inputs',
  sections: kitParts(const [
    ('a password', 'PasswordField'),
    ('a one-time code', 'InputOtp'),
    ('a number', 'NumberField'),
    ('add-ons', 'InputGroup'),
    ('a search', 'SearchField'),
    ('a text area', 'TextArea'),
    ('a combobox', 'Combobox'),
    ('tags', 'MultiSelect'),
    ('files', 'FileUpload'),
    ('chips', 'Chip'),
    ('tags on a line', 'Tag'),
    ('badges', 'Badge'),
  ]),
);
