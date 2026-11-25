// The home page's start steps: the chosen look's pub add line and links. The
// choice is the site's look (navigation.js), so Stint and the component pages
// open on it.
const start = document.querySelector('.start');
const chips = [...start.querySelectorAll('[data-look]')];
const packageName = start.querySelector('[data-start-package]');
const readme = start.querySelector('[data-start-readme]');
const lookPage = start.querySelector('[data-start-page]');
const copy = start.querySelector('.copy');
const note = start.querySelector('[data-start-note]');
const setups = [...start.querySelectorAll('[data-setup]')];

function choose(chip, remember) {
  for (const other of chips) other.setAttribute('aria-pressed', other === chip);
  // On a phone the chips scroll sideways: keep the chosen one in view.
  const row = chip.parentElement.getBoundingClientRect();
  const box = chip.getBoundingClientRect();
  if (box.left < row.left || box.right > row.right) chip.parentElement.scrollLeft += box.left - row.left - 8;
  packageName.textContent = chip.dataset.package;
  readme.href = 'https://pub.dev/packages/' + chip.dataset.package;
  readme.textContent = chip.dataset.name + ' on pub.dev';
  lookPage.href = 'looks/' + chip.dataset.look + '/';
  lookPage.textContent = chip.dataset.name + ' components';
  copy.textContent = 'Copy';
  for (const setup of setups) setup.hidden = setup.dataset.setup !== chip.dataset.look;
  note.hidden = setups.some(setup => setup.dataset.setup === chip.dataset.look);
  if (remember) setLook(chip.dataset.look, {}, false);
}

const first = selectedLook(chips.map(chip => chip.dataset.look), start.dataset.start);
choose(chips.find(chip => chip.dataset.look === first), false);
for (const chip of chips) chip.addEventListener('click', () => choose(chip, true));
copy.addEventListener('click', async () => {
  const line = copy.previousElementSibling;
  try {
    await navigator.clipboard.writeText(line.textContent);
    copy.textContent = 'Copied';
  } catch {
    const range = document.createRange();
    range.selectNodeContents(line);
    getSelection().removeAllRanges();
    getSelection().addRange(range);
    copy.textContent = 'Selected';
  }
});
