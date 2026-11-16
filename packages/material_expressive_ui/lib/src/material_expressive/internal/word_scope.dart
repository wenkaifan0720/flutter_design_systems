/// Where the package's primitives find the Material and Cupertino words they
/// read when the app supplies none: under [withPlatformWords], which the
/// theme mounts, a theme carried into an overlay mounts again, and a field's
/// context menu mounts for itself ([expressiveContextMenu]).
library;

import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoLocalizations;
import 'package:material_ui/material_ui.dart'
    show AdaptiveTextSelectionToolbar, MaterialLocalizations;
import 'package:flutter/widgets.dart';

import 'platform_words.dart';

/// [child] with the Material and Cupertino words the package's primitives
/// read, when the app supplies none.
///
/// The primitives use material_ui and cupertino_ui, whose localization
/// types are distinct from a Flutter app's: a MaterialApp's words
/// (flutter_localizations' included) are not theirs, a WidgetsApp has none,
/// and their own delegates load English only. A field's context menu reads
/// Material's words, or Cupertino's on iOS and macOS, and threw without them
/// in any other language. Keep the app's locale, delegates and direction,
/// supplying only the missing words ([expressiveMaterialWords],
/// [expressiveCupertinoWords]); an existing translation always wins.
///
/// In an overlay ([overlay], what a captured theme wraps) the child may be
/// one of the overlay's positioned children (a text magnifier is), which
/// must sit directly in a stack: Localizations adds a render object, so the
/// child gets a pass-through stack of its own under it.
Widget withPlatformWords(
  BuildContext context,
  Widget child, {
  bool overlay = false,
}) {
  final missing = <LocalizationsDelegate<Object?>>[
    if (Localizations.of<MaterialLocalizations>(
          context,
          MaterialLocalizations,
        ) ==
        null)
      expressiveMaterialWords,
    if (Localizations.of<CupertinoLocalizations>(
          context,
          CupertinoLocalizations,
        ) ==
        null)
      expressiveCupertinoWords,
  ];
  if (missing.isEmpty) return child;
  final placed = overlay
      ? Stack(
          fit: StackFit.passthrough,
          clipBehavior: Clip.none,
          children: <Widget>[child],
        )
      : child;
  final direction = Directionality.maybeOf(context);
  final localizedChild = direction == null
      ? placed
      : Directionality(textDirection: direction, child: placed);
  final locale = Localizations.maybeLocaleOf(context);
  if (locale == null) {
    return Localizations(
      locale: const Locale('en'),
      delegates: [...missing, DefaultWidgetsLocalizations.delegate],
      child: localizedChild,
    );
  }
  return Localizations.override(
    context: context,
    delegates: missing,
    child: localizedChild,
  );
}

/// A field's context menu: Material's default (the platform's own menu
/// where the field supports it, else the adaptive toolbar), under the words
/// it reads.
///
/// The menu stands in the root overlay and captures its themes from there,
/// so it never sees an `ExpressiveTheme` mounted under the app's `home`, nor
/// the words that theme supplies: it supplies them itself.
Widget expressiveContextMenu(
  BuildContext context,
  EditableTextState editableTextState,
) {
  if (SystemContextMenu.isSupportedByField(editableTextState)) {
    return SystemContextMenu.editableText(editableTextState: editableTextState);
  }
  return withPlatformWords(
    context,
    AdaptiveTextSelectionToolbar.editableText(
      editableTextState: editableTextState,
    ),
  );
}
