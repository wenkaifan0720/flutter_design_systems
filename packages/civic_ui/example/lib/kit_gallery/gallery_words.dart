import 'package:material_ui/material_ui.dart';
import 'package:civic_ui/civic_ui.dart';

/// The gallery's words, as an ordinary app gives them: ui_core's in its 30
/// languages, so a device in one of them hears the parts' shared words
/// (Back, Close, Cancel) in it, and Flutter's Material, Cupertino and
/// widgets ones (the widgets' give Arabic its direction). Civic's theme
/// gives its own parts their Material and Cupertino words itself.
const List<LocalizationsDelegate<Object?>> galleryDelegates = [
  RawWidgetsLocalizations.delegate,
  ...GlobalMaterialLocalizations.delegates,
];
