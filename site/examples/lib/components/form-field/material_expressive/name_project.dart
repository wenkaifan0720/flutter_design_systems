import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

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
      child: ExpressiveFormField(
        labelText: 'Project name',
        helperText: 'For example, Field notes.',
        errorText: tooShort ? 'Use at least two letters.' : null,
        child: ExpressiveTextField(
          onChanged: (value) =>
              setState(() => tooShort = value.trim().length == 1),
        ),
      ),
    ),
  );
}
