// The tiers of Comic's tests. The everyday run, `flutter test --exclude-tags goldens,sweep`, keeps a representative of
// every matrix: each part, page and value of each axis at least once, the axes' values rotating over the cases, so a
// fault class is still caught on every run. The rest of each matrix is tagged `sweep`; `flutter test --tags sweep` runs
// it, and a full run (`flutter test`, at READY and release) runs every tier.
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// The tag of a case only the full sweep runs.
const sweep = 'sweep';

/// The tags of one case of a matrix: none when [everyday], so every run has it, else [sweep].
List<String>? sweepUnless(bool everyday) => everyday ? null : const [sweep];

/// The platforms every run checks a part on: a phone's touch and a desk's pointer.
const everydayPlatforms = {TargetPlatform.android, TargetPlatform.macOS};

/// [body] as a test on each platform of [across] (every platform unless given): on [everyday] each run, on the
/// rest in the sweep.
void testWidgetsOnEveryPlatform(
  String description,
  WidgetTesterCallback body, {
  Set<TargetPlatform> everyday = everydayPlatforms,
  Set<TargetPlatform>? across,
}) {
  final platforms = across ?? TargetPlatform.values.toSet();
  assert(platforms.containsAll(everyday));
  if (everyday.isNotEmpty) {
    testWidgets(description, body, variant: TargetPlatformVariant(everyday));
  }
  final rest = platforms.difference(everyday);
  if (rest.isNotEmpty) {
    testWidgets(
      description,
      body,
      variant: TargetPlatformVariant(rest),
      tags: const [sweep],
    );
  }
}

/// The everyday platform for a check at [width]: a phone's touch below 840, a desk's pointer from it.
TargetPlatform platformAt(double width) =>
    width < 840 ? TargetPlatform.android : TargetPlatform.macOS;
