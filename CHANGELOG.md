# Changelog

All notable changes to Sage Clock are documented here.

## [2.4.0] \u2014 2026-10-24

### Added
- **Adjustable refresh interval**: a "Nh\u1ecbp nh\u1ea3y gi\u1edd" (time step)
  submenu in the plugin menu, 1\u201310 minutes between display updates
  (setting key `sageclock_interval`, default 2). Longer intervals save
  battery and e-ink wear; the saying line rotates with the same rhythm.
  Note: the displayed time can lag real time by up to interval\u22121
  minutes \u2014 that is the trade-off of a slow-refresh desk clock.

## [2.3.0] \u2014 2026-10-24

### Added
- **Display size setting** in the plugin menu: Small / Medium / Large,
  scaling both the pixel digits and the quote text (setting key
  `sageclock_size`, default Medium). Medium is noticeably smaller than
  the old fixed layout, with comfortable margins \u2014 feedback from the
  first on-device test.
- **OTA self-update**: a menu item downloads the latest `main.lua` /
  `_meta.lua` from this repo over Wi-Fi and keeps a `.bak` backup \u2014
  no PC needed for future updates.
- Current version shown as a row in the plugin menu.

### Changed
- Exit is now a **double-tap** (two taps within 0.6 s), so an accidental
  touch no longer closes the clock; swiping still exits.
- Full e-ink refresh every 5 changes (10 minutes) instead of every 10,
  for less ghosting.

## [2.2.0] — 2026-10-24

### Changed
- The saying library grows from 8 to **80 quotes**: Vietnamese proverbs,
  folk sayings and ca dao about time, plus classic English aphorisms
  (Franklin, Gandhi, Ali, Horace…). A full rotation now takes 160 minutes.

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
