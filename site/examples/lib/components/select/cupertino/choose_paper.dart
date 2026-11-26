import 'package:cupertino_ui/cupertino_ui.dart';

class ChoosePaper extends StatefulWidget {
  const ChoosePaper({super.key});
  @override
  State<ChoosePaper> createState() => _ChoosePaperState();
}

class _ChoosePaperState extends State<ChoosePaper> {
  static const papers = ['A4', 'A5', 'Letter'];
  String paper = 'A4';

  void showPicker(Widget picker) => showCupertinoModalPopup<void>(
    context: context,
    builder: (context) => Container(
      height: 216,
      padding: const EdgeInsets.only(top: 6),
      color: CupertinoColors.systemBackground.resolveFrom(context),
      child: SafeArea(top: false, child: picker),
    ),
  );

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Paper size'),
          CupertinoButton(
            onPressed: () => showPicker(
              CupertinoPicker(
                itemExtent: 32,
                scrollController: FixedExtentScrollController(
                  initialItem: papers.indexOf(paper),
                ),
                onSelectedItemChanged: (index) =>
                    setState(() => paper = papers[index]),
                children: [
                  for (final size in papers) Center(child: Text(size)),
                ],
              ),
            ),
            child: Text(paper),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Text('Print on $paper'),
    ],
  );
}
