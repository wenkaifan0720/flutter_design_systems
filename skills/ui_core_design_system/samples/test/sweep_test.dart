import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tend/app.dart';
import 'package:tend/garden.dart';
import 'package:tend/screens/plant.dart';
import 'package:tend/screens/plants.dart';
import 'package:tend/screens/settings.dart';

import '../../evals/sweep.dart';

void main() {
  final garden = Garden.example(today: DateTime(2026, 3, 12));
  tearDownAll(garden.dispose);
  final screens = {
    'Plants': (_) => const PlantsScreen(),
    'Plant': (_) => PlantScreen(plant: garden.plants.first),
    'New plant': (_) => const PlantScreen(),
    'Settings': (_) => const SettingsScreen(),
  };
  Widget host(BuildContext context, Widget child, Brightness brightness) =>
      GardenScope(garden: garden, child: tendHost(context, child, brightness));

  testWidgets('every screen holds in the scoring sweep', (tester) async {
    final found = await sweepScreens(
      tester,
      screens: screens,
      host: host,
      name: 'Tend',
    );
    expect(found, isEmpty, reason: found.join('\n'));
  });

  testWidgets('the review pictures draw every screen', (tester) async {
    final files = await shootScreens(
      tester,
      screens: screens,
      host: host,
      outDir: Platform.environment['SHOOT_DIR']!,
    );
    expect(files, isNotEmpty);
  }, skip: !Platform.environment.containsKey('SHOOT_DIR'));
}
