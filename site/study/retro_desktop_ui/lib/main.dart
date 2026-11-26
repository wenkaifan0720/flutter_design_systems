import 'package:flutter/widgets.dart';
import 'package:stint_core/stint_core.dart';

import 'stint_retro_desktop.dart' deferred as study;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final launch = StintLaunch.fromUri(Uri.base);
  if (launch.semantics) WidgetsBinding.instance.ensureSemantics();
  await study.loadLibrary();
  runApp(await study.openStintRetroDesktop(launch));
}
