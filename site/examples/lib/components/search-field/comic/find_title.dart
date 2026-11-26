import 'package:flutter/widgets.dart';
import 'package:comic_ui/comic_ui.dart';

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

  void filter(String value) =>
      setState(() => query = value.trim().toLowerCase());
  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 360),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ComicSearchField(
          name: 'Find a title',
          hintText: 'Search titles',
          onChanged: filter,
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
