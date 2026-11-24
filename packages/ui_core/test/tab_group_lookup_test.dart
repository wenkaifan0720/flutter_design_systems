// RawTabGroup.maybeOf (0.6.0): a look's own part under a tab group reads
// it, by its exact value type, and is built again when the group's value,
// its handler, its orientation or its activation changes.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

var _builds = 0;
RawTabGroup<String>? _found;

class _Reader extends StatelessWidget {
  const _Reader();

  @override
  Widget build(BuildContext context) {
    _builds++;
    _found = RawTabGroup.maybeOf<String>(context);
    return const SizedBox();
  }
}

Widget _group({
  String? value = 'overview',
  Axis orientation = Axis.horizontal,
  bool selectionFollowsFocus = true,
  ValueChanged<String>? onChanged,
}) => Directionality(
  textDirection: TextDirection.ltr,
  child: RawTabGroup<String>(
    groupValue: value,
    orientation: orientation,
    selectionFollowsFocus: selectionFollowsFocus,
    onChanged: onChanged,
    child: const _Reader(),
  ),
);

void _changed(String value) {}

void main() {
  setUp(() {
    _builds = 0;
    _found = null;
  });

  testWidgets('it finds the group above, null outside one', (tester) async {
    await tester.pumpWidget(_group());
    expect(_found?.groupValue, 'overview');
    expect(_found?.orientation, Axis.horizontal);
    await tester.pumpWidget(const _Reader());
    expect(_found, isNull);
  });

  testWidgets('it finds a group by its exact value type', (tester) async {
    int? number;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: RawTabGroup<String>(
          groupValue: 'overview',
          child: Builder(
            builder: (context) {
              number = RawTabGroup.maybeOf<int>(context)?.groupValue;
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    expect(number, isNull);
  });

  testWidgets('a reader is built again as the group changes, not otherwise', (
    tester,
  ) async {
    await tester.pumpWidget(_group());
    expect(_builds, 1);
    await tester.pumpWidget(_group());
    expect(_builds, 1);
    await tester.pumpWidget(_group(value: 'reviews'));
    expect((_builds, _found?.groupValue), (2, 'reviews'));
    await tester.pumpWidget(
      _group(value: 'reviews', orientation: Axis.vertical),
    );
    expect((_builds, _found?.orientation), (3, Axis.vertical));
    await tester.pumpWidget(
      _group(
        value: 'reviews',
        orientation: Axis.vertical,
        selectionFollowsFocus: false,
      ),
    );
    expect((_builds, _found?.selectionFollowsFocus), (4, false));
    await tester.pumpWidget(
      _group(
        value: 'reviews',
        orientation: Axis.vertical,
        selectionFollowsFocus: false,
        onChanged: _changed,
      ),
    );
    expect((_builds, _found?.onChanged), (5, _changed));
  });
}
