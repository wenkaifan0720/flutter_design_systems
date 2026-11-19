// The reader's own pages: their applications (filters beside the list
// from 1024 wide, above it below), one application's record (its answers,
// its documents, its history and what can be done with it) and their
// settings, a form of parts and nothing else. On a tablet (600 to 1024
// wide) the list and the open record stand side by side. Each list has its
// empty state and its unavailable one.
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:civic_ui/civic_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'permits.dart';

typedef _Event = ({String title, String date, String? words});

typedef _Application = ({
  String title,
  String reference,
  String sent,
  String sentOn,
  String status,
  String vehicle,
  List<String> documents,
  List<_Event> history,
});

const List<_Application> _applications = [
  (
    title: 'Resident permit, Zone\u00A0B',
    reference: 'BRM-4821-K',
    sent: 'Sent 3\u00A0November',
    sentOn: '3 November 2026',
    status: 'review',
    vehicle: 'Car or van',
    documents: ['tenancy-agreement.pdf', 'application-summary.pdf'],
    history: [
      (
        title: 'Proof of address checked',
        date: '5 November 2026',
        words: 'We matched your tenancy agreement to your address.',
      ),
      (
        title: 'Application received',
        date: '3 November 2026',
        words: 'We will decide within 5 working days.',
      ),
    ],
  ),
  (
    title: 'Visitor permits, 10\u00A0days',
    reference: 'BRM-3307-A',
    sent: 'Sent 12\u00A0October',
    sentOn: '12 October 2026',
    status: 'approved',
    vehicle: 'Car or van',
    documents: ['tenancy-agreement.pdf'],
    history: [
      (
        title: 'Permit approved',
        date: '14 October 2026',
        words: 'Your visitor permits are ready to use.',
      ),
      (title: 'Application received', date: '12 October 2026', words: null),
    ],
  ),
  (
    title: 'Second permit, Zone\u00A0B',
    reference: 'BRM-2914-C',
    sent: 'Sent 2\u00A0September',
    sentOn: '2 September 2026',
    status: 'refused',
    vehicle: 'Motorcycle',
    documents: ['council-tax-bill.pdf'],
    history: [
      (
        title: 'Application refused',
        date: '9 September 2026',
        words: 'A household in Zone\u00A0B can hold two resident permits.',
      ),
      (title: 'Application received', date: '2 September 2026', words: null),
    ],
  ),
];

const _statuses = [
  ('review', 'In review', CivicTone.info),
  ('approved', 'Approved', CivicTone.success),
  ('refused', 'Refused', CivicTone.error),
];

/// The width of a filter column beside a list, from 1024 wide: its short
/// options' names and no more, so the list keeps the room.
const double permitsFilterWidth = 240;

/// The width of a tablet's list pane, beside the open record.
const double permitsListPane = 320;

/// Whether the applications and a record stand side by side: a tablet's
/// app (600 to 1024 wide) with applications to show.
bool permitsPanes(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  return CivicLayout.isApp(width) &&
      width >= CivicLayout.medium &&
      context.permits.condition == PermitsCondition.usual;
}

/// An app's filters folded into a row on a card that opens them in place;
/// the site's, help-like, under a fold.
Widget permitsFilterFold(
  BuildContext context, {
  required String filterTitle,
  required Widget filters,
}) {
  final state = context.permits;
  return CivicLayout.isApp(MediaQuery.sizeOf(context).width)
      ? CivicListGroup(
          children: [
            CivicListRow(
              leading: const Icon(LucideIcons.listFilter),
              title: Text(filterTitle),
              endIcon: state.filtersOpen
                  ? LucideIcons.chevronUp
                  : LucideIcons.chevronDown,
              onTap: () {
                state.filtersOpen = !state.filtersOpen;
                state.changed();
              },
            ),
            if (state.filtersOpen)
              Padding(
                padding: const EdgeInsets.all(CivicSpacing.s16),
                child: filters,
              ),
          ],
        )
      : CivicDetails(title: filterTitle, child: filters);
}

/// A page with a filter column and a reading column: side by side when the
/// page's column has room for both (a wide window without the side
/// navigation); otherwise [lead] (a search box) first, then the filters
/// folded under [filterTitle] so the list stays in sight, then the list.
Widget permitsFilteredBody(
  BuildContext context, {
  required String title,
  required String filterTitle,
  required Widget filters,
  required List<Widget> main,
  List<Widget> lead = const [],
  Widget? backLink,
}) {
  final fold = permitsFilterFold(
    context,
    filterTitle: filterTitle,
    filters: filters,
  );
  Widget stacked() => Align(
    alignment: AlignmentDirectional.topStart,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: CivicLayout.readingWidth),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          ...lead,
          if (lead.isNotEmpty) const SizedBox(height: CivicSpacing.s24),
          fold,
          const SizedBox(height: CivicSpacing.s24),
          ...main,
        ],
      ),
    ),
  );
  // The filters' legend and the list's first line share a baseline.
  Widget beside() => Row(
    crossAxisAlignment: CrossAxisAlignment.baseline,
    textBaseline: TextBaseline.alphabetic,
    children: [
      SizedBox(width: permitsFilterWidth, child: filters),
      const SizedBox(width: CivicSpacing.s48),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            ...lead,
            if (lead.isNotEmpty) const SizedBox(height: CivicSpacing.s32),
            ...main,
          ],
        ),
      ),
    ],
  );
  return CivicPageBody(
    title: title,
    backLink: backLink,
    maxWidth: CivicLayout.pageWidth,
    children: [
      LayoutBuilder(
        builder: (context, column) =>
            column.maxWidth >=
                CivicLayout.readingWidth + permitsFilterWidth + CivicSpacing.s48
            ? beside()
            : stacked(),
      ),
    ],
  );
}

/// The page a service shows when part of it cannot do its job: names what
/// is down ([title]), says what is safe, offers to try again and, with
/// [onElse], what to do instead.
class PermitsUnavailable extends StatelessWidget {
  /// [title] is down; [safe] says what the reader keeps.
  const PermitsUnavailable({
    super.key,
    required this.title,
    required this.safe,
    this.backLink,
    this.elseLabel,
    this.onElse,
  });

  /// What is down, in a sentence: the page's heading.
  final String title;

  /// What the reader has not lost.
  final String safe;

  /// The way back, when the page has one.
  final Widget? backLink;

  /// What the reader can do instead, as a link.
  final String? elseLabel;

  /// Does it.
  final VoidCallback? onElse;

  @override
  Widget build(BuildContext context) {
    final state = context.permits;
    final other = elseLabel;
    return CivicPageBody(
      backLink: backLink,
      children: [
        CivicEmptyState(
          title: context.say(title),
          isPageHeading: true,
          announce: true,
          // Trying again first, as the page's one button; the other way
          // after it.
          actions: [
            CivicButton(
              onPressed: () {
                state.condition = PermitsCondition.usual;
                state.changed();
              },
              child: Text(DesignLocalizations.of(context).retryButtonLabel),
            ),
            if (other != null)
              CivicLink(onPressed: onElse, child: Text(context.say(other))),
          ],
          children: [
            Text(context.say(safe)),
            // A way to a person when the service is down.
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: CivicLink(
                onPressed: () {},
                child: Text(context.say('Contact the parking team')),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

String _statusLabel(String id) => _statuses.firstWhere((s) => s.$1 == id).$2;
CivicTone _statusTone(String id) => _statuses.firstWhere((s) => s.$1 == id).$3;

/// The reader's applications, each a row going to its record, with a
/// status; filters by status beside them from 1024 wide.
class PermitsApplicationsPage extends StatelessWidget {
  /// The applications page.
  const PermitsApplicationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.permits;
    if (permitsPanes(context)) return const _ApplicationPanes();
    if (state.condition == PermitsCondition.unavailable) {
      return const PermitsUnavailable(
        title: 'Sorry, we cannot show your applications right now',
        safe: 'Your applications are safe: nothing has been lost.',
      );
    }
    final title = context.say('Your applications');
    if (state.condition == PermitsCondition.empty) {
      return CivicPageBody(
        title: title,
        children: [
          CivicEmptyState(
            title: context.say('You have no applications yet'),
            actions: [
              CivicButton(
                onPressed: () => state.go(PermitsPage.start),
                child: Text(context.say('Apply for a permit')),
              ),
            ],
            children: [
              Text(
                context.say('When you apply for a permit, it will show here.'),
              ),
            ],
          ),
        ],
      );
    }
    return permitsFilteredBody(
      context,
      title: title,
      filterTitle: context.say('Filter by status'),
      filters: _statusFilters(context),
      main: _applicationsList(context),
    );
  }
}

/// The status filters of the applications.
Widget _statusFilters(BuildContext context) {
  final state = context.permits;
  return CivicFieldset(
    labelText: context.say('Status'),
    // What a tick does, before it is ticked.
    helperText: context.say('Tick statuses to narrow the list.'),
    children: [
      for (final (id, label, _) in _statuses)
        CivicCheckbox(
          value: state.statuses.contains(id),
          labelText: context.say(label),
          onChanged: (v) {
            v == true ? state.statuses.add(id) : state.statuses.remove(id);
            state.changed();
          },
        ),
      // The list changes as a box is ticked; this undoes every tick.
      if (state.statuses.isNotEmpty)
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: CivicLink(
            onPressed: () {
              state.statuses.clear();
              state.changed();
            },
            child: Text(context.say('Clear filters')),
          ),
        ),
    ],
  );
}

/// The applications the filters keep, as rows on a card, then the way to
/// apply again; [selected] marks the one whose record stands open beside
/// them.
List<Widget> _applicationsList(BuildContext context, {String? selected}) {
  final state = context.permits;
  final shown = [
    for (final a in _applications)
      if (state.statuses.isEmpty || state.statuses.contains(a.status)) a,
  ];
  return [
    Semantics(
      liveRegion: true,
      child: Text(
        context.sayCount(
          shown.length,
          one: 'Showing 1 application',
          other: 'Showing # applications',
        ),
        style: context.civicText.caption,
      ),
    ),
    // The filters applied, each a chip a press removes (beside the boxes
    // that tick them, for a reader who scrolled past those).
    if (state.statuses.isNotEmpty) ...[
      const SizedBox(height: CivicSpacing.s8),
      Wrap(
        spacing: CivicSpacing.s8,
        runSpacing: CivicSpacing.s8,
        children: [
          for (final (id, label, _) in _statuses)
            if (state.statuses.contains(id))
              CivicChip.removable(
                label: context.say(label),
                onDeleted: () {
                  state.statuses.remove(id);
                  state.changed();
                },
              ),
        ],
      ),
    ],
    const SizedBox(height: CivicSpacing.s8),
    if (shown.isEmpty)
      Padding(
        padding: const EdgeInsets.symmetric(vertical: CivicSpacing.s24),
        child: CivicEmptyState(
          title: context.say('No applications match'),
          announce: true,
          children: [
            Text(context.say('Clear the filters to see every application.')),
          ],
        ),
      )
    else
      CivicListGroup(
        children: [
          for (final a in shown)
            CivicListRow(
              title: Text(context.say(a.title)),
              subtitle: Text.rich(
                TextSpan(
                  children: [
                    permitsReference(context, a.reference),
                    TextSpan(text: ' · ${context.say(a.sent)}'),
                  ],
                ),
              ),
              trailing: CivicTag(
                label: context.say(_statusLabel(a.status)),
                tone: _statusTone(a.status),
              ),
              selected: a.reference == selected,
              // Beside the record the mark says which is open; no chevron.
              showChevron: selected == null,
              onTap: () => selected == null
                  ? state.openApplication(a.reference)
                  : state.showApplication(a.reference),
            ),
        ],
      ),
    const SizedBox(height: CivicSpacing.s32),
    Align(
      alignment: AlignmentDirectional.centerStart,
      child: CivicButton.secondary(
        onPressed: () => state.go(PermitsPage.start),
        child: Text(context.say('Apply for another permit')),
      ),
    ),
  ];
}

/// A tablet's applications: the list in a pane at the start, the open
/// record (the first, until another is chosen) beside it, the grip between
/// them.
class _ApplicationPanes extends StatelessWidget {
  const _ApplicationPanes();

  @override
  Widget build(BuildContext context) {
    final state = context.permits;
    final text = context.civicText;
    final a = _applications.firstWhere(
      (a) => a.reference == state.application,
      orElse: () => _applications.first,
    );
    final list = ListView(
      padding: EdgeInsetsDirectional.fromSTEB(
        CivicSpacing.s16,
        CivicSpacing.s32,
        CivicSpacing.s16,
        CivicSpacing.s32 + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        Semantics(
          header: true,
          child: Text(context.say('Your applications'), style: text.headingL),
        ),
        const SizedBox(height: CivicSpacing.s24),
        permitsFilterFold(
          context,
          filterTitle: context.say('Filter by status'),
          filters: _statusFilters(context),
        ),
        const SizedBox(height: CivicSpacing.s24),
        ..._applicationsList(context, selected: a.reference),
      ],
    );
    // The reader shares the room between the list and the record with the
    // grip between them; the list starts [permitsListPane] wide.
    return LayoutBuilder(
      builder: (context, box) => CivicSplitView(
        initialFraction: (permitsListPane / box.maxWidth).clamp(0.2, 0.6),
        minFirst: permitsListPane - CivicSpacing.s64,
        minSecond: permitsListPane,
        semanticLabel: context.say('Resize the list and the record'),
        first: list,
        second: KeyedSubtree(
          key: ValueKey(a.reference),
          child: _record(context, a, pane: true),
        ),
      ),
    );
  }
}

/// One application's record: its status, its answers, the documents sent
/// with it, its history newest first, and what the reader can do. From
/// 1024 wide the actions stand in a column beside the record.
class PermitsApplicationPage extends StatelessWidget {
  /// The record of the application the state has open.
  const PermitsApplicationPage({super.key});

  @override
  Widget build(BuildContext context) {
    if (permitsPanes(context)) return const _ApplicationPanes();
    final state = context.permits;
    final a = _applications.firstWhere(
      (a) => a.reference == state.application,
      orElse: () => _applications.first,
    );
    return _record(
      context,
      a,
      backLink: context.backLinkTo(PermitsPage.applications),
    );
  }
}

/// The record of [a], as its own page or beside the list.
/// Beside the list ([pane]) its heading is a size down, the list's the
/// page's.
Widget _record(
  BuildContext context,
  _Application a, {
  Widget? backLink,
  bool pane = false,
}) {
  final text = context.civicText;
  final t = context.civicTheme;
  final open = a.status == 'review';
  // A link's target is taller than its words by [room] under them: the
  // gap after a list of links gives that back, so every section stands
  // the same distance under the last thing before it.
  final line =
      MediaQuery.textScalerOf(context).scale(text.body.fontSize ?? 19) *
      (text.body.height ?? 1.25);
  final room = math.max(
    0.0,
    (DesignTapTargets.of(context).floorOn().height - line) / 2,
  );
  final actions = Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      CivicSectionHeader(title: context.say('What you can do')),
      CivicLink(
        onPressed: () {},
        child: Text(context.say('Contact the parking team')),
      ),
      if (open) ...[
        // The way that can't be undone comes last, and the page stops and
        // asks first.
        const SizedBox(height: CivicSpacing.s16),
        CivicButton.secondary(
          isDestructiveAction: true,
          onPressed: () async {
            final withdraw = await showCivicDialog<bool>(
              context: context,
              builder: (dialog) => CivicDialog(
                title: dialog.say('Withdraw this application?'),
                content: Text(
                  dialog.say(
                    'You will need to apply again to park in your zone.',
                  ),
                ),
                actions: [
                  CivicButton(
                    isDestructiveAction: true,
                    onPressed: () => Navigator.of(dialog).pop(true),
                    child: Text(dialog.say('Withdraw application')),
                  ),
                  CivicButton.secondary(
                    onPressed: () => Navigator.of(dialog).pop(false),
                    child: Text(dialog.say('Keep it')),
                  ),
                ],
              ),
            );
            if (withdraw == true && context.mounted) {
              CivicToast.show(
                context,
                context.say('We have sent you a link to withdraw it.'),
              );
            }
          },
          child: Text(context.say('Withdraw application')),
        ),
      ],
    ],
  );
  final record = <Widget>[
    Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '${context.say('Reference')} ',
            style: text.body.copyWith(color: t.textSecondary),
          ),
          permitsReference(
            context,
            a.reference,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    ),
    const SizedBox(height: CivicSpacing.s12),
    Align(
      alignment: AlignmentDirectional.centerStart,
      child: CivicTag(
        label: context.say(_statusLabel(a.status)),
        tone: _statusTone(a.status),
      ),
    ),
    const SizedBox(height: CivicSpacing.s32),
    CivicSummaryList(
      rows: [
        CivicSummaryRow(
          label: context.say('Vehicle'),
          value: Text(context.say(a.vehicle)),
        ),
        CivicSummaryRow(
          label: context.say('Address'),
          value: Text(permitsAsTyped('14 Ropewalk Row\nBrindlemere\nBR4 7QX')),
        ),
        CivicSummaryRow(
          label: context.say('Sent'),
          value: Text(context.say(a.sentOn)),
        ),
      ],
    ),
  ];
  final papers = <Widget>[
    CivicSectionHeader(title: context.say('Documents')),
    // Links a line apart, as the confirmation's, so wrapped they still
    // read as more than one.
    for (final (i, name) in a.documents.indexed) ...[
      if (i > 0) const SizedBox(height: CivicSpacing.s8),
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: CivicLink(
          onPressed: () {},
          semanticLabel: '${context.say('Open')} $name',
          child: Text(name),
        ),
      ),
    ],
    SizedBox(height: CivicSpacing.s48 - room),
    CivicSectionHeader(title: context.say('History')),
    CivicTimeline(
      entries: [
        for (final e in a.history)
          CivicTimelineEntry(
            title: context.say(e.title),
            date: context.say(e.date),
            child: e.words == null ? null : Text(context.say(e.words!)),
          ),
      ],
    ),
  ];
  // One column at every width, at the measure of the list it opens from,
  // so its right edge stays where the list's was: the record, its papers
  // and its history, then what the reader can do, the way that can't be
  // undone last of all.
  return CivicPageBody(
    backLink: backLink,
    title: pane ? null : context.say(a.title),
    children: [
      if (pane) ...[
        Semantics(
          header: true,
          child: Text(context.say(a.title), style: text.headingL),
        ),
        const SizedBox(height: CivicSpacing.s16),
      ],
      ...record,
      const SizedBox(height: CivicSpacing.s48),
      ...papers,
      const SizedBox(height: CivicSpacing.s48),
      actions,
    ],
  );
}

/// The reader's settings: contact, language, appearance and text size. A
/// form of Civic's parts only: no colour or face of its own.
class PermitsSettingsPage extends StatefulWidget {
  /// The settings page.
  const PermitsSettingsPage({super.key});

  @override
  State<PermitsSettingsPage> createState() => _PermitsSettingsPageState();
}

class _PermitsSettingsPageState extends State<PermitsSettingsPage> {
  bool _saved = false;

  @override
  Widget build(BuildContext context) {
    final state = context.permits;
    return CivicPageBody(
      title: context.say('Settings'),
      children: [
        if (_saved) ...[
          CivicNotificationBanner(
            title: context.say('Success'),
            tone: CivicTone.success,
            child: Text(context.say('Your settings have been saved')),
          ),
          const SizedBox(height: CivicSpacing.s32),
        ],
        // Each group's name is its heading, a size under the page's, and
        // every heading a name, not some names and some questions: the
        // choices are saved together, so they are boxes to tick and options
        // to pick, not switches that act at once.
        CivicFieldset(
          labelText: context.say('Contact preferences'),
          helperText: context.say('Select all that apply.'),
          children: [
            for (final (id, label) in const [
              ('email', 'Email'),
              ('text', 'Text message'),
              ('post', 'Post'),
            ])
              CivicCheckbox(
                value: state.contact.contains(id),
                labelText: context.say(label),
                onChanged: (v) {
                  v == true ? state.contact.add(id) : state.contact.remove(id);
                  state.changed();
                },
              ),
          ],
        ),
        const SizedBox(height: CivicSpacing.s48),
        CivicFieldset(
          labelText: context.say('Reminders'),
          children: [
            CivicCheckbox(
              value: state.reminders,
              onChanged: (v) {
                state.reminders = v ?? false;
                state.changed();
              },
              labelText: context.say('Renewal reminders'),
              helperText: context.say(
                'We will remind you a month before your permit ends.',
              ),
            ),
          ],
        ),
        const SizedBox(height: CivicSpacing.s48),
        CivicRadioGroup<bool>(
          labelText: context.say('Language'),
          groupValue: state.arabic,
          onChanged: (v) => state.arabic = v ?? false,
          children: const [
            CivicRadio(value: false, labelText: 'English'),
            CivicRadio(value: true, labelText: 'العربية'),
          ],
        ),
        const SizedBox(height: CivicSpacing.s48),
        CivicFieldset(
          labelText: context.say('Text size'),
          children: [
            CivicCheckbox(
              value: state.largerText,
              onChanged: (v) => state.largerText = v ?? false,
              labelText: context.say('Larger text'),
              helperText: context.say('Makes the words on every page bigger.'),
            ),
          ],
        ),
        const SizedBox(height: CivicSpacing.s48),
        CivicRadioGroup<PermitsAppearance>(
          labelText: context.say('Appearance'),
          groupValue: state.appearance,
          onChanged: (v) => state.appearance = v ?? PermitsAppearance.light,
          children: [
            CivicRadio(
              value: PermitsAppearance.light,
              labelText: context.say('Light'),
            ),
            CivicRadio(
              value: PermitsAppearance.dark,
              labelText: context.say('Dark'),
            ),
            CivicRadio(
              value: PermitsAppearance.system,
              labelText: context.say('Match this device'),
            ),
          ],
        ),
        const SizedBox(height: CivicSpacing.s48),
        CivicButton(
          onPressed: () {
            setState(() => _saved = true);
            CivicToast.show(
              context,
              context.say('Your settings have been saved'),
            );
          },
          child: Text(context.say('Save settings')),
        ),
      ],
    );
  }
}
