# Segment34 MkIII
A watchface for Garmin watches with a 34 Segment display, forked from [Segment34 MkII](https://github.com/ludw/Segment34mkII) after [PR #76](https://github.com/ludw/Segment34mkII/pull/76) was rejected.

![Screenshot of the watchface](screenshot.png "Screenshot")

The watchface features the following:

- Time displayed with a 34 segment display
- Phase of the moon with graphic display
- Heartrate or Respiration rate
- Weather (conditions, temperature and windspeed)
- Sunrise/Sunset
- Date
- Notification count
- Configurable: Active minutes / Distance / Floors / Time to Recovery / VO2 Max
- Configurable: Steps / Calories / Distance
- Battery days remaining (or percentage on some watches)
- Always on mode
- Settings in the Garmin app


## Frequently Asked Questions
https://github.com/Rubilmax/Segment34mkIII/blob/main/FAQ.md

## IQ Store Listing
https://apps.garmin.com/apps/38417f58-d9a2-4d76-a10d-ad2263acdf6b

## Contributing (code)
Pull requests are welcome, but please follow the following guidelines:
- For larger changes, **please open an issue first** and discuss what you have in mind.
- Keep PRs small, don't do a lot of different changes at once.
- Explain what you have changed and why.
- Only submit code you have actually run and tested (on all supported screen sizes).
- Remeber that watch faces has to be performant and memory efficient.
  Changes that significantly increase memory use or degrade performance will be rejected.
- For optimizations, please provide memory and profiler comparisons.
- Try to keep the code in the same style as the rest of the project.
   - Indent with four spaces.
   - local variables with snake_case.
   - function and global variables names with camelCase.
   - cache all properties.
   - use comments only when they add value.
     Explain things that look strange or values that has to be looked up to be understood.

 ## TODO / Things people have asked for
- Adjustable font size
- Goal completion marker
- Pressure trend
- Monthly run/bike distance
- Notifications as icon
- 7 day rolling run distance
- Line font for bottom fields
- AM/PM indicator
- clock font without segments
- separate 24h mode for alt tz
- Configurable data for the notification field, week number and other short info could work
- Second custom theme for easy switching
