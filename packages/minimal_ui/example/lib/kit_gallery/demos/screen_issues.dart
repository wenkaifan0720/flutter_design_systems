/// The Screen · Issues gallery group: an issue tracker's "My issues" root
/// over its own tab bar — Assigned · Created · Subscribed (live: each has
/// its own issues), then the issues grouped by status, each group header
/// leading with its status glyph and ending in its count, and one 44 px
/// row per issue: priority, the mono id, the status glyph, the title, a
/// label tag and the assignee. The filter menu narrows by priority, a group
/// header folds its group, a tap selects an issue (in the example's
/// Tracker, opens it: [KitIssuePage]).
library;

import 'package:material_ui/material_ui.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';
import '../kit_words.dart';

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

List<MinimalNavItem> get _tabs => [
  MinimalNavItem(LucideIcons.inbox, ar('Inbox', 'الوارد')),
  MinimalNavItem(LucideIcons.circleUser, ar('My issues', 'مهامي')),
  MinimalNavItem(LucideIcons.folderKanban, ar('Projects', 'المشاريع')),
  MinimalNavItem(LucideIcons.layers, ar('Views', 'العروض')),
];

/// What kind of work an issue is; null prints no tag.
enum _Label {
  bug('Bug', 'خلل', MinimalTone.destructive),
  feature('Feature', 'ميزة', MinimalTone.primary),
  design('Design', 'تصميم', MinimalTone.neutral),
  chore('Chore', 'صيانة', MinimalTone.neutral);

  const _Label(this.english, this.arabic, this.tone);

  final String english;
  final String arabic;
  final MinimalTone tone;

  /// The kind's name in the gallery's language.
  String get text => ar(english, arabic);
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
String get _me => ar('Mira Holt', 'ليلى حداد');

/// The statuses a list groups by, in the order it shows them.
const List<MinimalTaskStatus> _groups = [
  MinimalTaskStatus.active,
  MinimalTaskStatus.todo,
  MinimalTaskStatus.backlog,
];

/// The issues of each view: assigned to me, created by me, subscribed to.
List<List<_Issue>> get _views => [
  [
    _issue(
      'ENG-142',
      ar('Promo codes ignored', 'رموز الخصم مُتجاهَلة'),
      MinimalTaskStatus.active,
      MinimalPriority.urgent,
      _me,
      _Label.bug,
    ),
    _issue(
      'ENG-138',
      ar('Offline order queue', 'طابور الطلبات دون اتصال'),
      MinimalTaskStatus.active,
      MinimalPriority.high,
      _me,
      _Label.feature,
    ),
    _issue(
      'ENG-151',
      ar('Receipts cut off long lines', 'الإيصالات تقطع الأسطر الطويلة'),
      MinimalTaskStatus.active,
      MinimalPriority.medium,
      _me,
    ),
    _issue(
      'ENG-157',
      ar('Split bills by card', 'تقسيم الفاتورة على البطاقات'),
      MinimalTaskStatus.todo,
      MinimalPriority.high,
      _me,
      _Label.feature,
    ),
    _issue(
      'ENG-149',
      ar('Tax rounding off', 'تقريب الضريبة خاطئ'),
      MinimalTaskStatus.todo,
      MinimalPriority.medium,
      _me,
      _Label.bug,
    ),
    _issue(
      'ENG-133',
      ar('Migrate settings', 'نقل الإعدادات'),
      MinimalTaskStatus.todo,
      MinimalPriority.medium,
      _me,
      _Label.chore,
    ),
    _issue(
      'ENG-160',
      ar('Double tap bumps a ticket', 'النقر المزدوج يرفع التذكرة'),
      MinimalTaskStatus.todo,
      MinimalPriority.low,
      _me,
    ),
    _issue(
      'ENG-162',
      ar('Empty reports state', 'حالة التقارير الفارغة'),
      MinimalTaskStatus.todo,
      MinimalPriority.low,
      _me,
      _Label.design,
    ),
    _issue(
      'ENG-121',
      ar('Dark order ticket', 'تذكرة الطلب الداكنة'),
      MinimalTaskStatus.backlog,
      MinimalPriority.low,
      _me,
      _Label.design,
    ),
    _issue(
      'ENG-117',
      ar('CSV customer export', 'تصدير العملاء بصيغة CSV'),
      MinimalTaskStatus.backlog,
      MinimalPriority.none,
      _me,
      _Label.feature,
    ),
    _issue(
      'ENG-109',
      ar('Loyalty stamps on receipts', 'أختام الولاء على الإيصالات'),
      MinimalTaskStatus.backlog,
      MinimalPriority.none,
      _me,
    ),
    _issue(
      'ENG-104',
      ar('Faster order search', 'بحث أسرع في الطلبات'),
      MinimalTaskStatus.backlog,
      MinimalPriority.low,
      _me,
      _Label.chore,
    ),
  ],
  [
    _issue(
      'ENG-155',
      ar('Refunds lose the tip line', 'المبالغ المستردة تُسقط سطر البقشيش'),
      MinimalTaskStatus.active,
      MinimalPriority.high,
      ar('Oskar Lind', 'عمر الخطيب'),
      _Label.bug,
    ),
    _issue(
      'ENG-158',
      ar('Reader pairing fails', 'إقران قارئ البطاقات يفشل'),
      MinimalTaskStatus.todo,
      MinimalPriority.urgent,
      ar('Ines Duarte', 'هالة منصور'),
      _Label.bug,
    ),
    _issue(
      'ENG-161',
      ar('Weekend pre-orders', 'طلبات مسبقة لعطلة الأسبوع'),
      MinimalTaskStatus.todo,
      MinimalPriority.medium,
      ar('Tom Alves', 'طارق عيسى'),
      _Label.feature,
    ),
    _issue(
      'ENG-127',
      ar('Staff roles and PINs', 'أدوار الموظفين ورموزهم'),
      MinimalTaskStatus.backlog,
      MinimalPriority.low,
      ar('Hanna Berg', 'هند البرغوثي'),
      _Label.feature,
    ),
    _issue(
      'ENG-119',
      ar('Print labels for trays', 'طباعة ملصقات للصواني'),
      MinimalTaskStatus.backlog,
      MinimalPriority.none,
      ar('Liv Sande', 'لينا سعادة'),
    ),
  ],
  [
    _issue(
      'ENG-144',
      ar('Sync stalls on wifi', 'المزامنة تتعطل على الواي فاي'),
      MinimalTaskStatus.active,
      MinimalPriority.urgent,
      ar('Tom Alves', 'طارق عيسى'),
      _Label.bug,
    ),
    _issue(
      'ENG-146',
      ar('New receipt layout', 'تخطيط جديد للإيصال'),
      MinimalTaskStatus.active,
      MinimalPriority.medium,
      ar('Liv Sande', 'لينا سعادة'),
      _Label.design,
    ),
    _issue(
      'ENG-153',
      ar('Hourly sales chart', 'مخطط المبيعات بالساعة'),
      MinimalTaskStatus.todo,
      MinimalPriority.medium,
      ar('Oskar Lind', 'عمر الخطيب'),
      _Label.feature,
    ),
    _issue(
      'ENG-112',
      ar('Retire old price list', 'إلغاء قائمة الأسعار القديمة'),
      MinimalTaskStatus.backlog,
      MinimalPriority.low,
      ar('Hanna Berg', 'هند البرغوثي'),
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
Map<String, String> get _descriptions => {
  'ENG-142': ar(
    'A promo code typed at the till is accepted, then the total ignores '
        'it. Seen on the Lund till twice this week; the receipt prints the '
        'full price.',
    'يُقبل رمز الخصم المكتوب عند الصندوق، ثم يتجاهله المجموع. رأيناه في '
        'صندوق لوند مرتين هذا الأسبوع؛ والإيصال يطبع السعر كاملًا.',
  ),
  'ENG-157': ar(
    'Let a table pay in parts: pick the items each card pays for, or '
        'split the total evenly. The reader takes one card at a time.',
    'دع الطاولة تدفع على أجزاء: اختر ما تدفعه كل بطاقة، أو قسّم المجموع '
        'بالتساوي. يقرأ الجهاز بطاقة واحدة في كل مرة.',
  ),
  'ENG-138': ar(
    'When the wifi drops, orders wait in a queue on the till and go out '
        'in order once it is back, with a count on the status bar.',
    'حين ينقطع الواي فاي تنتظر الطلبات في طابور على الصندوق، وتُرسل '
        'بالترتيب حين يعود، مع عدّاد في شريط الحالة.',
  ),
  'ENG-149': ar(
    'Line totals round before tax, the order total after: a basket of '
        'nine buns comes out a cent off.',
    'تُقرَّب مجاميع البنود قبل الضريبة ومجموع الطلب بعدها: فتخرج سلة من '
        'تسع كعكات بفارق سنت.',
  ),
  'ENG-121': ar(
    'The order ticket in the dark appearance: the stage colours read too '
        'loud on the black.',
    'تذكرة الطلب في المظهر الداكن: ألوان المراحل صارخة أكثر من اللازم '
        'على الأسود.',
  ),
  'ENG-151': ar(
    'A long product name runs off the receipt\'s right edge instead of '
        'wrapping.',
    'اسم المنتج الطويل يتجاوز حافة الإيصال بدل أن يلتف إلى سطر جديد.',
  ),
};

/// What happened to an issue, newest first: when, who, what.
typedef _Event = ({DateTime at, String who, String what});

/// The issues' trails past their creation: what the Tracker's Inbox lists.
Map<String, List<_Event>> get _events => {
  'ENG-157': [
    (
      at: DateTime(2026, 8, 28, 9, 39),
      who: ar('Oskar Lind', 'عمر الخطيب'),
      what: ar('assigned it to you', 'أسندها إليك'),
    ),
  ],
  'ENG-142': [
    (
      at: DateTime(2026, 8, 28, 9, 6),
      who: ar('Ines Duarte', 'هالة منصور'),
      what: ar(
        'commented: “Seen it twice on the Lund till”',
        'علّقت: «رأيتها مرتين على صندوق لوند»',
      ),
    ),
    (
      at: DateTime(2026, 8, 27, 16, 20),
      who: ar('Mira Holt', 'ليلى حداد'),
      what: ar('moved it to In progress', 'نقلها إلى «قيد التنفيذ»'),
    ),
  ],
  'ENG-138': [
    (
      at: DateTime(2026, 8, 28, 7, 48),
      who: ar('Tom Alves', 'طارق عيسى'),
      what: ar('moved it to In progress', 'نقلها إلى «قيد التنفيذ»'),
    ),
  ],
  'ENG-149': [
    (
      at: DateTime(2026, 8, 28, 6, 48),
      who: ar('Hanna Berg', 'هند البرغوثي'),
      what: ar('raised the priority to Medium', 'رفعت الأولوية إلى «متوسطة»'),
    ),
  ],
  'ENG-121': [
    (
      at: DateTime(2026, 8, 27, 15, 2),
      who: ar('Liv Sande', 'لينا سعادة'),
      what: ar('mentioned you', 'أشارت إليك'),
    ),
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
                label: ar('Status', 'الحالة'),
                value: issue.status.labelIn(context),
              ),
              MinimalProperty(
                icon: LucideIcons.signal,
                label: ar('Priority', 'الأولوية'),
                value: issue.priority.labelIn(context),
              ),
              MinimalProperty(
                icon: LucideIcons.circleUser,
                label: ar('Assignee', 'المسؤول'),
                value: issue.assignee == _me
                    ? ar('You', 'أنت')
                    : issue.assignee,
              ),
              MinimalProperty(
                icon: LucideIcons.tag,
                label: ar('Label', 'التصنيف'),
                value: label?.text,
                tone: label?.tone,
                placeholder: ar('None', 'لا شيء'),
              ),
            ],
          ),
          MinimalSectionHeader(
            ar('Description', 'الوصف'),
            padding: EdgeInsets.fromLTRB(
              0,
              MinimalSpacing.s24,
              0,
              MinimalSpacing.s8,
            ),
          ),
          Text(
            description ?? ar('No description yet.', 'لا وصف بعد.'),
            style: description == null ? t.body.c(t.mutedForeground) : t.body,
          ),
          MinimalSectionHeader(
            ar('Activity', 'النشاط'),
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
                text: ar('created the issue', 'أنشأت المهمة'),
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
        title: ar('My issues', 'مهامي'),
        actions: [
          MinimalMenu.button(
            LucideIcons.listFilter,
            // A filter in force shows in the bar: the pill names it.
            text: priority?.labelIn(context),
            semanticLabel: ar('Filter by priority', 'التصفية حسب الأولوية'),
            items: [
              MinimalMenuItem(
                ar('Any priority', 'أي أولوية'),
                selected: priority == null,
                onPressed: () => setState(() => _priority = null),
              ),
              for (final (i, p) in MinimalPriority.values.indexed)
                MinimalMenuItem(
                  p.labelIn(context),
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
            // words at the start. From 160% text it keeps its words whole
            // and scrolls sideways when they outrun the width.
            child: LayoutBuilder(
              builder: (context, box) {
                final big =
                    MediaQuery.textScalerOf(context).scale(10) / 10 >=
                    MinimalChromeMetrics.rowStackScale;
                final views = MinimalSegmentedButton(
                  expand: !big && box.maxWidth < _naturalFrom,
                  segments: [
                    MinimalButtonSegment(0, ar('Assigned', 'المسندة')),
                    MinimalButtonSegment(1, ar('Created', 'المنشأة')),
                    MinimalButtonSegment(2, ar('Subscribed', 'المتابَعة')),
                  ],
                  value: _view,
                  semanticLabel: ar('Issues', 'المهام'),
                  onChanged: (i) => setState(() {
                    _view = i;
                    _selected = null;
                  }),
                );
                return Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: big
                      ? SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: views,
                        )
                      : views,
                );
              },
            ),
          ),
          if (issues.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: MinimalSpacing.s48),
              child: MinimalEmptyState(
                icon: LucideIcons.listFilter,
                title: priority == MinimalPriority.none
                    ? ar('Every issue has a priority', 'لكل مهمة أولوية')
                    : ar(
                        'No ${priority?.label.toLowerCase()}-priority issues',
                        'لا مهام بأولوية '
                            '${priority?.labelIn(context) ?? ''}',
                      ),
                body: ar(
                  'Nothing in this view matches the filter.',
                  'لا شيء في هذا العرض يطابق التصفية.',
                ),
                actionLabel: ar('Clear filter', 'مسح التصفية'),
                onAction: () => setState(() => _priority = null),
              ),
            ),
          for (final status in _groups)
            if (issues.where((i) => i.status == status).toList()
                case final group when group.isNotEmpty) ...[
              MinimalSectionHeader(
                status.labelIn(context),
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
    final scale = MediaQuery.textScalerOf(context).scale(10) / 10;
    final stacked = scale > _stackAbove || (face && width < _oneTrailingUnder);
    // From 160% text the id leaves the lead for the line under the title,
    // which keeps the title's words rather than a wide mono column.
    final idUnder = scale >= MinimalChromeMetrics.rowStackScale;
    final id = Text(
      issue.id,
      style: t.mono.c(t.mutedForeground),
      textDirection: TextDirection.ltr,
    );
    final tag = label == null ? null : MinimalTag(label.text, dot: label.tone);
    final under = [if (idUnder) id, if (stacked && tag != null) tag];
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
      below: under.isEmpty
          ? null
          : Align(
              alignment: AlignmentDirectional.centerStart,
              child: Wrap(
                spacing: MinimalSpacing.s8,
                runSpacing: MinimalSpacing.s4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: under,
              ),
            ),
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          MinimalPriorityIcon(issue.priority),
          const MinimalGap(MinimalSpacing.s8),
          if (!idUnder) ...[id, const MinimalGap(MinimalSpacing.s8)],
          MinimalStatusIcon(issue.status),
        ],
      ),
      trailing: trailing.isEmpty
          ? null
          : Row(mainAxisSize: MainAxisSize.min, children: trailing),
    );
  }
}
