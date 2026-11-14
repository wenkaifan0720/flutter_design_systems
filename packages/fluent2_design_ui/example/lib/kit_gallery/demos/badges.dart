/// Fluent 2's badges and tags: the Badge's four appearances in its tones
/// and sizes, the CounterBadge (with its overflow and its dot), the status
/// glyphs Planner sets, the Tag (with a second line, a person, dismissible,
/// disabled), the InteractionTag and a TagGroup of filters picked one at a
/// time and several at once.
library;

import 'package:flutter/material.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';

import '../kit.dart';

Widget kitBadgesDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Badges & tags',
  sections: [
    kitSection('Badge appearances', children: [kitSpecimenBadgeTones()]),
    kitSection('Badge sizes and shapes', children: [kitSpecimenBadgeSizes()]),
    kitSection('Counter badges', children: [kitSpecimenCounterBadges()]),
    kitSection('Status', children: [kitSpecimenStatusGlyphs()]),
    kitSection('Tags', children: [kitSpecimenTags()]),
    kitSection('Tag sizes', children: [kitSpecimenTagSizes()]),
    kitSection(
      'Interaction tags',
      children: [
        kitSpecimenInteractionTagRest(),
        kitSpecimenInteractionTagSelected(),
        const _Filters(),
      ],
    ),
    kitSection('Tag group', children: [kitSpecimenTagGroup()]),
  ],
);

/// The four appearances in the tones a workspace uses.
Widget kitSpecimenBadgeTones() => Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.start,
  spacing: Fluent2Spacing.m,
  children: [
    for (final appearance in Fluent2BadgeAppearance.values)
      kitRow([
        Fluent2LabelBadge(label: 'Draft', appearance: appearance),
        Fluent2LabelBadge(
          label: 'Shared',
          appearance: appearance,
          color: Fluent2BadgeColor.informative,
        ),
        Fluent2LabelBadge(
          label: 'Approved',
          icon: Fluent2Icons.checkmark,
          appearance: appearance,
          color: Fluent2BadgeColor.success,
        ),
        Fluent2LabelBadge(
          label: 'Due soon',
          appearance: appearance,
          color: Fluent2BadgeColor.warning,
        ),
        Fluent2LabelBadge(
          label: 'Overdue',
          appearance: appearance,
          color: Fluent2BadgeColor.danger,
        ),
        Fluent2LabelBadge(
          label: 'External',
          appearance: appearance,
          color: Fluent2BadgeColor.severe,
        ),
        Fluent2LabelBadge(
          label: 'Archived',
          appearance: appearance,
          color: Fluent2BadgeColor.subtle,
        ),
      ]),
  ],
);

/// The six sizes (the two dots carry no words) and the three shapes.
Widget kitSpecimenBadgeSizes() => Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.start,
  spacing: Fluent2Spacing.m,
  children: [
    kitRow([
      for (final size in Fluent2BadgeSize.values)
        Fluent2LabelBadge(
          label: size.isDot ? null : 'New',
          size: size,
          semanticLabel: size.isDot ? 'New' : null,
        ),
    ]),
    kitRow([
      for (final shape in Fluent2BadgeShape.values)
        Fluent2LabelBadge(
          label: 'Shared',
          icon: Fluent2Icons.people,
          appearance: Fluent2BadgeAppearance.tint,
          shape: shape,
        ),
    ]),
  ],
);

/// Unread counts on the workspace's commands, one past its overflow, and
/// the dot.
Widget kitSpecimenCounterBadges() => kitRow([
  Fluent2IconButton(
    Fluent2Icons.chat,
    label: 'Chat, 3 unread',
    onPressed: () {},
    badge: const Fluent2Badge(3, size: Fluent2BadgeSize.small),
  ),
  Fluent2IconButton(
    Fluent2Icons.mail,
    label: 'Mail, 120 unread',
    onPressed: () {},
    badge: const Fluent2Badge(
      120,
      color: Fluent2BadgeCountColor.danger,
      size: Fluent2BadgeSize.small,
    ),
  ),
  Fluent2IconButton(
    Fluent2Icons.alert,
    label: 'Activity, new',
    onPressed: () {},
    badge: const Fluent2Badge.dot(),
  ),
  const Fluent2Badge(12),
  const Fluent2Badge(
    5,
    appearance: Fluent2BadgeAppearance.ghost,
    color: Fluent2BadgeCountColor.informative,
  ),
]);

/// A plan's tasks in each of their states.
Widget kitSpecimenStatusGlyphs() => Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.start,
  spacing: Fluent2Spacing.s,
  children: const [
    Fluent2StatusGlyph(Fluent2TaskStatus.notStarted, label: 'Draft the brief'),
    Fluent2StatusGlyph(Fluent2TaskStatus.inProgress, label: 'Review the deck'),
    Fluent2StatusGlyph(Fluent2TaskStatus.done, label: 'Book the room'),
    Fluent2StatusGlyph(Fluent2TaskStatus.atRisk, label: 'Vendor contract'),
    Fluent2StatusGlyph(Fluent2TaskStatus.blocked, label: 'Storage upgrade'),
    Fluent2StatusGlyph(Fluent2TaskStatus.cancelled, label: 'Offsite dinner'),
  ],
);

/// Labels on a file: plain, with a glyph, a person, a second line,
/// dismissible and disabled.
Widget kitSpecimenTags() => kitRow([
  const Fluent2Tag('Design', icon: Fluent2Icons.tag),
  const Fluent2Tag('Mara Okafor', avatar: 'Mara Okafor'),
  const Fluent2Tag('Launch plan.docx', secondary: 'Edited by Kai Tanaka'),
  Fluent2Tag(
    'Marketing',
    appearance: Fluent2TagAppearance.outline,
    onDeleted: () {},
  ),
  Fluent2Tag(
    'Q4 launch',
    appearance: Fluent2TagAppearance.brand,
    onDeleted: () {},
  ),
  const Fluent2Tag('Legacy', enabled: false),
]);

/// The three sizes, each with a glyph, a person and a dismiss.
Widget kitSpecimenTagSizes() => Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.start,
  spacing: Fluent2Spacing.m,
  children: [
    for (final size in Fluent2TagSize.values)
      kitRow([
        Fluent2Tag('Design', icon: Fluent2Icons.tag, size: size),
        Fluent2Tag(
          'Kai Tanaka',
          avatar: 'Kai Tanaka',
          size: size,
          shape: Fluent2TagShape.circular,
        ),
        Fluent2Tag(
          'Q4 launch',
          appearance: Fluent2TagAppearance.brand,
          size: size,
          onDeleted: () {},
        ),
      ]),
  ],
);

/// Interaction tags at rest: a filter, one with a dismiss part, one with
/// a person.
Widget kitSpecimenInteractionTagRest() => kitRow([
  Fluent2InteractionTag(
    'Shared with me',
    icon: Fluent2Icons.share,
    selected: false,
    onPressed: () {},
  ),
  Fluent2InteractionTag(
    'Meeting notes',
    icon: Fluent2Icons.note,
    appearance: Fluent2TagAppearance.outline,
    onPressed: () {},
    onDeleted: () {},
  ),
  Fluent2InteractionTag(
    'Noor Haddad',
    avatar: 'Noor Haddad',
    shape: Fluent2TagShape.circular,
    onPressed: () {},
  ),
]);

/// Interaction tags selected: the brand fill, with and without a dismiss.
Widget kitSpecimenInteractionTagSelected() => kitRow([
  Fluent2InteractionTag(
    'Shared with me',
    icon: Fluent2Icons.share,
    selected: true,
    onPressed: () {},
  ),
  Fluent2InteractionTag(
    'Design',
    selected: true,
    onPressed: () {},
    onDeleted: () {},
  ),
]);

/// The file filters, one picked.
Widget kitSpecimenTagGroup() => Fluent2TagGroup<String>(
  label: 'File type',
  items: const [
    Fluent2TagItem('all', 'All files', dismissible: false),
    Fluent2TagItem('docs', 'Documents', icon: Fluent2Icons.document),
    Fluent2TagItem('sheets', 'Spreadsheets', icon: Fluent2Icons.grid),
    Fluent2TagItem('images', 'Images', icon: Fluent2Icons.image),
  ],
  selected: const {'docs'},
  onSelectionChanged: (_) {},
);

class _Filters extends StatefulWidget {
  const _Filters();

  @override
  State<_Filters> createState() => _FiltersState();
}

class _FiltersState extends State<_Filters> {
  Set<String> _people = {'Kai Tanaka'};
  final Set<String> _shown = {
    for (final p in kitPeople.skip(1).take(4)) p.name,
  };
  bool _mine = true;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: Fluent2Spacing.m,
    children: [
      kitRow([
        Fluent2InteractionTag(
          'Shared with me',
          icon: Fluent2Icons.share,
          selected: _mine,
          onPressed: () => setState(() => _mine = !_mine),
        ),
        Fluent2InteractionTag(
          'Meeting notes',
          icon: Fluent2Icons.note,
          appearance: Fluent2TagAppearance.outline,
          onPressed: () {},
          onDeleted: () {},
        ),
      ]),
      Fluent2TagGroup<String>(
        label: 'People',
        multiple: true,
        shape: Fluent2TagShape.circular,
        items: [
          for (final name in _shown) Fluent2TagItem(name, name, avatar: name),
        ],
        selected: _people,
        onSelectionChanged: (next) => setState(() => _people = next),
        onDeleted: (name) => setState(() {
          _shown.remove(name);
          _people = {..._people}..remove(name);
        }),
      ),
    ],
  );
}
