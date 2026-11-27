/// Studio: an app as a well-made piece of studio equipment. Brushed anodised
/// panels with machined edges, recessed glass displays, backlit keys with an
/// indicator light, faders, knobs, toggles and segment meters, under one
/// light from the top, by day in a bright room and by night in low light.
///
/// Install [StudioTheme] once in an app's `builder:` (or [StudioHost],
/// which adds the toasts and the chassis); give the app's own `ThemeData`
/// [studioPageTransitions], or route its pages with [StudioPage] and
/// [StudioSheetPage].
library;

// The glyphs Studio draws with, so an app's own glyphs match them.
export 'package:lucide_icons_flutter/lucide_icons.dart' show LucideIcons;

export 'studio/actions.dart';
export 'studio/app.dart';
export 'studio/button.dart';
export 'studio/charts.dart';
export 'studio/choices.dart';
export 'studio/collections.dart';
export 'studio/controls.dart';
export 'studio/display.dart';
export 'studio/entry.dart';
export 'studio/feedback.dart';
export 'studio/fonts.dart';
export 'studio/form.dart';
export 'studio/lists.dart';
export 'studio/menu.dart';
export 'studio/navigation.dart';
export 'studio/overlays.dart';
export 'studio/panel.dart';
export 'studio/pickers.dart';
export 'studio/popovers.dart';
export 'studio/select.dart';
export 'studio/surface.dart';
export 'studio/text_field.dart';
export 'studio/theme.dart';
export 'studio/transitions.dart';
export 'studio/wayfinding.dart';
export 'studio/words.dart';
