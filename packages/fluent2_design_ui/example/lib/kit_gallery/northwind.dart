/// Northwind, the small team's workspace the gallery's screens belong to:
/// one app of four nav roots (Home, Files, Requests, Settings) behind
/// Fluent's tab bar on a phone and its nav pane from 1024 wide, each root an
/// ordinary screen of the kind a person judges a look by. The Screens pages
/// open it on their own root; the roots keep their state as you move
/// between them. It draws its own navigation, with no router, so the
/// package's example carries it.
library;

import 'package:flutter/material.dart';
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

const List<Fluent2NavItem> _tabs = [
  Fluent2NavItem(Fluent2Icons.home, 'Home', null, Fluent2Icons.homeFilled),
  Fluent2NavItem(Fluent2Icons.folder, 'Files', null, Fluent2Icons.folderFilled),
  Fluent2NavItem(
    Fluent2Icons.clipboard,
    'Requests',
    null,
    Fluent2Icons.clipboardFilled,
  ),
  Fluent2NavItem(
    Fluent2Icons.settings,
    'Settings',
    null,
    Fluent2Icons.settingsFilled,
  ),
];

/// The roots and the navigation between them, as Fluent2Shell draws them
/// over a router: the nav pane beside the pages from 1024 wide, else the
/// tab bar at the foot with its band reserved at each root's end.
class _Shell extends StatefulWidget {
  const _Shell(this.root);

  final KitNorthwindRoot root;

  @override
  State<_Shell> createState() => _ShellState();
}

class _ShellState extends State<_Shell> {
  late int _tab = widget.root.index;
  bool _collapsed = false;

  void _select(int i) => setState(() => _tab = i);

  @override
  Widget build(BuildContext context) {
    // Each root keeps its scroll and its state while another shows.
    final roots = IndexedStack(
      index: _tab,
      children: const [_Home(), _Files(), _Request(), _Settings()],
    );
    if (Fluent2Layout.isWide(context)) {
      return Fluent2Beside(
        pane: Fluent2NavigationDrawer(
          items: _tabs,
          selectedIndex: _tab,
          onDestinationSelected: _select,
          brand: 'Northwind',
          collapsed: _collapsed,
          onToggle: () => setState(() => _collapsed = !_collapsed),
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

/// The width from which a screen stands its parts side by side.
const double _twoColumns = 760;

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
        borderRadius: BorderRadius.circular(Fluent2Radius.xLarge),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Fluent2Spacing.xl),
        child: Row(
          spacing: Fluent2Spacing.l,
          children: [
            const Fluent2Avatar(
              name: 'Ines Duarte',
              size: 48,
              color: Fluent2AvatarColor.colorful,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: Fluent2Spacing.xs,
                children: [
                  Text(
                    'Good afternoon, Ines',
                    style: t.title3.c(t.colors.neutralForeground1),
                  ),
                  Text(
                    'Three meetings and two requests need you today.',
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
      title: 'Today',
      aside: '3 meetings',
      action: Fluent2SectionHeader.link('Calendar', onPressed: () {}),
      rows: [
        Fluent2ListItem(
          icon: Fluent2Icons.video,
          title: 'Standup',
          subtitle: '09:30 · 15 min · Video call',
          onTap: () {},
        ),
        Fluent2ListItem(
          icon: Fluent2Icons.calendarLtr,
          title: 'Roadmap review',
          subtitle: '14:00 · 1 h · Room 2',
          onTap: () {},
        ),
        Fluent2ListItem(
          icon: Fluent2Icons.people,
          title: 'Design crit',
          subtitle: '16:00 · 45 min · Studio',
          onTap: () {},
        ),
      ],
    );
    final review = Fluent2ListSection(
      title: 'Waiting on you',
      aside: '2 requests',
      rows: [
        Fluent2ListItem(
          leading: const Fluent2Avatar(
            name: 'Kai Tanaka',
            color: Fluent2AvatarColor.colorful,
          ),
          title: 'Second monitor',
          subtitle: 'Kai Tanaka · Equipment',
          trailing: const Fluent2Tag(
            'Urgent',
            appearance: Fluent2TagAppearance.brand,
            size: Fluent2TagSize.small,
          ),
          chevron: true,
          onTap: () {},
        ),
        Fluent2ListItem(
          leading: const Fluent2Avatar(
            name: 'Priya Raman',
            color: Fluent2AvatarColor.colorful,
          ),
          title: 'Access to Finance share',
          subtitle: 'Priya Raman · Access',
          chevron: true,
          onTap: () {},
        ),
      ],
    );
    final storage = Fluent2Card(
      children: [
        const Fluent2CardHeader(
          image: Icon(Fluent2Icons.cloud),
          header: 'Storage',
          description: '62 GB of 100 GB used',
        ),
        const Fluent2ProgressBar(value: .62, semanticLabel: 'Storage used'),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Fluent2Button('Manage storage', onPressed: () {}),
        ),
      ],
    );
    final recent = Fluent2ListSection(
      title: 'Recent files',
      action: Fluent2SectionHeader.link('All files', onPressed: () {}),
      rows: [
        for (final (name, meta) in _recent)
          Fluent2ListItem(
            leading: _fileTile(name),
            title: name,
            subtitle: meta,
            onTap: () {},
          ),
      ],
    );
    return Fluent2Scaffold(
      topBar: const Fluent2AppBar(title: 'Home'),
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
    final groups = [
      for (final (title, files) in _files[name]!)
        (
          title,
          [
            for (final f in files)
              if (q.isEmpty || f.name.toLowerCase().contains(q)) f,
          ],
        ),
    ].where((g) => g.$2.isNotEmpty);
    return Fluent2Scaffold(
      topBar: Fluent2AppBar(
        title: 'Files',
        actions: [
          Fluent2IconButton(
            Fluent2Icons.cloudArrowUp,
            label: 'Upload',
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
              hint: 'Search files',
              value: _query,
              onChanged: (v) => setState(() => _query = v),
              onClear: () => setState(() => _query = ''),
            ),
          ),
          const Fluent2Gap(Fluent2Spacing.m),
          Fluent2TabList(
            label: 'Which files',
            selectedIndex: _set,
            onChanged: (i) => setState(() => _set = i),
            tabs: _files.keys.toList(),
          ),
          const Fluent2Gap(Fluent2Spacing.l),
          if (groups.isEmpty)
            Fluent2EmptyState(
              icon: Fluent2Icons.search,
              title: 'No files match “${_query.trim()}”',
              body: 'Try another name, or look in Shared and Starred.',
            ),
          for (final (title, files) in groups) ...[
            Fluent2ListGroup(
              title: title,
              children: [
                for (final f in files)
                  Fluent2ListItem(
                    leading: _fileTile(f.name),
                    title: f.name,
                    subtitle: f.meta,
                    value: f.size,
                    onTap: () {},
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

// --- Requests --------------------------------------------------------------

const _kinds = [
  Fluent2Option('equipment', 'Equipment'),
  Fluent2Option('access', 'Access'),
  Fluent2Option('room', 'Room booking'),
  Fluent2Option('other', 'Something else'),
];

const _priorities = [
  Fluent2ButtonSegment('low', 'Low'),
  Fluent2ButtonSegment('normal', 'Normal'),
  Fluent2ButtonSegment('urgent', 'Urgent'),
];

const _when = [
  Fluent2Option('week', 'This week'),
  Fluent2Option('next', 'Next week'),
  Fluent2Option('month', 'This month'),
];

const _approvers = [
  Fluent2Option('kai', 'Kai Tanaka'),
  Fluent2Option('mara', 'Mara Okafor'),
  Fluent2Option('tomas', 'Tomas Lindqvist'),
];

class _Request extends StatefulWidget {
  const _Request();

  @override
  State<_Request> createState() => _RequestState();
}

class _RequestState extends State<_Request> {
  String _title = 'Second monitor';
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
      'Operations will reply by tomorrow.',
      title: 'Request sent',
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
      topBar: const Fluent2AppBar(title: 'New request'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Fluent2Gap(Fluent2Spacing.m),
          _measured(
            560,
            Text(
              'Ask the operations team for equipment, access or a room. '
              'Most requests are answered within a day.',
              style: t.body1.c(t.textSecondary),
            ),
          ),
          const Fluent2Gap(Fluent2Spacing.xxl),
          Fluent2FormSection(
            title: 'What you need',
            children: [
              Fluent2FormField(
                label: 'Title',
                required: true,
                validationMessage: _tried && _missingTitle
                    ? 'Give the request a title.'
                    : null,
                child: Fluent2TextField(
                  value: _title,
                  hint: 'For example, a second monitor',
                  invalid: _tried && _missingTitle,
                  onChanged: (v) => setState(() => _title = v),
                ),
              ),
              Fluent2FormField(
                label: 'Type',
                child: Fluent2Select<String>(
                  prompt: 'Choose a type',
                  options: _kinds,
                  value: _kind,
                  onChanged: (v) => setState(() => _kind = v),
                ),
              ),
              Fluent2FormField(
                label: 'Priority',
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Fluent2SegmentedButton<String>(
                    label: 'Priority',
                    segments: _priorities,
                    value: _priority,
                    onChanged: (v) => setState(() => _priority = v),
                  ),
                ),
              ),
              Fluent2FormField(
                label: 'Details',
                helper: 'What it is for, and anything the team should know.',
                child: Fluent2TextArea(
                  value: _details,
                  hint: 'Add details',
                  onChanged: (v) => setState(() => _details = v),
                ),
              ),
            ],
          ),
          const Fluent2Gap(Fluent2Spacing.xxl),
          Fluent2FormSection(
            title: 'When and who',
            children: [
              Fluent2FormField(
                label: 'Needed by',
                required: true,
                validationMessage: _tried && _missingBy
                    ? 'Choose when you need it.'
                    : null,
                child: Fluent2Select<String>(
                  prompt: 'Choose a date',
                  options: _when,
                  value: _by,
                  onChanged: (v) => setState(() => _by = v),
                ),
              ),
              Fluent2FormField(
                label: 'Approver',
                child: Fluent2Select<String>(
                  prompt: 'Choose an approver',
                  options: _approvers,
                  value: _approver,
                  onChanged: (v) => setState(() => _approver = v),
                ),
              ),
              Fluent2Checkbox(
                value: _updates,
                label: 'Email me when the status changes',
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
                'Submit request',
                appearance: Fluent2ButtonAppearance.primary,
                onPressed: _submit,
              ),
              Fluent2Button('Clear', onPressed: _clear),
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
      topBar: const Fluent2AppBar(title: 'Settings'),
      body: _measured(
        720,
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Fluent2Gap(Fluent2Spacing.m),
            Fluent2ListGroup(
              children: [
                Fluent2ListItem(
                  leading: const Fluent2Avatar(
                    name: 'Ines Duarte',
                    color: Fluent2AvatarColor.colorful,
                    size: 40,
                  ),
                  title: 'Ines Duarte',
                  subtitle: 'ines@northwind.example',
                  chevron: true,
                  onTap: () {},
                ),
              ],
            ),
            gap,
            Fluent2ListGroup(
              title: 'Notifications',
              footer: 'Quiet hours hold everything but calls.',
              children: [
                Fluent2ListItem(
                  icon: Fluent2Icons.alert,
                  title: 'Push notifications',
                  trailing: Fluent2Switch(
                    value: _push,
                    semanticLabel: 'Push notifications',
                    onChanged: (v) => setState(() => _push = v),
                  ),
                ),
                Fluent2ListItem(
                  icon: Fluent2Icons.chat,
                  title: 'Mentions only',
                  subtitle: 'Skip the rest of a channel',
                  trailing: Fluent2Switch(
                    value: _mentions,
                    semanticLabel: 'Mentions only',
                    onChanged: (v) => setState(() => _mentions = v),
                  ),
                ),
                Fluent2ListItem(
                  icon: Fluent2Icons.mail,
                  title: 'Email digest',
                  value: 'Weekly',
                  chevron: true,
                  onTap: () {},
                ),
                Fluent2ListItem(
                  icon: Fluent2Icons.weatherMoon,
                  title: 'Quiet hours',
                  value: '22:00–07:00',
                  chevron: true,
                  onTap: () {},
                ),
              ],
            ),
            gap,
            Fluent2ListGroup(
              title: 'General',
              children: [
                Fluent2ListItem(
                  icon: Fluent2Icons.paintBrush,
                  title: 'Appearance',
                  value: 'System',
                  chevron: true,
                  onTap: () {},
                ),
                Fluent2ListItem(
                  icon: Fluent2Icons.globe,
                  title: 'Language',
                  value: 'English (UK)',
                  chevron: true,
                  onTap: () {},
                ),
                Fluent2ListItem(
                  icon: Fluent2Icons.people,
                  title: 'Show when I’m active',
                  trailing: Fluent2Switch(
                    value: _status,
                    semanticLabel: 'Show when I’m active',
                    onChanged: (v) => setState(() => _status = v),
                  ),
                ),
              ],
            ),
            gap,
            Fluent2ListGroup(
              title: 'Privacy and security',
              children: [
                Fluent2ListItem(
                  icon: Fluent2Icons.shieldCheckmark,
                  title: 'Two-step verification',
                  value: 'On',
                  chevron: true,
                  onTap: () {},
                ),
                Fluent2ListItem(
                  icon: Fluent2Icons.lockClosed,
                  title: 'Signed-in devices',
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
                'Sign out',
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
