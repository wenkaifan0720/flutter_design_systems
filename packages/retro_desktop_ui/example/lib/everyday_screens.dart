/// Papers, the example's own application, opened at each of its ten everyday
/// screens: an app built on Retro Desktop, at work. Each entry is the whole
/// app at that screen, by day or by night, read either way; right to left it
/// speaks Hebrew.
library;

import 'package:flutter/widgets.dart';

import 'kit_gallery/demos/papers.dart';

/// One everyday screen: its id (the gallery link's, `/#/<id>`) and the whole
/// app opened at it.
typedef EverydayScreen = ({
  String id,
  Widget Function(Brightness brightness, TextDirection direction) app,
});

/// The ten screens, in the order a day with Papers meets them.
final everydayScreens = <EverydayScreen>[
  // The desktop: the documents window in front of the others.
  (
    id: 'overview',
    app: (brightness, direction) => kitPapersScreen(
      KitPapersWindow.documents,
      brightness,
      direction: direction,
    ),
  ),
  // The documents list, the only window open.
  (
    id: 'list',
    app: (brightness, direction) => kitPapersScreen(
      KitPapersWindow.documents,
      brightness,
      alone: true,
      direction: direction,
    ),
  ),
  // One document open to read.
  (
    id: 'document',
    app: (brightness, direction) => kitPapersScreen(
      KitPapersWindow.document,
      brightness,
      direction: direction,
    ),
  ),
  // Your details: a form.
  (
    id: 'form',
    app: (brightness, direction) => kitPapersScreen(
      KitPapersWindow.details,
      brightness,
      direction: direction,
    ),
  ),
  (
    id: 'settings',
    app: (brightness, direction) => kitPapersScreen(
      KitPapersWindow.settings,
      brightness,
      direction: direction,
    ),
  ),
  // Ordering printed copies of a document.
  (
    id: 'checkout',
    app: (brightness, direction) => kitPapersScreen(
      KitPapersWindow.prints,
      brightness,
      direction: direction,
    ),
  ),
  // Closing your details with changes unsaved: the alert that asks first.
  (
    id: 'save-changes',
    app: (brightness, direction) => kitPapersScreen(
      KitPapersWindow.details,
      brightness,
      moment: KitPapersMoment.unsaved,
      direction: direction,
    ),
  ),
  // The bin, emptied.
  (
    id: 'empty',
    app: (brightness, direction) =>
        kitPapersScreen(KitPapersWindow.bin, brightness, direction: direction),
  ),
  // Finding a document as you type.
  (
    id: 'search',
    app: (brightness, direction) => kitPapersScreen(
      KitPapersWindow.documents,
      brightness,
      moment: KitPapersMoment.search,
      direction: direction,
    ),
  ),
  // An order for printed copies that failed, and what to do next.
  (
    id: 'error',
    app: (brightness, direction) => kitPapersScreen(
      KitPapersWindow.prints,
      brightness,
      moment: KitPapersMoment.failedOrder,
      direction: direction,
    ),
  ),
];
