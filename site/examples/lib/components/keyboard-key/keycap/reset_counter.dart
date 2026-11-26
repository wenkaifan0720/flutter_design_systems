import 'package:flutter/widgets.dart';
import 'package:keycap_ui/keycap_ui.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;

class ResetCounter extends StatefulWidget {
  const ResetCounter({super.key});

  @override
  State<ResetCounter> createState() => _ResetCounterState();
}

class _ResetCounterState extends State<ResetCounter> {
  static const reset = SingleActivator(LogicalKeyboardKey.escape);
  int count = 0;

  @override
  Widget build(BuildContext context) => CallbackShortcuts(
    bindings: {reset: () => setState(() => count = 0)},
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        KeycapButton(
          onPressed: () => setState(() => count++),
          child: const Text('Count one'),
        ),
        const SizedBox(height: 12),
        const Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          children: [KeycapKbd.shortcut(reset), Text('Reset count')],
        ),
        const SizedBox(height: 12),
        Text('Count: $count'),
      ],
    ),
  );
}
