// `flutter test --exclude-tags goldens,sweep` exercises every component and page
// with a representative set of widths, presets, settings and platforms.
// `flutter test --tags sweep` covers the remaining combinations.
import 'package:flutter/foundation.dart';

/// The tag of a case only the full run takes.
const sweep = 'sweep';

/// The tags of one case of a matrix: none when [everyday], so every run has it, else [sweep].
List<String>? sweepUnless(bool everyday) => everyday ? null : const [sweep];

/// The everyday platform for a check at [width]: a phone's touch below 840, a desk's pointer from it.
TargetPlatform platformAt(double width) =>
    width < 840 ? TargetPlatform.android : TargetPlatform.macOS;
