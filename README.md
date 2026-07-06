# Subscription Tracker UI

A pixel-perfect implementation of a Figma subscription-tracker home screen (393×852, iPhone 15 Pro viewport), built with vanilla HTML/CSS/JS — no frameworks, no build step.

**Live demo:** https://subscription-tracker-ui.vercel.app

## Features

- Spend summary with an interactive graph: tap or drag anywhere on the curve (or the dot itself) to scrub between days
- Tap the graph dot to fade the tooltip in/out
- Horizontally scrollable date rail (swipe, drag, or mouse wheel) with tappable dates, while the graph stays fixed
- Upcoming renewals list with an animated expand/collapse subscription card
- UI scales to fit the browser viewport while keeping exact design proportions

## Structure

- `index.html` — markup for the screen
- `styles.css` — all styling, values taken 1:1 from the Figma design
- `app.js` — calendar strip, graph scrubbing, tooltip, and card animations
- `assets/` — original SVG assets exported from the Figma file

## Run locally

Any static file server works, e.g.:

```sh
python3 -m http.server 4604
```

Then open http://localhost:4604.
