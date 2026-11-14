/// Fluent 2's tab list in its four appearances and three sizes, with
/// glyphs, scrolling when its tabs outrun the width, standing vertical
/// and with a disabled tab; and the breadcrumb at its sizes, collapsing
/// its middle into a menu.
library;

import 'package:flutter/material.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';

import '../kit.dart';

/// Holds a live value for a specimen: [builder] draws the control with the
/// value and the setter it hands the control.
class _Live<T> extends StatefulWidget {
  const _Live(this.initial, this.builder);

  final T initial;
  final Widget Function(T value, ValueChanged<T> set) builder;

  @override
  State<_Live<T>> createState() => _LiveState<T>();
}

class _LiveState<T> extends State<_Live<T>> {
  late T _value = widget.initial;

  @override
  Widget build(BuildContext context) =>
      widget.builder(_value, (v) => setState(() => _value = v));
}

Widget kitTabsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Tabs and breadcrumb',
  sections: [
    kitSection('Transparent, with glyphs', children: [kitSpecimenTabsFit()]),
    for (final appearance in Fluent2TabAppearance.values.skip(1))
      kitSection(kitSay(appearance), children: [_tabs(appearance: appearance)]),
    for (final size in Fluent2TabSize.values)
      kitSection(
        'Size ${kitSay(size).toLowerCase()}',
        children: [_tabs(size: size)],
      ),
    kitSection('Scrolling', children: [kitSpecimenTabsScroll()]),
    kitSection('Vertical', children: [_tabs(vertical: true)]),
    kitSection('Breadcrumb', children: [kitSpecimenBreadcrumb()]),
    kitSection(
      'Breadcrumb collapsed',
      children: [kitSpecimenBreadcrumbOverflow()],
    ),
    kitSection(
      'Breadcrumb sizes',
      children: [
        for (final size in Fluent2BreadcrumbSize.values)
          Fluent2Breadcrumb(
            size: size,
            items: [
              Fluent2BreadcrumbItem('Northwind', onPressed: () {}),
              Fluent2BreadcrumbItem('Design', onPressed: () {}),
              const Fluent2BreadcrumbItem('Brand guidelines.pdf'),
            ],
          ),
      ],
    ),
  ],
);

/// A team channel's pages, Archive disabled; [glyphs] puts each page's
/// glyph before it, [many] adds four more pages.
List<Fluent2Tab> _pages({bool glyphs = false, bool many = false}) => [
  Fluent2Tab(
    'Posts',
    icon: glyphs ? Fluent2Icons.chat : null,
    selectedIcon: glyphs ? Fluent2Icons.chatFilled : null,
  ),
  Fluent2Tab(
    'Files',
    icon: glyphs ? Fluent2Icons.folder : null,
    selectedIcon: glyphs ? Fluent2Icons.folderFilled : null,
  ),
  Fluent2Tab(
    'Notes',
    icon: glyphs ? Fluent2Icons.note : null,
    selectedIcon: glyphs ? Fluent2Icons.noteFilled : null,
  ),
  if (many) ...[
    const Fluent2Tab('Meetings'),
    const Fluent2Tab('Tasks'),
    const Fluent2Tab('Whiteboard'),
    const Fluent2Tab('Wiki'),
  ],
  const Fluent2Tab('Archive', enabled: false),
];

/// A live tab list over the channel's pages, for the demo's bands.
Widget _tabs({
  Fluent2TabAppearance appearance = Fluent2TabAppearance.transparent,
  Fluent2TabSize size = Fluent2TabSize.medium,
  bool vertical = false,
}) => _Live<int>(
  0,
  (value, set) => Fluent2TabList.items(
    appearance: appearance,
    size: size,
    vertical: vertical,
    label: 'Channel pages',
    selectedIndex: value,
    onChanged: set,
    items: _pages(),
  ),
);

// --- Specimens --------------------------------------------------------------

Widget kitSpecimenTabsFit() => _Live<int>(
  0,
  (value, set) => Fluent2TabList.items(
    label: 'Channel pages',
    selectedIndex: value,
    onChanged: set,
    items: _pages(glyphs: true),
  ),
);

Widget kitSpecimenTabsScroll() => _Live<int>(
  0,
  (value, set) => Fluent2TabList.items(
    label: 'Channel pages',
    selectedIndex: value,
    onChanged: set,
    items: _pages(many: true),
  ),
);

Widget kitSpecimenTabsCircular() => _Live<int>(
  0,
  (value, set) => Fluent2TabList.items(
    appearance: Fluent2TabAppearance.filledCircular,
    label: 'Channel pages',
    selectedIndex: value,
    onChanged: set,
    items: _pages(),
  ),
);

Widget kitSpecimenBreadcrumb() => Fluent2Breadcrumb(
  items: [
    Fluent2BreadcrumbItem(
      'Northwind',
      icon: Fluent2Icons.home,
      onPressed: () {},
    ),
    Fluent2BreadcrumbItem('Design', onPressed: () {}),
    const Fluent2BreadcrumbItem('Brand guidelines.pdf'),
  ],
);

Widget kitSpecimenBreadcrumbOverflow() => Fluent2Breadcrumb(
  maxDisplayedItems: 3,
  items: [
    Fluent2BreadcrumbItem('Northwind', onPressed: () {}),
    Fluent2BreadcrumbItem('Shared', onPressed: () {}),
    Fluent2BreadcrumbItem('Design', onPressed: () {}),
    Fluent2BreadcrumbItem('Brand', onPressed: () {}),
    const Fluent2BreadcrumbItem('Logo usage.pdf'),
  ],
);
