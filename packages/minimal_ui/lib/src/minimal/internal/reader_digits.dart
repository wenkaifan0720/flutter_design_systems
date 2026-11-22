import 'package:flutter/widgets.dart';

import '../localizations.dart';

/// [text] with its ASCII digits written in the reader's
/// ([MinimalLocalizations.digits]: Arabic's ٤٥ for 45), every other
/// character as it is.
String minimalReaderDigits(BuildContext context, String text) {
  final words = MinimalLocalizations.of(context);
  return [
    for (final c in text.codeUnits)
      c >= 0x30 && c <= 0x39 ? words.digits(c - 0x30) : String.fromCharCode(c),
  ].join();
}
