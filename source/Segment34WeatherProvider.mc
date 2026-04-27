import Toybox.Application;
import Toybox.Background;
import Toybox.Lang;
import Toybox.Position;
import Toybox.System;
import Toybox.Time;
import Toybox.Weather;
using Toybox.Position;

// The background weather service and the foreground watch face share this helper
// surface, so every exported weather-provider symbol must be linked into the
// background process explicitly.
(:background)
const WEATHER_PROVIDER_GARMIN = 0;
(:background)
const WEATHER_PROVIDER_OPEN_METEO = 1;
(:background)
const WEATHER_PROVIDER_STATE_KEY = "weather_provider_state_v1";
(:background)
const WEATHER_SNAPSHOT_KEY = "weather_snapshot_v2";
(:background)
const WEATHER_PROVIDER_LEGACY_GARMIN_LOCATION_KEY = "garmin_weather_location_v1";
(:background)
const WEATHER_PROVIDER_OPEN_METEO_NAME = "open_meteo_best_match";
(:background)
const WEATHER_SNAPSHOT_VERSION = 2;
(:background)
const WEATHER_PROVIDER_FETCH_INTERVAL_S = 1800;
(:background)
const WEATHER_PROVIDER_STALE_AFTER_S = 28800;
(:background)
const WEATHER_PROVIDER_IMMEDIATE_GUARD_S = 300;
(:background)
const WEATHER_PROVIDER_HOURLY_FORECAST_LIMIT = 32;
// A 32-hour hourly window can spill into a third local calendar day late in the day.
(:background)
const WEATHER_PROVIDER_FORECAST_DAYS = 3;
(:background)
const WEATHER_PROVIDER_LOCATION_SOURCE_DEVICE = "device";
(:background)
const WEATHER_PROVIDER_LOCATION_SOURCE_GARMIN_CACHE = "garmin_cache";
(:background)
const WEATHER_PROVIDER_LOCATION_SOURCE_UNAVAILABLE = "unavailable";
(:background)
const WEATHER_PROVIDER_ERROR_LOCATION_UNAVAILABLE = "Location unavailable";
(:background)
const WEATHER_PROVIDER_ERROR_INVALID_RESPONSE = "Invalid response";
(:background)
const WEATHER_PROVIDER_ERROR_REQUEST_FAILED = "Request failed";
(:background)
const WEATHER_PROVIDER_OPEN_METEO_URL = "https://api.open-meteo.com/v1/forecast";
(:background)
const WEATHER_PROVIDER_BACKGROUND_PAYLOAD_VERSION = 1;
(:background)
const WEATHER_PROVIDER_BACKGROUND_RESULT_SUCCESS = 0;
(:background)
const WEATHER_PROVIDER_BACKGROUND_RESULT_LOCATION_UNAVAILABLE = 1;
(:background)
const WEATHER_PROVIDER_BACKGROUND_RESULT_INVALID_RESPONSE = 2;
(:background)
const WEATHER_PROVIDER_BACKGROUND_RESULT_REQUEST_FAILED = 3;

(:background)
function weatherProviderGetSelection() as Number {
    var provider = Application.Properties.getValue("weatherProvider");
    if (provider == null) { return WEATHER_PROVIDER_GARMIN; }
    return provider as Number;
}

(:background)
function weatherProviderUsesOpenMeteo() as Boolean {
    return weatherProviderGetSelection() == WEATHER_PROVIDER_OPEN_METEO;
}

(:background)
function weatherProviderGetPropertyOrDefault(key as String, defaultValue) {
    var value = Application.Properties.getValue(key);
    if (value == null) { return defaultValue; }
    return value;
}

(:background)
function weatherProviderIsWeatherSourceId(id as Number) as Boolean {
    if (id == 20 || id == 39 || id == 40 || (id >= 43 && id <= 55) || (id >= 63 && id <= 79)) {
        return true;
    }
    return false;
}

(:background)
function weatherProviderPropertyNeedsWeather(key as String, defaultValue as Number) as Boolean {
    return weatherProviderIsWeatherSourceId(weatherProviderGetPropertyOrDefault(key, defaultValue) as Number);
}

(:background)
function weatherProviderIsWeatherRequired() as Boolean {
    if (weatherProviderPropertyNeedsWeather("sunriseFieldShows", 39)) { return true; }
    if (weatherProviderPropertyNeedsWeather("sunsetFieldShows", 40)) { return true; }
    if (weatherProviderPropertyNeedsWeather("weatherLine1Shows", 78)) { return true; }
    if (weatherProviderPropertyNeedsWeather("weatherLine2Shows", 79)) { return true; }
    if (weatherProviderPropertyNeedsWeather("dateFieldShows", -1)) { return true; }
    if (weatherProviderPropertyNeedsWeather("bottomFieldShows", 17)) { return true; }
    if (weatherProviderPropertyNeedsWeather("aodFieldShows", -1)) { return true; }
    if (weatherProviderPropertyNeedsWeather("aodRightFieldShows", -2)) { return true; }
    if (weatherProviderPropertyNeedsWeather("bottomField2Shows", -2)) { return true; }
    if (weatherProviderPropertyNeedsWeather("notificationCountShows", 14)) { return true; }

    var touchAlternativeActive = weatherProviderGetPropertyOrDefault("touchAlternativeActive", false) as Boolean;
    if (touchAlternativeActive) {
        if (weatherProviderPropertyNeedsWeather("touchAlternativeLeftValueShows", 12)) { return true; }
        if (weatherProviderPropertyNeedsWeather("touchAlternativeMiddleValueShows", 2)) { return true; }
        if (weatherProviderPropertyNeedsWeather("touchAlternativeRightValueShows", 32)) { return true; }
        if (weatherProviderPropertyNeedsWeather("touchAlternativeFourthValueShows", -2)) { return true; }
        return false;
    }

    if (weatherProviderPropertyNeedsWeather("leftValueShows", 11)) { return true; }
    if (weatherProviderPropertyNeedsWeather("middleValueShows", 29)) { return true; }
    if (weatherProviderPropertyNeedsWeather("rightValueShows", 6)) { return true; }
    return weatherProviderPropertyNeedsWeather("fourthValueShows", 10);
}

(:background)
function weatherProviderToNumber(value) as Number? {
    if (value == null) { return null; }
    return value.toNumber();
}

(:background)
function weatherProviderToFloat(value) as Float? {
    if (value == null) { return null; }
    return value.toFloat();
}

(:background)
function weatherProviderToString(value) as String? {
    if (value == null) { return null; }
    if (value instanceof String) {
        return value as String;
    }
    return value.toString();
}

(:background)
function weatherProviderNormalizeLocation(location as Array?) as Array<Float>? {
    if (location == null || location.size() < 2 || location[0] == null || location[1] == null) {
        return null;
    }
    return [(location[0] as Number).toFloat(), (location[1] as Number).toFloat()];
}

(:background)
function weatherProviderDeleteLegacyLocationData() as Void {
    Application.Storage.deleteValue(WEATHER_PROVIDER_LEGACY_GARMIN_LOCATION_KEY);

    var state = weatherProviderLoadState();
    if (state == null || state.get("location") == null) { return; }

    var provider = weatherProviderToString(state.get("provider"));
    if (provider == null) { return; }

    weatherProviderStoreState(weatherProviderBuildState(
        provider,
        weatherProviderToNumber(state.get("lastAttemptAt")),
        weatherProviderToNumber(state.get("lastSuccessAt")),
        weatherProviderToNumber(state.get("lastErrorCode")),
        weatherProviderToString(state.get("lastErrorMessage")),
        weatherProviderToString(state.get("locationSource"))
    ));
}

(:background)
function weatherProviderBuildLocation(location as Array?) as Position.Location or Null {
    var normalized = weatherProviderNormalizeLocation(location);
    if (normalized == null) { return null; }
    return new Position.Location({
        :latitude => normalized[0],
        :longitude => normalized[1],
        :format => :degrees
    });
}

(:background)
function weatherProviderLoadState() as Dictionary? {
    return Application.Storage.getValue(WEATHER_PROVIDER_STATE_KEY) as Dictionary?;
}

(:background)
function weatherProviderLoadOpenMeteoState() as Dictionary? {
    var state = weatherProviderLoadState();
    if (state == null) { return null; }
    if ((state.get("provider") as String?) != WEATHER_PROVIDER_OPEN_METEO_NAME) { return null; }
    return state;
}

(:background)
function weatherProviderStoreState(state as Dictionary) as Void {
    Application.Storage.setValue(WEATHER_PROVIDER_STATE_KEY, state);
}

(:background)
function weatherProviderBuildState(provider as String, lastAttemptAt as Number?, lastSuccessAt as Number?, lastErrorCode as Number?, lastErrorMessage as String?, locationSource as String?) as Dictionary {
    return {
        "provider" => provider,
        "lastAttemptAt" => lastAttemptAt,
        "lastSuccessAt" => lastSuccessAt,
        "lastErrorCode" => lastErrorCode,
        "lastErrorMessage" => weatherProviderTruncateString(lastErrorMessage, 120),
        "locationSource" => locationSource
    };
}

(:background)
function weatherProviderLoadSnapshotRaw() as Dictionary? {
    var snapshot = Application.Storage.getValue(WEATHER_SNAPSHOT_KEY) as Dictionary?;
    if (snapshot == null) { return null; }
    if ((snapshot.get("version") as Number?) != WEATHER_SNAPSHOT_VERSION) { return null; }
    if ((snapshot.get("provider") as String?) != WEATHER_PROVIDER_OPEN_METEO_NAME) { return null; }
    return snapshot;
}

(:background)
function weatherProviderLoadSnapshot() as Dictionary? {
    var snapshot = weatherProviderLoadSnapshotRaw();
    if (snapshot == null) { return null; }

    var fetchedAt = weatherProviderToNumber(snapshot.get("fetchedAt"));
    if (fetchedAt == null) { return null; }
    if (Time.now().value() - fetchedAt >= WEATHER_PROVIDER_STALE_AFTER_S) { return null; }

    return snapshot;
}

(:background)
function weatherProviderStoreSnapshot(snapshot as Dictionary) as Void {
    Application.Storage.setValue(WEATHER_SNAPSHOT_KEY, snapshot);
}

(:background)
function weatherProviderHasScheduledRefresh() as Boolean {
    return Background.getTemporalEventRegisteredTime() != null;
}

(:background)
function weatherProviderHasImmediateRefreshScheduled() as Boolean {
    var registered = Background.getTemporalEventRegisteredTime();
    if (registered == null) { return false; }

    if (registered instanceof Time.Moment) {
        return true;
    }

    return (registered as Time.Duration).value() <= WEATHER_PROVIDER_IMMEDIATE_GUARD_S;
}

(:background)
function weatherProviderLogSchedulingFailure(operation as String, error) as Void {
    var errorText = "unknown";
    if (error != null) {
        if (error instanceof String) {
            errorText = error as String;
        } else {
            try {
                errorText = error.toString();
            } catch(e) {}
        }
    }

    System.println("Open-Meteo scheduling failure: operation=" + operation + ", error=" + errorText);
}

(:background)
function weatherProviderDeleteScheduledRefresh() as Void {
    if (!weatherProviderHasScheduledRefresh()) { return; }

    try {
        Background.deleteTemporalEvent();
    } catch(e) {}
}

(:background)
function weatherProviderScheduleNextRefresh() as Void {
    try {
        Background.registerForTemporalEvent(new Time.Duration(WEATHER_PROVIDER_FETCH_INTERVAL_S));
    } catch(e) {
        weatherProviderLogSchedulingFailure("next_refresh", e);
    }
}

(:background)
function weatherProviderScheduleImmediateRefreshIfNeeded() as Void {
    if (!weatherProviderUsesOpenMeteo() || !weatherProviderIsWeatherRequired()) {
        weatherProviderDeleteScheduledRefresh();
        return;
    }

    if (weatherProviderHasImmediateRefreshScheduled()) {
        return;
    }

    var state = weatherProviderLoadOpenMeteoState();
    var lastAttemptAt = (state != null) ? weatherProviderToNumber(state.get("lastAttemptAt")) : null;
    var now = Time.now().value();
    var lastFailureWasLocationUnavailable = weatherProviderLastFailureWasLocationUnavailable(state);

    if (!lastFailureWasLocationUnavailable
        && lastAttemptAt != null
        && now - (lastAttemptAt as Number) < WEATHER_PROVIDER_FETCH_INTERVAL_S) {
        return;
    }

    if (lastAttemptAt != null && now - (lastAttemptAt as Number) < WEATHER_PROVIDER_IMMEDIATE_GUARD_S) {
        return;
    }

    try {
        Background.registerForTemporalEvent(Time.now());
    } catch(e) {
        weatherProviderLogSchedulingFailure("immediate_refresh_now", e);
        try {
            Background.registerForTemporalEvent(new Time.Duration(WEATHER_PROVIDER_IMMEDIATE_GUARD_S));
        } catch(e2) {
            weatherProviderLogSchedulingFailure("immediate_refresh_fallback", e2);
        }
    }
}

(:background)
function weatherProviderBuildOpenMeteoParams(location as Array?) as Dictionary {
    var normalized = weatherProviderNormalizeLocation(location);
    if (normalized == null) { return {}; }
    return {
        "latitude" => (normalized[0] as Float).format("%.6f"),
        "longitude" => (normalized[1] as Float).format("%.6f"),
        "timezone" => "auto",
        "timeformat" => "unixtime",
        "forecast_days" => WEATHER_PROVIDER_FORECAST_DAYS.format("%d"),
        "wind_speed_unit" => "ms",
        "current" => "temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,wind_speed_10m,wind_direction_10m",
        "hourly" => "temperature_2m,relative_humidity_2m,apparent_temperature,precipitation_probability,weather_code,wind_speed_10m,wind_direction_10m,uv_index",
        "daily" => "temperature_2m_max,temperature_2m_min,uv_index_max,sunrise,sunset"
    };
}

(:background)
function weatherProviderGetArrayValue(values as Array?, index as Number) {
    if (values == null || index < 0 || index >= values.size()) { return null; }
    return values[index];
}

(:background)
function weatherProviderGetArrayNumber(values as Array?, index as Number) as Number? {
    return weatherProviderToNumber(weatherProviderGetArrayValue(values, index));
}

(:background)
function weatherProviderGetArrayFloat(values as Array?, index as Number) as Float? {
    return weatherProviderToFloat(weatherProviderGetArrayValue(values, index));
}

(:background)
function weatherProviderGetLocalDayStart(timestamp as Number, utcOffsetSeconds as Number) as Number {
    var localTimestamp = timestamp + utcOffsetSeconds;
    var remainder = localTimestamp % 86400;
    if (remainder < 0) {
        remainder += 86400;
    }
    return localTimestamp - remainder;
}

(:background)
function weatherProviderFindNearestHourlyIndex(times as Array?, target as Number?, maxDiffSeconds as Number) as Number {
    if (times == null || target == null) { return -1; }

    var bestIdx = -1;
    var bestDiff = maxDiffSeconds + 1;
    for (var i = 0; i < times.size(); i++) {
        var timeValue = weatherProviderToNumber(times[i]);
        if (timeValue == null) { continue; }

        var diff = timeValue - (target as Number);
        if (diff < 0) {
            diff = -diff;
        }
        if (diff <= maxDiffSeconds && diff < bestDiff) {
            bestDiff = diff;
            bestIdx = i;
        }
    }

    return bestIdx;
}

(:background)
function weatherProviderFindDailyIndexForTime(times as Array?, timestamp as Number?, utcOffsetSeconds as Number) as Number {
    if (times == null || timestamp == null) { return -1; }

    var targetDay = weatherProviderGetLocalDayStart(timestamp as Number, utcOffsetSeconds);
    for (var i = 0; i < times.size(); i++) {
        var timeValue = weatherProviderToNumber(times[i]);
        if (timeValue == null) { continue; }
        if (weatherProviderGetLocalDayStart(timeValue, utcOffsetSeconds) == targetDay) {
            return i;
        }
    }

    return -1;
}

(:background)
function weatherProviderGetForecastHour(timestamp as Number, utcOffsetSeconds as Number) as Number {
    var localTimestamp = timestamp + utcOffsetSeconds;
    var remainder = localTimestamp % 86400;
    if (remainder < 0) {
        remainder += 86400;
    }
    return (remainder / 3600).toNumber();
}

(:background)
function weatherProviderWmoToGarminCondition(wmoCode as Number?) as Number {
    if (wmoCode == null) { return 53; }

    if (wmoCode == 0) { return 0; }
    if (wmoCode == 1) { return 23; }
    if (wmoCode == 2) { return 1; }
    if (wmoCode == 3) { return 20; }
    if (wmoCode == 45 || wmoCode == 48) { return 8; }
    if (wmoCode == 51 || wmoCode == 53 || wmoCode == 55) { return 31; }
    if (wmoCode == 56 || wmoCode == 57 || wmoCode == 66 || wmoCode == 67) { return 49; }
    if (wmoCode == 61) { return 14; }
    if (wmoCode == 63) { return 3; }
    if (wmoCode == 65) { return 15; }
    if (wmoCode == 71) { return 16; }
    if (wmoCode == 73) { return 4; }
    if (wmoCode == 75) { return 17; }
    if (wmoCode == 77) { return 48; }
    if (wmoCode == 80) { return 24; }
    if (wmoCode == 81) { return 25; }
    if (wmoCode == 82) { return 26; }
    if (wmoCode == 85) { return 48; }
    if (wmoCode == 86) { return 17; }
    if (wmoCode == 95) { return 6; }
    if (wmoCode == 96) { return 12; }
    if (wmoCode == 99) { return 10; }

    return 53;
}

(:background)
function weatherProviderGetDailyNumber(daily as Dictionary?, key as String, index as Number) as Number? {
    if (daily == null) { return null; }
    return weatherProviderGetArrayNumber(daily.get(key) as Array?, index);
}

(:background)
function weatherProviderGetHourlyNumber(hourly as Dictionary?, key as String, index as Number) as Number? {
    if (hourly == null) { return null; }
    return weatherProviderGetArrayNumber(hourly.get(key) as Array?, index);
}

(:background)
function weatherProviderGetHourlyFloat(hourly as Dictionary?, key as String, index as Number) as Float? {
    if (hourly == null) { return null; }
    return weatherProviderGetArrayFloat(hourly.get(key) as Array?, index);
}

(:background)
function weatherProviderLastFailureWasLocationUnavailable(state as Dictionary?) as Boolean {
    if (state == null) { return false; }

    var message = state.get("lastErrorMessage") as String?;
    return message != null && message.equals(WEATHER_PROVIDER_ERROR_LOCATION_UNAVAILABLE);
}

(:background)
function weatherProviderBuildSnapshotFromOpenMeteoResponse(data as Dictionary, location as Array?, fetchedAt as Number) as Dictionary? {
    var normalizedLocation = weatherProviderNormalizeLocation(location);
    if (normalizedLocation == null) { return null; }

    var current = data.get("current") as Dictionary?;
    var hourly = data.get("hourly") as Dictionary?;
    var daily = data.get("daily") as Dictionary?;
    var utcOffsetSeconds = weatherProviderToNumber(data.get("utc_offset_seconds"));
    if (current == null || hourly == null || daily == null || utcOffsetSeconds == null) { return null; }

    var timezone = weatherProviderToString(data.get("timezone"));
    if (timezone == null) { timezone = "GMT"; }

    var currentTime = weatherProviderToNumber(current.get("time"));
    if (currentTime == null) { currentTime = fetchedAt; }

    var hourlyTimes = hourly.get("time") as Array?;
    var dailyTimes = daily.get("time") as Array?;
    if (hourlyTimes == null || dailyTimes == null || hourlyTimes.size() == 0 || dailyTimes.size() == 0) {
        return null;
    }

    var nearestHourlyIdx = weatherProviderFindNearestHourlyIndex(hourlyTimes, currentTime, 1800);
    var currentDayIdx = weatherProviderFindDailyIndexForTime(dailyTimes, currentTime, utcOffsetSeconds as Number);
    if (currentDayIdx < 0) { currentDayIdx = 0; }

    var currentUv = (nearestHourlyIdx >= 0) ? weatherProviderGetHourlyFloat(hourly, "uv_index", nearestHourlyIdx) : null;
    if (currentUv == null) {
        currentUv = weatherProviderToFloat(weatherProviderGetDailyNumber(daily, "uv_index_max", currentDayIdx));
    }

    var currentSnapshot = {
        "condition" => weatherProviderWmoToGarminCondition(weatherProviderToNumber(current.get("weather_code"))),
        "temperature" => weatherProviderToNumber(current.get("temperature_2m")),
        "feelsLikeTemperature" => weatherProviderToFloat(current.get("apparent_temperature")),
        "precipitationChance" => (nearestHourlyIdx >= 0) ? weatherProviderGetHourlyNumber(hourly, "precipitation_probability", nearestHourlyIdx) : null,
        "relativeHumidity" => weatherProviderToNumber(current.get("relative_humidity_2m")),
        "windBearing" => weatherProviderToNumber(current.get("wind_direction_10m")),
        "windSpeed" => weatherProviderToFloat(current.get("wind_speed_10m")),
        "highTemperature" => weatherProviderGetDailyNumber(daily, "temperature_2m_max", currentDayIdx),
        "lowTemperature" => weatherProviderGetDailyNumber(daily, "temperature_2m_min", currentDayIdx),
        "uvIndex" => currentUv
    };

    var hourlySnapshot = [];
    var hourlyStartIdx = nearestHourlyIdx;
    if (hourlyStartIdx < 0) { hourlyStartIdx = 0; }
    var hourlyEndIdx = hourlyStartIdx + WEATHER_PROVIDER_HOURLY_FORECAST_LIMIT;
    if (hourlyEndIdx > hourlyTimes.size()) {
        hourlyEndIdx = hourlyTimes.size();
    }

    for (var i = hourlyStartIdx; i < hourlyEndIdx; i++) {
        var forecastTime = weatherProviderToNumber(hourlyTimes[i]);
        if (forecastTime == null) { continue; }

        var dayIdx = weatherProviderFindDailyIndexForTime(dailyTimes, forecastTime, utcOffsetSeconds as Number);

        hourlySnapshot.add({
            "forecastTime" => forecastTime,
            "forecastHour" => weatherProviderGetForecastHour(forecastTime, utcOffsetSeconds as Number),
            "condition" => weatherProviderWmoToGarminCondition(weatherProviderGetHourlyNumber(hourly, "weather_code", i)),
            "temperature" => weatherProviderGetHourlyNumber(hourly, "temperature_2m", i),
            "feelsLikeTemperature" => weatherProviderGetHourlyFloat(hourly, "apparent_temperature", i),
            "precipitationChance" => weatherProviderGetHourlyNumber(hourly, "precipitation_probability", i),
            "relativeHumidity" => weatherProviderGetHourlyNumber(hourly, "relative_humidity_2m", i),
            "windBearing" => weatherProviderGetHourlyNumber(hourly, "wind_direction_10m", i),
            "windSpeed" => weatherProviderGetHourlyFloat(hourly, "wind_speed_10m", i),
            "highTemperature" => weatherProviderGetDailyNumber(daily, "temperature_2m_max", dayIdx),
            "lowTemperature" => weatherProviderGetDailyNumber(daily, "temperature_2m_min", dayIdx),
            "uvIndex" => weatherProviderGetHourlyFloat(hourly, "uv_index", i)
        });
    }

    return {
        "version" => WEATHER_SNAPSHOT_VERSION,
        "provider" => WEATHER_PROVIDER_OPEN_METEO_NAME,
        "fetchedAt" => fetchedAt,
        "location" => normalizedLocation,
        "timezone" => timezone,
        "utcOffsetSeconds" => utcOffsetSeconds,
        "current" => currentSnapshot,
        "hourly" => hourlySnapshot
    };
}

(:background)
function weatherProviderEncodeBackgroundLocationSource(source as String?) as Number {
    if (source == WEATHER_PROVIDER_LOCATION_SOURCE_DEVICE) { return 0; }
    if (source == WEATHER_PROVIDER_LOCATION_SOURCE_GARMIN_CACHE) { return 1; }
    return 2;
}

(:background)
function weatherProviderDecodeBackgroundLocationSource(code as Number?) as String {
    if (code == 0) { return WEATHER_PROVIDER_LOCATION_SOURCE_DEVICE; }
    if (code == 1) { return WEATHER_PROVIDER_LOCATION_SOURCE_GARMIN_CACHE; }
    return WEATHER_PROVIDER_LOCATION_SOURCE_UNAVAILABLE;
}

(:background)
function weatherProviderEncodeBackgroundCurrentEntry(entry as Dictionary?) as Array? {
    if (entry == null) { return null; }

    return [
        weatherProviderToNumber(entry.get("condition")),
        weatherProviderToNumber(entry.get("temperature")),
        weatherProviderToFloat(entry.get("feelsLikeTemperature")),
        weatherProviderToNumber(entry.get("precipitationChance")),
        weatherProviderToNumber(entry.get("relativeHumidity")),
        weatherProviderToNumber(entry.get("windBearing")),
        weatherProviderToFloat(entry.get("windSpeed")),
        weatherProviderToNumber(entry.get("highTemperature")),
        weatherProviderToNumber(entry.get("lowTemperature")),
        weatherProviderToFloat(entry.get("uvIndex"))
    ];
}

(:background)
function weatherProviderEncodeBackgroundHourlyEntry(entry as Dictionary?) as Array? {
    if (entry == null) { return null; }

    return [
        weatherProviderToNumber(entry.get("forecastTime")),
        weatherProviderToNumber(entry.get("condition")),
        weatherProviderToNumber(entry.get("temperature")),
        weatherProviderToFloat(entry.get("feelsLikeTemperature")),
        weatherProviderToNumber(entry.get("precipitationChance")),
        weatherProviderToNumber(entry.get("relativeHumidity")),
        weatherProviderToNumber(entry.get("windBearing")),
        weatherProviderToFloat(entry.get("windSpeed")),
        weatherProviderToNumber(entry.get("highTemperature")),
        weatherProviderToNumber(entry.get("lowTemperature")),
        weatherProviderToFloat(entry.get("uvIndex"))
    ];
}

(:background)
function weatherProviderEncodeBackgroundSnapshot(snapshot as Dictionary?) as Dictionary? {
    if (snapshot == null) { return null; }

    var location = weatherProviderNormalizeLocation(snapshot.get("location") as Array?);
    var fetchedAt = weatherProviderToNumber(snapshot.get("fetchedAt"));
    var utcOffsetSeconds = weatherProviderToNumber(snapshot.get("utcOffsetSeconds"));
    var current = weatherProviderEncodeBackgroundCurrentEntry(snapshot.get("current") as Dictionary?);
    if (location == null || fetchedAt == null || utcOffsetSeconds == null || current == null) {
        return null;
    }

    var hourly = [];
    var hourlyEntries = snapshot.get("hourly") as Array?;
    if (hourlyEntries != null) {
        for (var i = 0; i < hourlyEntries.size(); i++) {
            var encoded = weatherProviderEncodeBackgroundHourlyEntry(hourlyEntries[i] as Dictionary?);
            if (encoded != null) {
                hourly.add(encoded);
            }
        }
    }

    var timezone = weatherProviderToString(snapshot.get("timezone"));
    if (timezone == null) { timezone = "GMT"; }

    return {
        "t" => fetchedAt,
        "l" => location,
        "z" => timezone,
        "o" => utcOffsetSeconds,
        "c" => current,
        "h" => hourly
    };
}

(:background)
function weatherProviderDecodeBackgroundCurrentEntry(values as Array?) as Dictionary? {
    if (values == null) { return null; }

    return {
        "condition" => weatherProviderGetArrayNumber(values, 0),
        "temperature" => weatherProviderGetArrayNumber(values, 1),
        "feelsLikeTemperature" => weatherProviderGetArrayFloat(values, 2),
        "precipitationChance" => weatherProviderGetArrayNumber(values, 3),
        "relativeHumidity" => weatherProviderGetArrayNumber(values, 4),
        "windBearing" => weatherProviderGetArrayNumber(values, 5),
        "windSpeed" => weatherProviderGetArrayFloat(values, 6),
        "highTemperature" => weatherProviderGetArrayNumber(values, 7),
        "lowTemperature" => weatherProviderGetArrayNumber(values, 8),
        "uvIndex" => weatherProviderGetArrayFloat(values, 9)
    };
}

(:background)
function weatherProviderDecodeBackgroundHourlyEntry(values as Array?, utcOffsetSeconds as Number) as Dictionary? {
    if (values == null) { return null; }

    var forecastTime = weatherProviderGetArrayNumber(values, 0);
    if (forecastTime == null) { return null; }

    return {
        "forecastTime" => forecastTime,
        "forecastHour" => weatherProviderGetForecastHour(forecastTime, utcOffsetSeconds),
        "condition" => weatherProviderGetArrayNumber(values, 1),
        "temperature" => weatherProviderGetArrayNumber(values, 2),
        "feelsLikeTemperature" => weatherProviderGetArrayFloat(values, 3),
        "precipitationChance" => weatherProviderGetArrayNumber(values, 4),
        "relativeHumidity" => weatherProviderGetArrayNumber(values, 5),
        "windBearing" => weatherProviderGetArrayNumber(values, 6),
        "windSpeed" => weatherProviderGetArrayFloat(values, 7),
        "highTemperature" => weatherProviderGetArrayNumber(values, 8),
        "lowTemperature" => weatherProviderGetArrayNumber(values, 9),
        "uvIndex" => weatherProviderGetArrayFloat(values, 10)
    };
}

(:background)
function weatherProviderDecodeBackgroundSnapshot(snapshot as Dictionary?) as Dictionary? {
    if (snapshot == null) { return null; }

    var fetchedAt = weatherProviderToNumber(snapshot.get("t"));
    var location = weatherProviderNormalizeLocation(snapshot.get("l") as Array?);
    var utcOffsetSeconds = weatherProviderToNumber(snapshot.get("o"));
    var current = weatherProviderDecodeBackgroundCurrentEntry(snapshot.get("c") as Array?);
    if (fetchedAt == null || location == null || utcOffsetSeconds == null || current == null) {
        return null;
    }

    var timezone = weatherProviderToString(snapshot.get("z"));
    if (timezone == null) { timezone = "GMT"; }

    var hourly = [];
    var hourlyEntries = snapshot.get("h") as Array?;
    if (hourlyEntries != null) {
        for (var i = 0; i < hourlyEntries.size(); i++) {
            var decoded = weatherProviderDecodeBackgroundHourlyEntry(hourlyEntries[i] as Array?, utcOffsetSeconds as Number);
            if (decoded != null) {
                hourly.add(decoded);
            }
        }
    }

    return {
        "version" => WEATHER_SNAPSHOT_VERSION,
        "provider" => WEATHER_PROVIDER_OPEN_METEO_NAME,
        "fetchedAt" => fetchedAt,
        "location" => location,
        "timezone" => timezone,
        "utcOffsetSeconds" => utcOffsetSeconds,
        "current" => current,
        "hourly" => hourly
    };
}

(:background)
function weatherProviderBuildBackgroundSuccessPayload(snapshot as Dictionary, lastAttemptAt as Number, lastSuccessAt as Number, locationSource as String?) as Dictionary? {
    var encodedSnapshot = weatherProviderEncodeBackgroundSnapshot(snapshot);
    if (encodedSnapshot == null) { return null; }

    return {
        "v" => WEATHER_PROVIDER_BACKGROUND_PAYLOAD_VERSION,
        "r" => WEATHER_PROVIDER_BACKGROUND_RESULT_SUCCESS,
        "a" => lastAttemptAt,
        "u" => lastSuccessAt,
        "s" => weatherProviderEncodeBackgroundLocationSource(locationSource),
        "p" => encodedSnapshot
    };
}

(:background)
function weatherProviderBuildBackgroundFailurePayload(reason as Number, lastAttemptAt as Number, responseCode as Number?, locationSource as String?) as Dictionary {
    return {
        "v" => WEATHER_PROVIDER_BACKGROUND_PAYLOAD_VERSION,
        "r" => reason,
        "a" => lastAttemptAt,
        "c" => responseCode,
        "s" => weatherProviderEncodeBackgroundLocationSource(locationSource)
    };
}

(:background)
function weatherProviderBuildBackgroundErrorMessage(reason as Number, responseCode as Number?) as String {
    if (reason == WEATHER_PROVIDER_BACKGROUND_RESULT_LOCATION_UNAVAILABLE) {
        return WEATHER_PROVIDER_ERROR_LOCATION_UNAVAILABLE;
    }

    if (reason == WEATHER_PROVIDER_BACKGROUND_RESULT_INVALID_RESPONSE) {
        return WEATHER_PROVIDER_ERROR_INVALID_RESPONSE;
    }

    if (responseCode != null && responseCode >= 0) {
        return WEATHER_PROVIDER_ERROR_REQUEST_FAILED + " (" + responseCode.format("%d") + ")";
    }

    return WEATHER_PROVIDER_ERROR_REQUEST_FAILED;
}

(:background)
function weatherProviderApplyBackgroundPayload(data) as Boolean {
    if (!(data instanceof Dictionary)) { return false; }

    var payload = data as Dictionary;
    if (weatherProviderToNumber(payload.get("v")) != WEATHER_PROVIDER_BACKGROUND_PAYLOAD_VERSION) {
        return false;
    }

    var reason = weatherProviderToNumber(payload.get("r"));
    var lastAttemptAt = weatherProviderToNumber(payload.get("a"));
    if (reason == null || lastAttemptAt == null) {
        return false;
    }

    var locationSource = weatherProviderDecodeBackgroundLocationSource(weatherProviderToNumber(payload.get("s")));
    var existingState = weatherProviderLoadOpenMeteoState();
    var lastSuccessAt = (existingState != null) ? weatherProviderToNumber(existingState.get("lastSuccessAt")) : null;

    if (reason == WEATHER_PROVIDER_BACKGROUND_RESULT_SUCCESS) {
        var snapshot = weatherProviderDecodeBackgroundSnapshot(payload.get("p") as Dictionary?);
        if (snapshot == null) {
            weatherProviderStoreState(weatherProviderBuildState(
                WEATHER_PROVIDER_OPEN_METEO_NAME,
                lastAttemptAt,
                lastSuccessAt,
                null,
                WEATHER_PROVIDER_ERROR_INVALID_RESPONSE,
                locationSource
            ));
            return false;
        }

        var successAt = weatherProviderToNumber(payload.get("u"));
        if (successAt == null) {
            successAt = lastAttemptAt;
        }

        weatherProviderStoreSnapshot(snapshot);
        weatherProviderStoreState(weatherProviderBuildState(
            WEATHER_PROVIDER_OPEN_METEO_NAME,
            lastAttemptAt,
            successAt,
            null,
            null,
            locationSource
        ));
        return true;
    }

    var responseCode = weatherProviderToNumber(payload.get("c"));
    weatherProviderStoreState(weatherProviderBuildState(
        WEATHER_PROVIDER_OPEN_METEO_NAME,
        lastAttemptAt,
        lastSuccessAt,
        responseCode,
        weatherProviderBuildBackgroundErrorMessage(reason as Number, responseCode),
        locationSource
    ));
    return false;
}

(:background)
function weatherProviderTruncateString(value as String?, maxLength as Number) as String? {
    if (value == null) { return null; }
    if (value.length() <= maxLength) { return value; }
    return value.substring(0, maxLength);
}
