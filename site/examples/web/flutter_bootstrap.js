{{flutter_js}}
{{flutter_build_config}}

const config = { canvasKitBaseUrl: 'canvaskit/' };
if (window === window.parent) {
  // The standalone specimen uses native pixels even in a smaller browser.
  const host = document.createElement('div');
  host.id = 'preview';
  document.body.append(host);
  function sizePreview() {
    const width = new URLSearchParams(location.hash.split('?')[1]).get('width');
    host.style.width = ['390', '1440'].includes(width) ? width + 'px' : '100%';
  }
  sizePreview();
  window.addEventListener('hashchange', sizePreview);
  config.hostElement = host;
}
_flutter.loader.load({ config });
