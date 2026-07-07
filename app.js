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

// ---- Graph model ----
// Cumulative spend curve for the whole month in the design's plot units:
// x in day-space, y within the 137px-tall plot (lower y = higher spend).
// Days 17.3-23 keep the exact vertex geometry of the Figma curve, so the
// default window (18-23) renders pixel-identical to the design.
const CURVE_VERTICES = [
  [1, 132], [2, 127], [3, 128.5], [4, 121], [5, 116], [6, 117.5],
  [7, 110], [8, 112], [9, 104], [10, 106], [11, 99], [12, 101],
  [13, 95], [14, 97], [15, 108], [16, 122], [17, 134],
  [17.325, 136.546], [17.494, 136.546], [18.008, 116.975], [18.417, 116.975],
  [19.008, 61.72], [20.008, 55.7515], [23.008, 0.478],
  [24, -6], [25, -20], [26, -45], [27, -49], [28, -63], [29, -67], [30, -77], [31, -83],
];

function rawY(d) {
  const v = CURVE_VERTICES;
  if (d <= v[0][0]) return v[0][1];
  for (let i = 1; i < v.length; i++) {
    if (d <= v[i][0]) {
      const [a, ya] = v[i - 1];
      const [b, yb] = v[i];
      return ya + ((d - a) / (b - a)) * (yb - ya);
    }
  }
  return v[v.length - 1][1];
}

// Daily spend deltas; days 18-23 keep the design's values
const DAY_INFO = {
  1: ['+$2.99', '(+2%)'], 2: ['+$1.49', '(+1%)'], 3: ['+$4.99', '(+3%)'],
  4: ['+$0.99', '(+1%)'], 5: ['+$7.99', '(+4%)'], 6: ['+$2.49', '(+1%)'],
  7: ['+$5.99', '(+3%)'], 8: ['+$1.99', '(+1%)'], 9: ['+$9.99', '(+5%)'],
  10: ['+$3.49', '(+2%)'], 11: ['+$6.99', '(+3%)'], 12: ['+$2.99', '(+1%)'],
  13: ['+$8.49', '(+4%)'], 14: ['+$4.49', '(+2%)'], 15: ['+$10.99', '(+5%)'],
  16: ['+$3.99', '(+2%)'], 17: ['+$5.49', '(+2%)'],
  18: ['+$4.20', '(+2%)'], 19: ['+$18.50', '(+8%)'], 20: ['+$2.99', '(+1%)'],
  21: ['+$11.99', '(+5%)'], 22: ['+$8.00', '(+3%)'], 23: ['+$25.00', '(+1%)'],
  24: ['+$2.99', '(+1%)'], 25: ['+$8.00', '(+3%)'], 26: ['+$25.00', '(+9%)'],
  27: ['+$1.99', '(+1%)'], 28: ['+$11.99', '(+4%)'], 29: ['+$3.49', '(+1%)'],
  30: ['+$8.00', '(+3%)'], 31: ['+$5.99', '(+2%)'],
};

// ---- Sliding chart window ----
// The plot shows a 6-day window; day d of window starting at s is centered
// at x = (d - s) * 60 + 41. Selecting a date outside the window slides the
// whole curve so the marker always lands on the selected date.
const WINDOW_LAST = 26; // latest possible windowStart (26..31)
let windowStart = 18;
let currentDay = 23;
let offsetNow = 18; // animated fractional window position

const dot = document.querySelector('.graph-dot');
const tooltip = document.querySelector('.graph-tooltip');
const tooltipDate = document.querySelector('.tooltip-date');
const tooltipAmount = document.querySelector('.tooltip-amount');
const tooltipPercent = document.querySelector('.tooltip-percent');
const vline = document.querySelector('.vline');
const plotHit = document.querySelector('.plot-hit');
const curveLine = document.querySelector('.curve-line');
const curveArea = document.querySelector('.curve-area');

const TOOLTIP_W = 110;
const TOOLTIP_H = 56;
const STRIP_TOP = 269;

const xFor = (d, o) => (d - o) * 60 + 41;

// Normalize the visible stroke segment into the design's vertical range so
// the default window maps 1:1 and other windows fill the plot sensibly.
function normBounds(o) {
  let lo = Infinity, hi = -Infinity;
  for (let d = o - 0.6833; d <= o + 5.0167; d += 0.05) {
    const y = rawY(d);
    if (y < lo) lo = y;
    if (y > hi) hi = y;
  }
  return { hi, span: Math.max(hi - lo, 20) };
}
const normY = (y, b) => 136.546 - (b.hi - y) * (136.068 / b.span);

function samplePoints(from, to) {
  const pts = [[from, rawY(from)]];
  for (const [vd, vy] of CURVE_VERTICES) {
    if (vd > from && vd < to) pts.push([vd, vy]);
  }
  pts.push([to, rawY(to)]);
  return pts;
}

function renderCurve(o) {
  const b = normBounds(o);
  const linePts = samplePoints(o - 0.6833, o + 5.0167);
  const line = 'M' + linePts
    .map(p => `${xFor(p[0], o).toFixed(2)} ${normY(p[1], b).toFixed(2)}`)
    .join(' L');
  // area fill continues to the right edge of the plot, like the design
  const areaPts = samplePoints(o - 0.6833, o + 5.8667);
  const area = 'M' + areaPts
    .map(p => `${xFor(p[0], o).toFixed(2)} ${normY(p[1], b).toFixed(2)}`)
    .join(' L') + ' L393 137 L0 137 Z';
  curveLine.setAttribute('d', line);
  curveArea.setAttribute('d', area);
  return b;
}

function markerY(day, b) {
  // day vertices sit at d+0.008 (the design's half-pixel offset)
  return normY(rawY(Math.min(day + 0.008, 31)), b);
}

function setMarkerPositions(o, b) {
  const x = xFor(currentDay, o);
  const dotTop = 122 + markerY(currentDay, b);
  dot.style.left = (x - 10) + 'px';
  dot.style.top = dotTop + 'px';
  vline.style.left = x + 'px';

  const below = dotTop + 28;
  const top = below + TOOLTIP_H > STRIP_TOP ? dotTop - 8 - TOOLTIP_H : below;
  const left = Math.min(263, Math.max(10, x - 78));
  tooltip.style.left = left + 'px';
  tooltip.style.top = top + 'px';
}

// ---- Window slide animation ----
let slideRaf = null;

function animateWindow(target) {
  if (slideRaf) cancelAnimationFrame(slideRaf);
  const from = offsetNow;
  const start = performance.now();
  const DUR = 250;
  const easeInOut = t => (t < 0.5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2);
  [dot, vline, tooltip].forEach(el => el.classList.add('no-trans'));
  const step = now => {
    const t = Math.min((now - start) / DUR, 1);
    offsetNow = from + (target - from) * easeInOut(t);
    const b = renderCurve(offsetNow);
    setMarkerPositions(offsetNow, b);
    if (t < 1) {
      slideRaf = requestAnimationFrame(step);
    } else {
      offsetNow = target;
      slideRaf = null;
      [dot, vline, tooltip].forEach(el => el.classList.remove('no-trans'));
    }
  };
  slideRaf = requestAnimationFrame(step);
}

function setDay(day) {
  if (day === currentDay) return;
  currentDay = day;

  tooltipDate.textContent = day + ' Jun 2026';
  tooltipAmount.textContent = DAY_INFO[day][0];
  tooltipPercent.textContent = DAY_INFO[day][1];
  buildStrip(day);

  // slide the window so the selected date sits at its right edge,
  // matching the design's default (day 23 at the end of the chart)
  let ns = windowStart;
  if (day < ns || day > ns + 5) {
    ns = Math.min(Math.max(day - 5, 1), WINDOW_LAST);
  }

  if (ns !== windowStart) {
    windowStart = ns;
    // keep the date rail aligned with the chart window
    scroller.scrollTo({ left: (ns - 1) * 60 - 7, behavior: 'smooth' });
    animateWindow(ns);
  } else {
    // marker glides via its CSS transitions
    const b = renderCurve(offsetNow);
    setMarkerPositions(offsetNow, b);
  }
}

function pickDay(clientX) {
  const rect = plotHit.getBoundingClientRect();
  // the screen is scaled to fit the viewport: convert the click position
  // from screen pixels back into the design's 393px coordinate space
  const scale = rect.width / 393;
  const x = (clientX - rect.left) / scale;
  const k = Math.min(Math.max(Math.round((x - 41) / 60), 0), 5);
  setDay(windowStart + k);
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
// The dates scroll horizontally; tapping any date selects it and the chart
// window slides so the marker lands on that date.
const scroller = document.querySelector('.date-scroll');

// Start scrolled so days 18-23 sit exactly where the design places them
scroller.scrollLeft = (windowStart - 1) * 60 - 7;

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

// initial render (identical to the design)
setMarkerPositions(offsetNow, renderCurve(offsetNow));

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
