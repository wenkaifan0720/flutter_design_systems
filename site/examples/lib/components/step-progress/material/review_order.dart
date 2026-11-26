import 'package:material_ui/material_ui.dart';

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
    child: SizedBox(
      height: 220,
      child: Stepper(
        type: StepperType.horizontal,
        currentStep: step,
        onStepContinue: () => setState(() => step = (step + 1) % steps.length),
        controlsBuilder: (context, details) => Align(
          alignment: AlignmentDirectional.centerStart,
          child: FilledButton(
            onPressed: details.onStepContinue,
            child: Text(step == steps.length - 1 ? 'Start again' : 'Continue'),
          ),
        ),
        steps: [
          for (final (index, name) in steps.indexed)
            Step(
              title: Text(name),
              content: Text('Step ${index + 1}: $name'),
              isActive: index <= step,
              state: index < step ? StepState.complete : StepState.indexed,
            ),
        ],
      ),
    ),
  );
}
