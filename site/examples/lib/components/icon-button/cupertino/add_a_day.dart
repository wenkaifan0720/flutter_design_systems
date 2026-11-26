import 'package:cupertino_ui/cupertino_ui.dart';

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
      CupertinoButton(
        onPressed: () => setState(() => days++),
        child: const Icon(
          CupertinoIcons.add_circled,
          size: 32,
          semanticLabel: 'Add a day',
        ),
      ),
      const SizedBox(height: 12),
      Text('Loan period: $days days'),
    ],
  );
}
