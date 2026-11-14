import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

/// The [ExpressivePressable] nearest above [finder]: what a finger lands on.
///
/// A pressable draws its ink over its content (Compose's indication sits
/// over the content too), so its label, icon or handle never takes the hit
/// itself; with hit-test warnings fatal (flutter_test_config.dart) a test
/// taps the pressable, found from the content it shows.
Finder pressableOf(Finder finder) =>
    find.ancestor(of: finder, matching: find.byType(ExpressivePressable)).first;
