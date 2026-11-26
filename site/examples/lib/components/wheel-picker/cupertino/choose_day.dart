import 'package:cupertino_ui/cupertino_ui.dart';

class ChooseDay extends StatefulWidget {
  const ChooseDay({super.key});
  @override
  State<ChooseDay> createState() => _ChooseDayState();
}

class _ChooseDayState extends State<ChooseDay> {
  int day = 12;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 280,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 150,
          child: CupertinoPicker(
            itemExtent: 32,
            scrollController: FixedExtentScrollController(initialItem: day - 1),
            onSelectedItemChanged: (index) => setState(() => day = index + 1),
            children: [
              for (var date = 1; date <= 30; date++)
                Center(child: Text('November $date')),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text('November $day'),
      ],
    ),
  );
}
