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

    function initialize() {
        ServiceDelegate.initialize();
    }

    function onTemporalEvent() as Void {
        weatherProviderScheduleNextRefresh();

        var now = Time.now().value();
        var resolvedLocation = resolveWeatherLocation();
        var location = resolvedLocation.get("location") as Array?;
        var locationSource = resolvedLocation.get("source") as String?;

        if (location == null) {
            Background.exit(weatherProviderBuildBackgroundFailurePayload(
                WEATHER_PROVIDER_BACKGROUND_RESULT_LOCATION_UNAVAILABLE,
                now,
                null,
                WEATHER_PROVIDER_LOCATION_SOURCE_UNAVAILABLE
            ));
            return;
        }

        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON,
            :context => {
                "fetchedAt" => now,
                "location" => location,
                "locationSource" => locationSource,
                "lastAttemptAt" => now
            }
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
                options.get(:context) as Dictionary
            );
            Background.exit(weatherProviderBuildBackgroundFailurePayload(
                WEATHER_PROVIDER_BACKGROUND_RESULT_REQUEST_FAILED,
                now,
                -1,
                locationSource
            ));
        }
    }

    function onWeatherResponse(responseCode as Number, data as Dictionary or String or PersistedContent.Iterator or Null, context as Object) as Void {
        var responseContext = context as Dictionary;
        var location = responseContext.get("location") as Array?;
        var locationSource = responseContext.get("locationSource") as String?;
        var lastAttemptAt = weatherProviderToNumber(responseContext.get("lastAttemptAt"));

        if (responseCode == 200 && data instanceof Dictionary) {
            var snapshot = weatherProviderBuildSnapshotFromOpenMeteoResponse(
                data as Dictionary,
                location,
                weatherProviderToNumber(responseContext.get("fetchedAt")) as Number
            );
            if (snapshot != null) {
                var successPayload = weatherProviderBuildBackgroundSuccessPayload(
                    snapshot,
                    lastAttemptAt as Number,
                    Time.now().value(),
                    locationSource
                );
                if (successPayload != null) {
                    // Known limitation: background storage writes are currently unavailable for
                    // this flow, so the snapshot must be passed back through Background.exit()
                    // and persisted later in AppBase.onBackgroundData(). If multiple background
                    // runs happen while the foreground app is inactive, only the latest payload
                    // is delivered, so a later failure can overwrite an earlier success.
                    Background.exit(successPayload);
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
        Background.exit(weatherProviderBuildBackgroundFailurePayload(
            failureReason,
            lastAttemptAt as Number,
            responseCode,
            locationSource
        ));
    }

    hidden function resolveWeatherLocation() as Dictionary {
        try {
            var info = Position.getInfo();
            if (info != null && info has :position && info.position != null) {
                var devicePosition = info.position as Location;
                var degrees = devicePosition.toDegrees() as Array?;
                if (degrees != null && degrees.size() >= 2 && degrees[0] != null && degrees[1] != null) {
                    return {
                        "location" => [(degrees[0] as Number).toFloat(), (degrees[1] as Number).toFloat()],
                        "source" => WEATHER_PROVIDER_LOCATION_SOURCE_DEVICE
                    };
                }
            }
        } catch(e) {}

        if (Activity has :getActivityInfo) {
            try {
                var activityInfo = Activity.getActivityInfo();
                if (activityInfo != null && activityInfo.currentLocation != null) {
                    var activityLocation = activityInfo.currentLocation as Location;
                    var degrees = activityLocation.toDegrees() as Array?;
                    if (degrees != null && degrees.size() >= 2 && degrees[0] != null && degrees[1] != null) {
                        return {
                            "location" => [(degrees[0] as Number).toFloat(), (degrees[1] as Number).toFloat()],
                            "source" => WEATHER_PROVIDER_LOCATION_SOURCE_DEVICE
                        };
                    }
                }
            } catch(e) {}
        }

        if (Weather has :getCurrentConditions) {
            try {
                var currentConditions = Weather.getCurrentConditions();
                if (currentConditions != null && currentConditions.observationLocationPosition != null) {
                    var cachedLocation = currentConditions.observationLocationPosition as Location;
                    var degrees = cachedLocation.toDegrees() as Array?;
                    if (degrees != null && degrees.size() >= 2 && degrees[0] != null && degrees[1] != null) {
                        return {
                            "location" => [(degrees[0] as Number).toFloat(), (degrees[1] as Number).toFloat()],
                            "source" => WEATHER_PROVIDER_LOCATION_SOURCE_GARMIN_CACHE
                        };
                    }
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
