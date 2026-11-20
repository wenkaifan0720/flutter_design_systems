// Clay: counted words. A count a person reads or hears ("1 habit",
// "3 habits") takes its noun's form for that count in the reader's
// language, by CLDR's plural rules: never "$n things" by concatenation.

import 'package:flutter/widgets.dart';

/// The plural categories of CLDR: which form of a counted phrase a language
/// uses for a count. English has [one] and [other]; Arabic has all six.
enum ClayPluralCategory {
  /// Arabic's 0.
  zero,

  /// The singular: 1 in English; 0 and 1 in French and Hindi; 1, 21, 31 in
  /// Russian.
  one,

  /// The dual: Arabic's and Hebrew's 2.
  two,

  /// A paucal: Czech, Polish, Russian and Ukrainian 2-4, Romanian 0 and
  /// 2-19, Arabic 3-10.
  few,

  /// Polish, Russian and Ukrainian 5-20, Arabic 11-99.
  many,

  /// Every other count, and every count in a language without plurals
  /// (Japanese, Korean, Chinese, Thai, Vietnamese, Indonesian, Malay).
  other,
}

/// The category whole number [count] falls in for [locale]'s language: the
/// rules of the 30 languages ui_core speaks; any other language counts as
/// English does.
///
/// ```dart
/// clayPluralCategory(const Locale('pl'), 3)
/// ```
ClayPluralCategory clayPluralCategory(Locale locale, int count) {
  final i = count.abs();
  final i10 = i % 10;
  final i100 = i % 100;
  final fewSlavic = i10 >= 2 && i10 <= 4 && (i100 < 12 || i100 > 14);
  const one = ClayPluralCategory.one;
  const few = ClayPluralCategory.few;
  const many = ClayPluralCategory.many;
  const other = ClayPluralCategory.other;
  return switch (locale.languageCode) {
    'ja' || 'ko' || 'zh' || 'th' || 'vi' || 'id' || 'in' || 'ms' => other,
    'bn' || 'fa' || 'hi' || 'fr' || 'pt' => i <= 1 ? one : other,
    'cs' || 'sk' =>
      i == 1
          ? one
          : i >= 2 && i <= 4
          ? few
          : other,
    'pl' =>
      i == 1
          ? one
          : fewSlavic
          ? few
          : many,
    'ru' || 'uk' || 'be' =>
      i10 == 1 && i100 != 11
          ? one
          : fewSlavic
          ? few
          : many,
    'ro' =>
      i == 1
          ? one
          : i == 0 || (i100 >= 1 && i100 <= 19)
          ? few
          : other,
    'he' || 'iw' =>
      i == 1
          ? one
          : i == 2
          ? ClayPluralCategory.two
          : other,
    'fil' || 'tl' => i10 != 4 && i10 != 6 && i10 != 9 ? one : other,
    'ar' =>
      i == 0
          ? ClayPluralCategory.zero
          : i == 1
          ? one
          : i == 2
          ? ClayPluralCategory.two
          : i100 >= 3 && i100 <= 10
          ? few
          : i100 >= 11
          ? many
          : other,
    _ => i == 1 ? one : other,
  };
}

/// The form of a counted phrase for [count] in [context]'s language (its
/// [Localizations] locale, else English): [one] and [other] at least, and
/// [zero], [two], [few] and [many] for the languages that have them. A form
/// the language uses but the caller left out falls back to [other].
///
/// ```dart
/// clayPlural(context, 3, one: '1 habit', other: '3 habits')
/// ```
String clayPlural(
  BuildContext context,
  int count, {
  String? zero,
  required String one,
  String? two,
  String? few,
  String? many,
  required String other,
}) {
  final locale = Localizations.maybeLocaleOf(context) ?? const Locale('en');
  return switch (clayPluralCategory(locale, count)) {
        ClayPluralCategory.zero => zero,
        ClayPluralCategory.one => one,
        ClayPluralCategory.two => two,
        ClayPluralCategory.few => few,
        ClayPluralCategory.many => many,
        ClayPluralCategory.other => other,
      } ??
      other;
}
