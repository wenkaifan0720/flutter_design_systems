// Each name retro_desktop_ui 0.8.1 renamed, used once; dart fix renames it (renamed_0_8_1.dart.expect).
import 'package:retro_desktop_ui/retro_desktop_parts.dart';

dynamic any;

void constructors() {
  RetroDesktopTextField(initial: any);
  RetroDesktopTextArea(initial: any);
  RetroDesktopInput(initial: any);
}

void getters(
  RetroDesktopTextField field,
  RetroDesktopTextArea area,
  RetroDesktopInput input,
) {
  any = field.initial;
  any = area.initial;
  any = input.initial;
}
