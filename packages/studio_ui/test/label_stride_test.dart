// Crowded labels thin evenly and reach as far as their number allows: a
// week with room for two keeps Mon and Sun, never Mon and Sat (a stride of
// five), and a scale with room for two keeps 0 and its top.
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_ui/src/studio/internal/label_stride.dart';

void main() {
  // The stride for a week of seven labels with room for every [room]th.
  int? week(int room) => studioLabelStride(7, (every) => every >= room);

  test('every label, every other or every third, as room allows', () {
    expect(week(1), 1); // Mon to Sun
    expect(week(2), 2); // Mon, Wed, Fri, Sun
    expect(week(3), 3); // Mon, Thu, Sun
  });

  test('two that fit are the first and the last', () {
    expect(week(4), 6); // Mon and Sun, not Mon and Fri
    expect(week(5), 6); // Mon and Sun, not Mon and Sat
    expect(week(6), 6);
    // A scale of 0 to 5 with room for two: 0 and 5.
    expect(studioLabelStride(6, (every) => every >= 3), 5);
  });

  test('a wider stride with no room is passed over', () {
    // Room at four and five, not at six (an end label too wide).
    expect(studioLabelStride(7, (every) => every == 4 || every == 5), 5);
  });

  test('one alone, or none', () {
    expect(week(7), 7);
    expect(studioLabelStride(7, (_) => false), isNull);
    expect(studioLabelStride(1, (_) => true), 1);
  });
}
