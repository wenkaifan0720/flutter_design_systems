// ignore_for_file: avoid_relative_lib_imports
import 'package:flutter_test/flutter_test.dart';

import '../example/lib/kit_gallery/simmer/data.dart';

void main() {
  test(
    'a changed plan combines quantities and keeps checked items and extras',
    () {
      const dinner = 'miso-aubergine';
      final first = simmerShoppingFor([dinner, null], 2, []);
      final rice = first.singleWhere((i) => i.name == 'Short-grain rice');
      expect(rice.amount, '150 g');
      rice.bought = true;
      final extra = SimmerItem(
        'Coffee',
        '1',
        'Other',
        bought: true,
        addedByHand: true,
      );
      first.add(extra);

      final next = simmerShoppingFor([dinner, dinner], 3, first);
      final combined = next.singleWhere((i) => i.name == rice.name);
      expect(combined.amount, '450 g');
      expect(combined.bought, isTrue);
      expect(next.where((i) => i == extra), hasLength(1));
      final repeated = simmerShoppingFor([dinner, dinner], 3, next);
      expect(repeated.length, next.length);
      expect(repeated.singleWhere((i) => i.name == rice.name).amount, '450 g');
      expect(simmerShoppingFor([null], 2, repeated), [extra]);
    },
  );
}
