# Segment34Plus

A watchface for Garmin watches with a 34-segment display, forked from [Segment34 MkII](https://github.com/ludw/Segment34mkII) after [PR #76](https://github.com/ludw/Segment34mkII/pull/76) was rejected.

![Screenshot of the watchface](screenshot.png "Screenshot")

## Features

- Time displayed with a 34-segment display
- Phase of the moon with graphic display
- Heartrate or Respiration rate
- Weather (conditions, temperature, windspeed, precipitation, UV index, humidity)
- Wind / Precip / UV / Humidity combo line option with icons
- Sunrise / Sunset
- Date
- Notification count
- Configurable: Active minutes / Distance / Floors / Time to Recovery / VO2 Max
- Configurable: Steps / Calories / Distance
- Battery days remaining (or percentage on some watches)
- Always-on mode
- Settings in the Garmin app

## Improvements over Segment34 MkII

### New functionality

- **Wind / Precip / UV / Humidity line option** with dedicated icons for weather line 1
- **Humidity icon** added to the icon set
- **Redesigned font icons** to better match the LED segment style
- **Improved default settings** for a better out-of-box experience
- **Altitude labels** renamed to `ALT (M)` / `ALT (FT)` format

### Performance (2x faster `drawWatchface`)

The rendering pipeline has been heavily optimized to cut per-frame work in half:

- **Single data fetch per frame** — `ActivityMonitor.getInfo()`, `System.getSystemStats()`, and `Gregorian.info()` are called once and passed through, eliminating dozens of redundant system calls
- **Cached string resources** — unit strings (`KCAL`, `M`, `FT`, `STEPS`, etc.) are loaded once at init instead of hitting flash storage every frame
- **Pre-computed background strings** — background fill strings are built once at startup instead of concatenated per field per frame
- **Cached weather condition resource IDs** — the 54-element weather condition array is allocated once instead of every frame
- **Lazy-cached sensor data** — stress and body battery queries (Complications API + SensorHistory iterators) are cached per frame, avoiding redundant lookups when configured in multiple slots
- **AMOLED pattern caching** — the burn-in protection pattern string and row count are computed once instead of every draw call
- **Cached field widths** — bottom field width calculations reuse a stored array instead of recomputing on every update

## FAQ

https://github.com/Rubilmax/Segment34Plus/blob/main/FAQ.md

## IQ Store Listing

https://apps.garmin.com/apps/38417f58-d9a2-4d76-a10d-ad2263acdf6b

## Contributing

Pull requests are welcome, but please follow these guidelines:

- For larger changes, **please open an issue first** and discuss what you have in mind.
- Keep PRs small, don't do a lot of different changes at once.
- Explain what you have changed and why.
- Only submit code you have actually run and tested (on all supported screen sizes).
- Remember that watch faces have to be performant and memory efficient.
  Changes that significantly increase memory use or degrade performance will be rejected.
- For optimizations, please provide memory and profiler comparisons.
- Try to keep the code in the same style as the rest of the project:
  - Indent with four spaces.
  - Local variables with snake_case.
  - Function and global variable names with camelCase.
  - Cache all properties.
  - Use comments only when they add value.
