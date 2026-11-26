import 'package:cupertino_ui/cupertino_ui.dart';

class NameProject extends StatelessWidget {
  const NameProject({super.key});

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 400),
    child: SingleChildScrollView(
      child: CupertinoFormSection.insetGrouped(
        header: const Text('Project'),
        footer: const Text('For example, Field notes.'),
        children: [
          CupertinoTextFormFieldRow(
            prefix: const Text('Name'),
            placeholder: 'Project name',
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: (value) =>
                value?.trim().length == 1 ? 'Use at least two letters.' : null,
          ),
        ],
      ),
    ),
  );
}
