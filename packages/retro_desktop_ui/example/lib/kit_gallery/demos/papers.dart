/// Papers: the look's own application, a documents workspace that is a
/// desktop. The menu bar across the top does its job (the app's menu, File,
/// Edit, View, Window); icons on the desk open windows; windows are as wide as
/// what they hold, two or three at once on a wide screen and one at a time on
/// a phone.
library;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

import '../kit.dart';
import 'papers_words.dart';
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

/// A moment the app can open on, so a link shows it: a search typed, a
/// change not saved yet, an order that failed.
enum KitPapersMoment {
  /// The app at rest.
  none,

  /// "list" typed in the documents' Find field: two of six match.
  search,

  /// Your details changed, and the window asked to close: save first?
  unsaved,

  /// An order for copies that could not be sent: try again?
  failedOrder,
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
/// only one), opening on [moment], reading [direction] (else the example's
/// choice). Right to left it speaks Hebrew, the look's own words (Cancel,
/// Clear, Close) with it.
Widget kitPapersScreen(
  KitPapersWindow front,
  Brightness brightness, {
  bool alone = false,
  KitPapersMoment moment = KitPapersMoment.none,
  TextDirection? direction,
}) => kitAppScreen(
  brightness: brightness,
  direction: direction,
  words: (direction ?? kitShownDirection) == TextDirection.rtl
      ? const [KitPapersHebrewDesignWords.delegate]
      : null,
  home: KitPapers(front: front, alone: alone, moment: moment),
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

/// The documents list's state: which row is selected, how it sorts and what
/// the Find field holds.
class KitDocumentsView extends ChangeNotifier {
  /// Starts on the document named first, sorted by name, [query] found.
  KitDocumentsView([this._selected = 'Project notes', String query = ''])
    : find = TextEditingController(text: query) {
    find.addListener(_found);
    _found();
  }

  String _selected;
  int _sort = 0;
  bool _ascending = true;

  /// The Find field's words: a document shows when its name or kind holds
  /// them.
  final TextEditingController find;

  /// The Find field's focus, which File > Find… moves to.
  final FocusNode findFocus = FocusNode(debugLabel: 'Find a document');

  var _query = '';

  void _found() {
    final q = find.text.trim().toLowerCase();
    if (q == _query) return;
    _query = q;
    // A selection the search hides moves to the first that shows.
    final shown = rows;
    if (shown.isNotEmpty && !shown.any((r) => r.name == _selected)) {
      _selected = shown.first.name;
    }
    notifyListeners();
  }

  /// What the Find field holds, trimmed and in lower case; empty: all.
  String get query => _query;

  /// Whether the list reads in Hebrew: names and kinds sort by their Hebrew.
  /// Find matches either language.
  bool hebrew = false;

  String _shown(String english) => hebrew ? papersHebrewFor(english) : english;

  @override
  void dispose() {
    find.dispose();
    findFocus.dispose();
    super.dispose();
  }

  /// The selected document's name.
  String get selected => _selected;

  /// The current document while it is visible in the filtered list.
  String? get visibleSelection =>
      rows.any((row) => row.name == _selected) ? _selected : null;

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

  /// The documents the Find field leaves, in this order.
  List<KitPaper> get rows {
    bool holds(String english) =>
        english.toLowerCase().contains(_query) ||
        papersHebrewFor(english).contains(_query);
    bool shows(KitPaper p) => _query.isEmpty || holds(p.name) || holds(p.kind);
    int byName(KitPaper a, KitPaper b) =>
        _shown(a.name).compareTo(_shown(b.name));
    int compare(KitPaper a, KitPaper b) => switch (_sort) {
      1 => _shown(a.kind).compareTo(_shown(b.kind)),
      // A smaller age is newer: oldest first is the larger age first.
      2 => b.age.compareTo(a.age),
      3 => a.bytes.compareTo(b.bytes),
      _ => byName(a, b),
    };
    final out = [...kitPapers.where(shows)]
      ..sort((a, b) {
        final c = compare(a, b);
        final d = c == 0 ? byName(a, b) : c;
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
      final say = context.say;
      final selected = rows.indexWhere((row) => row.name == view.selected);
      final list = RetroDesktopListTable(
        label: say('Documents'),
        columns: [
          column(0, say('Name'), null),
          if (!phone) column(1, say('Kind'), 96),
          // As wide as its longest date, 'Yesterday, 16:40'.
          column(2, say('Changed'), phone ? 104 : 148),
          if (!phone) column(3, say('Size'), 76),
        ],
        ascending: view.ascending,
        onSort: (k) => view.sortBy(phone && k == 1 ? 2 : k),
        selected: selected < 0 ? null : selected,
        onSelected: (i) => view.select(rows[i].name),
        onOpen: (i) => onOpen(rows[i].name),
        rows: [
          for (final r in rows)
            RetroDesktopListTableRow(
              key: ValueKey(r.name),
              title: say(r.name),
              icon: r.icon,
              note: phone ? '${say(r.kind)}, ${r.size}' : null,
              cells: [
                if (!phone) (say(r.kind), null),
                (say(phone ? _shortDate(r.changed) : r.changed), null),
                if (!phone) (r.size, null),
              ],
            ),
        ],
      );
      final find = RetroDesktopSearchField(
        hint: say('Find a document'),
        name: say('Find a document'),
        controller: view.find,
        focusNode: view.findFocus,
      );
      // Nothing found: the list's place says so, and how to find more.
      final shown = rows.isNotEmpty || view.query.isEmpty
          ? list
          : RetroDesktopEmpty(
              title: context.papersHebrew
                  ? 'אין מסמכים שתואמים ל״${view.find.text.trim()}״'
                  : 'No documents match “${view.find.text.trim()}”',
              body: say(
                'Check the spelling, or look for a kind: document, '
                'checklist or notebook.',
              ),
            );
      if (phone) {
        return RetroDesktopColumn(gap: 12, children: [find, shown]);
      }
      final some = rows.isNotEmpty;
      return RetroDesktopColumn(
        gap: 12,
        children: [
          find,
          shown,
          _Buttons([
            RetroDesktopButton(
              say('Order copies…'),
              onPressed: some ? () => onOrder(view.selected) : null,
            ),
            RetroDesktopButton(
              say('Open'),
              isDefaultAction: true,
              onPressed: some ? () => onOpen(view.selected) : null,
            ),
          ]),
        ],
      );
    },
  );
}

/// The contact details Papers saves for the session.
typedef KitContactDetails = ({String name, String email, String location});

const _defaultContact = (
  name: 'Alex Lee',
  email: 'alex@example.com',
  location: 'local',
);

/// Your details: the name on what you share and order, and where new
/// documents go. Label over field, "Cancel" beside the ringed default.
class KitDetailsForm extends StatefulWidget {
  /// Edits [details] and reports changes before the user saves or cancels.
  const KitDetailsForm({
    super.key,
    this.details = _defaultContact,
    this.onChanged,
    this.onSave,
    this.onCancel,
  });

  /// The values displayed when the form opens.
  final KitContactDetails details;

  /// Called whenever a field changes.
  final ValueChanged<KitContactDetails>? onChanged;

  /// Called when Save is selected.
  final VoidCallback? onSave;

  /// Called when Cancel is selected.
  final VoidCallback? onCancel;

  @override
  State<KitDetailsForm> createState() => _KitDetailsFormState();
}

class _KitDetailsFormState extends State<KitDetailsForm> {
  late var _draft = widget.details;

  void _change({String? name, String? email, String? location}) {
    setState(
      () => _draft = (
        name: name ?? _draft.name,
        email: email ?? _draft.email,
        location: location ?? _draft.location,
      ),
    );
    widget.onChanged?.call(_draft);
  }

  void _done(bool save) {
    showRetroDesktopSnackBar(
      context,
      context.say(
        save ? 'Your details are saved' : 'Your details are as they were',
      ),
    );
    (save ? widget.onSave : widget.onCancel)?.call();
  }

  @override
  Widget build(BuildContext context) {
    final say = context.say;
    return RetroDesktopColumn(
      gap: 16,
      children: [
        Text(
          say(
            'Your name goes on the documents you share and on the copies you '
            'order.',
          ),
          style: context.retroDesktopTheme.type.meta,
        ),
        RetroDesktopTextField(
          label: say('Name'),
          initial: say(widget.details.name),
          onChanged: (name) => _change(name: name),
        ),
        RetroDesktopTextField(
          label: say('Email address'),
          initial: widget.details.email,
          keyboardType: TextInputType.emailAddress,
          onChanged: (email) => _change(email: email),
        ),
        RetroDesktopSelect<String>(
          label: say('Save new documents to'),
          value: _draft.location,
          options: [
            RetroDesktopOption('local', say('This computer')),
            RetroDesktopOption('shared', say('The shared disk')),
          ],
          onChanged: (value) => _change(location: value),
        ),
        Visibility(
          visible:
              RetroDesktopTheme.of(context).desk ||
              (ModalRoute.isCurrentOf(context) ?? true),
          maintainSize: true,
          maintainState: true,
          maintainAnimation: true,
          child: _Buttons([
            RetroDesktopButton(say('Cancel'), onPressed: () => _done(false)),
            RetroDesktopButton(
              say('Save'),
              isDefaultAction: true,
              onPressed: () => _done(true),
            ),
          ]),
        ),
      ],
    );
  }
}

/// How the workspace behaves: checkboxes in named groups, which take effect
/// as they change, so the window has no buttons.
class KitSettingsPanel extends StatelessWidget {
  /// The settings.
  const KitSettingsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final say = context.say;
    return RetroDesktopColumn(
      gap: 16,
      children: [
        RetroDesktopGroupBox(
          title: say('Documents'),
          child: RetroDesktopColumn(
            children: [
              kitValue(
                true,
                (value, change) => RetroDesktopCheckRow(
                  label: say('Save as I type'),
                  note: say('Every change is kept as you make it.'),
                  value: value,
                  onChanged: change,
                ),
              ),
              kitValue(
                false,
                (value, change) => RetroDesktopCheckRow(
                  label: say('Keep a copy on this computer'),
                  note: say('Open your documents without a connection.'),
                  value: value,
                  onChanged: change,
                ),
              ),
            ],
          ),
        ),
        RetroDesktopGroupBox(
          title: say('Notices'),
          child: kitValue(
            true,
            (value, change) => RetroDesktopCheckRow(
              label: say('Tell me when a shared document changes'),
              value: value,
              onChanged: change,
            ),
          ),
        ),
        RetroDesktopDisclosure(
          title: say('Advanced'),
          child: kitValue(
            false,
            (value, change) => RetroDesktopCheckRow(
              label: say('Send a report when something goes wrong'),
              note: say('It holds no document, only what failed.'),
              value: value,
              onChanged: change,
            ),
          ),
        ),
      ],
    );
  }
}

/// Printed copies of a document, bound and posted: the order as a table with
/// the amount due set apart at its foot, where they go, the postage and how
/// you pay.
class KitPrintOrder extends StatefulWidget {
  /// An order for copies of [document]; [onDone] runs after either button.
  /// [failed]: it opens on the alert of an order the print shop never got.
  const KitPrintOrder({
    super.key,
    required this.document,
    this.onDone,
    this.failed = false,
  });

  /// The document's name.
  final String document;

  /// Closes the window it stands in, if any.
  final VoidCallback? onDone;

  /// Whether it opens on a failed order's alert.
  final bool failed;

  @override
  State<KitPrintOrder> createState() => _KitPrintOrderState();
}

class _KitPrintOrderState extends State<KitPrintOrder> {
  var _copies = 2;
  var _post = 'standard';
  var _pay = 'card';

  static String _money(int cents) =>
      '\$${cents ~/ 100}.${(cents % 100).toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    if (widget.failed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _failed();
      });
    }
  }

  void _done(String message) {
    showRetroDesktopSnackBar(context, context.say(message));
    widget.onDone?.call();
  }

  // The period's stop alert: what happened, that nothing is lost, and the
  // one thing to do, ringed.
  Future<void> _failed() async {
    final again = await showRetroDesktopDialog<bool>(
      context,
      builder: (context) => RetroDesktopDialog(
        title: context.say('The order wasn’t sent'),
        message: context.say(
          'Papers couldn’t reach the print shop. Check your connection, '
          'then try again: your order is kept.',
        ),
        tone: RetroDesktopTone.danger,
        actions: [
          RetroDesktopDialogAction(context.say('Cancel'), value: false),
          RetroDesktopDialogAction(
            context.say('Try again'),
            value: true,
            isDefaultAction: true,
          ),
        ],
      ),
    );
    if (mounted && again == true) {
      _done('Copies ordered: they arrive by post');
    }
  }

  @override
  Widget build(BuildContext context) {
    final doc = _paper(widget.document);
    // A bound copy costs a base and a little a page.
    final each = 300 + doc.pages * 50;
    final postage = _post == 'standard' ? 400 : 1200;
    final say = context.say;
    return RetroDesktopColumn(
      gap: 16,
      children: [
        RetroDesktopTable(
          columns: [
            RetroDesktopTableColumn(say('Item'), flex: 3),
            RetroDesktopTableColumn(
              say('Copies'),
              width: 76,
              figures: true,
              end: true,
            ),
            RetroDesktopTableColumn(
              say('Price'),
              width: 72,
              figures: true,
              end: true,
            ),
          ],
          rows: [
            [
              context.papersHebrew
                  ? '${say(doc.name)}, כרוך'
                  : '${doc.name}, bound',
              '$_copies',
              _money(each * _copies),
            ],
            [
              say(
                _post == 'standard' ? 'Postage, standard' : 'Postage, express',
              ),
              '',
              _money(postage),
            ],
          ],
          due: (say('Amount due'), _money(each * _copies + postage)),
        ),
        RetroDesktopSelect<int>(
          label: say('Copies'),
          value: _copies,
          options: [for (var n = 1; n <= 5; n++) RetroDesktopOption(n, '$n')],
          onChanged: (value) => setState(() => _copies = value),
        ),
        // The name and the address in one field, as a label is written: two
        // fields ran the form past a 900 desk under two windows and cut its
        // buttons, and side by side they left the window's keylines.
        RetroDesktopTextField(
          label: say('Deliver to'),
          initial: say('Alex Lee, 12 Harbour Street, Leith'),
        ),
        RetroDesktopRadioGroup<String>(
          label: say('Postage'),
          value: _post,
          onChanged: (value) => setState(() => _post = value),
          options: [
            RetroDesktopRadio(
              'standard',
              say('Standard, in 3 to 5 days, \$4.00'),
            ),
            RetroDesktopRadio('express', say('Express, the next day, \$12.00')),
          ],
        ),
        RetroDesktopSelect<String>(
          label: say('Pay with'),
          value: _pay,
          options: [
            RetroDesktopOption('card', say('The card ending 4242')),
            RetroDesktopOption('invoice', say('An invoice, due in 30 days')),
          ],
          onChanged: (value) => setState(() => _pay = value),
        ),
        _Buttons([
          RetroDesktopButton(
            say('Cancel'),
            onPressed: () => _done('No copies ordered'),
          ),
          RetroDesktopButton(
            say('Place order'),
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
    this.moment = KitPapersMoment.none,
  });

  /// The window in front when the app opens.
  final KitPapersWindow front;

  /// Whether it opens with no other window.
  final bool alone;

  /// The moment it opens on.
  final KitPapersMoment moment;

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
  var _started = false;
  var _opened = 'Project notes';
  var _ordering = 'Project notes';
  String? _icon;
  var _savedDetails = _defaultContact;
  late var _draftDetails = widget.moment == KitPapersMoment.unsaved
      ? (
          name: 'Alex Lee-Morgan',
          email: _defaultContact.email,
          location: _defaultContact.location,
        )
      : _savedDetails;
  bool _confirmingDetails = false;

  @override
  void initState() {
    super.initState();
    if (widget.moment == KitPapersMoment.unsaved) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _close(KitPapersWindow.details);
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final hebrew = context.papersHebrew;
    _view.hebrew = hebrew;
    if (_started) return;
    _started = true;
    // The search a link opens on, typed in the app's language: two of six.
    if (widget.moment == KitPapersMoment.search) {
      _view.find.text = hebrew ? 'רשימת' : 'list';
    }
    // The window's foot counts what the Find field leaves.
    _view.addListener(_viewChanged);
  }

  void _viewChanged() => setState(() {});

  @override
  void dispose() {
    _view.removeListener(_viewChanged);
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

  void _close(KitPapersWindow w) {
    if (w == KitPapersWindow.details && _draftDetails != _savedDetails) {
      _closeEdited();
      return;
    }
    setState(() => _open.remove(w));
  }

  // Closing your details with a change in them: the period's three answers,
  // Save ringed, "Don't save" at the far start, away from it.
  Future<void> _closeEdited() async {
    if (_confirmingDetails) return;
    _confirmingDetails = true;
    final answer = await showRetroDesktopDialog<String>(
      context,
      builder: (context) => RetroDesktopDialog(
        title: context.say('Save the changes to your details?'),
        message: context.say(
          'If you close without saving, your changes are lost.',
        ),
        tone: RetroDesktopTone.warning,
        actions: [
          RetroDesktopDialogAction(context.say('Don’t save'), value: 'discard'),
          RetroDesktopDialogAction(context.say('Cancel'), value: 'cancel'),
          RetroDesktopDialogAction(
            context.say('Save'),
            value: 'save',
            isDefaultAction: true,
          ),
        ],
      ),
    );
    if (!mounted) return;
    _confirmingDetails = false;
    if (answer == null || answer == 'cancel') return;
    if (answer == 'save' && context.mounted) {
      showRetroDesktopSnackBar(context, context.say('Your details are saved'));
    }
    _finishDetails(save: answer == 'save');
  }

  void _finishDetails({required bool save}) {
    setState(() {
      if (save) _savedDetails = _draftDetails;
      _draftDetails = _savedDetails;
      _open.remove(KitPapersWindow.details);
    });
  }

  void _openDocument(String name) {
    _view.select(name);
    setState(() => _opened = name);
    _front(KitPapersWindow.document);
  }

  void _order(String name) {
    setState(() => _ordering = name);
    _front(KitPapersWindow.prints);
  }

  // File > Find…: the documents window in front, its Find field focused.
  void _find() {
    if (!_open.contains(KitPapersWindow.documents)) {
      setState(() => _open.add(KitPapersWindow.documents));
    } else {
      _front(KitPapersWindow.documents);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _view.findFocus.requestFocus();
    });
  }

  String _title(KitPapersWindow w, String opened) => context.say(switch (w) {
    KitPapersWindow.documents => 'Documents',
    KitPapersWindow.document => opened,
    KitPapersWindow.details => 'Your details',
    KitPapersWindow.settings => 'Settings',
    KitPapersWindow.prints => 'Order printed copies',
    KitPapersWindow.bin => 'Bin',
  });

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
    final say = context.say;
    final he = context.papersHebrew;
    return RetroDesktopWindow(
      key: ValueKey('papers-window/${w.name}'),
      title: _title(w, _opened),
      icon: _glyph(w),
      onClose: onClose ?? () => _close(w),
      info: w != KitPapersWindow.documents
          ? null
          : _view.query.isEmpty
          ? (he
                ? '${kitPapers.length} מסמכים'
                : '${kitPapers.length} documents')
          : (he
                ? '${_view.rows.length} מתוך ${kitPapers.length} מסמכים'
                : '${_view.rows.length} of ${kitPapers.length} documents'),
      infoEnd: w == KitPapersWindow.documents ? say('1.2 GB available') : null,
      status: switch (w) {
        KitPapersWindow.document => [
          he
              ? '*${doc.pages}* ${doc.pages == 1 ? 'עמוד' : 'עמודים'}'
              : '*${doc.pages}* ${doc.pages == 1 ? 'page' : 'pages'}',
          doc.size,
        ],
        KitPapersWindow.settings => [say('Changes are kept as you make them')],
        _ => const [],
      },
      statusAction: w == KitPapersWindow.document
          ? RetroDesktopButton(
              say('Order copies…'),
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
          path: [say('Documents')],
          title: say(doc.name),
          meta: [
            (say('Kind'), say(doc.kind)),
            (say('Changed'), say(doc.changed)),
          ],
          paragraphs: [for (final p in doc.paragraphs) say(p)],
        ),
        KitPapersWindow.details => KitDetailsForm(
          details: _draftDetails,
          onChanged: (value) => _draftDetails = value,
          onSave: () => _finishDetails(save: true),
          onCancel: () => _finishDetails(save: false),
        ),
        KitPapersWindow.settings => const KitSettingsPanel(),
        KitPapersWindow.prints => KitPrintOrder(
          key: ValueKey(_ordering),
          document: _ordering,
          failed: widget.moment == KitPapersMoment.failedOrder,
          onDone: () => _close(KitPapersWindow.prints),
        ),
        KitPapersWindow.bin => RetroDesktopEmpty(
          title: say('The bin is empty'),
          body: say('What you delete waits here for 30 days.'),
          art: const RetroDesktopDeskArt(RetroDesktopDeskMark.bin),
        ),
      },
    );
  }

  List<RawMenuEntry> _menus(KitPapersHost? host) {
    final selected = _view.visibleSelection;
    final front = _open.isEmpty ? null : _open.last;
    final say = context.say;
    RawMenuEntry sort(int k, String label) => RawMenuEntry(
      label: say(label),
      checked: _view.sort == k,
      onPressed: () => setState(() => _view.sortBy(k)),
    );
    // A command's keys as ui_core spells them, in the platform's words: Command on Apple's, Ctrl elsewhere. Words,
    // not Apple's symbols: the look's typefaces draw none of ⌘ ⌥ ⇧ ⌃.
    String keys(LogicalKeyboardKey key) {
      final apple = switch (defaultTargetPlatform) {
        TargetPlatform.macOS || TargetPlatform.iOS => true,
        _ => false,
      };
      return designShortcutLabel(
        context,
        SingleActivator(key, meta: apple, control: !apple),
        appleSymbols: false,
      );
    }

    return [
      RawMenuEntry(
        label: say('Papers'),
        children: [
          RawMenuEntry(
            label: say('About Papers'),
            onPressed: () => showRetroDesktopSnackBar(
              context,
              say('Papers keeps your documents in one place'),
            ),
          ),
          const RawMenuEntry.divider(),
          RawMenuEntry(
            label: say('Your details…'),
            onPressed: () => _front(KitPapersWindow.details),
          ),
          RawMenuEntry(
            label: say('Settings…'),
            shortcut: keys(LogicalKeyboardKey.comma),
            onPressed: () => _front(KitPapersWindow.settings),
          ),
        ],
      ),
      RawMenuEntry(
        label: say('File'),
        children: [
          RawMenuEntry(
            label: say('Open'),
            shortcut: keys(LogicalKeyboardKey.keyO),
            onPressed: selected == null ? null : () => _openDocument(selected),
          ),
          RawMenuEntry(
            label: say('Close window'),
            shortcut: keys(LogicalKeyboardKey.keyW),
            onPressed: front == null ? null : () => _close(front),
          ),
          const RawMenuEntry.divider(),
          RawMenuEntry(
            label: say('Find…'),
            shortcut: keys(LogicalKeyboardKey.keyF),
            onPressed: _find,
          ),
          const RawMenuEntry.divider(),
          RawMenuEntry(
            label: say('Order printed copies…'),
            shortcut: keys(LogicalKeyboardKey.keyP),
            onPressed: selected == null ? null : () => _order(selected),
          ),
        ],
      ),
      RawMenuEntry(
        label: say('Edit'),
        // Nothing is chosen, so the edit commands have no onPressed: unavailable.
        children: [
          RawMenuEntry(
            label: say('Undo'),
            shortcut: keys(LogicalKeyboardKey.keyZ),
          ),
          const RawMenuEntry.divider(),
          RawMenuEntry(
            label: say('Cut'),
            shortcut: keys(LogicalKeyboardKey.keyX),
          ),
          RawMenuEntry(
            label: say('Copy'),
            shortcut: keys(LogicalKeyboardKey.keyC),
          ),
          RawMenuEntry(
            label: say('Paste'),
            shortcut: keys(LogicalKeyboardKey.keyV),
          ),
        ],
      ),
      RawMenuEntry(
        label: say('View'),
        children: [
          sort(0, 'By name'),
          sort(1, 'By kind'),
          sort(2, 'By date changed'),
          sort(3, 'By size'),
          if (host != null) ...[
            const RawMenuEntry.divider(),
            RawMenuEntry(
              label: say('Night'),
              checked: host.night,
              onPressed: () => host.onNight(!host.night),
            ),
          ],
        ],
      ),
      RawMenuEntry(
        label: say('Window'),
        children: [
          for (final w in KitPapersWindow.values)
            RawMenuEntry(
              label: _title(w, _opened),
              checked: front == w,
              onPressed: w != KitPapersWindow.prints
                  ? () => _front(w)
                  : selected == null
                  ? null
                  : () => _order(selected),
            ),
        ],
      ),
    ];
  }

  Widget _icons({required bool rail}) {
    Widget icon(String name, Widget art, VoidCallback open) =>
        RetroDesktopDeskIcon(
          context.say(name),
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
      const margin = 24.0;
      // The icons' rail at the desk's end, as wide as an icon at this text size (its name grows with the text).
      final icon = RetroDesktopDeskIcon.widthOf(context);
      final reach = room.maxWidth - (icon + 12) - margin;
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
          KeyedSubtree(
            key: ValueKey('papers/${w.name}'),
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
            width: icon,
            child: _icons(rail: true),
          ),
          Positioned.fill(
            child: _DeskWindows(
              places,
              step: cascade,
              rtl: Directionality.of(context) == TextDirection.rtl,
              children: placed,
            ),
          ),
        ],
      );
    },
  );

  // From a tablet's width to the desk's (600 up to 1024): the list and the window in front of it side by side, as two
  // windows tiled on a small screen, each scrolling on its own; a window alone keeps its desk width, the desk's icons
  // at the end. One window stretched across a tablet read as a phone's screen blown up, half of it empty.
  static const _tiledFrom = 600.0;

  Widget _tiled(BuildContext context) {
    if (_open.isEmpty) return _phone(context);
    final others = _open.where((w) => w != KitPapersWindow.documents);
    final panes = [
      if (_open.contains(KitPapersWindow.documents)) KitPapersWindow.documents,
      if (others.isNotEmpty) others.last,
    ];
    Widget pane(KitPapersWindow w) => SingleChildScrollView(
      key: ValueKey('papers-tiled/${w.name}'),
      padding: const EdgeInsets.only(bottom: 16),
      child: Listener(
        onPointerDown: (_) => _front(w),
        child: RetroDesktopWindowScope(
          active: w == _open.last,
          compact: true,
          child: _window(w),
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(12, 12, 12, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: panes.length == 2
            ? [
                Expanded(child: pane(panes.first)),
                const SizedBox(width: 12),
                Expanded(child: pane(panes.last)),
              ]
            : [
                Expanded(
                  child: Align(
                    alignment: AlignmentDirectional.topStart,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: _width(panes.single),
                      ),
                      child: pane(panes.single),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: RetroDesktopDeskIcon.widthOf(context),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _icons(rail: true),
                  ),
                ),
              ],
      ),
    );
  }

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
    final selected = _view.visibleSelection;
    if (selected != null) {
      key(LogicalKeyboardKey.keyO, () => _openDocument(selected), keys);
      key(LogicalKeyboardKey.keyP, () => _order(selected), keys);
    }
    key(LogicalKeyboardKey.keyF, _find, keys);
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
              label: context.say('Papers'),
              // On a phone the titles and the way back need the mark's room.
              leading: t.desk ? const RetroDesktopSystemMark() : null,
              menus: _menus(host),
              // The one way back to the gallery the app stands in: a small push button, the gallery's own control
              // and not one of the app's menus (a quiet one read as a grey pill in the bar).
              trailing: host == null
                  ? null
                  : RetroDesktopButton(
                      context.say('Gallery'),
                      size: RetroDesktopButtonSize.small,
                      onPressed: host.onGallery,
                    ),
            ),
          ),
          body: t.desk
              ? _desk(context)
              : t.width >= _tiledFrom
              ? _tiled(context)
              : _phone(context),
        ),
      ),
    );
  }
}

/// The desk's windows, back to front, each at its start and top and as tall
/// as it holds: stretched past the window behind it, a short form stood over
/// a band of empty grey under its buttons. Only where its foot would end in
/// the foot of a window behind it (the last step of that one) does it reach
/// 8 past that one's foot, so no edge of it crosses the words there (a
/// Settings window over a document cut its "Order copies…" in half).
class _DeskWindows extends MultiChildRenderObjectWidget {
  const _DeskWindows(
    this.places, {
    required this.step,
    required this.rtl,
    required super.children,
  });

  /// Each window (one a child, in order) with its start, top and width.
  final List<(KitPapersWindow, double, double, double)> places;
  final double step;
  final bool rtl;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderDeskWindows(places, step, rtl);

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderDeskWindows)
      ..places = places
      ..step = step
      ..rtl = rtl
      ..markNeedsLayout();
  }
}

class _DeskWindowData extends ContainerBoxParentData<RenderBox> {}

class _RenderDeskWindows extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _DeskWindowData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _DeskWindowData> {
  _RenderDeskWindows(this.places, this.step, this.rtl);

  List<(KitPapersWindow, double, double, double)> places;
  double step;
  bool rtl;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _DeskWindowData) {
      child.parentData = _DeskWindowData();
    }
  }

  @override
  void performLayout() {
    size = constraints.biggest;
    final laid = <Rect>[];
    var child = firstChild;
    for (final (_, start, top, width) in places) {
      if (child == null) break;
      final left = rtl ? size.width - start - width : start;
      child.layout(BoxConstraints.tightFor(width: width), parentUsesSize: true);
      var height = child.size.height;
      var least = 0.0;
      for (final r in laid) {
        final across = r.left < left + width && left < r.right;
        final foot = top + height;
        if (across && foot > r.bottom - step && foot < r.bottom + 8) {
          if (r.bottom + 8 - top > least) least = r.bottom + 8 - top;
        }
      }
      if (least > height) {
        child.layout(
          BoxConstraints(minWidth: width, maxWidth: width, minHeight: least),
          parentUsesSize: true,
        );
        height = child.size.height;
      }
      (child.parentData! as _DeskWindowData).offset = Offset(left, top);
      laid.add(Rect.fromLTWH(left, top, width, height));
      child = childAfter(child);
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}
