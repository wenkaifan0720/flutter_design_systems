import 'package:material_ui/material_ui.dart';

import '../kit.dart';

/// Progress, waiting, news and the states a screen can be in.
Widget kitFeedbackDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Feedback',
  sections: kitSpecimens(const [
    'LinearProgressIndicator',
    'CircularProgressIndicator',
    'Skeleton',
    'Meter',
    'Banner',
    'StatusView',
    'EmptyState',
  ]),
);
