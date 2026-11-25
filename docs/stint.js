const study = document.querySelector('#study');
const selector = document.querySelector('#look');
const studyFrame = study.querySelector('iframe');
const viewport = study.querySelector('.viewport');
const stage = study.querySelector('.stage');
const scaleLabel = study.querySelector('.frame-size');
const quick = study.querySelector('.quick');
const quickNote = study.querySelector('#quick-note');
const more = quick.querySelector('.quick-more');
let width = ['390', '1440'].includes(params.get('width')) ? params.get('width')
  : matchMedia('(max-width: 760px)').matches ? '390' : '1440';

// The app's settings the quick controls change in place, by message: the
// address keeps each choice, and a new edition opens with them.
const settingKeys = ['theme', 'accent', 'scale', 'lang', 'density', 'motion', 'bold', 'targets', 'reader'];
const toggleValues = {motion: ['reduce', 'full'], bold: ['1', '0'], targets: ['1', '0'], reader: ['1', '0']};
const chosen = {};
for (const key of settingKeys) if (params.has(key)) chosen[key] = params.get(key);
if (!chosen.lang && params.get('dir') === 'rtl') chosen.lang = 'ar';
let effective = null;
let pending = {};
let openLook = null;

function frameUrl(id) {
  const url = new URL('../examples/', location.href);
  url.searchParams.set('stint', id);
  for (const key of ['page', 'state']) if (params.has(key)) url.searchParams.set(key, params.get(key));
  for (const [key, value] of Object.entries(chosen)) url.searchParams.set(key, value);
  return url;
}

function sizeStudy() {
  if (study.hidden) return;
  const phone = width === '390';
  const height = phone ? 844 : 960;
  viewport.classList.toggle('phone-frame', phone);
  viewport.style.aspectRatio = width + '/' + height;
  studyFrame.style.width = width + 'px';
  studyFrame.style.height = height + 'px';
  const factor = phone ? 1 : Math.min(1, viewport.getBoundingClientRect().width / Number(width));
  studyFrame.style.transform = factor === 1 ? '' : 'scale(' + factor + ')';
  scaleLabel.textContent = 'Shown at ' + Math.round(factor * 100) + '%';
}

function same(key, a, b) {
  if (a == null || b == null) return false;
  return key === 'scale' ? Math.abs(Number(a) - Number(b)) < 0.01 : a === b;
}

function showChoices() {
  const state = {...chosen, ...effective};
  for (const group of quick.querySelectorAll('[data-set]')) {
    for (const button of group.querySelectorAll('[data-value]')) {
      button.setAttribute('aria-pressed', same(group.dataset.set, button.dataset.value, state[group.dataset.set]));
    }
  }
  for (const button of quick.querySelectorAll('[data-toggle]')) {
    button.setAttribute('aria-pressed', state[button.dataset.toggle] === toggleValues[button.dataset.toggle][0]);
  }
  stage.classList.toggle('night', state.theme === 'night');
  const floor = effective?.floor || '44';
  const notes = [];
  if (state.targets === '1') {
    notes.push('Tap targets: green meets the ' + floor + ' × ' + floor + ' floor for ' + (floor === '44' ? 'a finger' : 'a pointer') + ' on this device, red is smaller, grey is cut off by its list or panel.');
  }
  if (state.reader === '1') notes.push('Screen reader: each stop, with what it announces.');
  quickNote.textContent = notes.join(' ');
  quickNote.hidden = notes.length === 0;
}

function remember(changes) {
  const address = new URL(location.href);
  for (const [key, value] of Object.entries(changes)) {
    chosen[key] = value;
    address.searchParams.set(key, value);
  }
  if ('lang' in changes) address.searchParams.delete('dir');
  history.replaceState(null, '', address);
  study.querySelector('.open-preview').href = frameUrl(selector.value);
}

function send(changes) {
  if (!effective) {
    Object.assign(pending, changes);
    return;
  }
  studyFrame.contentWindow?.postMessage({type: 'stint-options', params: changes}, location.origin);
}

function choose(key, value) {
  remember({[key]: value});
  send({[key]: value});
  showChoices();
}

addEventListener('message', event => {
  if (event.origin !== location.origin || event.source !== studyFrame.contentWindow) return;
  const data = event.data;
  if (!data || data.type !== 'stint-settings' || typeof data.params !== 'object') return;
  const next = data.params;
  if (effective) {
    // A change made in the app (its own Settings page) stays in the address.
    const changes = {};
    for (const key of settingKeys) {
      if (key in next && !same(key, next[key], effective[key]) && !same(key, next[key], chosen[key])) changes[key] = next[key];
    }
    if (Object.keys(changes).length) remember(changes);
  }
  effective = next;
  if (Object.keys(pending).length) {
    const changes = pending;
    pending = {};
    send(changes);
  }
  showChoices();
});

function showStudy() {
  const option = selector.selectedOptions[0];
  const available = option.dataset.study === 'true';
  const name = option.dataset.name;
  const id = option.value;
  document.title = 'Stint in ' + name + ' · Flutter Design Systems';
  document.querySelector('#swatch').style.background = option.dataset.swatch;
  quick.querySelector('[data-set="accent"] [data-value="look"] .dot').style.background = option.dataset.swatch;
  document.querySelector('#look-details').href = '../looks/' + id + '/';
  const unavailable = document.querySelector('#unavailable');
  unavailable.querySelector('p').textContent = available ? '' : 'Stint is not available in ' + name + ' yet. Open one of these editions.';
  for (const choice of selector.options) {
    choice.hidden = choice.dataset.study !== 'true' && choice !== option;
  }
  unavailable.hidden = available;
  study.hidden = !available;
  setLook(id, {width});
  if (!available) {
    studyFrame.removeAttribute('src');
    openLook = null;
    return;
  }
  const density = option.dataset.density !== 'false';
  const densityGroup = quick.querySelector('[data-set="density"]');
  for (const button of densityGroup.querySelectorAll('button')) button.hidden = !density;
  const off = densityGroup.querySelector('.seg-off');
  off.textContent = density ? '' : 'One density in ' + name;
  off.hidden = density;
  const url = frameUrl(id);
  study.querySelector('.open-preview').href = url;
  studyFrame.title = 'Stint team planner in ' + name;
  for (const button of study.querySelectorAll('[data-width]')) {
    button.setAttribute('aria-pressed', button.dataset.width === width);
  }
  sizeStudy();
  // Only a new edition loads the frame; every other change reaches the
  // running app by message.
  if (openLook !== id) {
    openLook = id;
    effective = null;
    studyFrame.returnFocus = document.activeElement === studyFrame ? null : document.activeElement;
    studyFrame.src = url;
  }
  showChoices();
}

followFrame(studyFrame);
new ResizeObserver(sizeStudy).observe(viewport);
selector.value = selectedLook([...selector.options].map(o => o.value), study.dataset.start);
selector.addEventListener('change', showStudy);
for (const button of study.querySelectorAll('[data-width]')) {
  button.addEventListener('click', () => {
    width = button.dataset.width;
    showStudy();
  });
}
for (const group of quick.querySelectorAll('[data-set]')) {
  for (const button of group.querySelectorAll('[data-value]')) {
    button.addEventListener('click', () => choose(group.dataset.set, button.dataset.value));
  }
}
for (const button of quick.querySelectorAll('[data-toggle]')) {
  button.addEventListener('click', () => {
    const [on, off] = toggleValues[button.dataset.toggle];
    choose(button.dataset.toggle, button.getAttribute('aria-pressed') === 'true' ? off : on);
  });
}
more.addEventListener('click', () => {
  const open = more.getAttribute('aria-expanded') !== 'true';
  more.setAttribute('aria-expanded', open);
  quick.classList.toggle('expanded', open);
});
showStudy();
