import 'package:cupertino_ui/cupertino_ui.dart';

class FindTitle extends StatefulWidget {
  const FindTitle({super.key});
  @override
  State<FindTitle> createState() => _FindTitleState();
}

class _FindTitleState extends State<FindTitle> {
  static const titles = ['Field notes', 'Field guide', 'Travel diary'];
  String query = '';

  Iterable<String> get matches =>
      titles.where((title) => title.toLowerCase().contains(query));

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 360),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CupertinoSearchTextField(
          placeholder: 'Search titles',
          onChanged: (value) =>
              setState(() => query = value.trim().toLowerCase()),
        ),
        const SizedBox(height: 12),
        Text(
          matches.isEmpty ? 'No matching titles' : matches.join('\n'),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}
