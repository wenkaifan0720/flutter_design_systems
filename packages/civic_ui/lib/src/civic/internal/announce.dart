import 'dart:async';

import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';

/// Tells a screen reader [message] (a page's problems, a status), where the
/// platform takes announcements; elsewhere the part that calls it is a
/// live region.
void civicAnnounce(BuildContext context, String message) {
  if (!(MediaQuery.maybeSupportsAnnounceOf(context) ?? false)) return;
  unawaited(
    SemanticsService.sendAnnouncement(
      View.of(context),
      message,
      Directionality.maybeOf(context) ?? TextDirection.ltr,
    ),
  );
}
