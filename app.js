// Scale the screen so the full 393x852 UI always fits the viewport
function fitToScreen() {
  const scale = Math.min(
    (window.innerWidth - 32) / 393,
    (window.innerHeight - 32) / 852
  );
  document.documentElement.style.setProperty('--fit-scale', Math.max(scale, 0.1));
}
window.addEventListener('resize', fitToScreen);
fitToScreen();

// Build the calendar day strip (days 1-31)
const strip = document.querySelector('.date-strip');

function buildStrip(activeDay) {
  strip.innerHTML = '';
  for (let day = 1; day <= 31; day++) {
    const cell = document.createElement('div');
    cell.className = 'day-cell';
    cell.dataset.day = day;
    if (day === activeDay) {
      cell.classList.add('active');
      const pill = document.createElement('div');
      pill.className = 'day-pill';
      const text = document.createElement('div');
      text.className = 'day-text';
      text.textContent = day;
      pill.appendChild(text);
      cell.appendChild(pill);
    } else {
      const text = document.createElement('div');
      text.className = 'day-text';
      text.textContent = day;
      cell.appendChild(text);
    }
    strip.appendChild(cell);
  }
}
buildStrip(23);

// ---- Interactive graph annotation ----
// Polyline of the spend curve (graph-line.svg path), relative to the
// graph container: x from left edge, y offset from top 132px.
const CURVE = [
  [0.5, 136.546], [10.6845, 136.546], [41.5, 116.975], [66, 116.975],
  [101.5, 61.72], [161.5, 55.7515], [341.5, 0.478],
];

function curveY(x) {
  if (x <= CURVE[0][0]) return CURVE[0][1];
  for (let i = 1; i < CURVE.length; i++) {
    const [x0, y0] = CURVE[i - 1];
    const [x1, y1] = CURVE[i];
    if (x <= x1) return y0 + ((x - x0) / (x1 - x0)) * (y1 - y0);
  }
  return CURVE[CURVE.length - 1][1];
}

// Daily spend deltas for the days visible on the graph (18-23 June).
// Day 23 keeps the exact values from the design.
const DAY_INFO = {
  18: { amount: '+$4.20', percent: '(+2%)' },
  19: { amount: '+$18.50', percent: '(+8%)' },
  20: { amount: '+$2.99', percent: '(+1%)' },
  21: { amount: '+$11.99', percent: '(+5%)' },
  22: { amount: '+$8.00', percent: '(+3%)' },
  23: { amount: '+$25.00', percent: '(+1%)' },
};

// Calendar strip geometry: day d's cell center lands at x = (d-1)*60 - 979
const dayX = d => (d - 1) * 60 - 979;
const DAYS = Object.keys(DAY_INFO).map(Number);

const dot = document.querySelector('.graph-dot');
const tooltip = document.querySelector('.graph-tooltip');
const tooltipDate = document.querySelector('.tooltip-date');
const tooltipAmount = document.querySelector('.tooltip-amount');
const tooltipPercent = document.querySelector('.tooltip-percent');
const vline = document.querySelector('.vline');
const plotHit = document.querySelector('.plot-hit');

const TOOLTIP_W = 110;
const TOOLTIP_H = 56;
const STRIP_TOP = 269;

let currentDay = 23;

function setDay(day) {
  if (day === currentDay) return;
  currentDay = day;

  // Days outside the charted 18-23 window aren't on the visible curve:
  // move the highlight pill but fade out the dot, line, and tooltip
  if (!(day in DAY_INFO)) {
    dot.style.opacity = '0';
    dot.style.pointerEvents = 'none';
    vline.style.opacity = '0';
    tooltip.classList.remove('show');
    buildStrip(day);
    return;
  }
  dot.style.opacity = '';
  dot.style.pointerEvents = '';
  vline.style.opacity = '';

  const x = dayX(day);
  // Day 23 uses the exact dot position from the design; others follow the curve
  const dotTop = day === 23 ? 122 : 122 + curveY(x);

  dot.style.left = (x - 10) + 'px';
  dot.style.top = dotTop + 'px';
  vline.style.left = x + 'px';

  // Tooltip sits below the dot unless it would collide with the date strip
  const below = dotTop + 28;
  const top = below + TOOLTIP_H > STRIP_TOP ? dotTop - 8 - TOOLTIP_H : below;
  const left = Math.min(263, Math.max(10, x - 78));
  tooltip.style.left = left + 'px';
  tooltip.style.top = top + 'px';

  tooltipDate.textContent = day + ' Jun 2026';
  tooltipAmount.textContent = DAY_INFO[day].amount;
  tooltipPercent.textContent = DAY_INFO[day].percent;

  buildStrip(day);
}

function pickDay(clientX) {
  const rect = plotHit.getBoundingClientRect();
  // the screen is scaled to fit the viewport: convert the click position
  // from screen pixels back into the design's 393px coordinate space
  const scale = rect.width / 393;
  const x = (clientX - rect.left) / scale;
  let nearest = DAYS[0];
  for (const d of DAYS) {
    if (Math.abs(dayX(d) - x) < Math.abs(dayX(nearest) - x)) nearest = d;
  }
  setDay(nearest);
}

// The dot is both tappable and draggable: a plain tap shows/hides the
// tooltip, while dragging past a small threshold scrubs across the days.
const DRAG_THRESHOLD = 3;
let dotDrag = null;

dot.addEventListener('pointerdown', e => {
  dotDrag = { startX: e.clientX, moved: false };
  dot.setPointerCapture(e.pointerId);
  e.stopPropagation();
});
dot.addEventListener('pointermove', e => {
  if (!dotDrag) return;
  if (Math.abs(e.clientX - dotDrag.startX) > DRAG_THRESHOLD) dotDrag.moved = true;
  if (dotDrag.moved) pickDay(e.clientX);
});
dot.addEventListener('pointerup', () => {
  if (!dotDrag) return;
  if (!dotDrag.moved) tooltip.classList.toggle('show');
  dotDrag = null;
});
dot.addEventListener('pointercancel', () => { dotDrag = null; });

let scrubbing = false;
plotHit.addEventListener('pointerdown', e => {
  scrubbing = true;
  plotHit.setPointerCapture(e.pointerId);
  pickDay(e.clientX);
});
plotHit.addEventListener('pointermove', e => {
  if (scrubbing) pickDay(e.clientX);
});
plotHit.addEventListener('pointerup', () => { scrubbing = false; });
plotHit.addEventListener('pointercancel', () => { scrubbing = false; });

// ---- Scrollable date rail ----
// The graph stays fixed; only the dates scroll horizontally. Native touch
// swipe works via overflow scrolling; mouse users can drag the rail; taps
// on a date select it (suppressed if the gesture was a drag).
const scroller = document.querySelector('.date-scroll');

// Start scrolled so days 18-23 sit exactly where the design places them
scroller.scrollLeft = 1013;

let railDrag = null;
scroller.addEventListener('pointerdown', e => {
  railDrag = { startX: e.clientX, startScroll: scroller.scrollLeft, moved: false };
});
scroller.addEventListener('pointermove', e => {
  if (!railDrag) return;
  const rect = scroller.getBoundingClientRect();
  const scale = rect.width / 393;
  const dx = (e.clientX - railDrag.startX) / scale;
  if (Math.abs(dx) > DRAG_THRESHOLD) {
    railDrag.moved = true;
    scroller.classList.add('dragging');
    scroller.setPointerCapture(e.pointerId);
  }
  if (railDrag.moved) scroller.scrollLeft = railDrag.startScroll - dx;
});
const endRailDrag = () => {
  if (railDrag && !railDrag.moved) railDrag.tapped = true;
  scroller.classList.remove('dragging');
};
scroller.addEventListener('pointerup', e => {
  if (railDrag && !railDrag.moved) {
    const cell = e.target.closest('.day-cell');
    if (cell) setDay(Number(cell.dataset.day));
  }
  endRailDrag();
  railDrag = null;
});
scroller.addEventListener('pointercancel', () => { endRailDrag(); railDrag = null; });

// Let vertical mouse wheels scroll the rail horizontally
scroller.addEventListener('wheel', e => {
  if (Math.abs(e.deltaY) > Math.abs(e.deltaX)) {
    scroller.scrollLeft += e.deltaY;
    e.preventDefault();
  }
}, { passive: false });

// Toggle the iCloud+ card between collapsed and expanded states,
// animating height and cross-fading content with ease-in-out
const collapsed = document.querySelector('.icloud-collapsed');
const expanded = document.querySelector('.icloud-expanded');
const toggleWrap = document.querySelector('.card-toggle');
let animating = false;

function swap(from, to) {
  if (animating) return;
  animating = true;

  const startHeight = toggleWrap.offsetHeight;
  from.hidden = true;
  to.hidden = false;
  const endHeight = to.offsetHeight;

  toggleWrap.style.height = startHeight + 'px';
  to.style.opacity = '0';
  toggleWrap.offsetHeight; // flush styles so the transition has a starting point

  requestAnimationFrame(() => {
    toggleWrap.style.height = endHeight + 'px';
    to.style.opacity = '1';
  });

  toggleWrap.addEventListener('transitionend', function done(e) {
    if (e.propertyName !== 'height') return;
    toggleWrap.style.height = '';
    to.style.opacity = '';
    toggleWrap.removeEventListener('transitionend', done);
    animating = false;
  });
}

collapsed.addEventListener('click', () => swap(collapsed, expanded));
expanded.querySelector('.chevron-container').addEventListener('click', () => swap(expanded, collapsed));
