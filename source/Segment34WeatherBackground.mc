import Toybox.Activity;
import Toybox.Background;
import Toybox.Communications;
import Toybox.Lang;
import Toybox.PersistedContent;
import Toybox.Position;
import Toybox.System;
import Toybox.Time;
import Toybox.Weather;
using Toybox.Position;

(:background)
class Segment34WeatherServiceDelegate extends System.ServiceDelegate {

    hidden var pendingRequestContext as Dictionary?;

    function initialize() {
        ServiceDelegate.initialize();
    }

    function onTemporalEvent() as Void {
        if (!weatherProviderUsesOpenMeteo() || !weatherProviderIsWeatherRequired()) {
            weatherProviderDeleteScheduledRefresh();
            exitBackgroundPayload(null);
            return;
        }

        weatherProviderScheduleNextRefresh();

        var now = Time.now().value();
        var resolvedLocation = resolveWeatherLocation();
        var location = resolvedLocation.get("location") as Array?;
        var locationSource = resolvedLocation.get("source") as String?;

        if (location == null) {
            exitBackgroundPayload(weatherProviderBuildBackgroundFailurePayload(
                WEATHER_PROVIDER_BACKGROUND_RESULT_LOCATION_UNAVAILABLE,
                now,
                null,
                WEATHER_PROVIDER_LOCATION_SOURCE_UNAVAILABLE
            ));
            return;
        }

        var requestContext = {
            "fetchedAt" => now,
            "location" => location,
            "locationSource" => locationSource,
            "lastAttemptAt" => now
        };
        pendingRequestContext = requestContext;

        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

        try {
            Communications.makeWebRequest(
                WEATHER_PROVIDER_OPEN_METEO_URL,
                weatherProviderBuildOpenMeteoParams(location),
                options,
                self.method(:onWeatherResponse)
            );
        } catch(e) {
            logOpenMeteoRequestFailure(
                WEATHER_PROVIDER_ERROR_REQUEST_FAILED,
                -1,
                requestContext
            );
            pendingRequestContext = null;
            exitBackgroundPayload(weatherProviderBuildBackgroundFailurePayload(
                WEATHER_PROVIDER_BACKGROUND_RESULT_REQUEST_FAILED,
                now,
                -1,
                locationSource
            ));
        }
    }

    function onWeatherResponse(responseCode as Number, data as Dictionary or String or PersistedContent.Iterator or Null) as Void {
        var responseContext = pendingRequestContext;
        pendingRequestContext = null;
        if (responseContext == null) {
            responseContext = {
                "fetchedAt" => Time.now().value(),
                "location" => null,
                "locationSource" => WEATHER_PROVIDER_LOCATION_SOURCE_UNAVAILABLE,
                "lastAttemptAt" => Time.now().value()
            };
        }
        var location = responseContext.get("location") as Array?;
        var locationSource = responseContext.get("locationSource") as String?;
        var lastAttemptAt = weatherProviderToNumber(responseContext.get("lastAttemptAt"));
        if (lastAttemptAt == null) { lastAttemptAt = Time.now().value(); }

        if (responseCode == 200 && data instanceof Dictionary) {
            var snapshot = weatherProviderBuildSnapshotFromOpenMeteoResponse(
                data as Dictionary,
                location,
                weatherProviderToNumber(responseContext.get("fetchedAt")) as Number
            );
            if (snapshot != null) {
                if (exitBackgroundSuccessPayloadWithHourlyFallbacks(
                    snapshot,
                    lastAttemptAt as Number,
                    Time.now().value(),
                    locationSource
                )) {
                    return;
                }
            }
        }

        var failureReason = WEATHER_PROVIDER_BACKGROUND_RESULT_INVALID_RESPONSE;
        var errorMessage = WEATHER_PROVIDER_ERROR_INVALID_RESPONSE;
        if (responseCode != 200) {
            failureReason = WEATHER_PROVIDER_BACKGROUND_RESULT_REQUEST_FAILED;
            errorMessage = weatherProviderBuildBackgroundErrorMessage(failureReason, responseCode);
        }

        logOpenMeteoRequestFailure(errorMessage, responseCode, responseContext);
        exitBackgroundPayload(weatherProviderBuildBackgroundFailurePayload(
            failureReason,
            lastAttemptAt as Number,
            responseCode,
            locationSource
        ));
    }

    hidden function exitBackgroundSuccessPayloadWithHourlyFallbacks(snapshot as Dictionary, lastAttemptAt as Number, successAt as Number, locationSource as String?) as Boolean {
        var hourlyLimit = WEATHER_PROVIDER_HOURLY_FORECAST_LIMIT;
        while (hourlyLimit >= WEATHER_PROVIDER_BACKGROUND_MIN_HOURLY_LIMIT) {
            if (tryExitBackgroundSuccessPayload(
                snapshot,
                lastAttemptAt,
                successAt,
                locationSource,
                hourlyLimit
            )) {
                return true;
            }
            hourlyLimit = hourlyLimit >> 1;
        }
        return tryExitBackgroundSuccessPayload(
            snapshot,
            lastAttemptAt,
            successAt,
            locationSource,
            0
        );
    }

    hidden function tryExitBackgroundSuccessPayload(snapshot as Dictionary, lastAttemptAt as Number, successAt as Number, locationSource as String?, hourlyLimit as Number) as Boolean {
        var payload = weatherProviderBuildBackgroundSuccessPayloadWithHourlyLimit(
            snapshot,
            lastAttemptAt,
            successAt,
            locationSource,
            hourlyLimit
        );
        if (payload == null) {
            return false;
        }

        return tryExitBackgroundPayload(payload);
    }

    hidden function tryExitBackgroundPayload(payload as Object or Null) as Boolean {
        try {
            Background.exit(payload);
            return true;
        } catch(e) {
            return false;
        }
    }

    hidden function exitBackgroundPayload(payload as Object or Null) as Void {
        if (tryExitBackgroundPayload(payload)) { return; }

        try {
            Background.exit(null);
        } catch(e) {}
    }

    hidden function buildLocationResult(location as Location?, source as String) as Dictionary? {
        if (location == null) { return null; }

        var degrees = location.toDegrees() as Array?;
        if (degrees == null || degrees.size() < 2 || degrees[0] == null || degrees[1] == null) {
            return null;
        }

        return {
            "location" => [(degrees[0] as Number).toFloat(), (degrees[1] as Number).toFloat()],
            "source" => source
        };
    }

    hidden function resolveWeatherLocation() as Dictionary {
        try {
            var info = Position.getInfo();
            if (info != null && info has :position && info.position != null) {
                var result = buildLocationResult(info.position as Location, WEATHER_PROVIDER_LOCATION_SOURCE_DEVICE);
                if (result != null) { return result; }
            }
        } catch(e) {}

        if (Activity has :getActivityInfo) {
            try {
                var activityInfo = Activity.getActivityInfo();
                if (activityInfo != null && activityInfo.currentLocation != null) {
                    var activityResult = buildLocationResult(activityInfo.currentLocation as Location, WEATHER_PROVIDER_LOCATION_SOURCE_DEVICE);
                    if (activityResult != null) { return activityResult; }
                }
            } catch(e) {}
        }

        if (Weather has :getCurrentConditions) {
            try {
                var currentConditions = Weather.getCurrentConditions();
                if (currentConditions != null && currentConditions.observationLocationPosition != null) {
                    var cachedResult = buildLocationResult(currentConditions.observationLocationPosition as Location, WEATHER_PROVIDER_LOCATION_SOURCE_GARMIN_CACHE);
                    if (cachedResult != null) { return cachedResult; }
                }
            } catch(e) {}
        }

        return {
            "location" => null,
            "source" => WEATHER_PROVIDER_LOCATION_SOURCE_UNAVAILABLE
        };
    }

    hidden function logOpenMeteoRequestFailure(message as String, responseCode as Number, context as Dictionary) as Void {
        var locationSource = context.get("locationSource") as String?;
        var location = weatherProviderNormalizeLocation(context.get("location") as Array?);
        var locationText = "unknown";
        if (location != null) {
            locationText = (location[0] as Float).format("%.4f") + "," + (location[1] as Float).format("%.4f");
        }

        System.println(
            "Open-Meteo request failure"
            + ": code=" + responseCode.format("%d")
            + ", message=" + message
            + ", locationSource=" + ((locationSource == null) ? "unknown" : locationSource)
            + ", location=" + locationText
        );
    }
}
