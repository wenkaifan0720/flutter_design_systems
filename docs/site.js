const select = document.querySelector('#look');
const specimens = document.querySelector('#specimens');
const packageLink = document.querySelector('#package-link');
const options = [...select.options];
// The look whose code the page was served with; a look's own page
// (`<slug>/<look>/`) keeps it unless the address names another.
const servedLook = specimens.dataset.look || page.defaultLook;
const variants = new Map([[servedLook, specimens.innerHTML]]);
document.querySelector('#look-pages').hidden = true;
const loadError = document.querySelector('#look-error');
let revision = 0;

const look = 'own' in specimens.dataset && !params.has('look') ? servedLook :
  selectedLook(options.map(option => option.value), servedLook);
const state = {
  width: ['390', '1440'].includes(params.get('width')) ? params.get('width') :
    matchMedia('(max-width: 760px)').matches ? '390' : '1440',
  theme: params.get('theme') === 'night' ? 'night' : 'day',
  dir: params.get('dir') === 'rtl' ? 'rtl' : 'ltr',
  scale: params.get('scale') === '2' ? '2' : '1',
};

const resize = new ResizeObserver(entries => {
  for (const {target, contentRect} of entries) {
    if (contentRect.width) {
      target.closest('.example').querySelector('.frame-size').textContent =
        '· ' + Math.round(contentRect.width) + ' px';
    }
  }
});

function renderSettings() {
  for (const example of specimens.querySelectorAll('[data-example]')) {
    const target = new URL(page.root + 'examples/', location.href);
    const iframe = example.querySelector('iframe');
    const viewport = example.querySelector('.viewport');
    const query = new URLSearchParams(state);
    if (viewport.dataset.height) query.set('align', 'top');
    target.hash = '/' + [select.value, page.page, example.dataset.example].join('/') + '?' + query;
    viewport.classList.toggle('phone-frame', state.width === '390');
    if (viewport.dataset.height) {
      const extra = state.scale === '2' ? 160 : 0;
      viewport.style.height = (Number(viewport.dataset.height) + extra) + 'px';
    }
    if (iframe.src !== target.href) iframe.src = target;
    example.querySelector('.open-preview').href = target;
    for (const button of example.querySelectorAll('[data-width]')) {
      button.setAttribute('aria-pressed', button.dataset.width === state.width);
    }
    const settings = {
      theme: [state.theme === 'night', 'Night', 'Day'],
      dir: [state.dir === 'rtl', 'RTL', 'LTR'],
      scale: [state.scale === '2', '200%', '100%'],
    };
    for (const button of example.querySelectorAll('[data-setting]')) {
      const [active, on, off] = settings[button.dataset.setting];
      button.setAttribute('aria-pressed', active);
      button.querySelector('[data-value]').textContent = active ? on : off;
    }
    example.querySelector('.stage').classList.toggle('night', state.theme === 'night');
    example.querySelector('.stage').classList.toggle('large-type', state.scale === '2');
  }
  setLook(select.value, state);
}

async function renderLook(id) {
  const request = ++revision;
  select.value = id;
  loadError.hidden = true;
  specimens.setAttribute('aria-busy', 'true');
  if (!variants.has(id)) {
    try {
      const response = await fetch(page.root + page.page + '/parts/' + id + '.html');
      if (!response.ok) throw new Error(String(response.status));
      variants.set(id, await response.text());
    } catch {
      if (request !== revision) return;
      loadError.querySelector('p').textContent = 'The ' + select.selectedOptions[0].text + ' example could not load.';
      loadError.hidden = false;
      specimens.hidden = true;
      specimens.removeAttribute('aria-busy');
      return;
    }
  }
  if (request !== revision) return;
  resize.disconnect();
  specimens.hidden = false;
  const next = document.createElement('template');
  next.innerHTML = variants.get(id);
  const existing = [...specimens.querySelectorAll('.example')];
  const incoming = [...next.content.querySelectorAll('.example')];
  if (existing.length && existing.length === incoming.length &&
      existing.every((entry, i) => entry.dataset.example === incoming[i].dataset.example)) {
    // Keep the mounted Flutter view. Its fragment loads the next deferred
    // library while the page replaces the corresponding source and API.
    existing.forEach((entry, i) => {
      entry.querySelector('.keyboard-note').replaceWith(incoming[i].querySelector('.keyboard-note'));
      entry.querySelector('.source').replaceChildren(...incoming[i].querySelector('.source').childNodes);
      entry.querySelector('iframe').title = incoming[i].querySelector('iframe').title;
    });
    specimens.querySelector('.reference').replaceWith(next.content.querySelector('.reference'));
  } else {
    specimens.replaceChildren(next.content);
  }
  specimens.removeAttribute('aria-busy');
  const option = select.selectedOptions[0];
  document.title = document.querySelector('h1').textContent + ' in ' + option.dataset.name + ' · Flutter Design Systems';
  document.querySelector('#swatch').style.background = option.dataset.swatch;
  packageLink.href = 'https://pub.dev/packages/' + option.dataset.package;
  packageLink.firstChild.textContent = option.dataset.name + ' on pub.dev ';
  for (const viewport of specimens.querySelectorAll('.viewport')) {
    const iframe = viewport.querySelector('iframe');
    followFrame(iframe);
    iframe.returnFocus = document.activeElement === iframe ? null : document.activeElement;
    resize.observe(viewport);
  }
  document.querySelector('#look-details').href = page.root + 'looks/' + id + '/';
  renderSettings();
}

function activateTab(tab) {
  for (const item of tab.parentElement.querySelectorAll('[role="tab"]')) {
    const active = item === tab;
    item.setAttribute('aria-selected', active);
    item.tabIndex = active ? 0 : -1;
    const panel = document.getElementById(item.getAttribute('aria-controls'));
    panel.hidden = !active;
  }
}

specimens.addEventListener('keydown', event => {
  if (!event.target.matches('.example-tabs [role="tab"]')) return;
  const tabs = [...event.target.parentElement.querySelectorAll('[role="tab"]')];
  const index = tabs.indexOf(event.target);
  let next;
  switch (event.key) {
    case 'ArrowRight': next = (index + 1) % tabs.length; break;
    case 'ArrowLeft': next = (index - 1 + tabs.length) % tabs.length; break;
    case 'Home': next = 0; break;
    case 'End': next = tabs.length - 1; break;
    default: return;
  }
  event.preventDefault();
  activateTab(tabs[next]);
  tabs[next].focus();
});

specimens.addEventListener('click', async event => {
  const button = event.target.closest('button');
  if (!button) return;
  if (button.matches('.example-tabs [role="tab"]')) {
    activateTab(button);
    return;
  }
  if (button.classList.contains('copy')) {
    const code = button.closest('.source').querySelector('code');
    try {
      await navigator.clipboard.writeText(code.textContent);
      button.textContent = 'Copied';
    } catch {
      const range = document.createRange();
      range.selectNodeContents(code);
      const selection = getSelection();
      selection.removeAllRanges();
      selection.addRange(range);
      button.textContent = 'Code selected';
    }
    return;
  }
  if (button.dataset.width) state.width = button.dataset.width;
  switch (button.dataset.setting) {
    case 'theme': state.theme = state.theme === 'day' ? 'night' : 'day'; break;
    case 'dir': state.dir = state.dir === 'ltr' ? 'rtl' : 'ltr'; break;
    case 'scale': state.scale = state.scale === '1' ? '2' : '1'; break;
  }
  renderSettings();
});
loadError.querySelector('button').addEventListener('click', () => renderLook(select.value));
select.addEventListener('change', () => renderLook(select.value));
renderLook(look);
