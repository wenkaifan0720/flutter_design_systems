part of '../stint_minimal.dart';

final _stintControls = [
  for (final language in [StintLanguage.ar, StintLanguage.ja, StintLanguage.de])
    MinimalLocalizations.delegateOf(
      _StintControls(
        RawWidgetsLocalizations.forLocale(language.locale),
        StintWords(language),
      ),
      isSupported: (locale) => locale.languageCode == language.name,
    ),
];

// Minimal's own words are English in every locale; the words every look
// shares (the time columns, AM and PM, months, weekdays, digits) come from
// ui_core's translations, and Stint's from its own.
class _StintControls extends MinimalLocalizationsEn {
  _StintControls(super.shared, this.words);
  final StintWords words;

  @override
  String get done => shared.doneButtonLabel;
  @override
  List<String> get weekdays => words.weekdayNames;
  @override
  String relativeDay(int days) => words.relativeDay(days);
  @override
  String decrease(String name) => words.adjust(name, increase: false);
  @override
  String increase(String name) => words.adjust(name, increase: true);
  @override
  String clear(String? name) => [shared.clearButtonTooltip, ?name].join(' ');
  @override
  String nothingMatches(String query) => switch (words.language) {
    StintLanguage.ja => '${shared.noResultsLabel}「$query」',
    StintLanguage.de => '${shared.noResultsLabel}: „$query“',
    _ => '${shared.noResultsLabel} «$query»',
  };
}
