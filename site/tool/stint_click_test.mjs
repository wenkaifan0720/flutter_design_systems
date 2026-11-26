// Clicks every control on every Stint screen in the built site and checks that each one responds.
//
// A control is any node the app's semantics tree offers for activation: buttons, segments, chips,
// checks, switches, steppers, fields, pickers and menu triggers. Each is clicked with a mouse at
// 1440 px and tapped with a finger at 390 px, at its centre, the way a person would. It passes when
// something in the app changes: its own state (checked, selected, pressed, expanded, value), the
// screen, a menu, sheet or dialog that opens, or focus moving into a text field. When it opens a
// menu, sheet or dialog, one control inside it is clicked too and must respond in turn. A choice
// that is already selected may stay as it is.
//
// The screen is restored after each click (Escape, or a fresh load when Escape is not enough).
// Long lists are sampled: when a screen repeats one control six or more times (task rows, row
// menus, time entries), the first two are clicked.
//
// A group of choices that reaches the semantics tree as one control (its options merged into one
// label) fails as well: neither a pointer nor a screen reader can pick one option.
//
// Usage, from the repository root, after `bash site/tool/build.sh`:
//
//   npm --prefix site/tool install
//   npx --prefix site/tool playwright-core install chromium-headless-shell
//   python3 site/tool/serve.py &
//   node site/tool/stint_click_test.mjs [--base URL] [--editions a,b] [--screens today,tasks]
//                                       [--widths 1440,390] [--jobs 4] [--out report.json]
//                                       [--browser path/to/chrome] [--shots dir] [--page 0]
//
// First it checks the Stint page around the app (--page 0 skips it): its accent menu stays hidden
// until the running edition names its palettes, lists six with the look's own chosen, keeps a
// choice across a reload and is rebuilt for another look; its tap-target note names the floor of
// what reaches the app (a pointer's on a desktop, a finger's on a phone).
//
// With --shots, the screen as each failing control left it is saved there.
//
// A control that shows a state of its own (a segment, a chip, a check, a switch, a row that can
// be current) must change that state, not something else: a group merged into one node turns a
// click on its third option into a change of its first.
//
// It exits with 1 when any control fails, and prints each failure as edition, width, screen and
// control.
import fs from 'node:fs';
import {parseArgs} from 'node:util';
import {chromium} from 'playwright-core';

const {values: args} = parseArgs({
  options: {
    base: {type: 'string', default: 'http://127.0.0.1:8000/docs/examples/'},
    editions: {type: 'string'},
    screens: {type: 'string', default: 'today,tasks,detail,time,settings'},
    widths: {type: 'string', default: '1440,390'},
    jobs: {type: 'string', default: '4'},
    out: {type: 'string'},
    shots: {type: 'string'},
    browser: {type: 'string'},
    page: {type: 'string', default: '1'},
  },
});

// Every Stint edition: one per look in site/looks.json, Flutter's own Material and Cupertino included.
const looks = Object.keys(JSON.parse(fs.readFileSync(new URL('../looks.json', import.meta.url))));
const editions = args.editions ? args.editions.split(',') : looks;
const screens = args.screens.split(',');
const widths = args.widths.split(',').map(Number);

// How long a control has to respond, and how long the app gets to settle after it does.
const RESPONSE_MS = 1500;
const SETTLE_MS = 450;
// A screen that repeats one control this often is a list; its first [SAMPLE] are clicked.
const LIST_AT = 6;
const SAMPLE = 2;
// Stint's choice groups (stint_core's words): two or more of one group's options in one control's
// label mean the group was merged into one node.
const CHOICE_GROUPS = [
  ['Low', 'Normal', 'High'],
  ['Planning', 'Review', 'Fieldwork'],
  ['System', 'Day', 'Night'],
  ['100%', '150%', '200%'],
  ['Standard', 'Compact'],
  ['All', 'Open', 'Done'],
];
// States a control shows of itself; one that has any must change its own when it is clicked.
const OWN_STATES = ['aria-checked', 'aria-selected', 'aria-pressed', 'aria-current', 'aria-expanded', 'aria-valuenow'];
// Controls in an opened menu, sheet or dialog that only close it.
const CLOSE = /^(cancel|close|dismiss|back|done|ok|not now|keep editing|clear)$/i;

// Runs in the page: the semantics tree as controls (with their state) and a fingerprint of all of
// it. Positions are left out of the fingerprint, so scrolling alone is not a response.
function readTree() {
  const roles = new Set(['button', 'checkbox', 'switch', 'radio', 'tab', 'slider', 'menuitem',
    'menuitemcheckbox', 'menuitemradio', 'link', 'combobox', 'textbox', 'spinbutton', 'option']);
  const states = ['aria-checked', 'aria-selected', 'aria-pressed', 'aria-expanded', 'aria-valuenow',
    'aria-valuetext', 'aria-current', 'aria-description', 'aria-disabled'];
  const text = e => (e.getAttribute('aria-label') ||
    [...e.childNodes].filter(n => n.nodeType === 3 || n.localName === 'span' ||
      n.localName === 'flt-semantics-label').map(n => n.textContent).join(' ') ||
    (e.localName !== 'flt-semantics' ? e.getAttribute('placeholder') || '' : '') ||
    (!e.querySelector('flt-semantics') ? e.textContent : '') || '').replace(/[ \t]+/g, ' ').trim();
  const nodes = [...document.querySelectorAll('flt-semantics, input, textarea')];
  const print = [];
  const controls = [];
  const overlays = [];
  for (const e of nodes) {
    // A running timer ticks without a click. It cannot prove that a control responded.
    if (e.closest('[flt-semantics-identifier="stint-elapsed"]')) continue;
    const role = e.getAttribute('role') || (e.localName === 'flt-semantics' ? '' : 'textbox');
    const label = text(e);
    const state = Object.fromEntries(states.filter(s => e.hasAttribute(s)).map(s => [s, e.getAttribute(s)]));
    if (e.localName !== 'flt-semantics') state.value = e.value;
    print.push(role + '|' + label + '|' + JSON.stringify(state));
    if (['dialog', 'alertdialog', 'menu', 'listbox'].includes(role) || e.getAttribute('aria-modal') === 'true') overlays.push(role);
    const actionable = e.localName !== 'flt-semantics' || e.hasAttribute('flt-tappable') ||
      (roles.has(role) && role !== 'textbox');
    // A field's semantics node holds its <input>: the input is the control.
    if (!actionable || (e.localName === 'flt-semantics' && e.querySelector(':scope > input, :scope > textarea'))) continue;
    const r = e.getBoundingClientRect();
    if (r.width < 2 || r.height < 2) continue;
    // Whether another control lies over its centre (a sticky bar, a pane's edge).
    const top = document.elementFromPoint(r.x + r.width / 2, r.y + r.height / 2)?.closest('flt-semantics, input, textarea');
    // Only a node whose own box holds the point covers it (a node's child can reach past it).
    const tr = top?.getBoundingClientRect();
    const holds = !!tr && tr.x <= r.x + r.width / 2 && r.x + r.width / 2 <= tr.x + tr.width &&
      tr.y <= r.y + r.height / 2 && r.y + r.height / 2 <= tr.y + tr.height;
    const over = !!top && holds && top !== e && !e.contains(top) && !top.contains(e);
    // A field's own input drawn over a key in it (a picker's glyph) lets a press through to the
    // key; another control over it (a sticky bar's) takes the press.
    const underInput = over && top.localName !== 'flt-semantics';
    const covered = over && !underInput && top.hasAttribute('flt-tappable');
    controls.push({role: role || 'button', label, state, x: r.x, y: r.y, w: r.width, h: r.height, covered, underInput,
      over: over ? (top.getAttribute('role') || top.localName) + ' ' + text(top).split('\n')[0] : '',
      disabled: state['aria-disabled'] === 'true' || e.disabled === true, focused: e === document.activeElement});
  }
  const active = document.activeElement;
  return {
    print: print.join('\n') + '\n@' + location.href,
    controls,
    overlays,
    typing: !!active && (active.localName === 'input' || active.localName === 'textarea'),
    w: innerWidth,
    h: innerHeight,
  };
}

// Runs in the page: the fingerprint alone, cheap enough to poll every few milliseconds so a
// response that lasts a moment (a refresh's loading state) is still seen.
function readPrint() {
  const states = ['aria-checked', 'aria-selected', 'aria-pressed', 'aria-expanded', 'aria-valuenow',
    'aria-valuetext', 'aria-current', 'aria-description', 'aria-disabled'];
  const nodes = document.querySelectorAll('flt-semantics, input, textarea');
  let print = '';
  for (const e of nodes) {
    // A running timer ticks without a click. It cannot prove that a control responded.
    if (e.closest('[flt-semantics-identifier="stint-elapsed"]')) continue;
    print += (e.getAttribute('role') || '') + '|' + (e.getAttribute('aria-label') || '') + '|' +
      // A leaf's words in full (a stepper's figure keeps its length: 45 to 50); a parent's length.
      (e.querySelector('flt-semantics') ? e.textContent.length : e.textContent) + '|' + states.map(s => e.getAttribute(s) ?? '').join(',') +
      (e.localName === 'flt-semantics' ? '' : '|' + e.value) + '\n';
  }
  const active = document.activeElement;
  return {print: print + '@' + location.href,
    typing: !!active && (active.localName === 'input' || active.localName === 'textarea')};
}

// A control's name across reads: role, label and its place among controls of that role and label.
function keyed(tree) {
  const seen = new Map();
  for (const c of tree.controls) {
    const base = c.role + '|' + c.label;
    const n = seen.get(base) ?? 0;
    seen.set(base, n + 1);
    c.key = base + '#' + n;
    c.shape = c.label.replace(/\d+/g, '#');
    // Controls of one size and column are one list's rows, whatever their labels.
    c.family = [c.role, Math.round(c.x), Math.round(c.w), Math.round(c.h), Object.keys(c.state).sort().join()].join('|');
  }
  return tree;
}

const selected = c => c.state['aria-selected'] === 'true' || c.state['aria-current'] === 'true' ||
  c.state['aria-current'] === 'page' || c.state['aria-pressed'] === 'true' ||
  (['radio', 'tab', 'option', 'menuitemradio'].includes(c.role) && c.state['aria-checked'] === 'true') ||
  // A text field that has the focus already: a press puts the caret where it is.
  (c.role === 'textbox' && c.focused);

const describe = c => (c.label.split('\n')[0] || '(unlabelled)') + ' [' + c.role + ']';

async function run(browser, edition, width) {
  const phone = width <= 390;
  const context = await browser.newContext({
    viewport: {width, height: phone ? 844 : 960},
    hasTouch: phone,
    isMobile: phone,
    deviceScaleFactor: 1,
  });
  const page = await context.newPage();
  const results = [];
  const tested = new Set();
  const read = async () => keyed(await page.evaluate(readTree));

  async function open(screen) {
    const q = new URLSearchParams({stint: edition, page: screen, theme: 'day', dir: 'ltr', a11y: '1'});
    await page.goto(args.base + '?' + q, {waitUntil: 'domcontentloaded'});
    await page.waitForFunction(() => {
      const labels = [...document.querySelectorAll('flt-semantics')].map(e => e.getAttribute('aria-label') || '');
      return labels.length > 10 && !labels.some(l => /^Loading/.test(l));
    }, null, {timeout: 60000});
    // A phone opens a record over the list once the list stands: hold out for a second of calm.
    return settle(6);
  }

  // Waits until [calm] + 1 reads in a row agree, the controls' places too, so loads and animations
  // (a route still sliding over the one it covers) have finished.
  async function settle(calm = 2) {
    const places = t => t.controls.map(c => `${Math.round(c.x)},${Math.round(c.y)}`).join(' ');
    let last = await read();
    let same = 0;
    for (let i = 0; i < 40 && same < calm; i++) {
      await page.waitForTimeout(150);
      const next = await read();
      same = next.print === last.print && places(next) === places(last) ? same + 1 : 0;
      last = next;
    }
    return last;
  }

  async function press(c) {
    // A check row (its box and its words one target, a node far wider than tall) is pressed on
    // its words, just past a box at its start, as a person reaches for the word. Stint runs
    // left to right here.
    const row = c.role === 'checkbox' && c.w > 3 * c.h;
    const x = row ? c.x + Math.min(c.h + 8, c.w / 2) : c.x + c.w / 2;
    const y = c.y + c.h / 2;
    if (phone) {
      await page.touchscreen.tap(x, y);
    } else {
      await page.mouse.move(x, y);
      await page.mouse.down();
      await page.mouse.up();
    }
  }

  // [want] in [tree]: by name, or, when its label carries a value that has changed since (a
  // stepper's figure, a picker's date), by its label with the figures left out.
  const find = (tree, want) => tree.controls.find(v => v.key === want.key) ??
    tree.controls.find(v => v.role === want.role && v.shape === want.shape);

  // Brings [want] to the middle band of the screen, clear of sticky bars (which the semantics
  // tree does not show), scrolling the pane under it; where the pane can scroll no further, as
  // close as it goes. Inside an open overlay ([stay]) a control in view is taken where it is: a
  // scroll would close a dropdown. Returns the control at rest, or why it cannot be reached.
  async function reveal(want, stay = false) {
    let last = 'it is gone';
    let previous = null;
    let searched = 0;
    for (let i = 0; i < 12; i++) {
      const tree = await read();
      const c = find(tree, want);
      if (!c) {
        // A lazy list builds only the rows near its view: look for it further along, then back.
        if (searched >= 16) return {why: last};
        await page.mouse.move(Math.min(Math.max(want.x + 12, 4), tree.w - 4), tree.h / 2);
        await page.mouse.wheel(0, searched < 6 ? 500 : -500);
        await page.waitForTimeout(250);
        searched++;
        i--;
        continue;
      }
      const inside = c.y >= 0 && c.y + c.h <= tree.h && c.x >= 0 && c.x + c.w <= tree.w;
      const middle = stay ? inside : c.y >= tree.h * 0.2 && c.y + c.h <= tree.h * 0.75;
      last = c.covered ? 'covered by ' + c.over : 'out of view at ' + [c.x, c.y].map(Math.round);
      const resting = previous && previous.x === c.x && previous.y === c.y;
      // In the band and at rest, or as far as the pane goes and in view.
      if (resting && inside && !c.covered && (middle || i > 0)) return c;
      if (c.x < 0 || c.x + c.w > tree.w) return {why: last};
      if (!middle && !(resting && i > 1)) {
        const delta = c.y + c.h / 2 - tree.h / 2;
        // Over its own pane, mid-screen, clear of sticky bars that do not scroll.
        await page.mouse.move(c.x + Math.min(12, c.w / 2), tree.h / 2);
        await page.mouse.wheel(0, Math.max(-600, Math.min(600, delta)));
      }
      previous = c;
      await page.waitForTimeout(200);
    }
    return {why: last};
  }

  // A slider moves under a drag or its keys, not a tap: step it the way a screen reader does,
  // through the value of the node the platform sees.
  async function nudge(c) {
    await page.evaluate(({x, y, w, h}) => {
      // The slider's own node: the one at its place, not a field drawn over it (a stepper's figure).
      const e = [...document.querySelectorAll('[role=slider]')].find(n => {
        const r = n.getBoundingClientRect();
        return Math.abs(r.x - x) < 2 && Math.abs(r.y - y) < 2 && Math.abs(r.width - w) < 2 && Math.abs(r.height - h) < 2;
      });
      if (!e) return;
      if (e.localName === 'input') {
        e.value = String(Math.min(Number(e.max || 100), Number(e.value) + 1));
        e.dispatchEvent(new Event('input', {bubbles: true}));
        e.dispatchEvent(new Event('change', {bubbles: true}));
      } else {
        e.focus();
        e.dispatchEvent(new KeyboardEvent('keydown', {key: 'ArrowRight', bubbles: true}));
      }
    }, {x: c.x, y: c.y, w: c.w, h: c.h});
  }

  // Clicks [c] and waits for any change; returns the tree after it, or null when nothing changed.
  async function respond(c, before) {
    const quick = await page.evaluate(readPrint);
    // A slider under its own field's input is reached the way a screen reader reaches it.
    if (!(c.role === 'slider' && c.underInput)) await press(c);
    let after = await changed(before, c.role === 'slider' ? 600 : RESPONSE_MS, quick);
    // A press that left the slider's value as it was (it reached the stepper's figure under it):
    // step it the way a screen reader does.
    const own = a => a && find(a, c);
    if (c.role === 'slider' && !(own(after) && JSON.stringify(own(after).state) !== JSON.stringify(c.state))) {
      const now = await page.evaluate(readPrint);
      await nudge(c);
      after = await changed(before, RESPONSE_MS, now) ?? after;
    }
    // A wide row's node can reach past what it draws (a check and its label at the start of a
    // full-width row): try its start, where the pointer target is.
    if (!after && c.role !== 'slider' && c.w > 160) {
      await press({...c, x: c.x + 4, w: 24});
      after = await changed(before, RESPONSE_MS, quick);
    }
    return after;
  }

  async function changed(before, wait, quick) {
    const start = Date.now();
    while (Date.now() - start < wait) {
      await page.waitForTimeout(30);
      const now = await page.evaluate(readPrint);
      if (now.print !== quick.print || (now.typing && !quick.typing)) {
        await page.waitForTimeout(SETTLE_MS);
        const after = await settle();
        const was = new Set(before.print.split('\n'));
        after.change = now.typing && !before.typing ? ['focus in a text field']
          : after.print.split('\n').filter(line => !was.has(line)).slice(0, 3);
        return after;
      }
    }
    return null;
  }

  async function shoot(entry) {
    if (!args.shots) return;
    entry.shot = `${args.shots}/${edition}-${width}-${entry.screen}-${results.length}.png`;
    await page.screenshot({path: entry.shot}).catch(() => {});
  }

  const sameScreen = (a, b) => {
    const names = t => t.controls.map(c => c.role + '|' + c.label).sort().join('\n');
    return names(a) === names(b) && a.overlays.length === b.overlays.length;
  };

  for (const screen of screens) {
    let base;
    try {
      base = await open(screen);
    } catch (error) {
      results.push({edition, width, screen, control: '(screen)', result: 'failed', detail: 'did not open: ' + error.message.split('\n')[0]});
      continue;
    }
    // Every screen has controls: one that shows none has not drawn.
    if (!base.controls.length) {
      results.push({edition, width, screen, control: '(screen)', result: 'failed', detail: 'showed no controls'});
      continue;
    }
    for (const c of base.controls) {
      const groups = CHOICE_GROUPS.filter(g => g.filter(word => c.label.split('\n').includes(word)).length >= 2);
      for (const g of groups) {
        results.push({edition, width, screen, control: describe(c), result: 'failed',
          detail: 'its options (' + g.join(', ') + ') are one control, so none can be picked'});
      }
    }
    // Which controls to click: each once per edition and width, lists sampled.
    const families = new Map();
    for (const c of base.controls) families.set(c.family, (families.get(c.family) ?? 0) + 1);
    const taken = new Map();
    const queue = [];
    for (const c of base.controls) {
      const name = c.role + '|' + c.label;
      if (tested.has(name)) continue;
      if (families.get(c.family) >= LIST_AT) {
        const n = taken.get(c.family) ?? 0;
        if (n >= SAMPLE) continue;
        taken.set(c.family, n + 1);
      }
      tested.add(name);
      queue.push(c);
    }
    // Every screen has controls of its own: one with nothing new is a screen
    // already tested, opened in place of this one.
    if (!queue.length) {
      results.push({edition, width, screen, control: '(screen)', result: 'failed', detail: 'showed no control of its own'});
      continue;
    }
    for (const want of queue) {
      const entry = {edition, width, screen, control: describe(want)};
      if (process.env.STINT_CLICK_DEBUG) console.error(edition, width, screen, describe(want), base.controls.length);
      results.push(entry);
      if (want.disabled) {
        entry.result = 'disabled';
        continue;
      }
      try {
        const c = await reveal(want);
        if (c.why) {
          entry.result = 'failed';
          entry.detail = 'could not be reached: ' + c.why;
          await shoot(entry);
          base = await open(screen);
          continue;
        }
        // A Search button submits its field: give the field a word first.
        if (c.role === 'button' && /^search/i.test(c.label)) {
          const field = (await read()).controls.find(v => v.role === 'textbox' && /search/i.test(v.label));
          if (field) {
            await page.mouse.click(field.x + field.w / 2, field.y + field.h / 2);
            await page.keyboard.type('print');
            await page.waitForTimeout(RESPONSE_MS);
          }
        }
        const before = await read();
        let after = await respond(c, before);
        // A response that lasts a moment (a refresh) can pass between two reads on a loaded
        // machine: press once more before calling it dead.
        if (!after && !selected(c)) after = await respond(c, await read());
        if (!after) {
          entry.result = selected(c) ? 'already selected' : 'failed';
          if (entry.result === 'failed') entry.detail = 'nothing changed when it was ' + (phone ? 'tapped' : 'clicked');
        } else {
          entry.result = 'responded';
          entry.change = after.change;
          const own = find(after, c);
          // Where you are (aria-current) marks a place; a press need not move it.
          const stateful = OWN_STATES.some(k => k !== 'aria-current' && k in c.state) ||
            ['checkbox', 'switch', 'radio', 'tab', 'slider'].includes(c.role);
          if (own && stateful && !selected(c) && own.label === c.label &&
              JSON.stringify(own.state) === JSON.stringify(c.state)) {
            entry.result = 'failed';
            entry.detail = 'its own state did not change; something else did: ' + (after.change[0] ?? '');
          }
          // A menu, sheet or dialog opened: one control inside it must respond too.
          const now = new Set(after.controls.map(v => v.role + '|' + v.label));
          const gone = before.controls.filter(v => !now.has(v.role + '|' + v.label)).length;
          const tabs = t => t.controls.filter(v => v.role === 'tab').map(v => v.label + v.state['aria-selected']).join();
          const moved = tabs(after) !== tabs(before) && tabs(after) !== '';
          const opened = after.overlays.length > before.overlays.length ||
            (c.state['aria-expanded'] === 'false' && find(after, c)?.state['aria-expanded'] === 'true') ||
            // A modal barrier hides what lies under it; a move to another screen keeps the tabs.
            (gone >= before.controls.length * 0.6 && !moved);
          if (opened) {
            const old = new Set(before.controls.map(v => v.role + '|' + v.label));
            const fresh = after.controls.filter(v => !old.has(v.role + '|' + v.label) && !v.disabled &&
              !selected(v) && !CLOSE.test(v.label.split('\n')[0]) && v.label);
            // A choice in it rather than its search field, which already has focus.
            const inner = fresh.find(v => v.role !== 'textbox') ?? fresh[0];
            if (inner) {
              const target = await reveal(inner, true);
              const inside = !target.why && await respond(target, await read());
              entry.inner = describe(inner);
              if (!inside) {
                entry.result = 'failed';
                entry.detail = 'opened, but ' + describe(inner) + ' inside it did not respond';
              }
            }
          }
        }
        // Back to the screen as it was: Escape closes what opened, else load it again.
        let now = await read();
        if (!sameScreen(now, base)) {
          await page.keyboard.press('Escape');
          now = await settle();
        }
        base = sameScreen(now, base) ? now : await open(screen);
      } catch (error) {
        entry.result = 'failed';
        entry.detail = 'error: ' + error.message.split('\n')[0];
        base = await open(screen).catch(() => base);
      }
      if (entry.result === 'failed' && !entry.shot) await shoot(entry);
    }
  }
  await context.close();
  return results;
}

// The Stint page: its accent menu and tap-target note, on a desktop and on a phone.
async function checkPage(browser) {
  const results = [];
  const record = (width, control, problem) => results.push({edition: '(page)', width, screen: 'stint page',
    control, result: problem ? 'failed' : 'passed', ...(problem ? {detail: problem} : {})});
  const address = look => new URL('../stint/?look=' + look, args.base).href;
  const menu = page => page.evaluate(() => {
    const group = document.querySelector('[data-set="accent"]');
    return {hidden: group.hidden, options: [...group.querySelectorAll('button')].map(b =>
      ({id: b.dataset.value, name: b.textContent.trim(), pressed: b.getAttribute('aria-pressed') === 'true'}))};
  });
  const listed = page => page.waitForFunction(() => {
    const group = document.querySelector('[data-set="accent"]');
    return !group.hidden && group.querySelector('button');
  }, null, {timeout: 90000});
  const [first, second] = editions.length > 1 ? editions : [editions[0], looks.find(l => l !== editions[0])];

  for (const phone of [false, true]) {
    const width = phone ? 390 : 1440;
    const context = await browser.newContext(phone
      ? {viewport: {width, height: 844}, hasTouch: true, isMobile: true, deviceScaleFactor: 1,
          userAgent: 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Mobile/15E148 Safari/604.1'}
      : {viewport: {width, height: 960}, deviceScaleFactor: 1});
    // A phone's browser says so in its platform too, which Flutter reads (with touch points).
    if (phone) {
      await context.addInitScript(() => {
        Object.defineProperty(navigator, 'platform', {get: () => 'iPhone'});
        Object.defineProperty(navigator, 'maxTouchPoints', {get: () => 5});
      });
    }
    const page = await context.newPage();
    try {
      await page.goto(address(first), {waitUntil: 'domcontentloaded'});
      if (!phone) {
        const start = await menu(page);
        record(width, 'Accent before the app names its palettes',
          start.hidden && start.options.length === 0 ? null : 'shown before the app named its palettes');
      }
      await listed(page);
      const own = await menu(page);
      const names = own.options.map(o => o.name);
      record(width, 'Accent lists the look\'s six palettes',
        own.options.length !== 6 ? 'lists ' + own.options.length + ': ' + names.join(', ')
          : new Set(names).size !== 6 || names.some(n => !n) ? 'names repeat or are empty: ' + names.join(', ')
          : !own.options[0].pressed || own.options.slice(1).some(o => o.pressed) ? 'the look\'s own is not the one chosen'
          : null);
      // The note names the floor of what reaches the app here.
      if (phone) await page.click('.quick-more');
      await page.click('[data-toggle="targets"]');
      // The note follows the app's answer.
      await page.waitForFunction(() => document.querySelector('#quick-note').textContent.includes('Tap targets'),
        null, {timeout: 15000}).catch(() => {});
      const note = await page.textContent('#quick-note');
      const want = phone ? 'the 40 × 40 touch floor' : 'the 24 × 24 pointer floor (40 × 40 on touch)';
      record(width, 'Tap targets note', note.includes(want) ? null : 'says "' + note + '", not "' + want + '"');
      if (phone) continue;

      // A choice is kept across a reload, as every other setting is.
      const pick = own.options[2];
      await page.click('[data-set="accent"] button[data-value="' + pick.id + '"]');
      await page.waitForFunction(id => new URL(location.href).searchParams.get('accent') === id, pick.id);
      await page.reload({waitUntil: 'domcontentloaded'});
      await listed(page);
      const kept = await menu(page);
      record(width, 'Accent kept across a reload',
        kept.options.find(o => o.pressed)?.id === pick.id ? null : 'chose ' + pick.id + ', reloaded to ' +
          (kept.options.find(o => o.pressed)?.id ?? 'none'));

      // Another look opens in its own palettes: the old list goes at once, the new one comes with it.
      await page.selectOption('#look', second);
      const between = await menu(page);
      const dropped = !new URL(page.url()).searchParams.has('accent');
      record(width, 'Accent emptied while another look loads',
        between.hidden && between.options.length === 0 && dropped ? null
          : 'still lists ' + between.options.map(o => o.id).join(', ') + (dropped ? '' : ', and the address keeps accent'));
      await listed(page);
      const next = await menu(page);
      record(width, 'Accent rebuilt for another look',
        next.options.length === 6 && next.options[0].pressed ? null
          : 'lists ' + next.options.map(o => o.id + (o.pressed ? '*' : '')).join(', '));
    } catch (error) {
      record(width, '(page)', 'the check broke: ' + error.message.split('\n')[0]);
    } finally {
      await context.close();
    }
  }
  return results;
}

const browser = await chromium.launch({
  ...(args.browser ? {executablePath: args.browser} : {}),
  args: ['--use-angle=swiftshader', '--enable-unsafe-swiftshader'],
});
const jobs = editions.flatMap(edition => widths.map(width => [edition, width]));
const all = [];
if (args.page !== '0') {
  const results = await checkPage(browser);
  const failed = results.filter(r => r.result === 'failed');
  console.log(`Stint page: ${results.length} checks, ${failed.length} failed`);
  for (const f of failed) console.log(`  ${f.width}: ${f.control}: ${f.detail}`);
  all.push(...results);
}
let next = 0;
await Promise.all(Array.from({length: Math.min(Number(args.jobs), jobs.length)}, async () => {
  while (next < jobs.length) {
    const [edition, width] = jobs[next++];
    // A job that breaks (its page crashed) fails alone; the others go on.
    const results = await run(browser, edition, width).catch(error => [{edition, width, screen: '(all)',
      control: '(run)', result: 'failed', detail: 'the run broke: ' + error.message.split('\n')[0]}]);
    const failed = results.filter(r => r.result === 'failed');
    console.log(`${edition} ${width}: ${results.length} controls, ${failed.length} failed`);
    for (const f of failed) console.log(`  ${f.screen}: ${f.control}: ${f.detail}`);
    all.push(...results);
  }
}));
await browser.close();
if (args.out) fs.writeFileSync(args.out, JSON.stringify(all, null, 1));
const failures = all.filter(r => r.result === 'failed');
console.log(`${all.length} controls, ${failures.length} failed`);
process.exit(failures.length ? 1 : 0);
