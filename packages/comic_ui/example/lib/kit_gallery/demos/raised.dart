/// Panels and speech above a page, plus live controls that raise each surface.
library;

import 'package:material_ui/material_ui.dart';
import 'package:comic_ui/comic_ui.dart';

import '../kit.dart';

Widget kitRaisedDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Raised panels',
  sections: [
    kitSection('A decision', children: [kitSpecimenDialog()]),
    kitSection('A longer task', children: [kitSpecimenSheet()]),
    kitSection('A choice', children: [kitSpecimenMenu()]),
    kitSection('Choices as you type', children: [kitSpecimenAutocomplete()]),
    kitSection('A small explanation', children: [kitSpecimenTooltip()]),
    kitSection('An announcement', children: [kitSpecimenSnackBar()]),
    kitSection('A toast', children: [kitSpecimenToast()]),
    kitSection('Try them', children: [kitTryRaised()]),
  ],
);

/// Live controls that raise each surface for real: a toast, a dialog, a sheet, a menu, a tooltip and a snack bar, and a
/// page pushed over the gallery as an app's own route, which Comic's theme turns in a cut.
Widget kitTryRaised() => Builder(
  builder: (context) => Builder(
    builder: (context) => Wrap(
      // Keep the focus marks clear when the launch buttons wrap.
      spacing: ComicSpace.gap,
      runSpacing: ComicSpace.gap,
      children: [
        ComicButton(
          kitSay(context, 'Toast'),
          onPressed: () => showComicToast(
            context,
            kitSay(context, 'Link copied'),
            tone: ComicTone.success,
          ),
        ),
        ComicButton(
          kitSay(context, 'Dialog'),
          onPressed: () => showComicDialog<void>(
            context,
            builder: (context) => ComicDialog(
              title: kitSay(context, 'Keep this issue?'),
              message: kitSay(context, 'It will stay in your collection.'),
              // The same decision as the page's own: Later, then the confirming act last.
              actions: [
                ComicButton.text(
                  kitSay(context, 'Later'),
                  onPressed: () => Navigator.pop(context),
                ),
                ComicButton.filled(
                  kitSay(context, 'Keep'),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ),
        ComicButton(
          kitSay(context, 'Sheet'),
          onPressed: () => showComicBottomSheet<void>(
            context,
            builder: (_) => ComicBottomSheet(
              title: kitSay(context, 'Issue details'),
              child: Text(
                kitSay(context, 'A longer explanation belongs in this panel.'),
              ),
            ),
          ),
        ),
        ComicMenuAnchor<String>(
          items: [
            ComicMenuItem('save', kitSay(context, 'Save')),
            ComicMenuItem('share', kitSay(context, 'Share')),
          ],
          onSelected: (value) => kitFeedback(
            context,
            value == 'save'
                ? kitSay(context, 'Issue saved.')
                : kitSay(context, 'Share link copied.'),
          ),
          builder: (context, open) =>
              ComicButton(kitSay(context, 'Menu'), onPressed: open),
        ),
        ComicTooltip(
          message: kitSay(context, 'Save this issue to your collection'),
          child: Builder(
            builder: (anchor) => ComicButton(
              kitSay(context, 'Explain'),
              onPressed: () {
                final box = anchor.findRenderObject()! as RenderBox;
                showComicTooltip(
                  context,
                  message: kitSay(
                    context,
                    'Save this issue to your collection',
                  ),
                  anchor: box.localToGlobal(Offset.zero) & box.size,
                );
              },
            ),
          ),
        ),
        ComicButton(
          kitSay(context, 'Announcement'),
          onPressed: () => showComicSnackBar(
            context,
            kitSay(context, 'Issue saved'),
            actionLabel: kitSay(context, 'Undo'),
            onAction: () =>
                kitFeedback(context, kitSay(context, 'Save undone.')),
          ),
        ),
        ComicButton(
          kitSay(context, 'Page'),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (context) => ComicScaffold(
                topBar: ComicAppBar(title: kitSay(context, 'The second issue')),
                body: ComicSections(
                  children: [
                    ComicPanel(
                      caption: kitSay(context, 'Issue details'),
                      child: Text(
                        kitSay(context, 'Read it again whenever you like.'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  ),
);

/// A modal over a page: at least [height] tall, and as tall as [child] when its words grow (large text), so the
/// modal is never cut; [child] stands at [alignment].
Widget _raised(
  Widget child,
  double height, {
  AlignmentGeometry alignment = Alignment.center,
}) => SizedBox(
  width: double.infinity,
  child: ConstrainedBox(
    constraints: BoxConstraints(minHeight: height),
    child: Builder(
      builder: (context) => Stack(
        alignment: alignment,
        children: [
          // This page is inactive under the modal, like a route below a barrier.
          Positioned.fill(
            child: ExcludeSemantics(
              child: Semantics(
                enabled: false,
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    kitSay(context, 'Your collection\nIssue 12\nIssue 11'),
                  ),
                ),
              ),
            ),
          ),
          // The modal's screen: Ben-Day dots over the page, as a live modal draws it.
          Positioned.fill(
            child: ComicScreenScrim(
              animation: kAlwaysCompleteAnimation,
              ink: ComicTheme.of(context).colors.scrim,
            ),
          ),
          child,
        ],
      ),
    ),
  ),
);
Widget kitSpecimenDialog() => Builder(
  builder: (context) => kitState<String?>(
    null,
    (context, value, change) => _raised(
      ComicDialog(
        title: kitSay(context, 'Keep this issue?'),
        message: value ?? kitSay(context, 'Read it again whenever you like.'),
        actions: [
          ComicButton.text(
            kitSay(context, 'Later'),
            onPressed: () => change(kitSay(context, 'Saved for later.')),
          ),
          ComicButton.filled(
            kitSay(context, 'Keep'),
            onPressed: () =>
                change(kitSay(context, 'Issue kept in your collection.')),
          ),
        ],
      ),
      340,
    ),
  ),
);
Widget kitSpecimenSheet() => Builder(
  builder: (context) => kitState(
    true,
    (context, value, change) => value
        ? _raised(
            // A sheet rises from the foot and is as tall as what it holds: the page shows above it, under the scrim.
            ComicBottomSheet(
              title: kitSay(context, 'Issue details'),
              onClose: () => change(false),
              child: Text(
                kitSay(
                  context,
                  'A panel for the longer explanation, with room to read and a clear way back.',
                ),
              ),
            ),
            300,
            alignment: Alignment.bottomCenter,
          )
        : ComicButton(
            kitSay(context, 'Show details'),
            onPressed: () => change(true),
          ),
  ),
);
const _cities = [
  'Amsterdam',
  'Athens',
  'Barcelona',
  'Berlin',
  'Bologna',
  'Lisbon',
  'London',
  'Lyon',
  'Madrid',
  'Marseille',
  'Milan',
  'Paris',
  'Porto',
  'Prague',
  'Rome',
  'Vienna',
];

Widget kitSpecimenAutocomplete() => Builder(
  builder: (context) => ComicCombobox<String>(
    labelText: kitSay(context, 'City'),
    hintText: kitSay(context, 'Start typing a city'),
    helperText: kitSay(context, 'A city not on the list says so.'),
    options: [for (final city in _cities) kitSay(context, city)],
    onSelected: (city) => kitFeedback(context, '$city chosen.'),
  ),
);

Widget kitSpecimenMenu() => Builder(
  builder: (context) => Builder(
    builder: (context) => ComicMenu<String>(
      items: [
        ComicMenuItem('save', kitSay(context, 'Save this issue')),
        ComicMenuItem('share', kitSay(context, 'Share')),
        ComicMenuItem('print', kitSay(context, 'Print'), enabled: false),
      ],
      onSelected: (value) => kitFeedback(
        context,
        value == 'save'
            ? kitSay(context, 'Issue saved.')
            : kitSay(context, 'Share link copied.'),
      ),
    ),
  ),
);
Widget kitSpecimenTooltip() => Builder(
  builder: (context) =>
      ComicTooltipFace(message: kitSay(context, 'Save this issue')),
);
Widget kitSpecimenSnackBar() => Builder(
  builder: (context) => kitState(
    true,
    (context, value, change) => value
        ? ComicSnackBar(
            kitSay(context, 'Issue saved to your collection'),
            actionLabel: kitSay(context, 'Undo'),
            onAction: () => change(false),
            onDismiss: () => change(false),
          )
        : ComicButton.text(
            kitSay(context, 'Save again'),
            onPressed: () => change(true),
          ),
  ),
);

Widget kitSpecimenToast() => Builder(
  builder: (context) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: ComicToast(kitSay(context, 'Link copied'), tone: ComicTone.success),
  ),
);
