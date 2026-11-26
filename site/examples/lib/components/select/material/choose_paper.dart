import 'package:material_ui/material_ui.dart';

class ChoosePaper extends StatefulWidget {
  const ChoosePaper({super.key});
  @override
  State<ChoosePaper> createState() => _ChoosePaperState();
}

class _ChoosePaperState extends State<ChoosePaper> {
  String paper = 'A4';

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      DropdownMenu<String>(
        label: const Text('Paper size'),
        initialSelection: paper,
        onSelected: (value) {
          if (value != null) setState(() => paper = value);
        },
        dropdownMenuEntries: const [
          DropdownMenuEntry(value: 'A4', label: 'A4'),
          DropdownMenuEntry(value: 'A5', label: 'A5'),
          DropdownMenuEntry(value: 'Letter', label: 'Letter'),
        ],
      ),
      const SizedBox(height: 12),
      Text('Print on $paper'),
    ],
  );
}
