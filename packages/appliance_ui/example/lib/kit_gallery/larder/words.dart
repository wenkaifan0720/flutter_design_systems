/// Larder's counted words: how many things an order holds, a search found or
/// the shelf shows. Each takes its number whole, so a language words its own
/// plural forms rather than having a word added to a number.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// The words Larder counts in, for [context]'s locale through [of].
///
/// Larder speaks English ([DefaultLarderWords], which [of] falls back to).
/// Another language extends [DefaultLarderWords], overriding the words it
/// says, and adds a delegate for its subclass beside [delegate].
abstract class LarderWords {
  /// Abstract const constructor, for subclasses.
  const LarderWords();

  /// The nearest [Localizations]' words, else English.
  static LarderWords of(BuildContext context) =>
      Localizations.of<LarderWords>(context, LarderWords) ??
      const DefaultLarderWords();

  /// Loads English for every locale: Larder's `localizationsDelegates`.
  static const LocalizationsDelegate<LarderWords> delegate =
      _DefaultLarderWordsDelegate();

  /// [count] things: what an order holds, what the shelf shows.
  String things(int count);

  /// What a search for [query] found: [count] things.
  String searchFound(int count, String query);
}

/// Larder's words in English.
class DefaultLarderWords extends LarderWords {
  /// English, the words [LarderWords.of] falls back to.
  const DefaultLarderWords();

  @override
  String things(int count) => count == 1 ? '1 thing' : '$count things';

  @override
  String searchFound(int count, String query) =>
      '${things(count)} for “$query”';
}

class _DefaultLarderWordsDelegate extends LocalizationsDelegate<LarderWords> {
  const _DefaultLarderWordsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<LarderWords> load(Locale locale) =>
      SynchronousFuture<LarderWords>(const DefaultLarderWords());

  @override
  bool shouldReload(_DefaultLarderWordsDelegate old) => false;
}
