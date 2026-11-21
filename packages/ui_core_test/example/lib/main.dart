// A settings card checked as a look's tests check their screens: the switch
// in the third row takes a 24 px tap, which the tap target check names. The
// checks run here in the app, the screen's semantics turned on to read; a
// look's tests run them under a tester.
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core_test/ui_core_test.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // The tap target check reads the semantics tree, which an app builds on
  // request (a test asks with `tester.ensureSemantics()`).
  _semantics = SemanticsBinding.instance.ensureSemantics();
  runApp(const ReviewApp());
}

// Held for the app's life: the tree is built while a handle is open.
// ignore: unused_element
SemanticsHandle? _semantics;

const Color _ink = Color(0xFF1F2328);
const Color _paper = Color(0xFFFFFFFF);
const Color _line = Color(0xFFD0D7DE);
const Color _accent = Color(0xFF0969DA);
const Color _alert = Color(0xFFCF222E);

/// A bare [WidgetsApp] showing one checked page.
class ReviewApp extends StatelessWidget {
  /// The example app.
  const ReviewApp({super.key});

  @override
  Widget build(BuildContext context) => WidgetsApp(
    color: _accent,
    title: 'ui_core_test example',
    pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) =>
        PageRouteBuilder<T>(
          settings: settings,
          pageBuilder: (context, _, _) => builder(context),
        ),
    home: const DefaultTextStyle(
      style: TextStyle(fontSize: 16, color: _ink),
      child: ColoredBox(
        color: Color(0xFFF6F8FA),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Center(child: SizedBox(width: 360, child: CheckedPage())),
        ),
      ),
    ),
  );
}

/// The settings card, and under it what the checks found on it.
class CheckedPage extends StatefulWidget {
  /// The page.
  const CheckedPage({super.key});

  @override
  State<CheckedPage> createState() => _CheckedPageState();
}

class _CheckedPageState extends State<CheckedPage> {
  final GlobalKey _card = GlobalKey();
  List<String>? _problems;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  void _check() {
    final card = _card.currentContext;
    if (!mounted || card == null) return;
    final reports = [
      const DesignTapTargetCheck(look: 'Example').check(card),
      const DesignWordBreakCheck(look: 'Example').check(card),
      const DesignClipCheck(look: 'Example').check(card),
    ];
    setState(() => _problems = [for (final r in reports) ...r.problems]);
  }

  @override
  Widget build(BuildContext context) {
    final problems = _problems;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsCard(key: _card),
        const SizedBox(height: 16),
        if (problems == null)
          const Text('Checking…')
        else if (problems.isEmpty)
          const Text('No problems found.')
        else
          for (final problem in problems)
            Text(problem, style: const TextStyle(color: _alert, fontSize: 14)),
      ],
    );
  }
}

/// A card of three settings rows, each a title and a switch.
class SettingsCard extends StatelessWidget {
  /// The card.
  const SettingsCard({super.key});

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: _paper,
      border: Border.all(color: _line),
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Row('Notifications', on: true),
          _Row('Sounds', on: false),
          _Row('Vibrate', on: true, tap: 24),
        ],
      ),
    ),
  );
}

class _Row extends StatelessWidget {
  const _Row(this.title, {required this.on, this.tap = 48});

  final String title;
  final bool on;
  // The height of the switch's tap target.
  final double tap;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 48,
    child: Row(
      children: [
        Expanded(child: Text(title)),
        _Switch(label: title, on: on, tap: tap),
      ],
    ),
  );
}

class _Switch extends StatelessWidget {
  const _Switch({required this.label, required this.on, required this.tap});

  final String label;
  final bool on;
  final double tap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: () {},
    child: Semantics(
      label: label,
      toggled: on,
      child: SizedBox(
        width: 48,
        height: tap,
        child: Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: on ? _accent : _line,
              borderRadius: BorderRadius.circular(12),
            ),
            child: SizedBox(
              width: 44,
              height: 24,
              child: Align(
                alignment: on
                    ? AlignmentDirectional.centerEnd
                    : AlignmentDirectional.centerStart,
                child: const Padding(
                  padding: EdgeInsets.all(3),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: _paper,
                      shape: BoxShape.circle,
                    ),
                    child: SizedBox.square(dimension: 18),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
