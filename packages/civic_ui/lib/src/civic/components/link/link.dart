import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../internal/link_face.dart';
import '../../internal/link_target.dart';
import '../../theme.dart';

/// Words that go somewhere: underlined, in the action colour. A press
/// thickens the underline; a keyboard focus lays the words on the yellow
/// plate over the ink bar, in ink.
///
/// A link that goes somewhere names where, its [url]: a screen reader
/// hears a link, and on the web it is an anchor with that address, which
/// the browser can open in a new tab. One that only runs [onPressed]
/// (opens a fold, clears the filters) is heard as a button, keeping a
/// link's look.
///
/// [semanticLabel] says the whole of it to a screen reader where the words
/// lean on what is beside them: a summary row's "Change" is "Change your
/// name".
///
/// Reads [CivicStyle]'s foreground (the ink at rest, by state) and
/// textStyle: its `style:`, then [CivicThemeData.linkStyle]. The underline,
/// the press that thickens it and the focus plate are the look's.
///
/// ```dart
/// CivicLink(
///   url: Uri.parse('/guidance/permit-zones'),
///   onPressed: () => router.go('/guidance/permit-zones'),
///   child: const Text('Read the guidance on permit zones'),
/// )
/// ```
class CivicLink extends StatelessWidget {
  /// A link.
  const CivicLink({
    super.key,
    this.onPressed,
    required this.child,
    this.url,
    this.semanticLabel,
    this.textStyle,
    this.focusNode,
    this.autofocus = false,
    this.statesController,
    this.style,
  }) : _ink = false;

  /// A link in the words' own ink rather than the action colour: a back
  /// link, a link in a footer.
  const CivicLink.quiet({
    super.key,
    this.onPressed,
    required this.child,
    this.url,
    this.semanticLabel,
    this.textStyle,
    this.focusNode,
    this.autofocus = false,
    this.statesController,
    this.style,
  }) : _ink = true;

  final bool _ink;

  /// Called on a press. Null with a [url]: a press follows the url;
  /// null without one: the words are plain words.
  final VoidCallback? onPressed;

  /// Where it goes: a web address (`https://…`), or a route as the app's
  /// router names it (`Uri.parse('/permits')`), url_launcher's [Link]
  /// beneath. With one it is read as a link carrying that address, on the
  /// web an anchor the URL strategy spells (`#/permits` on hash routes);
  /// without one it only runs [onPressed], and is read as a button.
  ///
  /// A press runs [onPressed] when there is one, so the app goes there its
  /// own way and the browser does not follow the address too; without it,
  /// the press follows the url (a web address opens, a route is pushed to
  /// the app's router). On the web a press with the new-tab key held (Cmd
  /// on a Mac, Ctrl elsewhere), or a middle click, leaves the page where it
  /// is and opens the address in a new tab, as any link's does.
  final Uri? url;

  /// The words.
  final Widget child;

  /// What a screen reader says for it; null says [child]'s words.
  final String? semanticLabel;

  /// The words' style, over the body's; its colour, when it has one, is
  /// the link's ink at rest.
  final TextStyle? textStyle;

  /// {@macro civic.focusNode}
  final FocusNode? focusNode;

  /// {@macro civic.autofocus}
  final bool autofocus;

  /// {@macro civic.statesController}
  final WidgetStatesController? statesController;

  /// Overrides for this link's look.
  final CivicStyle? style;

  @override
  Widget build(BuildContext context) {
    // The focus plate hugs the words, as a public service's link focus
    // does, however wide the column it stands in.
    return Align(
      alignment: AlignmentDirectional.centerStart,
      widthFactor: 1,
      heightFactor: 1,
      child: _link(context),
    );
  }

  Widget _link(BuildContext context) {
    final address = url;
    if (address == null) {
      // A link that only runs a callback is a button to a screen reader:
      // on the web an anchor with no address is read as plain words.
      return _pressable(onPressed, link: false);
    }
    return CivicLinkTarget(
      url: address,
      onPressed: onPressed,
      builder: (context, press) => _pressable(press, link: true),
    );
  }

  Widget _pressable(VoidCallback? onPressed, {required bool link}) {
    return DesignTapTarget(
      alignment: AlignmentDirectional.centerStart,
      child: DesignPressable(
        onPressed: onPressed,
        focusNode: focusNode,
        autofocus: autofocus,
        statesController: statesController,
        button: !link && onPressed != null,
        link: link,
        semanticLabel: semanticLabel,
        excludeSemantics: semanticLabel != null,
        mouseCursor: onPressed == null
            ? SystemMouseCursors.basic
            : SystemMouseCursors.click,
        builder: (context, states, _) => CivicLinkFace(
          states: states,
          quiet: _ink,
          textStyle: textStyle,
          style: style,
          child: child,
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(FlagProperty('quiet', value: _ink, ifTrue: 'quiet'))
      ..add(ObjectFlagProperty<VoidCallback>.has('onPressed', onPressed))
      ..add(DiagnosticsProperty<Uri>('url', url, defaultValue: null))
      ..add(StringProperty('semanticLabel', semanticLabel, defaultValue: null))
      ..add(
        DiagnosticsProperty<TextStyle>(
          'textStyle',
          textStyle,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'))
      ..add(
        DiagnosticsProperty<WidgetStatesController>(
          'statesController',
          statesController,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<CivicStyle>('style', style, defaultValue: null),
      );
  }
}

/// The way back, above a page's heading: a chevron and "Back" (in the
/// reader's language), in ink, underlined. The chevron points the way back
/// in either reading direction.
///
/// ```dart
/// CivicBackLink(onPressed: () => Navigator.of(context).maybePop())
/// ```
class CivicBackLink extends StatelessWidget {
  /// A back link.
  const CivicBackLink({
    super.key,
    required this.onPressed,
    this.label,
    this.focusNode,
  });

  /// Called on a press.
  final VoidCallback? onPressed;

  /// The words; null says "Back" in the reader's language.
  final String? label;

  /// {@macro civic.focusNode}
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final words = label ?? DesignLocalizations.of(context).backButtonTooltip;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return CivicLink.quiet(
      onPressed: onPressed,
      focusNode: focusNode,
      textStyle: context.civicText.bodySmall.copyWith(color: t.textPrimary),
      semanticLabel: words,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: CivicSpacing.s4,
        children: [
          Transform.flip(
            flipX: rtl,
            child: const Icon(
              LucideIcons.chevronLeft,
              size: 18,
              applyTextScaling: true,
            ),
          ),
          Text(words),
        ],
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(ObjectFlagProperty<VoidCallback>.has('onPressed', onPressed))
      ..add(StringProperty('label', label, defaultValue: null))
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      );
  }
}
