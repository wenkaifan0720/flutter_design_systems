/// Northwind, the small team's workspace the gallery's screens belong to:
/// one app of four nav roots (Home, Files, Requests, Settings) behind
/// Fluent's tab bar on a phone and its nav pane from 1024 wide, each root an
/// ordinary screen of the kind a person judges a look by. The Screens pages
/// open it on their own root; the roots keep their state as you move
/// between them, and a move between them is a cut. A file opens its own
/// page over Files, on the theme's page motion, as a pushed route under an
/// app's shell does. It draws its own navigation, with no router, so the
/// package's example carries it.
library;

import 'package:material_ui/material_ui.dart';
import 'package:fluent2_design_ui/fluent2_design_host.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';

import 'kit.dart';

/// Northwind's roots, in the tab bar's order.
enum KitNorthwindRoot {
  /// The overview: today, what waits on you, storage, recent files.
  home,

  /// The files, in sets.
  files,

  /// A new request to the operations team: a form.
  requests,

  /// The owner's settings.
  settings,
}

/// Northwind opened on [root], by day or by night.
class KitNorthwind extends StatelessWidget {
  /// Northwind opened on [root].
  const KitNorthwind({required this.brightness, required this.root, super.key});

  /// The appearance it stands in.
  final Brightness brightness;

  /// The root it opens on.
  final KitNorthwindRoot root;

  @override
  Widget build(BuildContext context) =>
      kitSurface(brightness: brightness, child: _Shell(root));
}

List<Fluent2NavItem> get _tabs => [
  Fluent2NavItem(
    Fluent2Icons.home,
    kitW('Home'),
    null,
    Fluent2Icons.homeFilled,
  ),
  Fluent2NavItem(
    Fluent2Icons.folder,
    kitW('Files'),
    null,
    Fluent2Icons.folderFilled,
  ),
  Fluent2NavItem(
    Fluent2Icons.clipboard,
    kitW('Requests'),
    null,
    Fluent2Icons.clipboardFilled,
  ),
  Fluent2NavItem(
    Fluent2Icons.settings,
    kitW('Settings'),
    null,
    Fluent2Icons.settingsFilled,
  ),
];

/// The roots and the navigation between them, as Fluent2Shell draws them
/// over a router: the nav pane beside the pages from 1024 wide, folded to
/// its rail from 640 (a tablet), else the tab bar at the foot with its band
/// reserved at each root's end.
class _Shell extends StatefulWidget {
  const _Shell(this.root);

  final KitNorthwindRoot root;

  @override
  State<_Shell> createState() => _ShellState();
}

class _ShellState extends State<_Shell> {
  late int _tab = widget.root.index;
  bool _collapsed = false;
  bool _opened = false;

  void _select(int i) => setState(() => _tab = i);

  @override
  Widget build(BuildContext context) {
    // Each root keeps its scroll and its state while another shows.
    final roots = IndexedStack(
      index: _tab,
      children: const [_Home(), _FilesRoot(), _Request(), _Settings()],
    );
    final wide = Fluent2Layout.isWide(context);
    if (wide || MediaQuery.sizeOf(context).width >= Fluent2Layout.medium) {
      return Fluent2Beside(
        pane: Fluent2NavigationDrawer(
          items: _tabs,
          selectedIndex: _tab,
          onDestinationSelected: _select,
          brand: kitW('Northwind'),
          collapsed: wide ? _collapsed : !_opened,
          onToggle: () => setState(
            () => wide ? _collapsed = !_collapsed : _opened = !_opened,
          ),
        ),
        child: ShellInsets(bottomInset: 0, child: roots),
      );
    }
    final band = Fluent2ShellInsets.allowance(
      systemInset: MediaQuery.paddingOf(context).bottom,
    );
    return Stack(
      fit: StackFit.expand,
      children: [
        ShellInsets(bottomInset: band, child: roots),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Fluent2NavigationBar(
            items: _tabs,
            selectedIndex: _tab,
            onDestinationSelected: _select,
          ),
        ),
      ],
    );
  }
}

/// The width from which a screen stands its parts side by side (Fluent's
/// `medium`: a tablet's too).
const double _twoColumns = Fluent2Layout.medium;

/// A column that stands at most [measure] wide from the page's start.
Widget _measured(double measure, Widget child) => Align(
  alignment: AlignmentDirectional.topStart,
  heightFactor: 1,
  child: ConstrainedBox(
    constraints: BoxConstraints(maxWidth: measure),
    child: child,
  ),
);

// --- Home ------------------------------------------------------------------

class _Home extends StatelessWidget {
  const _Home();

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    // The day's greeting on Fluent's soft brand banner (brandBackground2),
    // the owner's avatar before it, as a productivity app's home opens.
    final greeting = DecoratedBox(
      decoration: BoxDecoration(
        color: t.colors.brandBackground2,
        borderRadius: BorderRadius.circular(t.radiusXLarge),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Fluent2Spacing.xl),
        child: Row(
          spacing: Fluent2Spacing.l,
          children: [
            Fluent2Avatar(
              name: kitW('Ines Duarte'),
              size: 48,
              color: Fluent2AvatarColor.colorful,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: Fluent2Spacing.xs,
                children: [
                  Text(
                    kitW('Good afternoon, Ines'),
                    style: t.title3.c(t.colors.neutralForeground1),
                  ),
                  Text(
                    kitW('Three meetings and two requests need you today.'),
                    style: t.body1.c(t.colors.neutralForeground2),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    final today = Fluent2ListSection(
      title: kitW('Today'),
      aside: kitW('3 meetings'),
      action: Fluent2SectionHeader.link(kitW('Calendar'), onPressed: () {}),
      rows: [
        Fluent2ListItem(
          icon: Fluent2Icons.video,
          title: kitW('Standup'),
          subtitle: kitW('09:30 · 15 min · Video call'),
          onTap: () {},
        ),
        Fluent2ListItem(
          icon: Fluent2Icons.calendarLtr,
          title: kitW('Roadmap review'),
          subtitle: kitW('14:00 · 1 h · Room 2'),
          onTap: () {},
        ),
        Fluent2ListItem(
          icon: Fluent2Icons.people,
          title: kitW('Design crit'),
          subtitle: kitW('16:00 · 45 min · Studio'),
          onTap: () {},
        ),
      ],
    );
    final review = Fluent2ListSection(
      title: kitW('Waiting on you'),
      aside: kitW('2 requests'),
      rows: [
        Fluent2ListItem(
          leading: Fluent2Avatar(
            name: kitW('Kai Tanaka'),
            color: Fluent2AvatarColor.colorful,
          ),
          title: kitW('Second monitor'),
          subtitle: kitW('Kai Tanaka · Equipment'),
          trailing: Fluent2Tag(
            kitW('Urgent'),
            appearance: Fluent2TagAppearance.brand,
            size: Fluent2TagSize.small,
          ),
          chevron: true,
          onTap: () {},
        ),
        Fluent2ListItem(
          leading: Fluent2Avatar(
            name: kitW('Priya Raman'),
            color: Fluent2AvatarColor.colorful,
          ),
          title: kitW('Access to Finance share'),
          subtitle: kitW('Priya Raman · Access'),
          chevron: true,
          onTap: () {},
        ),
      ],
    );
    final storage = Fluent2Card(
      children: [
        Fluent2CardHeader(
          image: const Icon(Fluent2Icons.cloud),
          header: kitW('Storage'),
          description: kitW('62 GB of 100 GB used'),
        ),
        Fluent2ProgressBar(value: .62, semanticLabel: kitW('Storage used')),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Fluent2Button(kitW('Manage storage'), onPressed: () {}),
        ),
      ],
    );
    final recent = Fluent2ListSection(
      title: kitW('Recent files'),
      action: Fluent2SectionHeader.link(kitW('All files'), onPressed: () {}),
      rows: [
        for (final (name, meta) in _recent)
          Fluent2ListItem(
            leading: _fileTile(name),
            title: kitW(name),
            subtitle: kitW(meta),
            onTap: () {},
          ),
      ],
    );
    return Fluent2Scaffold(
      topBar: Fluent2AppBar(title: kitW('Home')),
      body: LayoutBuilder(
        builder: (context, box) {
          const gap = Fluent2Gap(Fluent2Spacing.xxl);
          if (box.maxWidth < _twoColumns) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Fluent2Gap(Fluent2Spacing.l),
                greeting,
                gap,
                today,
                gap,
                review,
                gap,
                storage,
                gap,
                recent,
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              greeting,
              gap,
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: Fluent2Spacing.xxl,
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [today, gap, review],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      // Headed first, so both columns start on one line.
                      children: [recent, gap, storage],
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

const _recent = [
  ('Q3 plan.docx', 'Kai Tanaka · 2 h ago'),
  ('Brand guidelines.pdf', 'Mara Okafor · Yesterday'),
  ('Offsite budget.xlsx', 'Tomas Lindqvist · Monday'),
];

// --- Files -----------------------------------------------------------------

typedef _File = ({String name, String meta, String size});

/// A file's tile, as a file store marks each kind: its glyph filled on the
/// kind's hue (a document in royal blue, a sheet in dark green, a PDF in
/// cranberry, a picture in grape).
Widget _fileTile(String name) {
  final (icon, hue) = switch (name.split('.').last) {
    'xlsx' => (Fluent2Icons.dataBarVerticalFilled, Fluent2Hue.darkGreen),
    'pdf' => (Fluent2Icons.documentFilled, Fluent2Hue.cranberry),
    'png' || 'jpg' => (Fluent2Icons.imageFilled, Fluent2Hue.grape),
    _ => (Fluent2Icons.documentTextFilled, Fluent2Hue.royalBlue),
  };
  return Fluent2IconTile(icon, hue: hue, size: 32);
}

const Map<String, List<(String, List<_File>)>> _files = {
  'Recent': [
    (
      'Today',
      [
        (name: 'Q3 plan.docx', meta: 'Kai Tanaka edited', size: '2.4 MB'),
        (name: 'Offsite budget.xlsx', meta: 'You edited', size: '310 KB'),
      ],
    ),
    (
      'Earlier this week',
      [
        (
          name: 'Brand guidelines.pdf',
          meta: 'Mara Okafor shared',
          size: '8.1 MB',
        ),
        (name: 'Launch hero.png', meta: 'Noor Haddad added', size: '1.2 MB'),
        (name: 'Standup notes', meta: 'Priya Raman edited', size: '24 KB'),
      ],
    ),
  ],
  'Shared': [
    (
      'Shared with you',
      [
        (name: 'Hiring plan.xlsx', meta: 'Tomas Lindqvist', size: '96 KB'),
        (name: 'Customer interviews', meta: 'Mara Okafor', size: '1.8 MB'),
      ],
    ),
  ],
  'Starred': [
    (
      'Starred',
      [(name: 'Brand guidelines.pdf', meta: 'Mara Okafor', size: '8.1 MB')],
    ),
  ],
};

class _Files extends StatefulWidget {
  const _Files();

  @override
  State<_Files> createState() => _FilesState();
}

class _FilesState extends State<_Files> {
  int _set = 0;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final name = _files.keys.elementAt(_set);
    final q = _query.trim().toLowerCase();
    // The search reads the names as the page shows them.
    final groups = [
      for (final (title, files) in _files[name]!)
        (
          title,
          [
            for (final f in files)
              if (q.isEmpty || kitW(f.name).toLowerCase().contains(q)) f,
          ],
        ),
    ].where((g) => g.$2.isNotEmpty);
    return Fluent2Scaffold(
      topBar: Fluent2AppBar(
        title: kitW('Files'),
        actions: [
          Fluent2IconButton(
            Fluent2Icons.cloudArrowUp,
            semanticLabel: kitW('Upload'),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Fluent2Gap(Fluent2Spacing.m),
          _measured(
            400,
            Fluent2SearchBox(
              hintText: kitW('Search files'),
              value: _query,
              onChanged: (v) => setState(() => _query = v),
              onClear: () => setState(() => _query = ''),
            ),
          ),
          const Fluent2Gap(Fluent2Spacing.m),
          Fluent2TabList(
            semanticLabel: kitW('Which files'),
            selectedIndex: _set,
            onChanged: (i) => setState(() => _set = i),
            tabs: [for (final set in _files.keys) kitW(set)],
          ),
          const Fluent2Gap(Fluent2Spacing.l),
          if (groups.isEmpty)
            Fluent2EmptyState(
              icon: Fluent2Icons.search,
              title: kitArabic
                  ? 'لا ملفات تطابق «${_query.trim()}»'
                  : 'No files match “${_query.trim()}”',
              body: kitW('Try another name, or look in Shared and Starred.'),
            ),
          for (final (title, files) in groups) ...[
            Fluent2ListGroup(
              title: kitW(title),
              children: [
                for (final f in files)
                  Fluent2ListItem(
                    leading: _fileTile(f.name),
                    title: kitW(f.name),
                    subtitle: kitW(f.meta),
                    value: kitW(f.size),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => _FilePage(f),
                      ),
                    ),
                  ),
              ],
            ),
            const Fluent2Gap(Fluent2Spacing.xxl),
          ],
        ],
      ),
    );
  }
}

/// Files with a navigator of its own, as a branch of an app's shell has: a
/// file's page is pushed over the list, the nav pane or the tab bar staying
/// where it is, and its top bar draws the way back.
class _FilesRoot extends StatelessWidget {
  const _FilesRoot();

  @override
  Widget build(BuildContext context) => Semantics(
    // Its own semantics container: the route under the navigator stands a
    // modal barrier, which would hide what painted before it.
    container: true,
    child: Navigator(
      onGenerateRoute: (settings) => MaterialPageRoute<void>(
        settings: settings,
        builder: (context) => const _Files(),
      ),
    ),
  );
}

/// A file's page: its last change, what it is and its size, and what to do
/// with it.
class _FilePage extends StatelessWidget {
  const _FilePage(this.file);

  final _File file;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final kind = switch (file.name.split('.').last) {
      'xlsx' => 'Spreadsheet',
      'pdf' => 'PDF',
      'png' || 'jpg' => 'Picture',
      _ => 'Document',
    };
    return Fluent2Scaffold(
      topBar: Fluent2AppBar(
        title: kitW(file.name),
        backLabel: kitW('Files'),
        actions: [
          Fluent2IconButton(
            Fluent2Icons.share,
            semanticLabel: kitW('Share'),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Fluent2Gap(Fluent2Spacing.l),
          Row(
            children: [
              _fileTile(file.name),
              const Fluent2Gap(Fluent2Spacing.m),
              Expanded(
                child: Text(kitW(file.meta), style: t.body1.c(t.textSecondary)),
              ),
            ],
          ),
          const Fluent2Gap(Fluent2Spacing.xl),
          _measured(
            560,
            Fluent2DescriptionList(
              title: kitW('Details'),
              properties: [
                Fluent2DescriptionItem(kitW('Type'), kitW(kind)),
                Fluent2DescriptionItem(kitW('Size'), kitW(file.size)),
              ],
            ),
          ),
          const Fluent2Gap(Fluent2Spacing.xxl),
          Wrap(
            spacing: Fluent2Spacing.s,
            runSpacing: Fluent2Spacing.s,
            children: [
              Fluent2Button(
                kitW('Open'),
                appearance: Fluent2ButtonAppearance.primary,
                onPressed: () {},
              ),
              Fluent2Button(kitW('Copy link'), onPressed: () {}),
            ],
          ),
        ],
      ),
    );
  }
}

// --- Requests --------------------------------------------------------------

List<Fluent2Option<String>> get _kinds => [
  Fluent2Option('equipment', kitW('Equipment')),
  Fluent2Option('access', kitW('Access')),
  Fluent2Option('room', kitW('Room booking')),
  Fluent2Option('other', kitW('Something else')),
];

List<Fluent2ButtonSegment<String>> get _priorities => [
  Fluent2ButtonSegment('low', kitW('Low')),
  Fluent2ButtonSegment('normal', kitW('Normal')),
  Fluent2ButtonSegment('urgent', kitW('Urgent')),
];

List<Fluent2Option<String>> get _when => [
  Fluent2Option('week', kitW('This week')),
  Fluent2Option('next', kitW('Next week')),
  Fluent2Option('month', kitW('This month')),
];

List<Fluent2Option<String>> get _approvers => [
  Fluent2Option('kai', kitW('Kai Tanaka')),
  Fluent2Option('mara', kitW('Mara Okafor')),
  Fluent2Option('tomas', kitW('Tomas Lindqvist')),
];

class _Request extends StatefulWidget {
  const _Request();

  @override
  State<_Request> createState() => _RequestState();
}

class _RequestState extends State<_Request> {
  String _title = kitW('Second monitor');
  String? _kind = 'equipment';
  String _priority = 'normal';
  String _details = '';
  String? _by;
  String? _approver = 'kai';
  bool _updates = true;
  bool _tried = false;

  bool get _missingTitle => _title.trim().isEmpty;
  bool get _missingBy => _by == null;

  void _submit() {
    setState(() => _tried = true);
    if (_missingTitle || _missingBy) return;
    showFluent2Toast(
      context,
      kitW('Operations will reply by tomorrow.'),
      title: kitW('Request sent'),
    );
  }

  void _clear() => setState(() {
    _title = '';
    _kind = null;
    _priority = 'normal';
    _details = '';
    _by = null;
    _tried = false;
  });

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    return Fluent2Scaffold(
      topBar: Fluent2AppBar(title: kitW('New request')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Fluent2Gap(Fluent2Spacing.m),
          _measured(
            560,
            Text(
              kitW(
                'Ask the operations team for equipment, access or a room. '
                'Most requests are answered within a day.',
              ),
              style: t.body1.c(t.textSecondary),
            ),
          ),
          const Fluent2Gap(Fluent2Spacing.xxl),
          Fluent2FormSection(
            title: kitW('What you need'),
            children: [
              Fluent2FormField(
                labelText: kitW('Title'),
                required: true,
                validationMessage: _tried && _missingTitle
                    ? kitW('Give the request a title.')
                    : null,
                child: Fluent2TextField(
                  value: _title,
                  hintText: kitW('For example, a second monitor'),
                  invalid: _tried && _missingTitle,
                  onChanged: (v) => setState(() => _title = v),
                ),
              ),
              Fluent2FormField(
                labelText: kitW('Type'),
                child: Fluent2Select<String>(
                  prompt: kitW('Choose a type'),
                  options: _kinds,
                  value: _kind,
                  onChanged: (v) => setState(() => _kind = v),
                ),
              ),
              Fluent2FormField(
                labelText: kitW('Priority'),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Fluent2SegmentedButton<String>(
                    semanticLabel: kitW('Priority'),
                    segments: _priorities,
                    value: _priority,
                    onChanged: (v) => setState(() => _priority = v),
                  ),
                ),
              ),
              Fluent2FormField(
                labelText: kitW('Details'),
                helperText: kitW(
                  'What it is for, and anything the team should know.',
                ),
                child: Fluent2TextArea(
                  value: _details,
                  hintText: kitW('Add details'),
                  onChanged: (v) => setState(() => _details = v),
                ),
              ),
            ],
          ),
          const Fluent2Gap(Fluent2Spacing.xxl),
          Fluent2FormSection(
            title: kitW('When and who'),
            children: [
              Fluent2FormField(
                labelText: kitW('Needed by'),
                required: true,
                validationMessage: _tried && _missingBy
                    ? kitW('Choose when you need it.')
                    : null,
                child: Fluent2Select<String>(
                  prompt: kitW('Choose a date'),
                  options: _when,
                  value: _by,
                  onChanged: (v) => setState(() => _by = v),
                ),
              ),
              Fluent2FormField(
                labelText: kitW('Approver'),
                child: Fluent2Select<String>(
                  prompt: kitW('Choose an approver'),
                  options: _approvers,
                  value: _approver,
                  onChanged: (v) => setState(() => _approver = v),
                ),
              ),
              Fluent2Checkbox(
                value: _updates,
                label: kitW('Email me when the status changes'),
                onChanged: (v) => setState(() => _updates = v),
              ),
            ],
          ),
          const Fluent2Gap(Fluent2Spacing.xxl),
          Wrap(
            spacing: Fluent2Spacing.s,
            runSpacing: Fluent2Spacing.s,
            children: [
              Fluent2Button(
                kitW('Submit request'),
                appearance: Fluent2ButtonAppearance.primary,
                onPressed: _submit,
              ),
              Fluent2Button(kitW('Clear'), onPressed: _clear),
            ],
          ),
        ],
      ),
    );
  }
}

// --- Settings --------------------------------------------------------------

class _Settings extends StatefulWidget {
  const _Settings();

  @override
  State<_Settings> createState() => _SettingsState();
}

class _SettingsState extends State<_Settings> {
  bool _push = true;
  bool _mentions = false;
  bool _status = true;

  @override
  Widget build(BuildContext context) {
    final gap = const Fluent2Gap(Fluent2Spacing.xxl);
    return Fluent2Scaffold(
      topBar: Fluent2AppBar(title: kitW('Settings')),
      body: _measured(
        720,
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Fluent2Gap(Fluent2Spacing.m),
            Fluent2ListGroup(
              children: [
                Fluent2ListItem(
                  leading: Fluent2Avatar(
                    name: kitW('Ines Duarte'),
                    color: Fluent2AvatarColor.colorful,
                    size: 40,
                  ),
                  title: kitW('Ines Duarte'),
                  subtitle: 'ines@northwind.example',
                  chevron: true,
                  onTap: () {},
                ),
              ],
            ),
            gap,
            Fluent2ListGroup(
              title: kitW('Notifications'),
              footer: kitW('Quiet hours hold everything but calls.'),
              children: [
                Fluent2ListItem(
                  icon: Fluent2Icons.alert,
                  title: kitW('Push notifications'),
                  trailing: Fluent2Switch(
                    value: _push,
                    semanticLabel: kitW('Push notifications'),
                    onChanged: (v) => setState(() => _push = v),
                  ),
                ),
                Fluent2ListItem(
                  icon: Fluent2Icons.chat,
                  title: kitW('Mentions only'),
                  subtitle: kitW('Skip the rest of a channel'),
                  trailing: Fluent2Switch(
                    value: _mentions,
                    semanticLabel: kitW('Mentions only'),
                    onChanged: (v) => setState(() => _mentions = v),
                  ),
                ),
                Fluent2ListItem(
                  icon: Fluent2Icons.mail,
                  title: kitW('Email digest'),
                  value: kitW('Weekly'),
                  chevron: true,
                  onTap: () {},
                ),
                Fluent2ListItem(
                  icon: Fluent2Icons.weatherMoon,
                  title: kitW('Quiet hours'),
                  value: '22:00–07:00',
                  chevron: true,
                  onTap: () {},
                ),
              ],
            ),
            gap,
            Fluent2ListGroup(
              title: kitW('General'),
              children: [
                Fluent2ListItem(
                  icon: Fluent2Icons.paintBrush,
                  title: kitW('Appearance'),
                  value: kitW('System'),
                  chevron: true,
                  onTap: () {},
                ),
                Fluent2ListItem(
                  icon: Fluent2Icons.globe,
                  title: kitW('Language'),
                  value: kitW('English (UK)'),
                  chevron: true,
                  onTap: () {},
                ),
                Fluent2ListItem(
                  icon: Fluent2Icons.people,
                  title: kitW('Show when I’m active'),
                  trailing: Fluent2Switch(
                    value: _status,
                    semanticLabel: kitW('Show when I’m active'),
                    onChanged: (v) => setState(() => _status = v),
                  ),
                ),
              ],
            ),
            gap,
            Fluent2ListGroup(
              title: kitW('Privacy and security'),
              children: [
                Fluent2ListItem(
                  icon: Fluent2Icons.shieldCheckmark,
                  title: kitW('Two-step verification'),
                  value: kitW('On'),
                  chevron: true,
                  onTap: () {},
                ),
                Fluent2ListItem(
                  icon: Fluent2Icons.lockClosed,
                  title: kitW('Signed-in devices'),
                  value: '3',
                  chevron: true,
                  onTap: () {},
                ),
              ],
            ),
            gap,
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Fluent2Button(
                kitW('Sign out'),
                icon: Fluent2Icons.signOut,
                onPressed: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}
