/// What comes up: `TermSideSheet`, `TermActionSheet`, `TermPopover`,
/// `TermHoverCard`, `TermTooltip`, `TermMenu`, `TermBanner`,
/// `TermEmptyState`, `TermStatusView` and `TermSkeleton`.
library;

import 'package:flutter/widgets.dart';

import '../kit.dart';

Widget kitSurfacesDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'surfaces',
  sections: kitParts(const [
    ('a side sheet', 'Sheet'),
    ('an action sheet', 'ActionSheet'),
    ('a popover', 'Popover'),
    ('a hover card', 'HoverCard'),
    ('a tooltip', 'Tooltip'),
    ('a menu', 'Menu'),
    ('a banner', 'Banner'),
    ('nothing here yet', 'EmptyState'),
    ('a view that failed', 'StatusView'),
    ('lines still loading', 'Skeleton'),
  ]),
);
