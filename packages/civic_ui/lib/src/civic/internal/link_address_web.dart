import 'dart:ui_web' as ui_web;

/// The address a link's [url] carries in the semantics tree, on the web:
/// an app's route as the app's URL strategy spells it (`/permits` is
/// `#/permits` on hash routes), as url_launcher spells its own anchor's; a
/// web address, or a place on the page (`#full-name`), as it is.
Uri civicLinkAddress(Uri url) {
  final strategy = ui_web.urlStrategy;
  final inPage = url.path.isEmpty && !url.hasQuery && url.hasFragment;
  if (url.hasScheme || inPage || strategy == null) return url;
  return Uri.parse(strategy.prepareExternalUrl(url.toString()));
}
