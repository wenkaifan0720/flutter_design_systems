import 'package:flutter/widgets.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;

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
      MinimalIconButton(
        CupertinoIcons.plus,
        semanticLabel: 'Add a day',
        onPressed: () => setState(() => days++),
      ),
      const SizedBox(height: 12),
      Text('Loan period: $days days'),
    ],
  );
}
