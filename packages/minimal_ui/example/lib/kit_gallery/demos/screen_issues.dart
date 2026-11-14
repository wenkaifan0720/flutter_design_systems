/// The Screen · Issues gallery group: an issue tracker's "My issues" root
/// over its own tab bar — Assigned · Created · Subscribed (live: each has
/// its own issues), then the issues grouped by status, each group header
/// leading with its status glyph and ending in its count, and one 44 px
/// row per issue: priority, the mono id, the status glyph, the title, a
/// label tag and the assignee. The filter menu narrows by priority, a group
/// header folds its group, a tap selects an issue (in the example's
/// Tracker, opens it: [KitIssuePage]).
library;

import 'package:flutter/material.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

Widget kitScreenIssuesDemo(Brightness brightness) => kitSurface(
  brightness: brightness,
  child: MinimalPreview(
    light: kitTheme(Brightness.light),
    dark: kitTheme(Brightness.dark),
    brightness: brightness,
    tabs: _tabs,
    activeIndex: 1,
    child: const KitIssuesPage(),
  ),
);

const List<MinimalNavItem> _tabs = [
  MinimalNavItem(LucideIcons.inbox, 'Inbox'),
  MinimalNavItem(LucideIcons.circleUser, 'My issues'),
  MinimalNavItem(LucideIcons.folderKanban, 'Projects'),
  MinimalNavItem(LucideIcons.layers, 'Views'),
];

/// What kind of work an issue is; null prints no tag.
enum _Label {
  bug('Bug', MinimalTone.destructive),
  feature('Feature', MinimalTone.primary),
  design('Design', MinimalTone.neutral),
  chore('Chore', MinimalTone.neutral);

  const _Label(this.text, this.tone);

  final String text;
  final MinimalTone tone;
}

typedef _Issue = ({
  String id,
  String title,
  MinimalTaskStatus status,
  MinimalPriority priority,
  _Label? label,
  String assignee,
});

_Issue _issue(
  String id,
  String title,
  MinimalTaskStatus status,
  MinimalPriority priority,
  String assignee, [
  _Label? label,
]) => (
  id: id,
  title: title,
  status: status,
  priority: priority,
  label: label,
  assignee: assignee,
);

/// The one looking at the list.
const String _me = 'Mira Holt';

/// The statuses a list groups by, in the order it shows them.
const List<MinimalTaskStatus> _groups = [
  MinimalTaskStatus.active,
  MinimalTaskStatus.todo,
  MinimalTaskStatus.backlog,
];

/// The issues of each view: assigned to me, created by me, subscribed to.
final List<List<_Issue>> _views = [
  [
    _issue(
      'ENG-142',
      'Promo codes ignored',
      MinimalTaskStatus.active,
      MinimalPriority.urgent,
      _me,
      _Label.bug,
    ),
    _issue(
      'ENG-138',
      'Offline order queue',
      MinimalTaskStatus.active,
      MinimalPriority.high,
      _me,
      _Label.feature,
    ),
    _issue(
      'ENG-151',
      'Receipts cut off long lines',
      MinimalTaskStatus.active,
      MinimalPriority.medium,
      _me,
    ),
    _issue(
      'ENG-157',
      'Split bills by card',
      MinimalTaskStatus.todo,
      MinimalPriority.high,
      _me,
      _Label.feature,
    ),
    _issue(
      'ENG-149',
      'Tax rounding off',
      MinimalTaskStatus.todo,
      MinimalPriority.medium,
      _me,
      _Label.bug,
    ),
    _issue(
      'ENG-133',
      'Migrate settings',
      MinimalTaskStatus.todo,
      MinimalPriority.medium,
      _me,
      _Label.chore,
    ),
    _issue(
      'ENG-160',
      'Double tap bumps a ticket',
      MinimalTaskStatus.todo,
      MinimalPriority.low,
      _me,
    ),
    _issue(
      'ENG-162',
      'Empty reports state',
      MinimalTaskStatus.todo,
      MinimalPriority.low,
      _me,
      _Label.design,
    ),
    _issue(
      'ENG-121',
      'Dark order ticket',
      MinimalTaskStatus.backlog,
      MinimalPriority.low,
      _me,
      _Label.design,
    ),
    _issue(
      'ENG-117',
      'CSV customer export',
      MinimalTaskStatus.backlog,
      MinimalPriority.none,
      _me,
      _Label.feature,
    ),
    _issue(
      'ENG-109',
      'Loyalty stamps on receipts',
      MinimalTaskStatus.backlog,
      MinimalPriority.none,
      _me,
    ),
    _issue(
      'ENG-104',
      'Faster order search',
      MinimalTaskStatus.backlog,
      MinimalPriority.low,
      _me,
      _Label.chore,
    ),
  ],
  [
    _issue(
      'ENG-155',
      'Refunds lose the tip line',
      MinimalTaskStatus.active,
      MinimalPriority.high,
      'Oskar Lind',
      _Label.bug,
    ),
    _issue(
      'ENG-158',
      'Reader pairing fails',
      MinimalTaskStatus.todo,
      MinimalPriority.urgent,
      'Ines Duarte',
      _Label.bug,
    ),
    _issue(
      'ENG-161',
      'Weekend pre-orders',
      MinimalTaskStatus.todo,
      MinimalPriority.medium,
      'Tom Alves',
      _Label.feature,
    ),
    _issue(
      'ENG-127',
      'Staff roles and PINs',
      MinimalTaskStatus.backlog,
      MinimalPriority.low,
      'Hanna Berg',
      _Label.feature,
    ),
    _issue(
      'ENG-119',
      'Print labels for trays',
      MinimalTaskStatus.backlog,
      MinimalPriority.none,
      'Liv Sande',
    ),
  ],
  [
    _issue(
      'ENG-144',
      'Sync stalls on wifi',
      MinimalTaskStatus.active,
      MinimalPriority.urgent,
      'Tom Alves',
      _Label.bug,
    ),
    _issue(
      'ENG-146',
      'New receipt layout',
      MinimalTaskStatus.active,
      MinimalPriority.medium,
      'Liv Sande',
      _Label.design,
    ),
    _issue(
      'ENG-153',
      'Hourly sales chart',
      MinimalTaskStatus.todo,
      MinimalPriority.medium,
      'Oskar Lind',
      _Label.feature,
    ),
    _issue(
      'ENG-112',
      'Retire old price list',
      MinimalTaskStatus.backlog,
      MinimalPriority.low,
      'Hanna Berg',
      _Label.chore,
    ),
  ],
];

/// The issue [id] names, from any view.
_Issue? _byId(String id) {
  for (final view in _views) {
    for (final issue in view) {
      if (issue.id == id) return issue;
    }
  }
  return null;
}

/// The title of issue [id], for a line that names it.
String kitIssueTitle(String id) => _byId(id)?.title ?? id;

/// What an issue says, past its title: the ones the Tracker opens on and
/// its Inbox points at.
const Map<String, String> _descriptions = {
  'ENG-142':
      'A promo code typed at the till is accepted, then the total ignores '
      'it. Seen on the Lund till twice this week; the receipt prints the '
      'full price.',
  'ENG-157':
      'Let a table pay in parts: pick the items each card pays for, or '
      'split the total evenly. The reader takes one card at a time.',
  'ENG-138':
      'When the wifi drops, orders wait in a queue on the till and go out '
      'in order once it is back, with a count on the status bar.',
  'ENG-149':
      'Line totals round before tax, the order total after: a basket of '
      'nine buns comes out a cent off.',
  'ENG-121':
      'The order ticket in the dark appearance: the stage colours read too '
      'loud on the black.',
  'ENG-151':
      'A long product name runs off the receipt\'s right edge instead of '
      'wrapping.',
};

/// What happened to an issue, newest first: when, who, what.
typedef _Event = ({DateTime at, String who, String what});

/// The issues' trails past their creation: what the Tracker's Inbox lists.
final Map<String, List<_Event>> _events = {
  'ENG-157': [
    (
      at: DateTime(2026, 8, 28, 9, 39),
      who: 'Oskar Lind',
      what: 'assigned it to you',
    ),
  ],
  'ENG-142': [
    (
      at: DateTime(2026, 8, 28, 9, 6),
      who: 'Ines Duarte',
      what: 'commented: "Seen it twice on the Lund till"',
    ),
    (
      at: DateTime(2026, 8, 27, 16, 20),
      who: 'Mira Holt',
      what: 'moved it to In progress',
    ),
  ],
  'ENG-138': [
    (
      at: DateTime(2026, 8, 28, 7, 48),
      who: 'Tom Alves',
      what: 'moved it to In progress',
    ),
  ],
  'ENG-149': [
    (
      at: DateTime(2026, 8, 28, 6, 48),
      who: 'Hanna Berg',
      what: 'raised the priority to Medium',
    ),
  ],
  'ENG-121': [
    (at: DateTime(2026, 8, 27, 15, 2), who: 'Liv Sande', what: 'mentioned you'),
  ],
};

/// One issue as its own page: the id and title, its properties, what it
/// says and what happened to it. [parent] names the list a pushed page
/// returns to; null, it stands beside that list.
class KitIssuePage extends StatelessWidget {
  const KitIssuePage({super.key, required this.id, this.parent});

  final String id;
  final String? parent;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final issue = _byId(id);
    if (issue == null) return const MinimalScaffold(body: SizedBox.shrink());
    final label = issue.label;
    final description = _descriptions[issue.id];
    return MinimalScaffold(
      topBar: MinimalAppBar(parent: parent, subtitle: issue.id),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(header: true, child: Text(issue.title, style: t.h1)),
          const MinimalGap(MinimalSpacing.s16),
          MinimalDescriptionList(
            properties: [
              MinimalProperty(
                icon: LucideIcons.circleDot,
                label: 'Status',
                value: issue.status.label,
              ),
              MinimalProperty(
                icon: LucideIcons.signal,
                label: 'Priority',
                value: issue.priority.label,
              ),
              MinimalProperty(
                icon: LucideIcons.circleUser,
                label: 'Assignee',
                value: issue.assignee == _me ? 'You' : issue.assignee,
              ),
              MinimalProperty(
                icon: LucideIcons.tag,
                label: 'Label',
                value: label?.text,
                tone: label?.tone,
                placeholder: 'None',
              ),
            ],
          ),
          const MinimalSectionHeader(
            'Description',
            padding: EdgeInsets.fromLTRB(
              0,
              MinimalSpacing.s24,
              0,
              MinimalSpacing.s8,
            ),
          ),
          Text(
            description ?? 'No description yet.',
            style: description == null ? t.body.c(t.mutedForeground) : t.body,
          ),
          const MinimalSectionHeader(
            'Activity',
            padding: EdgeInsets.fromLTRB(
              0,
              MinimalSpacing.s24,
              0,
              MinimalSpacing.s4,
            ),
          ),
          MinimalTimeline(
            entries: [
              for (final event in _events[issue.id] ?? const <_Event>[])
                MinimalActivity(
                  at: event.at,
                  actor: event.who,
                  text: event.what,
                ),
              MinimalActivity(
                at: DateTime(2026, 8, 20, 11, 15),
                actor: issue.assignee,
                text: 'created the issue',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The My issues root: the bar with the priority filter, the view switch,
/// then the issues grouped by status. [open] marks the issue shown beside
/// the list and [onOpen] opens one; without them a tap only selects.
/// [leading] stands at the bar's start (an app's way out).
class KitIssuesPage extends StatefulWidget {
  const KitIssuesPage({super.key, this.open, this.onOpen, this.leading});

  final String? open;
  final ValueChanged<String>? onOpen;
  final Widget? leading;

  @override
  State<KitIssuesPage> createState() => _KitIssuesPageState();
}

class _KitIssuesPageState extends State<KitIssuesPage> {
  int _view = 0;
  MinimalPriority? _priority;
  final Set<MinimalTaskStatus> _folded = {};
  String? _selected;

  String? get _open => widget.onOpen == null ? _selected : widget.open;

  void _tap(String id) {
    final onOpen = widget.onOpen;
    onOpen == null ? setState(() => _selected = id) : onOpen(id);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final priority = _priority;
    final issues = [
      for (final issue in _views[_view])
        if (priority == null || issue.priority == priority) issue,
    ];
    return MinimalScaffold(
      topBar: MinimalAppBar(
        leading: widget.leading,
        title: 'My issues',
        actions: [
          MinimalMenu.button(
            LucideIcons.listFilter,
            // A filter in force shows in the bar: the pill names it.
            text: priority?.label,
            label: 'Filter by priority',
            items: [
              MinimalMenuItem(
                'Any priority',
                selected: priority == null,
                onPressed: () => setState(() => _priority = null),
              ),
              for (final (i, p) in MinimalPriority.values.indexed)
                MinimalMenuItem(
                  p.label,
                  selected: p == priority,
                  startsGroup: i == 0,
                  onPressed: () => setState(() => _priority = p),
                ),
            ],
          ),
        ],
      ),
      padding: EdgeInsets.zero,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(border: Border(bottom: t.rule)),
            padding: const EdgeInsets.symmetric(
              horizontal: MinimalChromeMetrics.gutter,
              vertical: MinimalSpacing.s12,
            ),
            // A phone's switch spans the width; a wider list's keeps to its
            // words at the start.
            child: LayoutBuilder(
              builder: (context, box) => Align(
                alignment: AlignmentDirectional.centerStart,
                child: MinimalSegmentedButton(
                  expand: box.maxWidth < _naturalFrom,
                  segments: const [
                    MinimalButtonSegment(0, 'Assigned'),
                    MinimalButtonSegment(1, 'Created'),
                    MinimalButtonSegment(2, 'Subscribed'),
                  ],
                  value: _view,
                  label: 'Issues',
                  onChanged: (i) => setState(() {
                    _view = i;
                    _selected = null;
                  }),
                ),
              ),
            ),
          ),
          if (issues.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: MinimalSpacing.s48),
              child: MinimalEmptyState(
                icon: LucideIcons.listFilter,
                title: priority == MinimalPriority.none
                    ? 'Every issue has a priority'
                    : 'No ${priority?.label.toLowerCase()}-priority issues',
                body: 'Nothing in this view matches the filter.',
                actionLabel: 'Clear filter',
                onAction: () => setState(() => _priority = null),
              ),
            ),
          for (final status in _groups)
            if (issues.where((i) => i.status == status).toList()
                case final group when group.isNotEmpty) ...[
              MinimalSectionHeader(
                status.label,
                leading: MinimalStatusIcon(status, size: MinimalIconSize.i14),
                count: '${group.length}',
                expanded: !_folded.contains(status),
                onExpansionChanged: (_) => setState(() {
                  if (!_folded.remove(status)) _folded.add(status);
                }),
              ),
              MinimalListSection(
                children: [
                  for (final issue in group)
                    MinimalReveal(
                      visible: !_folded.contains(status),
                      child: _IssueRow(
                        issue,
                        selected: issue.id == _open,
                        onTap: () => _tap(issue.id),
                      ),
                    ),
                ],
              ),
            ],
        ],
      ),
    );
  }
}

/// From this wide the view switch keeps to its words rather than spanning
/// the list.
const double _naturalFrom = MinimalLayout.compact;

/// One issue as the library's list row: priority, id and status lead the
/// title; the label (every label the same neutral pill, told apart by its
/// dot) closes it, and the assignee's face when it is someone else's.
class _IssueRow extends StatelessWidget {
  const _IssueRow(this.issue, {required this.selected, required this.onTap});

  final _Issue issue;
  final bool selected;
  final VoidCallback onTap;

  /// Past this text scale the label pill leaves the title's line for the
  /// line under it, so the title keeps its words rather than its pill.
  static const double _stackAbove = 1.15;

  /// Under this width a row keeps one trailing thing: with a face to show,
  /// the label pill takes the line under the title.
  static const double _oneTrailingUnder = 480;

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, box) => _row(context, box.maxWidth));

  Widget _row(BuildContext context, double width) {
    final t = context.minimalTheme;
    final label = issue.label;
    final face = issue.assignee != _me;
    final stacked =
        MediaQuery.textScalerOf(context).scale(10) / 10 > _stackAbove ||
        (face && width < _oneTrailingUnder);
    final tag = label == null ? null : MinimalTag(label.text, dot: label.tone);
    final trailing = <Widget>[
      if (tag != null && !stacked) tag,
      // A face says whose issue it is: on my own there is nothing to say.
      if (face) ...[
        if (tag != null && !stacked) const MinimalGap(MinimalSpacing.s8),
        MinimalAvatar(issue.assignee, size: 24),
      ],
    ];
    return MinimalListTile(
      title: issue.title,
      selected: selected ? true : null,
      onTap: onTap,
      below: stacked && tag != null
          ? Align(alignment: AlignmentDirectional.centerStart, child: tag)
          : null,
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          MinimalPriorityIcon(issue.priority),
          const MinimalGap(MinimalSpacing.s8),
          Text(issue.id, style: t.mono.c(t.mutedForeground)),
          const MinimalGap(MinimalSpacing.s8),
          MinimalStatusIcon(issue.status),
        ],
      ),
      trailing: trailing.isEmpty
          ? null
          : Row(mainAxisSize: MainAxisSize.min, children: trailing),
    );
  }
}
