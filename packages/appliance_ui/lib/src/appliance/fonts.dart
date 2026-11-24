/// Where Appliance's face comes from. The `appliance_ui` package bundles
/// Barlow and sets [applianceFontPackage] to its own name; a host app that
/// bundles the face itself leaves it null.
library;

import 'package:flutter/services.dart';

/// The package that bundles Appliance's face, or null when the app does.
/// Every Appliance text style passes it as `TextStyle.package`.
// ignore: unnecessary_nullable_for_final_variable_declarations, the package's build names it.
const String? applianceFontPackage = 'appliance_ui';

/// Appliance's one typeface: Barlow, a quiet grotesk with rounded terminals,
/// close to the legend printed on a control panel. Regular, Medium and
/// SemiBold are bundled.
const String applianceFontFamily = 'Barlow';

/// Barlow's capitals as a fraction of its size (its OS/2 cap height, 700,
/// over its 1000 units per em): what `RawCapCenter` centres a label by.
const double applianceCapHeightFactor = 0.7;

const Map<int, String> _weights = {
  400: 'Barlow-Regular.ttf',
  500: 'Barlow-Medium.ttf',
  600: 'Barlow-SemiBold.ttf',
};

/// [family] under the name Flutter registers it by: `Barlow` when the app
/// bundles it, `packages/appliance_ui/Barlow` from the package. A test that
/// loads the face itself loads it under this name.
///
/// ```dart
/// final loader = FontLoader(applianceRegisteredFamily(applianceFontFamily));
/// ```
String applianceRegisteredFamily(String family) => applianceFontPackage == null
    ? family
    : 'packages/$applianceFontPackage/$family';

/// Loads the face Appliance bundles, so the first frame is set in it. Await
/// it before `runApp`: on the web a bundled face otherwise arrives after the
/// first frames, which flash in a fallback face.
///
/// ```dart
/// Future<void> main() async {WidgetsFlutterBinding.ensureInitialized(); await applianceLoadFonts(); runApp(const MyApp());}
/// ```
Future<void> applianceLoadFonts() {
  final loader = FontLoader(applianceRegisteredFamily(applianceFontFamily));
  for (final file in _weights.values) {
    loader.addFont(
      rootBundle.load(
        applianceFontPackage == null
            ? 'assets/fonts/$file'
            : 'packages/$applianceFontPackage/assets/fonts/$file',
      ),
    );
  }
  return loader.load();
}
