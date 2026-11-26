/// Where an item stands among others, in the page's language.
library;

import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

/// "[noun] [position] of [count]" in English ("Page 2 of 9"), as Ledger's
/// source words it; in another language, ui_core's position words for it
/// alone ("2 من 9" in Arabic), which name no noun.
String ledgerPosition(
  BuildContext context,
  String noun,
  int position,
  int count,
) {
  final words = RawWidgetsLocalizations.of(context)
      .positionLabel(position, count);
  // ui_core's English ("2 of 9") takes the source's noun before it.
  return words == '$position of $count' ? '$noun $words' : words;
}
