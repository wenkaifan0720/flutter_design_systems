// terminal_ui's example: the Overview first (the look at its best, what it
// is, the example app's screens and what the package holds), then every
// part's page from its index. The example app, slipway, is a small team's
// deploy console; open it from the Overview.
import 'package:flutter/material.dart';
import 'package:terminal_ui/terminal_ui.dart';

import 'gallery_pages.dart';
import 'kit_gallery/kit.dart';
import 'kit_gallery/overview.dart';
import 'kit_gallery/slipway.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // The faces before the first frame: the grid never starts in a fallback.
  await termLoadFonts();
  runApp(const TerminalExample());
}

/// The screens the Overview opens as the example app, not as parts.
const _screens = {
  'overview',
  'home',
  'runs',
  'run-detail',
  'deploy',
  'settings',
};

/// The example: the Overview, and the parts' pages it opens.
class TerminalExample extends StatefulWidget {
  /// The example, at night.
  const TerminalExample({super.key});

  @override
  State<TerminalExample> createState() => _TerminalExampleState();
}

class _TerminalExampleState extends State<TerminalExample> {
  // A link may open a page straight away: ?page=runs&theme=paper&dir=rtl,
  // one of slipway's screens (?place=diff) and a text scale (&scale=2).
  static final _query = Uri.base.queryParameters;
  static final _place = SlipwayPlace.values
      .where((p) => p.name == _query['place'])
      .firstOrNull;
  var _brightness = _query['theme'] == 'paper'
      ? Brightness.light
      : Brightness.dark;
  String? _part = galleryPages.any((p) => p.id == _query['page'])
      ? _query['page']
      : null;

  @override
  void initState() {
    super.initState();
    if (_query['dir'] == 'rtl') kitShownDirection = TextDirection.rtl;
    kitTextScale = double.tryParse(_query['scale'] ?? '') ?? 1;
  }

  @override
  Widget build(BuildContext context) {
    if (_place case final place?) {
      return slipwayApp(_brightness, place: place);
    }
    final part = _part;
    if (part != null) {
      final page = galleryPages.firstWhere((p) => p.id == part);
      kitOnBack = () => setState(() => _part = null);
      return KeyedSubtree(
        key: ValueKey('$part/${_brightness.name}'),
        child: page.build(_brightness),
      );
    }
    kitOnBack = null;
    return kitApp(
      brightness: _brightness,
      home: OverviewPage(
        onBrightness: () => setState(
          () => _brightness = _brightness == Brightness.dark
              ? Brightness.light
              : Brightness.dark,
        ),
        parts: [
          for (final p in galleryPages)
            if (!_screens.contains(p.id)) (id: p.id, title: p.title),
        ],
        onOpenPart: (id) => setState(() => _part = id),
      ),
    );
  }
}
