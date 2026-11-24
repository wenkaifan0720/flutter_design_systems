// RawTapTargetScope's runtime name (0.6.0), which drip's kit harness looks a
// scope up by.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

void main() {
  test("the scope's runtime name is the one drip's kit harness looks up", () {
    const scope = RawTapTargetScope(
      targets: RawTapTargets.fallback,
      child: SizedBox(),
    );
    expect(scope.runtimeType.toString(), 'RawTapTargetScope');
  });
}
