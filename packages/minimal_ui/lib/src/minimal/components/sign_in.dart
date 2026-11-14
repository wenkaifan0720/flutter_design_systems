import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../fonts.dart';
import '../internal/styled.dart';
import '../localizations.dart';
import '../theme.dart';
import 'button.dart';

/// Where an app's own logos live in its bundle.
const String _appLogos = 'assets/logos/';

/// Where the kit's marks live in the bundle: the package's folder in an app
/// on `minimal_ui`, or the app's own when the app bundles them itself.
const String _kitLogos = minimalFontPackage == null
    ? _appLogos
    : 'packages/$minimalFontPackage/$_appLogos';

/// The marks the kit ships, by base name, at their asset keys: what a mark
/// resolves against until the bundle's asset manifest has been read (and
/// if it cannot be), so the default providers draw on the first frame.
const Map<String, String> _shippedMarks = <String, String>{
  'apple_mark': '${_kitLogos}apple_mark.png',
  'apple_mark_dark': '${_kitLogos}apple_mark_dark.png',
  'apple_mark_mask': '${_kitLogos}apple_mark_mask.png',
  'github_mark': '${_kitLogos}github_mark.png',
  'github_mark_dark': '${_kitLogos}github_mark_dark.png',
  'github_mark_mask': '${_kitLogos}github_mark_mask.png',
  'google_mark': '${_kitLogos}google_mark.png',
  'google_mark_mask': '${_kitLogos}google_mark_mask.png',
};

/// The logo vocabulary a bundle carries — every `<name>.png` its asset
/// manifest lists under the kit's folder or the app's own `assets/logos/`,
/// by base name, at its asset key, the app's own winning — read once per
/// bundle. A slug is resolved by lookup in it, never by a failed asset load.
final Expando<Future<Map<String, String>>> _bundledLogos = Expando();

Future<Map<String, String>> _logoVocabulary(AssetBundle bundle) =>
    _bundledLogos[bundle] ??= AssetManifest.loadFromAssetBundle(bundle)
        .then((manifest) {
          final assets = manifest.listAssets();
          return {
            // The same folder twice when the app bundles the marks: the later entry wins.
            for (final dir in const [_kitLogos, _appLogos])
              for (final asset in assets)
                if (asset.startsWith(dir) &&
                    asset.endsWith('.png') &&
                    !asset.substring(dir.length).contains('/'))
                  asset.substring(dir.length, asset.length - 4): asset,
          };
        }, onError: (Object _) => _shippedMarks);

const Map<String, String> _providerNames = <String, String>{
  'apple': 'Apple',
  'google': 'Google',
  'github': 'GitHub',
  'microsoft': 'Microsoft',
  'gitlab': 'GitLab',
  'email': 'email',
  'sso': 'SSO',
};

String _providerName(String slug) =>
    _providerNames[slug] ??
    (slug.isEmpty ? '' : '${slug[0].toUpperCase()}${slug.substring(1)}');

/// One `Continue with <provider>` button: Minimal's 40 px bordered button
/// carrying the provider's mark — the real colours on the neutral surface,
/// the mono silhouette in the on-accent ink on the accent fill — so every
/// sign-in reads as one family in the app's own theme. Disabled, every mark
/// turns to its mono silhouette in the label's ink and dims with the words,
/// so no brand colour is left lit.
///
/// The mark resolves from the logo vocabulary the bundle carries at
/// `<slug>_mark[_dark|_mask].png`, as its asset manifest lists it: the
/// app's own `assets/logos/` first, then the marks that ship with the kit
/// (`apple`, `google` and `github`); `email` draws the mail glyph and says
/// "Continue with email"; a slug neither carries draws a mono monogram
/// square, never a wrong brand.
///
/// ```dart
/// MinimalSignInButton('apple', onPressed: signIn)
/// ```
class MinimalSignInButton extends StatelessWidget {
  /// A button that signs in with [provider].
  const MinimalSignInButton(
    this.provider, {
    super.key,
    this.onPressed,
    this.label,
    this.emphasis = false,
    this.expand = true,
    this.focusNode,
    this.autofocus = false,
  });

  /// `apple`, `google`, `github`, `email`, or another provider's slug.
  final String provider;

  /// Null disables the button (a provider that is not configured yet).
  final VoidCallback? onPressed;

  /// Unstated, `Continue with <Provider>`.
  final String? label;

  /// The accent-filled register for the one provider a page leads with.
  final bool emphasis;

  /// Fill the available width, as a stack of them does.
  final bool expand;

  /// The mark's height inside the button.
  static const double markSize = 16;

  /// Its focus node, for a caller that moves focus to it; null keeps one
  /// of its own.
  final FocusNode? focusNode;

  /// Whether it takes keyboard focus when it first appears.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    return MinimalButton(
      label ??
          MinimalLocalizations.of(context)
              .continueWith(_providerName(provider)),
      onPressed: onPressed,
      focusNode: focusNode,
      autofocus: autofocus,
      size: MinimalButtonSize.large,
      expand: expand,
      variant: emphasis
          ? MinimalButtonVariant.primary
          : MinimalButtonVariant.secondary,
      leading: _ProviderMark(
        provider,
        mono: emphasis,
        quiet: onPressed == null,
        color: emphasis ? t.primaryForeground : t.foreground,
      ),
    );
  }
}

/// The providers a sign-in page offers, stacked full width at the dense
/// 8 px gap — the first in emphasis when [leadWithFirst] is set. [onPressed]
/// receives the slug chosen; null disables them all (a request in flight).
///
/// ```dart
/// MinimalSignInStack(const ['apple', 'google', 'email'], onPressed: signIn)
/// ```
class MinimalSignInStack extends StatelessWidget {
  /// A button for each of [providers].
  const MinimalSignInStack(
    this.providers, {
    super.key,
    this.onPressed,
    this.leadWithFirst = false,
  });

  /// The providers, in order.
  final List<String> providers;

  /// Reports the provider pressed.
  final ValueChanged<String>? onPressed;

  /// Whether the first provider leads, in emphasis.
  final bool leadWithFirst;

  @override
  Widget build(BuildContext context) {
    final tap = onPressed;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, provider) in providers.indexed) ...[
          if (i > 0) const MinimalGap(MinimalSpacing.s8),
          MinimalSignInButton(
            provider,
            emphasis: leadWithFirst && i == 0,
            onPressed: tap == null ? null : () => tap(provider),
          ),
        ],
      ],
    );
  }
}

/// A provider's mark at [MinimalSignInButton.markSize]: the bundled brand
/// image (its dark cut on a dark ground where the vocabulary has one, or
/// its mask tinted [color] when [mono] or [quiet]), the mail glyph for
/// `email`, else a monogram square.
class _ProviderMark extends StatelessWidget {
  const _ProviderMark(
    this.slug, {
    required this.mono,
    required this.quiet,
    required this.color,
  });

  final String slug;
  final bool mono;

  /// A disabled button's mark: its mask tinted [color] like a mono one, or,
  /// where the vocabulary has no mask, the brand image in greys. Either way
  /// it dims as the words do.
  final bool quiet;
  final Color color;

  /// A brand image in greys, by luminance.
  static const ColorFilter _greys = ColorFilter.matrix(<double>[
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0, 0, 0, 1, 0, //
  ]);

  /// The asset key of the first of the slug's cuts, in preference order,
  /// that [bundled] carries, and whether it is the mask; null when it
  /// carries none.
  (String, bool)? _resolve(Map<String, String> bundled, {required bool dark}) {
    final base = '${slug}_mark';
    final mask = mono || quiet ? bundled['${base}_mask'] : null;
    if (mask != null) return (mask, true);
    if (mono) return null;
    for (final name in [if (dark) '${base}_dark', base]) {
      final key = bundled[name];
      if (key != null) return (key, false);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    const size = MinimalSignInButton.markSize;
    if (slug == 'email') {
      return MinimalIcon(LucideIcons.mail, size: size, color: color);
    }
    final monogram = _Monogram(slug, color: color);
    return ExcludeSemantics(
      child: FutureBuilder<Map<String, String>>(
        future: _logoVocabulary(DefaultAssetBundle.of(context)),
        initialData: _shippedMarks,
        builder: (context, snapshot) {
          final cut = _resolve(
            snapshot.data ?? _shippedMarks,
            dark: !t.isLightAppearance,
          );
          if (cut == null) return monogram;
          final (key, tinted) = cut;
          final mark = Image.asset(
            key,
            height: size,
            width: size,
            fit: BoxFit.contain,
            color: tinted ? color : null,
            colorBlendMode: tinted ? BlendMode.srcIn : null,
            // A manifest that listed a file the bundle cannot load.
            errorBuilder: (context, error, stackTrace) => monogram,
          );
          return quiet && !tinted
              ? ColorFiltered(colorFilter: _greys, child: mark)
              : mark;
        },
      ),
    );
  }
}

/// The graceful miss: the slug's initial in mono inside a hairline square.
class _Monogram extends StatelessWidget {
  const _Monogram(this.slug, {required this.color});

  final String slug;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    const size = MinimalSignInButton.markSize;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: minimalFrame(
        t.shapes.mark,
        side: BorderSide(color: color, width: t.hairline),
      ),
      child: Text(
        slug.isEmpty ? '' : slug[0].toUpperCase(),
        style: t.mono.c(color).copyWith(fontSize: 10, height: 1),
        textScaler: TextScaler.noScaling,
      ),
    );
  }
}
