import 'package:flutter/widgets.dart';
import 'package:terminal_ui/terminal_ui.dart';

class ReviewOrder extends StatefulWidget {
  const ReviewOrder({super.key});
  @override
  State<ReviewOrder> createState() => _ReviewOrderState();
}

class _ReviewOrderState extends State<ReviewOrder> {
  int step = 0;
  static const labels = ['Cart', 'Address', 'Review'];
  TermStepState stateFor(int index) {
    if (index < step) return TermStepState.done;
    return index == step ? TermStepState.current : TermStepState.upcoming;
  }

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 520),
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TermSteps(
            steps: [
              for (var i = 0; i < labels.length; i++)
                (label: labels[i], state: stateFor(i)),
            ],
          ),
          const SizedBox(height: 12),
          Text('Step ${step + 1}: ${labels[step]}'),
          const SizedBox(height: 12),
          TermButton(
            label: step == labels.length - 1 ? 'Start again' : 'Continue',
            onPressed: () => setState(() => step = (step + 1) % labels.length),
          ),
        ],
      ),
    ),
  );
}
