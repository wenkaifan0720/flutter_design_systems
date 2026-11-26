import 'package:flutter/widgets.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';

class NameProject extends StatefulWidget {
  const NameProject({super.key});
  @override
  State<NameProject> createState() => _NameProjectState();
}

class _NameProjectState extends State<NameProject> {
  bool tooShort = false;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 400),
    child: SingleChildScrollView(
      child: Fluent2FormField(
        labelText: 'Project name',
        helperText: 'For example, Field notes.',
        validationMessage: tooShort ? 'Use at least two letters.' : null,
        validationState: tooShort ? Fluent2ValidationState.error : null,
        child: Fluent2TextField(
          onChanged: (value) =>
              setState(() => tooShort = value.trim().length == 1),
        ),
      ),
    ),
  );
}
