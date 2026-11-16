// Brindlemere parking permits, the service built from Civic's parts,
// opened on its start page.
import 'package:flutter/material.dart';

import '../kit_permits.dart';

Widget kitPermitsDemo(Brightness brightness) => PermitsApp(
  initialPage: PermitsPage.start,
  initialAppearance: brightness == Brightness.dark
      ? PermitsAppearance.dark
      : PermitsAppearance.light,
);
