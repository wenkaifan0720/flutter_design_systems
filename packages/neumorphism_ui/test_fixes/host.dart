// NeumorphicHost, which neumorphism_ui 0.8.0 moved to the main library and gave Material's theme names, named
// through neumorphism_host.dart; dart fix imports neumorphism_ui.dart and renames them (host.dart.expect).
import 'package:neumorphism_ui/neumorphism_host.dart';

dynamic any;

void constructors() {
  NeumorphicHost(light: any, darkData: any, child: any);
}

void fields(NeumorphicHost host) {
  host.light;
  host.darkData;
}
