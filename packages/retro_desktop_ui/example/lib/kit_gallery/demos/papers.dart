/// Papers: the look's own application, a documents workspace that is a
/// desktop. The menu bar across the top does its job (the app's menu, File,
/// Edit, View, Window); icons on the desk open windows; windows are as wide as
/// what they hold, two or three at once on a wide screen and one at a time on
/// a phone.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

import '../kit.dart';
// The demo art is the example's; a test or page that draws it reads it from there.
// ignore: avoid_relative_lib_imports
import '../../demo_art.dart';

/// The app's windows.
enum KitPapersWindow {
  /// The list of documents on the disk.
  documents,

  /// One document, opened.
  document,

  /// Your name and where new documents go.
  details,

  /// How the workspace behaves.
  settings,

  /// Printed copies of a document, posted to you.
  prints,

  /// What was deleted.
  bin,
}

/// What the example around the app gives it: the one way back to the
/// gallery, and day or night. Without it (in a test) neither shows.
class KitPapersHost extends InheritedWidget {
  /// Gives the app below it the way back and the night switch.
  const KitPapersHost({
    super.key,
    required this.onGallery,
    required this.night,
    required this.onNight,
    required super.child,
  });

  /// Leaves the app for the gallery.
  final VoidCallback onGallery;

  /// Whether it is night.
  final bool night;

  /// Changes day or night.
  final ValueChanged<bool> onNight;

  /// The nearest host, or null.
  static KitPapersHost? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<KitPapersHost>();

  @override
  bool updateShouldNotify(KitPapersHost old) =>
      old.night != night ||
      old.onGallery != onGallery ||
      old.onNight != onNight;
}

/// The app as a whole screen, with [front] the active window ([alone]: the
/// only one).
Widget kitPapersScreen(
  KitPapersWindow front,
  Brightness brightness, {
  bool alone = false,
}) => kitAppScreen(
  brightness: brightness,
  home: KitPapers(front: front, alone: alone),
);

/// One document on the disk.
typedef KitPaper = ({
  String name,
  String kind,
  IconData icon,
  int age,
  String changed,
  int bytes,
  String size,
  int pages,
  List<String> paragraphs,
});

/// The documents on the disk, in the order they were made.
const List<KitPaper> kitPapers = [
  (
    name: 'Project notes',
    kind: 'Document',
    icon: RetroDesktopGlyphs.fileText,
    age: 0,
    changed: 'Today, 09:14',
    bytes: 24576,
    size: '24 KB',
    pages: 2,
    paragraphs: [
      'The new filing plan starts on Monday. Each team keeps one folder for '
          'work in progress and one for what is finished.',
      'Morgan will send the printed handbook to the two new starters before '
          'the end of the month.',
    ],
  ),
  (
    name: 'Quarterly plan',
    kind: 'Checklist',
    icon: RetroDesktopGlyphs.listChecks,
    age: 1,
    changed: 'Yesterday, 16:40',
    bytes: 114688,
    size: '112 KB',
    pages: 4,
    paragraphs: [
      'Three goals for the quarter: one place for every document, a weekly '
          'review, and printed copies on request.',
    ],
  ),
  (
    name: 'Research log',
    kind: 'Notebook',
    icon: RetroDesktopGlyphs.notebook,
    age: 7,
    changed: '4 November',
    bytes: 317440,
    size: '310 KB',
    pages: 9,
    paragraphs: [
      'Interviews with six teams about how they keep their papers. Most keep '
          'two copies of everything and trust neither.',
    ],
  ),
  (
    name: 'Meeting summary',
    kind: 'Document',
    icon: RetroDesktopGlyphs.fileText,
    age: 9,
    changed: '2 November',
    bytes: 18432,
    size: '18 KB',
    pages: 1,
    paragraphs: [
      'Agreed: documents move to the shared disk by Friday. Questions go to '
          'Alex.',
    ],
  ),
  (
    name: 'Team handbook',
    kind: 'Document',
    icon: RetroDesktopGlyphs.fileText,
    age: 14,
    changed: '28 October',
    bytes: 1258291,
    size: '1.2 MB',
    pages: 36,
    paragraphs: [
      'How we work together: where things live, who to ask, and what to do on '
          'your first day.',
    ],
  ),
  (
    name: 'Reading list',
    kind: 'Checklist',
    icon: RetroDesktopGlyphs.listChecks,
    age: 21,
    changed: '21 October',
    bytes: 6144,
    size: '6 KB',
    pages: 1,
    paragraphs: ['Five books on keeping records, two of them out of print.'],
  ),
];

KitPaper _paper(String name) => kitPapers.firstWhere((p) => p.name == name);

/// A date as a phone's narrow column sets it: today's by its time, yesterday's
/// by its day.
String _shortDate(String changed) => changed.startsWith('Today, ')
    ? changed.substring('Today, '.length)
    : changed.split(',').first;

/// The documents list's state: which row is selected and how it sorts.
class KitDocumentsView extends ChangeNotifier {
  /// Starts on the document named first, sorted by name.
  KitDocumentsView([this._selected = 'Project notes']);

  String _selected;
  int _sort = 0;
  bool _ascending = true;

  /// The selected document's name.
  String get selected => _selected;

  /// The sorted column: name, kind, changed, size.
  int get sort => _sort;

  /// Whether it sorts smallest (or oldest, or A) first.
  bool get ascending => _ascending;

  /// Selects [name].
  void select(String name) {
    if (name == _selected) return;
    _selected = name;
    notifyListeners();
  }

  /// A head's press: by column [k]; again, the other way. Names and kinds
  /// start at A, dates and sizes at the newest and largest.
  void sortBy(int k) {
    if (k == _sort) {
      _ascending = !_ascending;
    } else {
      _sort = k;
      _ascending = k < 2;
    }
    notifyListeners();
  }

  /// The documents in this order.
  List<KitPaper> get rows {
    int compare(KitPaper a, KitPaper b) => switch (_sort) {
      1 => a.kind.compareTo(b.kind),
      // A smaller age is newer: oldest first is the larger age first.
      2 => b.age.compareTo(a.age),
      3 => a.bytes.compareTo(b.bytes),
      _ => a.name.compareTo(b.name),
    };
    final out = [...kitPapers]
      ..sort((a, b) {
        final c = compare(a, b);
        final d = c == 0 ? a.name.compareTo(b.name) : c;
        return _ascending ? d : -d;
      });
    return out;
  }
}

/// The documents window's content: the list in sorted columns, one row
/// selected, and at its foot the default "Open" with its ring. A double press
/// or Return opens; on a phone a tap does.
class KitDocuments extends StatelessWidget {
  /// The list of [view], opening with [onOpen] and ordering copies with
  /// [onOrder].
  const KitDocuments({
    super.key,
    required this.view,
    required this.onOpen,
    required this.onOrder,
  });

  /// Selection and sort.
  final KitDocumentsView view;

  /// Opens a document.
  final ValueChanged<String> onOpen;

  /// Orders printed copies of a document.
  final ValueChanged<String> onOrder;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: view,
    builder: (context, _) {
      final t = RetroDesktopTheme.of(context);
      final phone = !t.desk;
      final rows = view.rows;
      RetroDesktopListTableColumn column(int k, String label, double? width) =>
          RetroDesktopListTableColumn(
            label,
            width: width,
            sorted: view.sort == k,
            figures: k == 3,
            end: k == 3,
          );
      final list = RetroDesktopListTable(
        label: 'Documents',
        columns: [
          column(0, 'Name', null),
          if (!phone) column(1, 'Kind', 96),
          // As wide as its longest date, 'Yesterday, 16:40'.
          column(2, 'Changed', phone ? 104 : 148),
          if (!phone) column(3, 'Size', 76),
        ],
        ascending: view.ascending,
        onSort: (k) => view.sortBy(phone && k == 1 ? 2 : k),
        selected: rows.indexWhere((r) => r.name == view.selected),
        onSelected: (i) => view.select(rows[i].name),
        onOpen: (i) => onOpen(rows[i].name),
        rows: [
          for (final r in rows)
            RetroDesktopListTableRow(
              key: ValueKey(r.name),
              title: r.name,
              icon: r.icon,
              note: phone ? '${r.kind}, ${r.size}' : null,
              cells: [
                if (!phone) (r.kind, null),
                (phone ? _shortDate(r.changed) : r.changed, null),
                if (!phone) (r.size, null),
              ],
            ),
        ],
      );
      if (phone) return list;
      return RetroDesktopColumn(
        gap: 12,
        children: [
          list,
          _Buttons([
            RetroDesktopButton(
              'Order copies…',
              onPressed: () => onOrder(view.selected),
            ),
            RetroDesktopButton(
              'Open',
              isDefaultAction: true,
              onPressed: () => onOpen(view.selected),
            ),
          ]),
        ],
      );
    },
  );
}

/// Your details: the name on what you share and order, and where new
/// documents go. Label over field, "Cancel" beside the ringed default.
class KitDetailsForm extends StatefulWidget {
  /// The form; [onDone] runs after either button.
  const KitDetailsForm({super.key, this.onDone});

  /// Closes the window it stands in, if any.
  final VoidCallback? onDone;

  @override
  State<KitDetailsForm> createState() => _KitDetailsFormState();
}

class _KitDetailsFormState extends State<KitDetailsForm> {
  var _where = 'local';

  void _done(String message) {
    showRetroDesktopSnackBar(context, message);
    widget.onDone?.call();
  }

  @override
  Widget build(BuildContext context) => RetroDesktopColumn(
    gap: 16,
    children: [
      Text(
        'Your name goes on the documents you share and on the copies you '
        'order.',
        style: context.retroDesktopTheme.type.meta,
      ),
      const RetroDesktopTextField(label: 'Name', initial: 'Alex Lee'),
      const RetroDesktopTextField(
        label: 'Email address',
        initial: 'alex@example.com',
        keyboardType: TextInputType.emailAddress,
      ),
      RetroDesktopSelect<String>(
        label: 'Save new documents to',
        value: _where,
        options: const [
          RetroDesktopOption('local', 'This computer'),
          RetroDesktopOption('shared', 'The shared disk'),
        ],
        onChanged: (value) => setState(() => _where = value),
      ),
      _Buttons([
        // The look's one secondary button is the push button.
        RetroDesktopButton(
          'Cancel',
          onPressed: () => _done('Your details are as they were'),
        ),
        RetroDesktopButton(
          'Save',
          isDefaultAction: true,
          onPressed: () => _done('Your details are saved'),
        ),
      ]),
    ],
  );
}

/// How the workspace behaves: checkboxes in named groups, which take effect
/// as they change, so the window has no buttons.
class KitSettingsPanel extends StatelessWidget {
  /// The settings.
  const KitSettingsPanel({super.key});

  @override
  Widget build(BuildContext context) => RetroDesktopColumn(
    gap: 16,
    children: [
      RetroDesktopGroupBox(
        title: 'Documents',
        child: RetroDesktopColumn(
          children: [
            kitValue(
              true,
              (value, change) => RetroDesktopCheckRow(
                label: 'Save as I type',
                note: 'Every change is kept as you make it.',
                value: value,
                onChanged: change,
              ),
            ),
            kitValue(
              false,
              (value, change) => RetroDesktopCheckRow(
                label: 'Keep a copy on this computer',
                note: 'Open your documents without a connection.',
                value: value,
                onChanged: change,
              ),
            ),
          ],
        ),
      ),
      RetroDesktopGroupBox(
        title: 'Notices',
        child: kitValue(
          true,
          (value, change) => RetroDesktopCheckRow(
            label: 'Tell me when a shared document changes',
            value: value,
            onChanged: change,
          ),
        ),
      ),
      RetroDesktopDisclosure(
        title: 'Advanced',
        child: kitValue(
          false,
          (value, change) => RetroDesktopCheckRow(
            label: 'Send a report when something goes wrong',
            note: 'It holds no document, only what failed.',
            value: value,
            onChanged: change,
          ),
        ),
      ),
    ],
  );
}

/// Printed copies of a document, bound and posted: the order as a table with
/// the amount due set apart at its foot, where they go, the postage and how
/// you pay.
class KitPrintOrder extends StatefulWidget {
  /// An order for copies of [document]; [onDone] runs after either button.
  const KitPrintOrder({super.key, required this.document, this.onDone});

  /// The document's name.
  final String document;

  /// Closes the window it stands in, if any.
  final VoidCallback? onDone;

  @override
  State<KitPrintOrder> createState() => _KitPrintOrderState();
}

class _KitPrintOrderState extends State<KitPrintOrder> {
  var _copies = 2;
  var _post = 'standard';
  var _pay = 'card';

  static String _money(int cents) =>
      '\$${cents ~/ 100}.${(cents % 100).toString().padLeft(2, '0')}';

  void _done(String message) {
    showRetroDesktopSnackBar(context, message);
    widget.onDone?.call();
  }

  @override
  Widget build(BuildContext context) {
    final doc = _paper(widget.document);
    // A bound copy costs a base and a little a page.
    final each = 300 + doc.pages * 50;
    final postage = _post == 'standard' ? 400 : 1200;
    return RetroDesktopColumn(
      gap: 16,
      children: [
        RetroDesktopTable(
          columns: const [
            RetroDesktopTableColumn('Item', flex: 3),
            RetroDesktopTableColumn(
              'Copies',
              width: 76,
              figures: true,
              end: true,
            ),
            RetroDesktopTableColumn(
              'Price',
              width: 72,
              figures: true,
              end: true,
            ),
          ],
          rows: [
            ['${doc.name}, bound', '$_copies', _money(each * _copies)],
            [
              _post == 'standard' ? 'Postage, standard' : 'Postage, express',
              '',
              _money(postage),
            ],
          ],
          due: ('Amount due', _money(each * _copies + postage)),
        ),
        RetroDesktopSelect<int>(
          label: 'Copies',
          value: _copies,
          options: [for (var n = 1; n <= 5; n++) RetroDesktopOption(n, '$n')],
          onChanged: (value) => setState(() => _copies = value),
        ),
        // The name and the address in one field, as a label is written: two
        // fields ran the form past a 900 desk under two windows and cut its
        // buttons, and side by side they left the window's keylines.
        const RetroDesktopTextField(
          label: 'Deliver to',
          initial: 'Alex Lee, 12 Harbour Street, Leith',
        ),
        RetroDesktopRadioGroup<String>(
          label: 'Postage',
          value: _post,
          onChanged: (value) => setState(() => _post = value),
          options: const [
            RetroDesktopRadio('standard', 'Standard, in 3 to 5 days, \$4.00'),
            RetroDesktopRadio('express', 'Express, the next day, \$12.00'),
          ],
        ),
        RetroDesktopSelect<String>(
          label: 'Pay with',
          value: _pay,
          options: const [
            RetroDesktopOption('card', 'The card ending 4242'),
            RetroDesktopOption('invoice', 'An invoice, due in 30 days'),
          ],
          onChanged: (value) => setState(() => _pay = value),
        ),
        _Buttons([
          RetroDesktopButton(
            'Cancel',
            onPressed: () => _done('No copies ordered'),
          ),
          RetroDesktopButton(
            'Place order',
            isDefaultAction: true,
            onPressed: () => _done('Copies ordered: they arrive by post'),
          ),
        ]),
      ],
    );
  }
}

/// A window's buttons at its foot, the default last and on the trailing
/// keyline, in the period's order; on a narrow window with large text they
/// break onto a second line rather than run out.
class _Buttons extends StatelessWidget {
  const _Buttons(this.children);
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.centerEnd,
    child: Wrap(
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: children,
    ),
  );
}

/// The app: the menu bar, the desk with its icons, and the open windows.
class KitPapers extends StatefulWidget {
  /// Papers, with [front] the active window; [alone]: the only one open.
  const KitPapers({
    super.key,
    this.front = KitPapersWindow.documents,
    this.alone = false,
  });

  /// The window in front when the app opens.
  final KitPapersWindow front;

  /// Whether it opens with no other window.
  final bool alone;

  @override
  State<KitPapers> createState() => _KitPapersState();
}

class _KitPapersState extends State<KitPapers> {
  // Back to front: the last is the active window.
  late final List<KitPapersWindow> _open = switch (widget.front) {
    final w when widget.alone => [w],
    KitPapersWindow.documents => [
      KitPapersWindow.document,
      KitPapersWindow.documents,
    ],
    KitPapersWindow.document => [
      KitPapersWindow.documents,
      KitPapersWindow.document,
    ],
    final w => [KitPapersWindow.documents, KitPapersWindow.document, w],
  };
  final _view = KitDocumentsView();
  var _opened = 'Project notes';
  var _ordering = 'Project notes';
  String? _icon;

  @override
  void dispose() {
    _view.dispose();
    super.dispose();
  }

  void _front(KitPapersWindow w) {
    if (_open.isNotEmpty && _open.last == w) return;
    setState(() {
      _open
        ..remove(w)
        ..add(w);
    });
  }

  void _close(KitPapersWindow w) => setState(() => _open.remove(w));

  void _openDocument(String name) {
    _view.select(name);
    setState(() => _opened = name);
    _front(KitPapersWindow.document);
  }

  void _order(String name) {
    setState(() => _ordering = name);
    _front(KitPapersWindow.prints);
  }

  static String _title(KitPapersWindow w, String opened) => switch (w) {
    KitPapersWindow.documents => 'Documents',
    KitPapersWindow.document => opened,
    KitPapersWindow.details => 'Your details',
    KitPapersWindow.settings => 'Settings',
    KitPapersWindow.prints => 'Order printed copies',
    KitPapersWindow.bin => 'Bin',
  };

  static IconData _glyph(KitPapersWindow w) => switch (w) {
    KitPapersWindow.documents => RetroDesktopGlyphs.folder,
    KitPapersWindow.document => RetroDesktopGlyphs.fileText,
    KitPapersWindow.details => RetroDesktopGlyphs.person,
    KitPapersWindow.settings => RetroDesktopGlyphs.key,
    KitPapersWindow.prints => RetroDesktopGlyphs.notebook,
    KitPapersWindow.bin => RetroDesktopGlyphs.delete,
  };

  // A window is as wide as what it holds: the list and its four columns, a
  // page to read, a dialog's fields.
  static double _width(KitPapersWindow w) => switch (w) {
    KitPapersWindow.documents => 600,
    KitPapersWindow.document => 460,
    // 440, not 400: a step in from the document (460) at 400 its end stood exactly on the document's, and the two
    // windows read as one edge.
    KitPapersWindow.details => 440,
    KitPapersWindow.settings => 440,
    KitPapersWindow.prints => 480,
    KitPapersWindow.bin => 320,
  };

  Widget _window(KitPapersWindow w, {VoidCallback? onClose}) {
    final doc = _paper(_opened);
    return RetroDesktopWindow(
      key: ValueKey('papers-window/${w.name}'),
      title: _title(w, _opened),
      icon: _glyph(w),
      onClose: onClose ?? () => _close(w),
      info: w == KitPapersWindow.documents
          ? '${kitPapers.length} documents'
          : null,
      infoEnd: w == KitPapersWindow.documents ? '1.2 GB available' : null,
      status: switch (w) {
        KitPapersWindow.document => [
          '*${doc.pages}* ${doc.pages == 1 ? 'page' : 'pages'}',
          doc.size,
        ],
        KitPapersWindow.settings => const ['Changes are kept as you make them'],
        _ => const [],
      },
      statusAction: w == KitPapersWindow.document
          ? RetroDesktopButton(
              'Order copies…',
              size: RetroDesktopButtonSize.small,
              onPressed: () => _order(_opened),
            )
          : null,
      child: switch (w) {
        KitPapersWindow.documents => KitDocuments(
          view: _view,
          onOpen: _openDocument,
          onOrder: _order,
        ),
        KitPapersWindow.document => RetroDesktopDocument(
          key: ValueKey(doc.name),
          path: const ['Documents'],
          title: doc.name,
          meta: [('Kind', doc.kind), ('Changed', doc.changed)],
          paragraphs: doc.paragraphs,
        ),
        KitPapersWindow.details => KitDetailsForm(
          onDone: () => _close(KitPapersWindow.details),
        ),
        KitPapersWindow.settings => const KitSettingsPanel(),
        KitPapersWindow.prints => KitPrintOrder(
          key: ValueKey(_ordering),
          document: _ordering,
          onDone: () => _close(KitPapersWindow.prints),
        ),
        KitPapersWindow.bin => const RetroDesktopEmpty(
          title: 'The bin is empty',
          body: 'What you delete waits here for 30 days.',
          art: RetroDesktopDeskArt(RetroDesktopDeskMark.bin),
        ),
      },
    );
  }

  List<DesignMenuEntry> _menus(KitPapersHost? host) {
    final front = _open.isEmpty ? null : _open.last;
    DesignMenuEntry sort(int k, String label) => DesignMenuEntry(
      label: label,
      checked: _view.sort == k,
      onPressed: () => setState(() => _view.sortBy(k)),
    );
    return [
      DesignMenuEntry(
        label: 'Papers',
        children: [
          DesignMenuEntry(
            label: 'About Papers',
            onPressed: () => showRetroDesktopSnackBar(
              context,
              'Papers keeps your documents in one place',
            ),
          ),
          const DesignMenuEntry.divider(),
          DesignMenuEntry(
            label: 'Your details…',
            onPressed: () => _front(KitPapersWindow.details),
          ),
          DesignMenuEntry(
            label: 'Settings…',
            shortcut: 'Ctrl+,',
            onPressed: () => _front(KitPapersWindow.settings),
          ),
        ],
      ),
      DesignMenuEntry(
        label: 'File',
        children: [
          DesignMenuEntry(
            label: 'Open',
            shortcut: 'Ctrl+O',
            onPressed: () => _openDocument(_view.selected),
          ),
          DesignMenuEntry(
            label: 'Close window',
            shortcut: 'Ctrl+W',
            onPressed: front == null ? null : () => _close(front),
          ),
          const DesignMenuEntry.divider(),
          DesignMenuEntry(
            label: 'Order printed copies…',
            shortcut: 'Ctrl+P',
            onPressed: () => _order(_view.selected),
          ),
        ],
      ),
      const DesignMenuEntry(
        label: 'Edit',
        // Nothing is chosen, so the edit commands have no onPressed: unavailable.
        children: [
          DesignMenuEntry(label: 'Undo', shortcut: 'Ctrl+Z'),
          DesignMenuEntry.divider(),
          DesignMenuEntry(label: 'Cut', shortcut: 'Ctrl+X'),
          DesignMenuEntry(label: 'Copy', shortcut: 'Ctrl+C'),
          DesignMenuEntry(label: 'Paste', shortcut: 'Ctrl+V'),
        ],
      ),
      DesignMenuEntry(
        label: 'View',
        children: [
          sort(0, 'By name'),
          sort(1, 'By kind'),
          sort(2, 'By date changed'),
          sort(3, 'By size'),
          if (host != null) ...[
            const DesignMenuEntry.divider(),
            DesignMenuEntry(
              label: 'Night',
              checked: host.night,
              onPressed: () => host.onNight(!host.night),
            ),
          ],
        ],
      ),
      DesignMenuEntry(
        label: 'Window',
        children: [
          for (final w in KitPapersWindow.values)
            DesignMenuEntry(
              label: _title(w, _opened),
              checked: front == w,
              onPressed: () => w == KitPapersWindow.prints
                  ? _order(_view.selected)
                  : _front(w),
            ),
        ],
      ),
    ];
  }

  Widget _icons({required bool rail}) {
    Widget icon(String name, Widget art, VoidCallback open) =>
        RetroDesktopDeskIcon(
          name,
          art: art,
          selected: _icon == name,
          onPressed: () => setState(() => _icon = name),
          onOpen: () {
            setState(() => _icon = name);
            open();
          },
        );
    final documents = icon(
      'Documents',
      const RetroDesktopDeskArt(RetroDesktopDeskMark.disk),
      () => _front(KitPapersWindow.documents),
    );
    final notes = icon(
      'Project notes',
      RetroDesktopFilePageArt(selected: _icon == 'Project notes'),
      () => _openDocument('Project notes'),
    );
    final bin = icon(
      'Bin',
      const RetroDesktopDeskArt(RetroDesktopDeskMark.bin),
      () => _front(KitPapersWindow.bin),
    );
    if (!rail) {
      return Wrap(
        alignment: WrapAlignment.center,
        spacing: 24,
        runSpacing: 16,
        children: [documents, notes, bin],
      );
    }
    return Column(
      children: [
        documents,
        const SizedBox(height: 20),
        notes,
        const Spacer(),
        bin,
      ],
    );
  }

  Widget _desk(BuildContext context) => LayoutBuilder(
    builder: (context, room) {
      const margin = 24.0, rail = 96.0;
      final reach = room.maxWidth - rail - margin;
      // The list stands at the desk's start; every other window opens
      // beside it, each new one a step down and in from the last, as
      // windows stacked on a desk do. A step is a whole title bar and its
      // rim: the window behind shows its title whole, never words cut in
      // half by the bar in front.
      final chrome = RetroDesktopTheme.of(context).type.chrome;
      final line = MediaQuery.textScalerOf(context)
          .scale((chrome.fontSize ?? 14) * (chrome.height ?? 1.2));
      // A title bar keeps a pointer's reach (44 on a desk, 48 to a
      // finger) or its words and 8, whichever is taller; Chisel's rim stands
      // above it, 4 more, and a gap of 8 below.
      const titleReach = 48.0;
      final cascade = ((titleReach > line + 8 ? titleReach : line + 8) + 12)
          .ceilToDouble();
      var step = 0;
      final placed = <Widget>[];
      final places = <(KitPapersWindow, double, double, double)>[];
      for (final w in _open) {
        final width = _width(w);
        final double start, top;
        if (w == KitPapersWindow.documents) {
          start = margin;
          top = margin;
        } else if (w == KitPapersWindow.bin) {
          start = (reach - width).clamp(margin, double.infinity);
          top = (room.maxHeight - 260).clamp(margin, double.infinity);
        } else {
          final beside = margin + _width(KitPapersWindow.documents) + margin;
          start = (beside + cascade * step).clamp(margin, reach - width);
          top = margin + cascade * step;
          step++;
        }
        final active = w == _open.last;
        places.add((w, start, top, width));
        placed.add(
          LayoutId(
            key: ValueKey('papers/${w.name}'),
            id: w,
            child: Listener(
              onPointerDown: (_) => _front(w),
              child: RetroDesktopWindowScope(
                active: active,
                compact: false,
                child: _window(w),
              ),
            ),
          ),
        );
      }
      return Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _icon = null),
            ),
          ),
          PositionedDirectional(
            top: 16,
            end: 6,
            bottom: 16,
            width: 84,
            child: _icons(rail: true),
          ),
          Positioned.fill(
            child: CustomMultiChildLayout(
              delegate: _DeskWindows(
                places,
                step: cascade,
                rtl: Directionality.of(context) == TextDirection.rtl,
              ),
              children: placed,
            ),
          ),
        ],
      );
    },
  );

  Widget _phone(BuildContext context) {
    if (_open.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 24, 12, 24),
        child: Align(
          alignment: Alignment.topCenter,
          child: _icons(rail: false),
        ),
      );
    }
    final w = _open.last;
    return SingleChildScrollView(
      key: ValueKey('papers-phone/${w.name}'),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
      child: RetroDesktopWindowScope(
        active: true,
        compact: true,
        child: _window(w),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    final host = KitPapersHost.maybeOf(context);
    final front = _open.isEmpty ? null : _open.last;
    void key(
      LogicalKeyboardKey k,
      VoidCallback run,
      Map<ShortcutActivator, VoidCallback> into,
    ) {
      into[SingleActivator(k, control: true)] = run;
      into[SingleActivator(k, meta: true)] = run;
    }

    final keys = <ShortcutActivator, VoidCallback>{};
    key(LogicalKeyboardKey.keyO, () => _openDocument(_view.selected), keys);
    key(LogicalKeyboardKey.keyP, () => _order(_view.selected), keys);
    key(LogicalKeyboardKey.comma, () => _front(KitPapersWindow.settings), keys);
    if (front != null) key(LogicalKeyboardKey.keyW, () => _close(front), keys);
    return CallbackShortcuts(
      bindings: keys,
      child: Focus(
        autofocus: true,
        child: RetroDesktopScaffold(
          fullBleed: true,
          scroll: false,
          topBar: ListenableBuilder(
            listenable: _view,
            builder: (context, _) => RetroDesktopMenuBar(
              label: 'Papers',
              // On a phone the titles and the way back need the mark's room.
              leading: t.desk ? const RetroDesktopSystemMark() : null,
              menus: _menus(host),
              // The one way back to the gallery the app stands in: a small push button, the gallery's own control
              // and not one of the app's menus (a quiet one read as a grey pill in the bar).
              trailing: host == null
                  ? null
                  : RetroDesktopButton(
                      'Gallery',
                      size: RetroDesktopButtonSize.small,
                      onPressed: host.onGallery,
                    ),
            ),
          ),
          body: t.desk ? _desk(context) : _phone(context),
        ),
      ),
    );
  }
}

/// The desk's windows, back to front, each at its start and top and as tall
/// as it holds. One stepped in front of another reaches at least a step past
/// that one's foot, as its head stands a step under that one's head: no edge
/// of it crosses the words in the other's foot (a Settings window over a
/// document cut its "Order copies…" in half).
class _DeskWindows extends MultiChildLayoutDelegate {
  _DeskWindows(this.places, {required this.step, required this.rtl});

  /// Each window with its start, top and width.
  final List<(KitPapersWindow, double, double, double)> places;
  final double step;
  final bool rtl;

  @override
  void performLayout(Size size) {
    final laid = <Rect>[];
    for (final (w, start, top, width) in places) {
      if (!hasChild(w)) continue;
      final left = rtl ? size.width - start - width : start;
      var least = 0.0;
      for (final r in laid) {
        final across = r.left < left + width && left < r.right;
        if (across && r.bottom > top && r.bottom + step - top > least) {
          least = r.bottom + step - top;
        }
      }
      final room = size.height - top;
      final height = layoutChild(
        w,
        BoxConstraints(
          minWidth: width,
          maxWidth: width,
          minHeight: least < room ? least : (room > 0 ? room : 0),
        ),
      ).height;
      positionChild(w, Offset(left, top));
      laid.add(Rect.fromLTWH(left, top, width, height));
    }
  }

  @override
  bool shouldRelayout(_DeskWindows old) {
    if (old.step != step || old.rtl != rtl) return true;
    if (old.places.length != places.length) return true;
    for (var i = 0; i < places.length; i++) {
      if (old.places[i] != places[i]) return true;
    }
    return false;
  }
}
