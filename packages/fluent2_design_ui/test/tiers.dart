// The tiers of Fluent 2's tests. The everyday run, `flutter test --exclude-tags goldens,sweep`, keeps a representative
// of every matrix: each part and page at least once, the values of each axis (width, preset, setting, light and dark,
// text scale, platform) turning over the cases, so a fault class is still caught on every run. The rest of each matrix
// is tagged `sweep`: `flutter test --tags sweep` runs it, and a full run (`flutter test`, at READY and release) runs
// every tier.
import 'package:flutter/foundation.dart';

/// The tag of a case only the full run takes.
const sweep = 'sweep';

/// The tags of one case of a matrix: none when [everyday], so every run has it, else [sweep].
List<String>? sweepUnless(bool everyday) => everyday ? null : const [sweep];

/// The everyday platform for a check at [width]: a phone's touch below 840, a desk's pointer from it.
TargetPlatform platformAt(double width) =>
    width < 840 ? TargetPlatform.android : TargetPlatform.macOS;
