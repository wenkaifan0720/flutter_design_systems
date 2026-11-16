/// Tables, trees and layout: `TermTable`, `TermDataTable`, `TermTree`,
/// `TermDisclosure`, `TermDivider`, `TermScrollArea`, `TermSplitView`,
/// `TermReorderableList`, `TermPullToRefresh`, `TermTimeline`, `TermAvatar`,
/// `TermAvatarGroup`, `TermMedia` and `TermDescriptionList`.
library;

import 'package:flutter/widgets.dart';

import '../kit.dart';

Widget kitContainersDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'containers',
  sections: kitParts(const [
    ('a table', 'Table'),
    ('a data table', 'DataTable'),
    ('a tree', 'TreeView'),
    ('a disclosure', 'Disclosure'),
    ('dividers', 'Divider'),
    ('a scroll area', 'ScrollArea'),
    ('a split view', 'Resizable'),
    ('a list you reorder', 'ReorderableListView'),
    ('pull to refresh', 'RefreshIndicator'),
    ('a timeline', 'Timeline'),
    ('avatars', 'Avatar'),
    ('a group of avatars', 'AvatarGroup'),
    ('a picture', 'Media'),
    ('terms and values', 'DescriptionList'),
  ]),
);
