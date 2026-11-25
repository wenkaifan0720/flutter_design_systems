// RawTapTargetScope's runtime name, which a tool that reads a widget tree by
// type name looks a scope up by.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

void main() {
  test("the scope's runtime name is the one a tool looks up", () {
    const scope = RawTapTargetScope(
      targets: RawTapTargets.fallback,
      child: SizedBox(),
    );
    expect(scope.runtimeType.toString(), 'RawTapTargetScope');
  });
}
