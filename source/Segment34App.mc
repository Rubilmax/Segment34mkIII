import Toybox.Application;
import Toybox.Background;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

(:background)
class Segment34App extends Application.AppBase {
    
    (:typecheck(disableBackgroundCheck))
    var mView as Segment34View or Null;
    
    function initialize() {
        AppBase.initialize();
        System.println("Segment34Plus app initialize");
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
        System.println("Segment34Plus app start");
        // Foreground startup continues through getInitialView() -> onSettingsChanged(),
        // which schedules weather refresh after the view and properties are ready.
        // Avoid doing that work here; on fenix847mm firmware 21.39 this early path
        // can crash before settings-backed symbols are stable.
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
    }

    // Return the initial view of your application here
    // AppBase is shared with the background process, but this callback is
    // foreground-only and intentionally wires up UI classes.
    (:typecheck(disableBackgroundCheck))
    function getInitialView() {
        System.println("Segment34Plus initial view");
        var view = new Segment34View();
        mView = view;
        onSettingsChanged();
        var delegate = new Segment34Delegate(view);
        return [view, delegate];
    }

    function getServiceDelegate() as [System.ServiceDelegate] {
        return [new Segment34WeatherServiceDelegate()];
    }

    (:typecheck(disableBackgroundCheck))
    function onSettingsChanged() as Void {
        if (mView != null) {
            mView.onSettingsChanged();
        }
        scheduleWeatherRefresh();
        WatchUi.requestUpdate();
    }

    (:typecheck(disableBackgroundCheck))
    function onStorageChanged() as Void {
        if (mView != null) {
            mView.onWeatherDataChanged();
        }
        WatchUi.requestUpdate();
    }

    (:typecheck(disableBackgroundCheck))
    function onBackgroundData(data) as Void {
        System.println("Open-Meteo background data received");
        if (!weatherProviderUsesOpenMeteo() || !weatherProviderIsWeatherRequired()) {
            System.println("Open-Meteo background data ignored: provider disabled or weather not required");
            weatherProviderDeleteScheduledRefresh();
            return;
        }

        var applied = false;
        try {
            applied = weatherProviderApplyBackgroundPayload(data);
        } catch(e) {
            System.println("Open-Meteo background payload apply failure: " + e);
        }

        System.println("Open-Meteo background data applied=" + (applied ? "true" : "false"));

        if (!applied) {
            return;
        }

        if (mView != null) {
            mView.onWeatherDataChanged();
        }
        WatchUi.requestUpdate();
    }

    (:typecheck(disableBackgroundCheck))
    hidden function scheduleWeatherRefresh() as Void {
        weatherProviderDeleteLegacyLocationData();

        if (!weatherProviderUsesOpenMeteo()) {
            System.println("Open-Meteo schedule skipped: provider disabled");
            weatherProviderDeleteScheduledRefresh();
            weatherProviderDeleteSnapshot();
            return;
        }

        if (!weatherProviderIsWeatherRequired()) {
            System.println("Open-Meteo schedule skipped: weather not required");
            weatherProviderDeleteScheduledRefresh();
            weatherProviderDeleteSnapshot();
            return;
        }

        System.println("Open-Meteo schedule requested: view=" + ((mView != null) ? "foreground" : "none"));
        if (mView != null) {
            mView.scheduleImmediateCustomWeatherRefreshIfNeeded();
        } else {
            weatherProviderScheduleImmediateRefreshIfNeeded();
        }
    }

}

function getApp() as Segment34App {
    return Application.getApp() as Segment34App;
}
