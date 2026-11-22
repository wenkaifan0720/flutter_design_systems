// A lettering style is a value, as a TextStyle is: two built with the same
// contour and layers are equal and hash alike, and a change to either tells
// them apart.
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_ui.dart';

void main() {
  test('lettering styles with the same contour and layers are equal', () {
    // Built at run time, as an app builds one: not the same instance.
    final outline = double.parse('2.9');
    final a = ComicLetteringStyle(
      outline: outline,
      layers: [(5.5, 5.5, 1, 'line')],
    );
    final b = ComicLetteringStyle(
      outline: outline,
      layers: [(5.5, 5.5, 1, 'line')],
    );
    expect(identical(a, b), isFalse);
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a, ComicLetteringStyle.title);
    expect(
      a,
      isNot(
        ComicLetteringStyle(outline: outline, layers: [(5.5, 5.5, 1, 'drama')]),
      ),
    );
    expect(
      a,
      isNot(
        const ComicLetteringStyle(outline: 3, layers: [(5.5, 5.5, 1, 'line')]),
      ),
    );
  });
}
