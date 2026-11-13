// A plain look on four behaviours: a toggle group, a labelled field, a
// button and toasts. Every pixel here is the example's own; the behaviours
// give it focus, the keyboard, the states and what a screen reader hears.
// No Material, no Cupertino.
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

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
                      border: Border.all(
                        color: parts.hasError ? _wrong : _line,
                        width: parts.hasError ? 2 : 1,
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
                      color: parts.hasError ? _wrong : const Color(0xFF59636E),
                    ),
                    child: parts.error ?? parts.helper ?? const SizedBox(),
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
              onSelectionChanged: (next) => setState(() => _period = next),
              semanticLabel: 'Period',
              itemBuilder: (context, value, states) => _Box(
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
          ],
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
