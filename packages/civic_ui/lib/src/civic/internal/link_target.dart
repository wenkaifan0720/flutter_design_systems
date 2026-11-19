import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:url_launcher/link.dart';
import 'package:url_launcher/url_launcher.dart';

import 'link_address.dart';

/// A part that goes to [url], url_launcher's [Link] beneath; [builder]
/// draws it, given the press for its pressable. The address joins the
/// pressable's own node, spelt as the browser opens it: one link, with its
/// href. On the web, Link draws the anchor and keeps the browser from
/// following it when the press is the app's.
///
/// The press runs [onPressed], or follows [url] without one (a web address
/// opens, a route is pushed to the app's router). On the web, with the
/// new-tab key held (Cmd on Apple's platforms, Ctrl elsewhere), it opens
/// the address in a new tab instead, here rather than by the browser: a
/// press a screen reader makes reaches the app after url_launcher has
/// already kept the browser from following the anchor.
class CivicLinkTarget extends StatelessWidget {
  /// A link to [url].
  const CivicLinkTarget({
    super.key,
    required this.url,
    required this.onPressed,
    required this.builder,
  });

  /// Where it goes: a web address, or a route as the app's router names it.
  final Uri url;

  /// What a press does; null follows [url].
  final VoidCallback? onPressed;

  /// The part, given its press.
  final Widget Function(BuildContext context, VoidCallback? press) builder;

  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: Semantics(
      link: true,
      linkUrl: civicLinkAddress(url),
      child: Link(
        uri: url,
        builder: (context, follow) => builder(context, _press(follow)),
      ),
    ),
  );

  VoidCallback? _press(FollowLink? follow) {
    final go = onPressed;
    if (follow == null) return go;
    return () {
      if (kIsWeb && _newTabHeld()) {
        unawaited(
          launchUrl(
            Uri.base.resolveUri(civicLinkAddress(url)),
            webOnlyWindowName: '_blank',
          ),
        );
      } else if (go != null) {
        go();
      } else {
        unawaited(follow());
      }
    };
  }

  /// Whether the key that opens a link in a new tab is held: Cmd on Apple's
  /// platforms, Ctrl elsewhere.
  static bool _newTabHeld() {
    final keys = HardwareKeyboard.instance;
    return switch (defaultTargetPlatform) {
      TargetPlatform.macOS || TargetPlatform.iOS => keys.isMetaPressed,
      _ => keys.isControlPressed,
    };
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<Uri>('url', url))
      ..add(ObjectFlagProperty<VoidCallback>.has('onPressed', onPressed));
  }
}
