/// A part's words where the app leaves Terminal's English default: the
/// reader's, from [TermLocalizations].
library;

import 'package:flutter/widgets.dart';

import '../localizations.dart';

/// [given], or, when it is Terminal's English default [english], the
/// reader's words for it ([words] of [TermLocalizations.of]).
String termWords(
  BuildContext context,
  String given,
  String english,
  String Function(TermLocalizations words) words,
) => given == english ? words(TermLocalizations.of(context)) : given;
