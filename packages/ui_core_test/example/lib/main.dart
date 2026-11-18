// A settings card under a DesignKeylineSheet. The switch in the third row
// ends 6 px before the trailing keyline, which the sheet marks in red.
import 'package:flutter/widgets.dart';
import 'package:ui_core_test/ui_core_test.dart';
import 'package:ui_core/ui_core.dart';

void main() => runApp(const ReviewApp());

const Color _ink = Color(0xFF1F2328);
const Color _paper = Color(0xFFFFFFFF);
const Color _line = Color(0xFFD0D7DE);
const Color _accent = Color(0xFF0969DA);

/// A bare [WidgetsApp] showing one review page.
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
        child: Center(
          child: SizedBox(
            width: 360,
            child: DesignKeylineSheet(
              check: DesignKeylineCheck(look: 'Example'),
              child: SettingsCard(),
            ),
          ),
        ),
      ),
    ),
  );
}

/// A card of three settings rows, each a title at the leading keyline and a
/// switch at the trailing one.
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
      child: DesignKeylineRegion(
        label: 'Settings',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Row('Notifications', on: true),
            _Row('Sounds', on: false),
            _Row('Vibrate', on: true, inset: 6),
          ],
        ),
      ),
    ),
  );
}

class _Row extends StatelessWidget {
  const _Row(this.title, {required this.on, this.inset = 0});

  final String title;
  final bool on;
  final double inset;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 48,
    child: Row(
      children: [
        Expanded(child: Text(title)),
        Padding(
          padding: EdgeInsetsDirectional.only(end: inset),
          child: _Switch(on: on),
        ),
      ],
    ),
  );
}

class _Switch extends StatelessWidget {
  const _Switch({required this.on});

  final bool on;

  @override
  Widget build(BuildContext context) => Semantics(
    toggled: on,
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
              decoration: BoxDecoration(color: _paper, shape: BoxShape.circle),
              child: SizedBox.square(dimension: 18),
            ),
          ),
        ),
      ),
    ),
  );
}
