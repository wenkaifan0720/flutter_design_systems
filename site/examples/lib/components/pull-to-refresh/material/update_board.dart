import 'package:material_ui/material_ui.dart';

class UpdateBoard extends StatefulWidget {
  const UpdateBoard({super.key});
  @override
  State<UpdateBoard> createState() => _UpdateBoardState();
}

class _UpdateBoardState extends State<UpdateBoard> {
  final indicator = GlobalKey<RefreshIndicatorState>();
  int issue = 1;

  Future<void> refresh() async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (mounted) setState(() => issue++);
  }

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 440),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 90,
          child: RefreshIndicator(
            key: indicator,
            onRefresh: refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [ListTile(title: Text('Issue $issue'))],
            ),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => indicator.currentState?.show(),
          child: const Text('Refresh'),
        ),
      ],
    ),
  );
}
