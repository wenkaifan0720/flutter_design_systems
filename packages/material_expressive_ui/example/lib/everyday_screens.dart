// The example's ten everyday screens, each as the whole example opened on
// it: the trip planner's five screens, the everyday dialog, tabs and card
// grid, the feedback states and the overview. A test (or a screenshot
// tool) pumps one in a brightness and a reading direction; right to left,
// the trip planner reads in Arabic.
import 'package:flutter/widgets.dart';

import 'kit_gallery/trip.dart';
import 'gallery.dart';

/// One screen: its [id] and the app opened on it.
typedef EverydayScreen = ({
  String id,
  Widget Function(Brightness brightness, TextDirection direction) app,
});

/// The ten screens, in the order a reader walks them.
final List<EverydayScreen> everydayScreens = [
  _screen('home', TripScreens.home),
  _screen('plan', TripScreens.plan),
  _screen('shared', TripScreens.shared),
  _screen('kit', TripScreens.kit),
  _screen('preferences', TripScreens.preferences),
  _screen('dialog', 'everyday-dialog'),
  _screen('tabs', 'everyday-tabs'),
  _screen('cards', 'everyday-cards'),
  _screen('feedback', 'feedback'),
  _screen('overview', galleryOverview),
];

EverydayScreen _screen(String id, String page) => (
  id: id,
  app: (brightness, direction) => GalleryApp(
    initialPage: page,
    initialBrightness: brightness,
    initialCustom: GalleryCustom(
      direction: direction == TextDirection.rtl ? 'rtl' : 'ltr',
    ),
  ),
);
