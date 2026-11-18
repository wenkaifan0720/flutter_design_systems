// Roomtone's counted words. Every count a person reads or hears is a real
// plural, worded through the app's localizations, never a number glued to a
// noun.
import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'package:flutter/widgets.dart';

/// Roomtone's counts. English ships ([RoomtoneWordsEn]); another language
/// extends it with its own plural forms and adds a delegate that loads it.
abstract class RoomtoneWords {
  /// Const constructor, for subclasses.
  const RoomtoneWords();

  /// The words in force at [context], else English.
  static RoomtoneWords of(BuildContext context) =>
      Localizations.of<RoomtoneWords>(context, RoomtoneWords) ??
      const RoomtoneWordsEn();

  /// Loads the English words for any locale.
  static const LocalizationsDelegate<RoomtoneWords> delegate =
      _RoomtoneWordsDelegate();

  /// "1 episode", "12 episodes".
  String episodes(int count);

  /// "1 show", "3 shows".
  String shows(int count);

  /// An episode's length: "1 min", "64 min".
  String minutes(int count);

  /// What is left of an episode: "1 min left", "1 h 4 min left".
  String timeLeft(int minutes);
}

/// Roomtone's words in English.
class RoomtoneWordsEn extends RoomtoneWords {
  /// English.
  const RoomtoneWordsEn();

  @override
  String episodes(int count) => count == 1 ? '1 episode' : '$count episodes';

  @override
  String shows(int count) => count == 1 ? '1 show' : '$count shows';

  // The abbreviation is the same for one and for many in English.
  @override
  String minutes(int count) => '$count min';

  @override
  String timeLeft(int minutes) => minutes >= 60
      ? '${minutes ~/ 60} h ${minutes % 60} min left'
      : '$minutes min left';
}

class _RoomtoneWordsDelegate extends LocalizationsDelegate<RoomtoneWords> {
  const _RoomtoneWordsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<RoomtoneWords> load(Locale locale) =>
      SynchronousFuture<RoomtoneWords>(const RoomtoneWordsEn());

  @override
  bool shouldReload(_RoomtoneWordsDelegate old) => false;
}
