import 'package:flutter/widgets.dart';
import 'package:clay_ui/clay_ui.dart';
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
        ClayButton('Count one', onPressed: () => setState(() => count++)),
        const SizedBox(height: 12),
        const Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          children: [ClayKbd('Esc'), Text('Reset count')],
        ),
        const SizedBox(height: 12),
        Text('Count: $count'),
      ],
    ),
  );
}
