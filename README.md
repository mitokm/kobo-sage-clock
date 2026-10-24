[English](README.md) · **Tiếng Việt**: [README.vi.md](README.vi.md)

# Kobo Sage Clock

![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)
![Version](https://img.shields.io/badge/version-2.1.0-blue.svg)
![KOReader plugin](https://img.shields.io/badge/KOReader-plugin-orange.svg)
![Device](https://img.shields.io/badge/device-Kobo%20Sage-lightgrey.svg)

Turn a **Kobo Sage** e-reader into a minimal **pixel desk clock**. The plugin
answers exactly one need:

> *My e-reader sits on my desk all day — why does its beautiful e-ink screen
> show nothing useful while idle?*

With Sage Clock running, the whole 1440×1920 screen shows:

1. **The time — hours and minutes only** (`HH:MM`), in giant hand-drawn
   pixel digits you can read from across the room.
2. **One rotating Vietnamese saying about time** underneath, in a small
   regular font — a new one every refresh.
3. **Nothing else.** No date, no seconds, no battery icon, no clutter.

| Single line | Stacked (hour over minute) |
| --- | --- |
| ![Clock, single line layout](docs/preview-ngang.svg) | ![Clock, stacked layout](docs/preview-doc.svg) |

## Gallery

![Sage Clock running on a Kobo Sage](docs/mockup-desk.png)

Every 2 minutes the clock redraws — new time, next saying:

![Time and saying rotation](docs/rotation.gif)

Full-resolution screen captures (1440×1920, exactly as the Sage renders
them): [single line](docs/preview-ngang.png) ·
[stacked](docs/preview-doc.png)

## Quick install

> Full step-by-step guide (Vietnamese, with troubleshooting):
> **[INSTALL.md](INSTALL.md)**

1. Download this repository as a ZIP (**Code → Download ZIP**) and unzip it.
2. Connect the Sage by USB and copy the **`sageclock.koplugin`** folder into
   **`.adds/koreader/plugins/`** on the device.
3. Eject safely, fully restart KOReader, then open
   **Menu ☰ → Tools → Sage Clock → Show clock (tap to exit)**.

Requires a Kobo Sage with **[KOReader](https://koreader.rocks) already
installed**. Tap or swipe anywhere on the clock to exit back to your book.

## The two layouts

| Layout | Digits | Best for |
| --- | --- | --- |
| **Single line** `18:40` | Pixel cell ≈ 52×104 px on the Sage | The classic clock look; leaves room for the saying below |
| **Stacked** — hour on the top line, minute on the bottom | Pixel cell ≈ 123×97 px — digits roughly twice as tall | Reading the time from far away; the saying still fits underneath |

Switch in **Menu → Tools → Sage Clock → Stacked: hour on top, minute below**.

## The rotating sayings

Every refresh, the line under the clock advances to the next saying in this
built-in list of Vietnamese proverbs and sayings about time:

| # | Saying | Rough meaning |
| --- | --- | --- |
| 1 | Thời gian là vàng bạc. | Time is gold and silver. |
| 2 | Việc hôm nay chớ để ngày mai. | Never put off today's work until tomorrow. |
| 3 | Chậm mà chắc. | Slow but sure. |
| 4 | Có công mài sắt, có ngày nên kim. | Grind an iron bar long enough and it becomes a needle — persistence pays. |
| 5 | Thì giờ thấm thoắt thoi đưa. | Time flies by like a weaver's shuttle. |
| 6 | Thời gian như bóng câu qua cửa sổ. | Time is like a colt's shadow passing the window. |
| 7 | Sông có khúc, người có lúc. | Rivers have bends, people have their moments. |
| 8 | Mỗi phút giây là một khởi đầu mới. | Every minute is a new beginning. |

The rotation needs no state: the plugin picks
`floor(unix_time / 120) mod 8`, so the saying changes exactly when the clock
redraws, and any two devices running Sage Clock show the same saying at the
same moment. Turn the line off in
**Menu → Tools → Sage Clock → Show a saying under the clock** if you want the
bare clock back.

## How it works

### Why a plugin, and not the stock sleep screen?

The stock Kobo sleep screen is a **static image**, and in deep sleep the CPU
is fully stopped — so no sleep-screen image can ever update itself. Sage
Clock runs inside KOReader and **keeps the device awake**, redrawing the
e-ink panel on a schedule. On show, it asks KOReader to prevent standby and
stop auto-suspend (via `UIManager:preventStandby()` /
`UIManager:stopAutoSuspend()`, each wrapped in `pcall` so a KOReader version
without one of them cannot crash the plugin); on close, it releases both.

### Refresh schedule

- The next redraw is scheduled with `UIManager:scheduleIn()` for the **next
  even-minute boundary**: `delay = 120 − (now mod 120) + 1` seconds (the
  extra second makes sure the system clock has actually flipped).
- At each tick the plugin rebuilds the widget only if the `HH:MM` text
  changed, and requests a normal (`ui`) refresh — except **every 10th change
  (20 minutes)**, which requests a **full refresh** to clear e-ink ghosting.
- Consequence, by design: **the displayed time can lag by up to 1 minute**,
  because odd minutes are never shown.

### Pixel digits

Digits are not a font. Each glyph is a hard-coded **5 columns × 7 rows**
bitmap (`#` = filled square, `:` is 2 columns wide) in the `GLYPHS` table in
`main.lua`, painted cell by cell with `Blitbuffer:paintRect()`. Nothing
depends on fonts installed on the device, and the look is identical on every
unit. Cell size is computed from the actual screen size:

- Single line: `cell_w = floor(screen_w × 0.94 / 26)` (26 = total columns of
  `HH:MM` including spacing), `cell_h = min(floor(screen_h × 0.55 / 7), 2 × cell_w)`.
- Stacked: `cell_w = floor(screen_w × 0.94 / 11)`,
  `cell_h = floor(screen_h × 0.76 / 15)` with sayings on (`0.90` with them off).

## Configuration

There is no config file — the two options live in KOReader's settings and
are toggled from **Menu → Tools → Sage Clock**:

| Menu option | Setting key | Default | Effect |
| --- | --- | --- | --- |
| Stacked: hour on top, minute below | `sageclock_stacked` | off | Switches between the single-line and stacked layouts |
| Show a saying under the clock | `sageclock_quote` | **on** | Shows/hides the rotating saying line |

Both take effect the next time the clock is opened.

## Battery & trade-offs

- The CPU stays awake the whole time the clock is shown, so battery drain is
  **far higher than deep sleep** — the e-ink redraws themselves (one partial
  refresh every 2 minutes) are the cheap part. Real-world drain has not been
  measured yet on a Sage; reports via Issues are welcome.
- For desk-clock or overnight use, **keep the Sage plugged into USB-C**.
- Front light is left exactly as you set it in KOReader — turn it off for
  the purest e-ink look, or keep a low warm light for a night clock.
- Exiting the clock (tap/swipe) restores normal KOReader sleep behaviour
  immediately.

## Project structure

```
kobo-sage-clock/
├─ README.md                  ← you are here (English)
├─ README.vi.md               ← Vietnamese guide
├─ INSTALL.md                 ← detailed installation, Vietnamese
├─ CHANGELOG.md
├─ LICENSE                    ← MIT
├─ docs/
│  ├─ preview-ngang.svg       ← single-line layout preview (vector)
│  ├─ preview-doc.svg         ← stacked layout preview (vector)
│  ├─ preview-ngang.png       ← full-resolution capture, single line (1440×1920)
│  ├─ preview-doc.png         ← full-resolution capture, stacked
│  ├─ mockup-desk.png         ← device mockup
│  └─ rotation.gif             ← animation: time + saying rotation
└─ sageclock.koplugin/        ← copy this folder to .adds/koreader/plugins/
   ├─ _meta.lua               ← plugin metadata (name, version)
   └─ main.lua                ← the whole plugin: glyphs, widget, scheduler
```

## Development

The plugin is a single self-contained Lua file with no dependencies beyond
KOReader itself.

- **Syntax-check** (LuaJIT is KOReader's runtime):
  `luajit -bl sageclock.koplugin/main.lua`
- **Change the refresh rhythm:** edit the `120` in
  `ClockWidget:scheduleTick()` (`delay = 120 − (now_s % 120) + 1`) *and* the
  matching `120` in `currentQuote()`, so the saying stays in sync.
- **Edit or add sayings:** edit the `QUOTES` table near the top of
  `main.lua`. Keep them short — long sayings wrap onto a second line and
  shrink the digits in stacked layout.
- **Restyle the digits:** edit the `GLYPHS` bitmaps (5×7 per digit, `:` is
  2 columns wide).
- After any change, copy `sageclock.koplugin` to the device again and fully
  restart KOReader.

## Known limitations

- Shows **hours and minutes only**, by design — no seconds, no date, and
  (with the 2-minute rhythm) the minute can be 1 behind real time.
- Not a true sleep screen: it only runs while KOReader is in the foreground
  and the clock has been opened. Pressing the power button still puts the
  device to sleep with the normal Kobo/KOReader sleep screen.
- Designed and tuned for the Sage's 1440×1920 screen; other Kobo models
  should work (sizes are computed from the real screen) but are untested.
- Sayings are Vietnamese only in this version.
- Battery drain in clock mode has not been measured yet.

## Troubleshooting

| Symptom | Fix |
| --- | --- |
| No **Sage Clock** entry in the Tools menu | KOReader was not fully restarted after copying, or the folder is in the wrong place — the path must be `.adds/koreader/plugins/sageclock.koplugin/main.lua` |
| Clock shows the wrong time | Fix the system time/time zone in the **Kobo's** Settings → Date and time (not in KOReader) |
| Clock is 1 minute behind | By design — it refreshes on even minutes only |
| Saying line missing | The toggle **Show a saying under the clock** is off — turn it on and reopen the clock |
| KOReader crashes/errors when opening the clock | Grab `crash.log` from `.adds/koreader` and open an Issue with it attached |
| Digits look ghosted after hours | Normal e-ink behaviour; the plugin already does a full refresh every 20 minutes — exiting and reopening the clock also forces one |

## Status & version

- **Version 2.1.0** — rotating sayings added (see [CHANGELOG.md](CHANGELOG.md)).
- Syntax-checked with LuaJIT 2.1; **not yet long-term tested on real Sage
  hardware**. Test reports and bug reports via Issues are very welcome.

## License

MIT — see [LICENSE](LICENSE).
