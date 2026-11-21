// A part built with a number outside the range it draws says so as it is
// built (a debug build's assert), rather than drawing nonsense.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

// A value the compiler can't fold, so each part is built at run time.
T _<T>(T value) => value;

Widget _app(Widget part) => Directionality(
  textDirection: TextDirection.ltr,
  child: MinimalTheme(
    data: MinimalThemeData.standard(),
    child: Center(child: SizedBox(width: 320, child: part)),
  ),
);

void main() {
  test('a constructor refuses a number out of its range', () {
    final cases = <String, Object Function()>{
      'pagination page past the last': () =>
          MinimalPagination(page: _(3), pageCount: 3),
      'pagination page below 0': () =>
          MinimalPagination(page: _(-1), pageCount: 3),
      'pagination without pages': () =>
          MinimalPagination(page: 0, pageCount: _(0)),
      'page dots past the last': () =>
          MinimalPageDots(count: 4, selectedIndex: _(4)),
      'page dots without pages': () =>
          MinimalPageDots(count: _(0), selectedIndex: 0),
      'rating above max': () => MinimalRating(value: _(6.0)),
      'rating below 0': () => MinimalRating(value: _(-1.0)),
      'rating without stars': () => MinimalRating(value: 0, max: _(0)),
      'slider value past max': () =>
          MinimalSlider(label: 'Volume', value: _(2.0)),
      'range slider min not below max': () => MinimalRangeSlider(
        label: 'Price',
        values: const RawRangeValues(0, 0),
        max: _(0.0),
      ),
      'range slider without divisions': () => MinimalRangeSlider(
        label: 'Price',
        values: const RawRangeValues(0, 1),
        divisions: _(0),
      ),
      'number field value past max': () =>
          MinimalNumberField(label: 'Guests', value: _(9), min: 1, max: 8),
      'code without boxes': () => MinimalInputOtp(length: _(0)),
      'meter warning past 1': () =>
          MinimalMeter(label: 'Storage', value: 1, warningAt: _(1.5)),
      'ring without a size': () => MinimalCircularProgressIndicator(size: _(0)),
      'bar without a height': () =>
          MinimalLinearProgressIndicator(label: 'Upload', height: _(0)),
    };
    for (final MapEntry(key: name, value: build) in cases.entries) {
      expect(build, throwsAssertionError, reason: name);
    }
  });

  testWidgets('a part reading a list refuses an index out of it', (
    tester,
  ) async {
    final cases = <String, Widget>{
      'step progress past all done': MinimalStepProgress(
        steps: const ['Account', 'Plan'],
        current: _(3),
      ),
      'step progress without steps': MinimalStepProgress(
        steps: _(const <String>[]),
        current: 0,
      ),
      'heatmap today past the last day': MinimalHeatmap(
        levels: const [0, 1, 2],
        today: _(3),
      ),
      'heatmap level above 2': MinimalHeatmap(levels: _(const [0, 3])),
      'range slider values past max': MinimalRangeSlider(
        label: 'Price',
        values: _(const RawRangeValues(0.2, 1.5)),
      ),
    };
    for (final MapEntry(key: name, value: part) in cases.entries) {
      await tester.pumpWidget(_app(part));
      expect(tester.takeException(), isA<AssertionError>(), reason: name);
    }
  });

  testWidgets('the ends of each range build', (tester) async {
    for (final part in <Widget>[
      MinimalPagination(page: _(2), pageCount: 3),
      MinimalPageDots(count: 4, selectedIndex: _(3)),
      MinimalRating(value: _(5.0)),
      MinimalRating(value: _(0.0)),
      MinimalStepProgress(steps: const ['Account', 'Plan'], current: _(2)),
      MinimalHeatmap(levels: const [0, 1, 2], today: _(2)),
      MinimalRangeSlider(label: 'Price', values: _(const RawRangeValues(0, 1))),
      MinimalMeter(label: 'Storage', value: _(12.0), max: 10, warningAt: 1),
    ]) {
      await tester.pumpWidget(_app(part));
      expect(tester.takeException(), isNull, reason: '$part');
    }
  });
}
