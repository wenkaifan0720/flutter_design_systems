const page = document.body.dataset;
const params = new URLSearchParams(location.search);

function selectedLook(ids, fallback) {
  let stored;
  try { stored = localStorage.getItem('flutter-design-systems.look'); } catch {}
  return [params.get('look'), stored].find(id => ids.includes(id)) || fallback;
}

function setLook(id, settings = {}, updateAddress = true) {
  const address = new URL(location.href);
  address.searchParams.set('look', id);
  for (const [key, value] of Object.entries(settings)) address.searchParams.set(key, value);
  if (updateAddress) history.replaceState(null, '', address);
  try { localStorage.setItem('flutter-design-systems.look', id); } catch {}
  for (const link of document.querySelectorAll('a[data-component], a[data-follow-look]')) {
    const target = new URL(link.href);
    for (const key of ['look', 'width', 'theme', 'dir', 'scale']) {
      if (address.searchParams.has(key)) target.searchParams.set(key, address.searchParams.get(key));
    }
    link.href = target;
  }
}
if (page.fixedLook) {
  setLook(page.fixedLook, {}, false);
  const directory = document.querySelector('#look-directory');
  directory.addEventListener('change', () => {
    location.assign('../' + directory.value + '/');
  });
}
else if (page.page === 'home') {
  const id = selectedLook([...document.querySelectorAll('[data-look-id]')].map(a => a.dataset.lookId), null);
  if (id) setLook(id, {}, false);
}

const browse = document.querySelector('.browse');
const sidebar = document.querySelector('#sidebar');
const search = sidebar.querySelector('input');
function openNav(open) {
  browse.setAttribute('aria-expanded', open);
  sidebar.classList.toggle('open', open);
}
browse.addEventListener('click', () => {
  const open = browse.getAttribute('aria-expanded') === 'false';
  openNav(open);
  if (open) search.focus();
});
const list = document.querySelector('#directory-links');
const countLabel = document.querySelector('#search-count');
const normalize = value => value.toLowerCase().replace(/[-_/]+/g, ' ').trim();
function filterDirectory() {
  const terms = normalize(search.value).split(/\s+/).filter(Boolean);
  let matches = 0;
  for (const group of list.querySelectorAll('.nav-group')) {
    let count = 0;
    for (const link of group.querySelectorAll('a')) {
      const name = normalize(group.querySelector('h3').textContent + ' ' + link.textContent);
      link.hidden = !terms.every(term => name.includes(term));
      if (!link.hidden) count++;
    }
    group.hidden = count === 0;
    matches += count;
  }
  document.querySelector('#empty').hidden = matches !== 0;
  countLabel.textContent = terms.length ? matches + (matches === 1 ? ' matching page' : ' matching pages') : '';
  list.scrollTop = 0;
}
search.addEventListener('input', filterDirectory);
search.addEventListener('keydown', event => {
  const first = list.querySelector('a:not([hidden])');
  if (first && event.key === 'ArrowDown') {
    event.preventDefault();
    first.focus();
  } else if (first && event.key === 'Enter' && search.value.trim()) {
    event.preventDefault();
    first.click();
  }
});
function handleShortcut(event) {
  if (event.defaultPrevented || event.altKey || event.metaKey || event.ctrlKey) return;
  if (event.key === '/' && !event.target.isContentEditable &&
      !['INPUT', 'SELECT', 'TEXTAREA'].includes(event.target.tagName)) {
    event.preventDefault();
    if (getComputedStyle(browse).display !== 'none') openNav(true);
    search.focus();
    search.select();
  } else if (event.key === 'Escape' && event.target === search && search.value) {
    event.preventDefault();
    search.value = '';
    filterDirectory();
  } else if (event.key === 'Escape' && sidebar.classList.contains('open')) {
    openNav(false);
    browse.focus();
  }
}
const currentLink = list.querySelector('[aria-current="page"]');
if (currentLink && list.clientHeight) {
  const delta = currentLink.getBoundingClientRect().top - list.getBoundingClientRect().top;
  if (delta > list.clientHeight - 32) list.scrollTop += delta - list.clientHeight / 2;
}
if (page.page === '404') document.querySelector('.skip').href = location.pathname + location.search + '#main';
document.addEventListener('keydown', handleShortcut);

// Flutter's initial Navigator focuses its view as it mounts. Preserve the
// reader's place in the documentation until they enter a preview themselves.
function followFrame(iframe) {
  if (iframe.dataset.observed) return;
  iframe.dataset.observed = 'true';
  iframe.addEventListener('load', () => {
    const doc = iframe.contentDocument;
    if (!doc) return;
    doc.addEventListener('pointerdown', () => { iframe.returnFocus = null; }, true);
    doc.addEventListener('keydown', event => {
      iframe.returnFocus = null;
      handleShortcut(event);
    }, true);
    const restore = () => requestAnimationFrame(() => {
      if (iframe.returnFocus && document.activeElement === iframe &&
          doc.activeElement?.tagName === 'FLUTTER-VIEW') {
        iframe.returnFocus.focus({preventScroll: true});
      }
    });
    new MutationObserver(restore).observe(doc.head, {childList: true, subtree: true, characterData: true});
    iframe.contentWindow.addEventListener('flutter-first-frame', restore, {once: true});
  });
}
