// What 0.2.0 deprecates with a mechanical fix, before `dart fix --apply` (comic.dart.expect is after).
import 'package:comic_ui/comic_ui.dart';

void main() {
  const face = ComicTypeface(scale: 1.1);
  const own = ComicTypeface.app(
    display: 'Brand',
    text: 'Brand Text',
    scale: 1.2,
  );
  final smaller = ComicTypeface.look.copyWith(
    display: 'ShantellSans',
    scale: .9,
  );
  print([face, own, smaller]);
}
