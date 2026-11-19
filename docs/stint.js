const study = document.querySelector('#study');
const selector = document.querySelector('#look');
const studyFrame = study.querySelector('iframe');
const viewport = study.querySelector('.viewport');
const scaleLabel = study.querySelector('.frame-size');
let width = ['390', '1440'].includes(params.get('width')) ? params.get('width')
  : matchMedia('(max-width: 760px)').matches ? '390' : '1440';

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

function showStudy() {
  const option = selector.selectedOptions[0];
  const available = option.dataset.study === 'true';
  const name = option.dataset.name;
  const id = option.value;
  document.title = 'Stint in ' + name + ' · Flutter Design Systems';
  document.querySelector('#swatch').style.background = option.dataset.swatch;
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
    return;
  }
  const url = new URL('../examples/', location.href);
  url.searchParams.set('stint', id);
  for (const key of ['page', 'theme', 'dir', 'scale', 'state', 'density']) {
    if (params.has(key)) url.searchParams.set(key, params.get(key));
  }
  study.querySelector('.open-preview').href = url;
  studyFrame.title = 'Stint team planner in ' + name;
  for (const button of study.querySelectorAll('[data-width]')) {
    button.setAttribute('aria-pressed', button.dataset.width === width);
  }
  sizeStudy();
  if (studyFrame.src !== url.href) {
    studyFrame.returnFocus = document.activeElement === studyFrame ? null : document.activeElement;
    studyFrame.src = url;
  }
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
showStudy();
