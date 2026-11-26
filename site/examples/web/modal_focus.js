// A browser can traverse out of an embedded Flutter view at its DOM edge.
// Keep native Tab traversal inside the semantic dialog while its route is up.
window.addEventListener('keydown', event => {
  if (event.key !== 'Tab' || event.altKey || event.metaKey || event.ctrlKey) return;
  const modal = [...document.querySelectorAll('[role="dialog"], [role="alertdialog"]')].at(-1);
  if (!modal) return;
  const stops = [...modal.querySelectorAll('[tabindex], button, input, select, textarea, a[href]')]
    .filter(node => node.tabIndex >= 0 && !node.disabled && node.getAttribute('aria-disabled') !== 'true');
  if (!stops.length) return;
  const first = stops[0];
  const last = stops[stops.length - 1];
  const current = document.activeElement;
  if (!modal.contains(current) || current === (event.shiftKey ? first : last)) {
    event.preventDefault();
    event.stopImmediatePropagation();
    (event.shiftKey ? last : first).focus({preventScroll: true});
  }
}, true);
