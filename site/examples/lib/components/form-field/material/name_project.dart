import 'package:material_ui/material_ui.dart';

class NameProject extends StatelessWidget {
  const NameProject({super.key});

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 400),
    child: TextFormField(
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (value) =>
          value?.trim().length == 1 ? 'Use at least two letters.' : null,
      decoration: const InputDecoration(
        labelText: 'Project name',
        helperText: 'For example, Field notes.',
        border: OutlineInputBorder(),
      ),
    ),
  );
}
