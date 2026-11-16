import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../theme.dart';

/// How far a [CivicSectionBreak] stands from what is round it.
enum CivicSectionBreakSize {
  /// No room: a rule between rows.
  none,

  /// A little room: between parts of a section.
  medium,

  /// A section's room: between sections of a page.
  large,
}

/// A hairline rule across the column that parts what is above from what is
/// below, with [size]'s room on either side. A heading parts sections
/// better; a rule is for the page whose parts have none.
///
/// ```dart
/// const CivicSectionBreak(size: CivicSectionBreakSize.large)
/// ```
class CivicSectionBreak extends StatelessWidget {
  /// A rule.
  const CivicSectionBreak({super.key, this.size = CivicSectionBreakSize.none});

  /// The room on either side.
  final CivicSectionBreakSize size;

  @override
  Widget build(BuildContext context) {
    final room = switch (size) {
      CivicSectionBreakSize.none => 0.0,
      CivicSectionBreakSize.medium => CivicSpacing.s16,
      CivicSectionBreakSize.large => CivicSpacing.s32,
    };
    return Padding(
      padding: EdgeInsets.symmetric(vertical: room),
      child: SizedBox(
        height: _hairline,
        width: double.infinity,
        child: ColoredBox(color: context.civicTheme.rule),
      ),
    );
  }

  static const double _hairline = 1;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      EnumProperty<CivicSectionBreakSize>(
        'size',
        size,
        defaultValue: CivicSectionBreakSize.none,
      ),
    );
  }
}
