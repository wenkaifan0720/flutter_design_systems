/// What the behaviours tell a screen reader, where the platform takes
/// announcements. Inside ui_core; not exported.
library;

import 'dart:async';

import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';

/// Tells a screen reader [message] (a highlighted option, a form's problems), when the
/// platform takes announcements.
void designAnnounce(BuildContext context, String message) {
  if (!(MediaQuery.maybeSupportsAnnounceOf(context) ?? false)) return;
  unawaited(
    SemanticsService.sendAnnouncement(
      View.of(context),
      message,
      Directionality.maybeOf(context) ?? TextDirection.ltr,
    ),
  );
}
