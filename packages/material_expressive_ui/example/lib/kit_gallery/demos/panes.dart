/// The panes group's demo: a scroll area and its scrollbar, two panes and
/// the drag handle between them, and the modal side sheet — each live.
library;

import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

import '../kit.dart';

/// The panes group's demo, in [brightness].
Widget kitPanesDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Panes',
  sections: const <Widget>[_Scroll(), _Split(), _SideSheet()],
);

class _Scroll extends StatefulWidget {
  const _Scroll();

  @override
  State<_Scroll> createState() => _ScrollState();
}

class _ScrollState extends State<_Scroll> {
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    return kitSection(
      'Scroll area · the scrollbar, and Tab then the arrows',
      children: <Widget>[
        SizedBox(
          height: 240,
          child: DecoratedBox(
            decoration: ShapeDecoration(
              color: t.colors.surfaceContainerLow,
              shape: t.shapes.medium,
            ),
            child: ExpressiveScrollArea(
              controller: _scroll,
              alwaysShown: true,
              semanticLabel: 'Release notes',
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.all(ExpressiveSpacing.s16),
                itemCount: 24,
                itemBuilder: (context, i) => Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: ExpressiveSpacing.s6,
                  ),
                  child: Text(
                    'Version 1.${24 - i}: smaller fixes and faster start-up.',
                    style: t.type.bodyMedium.copyWith(
                      color: t.colors.onSurface,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Split extends StatelessWidget {
  const _Split();

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    Widget pane(String title, String body, Color color) => DecoratedBox(
      decoration: ShapeDecoration(color: color, shape: t.shapes.large),
      child: Padding(
        padding: const EdgeInsets.all(ExpressiveSpacing.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: t.type.titleMedium.copyWith(color: t.colors.onSurface),
            ),
            const SizedBox(height: ExpressiveSpacing.s8),
            Flexible(
              child: Text(
                body,
                overflow: TextOverflow.fade,
                style: t.type.bodyMedium.copyWith(
                  color: t.colors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    return kitSection(
      'Resizable · drag the handle, or focus it and press the arrows',
      children: <Widget>[
        SizedBox(
          height: 220,
          child: ExpressiveResizable(
            initialFraction: 0.35,
            minFirst: 120,
            minSecond: 160,
            first: pane(
              'Folders',
              'Inbox, Drafts, Sent and Archive.',
              t.colors.surfaceContainerLow,
            ),
            second: pane(
              'Messages',
              'The folder chosen beside this pane lists its messages here.',
              t.colors.surfaceContainer,
            ),
          ),
        ),
      ],
    );
  }
}

Widget _filters(BuildContext context) {
  final t = context.expressiveTheme;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Text(
        'Show',
        style: t.type.titleSmall.copyWith(color: t.colors.onSurface),
      ),
      const SizedBox(height: ExpressiveSpacing.s8),
      ExpressiveCheckboxRow(
        label: 'Open orders',
        value: true,
        onChanged: (_) {},
      ),
      ExpressiveCheckboxRow(label: 'Shipped', value: false, onChanged: (_) {}),
      ExpressiveCheckboxRow(label: 'Refunded', value: false, onChanged: (_) {}),
    ],
  );
}

class _SideSheet extends StatelessWidget {
  const _SideSheet();

  @override
  Widget build(BuildContext context) => kitSection(
    'Side sheet · from the end edge over the scrim',
    children: <Widget>[
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: ExpressiveFilledButton.tonal(
          'Filters',
          onPressed: () => ExpressiveSheet.show<void>(
            context,
            title: 'Filters',
            builder: _filters,
            actions: <Widget>[
              Builder(
                builder: (context) => ExpressiveFilledButton(
                  'Apply',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              Builder(
                builder: (context) => ExpressiveOutlinedButton(
                  'Cancel',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: ExpressiveSpacing.s16),
      kitSpecimenSideSheetFilters(),
    ],
  );
}

/// The side sheet's panel standing: filters, Apply and Cancel at its foot.
Widget kitSpecimenSideSheetFilters() => SizedBox(
  width: 360,
  height: 420,
  child: ExpressiveSheet(
    title: 'Filters',
    onClose: () {},
    actions: <Widget>[
      ExpressiveFilledButton('Apply', onPressed: () {}),
      ExpressiveOutlinedButton('Cancel', onPressed: () {}),
    ],
    child: Builder(builder: _filters),
  ),
);
