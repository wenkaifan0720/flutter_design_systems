// A caller of what 0.2.0 deprecates, as written before: `dart fix --compare-to-golden test_fixes` checks that
// fix_data.yaml turns it into theme.dart.expect.
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

RetroDesktopThemeData chisel() => RetroDesktopThemeData.classic().copyWith(
  appearance: RetroDesktopAppearance.chisel,
  motion: const RetroDesktopMotion(state: Duration(milliseconds: 200)),
);
