/// The live gallery: every exported part, working, on pages with plain names. The specimen matrices stay separate,
/// for the goldens.
library;

import 'package:flutter/widgets.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';
import 'package:neumorphism_ui/neumorphism_host.dart';

import 'demos/actions.dart';
import 'demos/chrome.dart' show kitSpecimenNavigationRail;
import 'demos/moves.dart' show kitSlide;
import 'demos/collections.dart';
import 'demos/fields.dart';
import 'demos/overlays.dart';
import 'demos/pickers.dart'
    show kitSpecimenCalendar, kitSpecimenDateRangePicker;
import 'demos/records.dart';
// The demo art is the example's; a test or page that draws it reads it from there.
// ignore: avoid_relative_lib_imports
import '../demo_art.dart';

/// One page of the live gallery: its id (the `?design=` query and the tests), its title and its glyph in the
/// navigation.
typedef LivePage = ({String id, String title, IconData icon});

/// The pages, in reading order: the parts by family, then ordinary app screens, then what is the look's own.
const liveGalleryPages = <LivePage>[
  (id: 'overview', title: 'Overview', icon: NeumorphicGlyphs.house),
  // The showcase: an app of its own, which leaves the gallery's navigation for its own.
  (id: 'home', title: 'Hearth, an app', icon: NeumorphicGlyphs.lamp),
  (id: 'buttons', title: 'Buttons', icon: NeumorphicGlyphs.mousePointerClick),
  (id: 'fields', title: 'Text fields', icon: NeumorphicGlyphs.textCursorInput),
  (id: 'selection', title: 'Selection', icon: NeumorphicGlyphs.squareCheck),
  (id: 'pickers', title: 'Pickers', icon: NeumorphicGlyphs.calendarDays),
  (id: 'navigation', title: 'Navigation', icon: NeumorphicGlyphs.panelsTopLeft),
  (id: 'lists', title: 'Lists and tables', icon: NeumorphicGlyphs.list),
  (id: 'cards', title: 'Cards and media', icon: NeumorphicGlyphs.layoutGrid),
  (
    id: 'dialogs',
    title: 'Dialogs and sheets',
    icon: NeumorphicGlyphs.messageSquare,
  ),
  (id: 'feedback', title: 'Feedback', icon: NeumorphicGlyphs.bell),
  (id: 'charts', title: 'Charts', icon: NeumorphicGlyphs.chartColumn),
  (id: 'actions', title: 'Button groups', icon: NeumorphicGlyphs.group),
  (
    id: 'more-fields',
    title: 'More fields',
    icon: NeumorphicGlyphs.rectangleEllipsis,
  ),
  (
    id: 'collections',
    title: 'Tables and trees',
    icon: NeumorphicGlyphs.listTree,
  ),
  (id: 'overlays', title: 'Popovers and toasts', icon: NeumorphicGlyphs.layers),
  (id: 'records', title: 'Records and status', icon: NeumorphicGlyphs.history),
  (id: 'type', title: 'Type and colour', icon: NeumorphicGlyphs.palette),
  (id: 'relief', title: 'Relief and dials', icon: NeumorphicGlyphs.gauge),
  (id: 'shapes', title: 'Shape roles', icon: NeumorphicGlyphs.shapes),
  (id: 'inventory', title: 'Every component', icon: NeumorphicGlyphs.component),
];

/// A gridline's label on the hours chart: '4 h'.
String _hours(double value) => '${value.round()} h';

/// An ordinary screen whose controls own real state and show their motion.
class LiveExample extends StatefulWidget {
  const LiveExample({super.key, required this.page, this.onOpen, this.header});

  /// The page's id, from [liveGalleryPages].
  final String page;

  /// Opens another page by its id, from the Overview's tour.
  final ValueChanged<String>? onOpen;

  /// What stands above the page's title (the gallery's Customize panel).
  final Widget? header;

  @override
  State<LiveExample> createState() => _LiveExampleState();
}

class _LiveExampleState extends State<LiveExample> {
  final _name = TextEditingController(text: 'Alex Morgan');
  final _email = TextEditingController(text: 'alex@example.com');
  final _notes = TextEditingController();
  final _menuAnchor = GlobalKey();
  final _tooltipAnchor = GlobalKey();
  var _country = 'United States';
  var _tab = 0;
  var _emailUpdates = true;
  var _pushUpdates = false;
  var _checked = false;
  // The third state at rest, so the specimen shows what three states means (at false it never showed it).
  bool? _all;
  var _radio = 'standard';
  var _segment = 'month';
  var _filter = 0;
  var _latch = 'Auto';
  var _level = .4;
  var _people = 2;
  var _favourite = false;
  var _chip = false;
  var _chipVisible = true;
  var _expanded = false;
  var _pageDot = 0;
  var _page = 3;
  var _step = 1;
  var _status = '';
  var _rating = 4;
  var _choice = 'Basic';
  var _box = 0;
  var _todo = false;
  var _lamp = true;
  var _nav = 0;
  var _rail = 0;
  var _place = 0;
  var _busy = false;
  var _chartKind = LiveChartKind.line;
  var _chartLoading = false;
  var _chartEmpty = false;
  var _files = <String>['floor-plan.pdf'];
  var _dropActive = false;
  var _city2 = '';
  var _feedback = 'ready';
  var _dial = 21.0;
  var _knob = .5;
  var _date = DateTime(2026, 11, 12);
  var _time = const NeumorphicTime(9, 0);

  void _say(String value) => setState(() => _status = value);

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _notes.dispose();
    super.dispose();
  }

  NeumorphicThemeData get _t => NeumorphicTheme.of(context);

  Future<void> _dialog() async {
    final saved = await showNeumorphicDialog<bool>(
      context,
      builder: (context) => NeumorphicDialog(
        title: 'Save your changes?',
        message: 'Your preferences will be used on all your devices.',
        actions: [
          NeumorphicButton.text(
            'Cancel',
            onPressed: () => Navigator.pop(context, false),
          ),
          NeumorphicButton.filled(
            'Save changes',
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
    if (mounted) {
      _say(saved == true ? 'Changes saved' : 'Changes kept as they were');
    }
  }

  Future<void> _deleteDialog() async {
    final gone = await showNeumorphicDialog<bool>(
      context,
      builder: (context) => NeumorphicDialog(
        title: 'Delete this note?',
        message: 'It goes for good; nobody can bring it back.',
        actions: [
          NeumorphicButton.text(
            'Keep it',
            onPressed: () => Navigator.pop(context, false),
          ),
          NeumorphicButton(
            'Delete',
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
    if (mounted) _say(gone == true ? 'Note deleted' : 'Note kept');
  }

  Future<void> _menu() async {
    final box = _menuAnchor.currentContext!.findRenderObject()! as RenderBox;
    final value = await showNeumorphicMenu<String>(
      context,
      anchor: box.localToGlobal(Offset.zero) & box.size,
      items: const [
        NeumorphicMenuItem('Copy link', 'Copy link'),
        NeumorphicMenuItem('Archive', 'Archive'),
      ],
    );
    if (mounted && value != null) {
      _say(value == 'Archive' ? 'Item archived' : 'Link copied');
    }
  }

  Future<void> _sheet() => showNeumorphicBottomSheet<void>(
    context,
    builder: (context) => NeumorphicBottomSheet(
      title: 'How can we help?',
      actions: [
        NeumorphicButton.filled(
          'Got it',
          onPressed: () => Navigator.pop(context),
        ),
      ],
      child: const Text('Try a control to see its state and motion change.'),
    ),
  );

  Future<void> _pickDate() async {
    final value = await showNeumorphicDatePicker(
      context,
      value: _date,
      first: DateTime(2026),
      last: DateTime(2027),
    );
    if (mounted && value != null) setState(() => _date = value);
  }

  Future<void> _pickTime() async {
    final value = await showNeumorphicTimePicker(
      context,
      value: _time,
      twentyFour: true,
    );
    if (mounted && value != null) setState(() => _time = value);
  }

  void _tooltip() {
    final box = _tooltipAnchor.currentContext!.findRenderObject()! as RenderBox;
    final shown = showNeumorphicTooltip(
      context,
      message: 'Saved a minute ago',
      anchor: box.localToGlobal(Offset.zero) & box.size,
    );
    Future<void>.delayed(const Duration(seconds: 2), shown.dismiss);
  }

  Widget _stack(List<Widget> children, {double gap = 20}) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (var i = 0; i < children.length; i++) ...[
        if (i > 0) SizedBox(height: gap),
        children[i],
      ],
    ],
  );

  /// A screen for a piece that stands at a screen's edge (a rail, a bar, a drawer): a rounded well, the piece at [at].
  /// Loose on the page its square ends read as a sharp box (law 8); at a screen's edge they are the screen's.
  Widget _onScreen(
    Widget piece, {
    required AlignmentGeometry at,
    double? height,
  }) => NeumorphicSurface(
    cast: NeumorphicSurfaceLevel.well,
    radius: NeumorphicRadii.slab,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(
        _t.shapes.corner(NeumorphicRadii.slab).radius,
      ),
      child: SizedBox(
        height: height,
        child: Align(alignment: at, child: piece),
      ),
    ),
  );

  /// A screen's own page beside its rail or drawer in a frame: its title and a line.
  Widget _screenPage(String title, String line) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: _t.textTheme.title),
        const SizedBox(height: 6),
        Text(line, style: _t.textTheme.caption),
      ],
    ),
  );

  /// A titled part of a page: a section head over its parts.
  Widget _part(String title, List<Widget> children, {String? meta}) => _stack([
    NeumorphicSectionHeader(title: title, subtitle: meta),
    ...children,
  ], gap: 14);

  /// A bare mark with its words beside it: the words press it too, and the mark alone is spoken (it carries its label).
  /// [seconds] as m:ss, for a track's elapsed time.
  static String _clock(double seconds) {
    final s = seconds.round();
    return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
  }

  Widget _captioned(Widget mark, String words, VoidCallback onTap) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      mark,
      const SizedBox(width: 12),
      // Wraps under large text instead of running past the page.
      Flexible(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          excludeFromSemantics: true,
          onTap: onTap,
          child: ExcludeSemantics(child: Text(words)),
        ),
      ),
    ],
  );

  /// Tiles at least [least] wide in equal columns across the whole width.
  Widget _grid(double least, List<Widget> children, {double gap = 12}) =>
      LayoutBuilder(
        builder: (context, box) {
          final columns = ((box.maxWidth + gap) / (least + gap)).floor().clamp(
            1,
            children.length,
          );
          // A hair under the share, so rounding never sends the last tile of a row onto the next.
          final width = (box.maxWidth - gap * (columns - 1)) / columns - .01;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final child in children)
                SizedBox(width: width, child: child),
            ],
          );
        },
      );

  Widget _wrap(List<Widget> children, {double gap = 12, double? runGap}) =>
      Wrap(
        spacing: gap,
        runSpacing: runGap ?? gap,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: children,
      );

  // ---------------------------------------------------------------- Overview

  /// The Overview is the pitch: the look at its best, live (a room's dial, working), one sentence, the app, what the
  /// package holds, and only then the index.
  Widget _overview() => LayoutBuilder(
    builder: (context, box) {
      final t = _t;
      final wide = box.maxWidth >= 900;
      final words = NeumorphicColumn(
        gap: 16,
        children: [
          Text(
            'One porcelain material, cast and pressed',
            style: t.textTheme.page,
          ),
          Text(
            'Every part is moulded from the ground it stands on. Raised is off, pressed in is on, and the pigment '
            'means live.',
            style: t.textTheme.body.copyWith(color: t.colors.inkSecondary),
          ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: NeumorphicButton.filled(
              'Open Hearth, a home app',
              key: const Key('overview-open-app'),
              icon: NeumorphicGlyphs.arrowRight,
              wide: !wide,
              onPressed: () => widget.onOpen?.call('home'),
            ),
          ),
        ],
      );
      final dial = NeumorphicDial(
        key: const Key('overview-dial'),
        value: _dial,
        min: 10,
        max: 30,
        now: 21,
        label: _dial > 21 ? 'Warming to' : 'Holding at',
        labelIcon: _dial > 21 ? NeumorphicGlyphs.flame : null,
        figure: '${_dial.toStringAsFixed(1)}°',
        sub: 'Living room, now 21.0°',
        onDecrease: () => setState(() => _dial -= .5),
        onIncrease: () => setState(() => _dial += .5),
      );
      final app = NeumorphicListSection(
        label: 'Hearth, a home app',
        children: [
          for (final (i, screen) in const [
            (
              'home',
              NeumorphicGlyphs.house,
              'Home',
              'The room you are in, its dial and its lights',
            ),
            (
              'list',
              NeumorphicGlyphs.lamp,
              'Devices',
              'Every lamp in the house, and the one you open',
            ),
            (
              'checkout',
              NeumorphicGlyphs.lightbulb,
              'Shop',
              'A desk lamp and bulbs, to the door',
            ),
            (
              'form',
              NeumorphicGlyphs.user,
              'Account',
              'Your name, your email, who shares the home',
            ),
            (
              'settings',
              NeumorphicGlyphs.settings,
              'Settings',
              'Switches that apply as they move',
            ),
          ].indexed)
            NeumorphicListTile(
              key: Key('overview-app-${screen.$1}'),
              title: screen.$3,
              subtitle: screen.$4,
              isFirst: i == 0,
              leading: Icon(screen.$2, size: 22),
              trailing: const _Onward(),
              onPressed: () => widget.onOpen?.call(screen.$1),
            ),
        ],
      );
      // Beside Hearth's list on a desk: as many rows, each a line of words under its title, so the two cards end on one
      // line.
      final holds = NeumorphicListSection(
        label: 'In the package',
        children: [
          for (final (i, fact) in const [
            (
              NeumorphicGlyphs.layoutGrid,
              'Every part an app needs',
              'Fields, pickers, tables, dialogs, charts, dials',
            ),
            (
              NeumorphicGlyphs.panelsTopLeft,
              'Phone, tablet and desk',
              'Navigation and layouts that change with the window',
            ),
            (
              NeumorphicGlyphs.moon,
              'Day and night',
              'Every part cast on a light ground and a dark one',
            ),
            (
              NeumorphicGlyphs.palette,
              'Your own colours',
              'Five presets, or a ground and a pigment of your own',
            ),
            (
              NeumorphicGlyphs.eye,
              'For everyone',
              'Large text, less motion, contrast, screen readers',
            ),
          ].indexed)
            NeumorphicListTile(
              title: fact.$2,
              subtitle: fact.$3,
              isFirst: i == 0,
              leading: Icon(fact.$1, size: 22),
            ),
        ],
      );
      // The index is lists like the two above, a row a page, its glyph and words on the card's keyline: a wrap of text
      // buttons put each button's padding on the keyline and left the second column ragged. Three lists side by side
      // on a desk.
      final pages = liveGalleryPages.skip(2).toList();
      Widget pageList(List<LivePage> some) => NeumorphicListSection(
        children: [
          for (final (i, page) in some.indexed)
            NeumorphicListTile(
              key: Key('overview-index-${page.id}'),
              title: page.title,
              isFirst: i == 0,
              leading: Icon(page.icon, size: 22),
              trailing: const _Onward(),
              onPressed: () => widget.onOpen?.call(page.id),
            ),
        ],
      );
      final third = (pages.length / 3).ceil();
      final index = _part('Every page', [
        if (wide)
          NeumorphicRow(
            spans: const [1, 1, 1],
            children: [
              for (var i = 0; i < pages.length; i += third)
                Align(
                  alignment: AlignmentDirectional.topStart,
                  child: pageList(
                    pages.sublist(i, (i + third).clamp(0, pages.length)),
                  ),
                ),
            ],
          )
        else
          pageList(pages),
      ]);
      if (!wide) {
        return NeumorphicSections(children: [words, dial, app, holds, index]);
      }
      return NeumorphicSections(
        gap: 48,
        children: [
          // The words stand at the dial's middle, not its top: at the top they left a hole as tall as the dial below.
          // The dial keeps a page title's room above it, so its lit halo is whole (at 40 px it ran into the window).
          Padding(
            padding: const EdgeInsets.only(top: 24),
            child: NeumorphicRow(
              spans: const [6, 6],
              children: [
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: words,
                ),
                dial,
              ],
            ),
          ),
          NeumorphicRow(spans: const [7, 5], children: [app, holds]),
          index,
        ],
      );
    },
  );

  // ---------------------------------------------------------------- Buttons

  Widget _buttons() => _stack([
    _part('Actions', [
      _wrap([
        NeumorphicButton.filled('Save', onPressed: () => _say('Saved')),
        NeumorphicButton('Preview', onPressed: () => _say('Previewing')),
        NeumorphicButton('Share', onPressed: () => _say('Shared')),
        NeumorphicButton.text('Later', onPressed: () => _say('Later')),
        NeumorphicButton(
          'Delete',
          isDestructiveAction: true,
          onPressed: _deleteDialog,
        ),
      ]),
    ]),
    // Side by side on one centre line, so the three read as a scale (stacked with gaps they read as three keys).
    _part('Sizes', [
      Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (final size in NeumorphicButtonSize.values)
            NeumorphicButton.filled(
              size.name[0].toUpperCase() + size.name.substring(1),
              size: size,
              onPressed: () => _say('${size.name} pressed'),
            ),
        ],
      ),
    ]),
    _part('With a glyph, busy and disabled', [
      _wrap([
        // The message field's level plane, so the page's two sends are one glyph (in right to left both turn).
        NeumorphicButton.filled(
          'Send',
          icon: NeumorphicGlyphs.sendHorizontal,
          busy: _busy,
          onPressed: () {
            setState(() => _busy = true);
            Future<void>.delayed(const Duration(seconds: 2), () {
              if (mounted) setState(() => _busy = false);
            });
          },
        ),
        // Busy at rest, so the row shows the three states side by side: Send goes busy only while it sends.
        NeumorphicButton(
          'Uploading',
          icon: NeumorphicGlyphs.upload,
          busy: true,
          onPressed: () {},
        ),
        const NeumorphicButton('Unavailable'),
      ]),
    ]),
    _part('Icon and round keys', [
      _wrap([
        NeumorphicIconButton(
          NeumorphicGlyphs.star,
          key: const Key('live-favourite'),
          label: 'Favourite',
          selected: _favourite,
          onPressed: () => setState(() => _favourite = !_favourite),
        ),
        NeumorphicIconButton(
          NeumorphicGlyphs.bell,
          label: 'Alerts',
          badge: '3',
          onPressed: () => _say('Alerts opened'),
        ),
        NeumorphicRoundButton(
          NeumorphicGlyphs.plus,
          label: 'Add',
          onPressed: () => _say('Added'),
        ),
        NeumorphicLink('Read the guide', onPressed: () => _say('Guide')),
      ]),
      // The send key belongs to a composer, inside its field.
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: NeumorphicTextField(
          hint: 'Message',
          trailing: NeumorphicSendButton(onPressed: () => _say('Sent')),
        ),
      ),
    ]),
    _part('A wide action', [
      NeumorphicButton.filled(
        'Continue',
        wide: true,
        onPressed: () => _say('Continuing'),
      ),
    ]),
  ]);

  // ---------------------------------------------------------------- Text fields

  Widget _fields() => _stack([
    _part('Fields', [
      NeumorphicTextField(
        label: 'Full name',
        controller: _name,
        hint: 'As on your card',
        helper: 'We use it on receipts.',
        onChanged: (value) => _say('Editing $value'),
      ),
      NeumorphicTextField(
        label: 'Email address',
        controller: _email,
        leading: const Icon(NeumorphicGlyphs.mail, size: 18),
        keyboardType: TextInputType.emailAddress,
        error: _email.text.contains('@') ? null : 'Add an @ and a domain.',
        onChanged: (_) => setState(() {}),
      ),
      const NeumorphicTextField(
        label: 'Password',
        obscureText: true,
        initialValue: 'porcelain',
      ),
      const NeumorphicTextField(
        label: 'Member number',
        initialValue: 'NM-20418',
        enabled: false,
      ),
    ]),
    _part('Search and notes', [
      NeumorphicSearchField(
        hint: 'Search rooms',
        onChanged: (value) => _say('Searching $value'),
      ),
      NeumorphicTextArea(
        key: const Key('live-notes'),
        label: 'Notes',
        controller: _notes,
        lines: 3,
        hint: 'Anything we should know?',
        onChanged: (value) => _say('Notes: $value'),
      ),
    ]),
    _part('Codes and plain inputs', [
      NeumorphicInputOtp(
        key: const Key('live-code'),
        label: 'Verification code',
        length: 4,
        onChanged: (value) => _say('Code: $value'),
        onCompleted: (value) => _say('Code $value entered'),
      ),
      NeumorphicFormGroup(
        label: 'Room name',
        child: NeumorphicInput(onChanged: (value) => _say('Room $value')),
      ),
      // Its own input keeps a floor of groove above and below, as a field's line does: bare, two lines at twice the
      // text ran edge to edge.
      const NeumorphicFieldBox(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text('A shell for your own input'),
        ),
      ),
    ]),
  ]);

  // ---------------------------------------------------------------- Selection

  Widget _selection() => _stack([
    _part('Checkboxes', [
      NeumorphicCheckRow(
        label: 'Remember this choice',
        value: _checked,
        onChanged: (v) => setState(() => _checked = v ?? false),
      ),
      _wrap(
        [
          _captioned(
            NeumorphicCheckbox(
              key: const Key('live-check'),
              value: _checked,
              label: 'Include a receipt',
              onChanged: (value) => setState(() => _checked = value ?? false),
            ),
            'Include a receipt',
            () => setState(() => _checked = !_checked),
          ),
          _captioned(
            NeumorphicCheckbox(
              value: _all,
              tristate: true,
              label: 'All rooms',
              onChanged: (value) => setState(() => _all = value),
            ),
            'All rooms (three states)',
            () => setState(
              () => _all = _all == false
                  ? true
                  : _all == true
                  ? null
                  : false,
            ),
          ),
          // The round check is a bare mark: its row names it, merged into one control.
          MergeSemantics(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                NeumorphicRoundCheckbox(
                  value: _todo,
                  onChanged: (v) => setState(() => _todo = v),
                ),
                const SizedBox(width: 12),
                const Text('Water the plants'),
              ],
            ),
          ),
        ],
        gap: 24,
        runGap: 12,
      ),
    ]),
    _part('Radio group', [
      NeumorphicRadioGroup<String>(
        key: const Key('live-radio'),
        label: 'Delivery',
        value: _radio,
        options: const [
          NeumorphicRadio('standard', 'Standard', note: 'Three to five days'),
          NeumorphicRadio('express', 'Express', note: 'Tomorrow'),
          NeumorphicRadio('pickup', 'Pick up', enabled: false),
        ],
        onChanged: (value) => setState(() => _radio = value),
      ),
    ]),
    // A switch row stands in its settings card, as wide as one; across the whole column its switch stood 720 px
    // from its words, beside a bare switch with its words after it.
    _part('Switches', [
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: NeumorphicSlab(
            child: NeumorphicSwitchRow(
              label: 'Weekly summary',
              note: 'A short update every Friday.',
              value: _emailUpdates,
              onChanged: (v) => setState(() => _emailUpdates = v),
            ),
          ),
        ),
      ),
      _wrap([
        _captioned(
          NeumorphicSwitch(
            key: const Key('live-switch'),
            value: _pushUpdates,
            label: 'Enable alerts',
            onChanged: (value) => setState(() => _pushUpdates = value),
          ),
          'Enable alerts',
          () => setState(() => _pushUpdates = !_pushUpdates),
        ),
      ]),
    ]),
    _part('Segmented and latches', [
      NeumorphicSegmentedButton<String>(
        key: const Key('live-segments'),
        label: 'Billing',
        value: _segment,
        segments: const [
          NeumorphicButtonSegment('month', 'Monthly'),
          NeumorphicButtonSegment('quarter', 'Quarterly'),
          NeumorphicButtonSegment('year', 'Yearly'),
        ],
        onChanged: (value) => setState(() => _segment = value),
      ),
      NeumorphicLatchGroup(
        key: const Key('live-latches'),
        value: _latch,
        options: const [
          NeumorphicLatch('Auto'),
          NeumorphicLatch('On'),
          NeumorphicLatch('Off'),
        ],
        onChanged: (value) => setState(() => _latch = value),
      ),
    ]),
    _part('Chips and choices', [
      _wrap([
        for (final (i, name) in ['All', 'Unread', 'Starred'].indexed)
          NeumorphicChip(
            name,
            selected: _filter == i,
            onPressed: () => setState(() => _filter = i),
          ),
        NeumorphicChip(
          'Priority',
          key: const Key('live-chip'),
          icon: NeumorphicGlyphs.flame,
          selected: _chip,
          onPressed: () => setState(() => _chip = !_chip),
        ),
        if (_chipVisible)
          NeumorphicChip(
            'Draft',
            key: const Key('live-removable'),
            onDeleted: () => setState(() => _chipVisible = false),
          ),
      ]),
      NeumorphicChoices(
        value: _choice,
        options: const [
          NeumorphicChoice('Basic', note: 'One room'),
          NeumorphicChoice('Home', note: 'Every room'),
        ],
        onChanged: (v) => setState(() => _choice = v),
      ),
    ]),
    // Boxes of one word each are a part of their own, under their own head: right under the cards they read as the
    // cards' second row, and no width of theirs lined up with cards that take their words' width.
    // A control's 320 at most; on a phone's column they span it as the cards above do (at 320 they stopped 30 short).
    _part('Choice boxes', [
      LayoutBuilder(
        builder: (context, box) => Align(
          alignment: AlignmentDirectional.centerStart,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: box.maxWidth < 400 ? box.maxWidth : 320,
            ),
            child: NeumorphicGridOf(
              columns: 2,
              gap: 10,
              children: [
                for (final (i, name) in ['Warm', 'Cool'].indexed)
                  NeumorphicChoiceBox(
                    selected: _box == i,
                    inGroup: true,
                    onPressed: () => setState(() => _box = i),
                    child: Text(name),
                  ),
              ],
            ),
          ),
        ),
      ),
    ]),
    _part('Slider, stepper and rating', [
      // The slider's name and level are spoken by the slider; the words above are for the eye.
      ExcludeSemantics(
        child: NeumorphicSplit(
          start: Text('Alert volume', style: _t.textTheme.caption),
          end: Text(
            '${(_level * 100).round()}%',
            style: _t.textTheme.caption.tabular,
          ),
        ),
      ),
      NeumorphicSlider(
        key: const Key('live-volume'),
        label: 'Alert volume',
        value: _level,
        valueLabel: (v) => '${(v * 100).round()}%',
        onChanged: (v) => setState(() => _level = v),
      ),
      NeumorphicNumberField(
        key: const Key('live-stepper'),
        value: '$_people',
        unit: 'people',
        onDecrease: _people == 1 ? null : () => setState(() => _people--),
        onIncrease: () => setState(() => _people++),
      ),
      _stack([
        ExcludeSemantics(
          child: Text('Your rating', style: _t.textTheme.caption),
        ),
        NeumorphicRating(
          label: 'Your rating',
          value: _rating.toDouble(),
          onChanged: (v) => setState(() => _rating = v),
        ),
      ], gap: 2),
      _stack([
        ExcludeSemantics(
          child: Text('Average, 3.6 of 5', style: _t.textTheme.caption),
        ),
        const NeumorphicRating(label: 'Average rating', value: 3.6),
      ], gap: 8),
    ]),
  ]);

  // ---------------------------------------------------------------- Pickers

  Widget _pickers() => _stack([
    _part('Select', [
      NeumorphicSelect<String>(
        key: const Key('live-select'),
        label: 'Country',
        value: _country,
        options: const [
          NeumorphicMenuItem('United States', 'United States'),
          NeumorphicMenuItem('Canada', 'Canada'),
          NeumorphicMenuItem('United Kingdom', 'United Kingdom'),
        ],
        onChanged: (value) => setState(() => _country = value),
      ),
      // A picker row that opens a page of its own: a value and its note, not a second country menu.
      _stack([
        Text('Reminder', style: _t.textTheme.caption),
        NeumorphicSelectField(
          value: 'Every weekday',
          note: '07:30',
          onPressed: () => _say('Choosing a reminder'),
        ),
      ], gap: 8),
    ]),
    _part('Autocomplete', [
      NeumorphicSearchField(
        hint: 'Type a city',
        onChanged: (value) => setState(() => _city2 = value),
      ),
      if (_city2.isNotEmpty)
        NeumorphicMenu<String>(
          autofocus: false,
          items: [
            for (final city in const [
              'Bath',
              'Bristol',
              'Brighton',
              'Cambridge',
              'Cardiff',
            ])
              if (city.toLowerCase().startsWith(_city2.toLowerCase()))
                NeumorphicMenuItem(city, city),
          ],
          onSelected: (city) => _say('City: $city'),
        ),
    ]),
    _part('Date and time', [
      _wrap([
        NeumorphicButton(
          '${_date.month}/${_date.day}/${_date.year}',
          key: const Key('live-date'),
          icon: NeumorphicGlyphs.calendar,
          onPressed: _pickDate,
        ),
        NeumorphicButton(
          _time.format(twentyFour: true),
          key: const Key('live-time'),
          icon: NeumorphicGlyphs.clock,
          onPressed: _pickTime,
        ),
      ]),
      // The page's one today, as the calendars below hold it: on the clock's it marked the 13th over their 12th.
      NeumorphicDatePicker(
        value: _date,
        today: DateTime(2026, 11, 12),
        first: DateTime(2026),
        last: DateTime(2027),
        onChanged: (v) => setState(() => _date = v),
      ),
      NeumorphicTimePicker(
        value: _time,
        minuteStep: 15,
        onChanged: (v) => setState(() => _time = v),
      ),
    ]),
    _part('Calendar', [kitSpecimenCalendar()]),
    _part('Date range', [kitSpecimenDateRangePicker()]),
    _part('File drop', [
      NeumorphicFileUpload(
        hint: 'PDF or image, up to 10\u00a0MB',
        active: _dropActive,
        files: _files,
        onPressed: () => setState(() {
          _files = [..._files, 'photo-${_files.length}.jpg'];
          _dropActive = false;
        }),
        onRemove: (i) => setState(() => _files = [..._files]..removeAt(i)),
      ),
      NeumorphicSwitchRow(
        label: 'Show a drag held over it',
        value: _dropActive,
        onChanged: (v) => setState(() => _dropActive = v),
      ),
    ]),
  ]);

  // ---------------------------------------------------------------- Navigation

  Widget _navigation() => _stack([
    // A rail or a drawer stands at its screen's edge with the screen's page beside it: alone in the frame it read as
    // a panel jammed into an empty well.
    _part('Navigation rail', [
      _onScreen(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            kitSpecimenNavigationRail(),
            Expanded(
              child: _screenPage('Home', 'Three lights on, 21° inside.'),
            ),
          ],
        ),
        at: AlignmentDirectional.centerStart,
      ),
    ]),
    _part('Tabs', [
      NeumorphicTabBar(
        key: const Key('live-tabs'),
        tabs: const ['Overview', 'Activity', 'Files'],
        selectedIndex: _tab,
        onChanged: (value) => setState(() => _tab = value),
      ),
      AnimatedSwitcher(
        duration: _t.motion.state,
        child: NeumorphicSlab(
          key: ValueKey(_tab),
          child: _stack([
            Text(
              ['Project overview', 'Recent activity', 'Shared files'][_tab],
              style: _t.textTheme.title,
            ),
            Text(
              [
                'Everything you need to plan the next\u00a0step.',
                'Sam updated the project notes this morning.',
                'Three documents are ready for your review.',
              ][_tab],
            ),
            NeumorphicButton(
              ['View project', 'View all activity', 'Open files'][_tab],
              onPressed: () => _say(
                ['Project opened', 'Activity opened', 'Files opened'][_tab],
              ),
            ),
          ]),
        ),
      ),
    ]),
    // At a screen's top, as it stands in an app: its gutters are the screen's. In a slab of its own they added to the
    // slab's padding and its keys floated 64 in from the slab's ends.
    _part('App bar', [
      _onScreen(
        at: AlignmentDirectional.topCenter,
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: NeumorphicAppBar(
            title: 'Kitchen',
            subtitle: 'Three lights on',
            leading: NeumorphicBackButton(onPressed: () => _say('Back')),
            actions: [
              NeumorphicIconButton(
                NeumorphicGlyphs.ellipsis,
                label: 'More',
                onPressed: () => _say('More'),
              ),
            ],
          ),
        ),
      ),
    ]),
    _part('Bottom navigation', [
      _onScreen(
        height: 168,
        at: Alignment.bottomCenter,
        NeumorphicNavigationBar(
          selectedIndex: _nav,
          items: [
            for (final (i, (label, icon)) in [
              ('Home', NeumorphicGlyphs.house),
              ('Rooms', NeumorphicGlyphs.doorOpen),
              ('Energy', NeumorphicGlyphs.zap),
              ('You', NeumorphicGlyphs.user),
            ].indexed)
              NeumorphicNavItem(
                label: label,
                icon: icon,
                badge: i == 1 ? '2' : null,
              ),
          ],
          onDestinationSelected: (i) => setState(() => _nav = i),
        ),
      ),
    ]),
    _part('Side navigation', [
      // A drawer and a rail's section at their own width, as they stand at a screen's edge; the drawer cut to its
      // items (at a screen's edge it runs the screen's height).
      _onScreen(
        at: AlignmentDirectional.centerStart,
        LayoutBuilder(
          builder: (context, box) {
            // On a phone the drawer covers its page, as it does at a phone's edge: beside it the page had 45 px
            // and broke its words letter by letter; at its 280 the strip it left read as a page crushed to nothing.
            final phone = box.maxWidth < 280 + 200;
            final drawer = SizedBox(
              height: 196,
              child: NeumorphicNavigationDrawer(
                width: phone ? box.maxWidth : 280,
                label: 'Rooms',
                selectedIndex: _rail,
                items: const [
                  NeumorphicNavItem(
                    label: 'Living room',
                    icon: NeumorphicGlyphs.armchair,
                  ),
                  NeumorphicNavItem(
                    label: 'Kitchen',
                    icon: NeumorphicGlyphs.coffee,
                    count: '3',
                  ),
                  NeumorphicNavItem(
                    label: 'Garden',
                    icon: NeumorphicGlyphs.trees,
                  ),
                ],
                onDestinationSelected: (i) => setState(() => _rail = i),
              ),
            );
            if (phone) return drawer;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                drawer,
                Expanded(
                  child: _screenPage(
                    ['Living room', 'Kitchen', 'Garden'][_rail],
                    [
                      'Two lamps on.',
                      'Three things to do.',
                      'The lights come on at dusk.',
                    ][_rail],
                  ),
                ),
              ],
            );
          },
        ),
      ),
      // A rail's section stands in its rail at a screen's edge, its page beside it: under the drawer's frame it stood
      // alone, its chosen well a thin strip half the width.
      _onScreen(
        at: AlignmentDirectional.centerStart,
        LayoutBuilder(
          builder: (context, box) {
            // As the drawer: on a phone the rail's section covers its page (beside it, at twice the text, the page
            // broke Studio as Stu|dio; at its 240 it left half the screen blank).
            final phone = box.maxWidth < 240 + 200;
            final rail = SizedBox(
              width: phone ? box.maxWidth : 240,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: NeumorphicRailSet(
                  label: 'Places',
                  children: [
                    for (final (i, name) in ['Studio', 'Office'].indexed)
                      NeumorphicRailLink(
                        label: name,
                        figure: '${20 + i}.5°',
                        live: i == 0,
                        selected: _place == i,
                        onPressed: () => setState(() => _place = i),
                      ),
                  ],
                ),
              ),
            );
            if (phone) return rail;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                rail,
                Expanded(
                  child: _screenPage(
                    ['Studio', 'Office'][_place],
                    ['20.5°, holding.', '21.5°, the heating is off.'][_place],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ]),
    _part('Breadcrumbs and pagination', [
      NeumorphicBreadcrumb(
        crumbs: [
          NeumorphicCrumb('Home', onPressed: () => _say('Home')),
          NeumorphicCrumb('Rooms', onPressed: () => _say('Rooms')),
          const NeumorphicCrumb('Kitchen'),
        ],
      ),
      NeumorphicPagination(
        count: 9,
        page: _page,
        onChanged: (p) => setState(() => _page = p),
      ),
    ]),
    _part('Page dots and step progress', [
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: NeumorphicPageDots(
          key: const Key('live-dots'),
          label: 'Steps',
          count: 3,
          selectedIndex: _pageDot,
          onChanged: (value) => setState(() => _pageDot = value),
        ),
      ),
      NeumorphicStepProgress(count: 4, currentStep: _step, name: 'Setup'),
      // Both raised (a flat Back read as out of use on a step it could go back from); Next is the step's one act, in
      // the pigment, so the way on is marked.
      _wrap([
        NeumorphicButton(
          'Back a step',
          onPressed: _step == 0 ? null : () => setState(() => _step--),
        ),
        NeumorphicButton.filled(
          'Next step',
          onPressed: _step == 3 ? null : () => setState(() => _step++),
        ),
      ]),
    ]),
  ]);

  // ---------------------------------------------------------------- Lists and tables

  Widget _lists() => _stack([
    _part('Rows', [
      NeumorphicListSection(
        label: 'Account',
        children: [
          NeumorphicListTile(
            title: 'Profile',
            subtitle: 'Name, photo and email',
            isFirst: true,
            leading: const NeumorphicIconWell(NeumorphicGlyphs.user),
            trailing: const _Onward(),
            onPressed: () => _say('Profile'),
          ),
          NeumorphicListTile(
            title: 'Security',
            subtitle: 'Password and devices',
            leading: const NeumorphicIconWell(NeumorphicGlyphs.lock),
            trailing: const _Onward(),
            onPressed: () => _say('Security'),
          ),
        ],
      ),
      NeumorphicSlab(
        child: NeumorphicList(
          children: [
            const NeumorphicKvRow('Plan', 'Studio', isFirst: true),
            const NeumorphicWhoRow(
              initials: 'SR',
              name: 'Sam Rivera',
              note: 'Online',
              led: true,
            ),
            NeumorphicTodoRow(
              title: 'Water the plants',
              note: 'Every Tuesday',
              value: _todo,
              onChanged: (v) => setState(() => _todo = v),
            ),
            NeumorphicLevelRow(
              icon: NeumorphicGlyphs.lamp,
              title: 'Reading lamp',
              state: _lamp ? 'On' : 'Off',
              value: _lamp,
              onChanged: (v) => setState(() => _lamp = v),
            ),
            const NeumorphicStepRow(time: '09:00', title: 'Stand-up'),
            const NeumorphicTotalRow('Total', '£48.00'),
          ],
        ),
      ),
    ]),
    _part('Disclosure', [
      NeumorphicDisclosure(
        key: const Key('live-disclosure'),
        title: 'Privacy',
        isFirst: true,
        expanded: _expanded,
        onExpansionChanged: (value) => setState(() => _expanded = value),
        child: const Text('Your data stays on your devices.'),
      ),
    ]),
    _part('Table', [
      NeumorphicTable(
        columns: const [
          NeumorphicTableColumn('Room', flex: 2),
          NeumorphicTableColumn('Lights', numeric: true),
          NeumorphicTableColumn('Temperature', numeric: true),
        ],
        rows: [
          for (final (i, (room, lights, temp)) in [
            ('Living room', '2', '21.5°'),
            ('Kitchen', '3', '20.0°'),
            ('Study', '1', '19.5°'),
          ].indexed)
            NeumorphicTableRow(
              [room, lights, temp],
              selected: _box == i,
              onPressed: () => setState(() => _box = i),
            ),
        ],
      ),
    ]),
    _part('Heads and rules', [
      const NeumorphicSubHead('This week'),
      const NeumorphicEyebrow('Updated today'),
      // A ruled list: each row stands under the look's one line, the first without it. A row keeps its floor above
      // and below its words, as a list's rows do: bare, the line hugged the words under it. The rows stand together,
      // as a list's do: apart on the section's gap, the line stood twice as far from the row above as from its own.
      const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NeumorphicRuled(
            rule: false,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('The first row has no line'),
            ),
          ),
          NeumorphicRuled(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Every row after it stands under one'),
            ),
          ),
        ],
      ),
      // A divider closes the list from what follows it: above the first row it stood over the row that says it has
      // none.
      const NeumorphicDivider(),
      const Text('A divider parts one group from the next'),
    ]),
  ]);

  // ---------------------------------------------------------------- Cards and media

  Widget _cards() => LayoutBuilder(
    builder: (context, box) {
      final columns = box.maxWidth >= 700 ? 3 : 1;
      return _stack([
        // On the row's 28 gutter, as the cards under them.
        NeumorphicGridOf(
          columns: columns,
          gap: 28,
          children: [
            for (final (title, copy, icon) in [
              (
                'Personal',
                'A quiet space for your everyday plans.',
                NeumorphicGlyphs.user,
              ),
              (
                'Team',
                'Keep your shared work in one place.',
                NeumorphicGlyphs.users,
              ),
              (
                'Archive',
                'The work you have already completed.',
                NeumorphicGlyphs.bookOpen,
              ),
            ])
              NeumorphicSlab(
                child: NeumorphicColumn(
                  gap: 20,
                  children: [
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Icon(icon, size: 26),
                    ),
                    Text(title, style: _t.textTheme.title),
                    NeumorphicGrow(child: Text(copy)),
                    NeumorphicButton(
                      'Open $title',
                      wide: true,
                      onPressed: () => _say('$title opened'),
                    ),
                  ],
                ),
              ),
          ],
        ),
        // Two to a row, near one height: the row shares its tallest card's height, and a short card beside the
        // picture stood half empty. The picture takes five twelfths, inside its card's 480: in an even half it stood
        // centred short of the page's edge.
        NeumorphicRow(
          spans: const [7, 5],
          children: [
            NeumorphicCard(
              title: 'Kitchen',
              subtitle: 'Three lights on',
              trailing: const NeumorphicLiveText('Live'),
              children: const [
                NeumorphicKvRow('Temperature', '21.5°', isFirst: true),
                NeumorphicKvRow('Humidity', '42%'),
                NeumorphicKvRow('Air', 'Fresh'),
                NeumorphicKvRow('Window', 'Shut'),
              ],
            ),
            NeumorphicPictureCard(
              glyph: NeumorphicGlyphs.images,
              title: 'Garden at dusk',
              subtitle: 'Yesterday',
              aspect: 2,
              onPressed: () => _say('Picture opened'),
            ),
          ],
        ),
        // A note is its own well: inside another it was a well in a well, a double frame. It keeps its own height
        // under the cards: in their row it took the tallest card's height, a big empty well round one line.
        const NeumorphicNote(
          icon: NeumorphicGlyphs.info,
          title: 'A well holds what sits in the wall',
          subtitle: 'Stats, notes and lists of times.',
        ),
        _part('Pictures', [
          NeumorphicRow(
            spans: const [6, 6],
            children: const [
              NeumorphicMedia(
                label: 'Living room',
                glyph: NeumorphicGlyphs.armchair,
              ),
              NeumorphicMedia(label: 'A picture that did not load'),
            ],
          ),
        ]),
        _part('People', [
          _wrap([
            const NeumorphicAvatar('AM', name: 'Alex Morgan'),
            // One size along the row: a larger one among them read as a mistake, not a variant.
            const NeumorphicAvatar('SR', selected: true),
            const NeumorphicBadge(4, child: NeumorphicAvatar('TC')),
            // The monogram's own 36 suits a row's mark; among portraits it takes theirs.
            const NeumorphicMonogram('JL', size: 40),
            const NeumorphicAvatarGroup([
              NeumorphicFace('AM'),
              NeumorphicFace('SR'),
              NeumorphicFace('TC'),
            ], total: 7),
          ], gap: 16),
        ]),
        _part('Carousel', [
          NeumorphicCarouselView(
            label: 'Rooms',
            height: 140,
            // The middle room first: a neighbour shows on each side and both steps are live.
            initialPage: 1,
            onChanged: (i) => _say('Room ${i + 1}'),
            children: [
              kitSlide('Kitchen', '21.5°, lights on'),
              kitSlide('Hall', '19°, quiet'),
              kitSlide('Study', '20°, reading lamp'),
            ],
          ),
        ]),
        _part('Marks', [
          // The wordmark holds the mark, so the mark isn't shown again beside it (two rings, one alone), and it names the
          // gallery's own brand.
          _wrap([
            const NeumorphicBrandRow('Neumorphism'),
            const NeumorphicGableArt(),
          ], gap: 20),
        ]),
      ]);
    },
  );

  // ---------------------------------------------------------------- Dialogs and sheets

  Widget _dialogs() => _stack([
    _part('Dialog', [
      Text(
        'A clear decision, with room for the words.',
        style: _t.textTheme.body,
      ),
      _wrap([
        NeumorphicButton(
          'Open dialog',
          key: const Key('live-dialog'),
          onPressed: _dialog,
        ),
        NeumorphicButton(
          'Delete a note',
          isDestructiveAction: true,
          onPressed: _deleteDialog,
        ),
      ]),
    ]),
    _part('Sheet, menu and toast', [
      NeumorphicSlab(
        child: _stack([
          Text('Notification preferences', style: _t.textTheme.title),
          NeumorphicSwitchRow(
            label: 'Weekly summary',
            value: _emailUpdates,
            note: 'A short update every Friday.',
            onChanged: (value) => setState(() => _emailUpdates = value),
          ),
        ]),
      ),
      _wrap([
        NeumorphicButton('Open a sheet', onPressed: _sheet),
        NeumorphicButton('More actions', key: _menuAnchor, onPressed: _menu),
        // Four triggers of one kind: flat text keys beside raised ones read as out of use.
        NeumorphicButton(
          'Show message',
          onPressed: () => showNeumorphicSnackBar(
            context,
            message: 'Your changes are saved',
          ),
        ),
        NeumorphicButton(
          'Show a tooltip',
          key: _tooltipAnchor,
          onPressed: _tooltip,
        ),
      ]),
      // A link stands in its sentence, under the keys: wedged among them it read as a smaller, bodiless key. The
      // sentence wraps like one: at twice the text on a phone the link goes on to the next line.
      Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('Stuck on something? ', style: _t.textTheme.caption),
          NeumorphicTooltip(
            message: 'This link opens the help panel',
            child: NeumorphicLink('Get help', onPressed: _sheet),
          ),
        ],
      ),
    ]),
    _part('Menus, tooltips and notices, open', [
      NeumorphicMenu<String>(
        autofocus: false,
        // The menu keeps a column for a check or an icon; an app's menu fills it.
        items: const [
          NeumorphicMenuItem('copy', 'Copy', icon: NeumorphicGlyphs.copy),
          NeumorphicMenuItem('share', 'Share', icon: NeumorphicGlyphs.share2),
          NeumorphicMenuItem(
            'delete',
            'Delete',
            icon: NeumorphicGlyphs.trash2,
            danger: true,
          ),
        ],
        onSelected: (v) => _say('Menu: $v'),
      ),
      const NeumorphicTooltipFace(message: 'A tooltip says one thing'),
      NeumorphicSnackBar(
        'The thermostat is back online',
        title: 'Connected',
        tone: NeumorphicTone.success,
        actionLabel: 'View',
        onAction: () => _say('Viewing'),
      ),
      NeumorphicNudge(
        title: 'Turn on weekly summaries?',
        eyebrow: 'Suggestion',
        note: 'One message every Friday.',
        action: NeumorphicButton(
          'Turn on',
          onPressed: () => setState(() => _emailUpdates = true),
        ),
      ),
    ]),
  ]);

  // ---------------------------------------------------------------- Feedback

  Widget _feedbackPage() => _stack([
    _part('Notices', [
      for (final tone in NeumorphicTone.values)
        NeumorphicBanner(
          switch (tone) {
            NeumorphicTone.info => 'Your plan renews on 1\u00a0December.',
            NeumorphicTone.success => 'Your details are saved.',
            NeumorphicTone.warning => 'The battery is at 15%.',
            NeumorphicTone.danger => 'The heating did not start.',
          },
          title: tone.name[0].toUpperCase() + tone.name.substring(1),
          tone: tone,
          onDismiss: () => _say('${tone.name} dismissed'),
        ),
    ]),
    _part('Progress', [
      NeumorphicLinearProgressIndicator(value: _level, label: 'Upload'),
      const NeumorphicLinearProgressIndicator(label: 'Syncing'),
      _wrap([
        NeumorphicCircularProgressIndicator(value: _level),
        const NeumorphicCircularProgressIndicator(),
      ], gap: 20),
      // A track's place in a recording: the times under it say what it is, so it never reads as a second slider.
      _stack([
        ExcludeSemantics(
          child: Text('Now playing', style: _t.textTheme.caption),
        ),
        NeumorphicProgress(
          value: _level,
          start: _clock(_level * 238),
          end: '3:58',
        ),
      ], gap: 8),
      // The slider moves every indicator above; its words are for the eye, the slider speaks its own. Its words and
      // its slider are one item, as the recording's are: apart, the part's gap and the knob's reach set the slider
      // twice as far under its words.
      _stack([
        ExcludeSemantics(
          child: NeumorphicSplit(
            start: Text('Move them all', style: _t.textTheme.caption),
            end: Text(
              '${(_level * 100).round()}%',
              style: _t.textTheme.caption.tabular,
            ),
          ),
        ),
        NeumorphicSlider(
          label: 'Progress',
          value: _level,
          onChanged: (v) => setState(() => _level = v),
        ),
      ], gap: 0),
    ]),
    _part('States', [
      NeumorphicSegmentedButton<String>(
        label: 'State',
        value: _feedback,
        segments: const [
          NeumorphicButtonSegment('ready', 'Ready'),
          NeumorphicButtonSegment('loading', 'Loading'),
          NeumorphicButtonSegment('empty', 'Empty'),
          NeumorphicButtonSegment('error', 'Error'),
        ],
        onChanged: (v) => setState(() => _feedback = v),
      ),
      switch (_feedback) {
        'loading' => const NeumorphicLoadingState(),
        'empty' => const NeumorphicEmptyState(
          title: 'No rooms yet',
          body: 'Add a room to see it here.',
        ),
        'error' => NeumorphicErrorState(
          title: 'The rooms did not load',
          onRetry: () => setState(() => _feedback = 'ready'),
        ),
        _ => const NeumorphicSuccessState(
          title: 'All rooms are in',
          message: 'Every device answered.',
        ),
      },
      const NeumorphicSkeleton.row(),
      const NeumorphicSkeleton.lines(3),
    ]),
    _part('Badges, tags and live marks', [
      // Counts and tags on one line, the live marks on the next, each its own job: in one wrap 'Live' and 'Online'
      // stood side by side as the same dot and word, and the row broke with 'Online' alone.
      _wrap([
        const NeumorphicBadge(3),
        const NeumorphicBadge(120),
        const NeumorphicTag('Draft'),
        const NeumorphicTag('Shared'),
      ], gap: 16),
      _wrap([
        // The live words with their own LED, 8 from it as a status's dot stands from its words: a loose LED 16 before
        // them read as a second mark.
        const NeumorphicLiveText('Recording', led: true),
        const NeumorphicStatus('Sam is online', live: true),
        // A state that isn't live is plain ink: with its glyph, so it reads as a status and not a stray word.
        const NeumorphicStatus('Away', icon: NeumorphicGlyphs.clock),
      ], gap: 16),
    ]),
  ]);

  // ---------------------------------------------------------------- Charts

  /// The week's rain as the chosen kind, each kind by its own class.
  Widget _rainChart() {
    const label = 'Rain this week';
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    const rain = NeumorphicChartSeries('Rain, mm', [3, 5, 9, 4, 2, 1, 3]);
    const last = NeumorphicChartSeries('Last week', [2, 3, 4, 6, 3, 3, 2]);
    final empty = _chartEmpty;
    return switch (_chartKind) {
      LiveChartKind.line => NeumorphicLineChart(
        label: label,
        loading: _chartLoading,
        labels: labels,
        series: empty ? const [] : const [rain, last],
      ),
      LiveChartKind.bar => NeumorphicBarChart(
        label: label,
        loading: _chartLoading,
        labels: labels,
        series: empty ? const [] : const [rain, last],
      ),
      LiveChartKind.area => NeumorphicAreaChart(
        label: label,
        loading: _chartLoading,
        labels: labels,
        series: empty ? const [] : const [rain],
      ),
    };
  }

  // One measure for every chart, a chart's own 680: each standing at its own width, the column's edge was ragged.
  Widget _charts() => Align(
    alignment: AlignmentDirectional.topStart,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 680),
      child: _chartsBody(),
    ),
  );

  Widget _chartsBody() => _stack([
    _part('Line, bar and area', [
      NeumorphicSegmentedButton<LiveChartKind>(
        label: 'Chart',
        value: _chartKind,
        segments: const [
          NeumorphicButtonSegment(LiveChartKind.line, 'Line'),
          NeumorphicButtonSegment(LiveChartKind.bar, 'Bar'),
          NeumorphicButtonSegment(LiveChartKind.area, 'Area'),
        ],
        onChanged: (v) => setState(() => _chartKind = v),
      ),
      _wrap([
        NeumorphicChip(
          'Loading',
          selected: _chartLoading,
          onPressed: () => setState(() => _chartLoading = !_chartLoading),
        ),
        NeumorphicChip(
          'Empty',
          selected: _chartEmpty,
          onPressed: () => setState(() => _chartEmpty = !_chartEmpty),
        ),
      ]),
      _rainChart(),
    ]),
    _part('Donut and sparkline', [
      const NeumorphicPieChart(
        label: 'Energy today',
        caption: 'kWh today',
        slices: [
          NeumorphicPieSlice('Heating', 9.2),
          NeumorphicPieSlice('Water', 3.1),
          NeumorphicPieSlice('Kitchen', 2.4),
          NeumorphicPieSlice('Lights', 1.3),
        ],
      ),
      // The line beside its name, as a figure stands beside its label: at the row's two ends they were strangers.
      const Wrap(
        spacing: 16,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('Steps this week'),
          NeumorphicSparkline(label: 'Steps', values: [4, 6, 5, 7, 6, 8, 9]),
        ],
      ),
    ]),
    _part('The look\'s own bars', [
      const NeumorphicColumnBars(
        values: [2, 4, 3, 5, 1, 2, 4],
        labels: ['M', 'T', 'W', 'T', 'F', 'S', 'S'],
        now: 3,
        forecast: 5,
        nowLabel: 'Today, so far',
        forecastLabel: 'Expected by tonight',
        format: _hours,
      ),
      const NeumorphicTwoWayBars(
        above: [2, 4, 3, 5, 2, 1],
        below: {1: 1, 4: 2},
        slots: 6,
        peak: '5 kW',
        now: 2.5,
        nowLabel: 'Now',
        labels: {0: '06', 5: '18'},
        // Each swatch is its series' own paint: what was used in ink above the line, what was made in the pigment
        // below it.
        keys: [
          NeumorphicLegendItem('Used'),
          NeumorphicLegendItem('Made', kind: NeumorphicLegendSwatch.live),
        ],
      ),
      const NeumorphicShareBars(
        rows: [
          NeumorphicShare('Heating', '9.2', .55),
          NeumorphicShare('Water', '3.1', .18),
          NeumorphicShare('Kitchen', '2.4', .14),
        ],
      ),
      const NeumorphicStepLine(
        // What was used so far: a reading stops at now, where the set line's day still to come is dashed.
        readings: [(0, 2), (4, 2.4), (8, 3.4), (12, 3.6)],
        steps: [(0, 2), (12, 3), (24, 3)],
        now: 12,
        xMax: 24,
        yMin: 0,
        yMax: 5,
        yTicks: [1, 3, 5],
        // A unit word follows its figure after a space that never breaks, as the bars' "5 kW" does ("°" needs none).
        yLabel: ' kW',
        xLabels: [(0, '00'), (12, '12'), (24, '24')],
        keys: [
          NeumorphicLegendItem('Used'),
          NeumorphicLegendItem('Set', kind: NeumorphicLegendSwatch.line),
        ],
        note: 'Today',
      ),
    ]),
    _part('A chart key on its own', [
      const NeumorphicLegend([
        NeumorphicLegendItem('Used'),
        NeumorphicLegendItem('Made', kind: NeumorphicLegendSwatch.live),
        NeumorphicLegendItem('Set', kind: NeumorphicLegendSwatch.line),
      ], note: 'Today'),
    ]),
  ]);

  // ---------------------------------------------------------------- Type and colour

  Widget _type() {
    final t = _t;
    final c = t.colors;
    Widget chip(String name, Widget object) => SizedBox(
      child: NeumorphicSurface(
        cast: NeumorphicSurfaceLevel.part,
        padding: const EdgeInsets.all(12),
        child: NeumorphicBeside(
          object: object,
          child: Text(name, style: t.textTheme.caption),
        ),
      ),
    );
    Widget swatch(String name, Color color) => chip(
      name,
      DecoratedBox(
        decoration: ShapeDecoration(
          color: color,
          shape: t.shapes.circle(28).copyWith(side: BorderSide(color: c.rim)),
        ),
        child: const SizedBox.square(dimension: 28),
      ),
    );
    return _stack([
      _part('Type scale', [
        // Largest to smallest at this width: a phone's page head is smaller than a figure, so a fixed order listed
        // 30 px over 48.
        for (final (name, style) in [
          ('Page', t.textTheme.page),
          ('Figure', t.textTheme.figure),
          ('Value', t.textTheme.value),
          ('Title', t.textTheme.title),
          ('Body', t.textTheme.body),
          ('Caption', t.textTheme.caption),
          ('Micro', t.textTheme.micro),
        ]..sort((a, b) => (b.$2.fontSize ?? 0).compareTo(a.$2.fontSize ?? 0)))
          NeumorphicSplit(
            start: NeumorphicText(name, style: style),
            end: Text(
              '${style.fontSize?.toStringAsFixed(0)} px',
              style: t.textTheme.caption.tabular,
            ),
          ),
        // In a heading's measure, so it breaks at every width: on one line at 1440 it showed nothing.
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: const NeumorphicBalancedText(
              'A balanced heading breaks its lines evenly, so no word hangs alone',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              textAlign: TextAlign.start,
            ),
          ),
        ),
        // A label stands over its control: alone it was a caption that pointed at nothing.
        _stack([
          const NeumorphicLabel('A label over a control'),
          const NeumorphicTextField(
            label: 'A label over a control',
            nameOnly: true,
            hint: 'Kitchen',
          ),
        ], gap: 8),
      ]),
      // The tiles share the column's width in equal columns: at 150 each the grid stopped short of the column's edge.
      _part('Colour roles', [
        _grid(150, [
          swatch('Ground', c.ground),
          swatch('Face', c.faceStart),
          swatch('Well', c.wellStart),
          swatch('Light', c.highlight),
          swatch('Shadow', c.shadow),
          swatch('Rim', c.rim),
          swatch('Ink', c.ink),
          swatch('Ink 2', c.inkSecondary),
          swatch('Ink 3', c.inkTertiary),
          swatch('Quiet', c.quiet),
          swatch('Edge', c.edge),
          // The pigment is the look's one live colour; on the palette it is a sample as the others are, the same size.
          swatch('Pigment', c.accent),
        ]),
      ]),
      // Each mark with the kind it stands for, as a legend would show it: bare, three dots read as decoration.
      _part('Shape marks', [
        _wrap([
          for (final (shape, kind) in [
            (NeumorphicMarkShape.solid, 'Home'),
            (NeumorphicMarkShape.ring, 'Work'),
            (NeumorphicMarkShape.half, 'Shared'),
          ])
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                NeumorphicShapeMark(shape, size: 14),
                const SizedBox(width: 8),
                Text(kind),
              ],
            ),
        ], gap: 24),
      ]),
      // Named for the parts, not the card: 'With every shadow gone' over a card still casting its own read as the
      // demo contradicting its caption (fresh-eyes rounds).
      _part('Parts with their shadows gone', [
        const Text(
          'On the card, the parts as a washed-out screen shows them, faces and marks alone: every state still reads.',
        ),
        // One to a line, each with its words: a bare switch with its shadows gone is a ring on the wall, and a bare
        // checkbox beside it a row of two heights no screen sets. The slab keeps its relief, so the washed-out parts
        // read as a specimen on a card, not as controls that lost their styling; a setting's width, so the switch
        // stays by its words.
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: NeumorphicSlab(
              child: NeumorphicFlatScope(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 16,
                  children: [
                    NeumorphicSwitchRow(
                      label: 'Alerts',
                      value: _pushUpdates,
                      onChanged: (v) => setState(() => _pushUpdates = v),
                    ),
                    NeumorphicCheckRow(
                      label: 'Receipt',
                      value: _checked,
                      onChanged: (v) => setState(() => _checked = v ?? false),
                    ),
                    NeumorphicLatchGroup(
                      value: _latch,
                      options: const [
                        NeumorphicLatch('Auto'),
                        NeumorphicLatch('Off'),
                      ],
                      onChanged: (v) => setState(() => _latch = v),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ]),
      _part('Layout', [
        // Three equal slabs, each a figure over its word: as wells with a word in each they read as three fields to
        // type in (law 3). Where a third of the row can't hold the longest word whole (a phone at twice the text broke
        // 'Lights'), they stand one to a line.
        LayoutBuilder(
          builder: (context, box) {
            const figures = [
              ('3', 'Lights'),
              ('21°', 'Inside'),
              ('2', 'Doors'),
            ];
            final scaler = MediaQuery.textScalerOf(context);
            var widest = 0.0;
            for (final (_, word) in figures) {
              final w = _wordWidth(word, _t.textTheme.caption, scaler);
              if (w > widest) widest = w;
            }
            final slabs = [
              for (final (figure, word) in figures)
                NeumorphicSlab(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(figure, style: _t.textTheme.title.tabular),
                      Text(word, style: _t.textTheme.caption),
                    ],
                  ),
                ),
            ];
            if ((box.maxWidth - 32) / 3 < widest + 28) {
              return NeumorphicColumn(gap: 16, children: slabs);
            }
            return NeumorphicEqualRow(
              flex: const [1, 1, 1],
              gap: 16,
              children: slabs,
            );
          },
        ),
        // Columns as wide as their words want: the short one stays on one line, the long one wraps.
        const NeumorphicAutoRow(
          children: [
            Text('Delivery'),
            Text(
              'Saturday 14 November, between nine and noon, to the side door',
            ),
          ],
        ),
      ]),
    ]);
  }

  // ---------------------------------------------------------------- Relief and dials

  Widget _relief() => LayoutBuilder(
    builder: (context, box) {
      final columns = box.maxWidth >= 700 ? 2 : 1;
      // Two columns stand a section's gap apart: at 24 a column's trailing caption ran into the next one's heading
      // ("Living room Meters").
      final gap = columns == 2 ? 48.0 : 24.0;
      return _stack([
        NeumorphicGridOf(
          columns: columns,
          gap: gap,
          children: [
            NeumorphicWallSet(
              title: 'Thermostat',
              subtitle: 'Living room',
              child: NeumorphicDial(
                value: _dial,
                min: 10,
                max: 30,
                figure: '${_dial.toStringAsFixed(1)}°',
                label: 'Target',
                compact: true,
                onDecrease: () => setState(() => _dial -= .5),
                onIncrease: () => setState(() => _dial += .5),
              ),
            ),
            // The meters and the lights stand in one column beside the thermostat: the meters alone left a hole
            // 260 tall beside the dial.
            _stack([
              NeumorphicWallSet(
                title: 'Meters',
                child: _stack([
                  _wrap([
                    NeumorphicGauge(
                      value: _dial * 3,
                      figure: '${(_dial * 3).round()}',
                      name: 'Load',
                      live: true,
                      onPressed: () => _say('Load'),
                    ),
                    // Two readings of a few, one size and both named: a bare small dial beside a gauge stood smaller,
                    // lower and without a name.
                    NeumorphicGauge(
                      value: _dial,
                      min: 10,
                      max: 30,
                      figure: '${_dial.round()}°',
                      name: 'Inside',
                    ),
                  ], gap: 20),
                  // The knob reads the volume and the slider under it sets it: one item, as the recording's words and
                  // track are. Apart on the column's gap, the slider stood alone, a bare track with no name.
                  _stack([
                    NeumorphicKnobRow(
                      value: _knob,
                      label: 'Volume',
                      figure: '${(_knob * 100).round()}',
                    ),
                    NeumorphicSlider(
                      label: 'Volume',
                      value: _knob,
                      onChanged: (v) => setState(() => _knob = v),
                    ),
                  ], gap: 4),
                ]),
              ),
              NeumorphicWallSet(
                title: 'Lights',
                child: NeumorphicPushGroup(
                  items: [
                    NeumorphicPush(
                      icon: NeumorphicGlyphs.sun,
                      label: 'Day',
                      note: 'Until six',
                      selected: _latch != 'Off',
                      onPressed: () => setState(() => _latch = 'Auto'),
                    ),
                    NeumorphicPush(
                      icon: NeumorphicGlyphs.moon,
                      label: 'Night',
                      selected: _latch == 'Off',
                      onPressed: () => setState(() => _latch = 'Off'),
                    ),
                  ],
                ),
              ),
            ], gap: gap),
          ],
        ),
        // The timer and the month stand in the same columns as the thermostat and the meters: alone at the page's
        // width the timer floated and the month's days stood 150 px apart.
        NeumorphicGridOf(
          columns: columns,
          gap: gap,
          children: [
            const NeumorphicWallSet(
              title: 'Timer',
              subtitle: 'Bread',
              child: NeumorphicSpanDial(
                start: '09:00',
                end: '10:00',
                elapsed: 20,
                total: 60,
                figure: '40',
                unit: 'min',
                tag: 'Left',
              ),
            ),
            NeumorphicWallSet(
              title: 'Calendar',
              child: NeumorphicMonth(
                year: _date.year,
                month: _date.month,
                today: _date.day,
                onDay: (d) => setState(
                  () => _date = DateTime(_date.year, _date.month, d),
                ),
              ),
            ),
          ],
        ),
        // A morning's tray at the page's width, under the timer and the calendar beside it.
        const NeumorphicWallSet(
          title: 'Morning',
          child: NeumorphicDayTray(
            from: 8,
            to: 12,
            events: [
              NeumorphicTrayEvent(
                start: '08:30',
                end: '09:30',
                title: 'Reading',
                subtitle: 'At home',
              ),
              NeumorphicTrayEvent(
                start: '10:00',
                end: '11:00',
                title: 'Call with Sam',
                subtitle: 'Kitchen',
              ),
            ],
            free: [NeumorphicTrayFree('11:00', '12:00', 'Free')],
          ),
        ),
        // The look's hero, as an app's home would cast it: a house of rooms, each floor on its string course, the lit
        // rooms glowing. A phone gets the small elevation beside the words; the desk the whole casting.
        NeumorphicRelief(
          title: '14',
          subtitle: 'Harbour Street',
          count: '*4 of 6* rooms on',
          compact: true,
          onPressed: () => _say('House'),
          courses: [
            NeumorphicCourse('Upper', [
              NeumorphicBay(
                name: 'Bedroom',
                figure: '19.5°',
                note: 'Off',
                onPressed: () => _say('Bedroom'),
              ),
              NeumorphicBay(
                name: 'Study',
                figure: '20.5°',
                note: 'On',
                lit: .8,
                onPressed: () => _say('Study'),
              ),
              NeumorphicBay(
                name: 'Bath',
                figure: '22.0°',
                note: 'On',
                lit: .4,
                onPressed: () => _say('Bath'),
              ),
            ]),
            NeumorphicCourse('Ground', [
              NeumorphicBay(
                name: 'Kitchen',
                figure: '21.0°',
                note: 'On',
                lit: .6,
                onPressed: () => _say('Kitchen'),
              ),
              NeumorphicBay(
                name: 'Living room',
                figure: '21.5°',
                note: 'On',
                lit: 1,
                onPressed: () => _say('Living room'),
              ),
              NeumorphicBay(
                name: 'Hall',
                figure: '19.0°',
                note: 'Off',
                onPressed: () => _say('Hall'),
              ),
            ]),
          ],
          ground: const [
            NeumorphicGroundNote('Garden', icon: NeumorphicGlyphs.trees),
            NeumorphicGroundNote('Door locked'),
            NeumorphicGroundNote('Car charging'),
          ],
        ),
        // Named, as every part of the page is: bare under the house they read as copy left behind.
        _part('Words on the wall: a figure and a page head', [
          // Two specimens, a room apart: 14 under the figure, the head's overline ('Rooms') read as its caption.
          const Padding(
            padding: EdgeInsets.only(bottom: 18),
            child: NeumorphicFigure('16.8', unit: 'kWh'),
          ),
          const NeumorphicPageHead(
            title: 'A page head',
            overline: 'Rooms',
            subtitle: 'Its words stand on the wall.',
          ),
        ]),
      ]);
    },
  );

  // ---------------------------------------------------------------- Shape roles

  Widget _shapes() => _stack([
    // What the lineup is for, so it reads as one and not as a grab-bag of parts.
    Text(
      'One of each part in its own shape, so their corners read side by side: a field, a bank, a track, choices, '
      'tabs, rows, chips, a card\'s list and buttons.',
      style: _t.textTheme.body.copyWith(color: _t.colors.inkSecondary),
    ),
    NeumorphicTextField(label: 'Display name', controller: _name),
    NeumorphicSegmentedButton<String>(
      label: 'Billing period',
      value: _segment == 'quarter' ? 'month' : _segment,
      segments: const [
        NeumorphicButtonSegment('month', 'Monthly'),
        NeumorphicButtonSegment('year', 'Yearly'),
      ],
      onChanged: (v) => setState(() => _segment = v),
    ),
    // Its name and level over it, as every slider on these pages has: bare, it was a track with no name.
    _stack([
      ExcludeSemantics(
        child: NeumorphicSplit(
          start: Text('Alert volume', style: _t.textTheme.caption),
          end: Text(
            '${(_level * 100).round()}%',
            style: _t.textTheme.caption.tabular,
          ),
        ),
      ),
      NeumorphicSlider(
        label: 'Alert volume',
        value: _level,
        onChanged: (v) => setState(() => _level = v),
      ),
    ], gap: 0),
    NeumorphicRadioGroup<String>(
      label: 'Delivery',
      value: _radio == 'pickup' ? 'standard' : _radio,
      options: const [
        NeumorphicRadio('standard', 'Standard'),
        NeumorphicRadio('express', 'Express'),
      ],
      onChanged: (v) => setState(() => _radio = v),
    ),
    NeumorphicTabBar(
      tabs: const ['Overview', 'Activity'],
      selectedIndex: _tab % 2,
      onChanged: (v) => setState(() => _tab = v),
    ),
    NeumorphicTimePicker(
      value: _time,
      minuteStep: 30,
      onChanged: (v) => setState(() => _time = v),
    ),
    NeumorphicSwitchRow(
      label: 'Weekly summary',
      value: _emailUpdates,
      onChanged: (v) => setState(() => _emailUpdates = v),
    ),
    NeumorphicCheckRow(
      label: 'Remember this choice',
      value: _checked,
      onChanged: (v) => setState(() => _checked = v ?? false),
    ),
    NeumorphicSelect<String>(
      label: 'Country',
      value: _country,
      options: const [
        NeumorphicMenuItem('United States', 'United States'),
        NeumorphicMenuItem('Canada', 'Canada'),
      ],
      onChanged: (v) => setState(() => _country = v),
    ),
    _wrap([
      for (final (i, name) in ['All', 'Unread', 'Starred'].indexed)
        NeumorphicChip(
          name,
          selected: _filter == i,
          onPressed: () => setState(() => _filter = i),
        ),
    ], gap: 10),
    const NeumorphicListSection(
      label: 'Plan',
      children: [
        NeumorphicKvRow('Plan', 'Studio', isFirst: true),
        NeumorphicKvRow('Seats', '4'),
        NeumorphicKvRow('Renews', 'March'),
      ],
    ),
    _wrap([
      NeumorphicButton.filled('Save', onPressed: () => _say('Saved')),
      NeumorphicButton('Preview', onPressed: () => _say('Previewing')),
      NeumorphicButton('Open dialog', onPressed: _dialog),
    ]),
  ]);

  @override
  Widget build(BuildContext context) {
    final theme = NeumorphicTheme.of(context);
    final page = liveGalleryPages.firstWhere(
      (p) => p.id == widget.page,
      orElse: () => liveGalleryPages.first,
    );
    // The inventory lists itself: a lazy list of all 89 rows, so its page is the list rather than a column in a scroll.
    // Its title stands at the page's inset like every page's, above the list, and scrolls away with it: an open
    // customizing panel on a phone is taller than what is left of the screen.
    if (page.id == 'inventory') {
      return ColoredBox(
        color: theme.colors.ground,
        child: NestedScrollView(
          headerSliverBuilder: (context, _) => [
            SliverPadding(
              padding: theme.desk
                  ? const EdgeInsets.fromLTRB(48, 40, 48, 0)
                  : const EdgeInsets.fromLTRB(20, 16, 20, 0),
              sliver: SliverToBoxAdapter(
                child: _stack([
                  ?widget.header,
                  Text(page.title, style: theme.textTheme.page),
                ], gap: 28),
              ),
            ),
          ],
          body: NeumorphicInventoryGallery(
            padding: theme.desk
                ? const EdgeInsets.fromLTRB(48, 4, 48, 56)
                : const EdgeInsets.fromLTRB(20, 4, 20, 32),
          ),
        ),
      );
    }
    final child = switch (page.id) {
      'overview' => _overview(),
      'buttons' => _buttons(),
      'fields' => _fields(),
      'selection' => _selection(),
      'pickers' => _pickers(),
      'navigation' => _navigation(),
      'lists' => _lists(),
      'cards' => _cards(),
      'dialogs' => _dialogs(),
      'feedback' => _feedbackPage(),
      'charts' => _charts(),
      'actions' => _stack(kitActionsSections()),
      'more-fields' => _stack(kitFieldsSections()),
      'collections' => _stack(kitCollectionsSections()),
      'overlays' => _stack(kitOverlaysSections()),
      'records' => _stack(kitRecordsSections()),
      'type' => _type(),
      'relief' => _relief(),
      _ => _shapes(),
    };
    final wide = const {'cards', 'relief', 'overview'}.contains(page.id);
    return DefaultTextStyle(
      style: theme.textTheme.body,
      child: IconTheme(
        data: IconThemeData(color: theme.colors.ink),
        child: ColoredBox(
          color: theme.colors.ground,
          child: SingleChildScrollView(
            key: const Key('live-scroll'),
            // The look's own page insets: NeumorphicScaffold's at each width.
            padding: theme.desk
                ? const EdgeInsets.fromLTRB(48, 40, 48, 56)
                : const EdgeInsets.fromLTRB(20, 16, 20, 32),
            // One page margin for every page: each starts at the inset, a reading page keeping its 720 measure from
            // there rather than standing in the middle of what is left.
            child: Align(
              alignment: AlignmentDirectional.topStart,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: wide ? 1120 : 720),
                child: _stack([
                  ?widget.header,
                  // The Overview opens on its pitch, not on its own name.
                  if (page.id != 'overview')
                    Text(page.title, style: theme.textTheme.page),
                  child,
                  // What the last part tried said, as the kit says where a thing stands: a check and the answer.
                  // As a labelled line ('Last answer  Saved') it read as debug output left on the page.
                  if (_status.isNotEmpty)
                    Semantics(
                      liveRegion: true,
                      child: NeumorphicStatus(
                        _status,
                        key: const Key('live-status'),
                        icon: NeumorphicGlyphs.check,
                      ),
                    ),
                ], gap: 28),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The live charts page's choice: which of the three chart classes it draws.
enum LiveChartKind { line, bar, area }

/// A row's way in: a chevron pointing the way the words read (left in a right-to-left app).
class _Onward extends StatelessWidget {
  const _Onward();

  @override
  Widget build(BuildContext context) => Icon(
    Directionality.of(context) == TextDirection.rtl
        ? NeumorphicGlyphs.chevronLeft
        : NeumorphicGlyphs.chevronRight,
    size: 18,
  );
}

/// The width of [word] in [style] at the reader's text size.
double _wordWidth(String word, TextStyle style, TextScaler scaler) {
  final painter = TextPainter(
    text: TextSpan(text: word, style: style),
    textDirection: TextDirection.ltr,
    textScaler: scaler,
  )..layout();
  final width = painter.width;
  painter.dispose();
  return width;
}
