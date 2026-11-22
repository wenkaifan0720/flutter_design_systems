// The heatmap's middle step by night.
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

import 'support/themed_page.dart';

void main() {
  test("the heatmap's middle step is 45% by day and 60% by night", () {
    expect(MinimalHeatmap.levelColor(dayTheme, 1).a, closeTo(0.45, 0.01));
    expect(MinimalHeatmap.levelColor(nightTheme, 1).a, closeTo(0.6, 0.01));
  });
}
