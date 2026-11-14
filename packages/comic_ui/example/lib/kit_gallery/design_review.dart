/// Ordinary product screens, built from the same public components as the gallery.
library;

import 'package:flutter/material.dart';
import 'package:comic_ui/comic_ui.dart';

import 'kit.dart';

/// Screens available in the example and captured by the design review test.
const reviewPages =
    <({String id, String title, Widget Function(Brightness) build})>[
      (id: 'review-form', title: 'Try a form', build: reviewForm),
      (id: 'review-dialog', title: 'Try a decision', build: reviewDialog),
      (id: 'review-list', title: 'Try a list', build: reviewList),
      (id: 'review-tabs', title: 'Try tabs', build: reviewTabs),
      (id: 'review-cards', title: 'Try a card grid', build: reviewCards),
      (id: 'review-settings', title: 'Try settings', build: reviewSettings),
    ];

/// The same ordinary roles under Customize's current corner family.
/// Menus and the dialog are shown inline so every contour can be compared.
Widget reviewCorners(Brightness brightness) => _screen(
  brightness,
  'One corner system',
  LayoutBuilder(
    builder: (context, box) => ComicGridOf(
      columns: box.maxWidth >= 700 ? 2 : 1,
      gap: 24,
      runGap: 24,
      children: [
        kitSection(
          'Form and open dropdown',
          children: [
            const ComicTextField(
              label: 'Full name',
              initialValue: 'Alex Morgan',
            ),
            kitState(
              'standard',
              (context, value, change) => ComicColumn(
                gap: 4,
                children: [
                  ComicSelect<String>(
                    label: 'Delivery',
                    value: value,
                    options: const [
                      ComicSelectOption('standard', 'Standard delivery'),
                      ComicSelectOption('express', 'Express delivery'),
                    ],
                    onChanged: change,
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: ComicMenu<String>(
                      items: [
                        ComicMenuItem(
                          'standard',
                          'Standard delivery',
                          selected: value == 'standard',
                        ),
                        ComicMenuItem(
                          'express',
                          'Express delivery',
                          selected: value == 'express',
                        ),
                      ],
                      onSelected: change,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        kitSection(
          'Dialog and actions',
          children: [
            ComicDialog(
              title: 'Keep your saved items?',
              message: 'Keep this collection for another day.',
              actions: [
                ComicButton.text(
                  'Remove them',
                  onPressed: () => kitFeedback(context, 'Collection removed.'),
                ),
                ComicButton.filled(
                  'Keep them',
                  onPressed: () => kitFeedback(context, 'Collection kept.'),
                ),
              ],
            ),
          ],
        ),
        kitSection(
          'Segmented choices and chips',
          children: [
            kitState(
              0,
              (context, value, change) => ComicSegmentedButton<int>(
                label: 'View',
                value: value,
                segments: const [
                  ComicButtonSegment(0, 'Day'),
                  ComicButtonSegment(1, 'Week'),
                ],
                onChanged: change,
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                kitState(
                  true,
                  (context, value, change) => ComicChip(
                    'Saved',
                    selected: value,
                    onPressed: () => change(!value),
                  ),
                ),
                const ComicBadge(12),
              ],
            ),
            kitState(
              false,
              (context, value, change) => ComicSwitchRow(
                label: 'Delivery updates',
                value: value,
                onChanged: change,
              ),
            ),
          ],
        ),
        kitSection(
          'Slider and progress',
          children: [
            kitState(
              .45,
              (context, value, change) =>
                  ComicSlider(label: 'Volume', value: value, onChanged: change),
            ),
            const ComicLinearProgressIndicator(value: .45, label: 'Download'),
            kitState(
              3,
              (context, value, change) => ComicNumberField(
                value: value,
                unit: 'copies',
                onChanged: change,
                min: 1,
              ),
            ),
          ],
        ),
        kitSection(
          'Radio group and tabs',
          children: [
            kitState(
              0,
              (context, value, change) => ComicRadioGroup<int>(
                label: 'Format',
                value: value,
                options: const [
                  ComicRadio(0, 'Print edition'),
                  ComicRadio(1, 'Digital edition'),
                ],
                onChanged: change,
              ),
            ),
            kitState(
              0,
              (context, value, change) => ComicTabBar(
                tabs: const ['All items', 'Saved'],
                selectedIndex: value,
                onChanged: change,
              ),
            ),
          ],
        ),
        kitSection(
          'Date and time pickers',
          children: [
            kitState(
              DateTime(2026, 11, 8),
              (context, value, change) => ComicDatePicker(
                value: value,
                currentDate: DateTime(2026, 11, 7),
                onChanged: change,
              ),
            ),
            kitState(
              const ComicTime(9, 30),
              (context, value, change) => ComicTimePicker(
                value: value,
                minuteStep: 15,
                onChanged: change,
              ),
            ),
          ],
        ),
        kitSection(
          'Rows in a group',
          children: [
            kitState(
              1,
              (context, value, change) => ComicListSection(
                label: 'Issues',
                children: [
                  for (final (i, title) in const [
                    (0, 'The first issue'),
                    (1, 'The second issue'),
                    (2, 'The third issue'),
                  ])
                    ComicListTile(
                      title: title,
                      isFirst: i == 0,
                      selected: i == value,
                      trailing: const Icon(ComicGlyphs.forward),
                      onPressed: () => change(i),
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  ),
);

Widget _screen(Brightness brightness, String title, Widget body) => kitScreen(
  brightness: brightness,
  title: title,
  showSampleNavigation: false,
  sections: [
    Align(
      alignment: AlignmentDirectional.topStart,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 880),
        child: body,
      ),
    ),
  ],
);

/// A normal editable form; its delivery menu opens at the actual field.
Widget reviewForm(Brightness brightness) =>
    _screen(brightness, 'Delivery details', reviewFormBody());

/// The screen's body alone, for the live example's page of the same name.
Widget reviewFormBody() => kitState(
  'standard',
  (context, value, change) => ComicColumn(
    gap: 24,
    children: [
      Text(
        'Tell us where to send your order.',
        style: ComicTheme.of(context).type.body,
      ),
      const ComicTextField(label: 'Full name', initialValue: 'Alex Morgan'),
      const ComicTextField(
        label: 'Email address',
        initialValue: 'alex@example.com',
        keyboardType: TextInputType.emailAddress,
      ),
      ComicSelect<String>(
        key: const ValueKey('review/dropdown'),
        label: 'Delivery',
        value: value,
        options: const [
          ComicSelectOption('standard', 'Standard delivery'),
          ComicSelectOption('express', 'Express delivery'),
          ComicSelectOption('collect', 'Collect in store'),
        ],
        onChanged: change,
      ),
      kitState(
        true,
        (context, value, change) => ComicCheckRow(
          label: 'Email me delivery updates',
          value: value,
          onChanged: change,
        ),
      ),
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: ComicButton.filled(
          'Save details',
          onPressed: () => kitFeedback(context, 'Delivery details saved.'),
        ),
      ),
    ],
  ),
);

/// A real modal with equally prominent label placement in its two actions.
Widget reviewDialog(Brightness brightness) =>
    _screen(brightness, 'Manage your collection', reviewDialogBody());

/// The screen's body alone, for the live example's page of the same name.
Widget reviewDialogBody() => Builder(
  builder: (context) => ComicCard(
    title: 'Saved items',
    children: [
      const Text(
        'Your collection has 12 saved items. You can keep them for later.',
      ),
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: ComicButton(
          'Review saved items',
          key: const ValueKey('review/dialog-open'),
          onPressed: () async {
            final keep = await showComicDialog<bool>(
              context,
              builder: (context) => ComicDialog(
                title: 'Keep your saved items?',
                message: 'Keep the collection for another day, or remove these items from your list.',
                actions: [
                  ComicButton.text(
                    'Remove them',
                    onPressed: () => Navigator.pop(context, false),
                  ),
                  ComicButton.filled(
                    'Keep them',
                    onPressed: () => Navigator.pop(context, true),
                  ),
                ],
              ),
            );
            if (context.mounted && keep != null) {
              kitFeedback(
                context,
                keep ? 'Your items are kept.' : 'Your items were removed.',
              );
            }
          },
        ),
      ),
    ],
  ),
);

/// Leading identities, titles, metadata and actions on one row system.
Widget reviewList(Brightness brightness) =>
    _screen(brightness, 'Your team', reviewListBody());

/// The screen's body alone, for the live example's page of the same name.
Widget reviewListBody() => Builder(
  builder: (context) => ComicListSection(
    label: 'Team members',
    children: [
      for (final (initials, name, role) in [
        ('AM', 'Alex Morgan', 'Project owner'),
        ('NW', 'Nia Walker', 'Designer'),
        ('JL', 'Jamie Lee', 'Editor'),
        ('SR', 'Sam Rivera', 'Contributor'),
      ])
        ComicListTile(
          title: name,
          subtitle: role,
          isFirst: initials == 'AM',
          leading: ComicAvatar(initials, name: name),
          action: ComicIconButton(
            ComicGlyphs.more,
            label: 'Options for $name',
            onPressed: () => kitFeedback(context, '$name selected.'),
          ),
        ),
    ],
  ),
);

/// Tabs change both their selection and the displayed list.
Widget reviewTabs(Brightness brightness) =>
    _screen(brightness, 'Your reading list', reviewTabsBody());

/// The screen's body alone, for the live example's page of the same name.
Widget reviewTabsBody() => kitState(
  0,
  (context, value, change) => ComicColumn(
    gap: 24,
    children: [
      ComicTabBar(
        tabs: const ['All items', 'Saved', 'Finished'],
        selectedIndex: value,
        onChanged: change,
      ),
      Text(
        [
          'All your reading in one place.',
          'Two items saved for later.',
          'You have finished this issue.',
        ][value],
        style: ComicTheme.of(context).type.body,
      ),
      ComicListSection(
        children: [
          for (final title in switch (value) {
            1 => ['A small adventure', 'Making time'],
            2 => ['The everyday issue'],
            _ => ['A small adventure', 'Making time', 'The everyday issue'],
          })
            ComicListTile(
              title: title,
              subtitle: value == 2 ? 'Finished yesterday' : 'Ready to read',
              isFirst:
                  title ==
                  (value == 2 ? 'The everyday issue' : 'A small adventure'),
              action: ComicButton.text(
                'Open',
                onPressed: () => kitFeedback(context, '$title opened.'),
              ),
            ),
        ],
      ),
    ],
  ),
);

/// Cards use a clear frame and text hierarchy without a decorative silhouette.
Widget reviewCards(Brightness brightness) =>
    _screen(brightness, 'Your projects', reviewCardsBody());

/// The screen's body alone, for the live example's page of the same name.
Widget reviewCardsBody() => LayoutBuilder(
  builder: (context, box) => ComicGridOf(
    columns: box.maxWidth >= 700 ? 2 : 1,
    gap: 16,
    runGap: 16,
    children: [
      for (final (title, copy) in [
        ('Weekend plans', 'A few good places to go next.'),
        ('Reading notes', 'Ideas worth keeping close.'),
        ('Home projects', 'Small improvements, one at a time.'),
        ('Shared ideas', 'A space for the whole team.'),
      ])
        ComicCard(
          title: title,
          children: [
            Text(copy),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: ComicButton.text(
                'Open project',
                style: const ComicStyle(
                  padding: WidgetStatePropertyAll(
                    EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
                onPressed: () => kitFeedback(context, '$title opened.'),
              ),
            ),
          ],
        ),
    ],
  ),
);

/// Settings expose real switch state and motion with whole-row targets.
Widget reviewSettings(Brightness brightness) =>
    _screen(brightness, 'Notifications', reviewSettingsBody());

/// The screen's body alone, for the live example's page of the same name.
Widget reviewSettingsBody() => ComicColumn(
  gap: 24,
  children: [
    const Text('Choose when you hear from us.'),
    ComicListSection(
      label: 'Notification preferences',
      children: [
        for (final (label, note, initial) in [
          ('Weekly summary', 'A short update every Monday', true),
          ('New messages', 'When someone replies to you', true),
          ('Product news', 'Occasional news and improvements', false),
        ])
          kitState(
            initial,
            (context, value, change) => ComicSwitchRow(
              label: label,
              note: note,
              value: value,
              isFirst: label == 'Weekly summary',
              onChanged: change,
            ),
          ),
      ],
    ),
    const ComicDisclosure(
      title: 'About notifications',
      child: Text(
        'You can change these preferences at any time. Essential account messages are always sent.',
      ),
    ),
  ],
);
