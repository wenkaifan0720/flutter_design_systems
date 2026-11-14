/// Material 3 Expressive for Flutter: Material's newest look, ported from
/// Jetpack Compose's material3 1.5.0-alpha29 (its tokens, motion springs,
/// shape library and components). The one import an app needs.
///
/// It exports the theme ([ExpressiveTheme], [ExpressiveThemeData]), one
/// library per foundation (colour, type, shape, motion, spacing, icons,
/// elevation, interaction states) and every component.
///
/// The parts library (`material_expressive_parts.dart`), for a component
/// file copied out of the package to change, also exports what the
/// components are built from, among it the generated token classes. Those
/// keep Compose's names (`ButtonSmallTokens`, `AlertDialogBehavior`, …):
/// they are generated from Compose's source, the docs cite them by those
/// names, and a value checked against Compose is found by the same name
/// there.
library;

export 'material_expressive/color.dart';
export 'material_expressive/component_themes.dart';
export 'material_expressive/components/app_bar.dart';
export 'material_expressive/components/badge.dart';
export 'material_expressive/components/buttons.dart';
export 'material_expressive/components/cards.dart';
export 'material_expressive/components/carousel.dart';
export 'material_expressive/components/chart.dart';
export 'material_expressive/components/chips.dart';
export 'material_expressive/components/choice.dart';
export 'material_expressive/components/color_picker.dart';
export 'material_expressive/components/content.dart';
export 'material_expressive/components/data_table.dart';
export 'material_expressive/components/display.dart';
export 'material_expressive/components/fab.dart';
export 'material_expressive/components/feedback.dart';
export 'material_expressive/components/file_input.dart';
export 'material_expressive/components/form.dart';
export 'material_expressive/components/hero.dart';
export 'material_expressive/components/icon_buttons.dart';
export 'material_expressive/components/lists.dart';
export 'material_expressive/components/loading.dart';
export 'material_expressive/components/media.dart';
export 'material_expressive/components/menus.dart';
export 'material_expressive/components/nav.dart';
export 'material_expressive/components/overlays.dart';
export 'material_expressive/components/panes.dart';
export 'material_expressive/components/pickers.dart';
export 'material_expressive/components/progress.dart';
export 'material_expressive/components/screen.dart';
export 'material_expressive/components/select.dart';
export 'material_expressive/components/selection.dart';
export 'material_expressive/components/sheet.dart'
    hide expressiveSheetPageRoute;
export 'material_expressive/components/sliders.dart';
export 'material_expressive/components/splash.dart';
export 'material_expressive/components/split_button.dart';
export 'material_expressive/components/table.dart';
export 'material_expressive/components/text_fields.dart';
export 'material_expressive/components/toast.dart';
export 'material_expressive/components/toolbar.dart';
export 'material_expressive/components/wayfinding.dart';
export 'material_expressive/contrast.dart';
export 'material_expressive/elevation.dart';
export 'material_expressive/fonts.dart';
export 'material_expressive/icons.dart';
export 'material_expressive/motion.dart';
export 'material_expressive/shape.dart';
export 'material_expressive/spacing.dart';
export 'material_expressive/states.dart';
export 'material_expressive/styling.dart';
export 'material_expressive/strings.dart';
export 'material_expressive/theme.dart';
export 'material_expressive/type.dart';
