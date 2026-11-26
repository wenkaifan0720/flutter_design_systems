import 'package:material_ui/material_ui.dart';

class AddADay extends StatefulWidget {
  const AddADay({super.key});
  @override
  State<AddADay> createState() => _AddADayState();
}

class _AddADayState extends State<AddADay> {
  int days = 7;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      IconButton.filledTonal(
        tooltip: 'Add a day',
        icon: const Icon(Icons.add),
        onPressed: () => setState(() => days++),
      ),
      const SizedBox(height: 12),
      Text('Loan period: $days days'),
    ],
  );
}
