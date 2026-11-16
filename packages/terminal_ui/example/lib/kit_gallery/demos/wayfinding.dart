/// Where you are: `TermBreadcrumb`, `TermPagination`, `TermPageDots`,
/// `TermSteps`, `TermMenuBar`, `TermNavigationRail`, `TermScaffold` and
/// `TermCommandPalette`.
library;

import 'package:flutter/widgets.dart';

import '../kit.dart';

Widget kitWayfindingDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'wayfinding',
  sections: kitParts(const [
    ('a path', 'Breadcrumb'),
    ('pages', 'Pagination'),
    ('page dots', 'PageDots'),
    ('steps', 'StepProgress'),
    ('a menubar', 'MenuBar'),
    ('a rail', 'NavigationRail'),
    ('a shell that fits the screen', 'Scaffold'),
    ('commands', 'Command'),
  ]),
);
