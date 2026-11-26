import 'package:flutter/widgets.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

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
      child: RetroDesktopFormField(
        labelText: 'Project name',
        helperText: 'For example, Field notes.',
        errorText: tooShort ? 'Use at least two letters.' : null,
        child: RetroDesktopTextField(
          onChanged: (value) =>
              setState(() => tooShort = value.trim().length == 1),
        ),
      ),
    ),
  );
}
