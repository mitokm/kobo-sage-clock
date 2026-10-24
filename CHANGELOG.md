# Changelog

All notable changes to Sage Clock are documented here.

## [2.1.0] — 2026-10-24

### Added
- Rotating saying line under the clock: 8 built-in Vietnamese proverbs and
  sayings about time, advancing one step at every 2-minute refresh. The
  rotation is derived from the Unix timestamp (`floor(t / 120) mod 8`), so
  it needs no stored state.
- Menu toggle **Show a saying under the clock** (setting key
  `sageclock_quote`, default on). In stacked layout the digits shrink
  slightly to make room for the saying.

## [2.0.0] — 2026-10-24

### Changed
- Digits are now **hand-drawn pixel glyphs** (5×7 bitmaps painted cell by
  cell) instead of a text font — the look no longer depends on any font
  installed on the device.
- Refresh rhythm changed from every minute to **every 2 minutes**, aligned
  to even-minute boundaries, to save battery and reduce e-ink wear. The
  displayed minute can therefore lag by 1.

### Added
- Stacked layout (hour on the top line, minute on the bottom line) with a
  menu toggle (setting key `sageclock_stacked`).

## [1.0.0] — 2026-10-24

### Added
- First version: full-screen `HH:MM` clock for the Kobo Sage as a KOReader
  plugin, rendered in KOReader's UI font, refreshed every minute, tap or
  swipe to exit, standby/auto-suspend held off while the clock is shown,
  full e-ink refresh every 10 minutes to clear ghosting.
