/// The counted words Terminal's own parts say, beyond ui_core's
/// [DesignLocalizations]: what a screen reader hears for a group of people.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

/// The words Terminal's parts count in: each takes its count whole, so a
/// language words its own plural forms (one, few, many, …) rather than
/// having a word added to a number.
///
/// [of] reads the nearest [Localizations]' instance, and English
/// ([DefaultTermLocalizations]) when there is none, so nothing needs setting
/// up. An app in another language extends [DefaultTermLocalizations],
/// overriding the words it says, and adds a delegate for its subclass to its
/// `localizationsDelegates`, as it does for [DesignLocalizations].
///
/// ```dart
/// Text(TermLocalizations.of(context).avatarGroupLabel(const ['Ada Lovelace', 'Alan Turing']))
/// ```
abstract class TermLocalizations {
  /// Abstract const constructor, for subclasses.
  const TermLocalizations();

  /// The words for [context]'s locale: the nearest [Localizations]'
  /// [TermLocalizations], else English.
  static TermLocalizations of(BuildContext context) =>
      Localizations.of<TermLocalizations>(context, TermLocalizations) ??
      const DefaultTermLocalizations();

  /// What a screen reader hears for a `TermAvatarGroup` of [names]: how many
  /// people, then who ("2 people: Ada Lovelace, Alan Turing").
  String avatarGroupLabel(List<String> names);
}

/// The words in English, with no localizations package.
///
/// ```dart
/// const DefaultTermLocalizations().avatarGroupLabel(const ['Ada Lovelace'])
/// ```
class DefaultTermLocalizations implements TermLocalizations {
  /// English, the words [TermLocalizations.of] falls back to.
  const DefaultTermLocalizations();

  /// Makes the English words: what [delegate] loads for any locale.
  static Future<TermLocalizations> load(Locale locale) =>
      SynchronousFuture<TermLocalizations>(const DefaultTermLocalizations());

  /// A delegate that loads English for every locale, for an app's
  /// `localizationsDelegates`.
  static const LocalizationsDelegate<TermLocalizations> delegate =
      _DefaultTermLocalizationsDelegate();

  @override
  String avatarGroupLabel(List<String> names) {
    final count = names.length;
    return '${count == 1 ? '1 person' : '$count people'}: ${names.join(', ')}';
  }
}

class _DefaultTermLocalizationsDelegate
    extends LocalizationsDelegate<TermLocalizations> {
  const _DefaultTermLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<TermLocalizations> load(Locale locale) =>
      DefaultTermLocalizations.load(locale);

  @override
  bool shouldReload(_DefaultTermLocalizationsDelegate old) => false;

  @override
  String toString() => 'DefaultTermLocalizations.delegate(en)';
}
