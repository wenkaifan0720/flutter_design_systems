/// Expressive's formatting: the design kit's formatters — money, counts,
/// dates, clock times, the relative day — under the system's name, so page
/// code reads `ExpressiveFormat.money(…)` (wave decision D4).
///
/// The behaviour is the kit's alone (`package:initial_gen_app/design_kit/
/// format.dart`): the daylight-saving-correct day arithmetic, and a clock
/// that follows the platform's 24-hour setting. A system never forks it.
library;

import 'package:ui_core/host.dart';

export 'package:ui_core/host.dart' show DisplayFormat;

/// Expressive's formatters: the design kit's [DisplayFormat], named for the
/// system.
typedef ExpressiveFormat = DisplayFormat;
