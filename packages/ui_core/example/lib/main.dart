// A plain look on four behaviours: a toggle group, a labelled field, a
// button and toasts. Every pixel here is the example's own; the behaviours
// give it focus, the keyboard, the states and what a screen reader hears.
// No Material, no Cupertino.
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'ink_proof.dart' show InkProofPage;
import 'values.dart';

// 0.3.0 routes
import 'routes.dart';

// 0.3.0 routes end

void main() => runApp(const ExampleApp());

const Color _ink = Color(0xFF1F2328);
const Color _paper = Color(0xFFFFFFFF);
const Color _line = Color(0xFFD0D7DE);
const Color _accent = Color(0xFF0969DA);
const Color _wrong = Color(0xFFCF222E);

/// The example: a bare [WidgetsApp] whose navigator stands in a
/// [DesignToaster], so any page can show a toast.
class ExampleApp extends StatelessWidget {
  /// The example app.
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) => WidgetsApp(
    color: _accent,
    title: 'ui_core example',
    pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) =>
        PageRouteBuilder<T>(
          settings: settings,
          pageBuilder: (context, _, _) => builder(context),
        ),
    builder: (context, navigator) => DefaultTextStyle(
      style: const TextStyle(fontSize: 16, color: _ink),
      child: DesignToaster(
        toastBuilder: (context, details) => _Toast(details: details),
        child: navigator!,
      ),
    ),
    home: const ReportPage(),
  );
}

/// One page: the report's name, its period, and Save.
class ReportPage extends StatefulWidget {
  /// The page.
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  // The page owns what it makes, and disposes it.
  final TextEditingController _name = TextEditingController();
  final FocusNode _nameFocus = FocusNode();
  Set<String> _period = {'Week'};
  String? _nameError;

  @override
  void dispose() {
    _name.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    setState(() => _nameError = name.isEmpty ? 'Give the report a name' : null);
    if (name.isEmpty) {
      _nameFocus.requestFocus();
      return;
    }
    DesignToaster.of(context)
        .show(DesignToast(message: 'Saved "$name" for the ${_period.single}'));
  }

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: _paper,
    child: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        // A form keeps a reading width on a wide screen, at the page's start.
        child: Align(
          alignment: AlignmentDirectional.topStart,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            // On a screen too short for it, the report scrolls.
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'New report',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 24),
                  DesignField(
                    labelText: 'Name',
                    helperText: 'Shown at the top of the report',
                    errorText: _nameError,
                    required: true,
                    focusNode: _nameFocus,
                    builder: (context, parts) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ?parts.label,
                        const SizedBox(height: 6),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            // Wrong outranks focused, which outranks at rest.
                            border: Border.all(
                              color: parts.hasError
                                  ? _wrong
                                  : (parts.focused ? _accent : _line),
                              width: parts.hasError || parts.focused ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: parts.control,
                          ),
                        ),
                        const SizedBox(height: 4),
                        DefaultTextStyle.merge(
                          style: TextStyle(
                            fontSize: 13,
                            color: parts.hasError
                                ? _wrong
                                : const Color(0xFF59636E),
                          ),
                          child:
                              parts.error ?? parts.helper ?? const SizedBox(),
                        ),
                      ],
                    ),
                    child: EditableText(
                      controller: _name,
                      focusNode: _nameFocus,
                      style: const TextStyle(fontSize: 16, color: _ink),
                      cursorColor: _accent,
                      backgroundCursorColor: _line,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Period'),
                  const SizedBox(height: 6),
                  DesignToggleGroup<String>(
                    options: const ['Day', 'Week', 'Month'],
                    selected: _period,
                    onSelectionChanged: (next) =>
                        setState(() => _period = next),
                    semanticLabel: 'Period',
                    // One frame round the three, with a hairline between: the
                    // segments share their outline rather than butt three boxes.
                    layoutBuilder: (context, items) => _Segments(items: items),
                    itemBuilder: (context, value, states) => _Segment(
                      selected: states.contains(WidgetState.selected),
                      focused: states.contains(WidgetState.focused),
                      child: Text(value),
                    ),
                  ),
                  const SizedBox(height: 32),
                  DesignPressable(
                    onPressed: _save,
                    semanticLabel: 'Save',
                    builder: (context, states, child) => _Box(
                      selected: !states.contains(WidgetState.pressed),
                      focused: states.contains(WidgetState.focused),
                      child: const Text('Save'),
                    ),
                  ),
                  // 0.3.0 overlays
                  const SizedBox(height: 32),
                  const _ReportFile(),
                  const SizedBox(height: 32),
                  const _SendTo(),
                  const SizedBox(height: 32),
                  // The other pages, side by side.
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      // 0.3.0 routes
                      DesignPressable(
                        onPressed: () => Navigator.of(context).push(
                          PageRouteBuilder<void>(
                            pageBuilder: (context, _, _) => const RoutesPage(),
                          ),
                        ),
                        semanticLabel: 'Routes',
                        builder: (context, states, child) => _Box(
                          selected: false,
                          focused: states.contains(WidgetState.focused),
                          child: const Text('Routes'),
                        ),
                      ),
                      // 0.3.0 routes end
                      // 0.3.0 values
                      DesignPressable(
                        onPressed: () => Navigator.of(context).push(
                          PageRouteBuilder<void>(
                            pageBuilder: (context, _, _) => const ValuesPage(),
                          ),
                        ),
                        semanticLabel: 'Values',
                        builder: (context, states, child) => _Box(
                          selected: false,
                          focused: states.contains(WidgetState.focused),
                          child: const Text('Values'),
                        ),
                      ),
                      // 0.3.0 values end
                      DesignPressable(
                        onPressed: () => Navigator.of(context).push(
                          PageRouteBuilder<void>(
                            pageBuilder: (context, _, _) =>
                                const InkProofPage(),
                          ),
                        ),
                        semanticLabel: 'Ink proof',
                        builder: (context, states, _) => _Box(
                          selected: false,
                          focused: states.contains(WidgetState.focused),
                          child: const Text('Ink proof'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// The example's one shape: a box, filled when [selected], ringed when
/// [focused].
class _Box extends StatelessWidget {
  const _Box({
    required this.selected,
    required this.focused,
    required this.child,
  });

  final bool selected;
  final bool focused;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
    padding: const EdgeInsets.symmetric(horizontal: 16),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: selected ? _accent : _paper,
      border: Border.all(
        color: focused ? _ink : (selected ? _accent : _line),
        width: focused ? 2 : 1,
      ),
      borderRadius: BorderRadius.circular(6),
    ),
    child: DefaultTextStyle.merge(
      style: TextStyle(color: selected ? _paper : _ink),
      child: child,
    ),
  );
}

/// The toggle group's items in one frame: rounded outside, a hairline
/// between neighbours.
class _Segments extends StatelessWidget {
  const _Segments({required this.items});

  final List<Widget> items;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    position: DecorationPosition.foreground,
    decoration: BoxDecoration(
      border: Border.all(color: _line),
      borderRadius: BorderRadius.circular(6),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: IntrinsicHeight(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, item) in items.indexed) ...[
              if (i > 0)
                const SizedBox(width: 1, child: ColoredBox(color: _line)),
              item,
            ],
          ],
        ),
      ),
    ),
  );
}

/// One segment: filled when [selected], ringed inside when [focused].
class _Segment extends StatelessWidget {
  const _Segment({
    required this.selected,
    required this.focused,
    required this.child,
  });

  final bool selected;
  final bool focused;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
    padding: const EdgeInsets.symmetric(horizontal: 16),
    alignment: Alignment.center,
    color: selected ? _accent : _paper,
    foregroundDecoration: focused
        ? BoxDecoration(
            border: Border.all(color: _ink, width: 2),
            borderRadius: BorderRadius.circular(4),
          )
        : null,
    child: DefaultTextStyle.merge(
      style: TextStyle(color: selected ? _paper : _ink),
      child: child,
    ),
  );
}

class _Toast extends StatelessWidget {
  const _Toast({required this.details});

  final DesignToastDetails details;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: _ink,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          details.toast.message,
          style: const TextStyle(color: _paper),
        ),
      ),
    ),
  );
}

// 0.3.0 overlays: a menu at the pointer, a tooltip with a tail.

/// The report's file: a menu of its actions at the pointer (a right click,
/// a long press, Shift+F10 or the Menu key), each row with its keys as the
/// platform spells them (they work while the report has the focus), and an
/// "i" whose tooltip's tail points at it wherever the tip lands.
class _ReportFile extends StatelessWidget {
  const _ReportFile();

  void _say(BuildContext context, String words) =>
      DesignToaster.of(context).show(DesignToast(message: words));

  // A command's keys: Cmd on Apple's platforms, Ctrl elsewhere.
  static SingleActivator _keys(LogicalKeyboardKey key) {
    final apple =
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.iOS;
    return SingleActivator(key, meta: apple, control: !apple);
  }

  @override
  Widget build(BuildContext context) {
    void open() => _say(context, 'Opened Q3 report.pdf');
    void duplicate() => _say(context, 'Made Q3 report copy.pdf');
    final openKeys = _keys(LogicalKeyboardKey.keyO);
    final duplicateKeys = _keys(LogicalKeyboardKey.keyD);
    return Row(
      children: [
        Expanded(
          child: DesignContextMenu(
            semanticLabel: 'Q3 report.pdf',
            menuChildren: [
              DesignMenuEntry(
                label: 'Open',
                shortcut: designShortcutLabel(context, openKeys),
                onPressed: open,
              ),
              DesignMenuEntry(
                label: 'Duplicate',
                shortcut: designShortcutLabel(context, duplicateKeys),
                onPressed: duplicate,
              ),
              const DesignMenuEntry.divider(),
              const DesignMenuEntry(label: 'Delete'),
            ],
            itemBuilder: (context, entry, level, states) => _MenuRow(
              lit:
                  states.contains(WidgetState.focused) ||
                  states.contains(WidgetState.hovered),
              enabled: !states.contains(WidgetState.disabled),
              child: Row(
                children: [
                  Expanded(child: Text(entry.label)),
                  if (entry.shortcut case final keys?) ...[
                    const SizedBox(width: 24),
                    ExcludeSemantics(
                      child: Text(
                        keys,
                        style: const TextStyle(color: Color(0xFF6E7781)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            dividerBuilder: (context) => const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: SizedBox(height: 1, child: ColoredBox(color: _line)),
            ),
            surfaceBuilder: (context, info, items) => FadeTransition(
              opacity: info.animation,
              child: _Panel(children: items),
            ),
            child: CallbackShortcuts(
              bindings: {openKeys: open, duplicateKeys: duplicate},
              child: DesignPressable(
                onPressed: open,
                semanticLabel: 'Q3 report.pdf',
                builder: (context, states, child) => _Box(
                  selected: false,
                  focused: states.contains(WidgetState.focused),
                  child: const Text('Q3 report.pdf'),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        DesignTooltip(
          message: 'About this report',
          tooltipBuilder: (context, info) =>
              _Tip(info: info, message: 'About this report'),
          child: DesignPressable(
            onPressed: () => _say(context, 'Q3 report: 12 pages, edited today'),
            semanticLabel: 'About',
            builder: (context, states, child) => _Box(
              selected: false,
              focused: states.contains(WidgetState.focused),
              child: const Text('i'),
            ),
          ),
        ),
      ],
    );
  }
}

/// A menu's panel: white, a hairline round it.
class _Panel extends StatelessWidget {
  const _Panel({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: _paper,
      border: Border.all(color: _line),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Padding(
      padding: const EdgeInsets.all(4),
      child: IntrinsicWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    ),
  );
}

/// A menu's row: tinted when [lit] (the one the keys or the pointer are
/// on), faint when not [enabled].
class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.lit,
    required this.enabled,
    required this.child,
  });

  final bool lit;
  final bool enabled;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minWidth: 160, minHeight: 44),
    padding: const EdgeInsets.symmetric(horizontal: 12),
    alignment: AlignmentDirectional.centerStart,
    decoration: BoxDecoration(
      color: lit ? const Color(0x1F0969DA) : null,
      borderRadius: BorderRadius.circular(4),
    ),
    child: DefaultTextStyle.merge(
      style: TextStyle(color: enabled ? _ink : const Color(0xFF8C959F)),
      child: child,
    ),
  );
}

/// A tooltip's tip: dark, with a tail at the control's centre, on the side
/// the tip took.
class _Tip extends StatelessWidget {
  const _Tip({required this.info, required this.message});

  final DesignOverlayInfo info;
  final String message;

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: info.animation,
    child: CustomPaint(
      painter: _TipPainter(info),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          message,
          style: const TextStyle(fontSize: 13, color: _paper),
        ),
      ),
    ),
  );
}

// Where the tip landed is known only as it is laid out: the painter
// listens to it, so the tail is right in the first frame.
class _TipPainter extends CustomPainter {
  _TipPainter(this.info) : super(repaint: info.surfaceRect);

  final DesignOverlayInfo info;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = _ink;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(6)),
      paint,
    );
    final placed = info.surfaceRect.value;
    if (placed == null || size.width < 20) return;
    final x = (info.anchorRect.center.dx - placed.left).clamp(
      10.0,
      size.width - 10,
    );
    final below = info.side == DesignOverlaySide.below;
    final edge = below ? 0.0 : size.height;
    final point = below ? -5.0 : 5.0;
    canvas.drawPath(
      Path()
        ..moveTo(x - 5, edge)
        ..lineTo(x, edge + point)
        ..lineTo(x + 5, edge)
        ..close(),
      paint,
    );
  }

  @override
  bool shouldRepaint(_TipPainter oldDelegate) => oldDelegate.info != info;
}

/// Whom to send the report to: a search that takes its time and can fail.
/// The list says it is looking; offline, it says it could not load, with a
/// way to try again (Down then Enter, or a tap).
class _SendTo extends StatefulWidget {
  const _SendTo();

  @override
  State<_SendTo> createState() => _SendToState();
}

class _SendToState extends State<_SendTo> {
  static const List<String> _teams = [
    'Design',
    'Engineering',
    'Finance',
    'Legal',
    'Marketing',
    'Operations',
    'Product',
    'Research',
    'Sales',
    'Support',
  ];

  bool _offline = false;

  // A server's answer, after a while; none while offline.
  Future<Iterable<String>> _search(String query) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (_offline) throw StateError('offline');
    final words = query.trim().toLowerCase();
    return _teams.where((team) => team.toLowerCase().contains(words));
  }

  @override
  Widget build(BuildContext context) {
    final words = DesignLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Send to'),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: DesignCombobox<String>(
                search: _search,
                debounceDuration: const Duration(milliseconds: 250),
                semanticLabel: 'Send to',
                fieldBuilder: (context, field) => ListenableBuilder(
                  listenable: field.focusNode,
                  builder: (context, _) => DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: field.focusNode.hasFocus ? _accent : _line,
                        width: field.focusNode.hasFocus ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: EditableText(
                        controller: field.controller,
                        focusNode: field.focusNode,
                        style: const TextStyle(fontSize: 16, color: _ink),
                        cursorColor: _accent,
                        backgroundCursorColor: _line,
                        onEditingComplete: field.submit,
                      ),
                    ),
                  ),
                ),
                optionBuilder: (context, team, states) => _MenuRow(
                  lit:
                      states.contains(WidgetState.focused) ||
                      states.contains(WidgetState.hovered),
                  enabled: true,
                  child: Text(team),
                ),
                surfaceBuilder: (context, list) => _Sheet(child: list),
                loadingBuilder: (context) => _MenuRow(
                  lit: false,
                  enabled: false,
                  child: Text(words.loadingLabel),
                ),
                errorBuilder: (context, failure) => Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // The list's own node says it, as it appears.
                    ExcludeSemantics(
                      child: _MenuRow(
                        lit: false,
                        enabled: false,
                        child: Text(words.searchFailedMessage),
                      ),
                    ),
                    DesignPressable(
                      onPressed: failure.retry,
                      semanticLabel: words.retryButtonLabel,
                      builder: (context, states, child) => _MenuRow(
                        lit:
                            failure.focused ||
                            states.contains(WidgetState.hovered),
                        enabled: true,
                        child: Text(
                          words.retryButtonLabel,
                          style: const TextStyle(color: _accent),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            DesignPressable(
              onPressed: () => setState(() => _offline = !_offline),
              semanticLabel: 'Offline',
              toggled: _offline,
              builder: (context, states, child) => _Box(
                selected: _offline,
                focused: states.contains(WidgetState.focused),
                child: const Text('Offline'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// A list's surface: white, a hairline round it; it takes the list's width.
class _Sheet extends StatelessWidget {
  const _Sheet({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: _paper,
      border: Border.all(color: _line),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Padding(padding: const EdgeInsets.all(4), child: child),
  );
}
