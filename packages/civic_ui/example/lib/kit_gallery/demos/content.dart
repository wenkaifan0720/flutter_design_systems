// What a page shows: rows of a list, statuses, section headings, help
// folded under its title, a rule, the inset rule and the warning, the
// confirmation panel and the banner.
import 'package:flutter/material.dart';
import 'package:civic_ui/civic_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

Widget kitContentDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Rows, tags, insets & panels',
  sections: [
    KitSection(
      title: 'List rows and tags',
      spacing: 0,
      children: [
        CivicListRow(
          title: const Text('Resident permit, Zone B'),
          subtitle: const Text('BRM-4821-K, sent 3 November'),
          trailing: const CivicTag(label: 'In review', tone: CivicTone.info),
          onTap: () {},
        ),
        CivicListRow(
          title: const Text('Visitor permits, 10 days'),
          subtitle: const Text('BRM-3307-A, sent 12 October'),
          trailing: const CivicTag(label: 'Approved', tone: CivicTone.success),
          onTap: () {},
        ),
        CivicListRow(
          title: const Text('Second permit, Zone B'),
          subtitle: const Text('BRM-2914-C, sent 2 September'),
          trailing: const CivicTag(label: 'Refused', tone: CivicTone.error),
          onTap: () {},
        ),
        const CivicListRow(
          leading: Icon(LucideIcons.clock),
          title: Text('Permits are checked by hand on weekdays'),
          subtitle: Text('Allow 5 working days.'),
        ),
      ],
    ),
    const KitSection(
      title: 'Tags',
      children: [
        Wrap(
          spacing: CivicSpacing.s8,
          runSpacing: CivicSpacing.s8,
          children: [
            CivicTag(label: 'Not started'),
            CivicTag(label: 'In progress', tone: CivicTone.info),
            CivicTag(label: 'Completed', tone: CivicTone.success),
            CivicTag(label: 'Action needed', tone: CivicTone.warning),
            CivicTag(label: 'Cannot start yet', tone: CivicTone.error),
          ],
        ),
      ],
    ),
    KitSection(
      title: 'Section headers',
      children: [
        CivicSectionHeader(
          title: 'Your permits',
          action: CivicLink(onPressed: () {}, child: const Text('View all')),
        ),
      ],
    ),
    const KitSection(
      title: 'Details',
      caption: 'Help most readers will not need, folded under its title.',
      children: [
        CivicDetails(
          title: 'Help with proof of address',
          child: Text(
            'A council tax bill or a tenancy agreement from the last three '
            'months, as a PDF or a photo.',
          ),
        ),
        CivicDetails(
          title: 'If you do not have a vehicle yet',
          initiallyExpanded: true,
          child: Text(
            'Apply when you have its registration number: a permit names '
            'one vehicle.',
          ),
        ),
      ],
    ),
    const KitSection(
      title: 'Section break',
      children: [
        Text('Above the rule.'),
        CivicSectionBreak(size: CivicSectionBreakSize.medium),
        Text('Below the rule.'),
      ],
    ),
    const KitSection(
      title: 'Inset and warning',
      children: [
        CivicInset(child: Text('It can take up to 5 working days to decide.')),
        CivicWarning(
          assistiveLabel: 'Warning',
          child: Text(
            'You can be fined if you park in a permit zone without a permit.',
          ),
        ),
      ],
    ),
    const KitSection(
      title: 'Panels',
      children: [
        CivicConfirmationPanel(
          title: 'Application sent',
          child: Column(
            children: [
              Text('Your reference number'),
              SizedBox(height: CivicSpacing.s8),
              Text(
                'BRM-4821-K',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 30),
              ),
            ],
          ),
        ),
        CivicNotificationBanner(
          title: 'Important',
          child: Text('Permits for Zone C are paused until 1 December.'),
        ),
        CivicNotificationBanner(
          title: 'Success',
          tone: CivicTone.success,
          child: Text('Your contact preferences have been saved.'),
        ),
      ],
    ),
  ],
);
