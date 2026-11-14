/// Ordinary application layouts: the look supports work without extra motifs.
library;

import 'package:flutter/material.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

import '../kit.dart';
import 'papers.dart';

/// The six product layouts reviewed in the package's design contact sheet.
const kitOrdinaryScreens = [
  'form',
  'dialog',
  'list',
  'tabs',
  'cards',
  'settings',
  'checkout',
];

/// A complete page for one ordinary task, used by the design review and tests.
Widget kitOrdinaryScreen(String screen, Brightness brightness) => kitScreen(
  brightness: brightness,
  title: _title(screen),
  maxWindowWidth: _windowWidth(screen),
  sections: [kitOrdinaryContent(screen, openDialog: screen == 'dialog')],
);

/// A live collection of six everyday layouts in the example gallery.
Widget kitOrdinaryDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Everyday applications',
  maxWindowWidth: 1040,
  sections: [
    for (final screen in kitOrdinaryScreens)
      kitSection(_title(screen), children: [kitOrdinaryContent(screen)]),
  ],
);

// A window is as wide as what it holds, as Papers' are: a dialog's fields
// about 400, the list and its four columns 600.
double _windowWidth(String screen) => switch (screen) {
  'form' => 400,
  'settings' => 440,
  'checkout' => 480,
  'list' => 600,
  'dialog' => 720,
  'cards' => 1040,
  _ => 960,
};

String _title(String screen) => switch (screen) {
  'form' => 'Your details',
  'dialog' => 'Unsaved changes',
  'list' => 'Documents',
  'tabs' => 'Workspace',
  'cards' => 'Projects',
  'settings' => 'Settings',
  'checkout' => 'Order printed copies',
  _ => throw ArgumentError.value(screen, 'screen'),
};

/// Content for one ordinary task, shared by the gallery and responsive layout checks.
Widget kitOrdinaryContent(String screen, {bool openDialog = false}) => Align(
  alignment: AlignmentDirectional.topStart,
  child: ConstrainedBox(
    constraints: BoxConstraints(
      maxWidth: switch (screen) {
        'cards' => 1040,
        'tabs' => double.infinity,
        'dialog' => 840,
        _ => _windowWidth(screen),
      },
    ),
    child: switch (screen) {
      'form' => const KitDetailsForm(),
      'dialog' => _DialogPreview(initiallyOpen: openDialog),
      'list' => const _Documents(),
      'tabs' => _tabs(),
      'cards' => _cards(),
      'settings' => const KitSettingsPanel(),
      'checkout' => const KitPrintOrder(document: 'Project notes'),
      _ => const SizedBox.shrink(),
    },
  ),
);

/// Papers' list on its own: opening a document says so.
class _Documents extends StatefulWidget {
  const _Documents();
  @override
  State<_Documents> createState() => _DocumentsState();
}

class _DocumentsState extends State<_Documents> {
  final _view = KitDocumentsView();
  @override
  void dispose() {
    _view.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => KitDocuments(
    view: _view,
    onOpen: (name) => showRetroDesktopSnackBar(context, '$name opened'),
    onOrder: (name) =>
        showRetroDesktopSnackBar(context, 'Printed copies of $name'),
  );
}

class _DialogPreview extends StatefulWidget {
  const _DialogPreview({this.initiallyOpen = false});
  final bool initiallyOpen;
  @override
  State<_DialogPreview> createState() => _DialogPreviewState();
}

class _DialogPreviewState extends State<_DialogPreview> {
  String? result;
  @override
  void initState() {
    super.initState();
    if (widget.initiallyOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (mounted) await _open();
      });
    }
  }

  Future<void> _open() async {
    final next = await showRetroDesktopDialog<String>(
      context,
      builder: (context) => const RetroDesktopDialog(
        title: 'Save your changes?',
        message: 'Save your changes to Project notes before closing.',
        tone: RetroDesktopTone.warning,
        actions: [
          RetroDesktopDialogAction(
            'Keep editing',
            value: 'Back to your document',
          ),
          RetroDesktopDialogAction(
            'Save changes',
            value: 'Document saved',
            isDefaultAction: true,
          ),
        ],
      ),
    );
    if (mounted && next != null) setState(() => result = next);
  }

  @override
  Widget build(BuildContext context) => RetroDesktopColumn(
    gap: 16,
    children: [
      const RetroDesktopListTile(
        title: 'Project notes',
        subtitle: 'Edited just now',
      ),
      const Text('Meeting notes and next steps for the project.'),
      if (result != null) Text(result!),
      RetroDesktopButton(
        result == null ? 'Review changes' : 'Open dialog',
        onPressed: _open,
      ),
    ],
  );
}

Widget _tabs() => kitValue(
  0,
  (value, change) => RetroDesktopColumn(
    gap: 20,
    children: [
      RetroDesktopTabBar(
        tabs: const ['Recent', 'Shared', 'Archived'],
        selectedIndex: value,
        onChanged: change,
        // Each tab a list of its documents, Papers' rows: a 960 window
        // holding one line read as empty. The rows stand on the tab's own
        // panel, which is already their sunken ground: no well inside it.
        // Their own 12 inset carries most of the panel's keyline: 6 more puts
        // their icons on the tab words' line (16 stood them 10 past it). On
        // the panel they go unruled, as a Finder list's rows did: a rule from
        // the row's edge stood 10 before the icons, off the panel's line.
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 16),
          child: RetroDesktopColumn(
            children: [
              for (final (name, meta, icon) in switch (value) {
                0 => [
                  for (final p in kitPapers.take(4))
                    (p.name, '${p.kind} · ${p.changed}', p.icon),
                ],
                1 => const [
                  (
                    'Team handbook',
                    'Shared by Morgan Kim',
                    RetroDesktopGlyphs.fileText,
                  ),
                  (
                    'Meeting summary',
                    'Shared by Jamie Rivera',
                    RetroDesktopGlyphs.fileText,
                  ),
                  (
                    'Reading list',
                    'Shared by Alex Lee',
                    RetroDesktopGlyphs.listChecks,
                  ),
                ],
                _ => const [
                  (
                    'Last year\'s plan',
                    'Archived 12 March',
                    RetroDesktopGlyphs.listChecks,
                  ),
                  (
                    'Old handbook',
                    'Archived 3 February',
                    RetroDesktopGlyphs.fileText,
                  ),
                  (
                    'Spring research',
                    'Archived 20 January',
                    RetroDesktopGlyphs.notebook,
                  ),
                ],
              })
                RetroDesktopListTile(
                  title: name,
                  subtitle: meta,
                  leading: Icon(icon),
                  isFirst: true,
                ),
            ],
          ),
        ),
      ),
    ],
  ),
);

Widget _cards() => LayoutBuilder(
  builder: (context, room) => RetroDesktopGridOf(
    columns: room.maxWidth < 580
        ? 1
        : room.maxWidth < 880
        ? 2
        : 3,
    gap: 20,
    runGap: 20,
    children: [
      for (final card in const [
        ('Website refresh', 'Design and content', '4 documents'),
        ('Team handbook', 'Working together', '8 documents'),
        ('Product notes', 'Research and planning', '6 documents'),
        ('Launch checklist', 'Getting ready', '3 documents'),
        ('Customer interviews', 'What we learned', '5 documents'),
        ('Reference library', 'Useful resources', '12 documents'),
      ])
        RetroDesktopCard(
          title: card.$1,
          children: [
            Text(card.$2),
            Text(card.$3),
            kitAction(
              '${card.$1} opened',
              (press) => RetroDesktopButton('Open project', onPressed: press),
            ),
          ],
        ),
    ],
  ),
);
