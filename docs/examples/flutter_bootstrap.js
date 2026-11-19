fetch('bundle.json', {cache: 'no-store'}).then(r => r.json()).then(({build}) => {
  const script = document.createElement('script');
  script.src = 'bundles/' + build + '/flutter_bootstrap.js';
  document.head.append(script);
});
