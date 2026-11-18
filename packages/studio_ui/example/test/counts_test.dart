// Roomtone's counts are real plurals through its localizations
// (RoomtoneWords), never a number glued to a noun.
import 'package:flutter_test/flutter_test.dart';

import 'package:studio_ui_example/kit_gallery/roomtone/words.dart';

void main() {
  test('Roomtone counts one, then many', () {
    const words = RoomtoneWordsEn();
    expect(words.episodes(1), '1 episode');
    expect(words.episodes(2), '2 episodes');
    expect(words.shows(1), '1 show');
    expect(words.shows(2), '2 shows');
    expect(words.minutes(1), '1 min');
    expect(words.timeLeft(1), '1 min left');
    expect(words.timeLeft(64), '1 h 4 min left');
  });
}
