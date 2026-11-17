import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:ledger_ui/ledger_ui.dart';

/// The gallery's words, as an ordinary app gives them: ui_core's in its 30
/// languages, so a device in one of them hears the parts' shared words
/// (Cancel, Close, Today) in it, and Flutter's Material, Cupertino and
/// widgets ones (the widgets' give Hebrew its direction). Ledger's theme
/// gives its own parts their Material and Cupertino words itself.
const List<LocalizationsDelegate<Object?>> galleryDelegates = [
  DesignLocalizations.delegate,
  ...GlobalMaterialLocalizations.delegates,
];
