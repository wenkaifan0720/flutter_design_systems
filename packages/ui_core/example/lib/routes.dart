// The routes, plainly painted: an alert, a bottom sheet, tabs, swipe rows and a shell. Every pixel here is
// the example's own; the routes give them their spring, focus, the keys,
// Android's back and what a screen reader hears. No Material, no Cupertino.
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

const Color _ink = Color(0xFF1F2328);
const Color _paper = Color(0xFFFFFFFF);
const Color _line = Color(0xFFD0D7DE);
const Color _accent = Color(0xFF0969DA);
const Color _wrong = Color(0xFFCF222E);

/// A page that opens each route.
class RoutesPage extends StatefulWidget {
  /// The page.
  const RoutesPage({super.key});

  @override
  State<RoutesPage> createState() => _RoutesPageState();
}

class _RoutesPageState extends State<RoutesPage>
    with SingleTickerProviderStateMixin {
  String _said = '';
  final List<String> _mail = [for (var i = 1; i <= 12; i++) 'Message $i'];
  final RawSwipeActionsController _first = RawSwipeActionsController();
  late final RawTabController _tabs = RawTabController(length: 2, vsync: this);

  @override
  void dispose() {
    _first.dispose();
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _deleteDraft() async {
    final delete = await Navigator.of(context).push(
      RawModalDialogRoute<bool>(
        isAlert: true,
        builder: (context, details) => _Pop(
          animation: details.animation,
          child: RawAlertDialog(
            title: 'Delete the draft?',
            content: const Text('It cannot be brought back.'),
            actions: [
              RawDialogAction(
                label: 'Cancel',
                onPressed: () => Navigator.of(context).pop(false),
              ),
              RawDialogAction(
                label: 'Delete',
                isDestructiveAction: true,
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
            titleBuilder: (context, title) => Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            frameBuilder: (context, details, child) => _Frame(child: child),
            actionsBuilder: (context, details, child) =>
                Padding(padding: const EdgeInsets.only(top: 20), child: child),
            actionBuilder: (context, action, details) =>
                _Action(action: action, details: details),
          ),
        ),
      ),
    );
    if (!mounted) return;
    setState(() => _said = delete == true ? 'Deleted' : 'Kept');
  }

  void _showRecent() => Navigator.of(context).push(
    RawBottomSheetRoute<void>(
      snapSizes: const [0.5, 1],
      builder: (context, details) => AnimatedBuilder(
        animation: details.size,
        // Its top corners square as it reaches the top.
        builder: (context, child) => Container(
          decoration: BoxDecoration(
            color: _paper,
            border: Border.all(color: _line),
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(16 * (1 - details.size.value) * 2),
            ),
          ),
          child: child,
        ),
        child: Column(
          children: [
            RawBottomSheetDragHandle(
              builder: (context, states) => Container(
                margin: const EdgeInsets.symmetric(vertical: 20),
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: states.contains(WidgetState.focused) ? _accent : _line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                controller: details.scrollController,
                children: [
                  for (var i = 1; i <= 40; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      child: Text('Report $i'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: _paper,
    child: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Routes',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Text(_said),
            const SizedBox(height: 12),
            // Two tabs, an underline sliding between them as the pages swipe.
            RawTabBar(
              controller: _tabs,
              tabs: const [
                RawTab(label: 'Routes'),
                RawTab(label: 'Mail'),
              ],
              tabBuilder: (context, tab, details) => Container(
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: details.states.contains(WidgetState.focused)
                      ? Border.all(color: _accent, width: 2)
                      : null,
                ),
                child: Text(
                  tab.label,
                  style: TextStyle(
                    color: Color.lerp(_ink, _accent, details.selection),
                  ),
                ),
              ),
              indicatorBuilder: (context, details) => const Align(
                alignment: Alignment.bottomCenter,
                child: SizedBox(
                  height: 2,
                  width: double.infinity,
                  child: ColoredBox(color: _accent),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: RawTabBarView(
                controller: _tabs,
                children: [_routes(), _mailbox()],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _routes() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _Button(label: 'Delete the draft…', onPressed: _deleteDraft),
      const SizedBox(height: 12),
      _Button(label: 'Recent reports', onPressed: _showRecent),
      const SizedBox(height: 12),
      _Button(
        label: 'Mail app',
        onPressed: () => Navigator.of(context).push(
          PageRouteBuilder<void>(
            pageBuilder: (context, _, _) => const _MailApp(),
          ),
        ),
      ),
    ],
  );

  // Rows in one list open one at a time; scrolling closes them.
  Widget _mailbox() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _Button(
        label: 'Show the first row\'s actions',
        onPressed: _first.openEndActions,
      ),
      const SizedBox(height: 12),
      Expanded(
        child: ListView(
          children: [
            for (final m in _mail)
              RawSwipeActions(
                key: ValueKey(m),
                controller: m == _mail.first ? _first : null,
                startActions: [
                  RawSwipeAction(
                    label: 'Pin',
                    onPressed: () => setState(() => _said = 'Pinned $m'),
                  ),
                ],
                endActions: [
                  RawSwipeAction(
                    label: 'Delete',
                    destructive: true,
                    onPressed: () => setState(() => _mail.remove(m)),
                  ),
                ],
                actionBuilder: (context, action, details) => ColoredBox(
                  color: action.destructive ? _wrong : _accent,
                  child: Center(
                    child: Text(
                      action.label,
                      style: const TextStyle(color: _paper),
                    ),
                  ),
                ),
                child: Container(
                  height: 56,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: const BoxDecoration(
                    color: _paper,
                    border: Border(bottom: BorderSide(color: _line)),
                  ),
                  child: Text(m),
                ),
              ),
          ],
        ),
      ),
    ],
  );
}

// The dialog grows from 96% as it opens, on the route's own spring.
class _Pop extends StatelessWidget {
  const _Pop({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: animation,
    builder: (context, child) => Opacity(
      opacity: animation.value.clamp(0.0, 1.0),
      child: Transform.scale(
        scale: 0.96 + 0.04 * animation.value,
        child: child,
      ),
    ),
    child: child,
  );
}

class _Frame extends StatelessWidget {
  const _Frame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: _paper,
      border: Border.all(color: _line),
      borderRadius: BorderRadius.circular(12),
    ),
    child: DefaultTextStyle.merge(
      style: const TextStyle(fontSize: 16, color: _ink),
      child: child,
    ),
  );
}

class _Action extends StatelessWidget {
  const _Action({required this.action, required this.details});

  final RawDialogAction action;
  final RawDialogActionDetails details;

  @override
  Widget build(BuildContext context) {
    final focused = details.states.contains(WidgetState.focused);
    final colour = action.isDestructiveAction ? _wrong : _accent;
    return Container(
      constraints: const BoxConstraints(minWidth: 64, minHeight: 44),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border.all(
          color: focused ? colour : _line,
          width: focused ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(action.label, style: TextStyle(color: colour)),
    );
  }
}

class _Button extends StatelessWidget {
  const _Button({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => RawButton(
    onPressed: onPressed,
    semanticLabel: label,
    builder: (context, states, _) => Container(
      constraints: const BoxConstraints(minHeight: 44),
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border.all(
          color: states.contains(WidgetState.focused) ? _accent : _line,
          width: states.contains(WidgetState.focused) ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label),
    ),
  );
}

// A mail app in a shell: a bar, a rail or a sidebar by the window; each
// destination keeps its own stack; the inbox a list and its detail.
class _MailApp extends StatefulWidget {
  const _MailApp();

  @override
  State<_MailApp> createState() => _MailAppState();
}

class _MailAppState extends State<_MailApp> {
  int _destination = 0;
  String? _open;

  static const _destinations = [
    RawNavigationDestination(label: 'Inbox', icon: IconData(0xe156)),
    RawNavigationDestination(label: 'Settings', icon: IconData(0xe57f)),
  ];

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: _paper,
    child: RawAdaptiveShell.branches(
      destinations: _destinations,
      selectedIndex: _destination,
      onDestinationSelected: (i) => setState(() => _destination = i),
      destinationBuilder: (context, destination, details) {
        final selected = details.states.contains(WidgetState.selected);
        final focused = details.states.contains(WidgetState.focused);
        return Container(
          constraints: const BoxConstraints(minHeight: 56, minWidth: 72),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: focused ? Border.all(color: _accent, width: 2) : null,
          ),
          child: Text(
            destination.label,
            style: TextStyle(color: selected ? _accent : _ink),
          ),
        );
      },
      navigationBuilder: (context, details) => DecoratedBox(
        decoration: const BoxDecoration(
          border: Border.fromBorderSide(BorderSide(color: _line)),
        ),
        child: SafeArea(
          child: switch (details.mode) {
            RawNavigationMode.bar => Row(
              children: [
                for (final d in details.destinations) Expanded(child: d),
              ],
            ),
            RawNavigationMode.rail => SizedBox(
              width: 88,
              child: Column(children: details.destinations),
            ),
            RawNavigationMode.sidebar => SizedBox(
              width: 240,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: details.destinations,
              ),
            ),
          },
        ),
      ),
      branches: [
        (context) => RawListDetail<String>(
          selectedItem: _open,
          onSelectedItemChanged: (item) => setState(() => _open = item),
          listBuilder: (context) => ListView(
            children: [
              for (var i = 1; i <= 20; i++)
                _Button(
                  label: 'Message $i',
                  onPressed: () => setState(() => _open = 'Message $i'),
                ),
            ],
          ),
          detailBuilder: (context, item) => ColoredBox(
            color: _paper,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('$item, in full'),
            ),
          ),
          emptyDetailBuilder: (context) =>
              const Center(child: Text('No message chosen')),
          detailRouteBuilder: (builder) => PageRouteBuilder<void>(
            pageBuilder: (context, _, _) => builder(context),
          ),
        ),
        (context) => const Center(child: Text('Settings')),
      ],
    ),
  );
}
