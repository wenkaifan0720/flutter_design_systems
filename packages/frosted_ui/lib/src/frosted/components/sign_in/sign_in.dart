import 'package:flutter/widgets.dart';

import '../../glyphs.dart';

import '../../chrome_metrics.dart';
import '../../internal/face.dart';
import '../../internal/provider_marks.dart';
import '../../theme.dart';
import '../../internal/measure.dart';
import '../../internal/own_size.dart';
import '../button/button.dart';
import '../pressable/pressable.dart';
import '../../localizations.dart';
import '../../internal/dim.dart';
import '../../internal/cap.dart';

/// One way in: "Continue with" and the provider as a wide pill 48 tall, the
/// provider's mark 18 before the words. Apple's and Google's keep their
/// brands' own faces whatever the page (Apple's black button on the day,
/// its white on the night; Google's white with its grey outline on the day,
/// its near-black on the night) with their marks drawn in; email, and any
/// provider without a face of its own, wears the system's: the high glass,
/// or with [emphasis] the ink of the page's one act. [label] replaces the
/// words. While [busy] the face stays, takes no press and says "Working…",
/// announced as it changes. DERIVED: the source has no sign-in; the glass
/// and the ink buttons lend the faces.
///
/// ```dart
/// FrostedSignInButton('apple', onPressed: signInWithApple)
/// ```
///
/// ```dart
/// FrostedSignInButton('email', emphasis: true, onPressed: signInWithEmail)
/// ```
class FrostedSignInButton extends StatelessWidget {
  /// Creates a [FrostedSignInButton].
  const FrostedSignInButton(
    this.provider, {
    required this.onPressed,
    this.label,
    this.emphasis = false,
    this.busy = false,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  /// `apple`, `google` or `email`; any other is its name alone.
  final String provider;

  /// What signing in does; null draws the button disabled.
  final VoidCallback? onPressed;

  /// The node that holds this part's keyboard focus; null keeps one of its own.
  final FocusNode? focusNode;

  /// Whether this part takes keyboard focus when first shown.
  final bool autofocus;

  /// The words; null says "Continue with" and the provider's name.
  final String? label;

  /// The ink face for a provider without a brand face (email), for the way
  /// a page leads with.
  final bool emphasis;

  /// Whether the provider's window is open: no press, "Working…".
  final bool busy;

  static const Map<String, String> _names = {
    'apple': 'Apple',
    'google': 'Google',
    'email': 'email',
    'sso': 'SSO',
  };

  String _words(BuildContext context) {
    final name =
        _names[provider] ??
        (provider.isEmpty
            ? ''
            : '${provider[0].toUpperCase()}${provider.substring(1)}');
    return label ?? FrostedLocalizations.of(context).continueWith(name);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final words = busy
        ? FrostedLocalizations.of(context).working
        : _words(context);
    final press = busy ? null : onPressed;
    if (provider != 'apple' && provider != 'google') {
      return Semantics(
        liveRegion: busy,
        child: emphasis
            ? FrostedButton(
                focusNode: focusNode,
                autofocus: autofocus,
                words,
                icon: provider == 'email' ? FrostedGlyphs.email : null,
                expand: true,
                onPressed: press,
              )
            : FrostedButton.glass(
                words,
                icon: provider == 'email' ? FrostedGlyphs.email : null,
                expand: true,
                onPressed: press,
              ),
      );
    }
    final apple = provider == 'apple';
    final (fill, ink, edge) = apple
        ? t.isDark
              ? (_white, _black, null)
              : (_black, _white, null)
        : t.isDark
        ? (
            const Color(0xFF131314),
            const Color(0xFFE3E3E3),
            const Color(0xFF8E918F),
          )
        : (_white, const Color(0xFF1F1F1F), const Color(0xFF747775));
    final face = SizedBox(
      height: FrostedChromeMetrics.buttonWideHeight,
      width: double.infinity,
      child: FrostedFace(
        material: FrostedMaterial.paint,
        radius: BorderRadius.circular(
          FrostedChromeMetrics.buttonWideHeight / 2,
        ),
        color: fill,
        edge: edge,
        padding: const EdgeInsets.symmetric(
          horizontal: FrostedChromeMetrics.buttonInset,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: FrostedChromeMetrics.buttonGap,
          children: [
            FrostedProviderMark(
              provider,
              color: ink,
              size: FrostedChromeMetrics.buttonGlyph,
            ),
            Flexible(
              child: frostedCapCentred(
                Text(
                  words,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.textTheme.labelLarge
                      .at(FrostedChromeMetrics.buttonWideWord)
                      .c(ink),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    final button = Semantics(
      liveRegion: busy,
      child: FrostedPressable(
        focusNode: focusNode,
        autofocus: autofocus,
        onPressed: press,
        label: words,
        radius: FrostedChromeMetrics.buttonWideHeight / 2,
        child: FrostedDim(off: onPressed == null, child: face),
      ),
    );
    // From 600 wide it keeps a control's measure (320), as a wide button
    // does.
    return MediaQuery.sizeOf(context).width >= frostedMeasureFrom
        ? FrostedOwnSize(maxWidth: frostedControlMeasure, child: button)
        : button;
  }

  static const Color _white = Color(0xFFFFFFFF);
  static const Color _black = Color(0xFF000000);
}

/// Every way in a welcome offers, stacked the width of the column 12 apart
/// ([FrostedSignInButton] each). With [leadWithFirst] the first, if it has no
/// brand face (email), is lit as the page's one act. [onPressed] is handed the
/// provider chosen; without it every button is disabled.
///
/// ```dart
/// FrostedSignInStack(const ['apple', 'google', 'email'], onPressed: signIn)
/// ```
class FrostedSignInStack extends StatelessWidget {
  /// Creates a [FrostedSignInStack].
  const FrostedSignInStack(
    this.providers, {
    this.onPressed,
    this.leadWithFirst = false,
    super.key,
  });

  /// The providers' names, in order (apple, google, email).
  final List<String> providers;

  /// Called with the provider pressed; null leaves them inert.
  final ValueChanged<String>? onPressed;

  /// Whether the first provider stands as the main act.
  final bool leadWithFirst;

  @override
  Widget build(BuildContext context) {
    // From 600 wide the stack keeps a control's measure (320) at its
    // column's start, rather than running across a desktop page.
    return FrostedControlMeasure(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: FrostedSpacing.s12,
        children: [
          for (final (i, provider) in providers.indexed)
            FrostedSignInButton(
              provider,
              emphasis: leadWithFirst && i == 0,
              onPressed: onPressed == null ? null : () => onPressed!(provider),
            ),
        ],
      ),
    );
  }
}
