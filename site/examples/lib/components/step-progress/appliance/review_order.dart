import 'package:flutter/widgets.dart';
import 'package:appliance_ui/appliance_ui.dart';

class ReviewOrder extends StatefulWidget {
  const ReviewOrder({super.key});
  @override
  State<ReviewOrder> createState() => _ReviewOrderState();
}

class _ReviewOrderState extends State<ReviewOrder> {
  int step = 0;
  static const steps = ['Cart', 'Address', 'Review'];

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 520),
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ApplianceStepProgress(steps: steps, current: step),
          const SizedBox(height: 12),
          Text('Step ${step + 1}: ${steps[step]}'),
          const SizedBox(height: 12),
          ApplianceButton(
            step == steps.length - 1 ? 'Start again' : 'Continue',
            onPressed: () => setState(() => step = (step + 1) % steps.length),
          ),
        ],
      ),
    ),
  );
}
