import 'package:cupertino_ui/cupertino_ui.dart';

class UpdateBoard extends StatefulWidget {
  const UpdateBoard({super.key});
  @override
  State<UpdateBoard> createState() => _UpdateBoardState();
}

class _UpdateBoardState extends State<UpdateBoard> {
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
          height: 110,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              CupertinoSliverRefreshControl(onRefresh: refresh),
              SliverToBoxAdapter(
                child: CupertinoListTile(title: Text('Issue $issue')),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        CupertinoButton(onPressed: refresh, child: const Text('Refresh')),
      ],
    ),
  );
}
