import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Time;
import Toybox.Weather;
import Toybox.Complications;
using Toybox.Position;

const WEATHER_CYCLE_FEELS_LIKE_THRESHOLD_C = 5.0f;
const WEATHER_GROUP_UNKNOWN = 4;

function normalizeWeatherCondition(condition as Number, resourceCount as Number) as Number {
    if (condition < 0 || condition >= resourceCount) { return 53; }
    return condition;
}

class Segment34View extends WatchUi.WatchFace {

    hidden var screenHeight as Number;
    hidden var screenWidth as Number;
    (:initialized) hidden var clockHeight as Number;
    (:initialized) hidden var clockWidth as Number;
    (:initialized) hidden var labelHeight as Number;
    (:initialized) hidden var labelMargin as Number;
    (:initialized) hidden var tinyDataHeight as Number;
    (:initialized) hidden var smallDataHeight as Number;
    (:initialized) hidden var largeDataHeight as Number;
    (:initialized) hidden var largeDataWidth as Number;
    (:initialized) hidden var bottomDataWidth as Number;
    (:initialized) hidden var baseX as Number;
    (:initialized) hidden var baseY as Number;
    hidden var centerX as Number;
    hidden var centerY as Number;
    hidden var marginX as Number;
    hidden var marginY as Number;
    hidden var halfMarginY as Number = 0;
    hidden var halfClockHeight as Number = 0;
    hidden var halfClockWidth as Number = 0;

    hidden var fontMoon as WatchUi.FontResource;
    hidden var fontIcons as WatchUi.FontResource;
    (:initialized) hidden var fontClock as WatchUi.FontResource;
    (:initialized) hidden var fontClockOutline as WatchUi.FontResource;
    (:initialized) hidden var fontLabel as WatchUi.FontResource;
    (:initialized) hidden var fontTinyData as WatchUi.FontResource;
    (:initialized) hidden var fontSmallData as WatchUi.FontResource;
    (:initialized) hidden var fontLargeData as WatchUi.FontResource;
    (:initialized) hidden var fontAODData as WatchUi.FontResource;
    (:initialized) hidden var fontBottomData as WatchUi.FontResource;
    (:initialized) hidden var fontBattery as WatchUi.FontResource;
    hidden var weekNames as Array<String>?;
    hidden var monthNames as Array<String>?;

    // Layout Caching
    hidden var cachedFieldWidths as Array<Number> = [0, 0, 0, 0];
    hidden var cachedSysStats as System.Stats?;
    hidden var wakeTimestamp as Number = 0;
    hidden var cachedStressData as Number? = null;
    hidden var cachedBBData as Number? = null;
    hidden var fieldXCoords as Array<Number> = [0, 0, 0, 0];
    hidden var fieldY as Number = 0;
    hidden var bottomFiveY as Number = 0;
    (:Square) hidden var bottomFive1X as Number = 0;
    (:Square) hidden var bottomFive2X as Number = 0;
    (:Square) hidden var bottomFiveYOriginal as Number = 0;

    hidden var drawGradient as BitmapResource?;
    hidden var drawAODPattern as BitmapResource?;
    
    hidden var themeColors as Array<Graphics.ColorType> = [];
    (:WeatherCache) hidden var weatherCondition as CurrentConditions or ForecastWeather or StoredWeather or Null;
    (:NoWeatherCache) hidden var weatherCondition as CurrentConditions or ForecastWeather or Null;
    hidden var lastUpdate as Number? = null;
    hidden var lastSlowUpdate as Number? = null;
    hidden var lastCurrentConditionsFetch as Number? = null;
    hidden var lastHourlyForecastFetch as Number? = null;
    hidden var cachedValues as Dictionary = {};
    hidden var refreshCache as Dictionary = {};
    hidden var cachedComplicationValues as Dictionary = {};
    hidden var cachedTempUnit as String = "C";
    hidden var openMeteoAppliedSnapshotFetchedAt as Number? = null;

    (:WeatherCache) hidden var lastHfTime as Number? = null;
    (:WeatherCache) hidden var lastCcHash as Number? = null;

    // CGM Connect Widget complication IDs: reading, age
    hidden var cgmComplicationIds as Array = [null, null];

    // runtimeBitmap: visible[0], cachedStressDataValid[1], cachedBBDataValid[2], canBurnIn[3],
    // isSleeping[4], isWeatherRequired[5], isLowMem[6], reserved[7],
    // hasComplications[8], touchAlternativeActive[9], clockBgCompact[10],
    // lastWeatherPhasePlusOne[11:30]
    hidden var runtimeBitmap as Number = 1;
    // layoutBitmap: fieldSpaceingAdj[0:4], barBottomAdj[5:9], bottomFiveAdj[10:14],
    // textSideAdj[15:19], iconYAdjPlus16[20:24], patternRows[25:29], dualBottomFields[30]
    hidden var layoutBitmap as Number = 0;
    
    // Packed settings to keep the watch face under the class member limit on MIP devices.
    // propBitmapA: theme[0:4], outline[5:7], clockFont[8], reserved[9:12], clockBg[13],
    // dataBg[14], aodStyle[15:16], aodAlign[17],
    // dateAlign[18], bottomAlign[19:20], bottomLabelAlign[21:22], hemisphere[23],
    // hourFormat[24:25], reserved[26:28], tempUnit[29:30]
    // propBitmapB: showTempUnit[0], windUnit[1:3], pressureUnit[4:5], topPartShows[6],
    // dateFormat[7:10], reserved[11:12], smallFontVariant[13:14],
    // stressDynamicColor[15], is24H[16], weatherProvider[17], reserved[18:22], fieldLayout[23:26]
    hidden var propBitmapA as Number = 0;
    hidden var propBitmapB as Number = 0;
    hidden var propLeftValueShows as Number = 6;
    hidden var propMiddleValueShows as Number = 10;
    hidden var propRightValueShows as Number = 0;
    hidden var propFourthValueShows as Number = 0;
    hidden var propAodFieldShows as Number = -1;
    hidden var propAodRightFieldShows as Number = -2;
    hidden var propDateFieldShows as Number = -1;
    hidden var propBottomFieldShows as Number = 17;
    (:Square) hidden var propBottomField2Shows as Number = -2;
    hidden var propLeftBarShows as Number = 1;
    hidden var propRightBarShows as Number = 2;
    hidden var propIcon1 as Number = 1;
    hidden var propIcon2 as Number = 2;
    hidden var propSunriseFieldShows as Number = 39;
    hidden var propSunsetFieldShows as Number = 40;
    hidden var propWeatherLine1Shows as Number = 78;
    hidden var propWeatherLine2Shows as Number = 79;
    hidden var cachedHourlyForecast as Array<ForecastWeather> = [];
    hidden var cachedForecastChange as Array? = null;
    hidden var cachedForecastSecondChange as Array? = null;
    hidden var cachedForecastThirdChange as Array? = null;
    hidden var cachedForecastFourthChange as Array? = null;
    hidden var propNotificationCountShows as Number = 14;
    hidden var propWeekOffset as Number = 0;
    hidden var touchAlternativeBottomRow as Array<Number> = [4, 12, 2, 32, -2];

    // Cached labels: topLeft, topRight, bottomLeft, bottomMiddle, bottomRight, bottomFourth
    hidden var cachedLabels as Array<String> = ["", "", "", "", "", ""];

    // Cached strings: UNIT_KCAL, UNIT_M, UNIT_FT, UNIT_STEPS, UNIT_PUSHES, LABEL_NA,
    // LABEL_POS_NA, LABEL_FL, UNIT_DAY
    hidden var cachedTextResources as Array<String> = ["", "", "", "", "", "", "", "", ""];

    const battFull = "|||||||||||||||||||||||||||||||||||";
    const battEmpty = "{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{";
    // Non-clock complications intentionally refresh at most once per minute.
    // Activity, notification, weather, and heart-rate values may lag by up to 60s.
    const fullUpdateIntervalS = 60;
    const currentConditionsUpdateIntervalS = 300;
    const hourlyForecastUpdateIntervalS = 900;
    const weatherCycleIntervalS = 4;
    const weatherCycleMaxChanges = 3;

    // Pre-computed background strings to avoid per-frame string concatenation
    hidden var bgStrings as Array<String> = ["", "#", "##", "###", "####", "#####"];
    hidden var bgStringsAlt as Array<String> = ["", "$", "$$", "$$$", "$$$$", "$$$$$"];

    // Cached weather condition resource IDs to avoid per-frame array allocation
    hidden var cachedWeatherResIds as Array = [
        Rez.Strings.WEATHER_0, Rez.Strings.WEATHER_1, Rez.Strings.WEATHER_2, Rez.Strings.WEATHER_3,
        Rez.Strings.WEATHER_4, Rez.Strings.WEATHER_5, Rez.Strings.WEATHER_6, Rez.Strings.WEATHER_7,
        Rez.Strings.WEATHER_8, Rez.Strings.WEATHER_9, Rez.Strings.WEATHER_10, Rez.Strings.WEATHER_11,
        Rez.Strings.WEATHER_12, Rez.Strings.WEATHER_13, Rez.Strings.WEATHER_14, Rez.Strings.WEATHER_15,
        Rez.Strings.WEATHER_16, Rez.Strings.WEATHER_17, Rez.Strings.WEATHER_18, Rez.Strings.WEATHER_19,
        Rez.Strings.WEATHER_20, Rez.Strings.WEATHER_21, Rez.Strings.WEATHER_22, Rez.Strings.WEATHER_23,
        Rez.Strings.WEATHER_24, Rez.Strings.WEATHER_25, Rez.Strings.WEATHER_26, Rez.Strings.WEATHER_27,
        Rez.Strings.WEATHER_28, Rez.Strings.WEATHER_29, Rez.Strings.WEATHER_30, Rez.Strings.WEATHER_31,
        Rez.Strings.WEATHER_32, Rez.Strings.WEATHER_33, Rez.Strings.WEATHER_34, Rez.Strings.WEATHER_35,
        Rez.Strings.WEATHER_36, Rez.Strings.WEATHER_37, Rez.Strings.WEATHER_38, Rez.Strings.WEATHER_39,
        Rez.Strings.WEATHER_40, Rez.Strings.WEATHER_41, Rez.Strings.WEATHER_42, Rez.Strings.WEATHER_43,
        Rez.Strings.WEATHER_44, Rez.Strings.WEATHER_45, Rez.Strings.WEATHER_46, Rez.Strings.WEATHER_47,
        Rez.Strings.WEATHER_48, Rez.Strings.WEATHER_49, Rez.Strings.WEATHER_50, Rez.Strings.WEATHER_51,
        Rez.Strings.WEATHER_52, Rez.Strings.WEATHER_53
    ];

    enum colorNames {
        bg = 0,
        clock,
        clockBg,
        outline,
        dataVal,
        fieldBg,
        fieldLbl,
        date,
        dateDim,
        notif,
        stress,
        bodybatt,
        moon
    }

    (:Round240) const bottomFieldWidths = [3, 3, 3, 0];
    (:Round260) const bottomFieldWidths = [3, 4, 3, 0];
    (:Round280) const bottomFieldWidths = [4, 3, 4, 0];
    (:Round360) const bottomFieldWidths = [3, 4, 3, 0];
    (:Round390) const bottomFieldWidths = [4, 3, 4, 0];
    (:InstinctCrossover) const bottomFieldWidths = [4, 3, 4, 0];
    (:Round416) const bottomFieldWidths = [4, 4, 4, 0];
    (:Round454) const bottomFieldWidths = [4, 4, 4, 0];
    (:Square) const bottomFieldWidths = [4, 4, 4, 0];

    (:Round240) const barWidth = 3;
    (:Round260) const barWidth = 3;
    (:Round280) const barWidth = 3;
    (:Round360) const barWidth = 3;
    (:Round390) const barWidth = 4;
    (:InstinctCrossover) const barWidth = 4;
    (:Round416) const barWidth = 4;
    (:Round454) const barWidth = 4;
    (:Square) const barWidth = 4;

    function initialize() {
        WatchFace.initialize();
        hrResetState();
        cachedComplicationValues = {};
        lastCurrentConditionsFetch = null;
        lastHourlyForecastFetch = null;
        openMeteoAppliedSnapshotFetchedAt = null;
        runtimeBitmap = 0x1;
        layoutBitmap = 0;

        if(System.getDeviceSettings() has :requiresBurnInProtection && System.getDeviceSettings().requiresBurnInProtection) {
            runtimeBitmap |= 0x8;
        }
        updateProperties();
        
        screenHeight = Toybox.System.getDeviceSettings().screenHeight;
        screenWidth = Toybox.System.getDeviceSettings().screenWidth;
        fontMoon = Application.loadResource(Rez.Fonts.moon);
        fontIcons = Application.loadResource(Rez.Fonts.icons);
        centerX = Math.round(screenWidth / 2);
        centerY = Math.round(screenHeight / 2);
        marginY = Math.round(screenHeight / 30);
        marginX = Math.round(screenWidth / 20);

        refreshLoadedResourcesAndLayout();
        updateWeather();
    }

    hidden function refreshLoadedResourcesAndLayout() as Void {
        loadResources();
        loadAodFallbackResources();

        halfClockHeight = Math.round(clockHeight / 2);
        if(((runtimeBitmap >> 10) & 0x1) == 1) {
            halfClockWidth = Math.round((clockWidth / 5 * 4.2) / 2);
        } else {
            halfClockWidth = Math.round(clockWidth / 2);
        }
        
        halfMarginY = Math.round(marginY / 2);
        if (Toybox has :Complications) {
            runtimeBitmap |= 0x100;
        } else {
            runtimeBitmap &= ~0x100;
        }

        // Cache string resources (loadResource reads from flash each call)
        cachedTextResources = [
            Application.loadResource(Rez.Strings.UNIT_KCAL),
            Application.loadResource(Rez.Strings.UNIT_M),
            Application.loadResource(Rez.Strings.UNIT_FT),
            Application.loadResource(Rez.Strings.UNIT_STEPS),
            Application.loadResource(Rez.Strings.UNIT_PUSHES),
            Application.loadResource(Rez.Strings.LABEL_NA),
            Application.loadResource(Rez.Strings.LABEL_POS_NA),
            Application.loadResource(Rez.Strings.LABEL_FL),
            Application.loadResource(Rez.Strings.UNIT_DAY)
        ];

        calculateLayout();
    }

    hidden function updateActiveLabels() as Void {
        var activeSlots = getActiveBottomRowSlots();
        cachedFieldWidths = getFieldWidths();
        cachedLabels = [
            getLabelByType(propSunriseFieldShows, 1),
            getLabelByType(propSunsetFieldShows, 1),
            getLabelByType(activeSlots[0], cachedFieldWidths[0] - 1),
            getLabelByType(activeSlots[1], cachedFieldWidths[1] - 1),
            getLabelByType(activeSlots[2], cachedFieldWidths[2] - 1),
            getLabelByType(activeSlots[3], cachedFieldWidths[3] - 1)
        ];
    }

    hidden function getPrimaryBottomRowSlots() as Array<Number> {
        return [propLeftValueShows, propMiddleValueShows, propRightValueShows, propFourthValueShows];
    }

    hidden function getActiveBottomRowLayoutSetting() as Number {
        if (((runtimeBitmap >> 9) & 0x1) == 1) {
            return touchAlternativeBottomRow[0];
        }
        return (propBitmapB >> 23) & 0xF;
    }

    hidden function getActiveBottomRowSlots() as Array<Number> {
        if (((runtimeBitmap >> 9) & 0x1) == 1) {
            return [
                touchAlternativeBottomRow[1],
                touchAlternativeBottomRow[2],
                touchAlternativeBottomRow[3],
                touchAlternativeBottomRow[4]
            ];
        }
        return getPrimaryBottomRowSlots();
    }

    hidden function refreshWeatherRequirement() as Void {
        var activeSlots = getActiveBottomRowSlots();
        var weatherFields = [
            propSunriseFieldShows, propSunsetFieldShows,
            propWeatherLine1Shows, propWeatherLine2Shows,
            propDateFieldShows,
            activeSlots[0], activeSlots[1], activeSlots[2], activeSlots[3],
            propBottomFieldShows,
            propAodFieldShows, propAodRightFieldShows,
            getBottomField2Shows(),
            propNotificationCountShows
        ];

        runtimeBitmap &= ~0x20;
        for (var i = 0; i < weatherFields.size(); i++) {
            if (isWeatherSource(weatherFields[i])) {
                runtimeBitmap |= 0x20;
                break;
            }
        }
    }

    public function refreshBottomRowState() as Void {
        var wasWeatherRequired = ((runtimeBitmap >> 5) & 0x1) == 1;
        updateActiveLabels();
        refreshWeatherRequirement();
        if (screenWidth != null) {
            calculateLayout();
            if (((runtimeBitmap >> 5) & 0x1) == 1 && !wasWeatherRequired) {
                initializeWeatherData();
            }
        }
    }

    public function toggleTouchAlternative() as Void {
        if (((runtimeBitmap >> 9) & 0x1) == 1) {
            runtimeBitmap &= ~0x200;
            Application.Properties.setValue("touchAlternativeActive", false);
        } else {
            runtimeBitmap |= 0x200;
            Application.Properties.setValue("touchAlternativeActive", true);
        }
        refreshBottomRowState();
        weatherProviderScheduleImmediateRefreshIfNeeded();
        lastUpdate = null;
        WatchUi.requestUpdate();
    }

    hidden function loadSmallFont(resDefault, resReadable, resLines) as Void {
        var propSmallFontVariant = (propBitmapB >> 13) & 0x3;
        var selectedRes = resLines;
        if (propSmallFontVariant == 0) {
            selectedRes = resDefault;
        } else if (propSmallFontVariant == 1) {
            selectedRes = resReadable;
        }
        fontSmallData = Application.loadResource(selectedRes);
    }

    (:MIP)
    hidden function loadAodFallbackResources() as Void { }

    (:AMOLED)
    hidden function loadAodFallbackResources() as Void {
        if (screenWidth == 260) {
            fontClockOutline = fontClock;
            fontAODData = fontBottomData;
        }
        if (drawAODPattern == null) {
            drawAODPattern = Application.loadResource(Rez.Drawables.aod) as BitmapResource;
        }
    }

    (:Round240)
    hidden function loadResources() as Void {
        var propClockFont = (propBitmapA >> 8) & 0x1;
        if(propClockFont == 0) {
            fontClock = Application.loadResource(Rez.Fonts.segments80narrow);
        } else {
            fontClock = Application.loadResource(Rez.Fonts.segments80narrow_2);
        }
        fontTinyData = Application.loadResource(Rez.Fonts.smol);
        loadSmallFont(Rez.Fonts.led_small, Rez.Fonts.led_small_readable, Rez.Fonts.led_small_lines);
        fontLargeData = Application.loadResource(Rez.Fonts.led);
        fontBottomData = Application.loadResource(Rez.Fonts.led_small);
        fontLabel = Application.loadResource(Rez.Fonts.xsmol);
        fontBattery = fontTinyData;

        clockHeight = 80;
        clockWidth = 220;
        labelHeight = 5;
        labelMargin = 6;
        tinyDataHeight = 8;
        smallDataHeight = 13;
        largeDataHeight = 20;
        largeDataWidth = 18;
        bottomDataWidth = 12;

        baseX = centerX;
        baseY = centerY - smallDataHeight + 4;
        marginY = Math.round(screenHeight / 35);
        layoutBitmap = 10 | (1 << 5);
    }

    (:Round260)
    hidden function loadResources() as Void {
        var propClockFont = (propBitmapA >> 8) & 0x1;
        if(propClockFont == 0) {
            fontClock = Application.loadResource(Rez.Fonts.segments80);
        } else {
            fontClock = Application.loadResource(Rez.Fonts.segments80_2);
        }
        fontTinyData = Application.loadResource(Rez.Fonts.smol);
        loadSmallFont(Rez.Fonts.led_small, Rez.Fonts.led_small_readable, Rez.Fonts.led_small_lines);
        fontLargeData = Application.loadResource(Rez.Fonts.led);
        fontBottomData = fontLargeData;
        fontLabel = Application.loadResource(Rez.Fonts.xsmol);
        fontBattery = fontTinyData;

        clockHeight = 80;
        clockWidth = 227;
        labelHeight = 5;
        labelMargin = 6;
        tinyDataHeight = 8;
        smallDataHeight = 13;
        largeDataHeight = 20;
        largeDataWidth = 18;
        bottomDataWidth = 18;

        baseX = centerX + 1;
        baseY = centerY - smallDataHeight - 1;
        layoutBitmap = 15 | (1 << 5) | (2 << 10);
    }

    (:Round280)
    hidden function loadResources() as Void {
        var propClockFont = (propBitmapA >> 8) & 0x1;
        if(propClockFont == 0) {
            fontClock = Application.loadResource(Rez.Fonts.segments80wide);
        } else {
            fontClock = Application.loadResource(Rez.Fonts.segments80wide_2);
        }
        fontTinyData = Application.loadResource(Rez.Fonts.storre);
        loadSmallFont(Rez.Fonts.led_small, Rez.Fonts.led_small_readable, Rez.Fonts.led_small_lines);
        fontLargeData = Application.loadResource(Rez.Fonts.led);
        fontBottomData = fontLargeData;
        fontLabel = Application.loadResource(Rez.Fonts.smol);
        fontBattery = fontLabel;

        clockHeight = 80;
        clockWidth = 236;
        labelHeight = 8;
        labelMargin = 6;
        tinyDataHeight = 10;
        smallDataHeight = 13;
        largeDataHeight = 20;
        largeDataWidth = 18;
        bottomDataWidth = 18;

        baseX = centerX;
        baseY = centerY - smallDataHeight - 4;
        layoutBitmap = (1 << 5) | (5 << 10);
    }

    (:Round360)
    hidden function loadResources() as Void {
        var propClockFont = (propBitmapA >> 8) & 0x1;
        if(propClockFont == 0) {
            fontClock = Application.loadResource(Rez.Fonts.segments125narrow);
            fontClockOutline = Application.loadResource(Rez.Fonts.segments125narrowoutline);
        } else {
            fontClock = Application.loadResource(Rez.Fonts.segments125narrow_2);
            fontClockOutline = Application.loadResource(Rez.Fonts.segments125narrowoutline_2);
        }
        fontTinyData = Application.loadResource(Rez.Fonts.storre);
        loadSmallFont(Rez.Fonts.led, Rez.Fonts.led_inbetween, Rez.Fonts.led_lines);
        fontLargeData = Application.loadResource(Rez.Fonts.led_big);
        fontBottomData = Application.loadResource(Rez.Fonts.led);
        fontLabel = Application.loadResource(Rez.Fonts.smol);
        fontAODData = fontBottomData;
        fontBattery = Application.loadResource(Rez.Fonts.led_small_lines);

        drawGradient = Application.loadResource(Rez.Drawables.gradient) as BitmapResource;
        drawAODPattern = Application.loadResource(Rez.Drawables.aod) as BitmapResource;

        clockHeight = 125;
        clockWidth = 345;
        labelHeight = 8;
        labelMargin = 8;
        tinyDataHeight = 10;
        smallDataHeight = 20;
        largeDataHeight = 27;
        largeDataWidth = 24;
        bottomDataWidth = 18;

        baseX = centerX;
        baseY = centerY - smallDataHeight + 4;
        layoutBitmap = 20 | (2 << 5) | (10 << 15) | (12 << 20) | (((screenHeight / 20) + 1) << 25);
        marginY = 10;
    }

    (:Round390)
    hidden function loadResources() as Void {
        var propClockFont = (propBitmapA >> 8) & 0x1;
        if(propClockFont == 0) {
            fontClock = Application.loadResource(Rez.Fonts.clock125);
            fontClockOutline = Application.loadResource(Rez.Fonts.clock125outline);
        } else {
            fontClock = Application.loadResource(Rez.Fonts.clock125_2);
            fontClockOutline = Application.loadResource(Rez.Fonts.clock125outline_2);
        }
        fontTinyData = Application.loadResource(Rez.Fonts.led_small_lines);
        loadSmallFont(Rez.Fonts.led, Rez.Fonts.led_inbetween, Rez.Fonts.led_lines);
        fontLargeData = Application.loadResource(Rez.Fonts.led_big);
        fontBottomData = fontLargeData;
        fontLabel = Application.loadResource(Rez.Fonts.storre);
        fontAODData = Application.loadResource(Rez.Fonts.led);
        fontBattery = fontTinyData;

        drawGradient = Application.loadResource(Rez.Drawables.gradient) as BitmapResource;
        drawAODPattern = Application.loadResource(Rez.Drawables.aod) as BitmapResource;

        clockHeight = 125;
        clockWidth = 355;
        labelHeight = 10;
        labelMargin = 8;
        tinyDataHeight = 13;
        smallDataHeight = 20;
        largeDataHeight = 27;
        largeDataWidth = 24;
        bottomDataWidth = 24;

        baseX = centerX;
        baseY = centerY - smallDataHeight - 3;
        layoutBitmap = (2 << 5) | (6 << 10) | (((screenHeight / 20) + 1) << 25);
        marginY = 10;
    }

    (:InstinctCrossover)
    hidden function loadResources() as Void {
        var propClockFont = (propBitmapA >> 8) & 0x1;
        if(propClockFont == 0) {
            fontClock = Application.loadResource(Rez.Fonts.clock125);
            fontClockOutline = Application.loadResource(Rez.Fonts.clock125outline);
        } else {
            fontClock = Application.loadResource(Rez.Fonts.clock125_2);
            fontClockOutline = Application.loadResource(Rez.Fonts.clock125outline_2);
        }
        fontTinyData = Application.loadResource(Rez.Fonts.led_small_lines);
        loadSmallFont(Rez.Fonts.led, Rez.Fonts.led_inbetween, Rez.Fonts.led_lines);
        fontLargeData = Application.loadResource(Rez.Fonts.led_big);
        fontBottomData = fontLargeData;
        fontLabel = Application.loadResource(Rez.Fonts.storre);
        fontAODData = Application.loadResource(Rez.Fonts.led);
        fontBattery = fontTinyData;

        drawGradient = Application.loadResource(Rez.Drawables.gradient) as BitmapResource;
        drawAODPattern = Application.loadResource(Rez.Drawables.aod) as BitmapResource;

        clockHeight = 125;
        clockWidth = 350;
        labelHeight = 10;
        labelMargin = 8;
        tinyDataHeight = 15;
        smallDataHeight = 20;
        largeDataHeight = 27;
        largeDataWidth = 24;
        bottomDataWidth = 24;

        baseX = centerX;
        baseY = centerY;  // Centered for analog hands
        layoutBitmap = (2 << 5) | (10 << 10);
        marginY = 9;
    }

    (:Round416)
    hidden function loadResources() as Void {
        var propClockFont = (propBitmapA >> 8) & 0x1;
        if(propClockFont == 0) {
            fontClock = Application.loadResource(Rez.Fonts.clock125);
            fontClockOutline = Application.loadResource(Rez.Fonts.clock125outline);
        } else {
            fontClock = Application.loadResource(Rez.Fonts.clock125_2);
            fontClockOutline = Application.loadResource(Rez.Fonts.clock125outline_2);
        }
        fontTinyData = Application.loadResource(Rez.Fonts.led_small_lines);
        loadSmallFont(Rez.Fonts.led, Rez.Fonts.led_inbetween, Rez.Fonts.led_lines);
        fontLargeData = Application.loadResource(Rez.Fonts.led_big);
        fontBottomData = fontLargeData;
        fontLabel = Application.loadResource(Rez.Fonts.storre);
        fontAODData = Application.loadResource(Rez.Fonts.led);
        fontBattery = fontTinyData;

        drawGradient = Application.loadResource(Rez.Drawables.gradient) as BitmapResource;
        drawAODPattern = Application.loadResource(Rez.Drawables.aod) as BitmapResource;

        clockHeight = 125;
        clockWidth = 360;
        labelHeight = 10;
        labelMargin = 8;
        tinyDataHeight = 13;
        smallDataHeight = 20;
        largeDataHeight = 27;
        largeDataWidth = 24;
        bottomDataWidth = 24;

        baseX = centerX;
        baseY = centerY - smallDataHeight - 5;
        layoutBitmap = (2 << 5) | (8 << 10) | (((screenHeight / 20) + 1) << 25);
    }

    (:Round454)
    hidden function loadResources() as Void {
        var propClockFont = (propBitmapA >> 8) & 0x1;
        if(propClockFont == 0) {
            fontClock = Application.loadResource(Rez.Fonts.clock145);
            fontClockOutline = Application.loadResource(Rez.Fonts.clock145outline);
        } else {
            fontClock = Application.loadResource(Rez.Fonts.clock145_2);
            fontClockOutline = Application.loadResource(Rez.Fonts.clock145outline_2);
        }
        fontTinyData = Application.loadResource(Rez.Fonts.led_small_lines);
        loadSmallFont(Rez.Fonts.led, Rez.Fonts.led_inbetween, Rez.Fonts.led_lines);
        fontLargeData = Application.loadResource(Rez.Fonts.led_big);
        fontBottomData = fontLargeData;
        fontLabel = Application.loadResource(Rez.Fonts.storre);
        fontAODData = Application.loadResource(Rez.Fonts.led);
        fontBattery = fontTinyData;

        drawGradient = Application.loadResource(Rez.Drawables.gradient) as BitmapResource;
        drawAODPattern = Application.loadResource(Rez.Drawables.aod) as BitmapResource;

        clockHeight = 145;
        clockWidth = 413;
        labelHeight = 10;
        labelMargin = 8;
        tinyDataHeight = 13;
        smallDataHeight = 20;
        largeDataHeight = 27;
        largeDataWidth = 24;
        bottomDataWidth = 24;

        baseX = centerX + 3;
        baseY = centerY - smallDataHeight + 4;
        layoutBitmap = 20 | (2 << 5) | (4 << 10) | (4 << 15) | (((screenHeight / 20) + 1) << 25);
        marginY = 17;
    }

    (:Square)
    hidden function loadResources() as Void {
        var propClockFont = (propBitmapA >> 8) & 0x1;
        if(propClockFont == 0) {
            fontClock = Application.loadResource(Rez.Fonts.clock145);
            fontClockOutline = Application.loadResource(Rez.Fonts.clock145outline);
        } else {
            fontClock = Application.loadResource(Rez.Fonts.clock145_2);
            fontClockOutline = Application.loadResource(Rez.Fonts.clock145outline_2);
        }
        fontTinyData = Application.loadResource(Rez.Fonts.led_small_lines);
        loadSmallFont(Rez.Fonts.led, Rez.Fonts.led_inbetween, Rez.Fonts.led_lines);
        fontLargeData = Application.loadResource(Rez.Fonts.led_big);
        fontBottomData = fontLargeData;
        fontLabel = Application.loadResource(Rez.Fonts.storre);
        fontAODData = Application.loadResource(Rez.Fonts.led);
        fontBattery = fontTinyData;

        drawGradient = Application.loadResource(Rez.Drawables.gradient) as BitmapResource;
        drawAODPattern = Application.loadResource(Rez.Drawables.aod) as BitmapResource;

        clockHeight = 145;
        clockWidth = 413;
        labelHeight = 10;
        labelMargin = 8;
        tinyDataHeight = 13;
        smallDataHeight = 20;
        largeDataHeight = 27;
        largeDataWidth = 24;
        bottomDataWidth = 24;

        baseX = centerX + 3;
        baseY = centerY - smallDataHeight + 4;
        layoutBitmap = 20 | (2 << 5) | (4 << 10) | (4 << 15);
        marginY = 17;
    }

    hidden function computeDisplayValues(now as Gregorian.Info) as Dictionary {
        var values = {};
        var sysStats = System.getSystemStats();
        var activeSlots = getActiveBottomRowSlots();
        var isSleeping = ((runtimeBitmap >> 4) & 0x1) == 1;
        var displayTypes = [
            propSunriseFieldShows, propSunsetFieldShows,
            propWeatherLine1Shows, propWeatherLine2Shows,
            propDateFieldShows, propNotificationCountShows,
            activeSlots[0], activeSlots[1],
            activeSlots[2], activeSlots[3],
            propBottomFieldShows, propAodFieldShows,
            propAodRightFieldShows, getBottomField2Shows()
        ];
        var needsActivityInfo = anyComplicationNeedsActivityInfo(displayTypes)
            || iconNeedsActivityInfo(propIcon1)
            || iconNeedsActivityInfo(propIcon2)
            || barNeedsActivityInfo(propLeftBarShows)
            || barNeedsActivityInfo(propRightBarShows);
        var actInfo = null;
        if (needsActivityInfo) {
            try {
                actInfo = ActivityMonitor.getInfo();
            } catch(e) {}
        }
        cachedSysStats = sysStats;
        refreshCache = {};
        runtimeBitmap &= ~0x6;

        // From updateSlowData logic
        values[:dataClock] = getClockData(now);
        values[:dataMoon] = moonPhase(now);
        values[:dataLabelTopLeft] = cachedLabels[0];
        values[:dataLabelTopRight] = cachedLabels[1];
        values[:dataLabelBottomLeft] = cachedLabels[2];
        values[:dataLabelBottomMiddle] = cachedLabels[3];
        values[:dataLabelBottomRight] = cachedLabels[4];
        values[:dataLabelBottomFourth] = cachedLabels[5];

        // From updateData logic
        var fieldWidths = cachedFieldWidths;
        values[:dataTopLeft] = getDisplayValueByType(propSunriseFieldShows, 5, now, actInfo, sysStats);
        values[:dataTopRight] = getDisplayValueByType(propSunsetFieldShows, 5, now, actInfo, sysStats);
        var aboveLine1 = getWeatherLineDisplayState(propWeatherLine1Shows, 10, now, actInfo, sysStats);
        values[:dataAboveLine1] = aboveLine1[0];
        values[:dataAboveLine1Color] = aboveLine1[1];
        var aboveLine2 = getWeatherLineDisplayState(propWeatherLine2Shows, 10, now, actInfo, sysStats);
        values[:dataAboveLine2] = aboveLine2[0];
        values[:dataAboveLine2Color] = aboveLine2[1];
        values[:dataBelow] = getValueByTypeWithUnit(propDateFieldShows, 10, now, actInfo, sysStats);
        values[:dataNotificationsValue] = getValueByTypeWithUnit(propNotificationCountShows, 2, now, actInfo, sysStats);
        values[:dataNotificationsSuffix] = getNotificationSuffix(propNotificationCountShows, values[:dataNotificationsValue]);
        values[:dataNotificationsColor] = hrGetDisplayValueColor(propNotificationCountShows, themeColors[notif], themeColors[bg]);
        values[:dataBottomLeft] = getDisplayValueByType(activeSlots[0], fieldWidths[0], now, actInfo, sysStats);
        values[:dataBottomLeftColor] = hrGetDisplayValueColor(activeSlots[0], themeColors[dataVal], themeColors[bg]);
        values[:dataBottomMiddle] = getDisplayValueByType(activeSlots[1], fieldWidths[1], now, actInfo, sysStats);
        values[:dataBottomMiddleColor] = hrGetDisplayValueColor(activeSlots[1], themeColors[dataVal], themeColors[bg]);
        values[:dataBottomRight] = getDisplayValueByType(activeSlots[2], fieldWidths[2], now, actInfo, sysStats);
        values[:dataBottomRightColor] = hrGetDisplayValueColor(activeSlots[2], themeColors[dataVal], themeColors[bg]);
        values[:dataBottomFourth] = getDisplayValueByType(activeSlots[3], fieldWidths[3], now, actInfo, sysStats);
        values[:dataBottomFourthColor] = hrGetDisplayValueColor(activeSlots[3], themeColors[dataVal], themeColors[bg]);
        values[:dataBottom] = getDisplayValueByType(propBottomFieldShows, 5, now, actInfo, sysStats);
        values[:dataBottomColor] = hrGetDisplayValueColor(propBottomFieldShows, themeColors[dataVal], themeColors[bg]);
        computeBottomField2Values(values, now, actInfo, sysStats);
        values[:dataIcon1] = getIconState(propIcon1, actInfo);
        values[:dataIcon2] = getIconState(propIcon2, actInfo);
        values[:dataBattery] = getBattData(sysStats);
        values[:dataAODLeft] = getDisplayValueByType(propAodFieldShows, 10, now, actInfo, sysStats);
        values[:dataAODRight] = getDisplayValueByType(propAodRightFieldShows, 5, now, actInfo, sysStats);
        values[:dataLeftBar] = getBarData(propLeftBarShows, actInfo);
        values[:dataRightBar] = getBarData(propRightBarShows, actInfo);

        // Seconds are intentionally shown only while the watch face is active.
        if(isSleeping) {
            values[:dataSeconds] = "";
        } else {
            values[:dataSeconds] = now.sec.format("%02d");
        }

        return values;
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
    }

    // Called when this View is brought to the foreground.
    // Restore the state of this View and prepare it to be shown.
    // This includes loading resources into memory.
    function onShow() as Void {
        runtimeBitmap = (runtimeBitmap & 0x7FF) | 0x1;
        lastUpdate = null;
        lastSlowUpdate = null;
        wakeTimestamp = Time.now().value();
        hrResetState();
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        var isVisible = (runtimeBitmap & 0x1) != 0;
        if(!isVisible) { return; }

        var now = Time.Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var unix_timestamp = Time.now().value();
        var isSleeping = ((runtimeBitmap >> 4) & 0x1) == 1;
        var canBurnIn = ((runtimeBitmap >> 3) & 0x1) == 1;
        var lastWeatherPhase = ((runtimeBitmap >> 11) & 0xFFFFF) - 1;

        if(now.sec % 60 == 0 or lastSlowUpdate == null or unix_timestamp - lastSlowUpdate >= 60) {
            lastSlowUpdate = unix_timestamp;
            updateWeather();
        }

        var phaseBucket = ((unix_timestamp - wakeTimestamp) / weatherCycleIntervalS).toNumber();
        if(lastUpdate == null or unix_timestamp - lastUpdate >= fullUpdateIntervalS) {
            lastUpdate = unix_timestamp;
            cachedValues = computeDisplayValues(now);
            if (phaseBucket > 1048574) { phaseBucket = 1048574; }
            runtimeBitmap = (runtimeBitmap & 0x7FF) | ((phaseBucket + 1) << 11);
        } else {
            // Between full refreshes, only repaint time-driven data and phased weather text.
            // The rest of the complications are allowed to stay cached until the next minute tick.
            cachedValues[:dataClock] = getClockData(now);
            if(isSleeping) {
                cachedValues[:dataSeconds] = "";
            } else {
                cachedValues[:dataSeconds] = now.sec.format("%02d");
            }

            // Only type 79 lines phase-cycle. Recomputing a non-79 line here would be
            // pointless and would dereference the null activityInfo passed below.
            var refreshLine1 = shouldRefreshWeatherLine(propWeatherLine1Shows);
            var refreshLine2 = shouldRefreshWeatherLine(propWeatherLine2Shows);
            if ((refreshLine1 || refreshLine2) && phaseBucket != lastWeatherPhase) {
                if (phaseBucket > 1048574) { phaseBucket = 1048574; }
                runtimeBitmap = (runtimeBitmap & 0x7FF) | ((phaseBucket + 1) << 11);

                var sysStats = cachedSysStats;
                if (sysStats == null) {
                    sysStats = System.getSystemStats();
                    cachedSysStats = sysStats;
                }

                if (refreshLine1) {
                    var aboveLine1 = getWeatherLineDisplayState(propWeatherLine1Shows, 10, now, null, sysStats);
                    cachedValues[:dataAboveLine1] = aboveLine1[0];
                    cachedValues[:dataAboveLine1Color] = aboveLine1[1];
                }

                if (refreshLine2) {
                    var aboveLine2 = getWeatherLineDisplayState(propWeatherLine2Shows, 10, now, null, sysStats);
                    cachedValues[:dataAboveLine2] = aboveLine2[0];
                    cachedValues[:dataAboveLine2Color] = aboveLine2[1];
                }
            }

        }

        if(isSleeping and canBurnIn) {
            drawAOD(dc, now, cachedValues);
        } else {
            drawWatchface(dc, now, false, cachedValues);
        }
    }

    // Called when this View is removed from the screen.
    // Save the state of this View here.
    // This includes freeing resources from memory.
    function onHide() as Void {
        runtimeBitmap &= ~0x1;
    }

    // The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() as Void {
        wakeTimestamp = Time.now().value();
        lastUpdate = null;
        lastSlowUpdate = null;
        runtimeBitmap &= 0x7EF;
        hrResetState();
        WatchUi.requestUpdate();
    }

    // Terminate any active timers and prepare for slow updates.
    function onEnterSleep() as Void {
        lastUpdate = null;
        lastSlowUpdate = null;
        runtimeBitmap = (runtimeBitmap & 0x7FF) | 0x10;
        hrResetState();
        WatchUi.requestUpdate();
    }

    function onSettingsChanged() as Void {
        var wasOpenMeteo = useOpenMeteoProvider();
        var wasWeatherRequired = ((runtimeBitmap >> 5) & 0x1) == 1;
        var previousPropBitmapA = propBitmapA;
        var previousPropBitmapB = propBitmapB;

        updateProperties();

        var isOpenMeteo = useOpenMeteoProvider();
        var isWeatherRequired = ((runtimeBitmap >> 5) & 0x1) == 1;
        var resourceSettingsChanged = ((previousPropBitmapA ^ propBitmapA) & 0x100) != 0
            || ((previousPropBitmapB ^ propBitmapB) & 0x6000) != 0;
        var weatherProviderChanged = wasOpenMeteo != isOpenMeteo;
        var weatherRequirementChanged = wasWeatherRequired != isWeatherRequired;

        if (resourceSettingsChanged) {
            refreshLoadedResourcesAndLayout();
        } else if (screenWidth != null) {
            calculateLayout();
        }

        cachedComplicationValues = {};
        refreshCache = {};
        lastUpdate = null;
        lastSlowUpdate = null;
        hrResetState();

        if (weatherProviderChanged || weatherRequirementChanged) {
            clearCustomWeatherData();
            lastCurrentConditionsFetch = null;
            lastHourlyForecastFetch = null;
            if (!isOpenMeteo || !isWeatherRequired) {
                weatherProviderDeleteScheduledRefresh();
                weatherProviderDeleteSnapshot();
                weatherProviderDeleteState();
            }
        }

        if (isWeatherRequired) {
            if (isOpenMeteo) {
                applyCustomWeatherSnapshot(loadCustomWeatherSnapshot());
            } else {
                updateWeather();
            }
        } else {
            clearCustomWeatherData();
        }
        cachedTempUnit = getTempUnit();
        updateForecastChanges();
        WatchUi.requestUpdate();
    }

    public function onWeatherDataChanged() as Void {
        if (!useOpenMeteoProvider()) {
            return;
        }
        if (((runtimeBitmap >> 5) & 0x1) != 1) {
            return;
        }

        applyCustomWeatherSnapshot(loadCustomWeatherSnapshot());
        cachedTempUnit = getTempUnit();
        updateForecastChanges();
    }

    (:DefaultLayout)
    hidden function calculateLayout() as Void {
        var fieldSpaceingAdj = layoutBitmap & 0x1F;
        var bottomFiveAdj = (layoutBitmap >> 10) & 0x1F;
        var y1 = baseY + halfClockHeight + marginY;
        var y2 = y1 + smallDataHeight + marginY;
        var y3 = y2 + labelHeight + labelMargin + largeDataHeight;

        fieldY = y2 - 3;

        var data_width = Math.sqrt(centerY*centerY - (y3 - centerY)*(y3 - centerY)) * 2 + fieldSpaceingAdj;
        var left_edge = Math.round((screenWidth - data_width) / 2);

        calculateFieldXCoords(data_width, left_edge);

        bottomFiveY = y3 + halfMarginY + bottomFiveAdj - 2;
        calculateSquareLayout();
    }

    (:InstinctCrossover)
    hidden function calculateLayout() as Void {
        var fieldSpaceingAdj = layoutBitmap & 0x1F;
        var bottomFiveAdj = (layoutBitmap >> 10) & 0x1F;
        var y1 = baseY + halfClockHeight + marginY;
        var y2 = y1 + labelHeight + labelMargin + largeDataHeight;

        fieldY = y1 - 3;

        var data_width = Math.sqrt(centerY*centerY - (y2 - centerY)*(y2 - centerY)) * 2 + fieldSpaceingAdj;
        var left_edge = Math.round((screenWidth - data_width) / 2);

        calculateFieldXCoords(data_width, left_edge);

        bottomFiveY = y2 + halfMarginY + bottomFiveAdj - 2;
    }
    
    hidden function calculateFieldXCoords(data_width as Float, left_edge as Number) as Void {
        var digits = getFieldWidths();
        var tot_digits = digits[0] + digits[1] + digits[2] + digits[3];
        if (tot_digits == 0) { return; } 
        var dw1 = Math.round(digits[0] * data_width / tot_digits);
        var dw2 = Math.round(digits[1] * data_width / tot_digits);
        var dw3 = Math.round(digits[2] * data_width / tot_digits);
        var dw4 = Math.round(digits[3] * data_width / tot_digits);

        fieldXCoords[0] = left_edge + Math.round(dw1 / 2);
        fieldXCoords[1] = left_edge + Math.round(dw1 + (dw2 / 2));
        fieldXCoords[2] = left_edge + Math.round(dw1 + dw2 + (dw3 / 2));
        fieldXCoords[3] = left_edge + Math.round(dw1 + dw2 + dw3 + (dw4 / 2));
    }

    (:DefaultLayout)
    hidden function drawWatchface(dc as Dc, now as Gregorian.Info, aod as Boolean, values as Dictionary) as Void {
        var propTopPartShows = (propBitmapB >> 6) & 0x1;
        var propShowClockBg = ((propBitmapA >> 13) & 0x1) == 1;
        var propClockOutlineStyle = (propBitmapA >> 5) & 0x7;
        var propDateAlignment = (propBitmapA >> 18) & 0x1;
        var showSeconds = values[:dataSeconds].length() > 0;
        var textSideAdj = (layoutBitmap >> 15) & 0x1F;
        var clockBgText = (((runtimeBitmap >> 10) & 0x1) == 1) ? "####" : "#####";

        // Clear
        dc.setColor(themeColors[bg], themeColors[bg]);
        dc.clear();
        var yn1 = baseY - halfClockHeight - marginY - smallDataHeight;
        var yn2 = yn1 - marginY - smallDataHeight;

        // Draw Top data fields
        var top_data_height = labelHeight + halfMarginY;
        var top_field_font = fontTinyData;
        var top_field_center_offset = 20;
        if(propTopPartShows == 1) { top_field_center_offset = labelHeight; }
        dc.setColor(themeColors[fieldLbl], Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX - top_field_center_offset, marginY, fontLabel, values[:dataLabelTopLeft], Graphics.TEXT_JUSTIFY_RIGHT);
        dc.drawText(centerX + top_field_center_offset, marginY, fontLabel, values[:dataLabelTopRight], Graphics.TEXT_JUSTIFY_LEFT);

        dc.setColor(themeColors[dataVal], Graphics.COLOR_TRANSPARENT);
        if(propTopPartShows == 0) {
            dc.drawText(centerX - top_field_center_offset, marginY + top_data_height, top_field_font, values[:dataTopLeft], Graphics.TEXT_JUSTIFY_RIGHT);
            dc.drawText(centerX + top_field_center_offset, marginY + top_data_height, top_field_font, values[:dataTopRight], Graphics.TEXT_JUSTIFY_LEFT);

            // Draw Moon
            dc.setColor(themeColors[moon], Graphics.COLOR_TRANSPARENT);
            dc.drawText(centerX, marginY + ((top_data_height + tinyDataHeight) / 2), fontMoon, values[:dataMoon], Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        } else {
            if(top_data_height == halfMarginY) { top_field_font = fontSmallData; }
            dc.drawText(centerX - top_field_center_offset, marginY + top_data_height, top_field_font, values[:dataTopLeft], Graphics.TEXT_JUSTIFY_RIGHT);
            dc.drawText(centerX + top_field_center_offset, marginY + top_data_height, top_field_font, values[:dataTopRight], Graphics.TEXT_JUSTIFY_LEFT);
        }

        // Draw Lines above clock
        dc.setColor(values[:dataAboveLine1Color], Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, yn2, fontSmallData, values[:dataAboveLine1], Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(values[:dataAboveLine2Color], Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, yn1, fontSmallData, values[:dataAboveLine2], Graphics.TEXT_JUSTIFY_CENTER);        

        // Draw Clock
        dc.setColor(themeColors[clockBg], Graphics.COLOR_TRANSPARENT);
        if(propShowClockBg and !aod) {
            dc.drawText(baseX, baseY, fontClock, clockBgText, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
        dc.setColor(themeColors[clock], Graphics.COLOR_TRANSPARENT);
        dc.drawText(baseX, baseY, fontClock, values[:dataClock], Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Draw clock gradient
        if(drawGradient != null and themeColors[bg] == 0x000000 and !aod) {
            dc.drawBitmap(centerX - halfClockWidth, baseY - halfClockHeight, drawGradient);
        }

        if(propClockOutlineStyle == 2 or propClockOutlineStyle == 3) {
            if(fontClockOutline != null) { // Someone has only bothered to draw this font for AMOLED sizes
                // Draw outline
                dc.setColor(themeColors[outline], Graphics.COLOR_TRANSPARENT);
                dc.drawText(baseX, baseY, fontClockOutline, values[:dataClock], Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            }
        }

        // Draw stress and body battery bars
        drawSideBars(dc, values);

        // Draw Line below clock
        var y1 = baseY + halfClockHeight + marginY;
        dc.setColor(themeColors[date], Graphics.COLOR_TRANSPARENT);
        if(propDateAlignment == 0) {
            dc.drawText(baseX - halfClockWidth + textSideAdj, y1, fontSmallData, values[:dataBelow], Graphics.TEXT_JUSTIFY_LEFT);
        } else {
            dc.drawText(baseX, y1, fontSmallData, values[:dataBelow], Graphics.TEXT_JUSTIFY_CENTER);
        }
        
        // Draw seconds
        if(showSeconds) {
            dc.drawText(baseX + halfClockWidth - textSideAdj, y1, fontSmallData, values[:dataSeconds], Graphics.TEXT_JUSTIFY_RIGHT);
        }

        // Draw Notification count
        if(propDateAlignment == 0) {
            if(!showSeconds) { // No seconds, notification on right side
                hrDrawNotificationValue(dc, baseX + halfClockWidth - textSideAdj, y1, values[:dataNotificationsValue], values[:dataNotificationsSuffix], fontSmallData, values[:dataNotificationsColor], themeColors[notif], Graphics.TEXT_JUSTIFY_RIGHT);
            } else {
                var date_width = dc.getTextWidthInPixels(values[:dataBelow], fontSmallData);
                var sec_width = dc.getTextWidthInPixels(values[:dataSeconds], fontSmallData); 
                var date_right_edge = baseX - halfClockWidth + textSideAdj + date_width;
                var sec_left = baseX + halfClockWidth - textSideAdj - sec_width;
                var pos = sec_left - marginX;
                if((sec_left - date_right_edge) < 3 * marginX) {
                    pos = (date_right_edge + sec_left) / 2;
                }
                hrDrawNotificationValue(dc, pos, y1, values[:dataNotificationsValue], values[:dataNotificationsSuffix], fontSmallData, values[:dataNotificationsColor], themeColors[notif], Graphics.TEXT_JUSTIFY_CENTER);
            }
        } else { // Date is centered, notification on left side
            hrDrawNotificationValue(dc, baseX - halfClockWidth, y1, values[:dataNotificationsValue], values[:dataNotificationsSuffix], fontSmallData, values[:dataNotificationsColor], themeColors[notif], Graphics.TEXT_JUSTIFY_LEFT);
        }

        // Draw the three bottom data fields
        var digits = getFieldWidths();

        drawDataField(dc, fieldXCoords[0], fieldY, 3, values[:dataLabelBottomLeft], values[:dataBottomLeft], digits[0], fontLargeData, values[:dataBottomLeftColor]);
        drawDataField(dc, fieldXCoords[1], fieldY, 3, values[:dataLabelBottomMiddle], values[:dataBottomMiddle], digits[1], fontLargeData, values[:dataBottomMiddleColor]);
        drawDataField(dc, fieldXCoords[2], fieldY, 3, values[:dataLabelBottomRight], values[:dataBottomRight], digits[2], fontLargeData, values[:dataBottomRightColor]);
        drawDataField(dc, fieldXCoords[3], fieldY, 3, values[:dataLabelBottomFourth], values[:dataBottomFourth], digits[3], fontLargeData, values[:dataBottomFourthColor]);

        // Draw the 5 digit bottom field(s) and icons
        drawBottomFieldsWithIcons(dc, values);

        // Draw battery icon
        if(screenHeight == 240 and propBottomFieldShows != -2) {
            drawBatteryIcon(dc, centerX + 32, bottomFiveY, values);
        } else {
            drawBatteryIcon(dc, null, null, values);
        }
    }

    (:InstinctCrossover)
    hidden function drawWatchface(dc as Dc, now as Gregorian.Info, aod as Boolean, values as Dictionary) as Void {
        var propTopPartShows = (propBitmapB >> 6) & 0x1;
        var propShowClockBg = ((propBitmapA >> 13) & 0x1) == 1;
        var propClockOutlineStyle = (propBitmapA >> 5) & 0x7;
        var propDateAlignment = (propBitmapA >> 18) & 0x1;
        var showSeconds = values[:dataSeconds].length() > 0;
        var textSideAdj = (layoutBitmap >> 15) & 0x1F;
        var iconYAdj = ((layoutBitmap >> 20) & 0x1F) - 16;
        var clockBgText = (((runtimeBitmap >> 10) & 0x1) == 1) ? "####" : "#####";

        // Clear
        dc.setColor(themeColors[bg], themeColors[bg]);
        dc.clear();

        // Shifted positions: date line is now above clock
        var yn0 = baseY - halfClockHeight - marginY - smallDataHeight;  // date line (above clock)
        var yn1 = yn0 - marginY - smallDataHeight;  // weather line 2
        var yn2 = yn1 - marginY - smallDataHeight;  // weather line 1

        // Draw Top data fields
        var top_data_height = labelHeight + halfMarginY + 2;
        var top_field_font = fontTinyData;
        var top_field_center_offset = 20;
        if(propTopPartShows == 1) { top_field_center_offset = labelHeight; }
        dc.setColor(themeColors[fieldLbl], Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX - top_field_center_offset, marginY, fontLabel, values[:dataLabelTopLeft], Graphics.TEXT_JUSTIFY_RIGHT);
        dc.drawText(centerX + top_field_center_offset, marginY, fontLabel, values[:dataLabelTopRight], Graphics.TEXT_JUSTIFY_LEFT);

        dc.setColor(themeColors[dataVal], Graphics.COLOR_TRANSPARENT);
        if(propTopPartShows == 0) {
            dc.drawText(centerX - top_field_center_offset, marginY + top_data_height, top_field_font, values[:dataTopLeft], Graphics.TEXT_JUSTIFY_RIGHT);
            dc.drawText(centerX + top_field_center_offset, marginY + top_data_height, top_field_font, values[:dataTopRight], Graphics.TEXT_JUSTIFY_LEFT);

            // Draw Moon
            dc.setColor(themeColors[moon], Graphics.COLOR_TRANSPARENT);
            dc.drawText(centerX, marginY + ((top_data_height + tinyDataHeight) / 2), fontMoon, values[:dataMoon], Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        } else {
            if(top_data_height == halfMarginY) { top_field_font = fontSmallData; }
            dc.drawText(centerX - top_field_center_offset, marginY + top_data_height, top_field_font, values[:dataTopLeft], Graphics.TEXT_JUSTIFY_RIGHT);
            dc.drawText(centerX + top_field_center_offset, marginY + top_data_height, top_field_font, values[:dataTopRight], Graphics.TEXT_JUSTIFY_LEFT);
        }

        // Draw Lines above clock (shifted up by one row)
        dc.setColor(values[:dataAboveLine1Color], Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, yn2, fontSmallData, values[:dataAboveLine1], Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(values[:dataAboveLine2Color], Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, yn1, fontSmallData, values[:dataAboveLine2], Graphics.TEXT_JUSTIFY_CENTER);

        // Draw date line ABOVE clock (at yn0)
        dc.setColor(themeColors[date], Graphics.COLOR_TRANSPARENT);
        if(propDateAlignment == 0) {
            dc.drawText(baseX - halfClockWidth + textSideAdj, yn0, fontSmallData, values[:dataBelow], Graphics.TEXT_JUSTIFY_LEFT);
        } else {
            dc.drawText(baseX, yn0, fontSmallData, values[:dataBelow], Graphics.TEXT_JUSTIFY_CENTER);
        }

        // Draw seconds (above clock)
        if(showSeconds) {
            dc.drawText(baseX + halfClockWidth - textSideAdj, yn0, fontSmallData, values[:dataSeconds], Graphics.TEXT_JUSTIFY_RIGHT);
        }

        // Draw Notification count (above clock)
        if(propDateAlignment == 0) {
            if(!showSeconds) {
                hrDrawNotificationValue(dc, baseX + halfClockWidth - textSideAdj, yn0, values[:dataNotificationsValue], values[:dataNotificationsSuffix], fontSmallData, values[:dataNotificationsColor], themeColors[notif], Graphics.TEXT_JUSTIFY_RIGHT);
            } else {
                var date_width = dc.getTextWidthInPixels(values[:dataBelow], fontSmallData);
                var sec_width = dc.getTextWidthInPixels(values[:dataSeconds], fontSmallData);
                var date_right_edge = baseX - halfClockWidth + textSideAdj + date_width;
                var sec_left = baseX + halfClockWidth - textSideAdj - sec_width;
                var pos = sec_left - marginX;
                if((sec_left - date_right_edge) < 3 * marginX) {
                    pos = (date_right_edge + sec_left) / 2;
                }
                hrDrawNotificationValue(dc, pos, yn0, values[:dataNotificationsValue], values[:dataNotificationsSuffix], fontSmallData, values[:dataNotificationsColor], themeColors[notif], Graphics.TEXT_JUSTIFY_CENTER);
            }
        } else {
            hrDrawNotificationValue(dc, baseX - halfClockWidth, yn0, values[:dataNotificationsValue], values[:dataNotificationsSuffix], fontSmallData, values[:dataNotificationsColor], themeColors[notif], Graphics.TEXT_JUSTIFY_LEFT);
        }

        // Draw Clock
        dc.setColor(themeColors[clockBg], Graphics.COLOR_TRANSPARENT);
        if(propShowClockBg and !aod) {
            dc.drawText(baseX, baseY, fontClock, clockBgText, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
        dc.setColor(themeColors[clock], Graphics.COLOR_TRANSPARENT);
        dc.drawText(baseX, baseY, fontClock, values[:dataClock], Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Draw clock gradient
        if(drawGradient != null and themeColors[bg] == 0x000000 and !aod) {
            dc.drawBitmap(centerX - halfClockWidth, baseY - halfClockHeight, drawGradient);
        }

        if(propClockOutlineStyle == 2 or propClockOutlineStyle == 3) {
            if(fontClockOutline != null) {
                dc.setColor(themeColors[outline], Graphics.COLOR_TRANSPARENT);
                dc.drawText(baseX, baseY, fontClockOutline, values[:dataClock], Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            }
        }

        // Draw stress and body battery bars
        drawSideBars(dc, values);

        // Draw the three bottom data fields (directly below clock, no date row)
        var digits = getFieldWidths();

        drawDataField(dc, fieldXCoords[0], fieldY, 3, values[:dataLabelBottomLeft], values[:dataBottomLeft], digits[0], fontLargeData, values[:dataBottomLeftColor]);
        drawDataField(dc, fieldXCoords[1], fieldY, 3, values[:dataLabelBottomMiddle], values[:dataBottomMiddle], digits[1], fontLargeData, values[:dataBottomMiddleColor]);
        drawDataField(dc, fieldXCoords[2], fieldY, 3, values[:dataLabelBottomRight], values[:dataBottomRight], digits[2], fontLargeData, values[:dataBottomRightColor]);
        drawDataField(dc, fieldXCoords[3], fieldY, 3, values[:dataLabelBottomFourth], values[:dataBottomFourth], digits[3], fontLargeData, values[:dataBottomFourthColor]);

        // Draw the 5 digit bottom field
        var step_width = drawDataField(dc, centerX, bottomFiveY, 0, null, values[:dataBottom], 5, fontBottomData, values[:dataBottomColor]);

        // Draw icons
        dc.setColor(themeColors[dataVal], Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX - (step_width / 2) - (marginX / 2), bottomFiveY + (largeDataHeight / 2) + iconYAdj, fontIcons, values[:dataIcon1], Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(centerX + (step_width / 2) + (marginX / 2) - 2, bottomFiveY + (largeDataHeight / 2) + iconYAdj, fontIcons, values[:dataIcon2], Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

        // Draw battery icon
        drawBatteryIcon(dc, null, null, values);
    }

    (:MIP)
    hidden function drawAOD(dc as Dc, now as Gregorian.Info, values as Dictionary) as Void { }

    (:AMOLED)
    hidden function drawAOD(dc as Dc, now as Gregorian.Info, values as Dictionary) as Void {
        var propAodStyle = (propBitmapA >> 15) & 0x3;
        var propClockOutlineStyle = (propBitmapA >> 5) & 0x7;
        var propAodAlignment = (propBitmapA >> 17) & 0x1;
        var textSideAdj = (layoutBitmap >> 15) & 0x1F;
        dc.setColor(0x000000, 0x000000);
        dc.clear();

        if(propAodStyle == 2) {
            drawWatchface(dc, now, true, values);
            drawPattern(dc, 0x000000, (now.min % 3));
        } else if (propAodStyle == 1) {
            var clock_color = themeColors[clock];
            if(clock_color == 0x000000) { clock_color = 0x555555; }

            if(propClockOutlineStyle == 0 or propClockOutlineStyle == 2 or propClockOutlineStyle == 5) {
                // Draw Clock
                dc.setColor(clock_color, Graphics.COLOR_TRANSPARENT);
                dc.drawText(baseX, baseY, fontClock, values[:dataClock], Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            }

            if(propClockOutlineStyle == 1 or propClockOutlineStyle == 2 or propClockOutlineStyle == 3) {
                dc.setColor(themeColors[outline], Graphics.COLOR_TRANSPARENT);
                dc.drawText(baseX, baseY, fontClockOutline, values[:dataClock], Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            }

            if(propClockOutlineStyle == 4) {
                // Filled clock but outline color
                dc.setColor(themeColors[outline], Graphics.COLOR_TRANSPARENT);
                dc.drawText(baseX, baseY, fontClock, values[:dataClock], Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            }

            // Draw clock gradient
            if (drawAODPattern != null) {
                dc.drawBitmap(centerX - halfClockWidth - (now.min % 2), baseY - halfClockHeight, drawAODPattern);
            }

            // Draw Line below clock
            var y1 = baseY + halfClockHeight + marginY;
            dc.setColor(themeColors[dateDim], Graphics.COLOR_TRANSPARENT);
            if(propAodAlignment == 0) {
                dc.drawText(baseX - halfClockWidth + textSideAdj - (now.min % 3), y1, fontAODData, values[:dataAODLeft], Graphics.TEXT_JUSTIFY_LEFT);
            } else {
                dc.drawText(baseX - (now.min % 3), y1, fontAODData, values[:dataAODLeft], Graphics.TEXT_JUSTIFY_CENTER);
            }
            dc.drawText(baseX + halfClockWidth - textSideAdj - 2 - (now.min % 3), y1, fontAODData, values[:dataAODRight], Graphics.TEXT_JUSTIFY_RIGHT);
        }
    }

    (:AMOLED)
    hidden function drawPattern(dc as Dc, color as ColorType, offset as Number) as Void {
        var patternRows = (layoutBitmap >> 25) & 0x1F;
        if(patternRows == 0) { return; }
        var cols = (screenWidth / 20) + 1;
        var patternText = "";
        for(var i = 0; i < cols; i++) { patternText += "S"; }
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        var i = 0;
        while(i < patternRows) {
            dc.drawText(0, i*20 + offset, fontIcons, patternText, Graphics.TEXT_JUSTIFY_LEFT);
            i++;
        }
    }

    hidden function getFieldWidths() as Array<Number> {
        var propFieldLayout = getActiveBottomRowLayoutSetting();
        if(propFieldLayout == 0) { // Auto
            return bottomFieldWidths;
        } else if(propFieldLayout == 1) {
            return [3, 3, 3, 0];
        } else if(propFieldLayout == 2) {
            return [3, 4, 3, 0];
        } else if(propFieldLayout == 3) {
            return [3, 3, 4, 0];
        } else if(propFieldLayout == 4) {
            return [4, 3, 3, 0];
        } else if(propFieldLayout == 5) {
            return [4, 3, 4, 0];
        } else if(propFieldLayout == 6) {
            return [3, 4, 4, 0];
        } else if(propFieldLayout == 7) {
            return [4, 4, 3, 0];
        } else if(propFieldLayout == 8) {
            return [4, 4, 4, 0];
        } else if(propFieldLayout == 9) {
            return [3, 3, 3, 3];
        } else if(propFieldLayout == 10) {
            return [3, 3, 3, 4];
        } else if(propFieldLayout == 11) {
            return [4, 3, 3, 3];
        } else if(propFieldLayout == 12) {
            return [4, 4, 0, 0];
        } else if(propFieldLayout == 14) {
            return [4, 4, 2, 3];
        } else {
            return [5, 3, 3, 0];
        }
    }

    hidden function getCachedDeviceSettings() {
        if(!(refreshCache has :deviceSettingsLoaded)) {
            try {
                refreshCache[:deviceSettings] = System.getDeviceSettings();
            } catch(e) {
                refreshCache[:deviceSettings] = null;
            }
            refreshCache[:deviceSettingsLoaded] = true;
        }
        return refreshCache.get(:deviceSettings);
    }

    hidden function getCachedActivityDetails() {
        if(!(refreshCache has :activityDetailsLoaded)) {
            try {
                refreshCache[:activityDetails] = Activity.getActivityInfo();
            } catch(e) {
                refreshCache[:activityDetails] = null;
            }
            refreshCache[:activityDetailsLoaded] = true;
        }
        return refreshCache.get(:activityDetails);
    }

    hidden function getCachedUserProfile() {
        if(!(refreshCache has :userProfileLoaded)) {
            try {
                refreshCache[:userProfile] = UserProfile.getProfile();
            } catch(e) {
                refreshCache[:userProfile] = null;
            }
            refreshCache[:userProfileLoaded] = true;
        }
        return refreshCache.get(:userProfile);
    }

    hidden function getCachedOpenMeteoSnapshotForSunEvents() as Dictionary? {
        if (refreshCache has :openMeteoSunSnapshotLoaded) {
            return (refreshCache as Dictionary).get(:openMeteoSunSnapshot) as Dictionary?;
        }

        refreshCache[:openMeteoSunSnapshotLoaded] = true;
        var snapshot = null;
        try {
            snapshot = weatherProviderLoadSnapshot();
        } catch(e) {
            System.println("Open-Meteo sun event snapshot load failure: " + e);
        }

        refreshCache[:openMeteoSunSnapshot] = snapshot;
        return snapshot;
    }

    hidden function getOpenMeteoSunEvents(time as Time.Moment) as Array? {
        if (!useOpenMeteoProvider()) { return null; }

        var snapshot = getCachedOpenMeteoSnapshotForSunEvents();
        if (snapshot == null) {
            return null;
        }

        var utcOffsetSeconds = weatherProviderToNumber(snapshot.get("utcOffsetSeconds"));
        var sunEvents = snapshot.get("sunEvents") as Array?;
        var sunEventCount = (sunEvents == null) ? 0 : sunEvents.size();
        if (utcOffsetSeconds == null || sunEventCount == 0) {
            return null;
        }

        var targetDay = weatherProviderGetLocalDayStart(time.value(), utcOffsetSeconds as Number);
        for (var i = 0; i < sunEventCount; i++) {
            var entry = sunEvents[i] as Array?;
            if (entry == null || entry.size() < 3) { continue; }

            var dayStart = weatherProviderGetArrayNumber(entry, 0);
            var sunrise = weatherProviderGetArrayNumber(entry, 1);
            var sunset = weatherProviderGetArrayNumber(entry, 2);
            if (dayStart == null || sunrise == null || sunset == null) { continue; }
            if (dayStart != targetDay) { continue; }

            return [new Time.Moment(sunrise as Number), new Time.Moment(sunset as Number)];
        }

        return null;
    }

    hidden function getCachedSunEvents(time as Time.Moment, cacheKey as String) as Array? {
        if(cacheKey.equals("today")) {
            if(refreshCache has :sunEventsTodayLoaded) { return (refreshCache as Dictionary).get(:sunEventsToday) as Array?; }
            refreshCache[:sunEventsTodayLoaded] = true;
        } else {
            if(refreshCache has :sunEventsTomorrowLoaded) { return (refreshCache as Dictionary).get(:sunEventsTomorrow) as Array?; }
            refreshCache[:sunEventsTomorrowLoaded] = true;
        }

        var events = null;
        if (useOpenMeteoProvider()) {
            events = getOpenMeteoSunEvents(time);
        }

        if (events == null) {
            var activeWeather = getActiveWeatherCondition();
            if (activeWeather != null) {
                var loc = activeWeather.observationLocationPosition;
                if (loc != null) {
                    var sunrise = Weather.getSunrise(loc, time);
                    var sunset = Weather.getSunset(loc, time);
                    if (sunrise != null && sunset != null) {
                        events = [sunrise, sunset];
                    }
                }
            }
        }

        if(cacheKey.equals("today")) {
            refreshCache[:sunEventsToday] = events;
        } else {
            refreshCache[:sunEventsTomorrow] = events;
        }
        return events;
    }

    hidden function drawFieldLabel(dc as Dc, x as Number, y as Number, adjX as Number, label as String?, bgwidth as Number) as Void {
        var propBottomFieldLabelAlignment = (propBitmapA >> 21) & 0x3;
        if(label == null || label.length() == 0) { return; }

        var half_bg_width = Math.round(bgwidth / 2);
        dc.setColor(themeColors[fieldLbl], Graphics.COLOR_TRANSPARENT);
        if(propBottomFieldLabelAlignment == 0) {
            dc.drawText(x - half_bg_width + adjX, y, fontLabel, label, Graphics.TEXT_JUSTIFY_LEFT);
        } else if(propBottomFieldLabelAlignment == 2) {
            dc.drawText(x + half_bg_width - 1 + adjX, y, fontLabel, label, Graphics.TEXT_JUSTIFY_RIGHT);
        } else {
            dc.drawText(x + adjX, y, fontLabel, label, Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

    hidden function getNotificationSuffix(complicationType as Number, value as String) as String {
        if (complicationType == 10 or complicationType == 76) {
            return "\u2764  ";
        }
        if (value.length() == 0) {
            return "";
        }
        if (complicationType == 14) {
            return "\u2665  ";
        }
        return "";
    }

    hidden function drawDataField(dc as Dc, x as Number, y as Number, adjX as Number, label as String?, value as String, width as Number, font as FontResource, valueColor) as Number {
        var propShowDataBg = ((propBitmapA >> 14) & 0x1) == 1;
        var propBottomFieldAlignment = (propBitmapA >> 19) & 0x3;
        if(value.length() == 0 and (label == null or label.length() == 0)) { return 0; }
        if(width == 0) { return 0; }
        if(valueColor == null) { valueColor = themeColors[dataVal]; }
        var valueBg;
        if(screenHeight == 360 and width == 5 and label == null) {
            valueBg = bgStringsAlt[width];
        } else {
            valueBg = bgStrings[width];
        }

        var value_bg_width = (width == 5 && label == null) ? (bottomDataWidth * width) : (largeDataWidth * width);
        var half_bg_width = Math.round(value_bg_width / 2);
        var data_y = y;

        if(label != null && label.length() > 0) {
            drawFieldLabel(dc, x, y, adjX, label, value_bg_width);
            data_y += labelHeight + labelMargin;
        }

        if(propShowDataBg) {
            dc.setColor(themeColors[fieldBg], Graphics.COLOR_TRANSPARENT);
            dc.drawText(x - half_bg_width + adjX, data_y, font, valueBg, Graphics.TEXT_JUSTIFY_LEFT);
        }

        dc.setColor(valueColor, Graphics.COLOR_TRANSPARENT);
        if(propBottomFieldAlignment == 0) {
            dc.drawText(x - half_bg_width + adjX, data_y, font, value, Graphics.TEXT_JUSTIFY_LEFT);
        } else if (propBottomFieldAlignment == 1) {
            dc.drawText(x + adjX, data_y, font, value, Graphics.TEXT_JUSTIFY_CENTER);
        } else if (propBottomFieldAlignment == 2) {
            dc.drawText(x + half_bg_width - 1 + adjX, data_y, font, value, Graphics.TEXT_JUSTIFY_RIGHT);
        } else if (propBottomFieldAlignment == 3 and width != 5) {
            dc.drawText(x - half_bg_width + adjX, data_y, font, value, Graphics.TEXT_JUSTIFY_LEFT);
        } else if (propBottomFieldAlignment == 3 and width == 5) {
            dc.drawText(x + adjX, data_y, font, value, Graphics.TEXT_JUSTIFY_CENTER);
        }

        return value_bg_width;
    }

    hidden function drawSideBars(dc as Dc, values as Dictionary) as Void {
        var propStressDynamicColor = ((propBitmapB >> 15) & 0x1) == 1;
        var barBottomAdj = (layoutBitmap >> 5) & 0x1F;
        var barVal;
        var barHeight;
        var barColor;

        if (values[:dataLeftBar] != null) {
            barVal = values[:dataLeftBar];
            barHeight = Math.round(barVal * (clockHeight / 100.0));
            if (propLeftBarShows == 1 && propStressDynamicColor) {
                barColor = getStressColor(barVal);
            } else {
                barColor = themeColors[stress]; 
            }
            dc.setColor(barColor, Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(
                centerX - halfClockWidth - barWidth - barWidth, baseY + halfClockHeight - barHeight + barBottomAdj, barWidth, barHeight
            );

            if(propLeftBarShows == 6) {
                drawMoveBarTicks(dc, centerX - halfClockWidth - barWidth - barWidth, centerX - halfClockWidth);
            }
        }

        if (values[:dataRightBar] != null) {
            barVal = values[:dataRightBar];
            barHeight = Math.round(barVal * (clockHeight / 100.0));
            if (propRightBarShows == 1 && propStressDynamicColor) {
                barColor = getStressColor(barVal);
            } else {
                barColor = themeColors[bodybatt]; 
            }
            dc.setColor(barColor, Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(
                centerX + halfClockWidth + barWidth, baseY + halfClockHeight - barHeight + barBottomAdj, barWidth, barHeight
            );
            
            if(propRightBarShows == 6) {
                drawMoveBarTicks(dc, centerX + halfClockWidth + barWidth + barWidth, centerX + halfClockWidth);
            }
        }
    }

    hidden function drawMoveBarTicks(dc as Dc, x1, x2) as Void {
        dc.setColor(themeColors[bg], Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawLine(x1, baseY + halfClockHeight - (40 * (clockHeight / 100.0)), x2, baseY + halfClockHeight - (40 * (clockHeight / 100.0)));
        dc.drawLine(x1, baseY + halfClockHeight - (55 * (clockHeight / 100.0)), x2, baseY + halfClockHeight - (55 * (clockHeight / 100.0)));
        dc.drawLine(x1, baseY + halfClockHeight - (70 * (clockHeight / 100.0)), x2, baseY + halfClockHeight - (70 * (clockHeight / 100.0)));
        dc.drawLine(x1, baseY + halfClockHeight - (85 * (clockHeight / 100.0)), x2, baseY + halfClockHeight - (85 * (clockHeight / 100.0)));
        dc.setPenWidth(1);
    }

    hidden function getBatteryDisplayVariant(sysStats as System.Stats?) as Number {
        if(sysStats != null && sysStats.battery < 20) {
            return 1;
        }
        return 3;
    }

    (:AMOLED)
    hidden function drawBatteryIcon(dc as Dc, x as Number?, y as Number?, values as Dictionary) {
        var batteryVariant = getBatteryDisplayVariant(cachedSysStats);
        if(x == null) { x = centerX; }
        if(y == null) { y =  screenHeight - 23; }

        dc.setColor(0x555555, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y, fontIcons, "C", Graphics.TEXT_JUSTIFY_CENTER);
        if(cachedSysStats != null && cachedSysStats.battery <= 15) {
            dc.setColor(0xFF0000, Graphics.COLOR_TRANSPARENT);
        } else {
            dc.setColor(themeColors[dataVal], Graphics.COLOR_TRANSPARENT);
        }
        if(batteryVariant == 3) {
            dc.drawText(x - 19, y + 4, fontBattery, values[:dataBattery], Graphics.TEXT_JUSTIFY_LEFT);
        } else { // centered when not a bar
            dc.drawText(x - 1, y + 4, fontBattery, values[:dataBattery], Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

    (:MIP)
    hidden function drawBatteryIcon(dc as Dc, x as Number?, y as Number?, values as Dictionary) {
        var batteryVariant = getBatteryDisplayVariant(cachedSysStats);
        if(x == null) { x = centerX; }
        if(y == null) { y =  screenHeight - 20; }

        dc.setColor(0x555555, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y, fontIcons, "B", Graphics.TEXT_JUSTIFY_CENTER);
        if(cachedSysStats != null && cachedSysStats.battery <= 15) {
            dc.setColor(0xFF0000, Graphics.COLOR_TRANSPARENT);
        } else {
            dc.setColor(themeColors[dataVal], Graphics.COLOR_TRANSPARENT);
        }
        if(batteryVariant == 3) {
            dc.drawText(x - 11, y + 3, fontBattery, values[:dataBattery], Graphics.TEXT_JUSTIFY_LEFT);
        } else {
            dc.drawText(x - 1, y + 3, fontBattery, values[:dataBattery], Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

    hidden function setColorTheme(theme as Number) as Array<Graphics.ColorType> {
        var themeRes = [
            Rez.Strings.theme_0, Rez.Strings.theme_1, Rez.Strings.theme_2, Rez.Strings.theme_3,
            Rez.Strings.theme_4, Rez.Strings.theme_5, Rez.Strings.theme_6, Rez.Strings.theme_7,
            Rez.Strings.theme_8, Rez.Strings.theme_9, Rez.Strings.theme_10, Rez.Strings.theme_11,
            Rez.Strings.theme_12, Rez.Strings.theme_13, Rez.Strings.theme_14, Rez.Strings.theme_15,
            Rez.Strings.theme_16, Rez.Strings.theme_17, Rez.Strings.theme_18, Rez.Strings.theme_19,
            Rez.Strings.theme_20, Rez.Strings.theme_21, Rez.Strings.theme_22, Rez.Strings.theme_23,
            Rez.Strings.theme_24
        ];

        var str = "";
        if(theme >= 0 and theme < themeRes.size()) {
            str = WatchUi.loadResource(themeRes[theme]);
        } else {
            str = WatchUi.loadResource(Rez.Strings.theme_0);
        }

        return parseThemeString(str);
    }

    hidden function parseThemeString(csv as String) as Array<Graphics.ColorType> {
        var res = new [13]; 
        var comma = 0;
        for(var i=0; i<13; i++) {
            comma = csv.find(",");
            var hex = csv;
            if(comma != null) {
                hex = csv.substring(0, comma);
                csv = csv.substring(comma + 1, csv.length());
            }

            var hexString = hex as String;
            if(hexString.equals("FFFFFFFF")) {
                res[i] = Graphics.COLOR_TRANSPARENT; 
            } else {
                res[i] = hexString.toNumberWithBase(16);
            }
        }
        return res;
    }

    hidden function getValueOrDefault(propName as String, defaultVal as PropertyValueType) as PropertyValueType {
        var val = Application.Properties.getValue(propName);
        if(val == null) {
            return defaultVal;
        }
        return val;
    }

    hidden function complicationNeedsActivityInfo(complicationType as Number) as Boolean {
        var hasComplications = ((runtimeBitmap >> 8) & 0x1) == 1;
        if (complicationType == 0 || complicationType == 1 || complicationType == 2 || complicationType == 3
            || complicationType == 4 || complicationType == 5 || complicationType == 9 || complicationType == 11
            || complicationType == 17 || complicationType == 18 || complicationType == 19 || complicationType == 29
            || complicationType == 32 || complicationType == 33 || complicationType == 58) {
            return true;
        }
        if (complicationType == 6) {
            return !hasComplications;
        }
        return false;
    }

    hidden function anyComplicationNeedsActivityInfo(complicationTypes as Array<Number>) as Boolean {
        for (var i = 0; i < complicationTypes.size(); i++) {
            if (complicationNeedsActivityInfo(complicationTypes[i])) {
                return true;
            }
        }
        return false;
    }

    hidden function iconNeedsActivityInfo(setting as Number) as Boolean {
        return setting == 5;
    }

    hidden function barNeedsActivityInfo(setting as Number) as Boolean {
        return setting >= 3 && setting <= 6;
    }

    hidden function getComplicationValueCacheTtl(complicationType as Number) as Number {
        if (complicationType == 25 || complicationType == 35) {
            return 900;
        }
        if (complicationType == 7 || complicationType == 8 || complicationType == 27 || complicationType == 28
            || complicationType == 31 || complicationType == 39 || complicationType == 40 || complicationType == 76) {
            return 3600;
        }
        return 0;
    }

    hidden function getComplicationLocationCacheKey(complicationType as Number) as String {
        if (complicationType != 39 && complicationType != 40) {
            return "";
        }

        var activeWeather = getActiveWeatherCondition();
        if (activeWeather == null || activeWeather.observationLocationPosition == null) {
            return ":noloc";
        }

        var degrees = activeWeather.observationLocationPosition.toDegrees() as Array?;
        if (degrees == null || degrees.size() < 2 || degrees[0] == null || degrees[1] == null) {
            return ":noloc";
        }

        return ":" + degrees[0].toFloat().format("%.4f") + ":" + degrees[1].toFloat().format("%.4f");
    }

    hidden function getComplicationValueCacheKey(complicationType as Number, width as Number, now as Gregorian.Info) as String {
        var key = complicationType.format("%d") + ":" + width.format("%d");
        if (complicationType == 31 || complicationType == 39 || complicationType == 40) {
            key += ":" + formatNumberOrEmpty(now.year, "%04d") + formatNumberOrEmpty(now.month, "%02d") + formatNumberOrEmpty(now.day, "%02d");
        }
        key += getComplicationLocationCacheKey(complicationType);
        return key;
    }

    hidden function toFloatIfNumeric(value) as Float? {
        if (value instanceof Number) {
            return (value as Number).toFloat();
        }
        if (value instanceof Float) {
            return value as Float;
        }
        return null;
    }

    hidden function getCachedComplicationValue(complicationType as Number, width as Number, now as Gregorian.Info) as String? {
        var ttl = getComplicationValueCacheTtl(complicationType);
        if (ttl <= 0) { return null; }

        var cacheKey = getComplicationValueCacheKey(complicationType, width, now);
        var cachedEntry = cachedComplicationValues.get(cacheKey) as Dictionary?;
        if (cachedEntry == null) { return null; }

        var cachedAt = cachedEntry.get(:timestamp) as Number?;
        if (cachedAt == null || Time.now().value() - cachedAt >= ttl) {
            return null;
        }

        return cachedEntry.get(:value) as String?;
    }

    hidden function cacheComplicationValue(complicationType as Number, width as Number, now as Gregorian.Info, value as String) as Void {
        if (value.length() == 0 || value.equals(cachedTextResources[5]) || value.equals(cachedTextResources[6])) {
            return;
        }

        var ttl = getComplicationValueCacheTtl(complicationType);
        if (ttl <= 0) { return; }

        cachedComplicationValues[getComplicationValueCacheKey(complicationType, width, now)] = {
            :timestamp => Time.now().value(),
            :value => value
        };
    }

    hidden function getDisplayValueByType(complicationType as Number, width as Number, now as Gregorian.Info, activityInfo, sysStats as System.Stats) as String {
        var cachedValue = getCachedComplicationValue(complicationType, width, now);
        if (cachedValue != null) {
            return cachedValue;
        }

        var value = getValueByType(complicationType, width, now, activityInfo, sysStats);
        cacheComplicationValue(complicationType, width, now, value);
        return value;
    }

    hidden function updateProperties() as Void {
        propBitmapA = 0;
        propBitmapA |= (getValueOrDefault("colorTheme", 0) as Number) & 0x1F;
        propBitmapA |= ((getValueOrDefault("clockOutlineStyle", 0) as Number) & 0x7) << 5;
        propBitmapA |= ((getValueOrDefault("clockFont", 0) as Number) & 0x1) << 8;
        // Bits 9:12 are intentionally unused after removing display toggles.
        propBitmapA |= (((getValueOrDefault("showClockBg", true) as Boolean) ? 1 : 0) << 13);
        propBitmapA |= (((getValueOrDefault("showDataBg", true) as Boolean) ? 1 : 0) << 14);
        propBitmapA |= ((getValueOrDefault("aodStyle", 0) as Number) & 0x3) << 15;
        propBitmapA |= ((getValueOrDefault("aodAlignment", 0) as Number) & 0x1) << 17;
        propBitmapA |= ((getValueOrDefault("dateAlignment", 0) as Number) & 0x1) << 18;
        propBitmapA |= ((getValueOrDefault("bottomFieldAlignment", 2) as Number) & 0x3) << 19;
        propBitmapA |= ((getValueOrDefault("bottomFieldLabelAlignment", 0) as Number) & 0x3) << 21;
        propBitmapA |= ((getValueOrDefault("hemisphere", 0) as Number) & 0x1) << 23;
        propBitmapA |= ((getValueOrDefault("hourFormat", 0) as Number) & 0x3) << 24;
        propBitmapA |= ((getValueOrDefault("tempUnit", 0) as Number) & 0x3) << 29;

        propBitmapB = 0;
        propBitmapB |= ((getValueOrDefault("showTempUnit", true) as Boolean) ? 1 : 0);
        propBitmapB |= ((getValueOrDefault("windUnit", 0) as Number) & 0x7) << 1;
        propBitmapB |= ((getValueOrDefault("pressureUnit", 0) as Number) & 0x3) << 4;
        propBitmapB |= ((getValueOrDefault("topPartShows", 0) as Number) & 0x1) << 6;
        propBitmapB |= ((getValueOrDefault("dateFormat", 0) as Number) & 0xF) << 7;
        propBitmapB |= ((getValueOrDefault("smallFontVariant", 2) as Number) & 0x3) << 13;
        propBitmapB |= (((getValueOrDefault("stressDynamicColor", true) as Boolean) ? 1 : 0) << 15);
        propBitmapB |= ((System.getDeviceSettings().is24Hour ? 1 : 0) << 16);
        propBitmapB |= ((getValueOrDefault("weatherProvider", WEATHER_PROVIDER_OPEN_METEO) as Number) & 0x1) << 17;
        propBitmapB |= ((getValueOrDefault("fieldLayout", 11) as Number) & 0xF) << 23;

        propSunriseFieldShows = getValueOrDefault("sunriseFieldShows", 39) as Number;
        propSunsetFieldShows = getValueOrDefault("sunsetFieldShows", 40) as Number;
        propWeatherLine1Shows = getValueOrDefault("weatherLine1Shows", 78) as Number;
        propWeatherLine2Shows = getValueOrDefault("weatherLine2Shows", 79) as Number;
        propDateFieldShows = getValueOrDefault("dateFieldShows", -1) as Number;
        propLeftValueShows = getValueOrDefault("leftValueShows", 11) as Number;
        propMiddleValueShows = getValueOrDefault("middleValueShows", 29) as Number;
        propRightValueShows = getValueOrDefault("rightValueShows", 6) as Number;
        propFourthValueShows = getValueOrDefault("fourthValueShows", 10) as Number;
        touchAlternativeBottomRow = [
            getValueOrDefault("touchAlternativeFieldLayout", 4) as Number,
            getValueOrDefault("touchAlternativeLeftValueShows", 12) as Number,
            getValueOrDefault("touchAlternativeMiddleValueShows", 2) as Number,
            getValueOrDefault("touchAlternativeRightValueShows", 32) as Number,
            getValueOrDefault("touchAlternativeFourthValueShows", -2) as Number
        ];
        if (getValueOrDefault("touchAlternativeActive", false) as Boolean) {
            runtimeBitmap |= 0x200;
        } else {
            runtimeBitmap &= ~0x200;
        }
        propBottomFieldShows = getValueOrDefault("bottomFieldShows", 17) as Number;
        loadBottomField2Property();
        propLeftBarShows = getValueOrDefault("leftBarShows", 1) as Number;
        propRightBarShows = getValueOrDefault("rightBarShows", 2) as Number;
        propIcon1 = getValueOrDefault("icon1", 1) as Number;
        propIcon2 = getValueOrDefault("icon2", 2) as Number;
        propAodFieldShows = getValueOrDefault("aodFieldShows", -1) as Number;
        propAodRightFieldShows = getValueOrDefault("aodRightFieldShows", -2) as Number;
        propNotificationCountShows = getValueOrDefault("notificationCountShows", 14) as Number;
        propWeekOffset = getValueOrDefault("weekOffset", 0) as Number;

        var propTheme = propBitmapA & 0x1F;
        themeColors = setColorTheme(propTheme);
        refreshBottomRowState();

    }

    hidden function getAltitudeValue() as Float? {
        var hasComplications = ((runtimeBitmap >> 8) & 0x1) == 1;
        if(refreshCache has :altitudeValueLoaded) {
            return (refreshCache as Dictionary).get(:altitudeValue) as Float?;
        }

        var altitude = null;

        // 1. Best: Complications (Modern approach)
        if (hasComplications) {
            try {
                var comp = Complications.getComplication(new Id(Complications.COMPLICATION_TYPE_ALTITUDE));
                if (comp != null) {
                    altitude = toFloatIfNumeric(comp.value);
                }
            } catch(e) {}
        }

        // 2. From Sensor History
        if (altitude == null && (Toybox has :SensorHistory) && (Toybox.SensorHistory has :getElevationHistory)) {
            try {
                var elv_iterator = Toybox.SensorHistory.getElevationHistory({:period => 1});
                if (elv_iterator != null) {
                    var sample = elv_iterator.next();
                    if (sample != null) {
                        altitude = toFloatIfNumeric(sample.data);
                    }
                }
            } catch(e) {}
        }

        // 3. Fallback: Activity Info
        if (altitude == null) {
            var info = getCachedActivityDetails();
            if (info != null && info has :altitude && info.altitude != null) {
                altitude = info.altitude.toFloat();
            }
        }

        refreshCache[:altitudeValueLoaded] = true;
        refreshCache[:altitudeValue] = altitude;
        return altitude;
    }

    hidden function getClockData(now as Gregorian.Info) as String {
        // Clock formatting is fixed to zero-padded hours with a colon separator.
        return formatHour(now.hour).format("%02d") + ":" + now.min.format("%02d");
    }

    hidden function getIconState(setting as Number, activityInfo) as String {
        var deviceSettings = getCachedDeviceSettings();
        if (deviceSettings == null) { return ""; }

        if(setting == 1) { // Alarm
            var alarms = (deviceSettings has :alarmCount) ? deviceSettings.alarmCount : null;
            if(alarms != null && alarms > 0) {
                return "A";
            } else {
                return "";
            }
        } else if(setting == 2) { // DND
            var dnd = (deviceSettings has :doNotDisturb) ? deviceSettings.doNotDisturb : false;
            if(dnd) {
                return "D";
            } else {
                return "";
            }
        } else if(setting == 3) { // Bluetooth (on / off)
            var bl = (deviceSettings has :phoneConnected) ? deviceSettings.phoneConnected : false;
            if(bl) {
                return "L";
            } else {
                return "M";
            }
        } else if(setting == 4) { // Bluetooth (just off)
            var bl = (deviceSettings has :phoneConnected) ? deviceSettings.phoneConnected : false;
            if(bl) {
                return "";
            } else {
                return "M";
            }
        } else if(setting == 5) { // Move bar
            var mov = 0;
            if(activityInfo != null && activityInfo has :moveBarLevel) {
                if(activityInfo.moveBarLevel != null) {
                    mov = activityInfo.moveBarLevel;
                }
            }
            if(mov == 0) { return ""; }
            if(mov == 1) { return "N"; }
            if(mov == 2) { return "O"; }
            if(mov == 3) { return "P"; }
            if(mov == 4) { return "Q"; }
            if(mov == 5) { return "R"; }
        }
        return "";
    }

    hidden function getBarData(data_source as Number, activityInfo) as Number? {
        if(data_source == 1) {
            return getStressData();
        } else if (data_source == 2) {
            return getBBData();
        } else if (data_source == 3) {
            return getStepGoalProgress(activityInfo);
        } else if (data_source == 4) {
            return getFloorGoalProgress(activityInfo);
        } else if (data_source == 5) {
            return getActMinGoalProgress(activityInfo);
        } else if (data_source == 6) {
            return getMoveBar(activityInfo);
        }
        return null;
    }

    hidden function getStressData() as Number? {
        var hasComplications = ((runtimeBitmap >> 8) & 0x1) == 1;
        if (((runtimeBitmap >> 1) & 0x1) == 1) { return cachedStressData; }

        var result = null;
        if (hasComplications) {
            try {
                var complication_stress = Complications.getComplication(new Id(Complications.COMPLICATION_TYPE_STRESS));
                if (complication_stress != null && complication_stress.value != null) {
                    result = complication_stress.value;
                }
            } catch(e) {
                // Complication not found
            }
        }

        if (result == null && (Toybox has :SensorHistory) && (Toybox.SensorHistory has :getBodyBatteryHistory) && (Toybox.SensorHistory has :getStressHistory)) {
            try {
                var st_iterator = Toybox.SensorHistory.getStressHistory({:period => 1});
                if (st_iterator != null) {
                    var st = st_iterator.next();

                    if(st != null) {
                        result = st.data;
                    }
                }
            } catch(e) {}
        }

        cachedStressData = result;
        runtimeBitmap |= 0x2;
        return result;
    }

    hidden function getStressColor(val as Number) as Graphics.ColorType {
        if (val <= 25) { return 0x00AAFF; } // Rest (Blue)
        if (val <= 50) { return 0xFFAA00; } // Low (Yellow/Orange)
        if (val <= 75) { return 0xFF5500; } // Medium (Orange)
        return 0xAA0000;                   // High (Red)
    }

    hidden function getBBData() as Number? {
        var hasComplications = ((runtimeBitmap >> 8) & 0x1) == 1;
        if (((runtimeBitmap >> 2) & 0x1) == 1) { return cachedBBData; }

        var result = null;
        if (hasComplications) {
            try {
                var complication_bb = Complications.getComplication(new Id(Complications.COMPLICATION_TYPE_BODY_BATTERY));
                if (complication_bb != null && complication_bb.value != null) {
                    result = complication_bb.value;
                }
            } catch(e) {
                // Complication not found
            }
        }

        if (result == null && (Toybox has :SensorHistory) && (Toybox.SensorHistory has :getBodyBatteryHistory) && (Toybox.SensorHistory has :getStressHistory)) {
            try {
                var bb_iterator = Toybox.SensorHistory.getBodyBatteryHistory({:period => 1});
                if (bb_iterator != null) {
                    var bb = bb_iterator.next();

                    if(bb != null) {
                        result = bb.data;
                    }
                }
            } catch(e) {}
        }

        cachedBBData = result;
        runtimeBitmap |= 0x4;
        return result;
    }

    hidden function getStepGoalProgress(activityInfo) as Number? {
        if (activityInfo == null) { return null; }
        if(activityInfo has :steps && activityInfo has :stepGoal && activityInfo.steps != null && activityInfo.stepGoal != null) {
            var steps = activityInfo.steps;
            var goal = activityInfo.stepGoal;
            if(goal == null or goal == 0) { return 0; }
            if(steps == null or steps == 0) { return 0; }
            return Math.round(steps.toFloat() / goal.toFloat() * 100.0);
        }
        return null;
    }

    hidden function getFloorGoalProgress(activityInfo) as Number? {
        if (activityInfo == null) { return null; }
        if(activityInfo has :floorsClimbed and activityInfo has :floorsClimbedGoal) {
            if(activityInfo.floorsClimbed != null and activityInfo.floorsClimbedGoal != null) {
                var floors = activityInfo.floorsClimbed;
                var goal = activityInfo.floorsClimbedGoal;
                if(goal == null or goal == 0) { return 0; }
                if(floors == null or floors == 0) { return 0; }
                return Math.round(floors.toFloat() / goal.toFloat() * 100.0);
            }
        }
        return null;
    }

    hidden function getActMinGoalProgress(activityInfo) as Number? {
        if (activityInfo == null) { return null; }
        if(activityInfo has :activeMinutesWeek && activityInfo has :activeMinutesWeekGoal && activityInfo.activeMinutesWeek != null && activityInfo.activeMinutesWeekGoal != null) {
            var actmin = activityInfo.activeMinutesWeek;
            if(!(actmin has :total) || actmin.total == null) { return null; }
            var val = actmin.total;
            var goal = activityInfo.activeMinutesWeekGoal;
            if(goal == null or goal == 0) { return 0; }
            if(val == null or val == 0) { return 0; }
            return Math.round(val.toFloat() / goal.toFloat() * 100.0);
        }
        return null;
    }

    hidden function getMoveBar(activityInfo) as Number? {
        if (activityInfo == null) { return null; }
        if(activityInfo has :moveBarLevel) {
            if(activityInfo.moveBarLevel != null) {
                var mov = activityInfo.moveBarLevel;
                if(mov == 1) { return 40; }
                if(mov == 2) { return 55; }
                if(mov == 3) { return 70; }
                if(mov == 4) { return 85; }
                if(mov == 5) { return 100; }
            }
        }
        return null;
    }

    hidden function getBattData(sysStats as System.Stats) as String {
        var value = "";
        var batteryVariant = getBatteryDisplayVariant(sysStats);

        if(batteryVariant == 1) {
            var sample = sysStats.battery;
            if(sample < 100) {
                value = sample.format("%d") + "%";
            } else {
                value = sample.format("%d");
            }
        } else {
            var sample = 0;
            var max = 0;
            var batLevel = sysStats.battery;

            if(screenHeight > 280) {
                sample = Math.round(batLevel / 100.0 * 35).toNumber();
                max = 35;
            } else {
                sample = Math.round(batLevel / 100.0 * 20).toNumber();
                max = 20;
            }
            if(sample > 0) {
                value += battFull.substring(0, sample);
            }

            if(sample < max) {
                value += battEmpty.substring(0, max - sample);
            }
        }

        return value;
    }

    hidden function formatHour(hour as Number) as Number {
        var propIs24H = ((propBitmapB >> 16) & 0x1) == 1;
        var propHourFormat = (propBitmapA >> 24) & 0x3;
        if((!propIs24H and propHourFormat == 0) or propHourFormat == 2) {
            hour = hour % 12;
            if(hour == 0) { hour = 12; }
        }
        return hour;
    }

    hidden function getActiveWeatherCondition() {
        return weatherCondition;
    }

    hidden function getActiveForecastChange() as Array? {
        return cachedForecastChange;
    }

    hidden function getActiveForecastSecondChange() as Array? {
        return cachedForecastSecondChange;
    }

    hidden function getActiveForecastThirdChange() as Array? {
        return cachedForecastThirdChange;
    }

    hidden function getActiveForecastFourthChange() as Array? {
        return cachedForecastFourthChange;
    }

    hidden function toNumberOrNull(value) as Number? {
        if (value == null) { return null; }
        return value.toNumber();
    }

    hidden function formatNumberOrEmpty(value, format as String) as String {
        var numberValue = toNumberOrNull(value);
        if (numberValue == null) { return ""; }
        return numberValue.format(format);
    }

    hidden function valueToStringOrNull(value) as String? {
        if (value == null) { return null; }
        if (value instanceof String) { return value as String; }
        return (value as Lang.Object).toString();
    }

    hidden function toFloatOrNull(value) as Float? {
        if (value == null) { return null; }
        return value.toFloat();
    }

    hidden function useOpenMeteoProvider() as Boolean {
        return ((propBitmapB >> 17) & 0x1) == WEATHER_PROVIDER_OPEN_METEO;
    }

    hidden function buildForecastWeatherFromSnapshotEntry(entry as Dictionary?, location as Position.Location or Null) as ForecastWeather {
        var forecast = new ForecastWeather();
        if (entry == null) { return forecast; }

        forecast.observationLocationPosition = location;
        forecast.forecastTime = toNumberOrNull(entry.get("forecastTime"));
        forecast.forecastHour = toNumberOrNull(entry.get("forecastHour"));
        forecast.condition = toNumberOrNull(entry.get("condition"));
        forecast.temperature = toNumberOrNull(entry.get("temperature"));
        forecast.windBearing = toNumberOrNull(entry.get("windBearing"));
        forecast.windSpeed = toFloatOrNull(entry.get("windSpeed"));
        forecast.precipitationChance = toNumberOrNull(entry.get("precipitationChance"));
        forecast.highTemperature = toNumberOrNull(entry.get("highTemperature"));
        forecast.lowTemperature = toNumberOrNull(entry.get("lowTemperature"));
        forecast.feelsLikeTemperature = toFloatOrNull(entry.get("feelsLikeTemperature"));
        forecast.relativeHumidity = toNumberOrNull(entry.get("relativeHumidity"));

        var uv = toFloatOrNull(entry.get("uvIndex"));
        if (uv != null && uv >= 0.0f) {
            forecast.uvIndex = uv;
        }

        return forecast;
    }

    hidden function buildForecastWeatherFromSnapshotColumns(columns as Array?, index as Number, utcOffsetSeconds as Number, location as Position.Location or Null) as ForecastWeather? {
        var count = weatherProviderGetBackgroundHourlyColumnCount(columns);
        if (count <= 0 || index < 0 || index >= count) { return null; }

        var startTime = weatherProviderGetArrayNumber(columns, 0);
        var detailCount = weatherProviderGetArrayNumber(columns, 2);
        if (startTime == null) { return null; }
        if (detailCount == null) { detailCount = 0; }

        var forecastTime = (startTime as Number) + (index * 3600);
        var forecast = new ForecastWeather();
        forecast.observationLocationPosition = location;
        forecast.forecastTime = forecastTime;
        forecast.forecastHour = weatherProviderGetForecastHour(forecastTime, utcOffsetSeconds);
        forecast.condition = weatherProviderGetArrayNumber(weatherProviderGetArrayValue(columns, 3) as Array?, index);
        forecast.feelsLikeTemperature = weatherProviderGetArrayFloat(weatherProviderGetArrayValue(columns, 4) as Array?, index);

        if (index < (detailCount as Number)) {
            forecast.temperature = weatherProviderGetArrayNumber(weatherProviderGetArrayValue(columns, 5) as Array?, index);
            forecast.precipitationChance = weatherProviderGetArrayNumber(weatherProviderGetArrayValue(columns, 6) as Array?, index);
            forecast.relativeHumidity = weatherProviderGetArrayNumber(weatherProviderGetArrayValue(columns, 7) as Array?, index);
            forecast.windBearing = weatherProviderGetArrayNumber(weatherProviderGetArrayValue(columns, 8) as Array?, index);
            forecast.windSpeed = weatherProviderGetArrayFloat(weatherProviderGetArrayValue(columns, 9) as Array?, index);

            var uv = weatherProviderGetArrayFloat(weatherProviderGetArrayValue(columns, 10) as Array?, index);
            if (uv != null && uv >= 0.0f) { forecast.uvIndex = uv; }
        }

        return forecast;
    }

    hidden function copyWeatherToSnapshot(snapshot as ForecastWeather, weather) as Void {
        if (weather == null) { return; }

        if (weather.observationLocationPosition != null) { snapshot.observationLocationPosition = weather.observationLocationPosition; }
        if (weather.precipitationChance != null) { snapshot.precipitationChance = weather.precipitationChance; }
        if (weather.temperature != null) { snapshot.temperature = weather.temperature.toNumber(); }
        if (weather.windBearing != null) { snapshot.windBearing = weather.windBearing.toNumber(); }
        if (weather.windSpeed != null) { snapshot.windSpeed = weather.windSpeed.toFloat(); }
        if (weather.highTemperature != null) { snapshot.highTemperature = weather.highTemperature.toNumber(); }
        if (weather.lowTemperature != null) { snapshot.lowTemperature = weather.lowTemperature.toNumber(); }
        if (weather.feelsLikeTemperature != null) { snapshot.feelsLikeTemperature = weather.feelsLikeTemperature.toFloat(); }
        if (weather.relativeHumidity != null) { snapshot.relativeHumidity = weather.relativeHumidity.toNumber(); }
        if (weather.condition != null) { snapshot.condition = weather.condition.toNumber(); }
        if (weather has :uvIndex && weather.uvIndex != null && weather.uvIndex.toFloat() >= 0.0f) {
            snapshot.uvIndex = weather.uvIndex.toFloat();
        }
        if (weather has :forecastTime && weather.forecastTime != null) {
            snapshot.forecastTime = weather.forecastTime.toNumber();
        }
        if (weather has :forecastHour && weather.forecastHour != null) {
            snapshot.forecastHour = weather.forecastHour.toNumber();
        }
    }

    hidden function buildMergedForecastWeather(forecast as ForecastWeather or Null) as ForecastWeather {
        var snapshot = new ForecastWeather();
        copyWeatherToSnapshot(snapshot, weatherCondition);
        copyWeatherToSnapshot(snapshot, forecast);
        if (forecast != null) {
            // A forecast event must not present the current feels-like value as a
            // future measurement when that field is missing from the forecast.
            if (forecast.feelsLikeTemperature == null) {
                snapshot.feelsLikeTemperature = null;
            }
            if (snapshot.condition != null) {
                snapshot.condition = normalizeWeatherCondition(snapshot.condition as Number, cachedWeatherResIds.size());
            }
        }
        return snapshot;
    }

    hidden function buildForecastWeatherFromLive(entry) as ForecastWeather {
        var forecast = new ForecastWeather();
        if (entry == null) { return forecast; }

        if (entry.forecastTime != null) {
            forecast.forecastTime = entry.forecastTime.value();
            forecast.forecastHour = Time.Gregorian.info(entry.forecastTime, Time.FORMAT_SHORT).hour;
        }

        forecast.condition = toNumberOrNull(entry.condition);
        forecast.temperature = toNumberOrNull(entry.temperature);
        forecast.windBearing = toNumberOrNull(entry.windBearing);
        forecast.windSpeed = toFloatOrNull(entry.windSpeed);
        forecast.precipitationChance = toNumberOrNull(entry.precipitationChance);

        if (entry has :highTemperature) { forecast.highTemperature = toNumberOrNull(entry.highTemperature); }
        if (entry has :lowTemperature) { forecast.lowTemperature = toNumberOrNull(entry.lowTemperature); }
        if (entry has :feelsLikeTemperature) { forecast.feelsLikeTemperature = toFloatOrNull(entry.feelsLikeTemperature); }
        if (entry has :relativeHumidity) { forecast.relativeHumidity = toNumberOrNull(entry.relativeHumidity); }
        if (entry has :uvIndex) {
            var uv = toFloatOrNull(entry.uvIndex);
            if (uv != null && uv >= 0.0f) { forecast.uvIndex = uv; }
        }

        return forecast;
    }

    hidden function clearCustomWeatherData() as Void {
        weatherCondition = null;
        cachedHourlyForecast = [];
        cachedForecastChange = null;
        cachedForecastSecondChange = null;
        cachedForecastThirdChange = null;
        cachedForecastFourthChange = null;
        openMeteoAppliedSnapshotFetchedAt = null;
    }

    hidden function loadCustomWeatherSnapshot() as Dictionary? {
        try {
            return weatherProviderLoadSnapshot();
        } catch(e) {
            System.println("Open-Meteo snapshot load failure: " + e);
            weatherProviderDeleteSnapshot();
        }
        return null;
    }

    hidden function applyCustomWeatherSnapshot(snapshot as Dictionary?) as Void {
        var fetchedAt = (snapshot == null) ? null : weatherProviderToNumber(snapshot.get("fetchedAt"));
        var appliedFetchedAt = openMeteoAppliedSnapshotFetchedAt;
        if (fetchedAt != null && appliedFetchedAt != null && fetchedAt == appliedFetchedAt && weatherCondition != null) {
            return;
        }

        clearCustomWeatherData();
        if (snapshot == null) {
            return;
        }

        try {
            var location = weatherProviderBuildLocation(snapshot.get("location") as Array?);
            var current = snapshot.get("current") as Dictionary?;
            var currentWeather = buildForecastWeatherFromSnapshotEntry(current, location);
            weatherCondition = currentWeather;

            var hourly = snapshot.get("hourly") as Array?;
            if (hourly != null) {
                for (var i = 0; i < hourly.size(); i++) {
                    cachedHourlyForecast.add(buildForecastWeatherFromSnapshotEntry(hourly[i] as Dictionary?, location));
                }
            }
            if (cachedHourlyForecast.size() == 0) {
                var hourlyColumns = snapshot.get("hourlyColumns") as Array?;
                var utcOffsetSeconds = weatherProviderToNumber(snapshot.get("utcOffsetSeconds"));
                var hourlyColumnCount = weatherProviderGetBackgroundHourlyColumnCount(hourlyColumns);
                if (utcOffsetSeconds != null && hourlyColumnCount > 0) {
                    for (var j = 0; j < hourlyColumnCount; j++) {
                        var forecast = buildForecastWeatherFromSnapshotColumns(hourlyColumns, j, utcOffsetSeconds as Number, location);
                        if (forecast != null) { cachedHourlyForecast.add(forecast); }
                    }
                }
            }
            if (fetchedAt != null) { openMeteoAppliedSnapshotFetchedAt = fetchedAt; }
        } catch(e) {
            clearCustomWeatherData();
            System.println("Open-Meteo snapshot apply failure: " + e);
            weatherProviderDeleteSnapshot();
        }
    }

    public function scheduleImmediateCustomWeatherRefreshIfNeeded() as Void {
        if (!useOpenMeteoProvider()) { return; }
        weatherProviderScheduleImmediateRefreshIfNeeded();
    }

    (:WeatherCache)
    hidden function buildForecastWeatherFromStored(entry) as ForecastWeather {
        var forecast = new ForecastWeather();
        if (entry == null) { return forecast; }

        forecast.forecastTime = toNumberOrNull(entry.get("forecastTime"));
        forecast.forecastHour = toNumberOrNull(entry.get("forecastHour"));
        forecast.condition = toNumberOrNull(entry.get("condition"));
        forecast.temperature = toNumberOrNull(entry.get("temperature"));
        forecast.windBearing = toNumberOrNull(entry.get("windBearing"));
        forecast.windSpeed = toFloatOrNull(entry.get("windSpeed"));
        forecast.precipitationChance = toNumberOrNull(entry.get("precipitationChance"));
        forecast.highTemperature = toNumberOrNull(entry.get("highTemperature"));
        forecast.lowTemperature = toNumberOrNull(entry.get("lowTemperature"));
        forecast.feelsLikeTemperature = toFloatOrNull(entry.get("feelsLikeTemperature"));
        forecast.relativeHumidity = toNumberOrNull(entry.get("relativeHumidity"));

        var uv = toFloatOrNull(entry.get("uvIndex"));
        if (uv != null && uv >= 0.0f) {
            forecast.uvIndex = uv;
        }

        return forecast;
    }

    (:WeatherCache)
    hidden function initializeWeatherData() as Void {
        if (((runtimeBitmap >> 5) & 0x1) == 1 && weatherCondition == null) {
            if (useOpenMeteoProvider()) {
                applyCustomWeatherSnapshot(loadCustomWeatherSnapshot());
                scheduleImmediateCustomWeatherRefreshIfNeeded();
            } else {
                try { weatherCondition = readWeatherData(); } catch(e) {}
                if (weatherCondition == null) {
                    if(Toybox has :Weather && Weather has :getCurrentConditions) {
                        weatherCondition = Weather.getCurrentConditions();
                    }
                }
            }
        }
        cachedTempUnit = getTempUnit();
        if (!useOpenMeteoProvider()) {
            updateHourlyForecastData(null);
        }
        updateForecastChanges();
    }

    (:NoWeatherCache)
    hidden function initializeWeatherData() as Void {
        if (((runtimeBitmap >> 5) & 0x1) == 1 && weatherCondition == null) {
            if (useOpenMeteoProvider()) {
                applyCustomWeatherSnapshot(loadCustomWeatherSnapshot());
                scheduleImmediateCustomWeatherRefreshIfNeeded();
            } else if(Toybox has :Weather && Weather has :getCurrentConditions) {
                weatherCondition = Weather.getCurrentConditions();
            }
        }
        cachedTempUnit = getTempUnit();
        if (!useOpenMeteoProvider()) {
            updateHourlyForecastData(null);
        }
        updateForecastChanges();
    }

    (:WeatherCache)
    hidden function updateWeather() as Void {
        if (((runtimeBitmap >> 5) & 0x1) != 1) { return; }
        if (useOpenMeteoProvider()) {
            applyCustomWeatherSnapshot(loadCustomWeatherSnapshot());
            scheduleImmediateCustomWeatherRefreshIfNeeded();
            cachedTempUnit = getTempUnit();
            updateForecastChanges();
            return;
        }
        if(!(Toybox has :Weather) or !(Weather has :getCurrentConditions)) { return; }

        var now = Time.now().value();
        var shouldFetchCurrentConditions = weatherCondition == null
            || lastCurrentConditionsFetch == null
            || now - (lastCurrentConditionsFetch as Number) >= currentConditionsUpdateIntervalS;
        var shouldFetchHourlyForecast = cachedHourlyForecast.size() == 0
            || lastHourlyForecastFetch == null
            || now - (lastHourlyForecastFetch as Number) >= hourlyForecastUpdateIntervalS;

        var cc = null;
        var hf = null;
        if (shouldFetchCurrentConditions) {
            cc = Weather.getCurrentConditions();
            lastCurrentConditionsFetch = now;
        }
        if (shouldFetchHourlyForecast) {
            lastHourlyForecastFetch = now;
            if (Weather has :getHourlyForecast) {
                hf = Weather.getHourlyForecast();
            }
        }

        if(cc != null) {
            weatherCondition = cc;
        } else if (weatherCondition == null) {
            try { weatherCondition = readWeatherData(); } catch(e) {}
        }

        if (cc != null || shouldFetchHourlyForecast) {
            try { storeWeatherData(cc, shouldFetchHourlyForecast ? hf : null); } catch(e) {}
        }

        cachedTempUnit = getTempUnit();
        if (shouldFetchHourlyForecast) {
            updateHourlyForecastData(hf);
        }
        updateForecastChanges();
    }

    (:NoWeatherCache)
    hidden function updateWeather() as Void {
        if (((runtimeBitmap >> 5) & 0x1) != 1) { return; }
        if (useOpenMeteoProvider()) {
            applyCustomWeatherSnapshot(loadCustomWeatherSnapshot());
            scheduleImmediateCustomWeatherRefreshIfNeeded();
            cachedTempUnit = getTempUnit();
            updateForecastChanges();
            return;
        }
        if(!(Toybox has :Weather) or !(Weather has :getCurrentConditions)) { return; }

        var now = Time.now().value();
        var shouldFetchCurrentConditions = weatherCondition == null
            || lastCurrentConditionsFetch == null
            || now - (lastCurrentConditionsFetch as Number) >= currentConditionsUpdateIntervalS;
        var shouldFetchHourlyForecast = cachedHourlyForecast.size() == 0
            || lastHourlyForecastFetch == null
            || now - (lastHourlyForecastFetch as Number) >= hourlyForecastUpdateIntervalS;

        var cc = null;
        var hf = null;
        if (shouldFetchCurrentConditions) {
            cc = Weather.getCurrentConditions();
            lastCurrentConditionsFetch = now;
        }
        if (shouldFetchHourlyForecast) {
            lastHourlyForecastFetch = now;
            if (Weather has :getHourlyForecast) {
                hf = Weather.getHourlyForecast();
            }
        }

        if (cc != null) {
            weatherCondition = cc;
        }
        cachedTempUnit = getTempUnit();
        if (shouldFetchHourlyForecast) {
            updateHourlyForecastData(hf);
        }
        updateForecastChanges();
    }

    (:WeatherCache)
    hidden function updateHourlyForecastData(hfOverride as Array?) as Void {
        cachedHourlyForecast = [];
        var hf = hfOverride;

        if (hf == null && Toybox has :Weather && Weather has :getHourlyForecast) {
            hf = Weather.getHourlyForecast();
        }

        if (hf != null) {
            if (hf != null && hf.size() > 0) {
                for (var i = 0; i < hf.size(); i++) {
                    cachedHourlyForecast.add(buildForecastWeatherFromLive(hf[i]));
                }
                return;
            }
        }

        var hfData = Application.Storage.getValue("hourly_forecast") as Array?;
        if (hfData == null) { return; }

        for (var i = 0; i < hfData.size(); i++) {
            cachedHourlyForecast.add(buildForecastWeatherFromStored(hfData[i]));
        }
    }

    (:NoWeatherCache)
    hidden function updateHourlyForecastData(hfOverride as Array?) as Void {
        cachedHourlyForecast = [];
        var hf = hfOverride;

        if (hf == null) {
            if (!(Toybox has :Weather) || !(Weather has :getHourlyForecast)) { return; }
            hf = Weather.getHourlyForecast();
        }

        if (hf == null || hf.size() == 0) { return; }

        for (var i = 0; i < hf.size(); i++) {
            cachedHourlyForecast.add(buildForecastWeatherFromLive(hf[i]));
        }
    }

    hidden function isWeatherSource(id as Number) as Boolean {
        if (id == 20 || id == 39 || id == 40 || (id >= 43 && id <= 55) || (id >= 63 && id <= 70) || (id >= 73 && id <= 75) || (id >= 77 && id <= 79)) {
            return true;
        }
        return false;
    }

    (:WeatherCache)
    hidden function computeCcHash(cc) as Number {
        if (cc == null) { return 0; }
        
        var h = 17;

        var t = (cc.temperature != null) ? cc.temperature : -127;
        h = 31 * h + t;
        var c = (cc.condition != null) ? cc.condition : -1;
        h = 31 * h + c;
        var w = (cc.windSpeed != null) ? cc.windSpeed.toNumber() : -1;
        h = 31 * h + w;
        var b = (cc.windBearing != null) ? cc.windBearing : -1;
        h = 31 * h + b;

        return h;
    }

    (:WeatherCache)
    hidden function storeWeatherData(cc, hf as Array?) as Void {
        var now = Time.now().value();
        var sysStats = System.getSystemStats();
        var isLowMem = ((runtimeBitmap >> 6) & 0x1) == 1;

        if (!isLowMem && sysStats.freeMemory < 15000) {
            runtimeBitmap |= 0x40;
            Application.Storage.setValue("hourly_forecast", []); 
            lastHfTime = null; 
        } else if (isLowMem && sysStats.freeMemory > 17000) {
            runtimeBitmap &= ~0x40;
        }

        if (cc != null) {
            var newCcHash = computeCcHash(cc);

            if (lastCcHash == null || lastCcHash != newCcHash) {
                var cc_data = {};
                if(cc.observationLocationPosition != null) {
                    cc_data["observationLocationPosition"] = cc.observationLocationPosition.toDegrees();
                }
                if(cc.condition != null) { cc_data["condition"] = cc.condition; }
                if(cc.highTemperature != null) { cc_data["highTemperature"] = cc.highTemperature; }
                if(cc.lowTemperature != null) { cc_data["lowTemperature"] = cc.lowTemperature; }
                if(cc.precipitationChance != null) { cc_data["precipitationChance"] = cc.precipitationChance; }
                if(cc.relativeHumidity != null) { cc_data["relativeHumidity"] = cc.relativeHumidity; }
                if(cc.temperature != null) { cc_data["temperature"] = cc.temperature; }
                if(cc.feelsLikeTemperature != null) { cc_data["feelsLikeTemperature"] = cc.feelsLikeTemperature; }
                if(cc.windBearing != null) { cc_data["windBearing"] = cc.windBearing; }
                if(cc.windSpeed != null) { cc_data["windSpeed"] = cc.windSpeed; }
                if (cc has :uvIndex && cc.uvIndex != null) {
                    cc_data["uvIndex"] = cc.uvIndex;
                } else {
                    cc_data["uvIndex"] = -1;
                }
                cc_data["timestamp"] = now;
                Application.Storage.setValue("current_conditions", cc_data);

                lastCcHash = newCcHash;
            }
        }

        if (((runtimeBitmap >> 6) & 0x1) == 1) { return; }

        if (hf == null || hf.size() == 0) { return; }

        var firstForecastTime = hf[0].forecastTime.value();

        if (lastHfTime == null || lastHfTime != firstForecastTime) {
            var hf_data = [];
            
            for(var i=0; i<hf.size(); i++) {
                var tmp = {
                    "forecastTime" => hf[i].forecastTime.value(),
                    "forecastHour" => Time.Gregorian.info(hf[i].forecastTime, Time.FORMAT_SHORT).hour,
                    "condition" => hf[i].condition,
                    "temperature" => hf[i].temperature,
                    "windBearing" => hf[i].windBearing,
                    "windSpeed" => hf[i].windSpeed
                };
                if(hf[i].precipitationChance != null) { tmp["precipitationChance"] = hf[i].precipitationChance; }
                if(hf[i] has :highTemperature && hf[i].highTemperature != null) { tmp["highTemperature"] = hf[i].highTemperature; }
                if(hf[i] has :lowTemperature && hf[i].lowTemperature != null) { tmp["lowTemperature"] = hf[i].lowTemperature; }
                if(hf[i] has :feelsLikeTemperature && hf[i].feelsLikeTemperature != null) { tmp["feelsLikeTemperature"] = hf[i].feelsLikeTemperature; }
                if(hf[i] has :relativeHumidity && hf[i].relativeHumidity != null) { tmp["relativeHumidity"] = hf[i].relativeHumidity; }
                if(hf[i] has :uvIndex && hf[i].uvIndex != null) { 
                    tmp["uvIndex"] = hf[i].uvIndex; 
                } else {
                    tmp["uvIndex"] = -1;
                }
                
                hf_data.add(tmp);
            }

            Application.Storage.setValue("hourly_forecast", hf_data);
            lastHfTime = firstForecastTime;
        }
    }

    (:WeatherCache)
    hidden function readWeatherData() as StoredWeather {
        var ret = new StoredWeather();
        var now = Time.now().value();
        var cc_data = Application.Storage.getValue("current_conditions") as Dictionary<String, Application.PropertyValueType>?;
        if(cc_data == null) { return ret; }
        
        var data_age_s = now - (cc_data.get("timestamp") as Number);
        var pos = cc_data.get("observationLocationPosition") as Array?;
        if (pos != null) {
            ret.observationLocationPosition = new Position.Location({:latitude => pos[0], :longitude => pos[1], :format => :degrees});
        }
        if(data_age_s > 0 and data_age_s < 3600) {
            ret.condition = cc_data.get("condition") as Number;
            ret.highTemperature = cc_data.get("highTemperature") as Number;
            ret.lowTemperature = cc_data.get("lowTemperature") as Number;
            ret.precipitationChance = cc_data.get("precipitationChance") as Number;
            ret.relativeHumidity = cc_data.get("relativeHumidity") as Number;
            ret.temperature = cc_data.get("temperature") as Number;
            ret.feelsLikeTemperature = cc_data.get("feelsLikeTemperature") as Float;
            ret.windBearing = cc_data.get("windBearing") as Number;
            ret.windSpeed = cc_data.get("windSpeed") as Float;
            var currentUv = cc_data.get("uvIndex") as Float;
            if (currentUv != null && currentUv >= 0.0f) {
                ret.uvIndex = currentUv;
            }
        } else {
            var hf_data = Application.Storage.getValue("hourly_forecast") as Array?;
            if(hf_data == null) { return ret; }
            for(var i=0; i<hf_data.size(); i++) {
                var forecast_age = now - (hf_data[i].get("forecastTime") as Number);
                if(forecast_age > 0 and forecast_age < 3600) {
                    ret.condition = hf_data[i].get("condition") as Number;
                    ret.temperature = hf_data[i].get("temperature") as Number;
                    ret.highTemperature = hf_data[i].get("highTemperature") as Number;
                    ret.lowTemperature = hf_data[i].get("lowTemperature") as Number;
                    ret.precipitationChance = hf_data[i].get("precipitationChance") as Number;
                    ret.relativeHumidity = hf_data[i].get("relativeHumidity") as Number;
                    ret.feelsLikeTemperature = hf_data[i].get("feelsLikeTemperature") as Float;
                    ret.windBearing = hf_data[i].get("windBearing") as Number;
                    ret.windSpeed = hf_data[i].get("windSpeed") as Float;
                    var forecastUv = hf_data[i].get("uvIndex") as Float;
                    if (forecastUv != null && forecastUv >= 0.0f) {
                        ret.uvIndex = forecastUv;
                    }
                }
            }
        }
        
        return ret;
    }

    hidden function getValueByTypeWithUnit(complicationType as Number, width as Number, now as Gregorian.Info, activityInfo, sysStats as System.Stats) as String {
        var unit = getUnitByType(complicationType);
        if (unit.length() > 0) {
            unit = " " + unit;
        }
        return getDisplayValueByType(complicationType, width, now, activityInfo, sysStats) + unit;
    }

    hidden function shouldRefreshWeatherLine(complicationType as Number) as Boolean {
        if (complicationType == 79) { return hasWeatherCycleForecastChanges(); }
        return false;
    }

    hidden function getWeatherLineDisplayState(complicationType as Number, width as Number, now as Gregorian.Info, activityInfo, sysStats as System.Stats) as Array {
        if (!isWeatherSource(complicationType)) {
            return [getValueByTypeWithUnit(complicationType, width, now, activityInfo, sysStats), themeColors[dataVal]];
        }

        if (complicationType == 79) {
            var cycleState = getWeatherCycleState(
                getActiveWeatherCondition(),
                getActiveForecastChange(),
                getActiveForecastSecondChange(),
                getActiveForecastThirdChange(),
                getActiveForecastFourthChange()
            );
            return [cycleState[0], getWeatherPhaseColor(cycleState[1] as Number)];
        }

        return [getValueByTypeWithUnit(complicationType, width, now, activityInfo, sysStats), themeColors[dataVal]];
    }

    hidden function getUnitByType(complicationType) as String {
        if(complicationType == 11 or complicationType == 29 or complicationType == 58) { // Calories
            return cachedTextResources[0];
        } else if(complicationType == 12) { // Altitude (m)
            return cachedTextResources[1];
        } else if(complicationType == 15) { // Altitude (ft)
            return cachedTextResources[2];
        } else if(complicationType == 17) { // Steps / day
            return cachedTextResources[3];
        } else if(complicationType == 19) { // Wheelchair pushes
            return cachedTextResources[4];
        }
        return "";
    }

    hidden function getValueByType(complicationType as Number, width as Number, now as Gregorian.Info, activityInfo, sysStats as System.Stats) as String {
        var val = "";
        var numberFormat = "%d";
        var hasComplications = ((runtimeBitmap >> 8) & 0x1) == 1;

        if(complicationType == -2) { // Hidden
            return "";
        } else if(complicationType == -1) { // Date
            val = formatDate(now);
        } else if(complicationType == 0) { // Active min / week
            if(activityInfo != null && activityInfo has :activeMinutesWeek) {
                var activeMinutesWeek = activityInfo.activeMinutesWeek;
                if(activeMinutesWeek != null && activeMinutesWeek has :total && activeMinutesWeek.total != null) {
                    val = activeMinutesWeek.total.format(numberFormat);
                }
            }
        } else if(complicationType == 1) { // Active min / day
            if(activityInfo != null && activityInfo has :activeMinutesDay) {
                var activeMinutesDay = activityInfo.activeMinutesDay;
                if(activeMinutesDay != null && activeMinutesDay has :total && activeMinutesDay.total != null) {
                    val = activeMinutesDay.total.format(numberFormat);
                }
            }
        } else if(complicationType == 2) { // distance (km) / day
            if(activityInfo != null && activityInfo has :distance) {
                if(activityInfo.distance != null) {
                    var distance_km = activityInfo.distance / 100000.0;
                    val = formatDistanceByWidth(distance_km, width);
                }
            }
        } else if(complicationType == 3) { // distance (miles) / day
            if(activityInfo != null && activityInfo has :distance) {
                if(activityInfo.distance != null) {
                    var distance_miles = activityInfo.distance / 160900.0;
                    val = formatDistanceByWidth(distance_miles, width);
                }
            }
        } else if(complicationType == 4) { // floors climbed / day
            if(activityInfo != null && activityInfo has :floorsClimbed) {
                if(activityInfo.floorsClimbed != null) {
                    val = activityInfo.floorsClimbed.format(numberFormat);
                }
            }
        } else if(complicationType == 5) { // meters climbed / day
            if(activityInfo != null && activityInfo has :metersClimbed) {
                if(activityInfo.metersClimbed != null) {
                    val = activityInfo.metersClimbed.format(numberFormat);
                }
            }
        } else if(complicationType == 6) { // Time to Recovery (h)
            if (hasComplications) {
                try {
                    var complication = Complications.getComplication(new Id(Complications.COMPLICATION_TYPE_RECOVERY_TIME));
                    if (complication != null && complication.value instanceof Number) {
                        var recovery_h = (complication.value as Number) / 60.0;
                        if(recovery_h > 60) {
                            val = Math.round(recovery_h / 24.0).format(numberFormat) + cachedTextResources[8];
                        } else { val = Math.round(recovery_h).format(numberFormat); }
                    }
                } catch(e) {}
            } else {
                if(activityInfo != null && activityInfo has :timeToRecovery) {
                    if(activityInfo.timeToRecovery != null) {
                        var recovery_h = activityInfo.timeToRecovery;
                        if(recovery_h > 60) {
                            val = Math.round(recovery_h / 24.0).format(numberFormat) + cachedTextResources[8];
                        } else {
                            val = Math.round(recovery_h).format(numberFormat);
                        }
                    }
                }
            }
            
        } else if(complicationType == 7) { // VO2 Max Running
            var profile = getCachedUserProfile();
            if(profile != null && profile has :vo2maxRunning) {
                if(profile.vo2maxRunning != null) {
                    val = profile.vo2maxRunning.format(numberFormat);
                }
            }
        } else if(complicationType == 8) { // VO2 Max Cycling
            var profile = getCachedUserProfile();
            if(profile != null && profile has :vo2maxCycling) {
                if(profile.vo2maxCycling != null) {
                    val = profile.vo2maxCycling.format(numberFormat);
                }
            }
        } else if(complicationType == 9) { // Respiration rate
            if(activityInfo != null && activityInfo has :respirationRate) {
                var resp_rate = activityInfo.respirationRate;
                if(resp_rate != null) {
                    val = resp_rate.format(numberFormat);
                }
            }
        } else if(complicationType == 10) {
            var sample = hrGetCurrentHeartRateSample();
            if(sample != null) {
                val = sample.format("%01d");
            }
        } else if(complicationType == 11) { // Calories
            if (activityInfo != null && activityInfo has :calories) {
                if(activityInfo.calories != null) {
                    val = activityInfo.calories.format(numberFormat);
                }
            }
        } else if(complicationType == 12) { // Altitude (m)
                var alt = getAltitudeValue();
                if (alt != null) {
                    val = alt.format(numberFormat);
            }
        } else if(complicationType == 13) { // Stress
        var st = getStressData();
            if(st != null) {
                val = st.format(numberFormat);
            }
        } else if(complicationType == 14) { // Body battery
            var bb = getBBData();
            if(bb != null) {
                val = bb.format(numberFormat);
            }
        } else if(complicationType == 15) { // Altitude (ft)
            var alt = getAltitudeValue();
            if (alt != null) {
                val = (alt * 3.28084).format(numberFormat);
            }
        } else if(complicationType == 17) { // Steps / day
            if(activityInfo != null && activityInfo has :steps && activityInfo.steps != null) {
                if(width >= 5) {
                    val = activityInfo.steps.format(numberFormat);
                } else {
                    var steps_k = activityInfo.steps / 1000.0;
                    if(steps_k < 10 and width == 4) {
                        val = steps_k.format("%.1f") + "K";
                    } else {
                        val = steps_k.format("%d") + "K";
                    }
                }

            }
        } else if(complicationType == 18) { // Distance (m) / day
            if(activityInfo != null && activityInfo has :distance && activityInfo.distance != null) {
                val = (activityInfo.distance / 100).format(numberFormat);
            }
        } else if(complicationType == 19) { // Wheelchair pushes
            if(activityInfo != null && activityInfo has :pushes) {
                if(activityInfo.pushes != null) {
                    val = activityInfo.pushes.format(numberFormat);
                }
            }
        } else if(complicationType == 20) { // Weather condition
            val = getWeatherCondition(true);
        } else if(complicationType == 21) { // Weekly run distance (km)
            val = getWeeklyDistanceFromComplication(true, 0.001, width);
        } else if(complicationType == 22) { // Weekly run distance (miles)
            val = getWeeklyDistanceFromComplication(true, 0.000621371, width);
        } else if(complicationType == 23) { // Weekly bike distance (km)
            val = getWeeklyDistanceFromComplication(false, 0.001, width);
        } else if(complicationType == 24) { // Weekly bike distance (miles)
            val = getWeeklyDistanceFromComplication(false, 0.000621371, width);
        } else if(complicationType == 25) { // Training status
            if (hasComplications) {
                try {
                    var complication = Complications.getComplication(new Id(Complications.COMPLICATION_TYPE_TRAINING_STATUS));
                    if (complication != null && complication.value instanceof String) {
                        val = (complication.value as String).toUpper();
                    }
                } catch(e) {
                    // Complication not found
                }
            }
        } else if(complicationType == 26) { // Raw Barometric pressure (hPA)
            var info = getCachedActivityDetails();
            if (info != null && info has :rawAmbientPressure && info.rawAmbientPressure != null) {
                val = formatPressure(info.rawAmbientPressure / 100.0, width);
            }
        } else if(complicationType == 27) { // Weight kg
            var profile = getCachedUserProfile();
            if(profile != null && profile has :weight) {
                if(profile.weight != null) {
                    var weight_kg = profile.weight / 1000.0;
                    if (width == 3) {
                        val = weight_kg.format(numberFormat);
                    } else {
                        val = weight_kg.format("%.1f");
                    }
                }
            }
        } else if(complicationType == 28) { // Weight lbs
            var profile = getCachedUserProfile();
            if(profile != null && profile has :weight) {
                if(profile.weight != null) {
                    val = (profile.weight * 0.00220462).format(numberFormat);
                }
            }
        } else if(complicationType == 29) { // Act Calories
            var rest_calories = getRestCalories();
            // Get total calories and subtract rest calories
            if (activityInfo != null && activityInfo has :calories && activityInfo.calories != null && rest_calories > 0) {
                var active_calories = activityInfo.calories - rest_calories;
                if (active_calories > 0) {
                    val = active_calories.format(numberFormat);
                } else { val = "0"; }
            }
        } else if(complicationType == 30) { // Sea level pressure (hPA)
            var info = getCachedActivityDetails();
            if (info != null && info has :meanSeaLevelPressure && info.meanSeaLevelPressure != null) {
                val = formatPressure(info.meanSeaLevelPressure / 100.0, width);
            }
        } else if(complicationType == 31) { // Week number
            var week_number = isoWeekNumber(now.year, now.month, now.day);
            val = week_number.format(numberFormat);
        } else if(complicationType == 32) { // Weekly distance (km)
            var weekly_distance = getWeeklyDistance(activityInfo) / 100000.0;  // Convert to km
            val = formatDistanceByWidth(weekly_distance, width);
        } else if(complicationType == 33) { // Weekly distance (miles)
            var weekly_distance = getWeeklyDistance(activityInfo) * 0.00000621371;  // Convert to miles
            val = formatDistanceByWidth(weekly_distance, width);
        } else if(complicationType == 34) { // Battery percentage
            var battery = sysStats.battery;
            val = battery.format("%d");
        } else if(complicationType == 35) { // Battery days remaining
            if(sysStats has :batteryInDays) {
                if (sysStats.batteryInDays != null){
                    var sample = Math.round(sysStats.batteryInDays);
                    val = sample.format(numberFormat);
                }
            }
        } else if(complicationType == 36) { // Notification count
            var deviceSettings = getCachedDeviceSettings();
            var notif_count = (deviceSettings != null && deviceSettings has :notificationCount) ? deviceSettings.notificationCount : null;
            if(notif_count != null) {
                if(width == 2 and notif_count == 0) {
                    val = ""; // Hide when shown in the notification field and is zero
                } else {
                    val = notif_count.format(numberFormat);
                }
            }
        } else if(complicationType == 37) { // Solar intensity
            if(sysStats has :solarIntensity and sysStats.solarIntensity != null) {
                val = (sysStats.solarIntensity as Number).format(numberFormat);
            }
        } else if(complicationType == 38) { // Sensor temperature
            if ((Toybox has :SensorHistory) and (Toybox.SensorHistory has :getTemperatureHistory)) {
                try {
                    var tempIterator = Toybox.SensorHistory.getTemperatureHistory({:period => 1});
                    if (tempIterator != null) {
                        var temp = tempIterator.next();
                        if(temp != null and temp.data != null) {
                            val = formatTemperature(convertTemperature(temp.data, cachedTempUnit));
                        }
                    }
                } catch(e) {}
            }
        } else if(complicationType == 39) { // Sunrise
            var todaySunEvents = getCachedSunEvents(Time.now(), "today");
            if(todaySunEvents != null && todaySunEvents.size() == 2) {
                var sunrise = Time.Gregorian.info(todaySunEvents[0], Time.FORMAT_SHORT);
                var sunriseHour = formatHour(sunrise.hour);
                if(width < 5) {
                    val = sunriseHour.format("%02d") + sunrise.min.format("%02d");
                } else {
                    val = sunriseHour.format("%02d") + ":" + sunrise.min.format("%02d");
                }
            } else {
                val = cachedTextResources[5];
            }
        } else if(complicationType == 40) { // Sunset
            var todaySunEvents = getCachedSunEvents(Time.now(), "today");
            if(todaySunEvents != null && todaySunEvents.size() == 2) {
                var sunset = Time.Gregorian.info(todaySunEvents[1], Time.FORMAT_SHORT);
                var sunsetHour = formatHour(sunset.hour);
                if(width < 5) {
                    val = sunsetHour.format("%02d") + sunset.min.format("%02d");
                } else {
                    val = sunsetHour.format("%02d") + ":" + sunset.min.format("%02d");
                }
            } else {
                val = cachedTextResources[5];
            }
        } else if(complicationType == 42) { // Alarms
            var deviceSettings = getCachedDeviceSettings();
            if (deviceSettings != null && deviceSettings has :alarmCount && deviceSettings.alarmCount != null) {
                val = deviceSettings.alarmCount.format(numberFormat);
            }
        } else if(complicationType == 43) { // High temp
            var activeWeather = getActiveWeatherCondition();
            if(activeWeather != null and activeWeather.highTemperature != null) {
                var tempVal = activeWeather.highTemperature;
                val = formatTemperature(convertTemperature(tempVal, cachedTempUnit));
            }
        } else if(complicationType == 44) { // Low temp
            var activeWeather = getActiveWeatherCondition();
            if(activeWeather != null and activeWeather.lowTemperature != null) {
                var tempVal = activeWeather.lowTemperature;
                val = formatTemperature(convertTemperature(tempVal, cachedTempUnit));
            }
        } else if(complicationType == 45) { // Temperature, Wind, Feels like
            var temp = getTemperature();
            var wind = getWind();
            var feelsLike = getFeelsLike(true);
            val = join([temp, wind, feelsLike]);
        } else if(complicationType == 46) { // Temperature, Wind
            var temp = getTemperature();
            var wind = getWind();
            val = join([temp, wind]);
        } else if(complicationType == 47) { // Temperature, Wind, Humidity
            var temp = getTemperature();
            var wind = getWind();
            var humidity = getHumidity();
            val = join([temp, wind, humidity]);
        } else if(complicationType == 48) { // Temperature, Wind, High/Low
            var temp = getTemperature();
            var wind = getWind();
            var highlow = getHighLow();
            val = join([temp, wind, highlow]);
        } else if(complicationType == 49) { // Temperature, Wind, Precipitation chance
            var temp = getTemperature();
            var wind = getWind();
            var precip = getPrecip();
            val = join([temp, wind, precip]);
        } else if(complicationType == 50) { // Weather condition without precipitation
            val = getWeatherCondition(false);
        } else if(complicationType == 51) { // Temperature, Humidity, High/Low
            var temp = getTemperature();
            var humidity = getHumidity();
            var highlow = getHighLow();
            val = join([temp, humidity, highlow]);
        } else if(complicationType == 52) { // Temperature, Percipitation chance, High/Low
            var temp = getTemperature();
            var precip = getPrecip();
            var highlow = getHighLow();
            val = join([temp, precip, highlow]);
        } else if(complicationType == 53) { // Temperature
            val = getTemperature();
        } else if(complicationType == 54) { // Precipitation chance
            val = getPrecip();
            if(width == 3 and val.equals("\u26C6100%")) { val = "\u26C6100"; }
        } else if(complicationType == 55) { // Next Sun Event
            var nextSunEventArray = getNextSunEvent();
            if(nextSunEventArray != null && nextSunEventArray.size() == 2) { 
                var nextSunEvent = Time.Gregorian.info(nextSunEventArray[0], Time.FORMAT_SHORT);
                var nextSunEventHour = formatHour(nextSunEvent.hour);
                if(width < 5) {
                    val = nextSunEventHour.format("%02d") + nextSunEvent.min.format("%02d");
                } else {
                    val = nextSunEventHour.format("%02d") + ":" + nextSunEvent.min.format("%02d");
                }
            }
        } else if(complicationType == 56) { // Millitary Date Time Group
            val = getDateTimeGroup();
        } else if(complicationType == 57) { // Time of the next Calendar Event
            if (hasComplications) {
                try {
                    var complication = Complications.getComplication(new Id(Complications.COMPLICATION_TYPE_CALENDAR_EVENTS));
                    var colon_index = null;
                    if (complication != null && complication.value instanceof String) {
                        val = complication.value as String;
                        colon_index = val.find(":");
                        if (colon_index != null && colon_index < 2) {
                            val = "0" + val;
                        }
                    } else {
                        val = "--:--";
                    }
                    if (width < 5 and colon_index != null) {
                        val = val.substring(0, 2) + val.substring(3, 5);
                    }
                } catch(e) {
                    // Complication not found
                }
            }
        } else if(complicationType == 58) { // Active / Total calories
            var rest_calories = getRestCalories();
            var total_calories = 0;
            // Get total calories and subtract rest calories
            if (activityInfo != null && activityInfo has :calories && activityInfo.calories != null) {
                total_calories = activityInfo.calories;
            }
            var active_calories = (rest_calories > 0) ? (total_calories - rest_calories) : 0;
            active_calories = (active_calories > 0) ? active_calories : 0; // Ensure active calories is not negative
            val = active_calories.format(numberFormat) + "/" + total_calories.format(numberFormat);
        } else if(complicationType == 59) { // PulseOx
            if (hasComplications) {
                try {
                    var complication = Complications.getComplication(new Id(Complications.COMPLICATION_TYPE_PULSE_OX));
                    if (complication != null && complication.value instanceof Number) {
                        val = (complication.value as Number).format(numberFormat);
                    }
                } catch(e) {
                    // Complication not found
                }
            } else {
                if ((Toybox has :SensorHistory) and (Toybox.SensorHistory has :getOxygenSaturationHistory)) {
                    try {
                        var it = Toybox.SensorHistory.getOxygenSaturationHistory({:period => 1});
                        if (it != null) {
                            var ox = it.next();
                            var oxygen = (ox == null) ? null : toFloatIfNumeric(ox.data);
                            if(oxygen != null) {
                                val = oxygen.format("%d");
                            }
                        }
                    } catch(e) {}
                }
            }
        } else if(complicationType == 60) { // Location Long Lat dec deg
            var activityDetails = getCachedActivityDetails();
            var pos = (activityDetails != null && activityDetails has :currentLocation) ? activityDetails.currentLocation : null;
            if(pos != null) {
                var degrees = pos.toDegrees() as Array;
                val = degrees[0] + " " + degrees[1];
            } else {
                val = cachedTextResources[6];
            }
            
        } else if(complicationType == 61) { // Location Millitary format
            var activityDetails = getCachedActivityDetails();
            var pos = (activityDetails != null && activityDetails has :currentLocation) ? activityDetails.currentLocation : null;
            if(pos != null) {
                val = pos.toGeoString(Position.GEO_MGRS);
            } else {
                val = cachedTextResources[6];
            }
            
        } else if(complicationType == 62) { // Location Accuracy
            var activityDetails = getCachedActivityDetails();
            var acc = (activityDetails != null && activityDetails has :currentLocationAccuracy) ? activityDetails.currentLocationAccuracy : null;
            if(acc != null) {
                if(width < 4) {
                    val = (acc as Number).format("%d");
                } else {
                    if (acc >= 0 && acc < 5) {
                        val = ["N/A", "LAST", "POOR", "USBL", "GOOD"][acc];
                    } else {
                        val = (acc as Number).format("%d");
                    }
                }
            }
        } else if(complicationType == 63) { // Temperature, Wind, Humidity, Precipitation chance
            var temp = getTemperature();
            var wind = getWind();
            var humidity = getHumidity();
            var precip = getPrecip();
            val = join([temp, wind, humidity, precip]);
        } else if(complicationType == 64) { // UV Index
            val = getUVIndex();
        } else if(complicationType == 65) { // Temperature, UV Index, High/Low
            var temp = getTemperature();
            var uv = getUVIndex();
            var highlow = getHighLow();
            val = join([temp, uv, highlow]);
        } else if(complicationType == 66) { // Humidity
            val = getHumidity();
        } else if(complicationType == 67) { // Temperature, Feels like, High/Low
            var temp = getTemperature();
            var fl = getFeelsLike(true);
            var highlow = getHighLow();
            val = join([temp, fl, highlow]);
        } else if(complicationType == 68) { // Temperature, UV, Precip
            var temp = getTemperature();
            var uv = getUVIndex();
            var precip = getPrecip();
            val = join([temp, uv, precip]);
        } else if(complicationType == 69) { // Temperature, UV, Wind
            var temp = getTemperature();
            var uv = getUVIndex();
            var wind = getWind();
            val = join([temp, uv, wind]);
        } else if(complicationType == 70) { // Weather condition, Temperature
            var condition = getWeatherCondition(false);
            var temp = getTemperature();
            val = join([condition, temp]);
        } else if(complicationType == 71) { // CGM Glucose + Trend
            val = getCgmReading();
        } else if(complicationType == 72) { // CGM Age (minutes)
            val = getCgmAge();
        } else if(complicationType == 73) { // Weather condition, Feels like
            val = formatWeatherConditionFeelsLike(getActiveWeatherCondition());
        } else if(complicationType == 79) { // Weather condition, Feels like, Until when
            val = formatWeatherCycleValue(
                getActiveWeatherCondition(),
                getActiveForecastChange(),
                getActiveForecastSecondChange(),
                getActiveForecastThirdChange(),
                getActiveForecastFourthChange()
            );
        } else if(complicationType == 74) { // Feels like
            val = getFeelsLike(false);
        } else if(complicationType == 75) { // Hours to next sun event
            val = hoursToNextSunEvent();
        } else if(complicationType == 76) { // Resting Heart Rate
            var profile = getCachedUserProfile();
            if(profile != null && profile has :restingHeartRate) {
                if(profile.restingHeartRate != null) {
                    val = profile.restingHeartRate.format(numberFormat);
                }
            }
        } else if(complicationType == 77) { // Wind, Precipitation chance, UV Index
            var wind = getWind();
            var precip = getPrecip();
            var uv = getUVIndex();
            val = join([wind, precip, uv]);
        } else if(complicationType == 78) { // Wind, Precipitation chance, UV Index, Humidity
            var wind = getWind();
            var precip = getPrecip();
            var uv = getUVIndex();
            var humidity = getHumidity();
            val = join([wind, precip, uv, humidity]);
        }

        return val;
    }

    hidden function getLabelByType(complicationType as Number, labelSize as Number) as String {
        // labelSize 1 = short, 2 = mid, 3 = long

        switch(complicationType) {
            case 0: return formatLabel(Rez.Strings.LABEL_WMIN_1, Rez.Strings.LABEL_WMIN_2, Rez.Strings.LABEL_WMIN_3, labelSize);
            case 1: return formatLabel(Rez.Strings.LABEL_DMIN_1, Rez.Strings.LABEL_DMIN_2, Rez.Strings.LABEL_DMIN_3, labelSize);
            case 2: return formatLabel(Rez.Strings.LABEL_DKM_1, Rez.Strings.LABEL_DKM_2, Rez.Strings.LABEL_DKM_2, labelSize);
            case 3: return formatLabel(Rez.Strings.LABEL_DMI_1, Rez.Strings.LABEL_DMI_2, Rez.Strings.LABEL_DMI_3, labelSize);
            case 4: return Application.loadResource(Rez.Strings.LABEL_FLOORS);
            case 5: return formatLabel(Rez.Strings.LABEL_CLIMB_1, Rez.Strings.LABEL_CLIMB_2, Rez.Strings.LABEL_CLIMB_2, labelSize);
            case 6: return formatLabel(Rez.Strings.LABEL_RECOV_1, Rez.Strings.LABEL_RECOV_2, Rez.Strings.LABEL_RECOV_3, labelSize);
            case 7: return formatLabel(Rez.Strings.LABEL_VO2_1, Rez.Strings.LABEL_VO2_2, Rez.Strings.LABEL_VO2RUN_3, labelSize);
            case 8: return formatLabel(Rez.Strings.LABEL_VO2_1, Rez.Strings.LABEL_VO2_2, Rez.Strings.LABEL_VO2BIKE_3, labelSize);
            case 9: return formatLabel(Rez.Strings.LABEL_RESP_1, Rez.Strings.LABEL_RESP_2, Rez.Strings.LABEL_RESP_3, labelSize);
            case 10: return Application.loadResource(Rez.Strings.LABEL_HR);
            case 11: return formatLabel(Rez.Strings.LABEL_CAL_1, Rez.Strings.LABEL_CAL_2, Rez.Strings.LABEL_CAL_3, labelSize);
            case 12: return formatLabel(Rez.Strings.LABEL_ALT_1, Rez.Strings.LABEL_ALT_2, Rez.Strings.LABEL_ALTM_3, labelSize);
            case 13: return Application.loadResource(Rez.Strings.LABEL_STRESS);
            case 14: return formatLabel(Rez.Strings.LABEL_BBAT_1, Rez.Strings.LABEL_BBAT_2, Rez.Strings.LABEL_BBAT_3, labelSize);
            case 15: return formatLabel(Rez.Strings.LABEL_ALT_1, Rez.Strings.LABEL_ALT_2, Rez.Strings.LABEL_ALTFT_3, labelSize);
            case 17: return Application.loadResource(Rez.Strings.LABEL_STEPS);
            case 18: return formatLabel(Rez.Strings.LABEL_DIST_1, Rez.Strings.LABEL_DIST_2, Rez.Strings.LABEL_DIST_3, labelSize);
            case 19: return Application.loadResource(Rez.Strings.LABEL_PUSHES);
            case 20: return "";
            case 21: return formatLabel(Rez.Strings.LABEL_WKM_1, Rez.Strings.LABEL_WRUNM_2, Rez.Strings.LABEL_WRUNM_3, labelSize);
            case 22: return formatLabel(Rez.Strings.LABEL_WMI_1, Rez.Strings.LABEL_WRUNMI_2, Rez.Strings.LABEL_WRUNMI_3, labelSize);
            case 23: return formatLabel(Rez.Strings.LABEL_WKM_1, Rez.Strings.LABEL_WBIKEKM_2, Rez.Strings.LABEL_WBIKEKM_3, labelSize);
            case 24: return formatLabel(Rez.Strings.LABEL_WMI_1, Rez.Strings.LABEL_WBIKEMI_2, Rez.Strings.LABEL_WBIKEMI_3, labelSize);
            case 25: return Application.loadResource(Rez.Strings.LABEL_TRAINING);
            case 26: return Application.loadResource(Rez.Strings.LABEL_PRESSURE);
            case 27: return formatLabel(Rez.Strings.LABEL_KG_1, Rez.Strings.LABEL_WEIGHT_2, Rez.Strings.LABEL_KG_3, labelSize);
            case 28: return formatLabel(Rez.Strings.LABEL_LBS_1, Rez.Strings.LABEL_WEIGHT_2, Rez.Strings.LABEL_LBS_3, labelSize);
            case 29: return formatLabel(Rez.Strings.LABEL_ACAL_1, Rez.Strings.LABEL_ACAL_2, Rez.Strings.LABEL_ACAL_3, labelSize);
            case 30: return Application.loadResource(Rez.Strings.LABEL_PRESSURE);
            case 31: return Application.loadResource(Rez.Strings.LABEL_WEEK);
            case 32: return formatLabel(Rez.Strings.LABEL_WKM_1, Rez.Strings.LABEL_WDISTKM_2, Rez.Strings.LABEL_WDISTKM_3, labelSize);
            case 33: return formatLabel(Rez.Strings.LABEL_WMI_1, Rez.Strings.LABEL_WDISTMI_2, Rez.Strings.LABEL_WDISTMI_3, labelSize);
            case 34: return formatLabel(Rez.Strings.LABEL_BATT_1, Rez.Strings.LABEL_BATT_2, Rez.Strings.LABEL_BATT_3, labelSize);
            case 35: return formatLabel(Rez.Strings.LABEL_BATTD_1, Rez.Strings.LABEL_BATTD_2, Rez.Strings.LABEL_BATTD_3, labelSize);
            case 36: return formatLabel(Rez.Strings.LABEL_NOTIFS_1, Rez.Strings.LABEL_NOTIFS_1, Rez.Strings.LABEL_NOTIFS_3, labelSize);
            case 37: return formatLabel(Rez.Strings.LABEL_SUN_1, Rez.Strings.LABEL_SUNINT_2, Rez.Strings.LABEL_SUNINT_3, labelSize);
            case 38: return formatLabel(Rez.Strings.LABEL_TEMP_1, Rez.Strings.LABEL_TEMP_1, Rez.Strings.LABEL_STEMP_3, labelSize);
            case 39: return formatLabel(Rez.Strings.LABEL_DAWN_1, Rez.Strings.LABEL_DAWN_2, Rez.Strings.LABEL_DAWN_2, labelSize);
            case 40: return formatLabel(Rez.Strings.LABEL_DUSK_1, Rez.Strings.LABEL_DUSK_2, Rez.Strings.LABEL_DUSK_2, labelSize);
            case 42: return formatLabel(Rez.Strings.LABEL_ALARM_1, Rez.Strings.LABEL_ALARM_2, Rez.Strings.LABEL_ALARM_2, labelSize);
            case 43: return formatLabel(Rez.Strings.LABEL_HIGH_1, Rez.Strings.LABEL_HIGH_2, Rez.Strings.LABEL_HIGH_2, labelSize);
            case 44: return formatLabel(Rez.Strings.LABEL_LOW_1, Rez.Strings.LABEL_LOW_2, Rez.Strings.LABEL_LOW_2, labelSize);
            case 53: return formatLabel(Rez.Strings.LABEL_TEMP_1, Rez.Strings.LABEL_TEMP_1, Rez.Strings.LABEL_TEMP_3, labelSize);
            case 54: return formatLabel(Rez.Strings.LABEL_PRECIP_1, Rez.Strings.LABEL_PRECIP_1, Rez.Strings.LABEL_PRECIP_3, labelSize);
            case 55: return formatLabel(Rez.Strings.LABEL_NEXTSUN_1, Rez.Strings.LABEL_NEXTSUN_2, Rez.Strings.LABEL_NEXTSUN_3, labelSize);
            case 57: return formatLabel(Rez.Strings.LABEL_NEXTCAL_1, Rez.Strings.LABEL_NEXTCAL_2, Rez.Strings.LABEL_NEXTCAL_3, labelSize);
            case 59: return formatLabel(Rez.Strings.LABEL_OX_1, Rez.Strings.LABEL_OX_2, Rez.Strings.LABEL_OX_2, labelSize);
            case 62: return formatLabel(Rez.Strings.LABEL_ACC_1, Rez.Strings.LABEL_ACC_2, Rez.Strings.LABEL_ACC_3, labelSize);
            case 64: return formatLabel(Rez.Strings.LABEL_UV_1, Rez.Strings.LABEL_UV_2, Rez.Strings.LABEL_UV_2, labelSize);
            case 66: return formatLabel(Rez.Strings.LABEL_HUM_1, Rez.Strings.LABEL_HUM_2, Rez.Strings.LABEL_HUM_2, labelSize);
            case 71: return WatchUi.loadResource(Rez.Strings.LABEL_CGM) as String;
            case 72: return WatchUi.loadResource(Rez.Strings.LABEL_CGMAGE) as String;
            case 74: return formatLabel(Rez.Strings.LABEL_FL, Rez.Strings.LABEL_FL, Rez.Strings.LABEL_FL_3, labelSize);
            case 75: return formatLabel(Rez.Strings.LABEL_HRS_NEXT_SUN_EVENT_1, Rez.Strings.LABEL_HRS_NEXT_SUN_EVENT_1, Rez.Strings.LABEL_HRS_NEXT_SUN_EVENT_3, labelSize);
            case 76: return formatLabel(Rez.Strings.LABEL_RHR_1, Rez.Strings.LABEL_RHR_2, Rez.Strings.LABEL_RHR_3, labelSize);
        }

        return "";
    }

    hidden function formatLabel(short as ResourceId, mid as ResourceId, long as ResourceId, size as Number) as String {
        if(size == 1) { return Application.loadResource(short) + ":"; }
        if(size == 2) { return Application.loadResource(mid) + ":"; }
        return Application.loadResource(long) + ":";
    }

    hidden function formatDate(today as Gregorian.Info) as String {
        var propDateFormat = (propBitmapB >> 7) & 0xF;
        var value = "";

        switch(propDateFormat) {
            case 0: // Default: THU, 14 MAR 2024
                value = dayName(today.day_of_week) + ", " + today.day + " " + monthName(today.month) + " " + today.year;
                break;
            case 1: // ISO: 2024-03-14
                value = today.year + "-" + formatNumberOrEmpty(today.month, "%02d") + "-" + formatNumberOrEmpty(today.day, "%02d");
                break;
            case 2: // US: 03/14/2024
                value = formatNumberOrEmpty(today.month, "%02d") + "/" + formatNumberOrEmpty(today.day, "%02d") + "/" + today.year;
                break;
            case 3: // EU: 14.03.2024
                value = formatNumberOrEmpty(today.day, "%02d") + "." + formatNumberOrEmpty(today.month, "%02d") + "." + today.year;
                break;
            case 4: // THU, 14 MAR (Week number)
                value = dayName(today.day_of_week) + ", " + today.day + " " + monthName(today.month) + " (W" + isoWeekNumber(today.year, today.month, today.day) + ")";
                break;
            case 5: // THU, 14 MAR 2024 (Week number)
                value = dayName(today.day_of_week) + ", " + today.day + " " + monthName(today.month) + " " + today.year + " (W" + isoWeekNumber(today.year, today.month, today.day) + ")";
                break;
            case 6: // WEEKDAY, DD MONTH
                value = dayName(today.day_of_week) + ", " + today.day + " " + monthName(today.month);
                break;
            case 7: // WEEKDAY, YYYY-MM-DD
                value = dayName(today.day_of_week) + ", " + today.year + "-" + formatNumberOrEmpty(today.month, "%02d") + "-" + formatNumberOrEmpty(today.day, "%02d");
                break;
            case 8: // WEEKDAY, MM/DD/YYYY
                value = dayName(today.day_of_week) + ", " + formatNumberOrEmpty(today.month, "%02d") + "/" + formatNumberOrEmpty(today.day, "%02d") + "/" + today.year;
                break;
            case 9: // WEEKDAY, DD.MM.YYYY
                value = dayName(today.day_of_week) + ", " + formatNumberOrEmpty(today.day, "%02d") + "." + formatNumberOrEmpty(today.month, "%02d") + "." + today.year;
                break;
        }

        return value;
    }

    hidden function join(array as Array<String>) as String {
        var ret = "";
        for(var i=0; i<array.size(); i++) {
            if(array[i].length() == 0) {
                continue;
            }
            if(ret.length() == 0) {
                ret = array[i];
            } else {
                ret = ret + "  " + array[i];
            }
        }
        return ret;
    }

    hidden function getDateTimeGroup() as String {
        // 052125ZMAR25
        // DDHHMMZmmmYY
        var now = Time.now();
        var utc = Time.Gregorian.utcInfo(now, Time.FORMAT_SHORT);
        var value = utc.day.format("%02d") + utc.hour.format("%02d") + utc.min.format("%02d") + "Z" + monthName(utc.month) + utc.year.toString().substring(2,4);

        return value;
    }

    hidden function formatPressure(pressureHpa as Float, width as Number) as String {
        var propPressureUnit = (propBitmapB >> 4) & 0x3;
        var val = "";
        var nf = "%d";

        if (propPressureUnit == 0) { // hPA
            val = pressureHpa.format(nf);
        } else if (propPressureUnit == 1) { // mmHG
            val = (pressureHpa * 0.750062).format(nf);
        } else if (propPressureUnit == 2) { // inHG
            if(width == 5) {
                val = (pressureHpa * 0.02953).format("%.2f");
            } else {
                val = (pressureHpa * 0.02953).format("%.1f");
            }
        }

        return val;
    }

    hidden function moonPhase(time) as String {
        var jd = julianDay(time.year, time.month, time.day);

        var days_since_new_moon = jd - 2459966;
        var lunar_cycle = 29.53;
        var phase = ((days_since_new_moon / lunar_cycle) * 100).toNumber() % 100;
        var into_cycle = (phase / 100.0) * lunar_cycle;

        if(time.month == 5 and time.day == 4) {
            return "8"; // That's no moon!
        }

        var moonPhase;
        if (into_cycle < 3) { // 2+1
            moonPhase = 0;
        } else if (into_cycle < 6) { // 4
            moonPhase = 1;
        } else if (into_cycle < 10) { // 4
            moonPhase = 2;
        } else if (into_cycle < 14) { // 4
            moonPhase = 3;
        } else if (into_cycle < 18) { // 4
            moonPhase = 4;
        } else if (into_cycle < 22) { // 4
            moonPhase = 5;
        } else if (into_cycle < 26) { // 4
            moonPhase = 6;
        } else if (into_cycle < 29) { // 3
            moonPhase = 7;
        } else {
            moonPhase = 0;
        }

        var propHemisphere = (propBitmapA >> 23) & 0x1;

        // If hemisphere is 1 (southern), invert the phase index
        if (propHemisphere == 1) {
            moonPhase = (8 - moonPhase) % 8;
        }

        return moonPhase.toString();

    }

    hidden function formatDistanceByWidth(distance as Float, width as Number) as String {
        if (width == 3) {
            return distance < 9.9 ? distance.format("%.1f") : Math.round(distance).format("%d");
        } else if (width == 4) {
            return distance < 100 ? distance.format("%.1f") : distance.format("%d");
        } else {  // width == 5
            return distance < 1000 ? distance.format("%05.1f") : distance.format("%05d");
        }
    }

    hidden function getWeatherPhase(phaseCount as Number) as Number {
        if (phaseCount <= 1) { return 0; }
        var elapsed = Time.now().value() - wakeTimestamp;
        return ((elapsed / weatherCycleIntervalS).toNumber() % phaseCount);
    }

    hidden function blendWeatherColorChannel(baseChannel as Number, accentChannel as Number, accentPercent as Number) as Number {
        return Math.round(((baseChannel * (100 - accentPercent)) + (accentChannel * accentPercent)) / 100.0).toNumber();
    }

    hidden function getWeatherPhaseColor(accentPercent as Number) as Graphics.ColorType {
        var baseColor = themeColors[dataVal];
        if (accentPercent <= 0) { return baseColor; }

        var accentColor = themeColors[clock];
        var red = blendWeatherColorChannel((baseColor >> 16) & 0xFF, (accentColor >> 16) & 0xFF, accentPercent);
        var green = blendWeatherColorChannel((baseColor >> 8) & 0xFF, (accentColor >> 8) & 0xFF, accentPercent);
        var blue = blendWeatherColorChannel(baseColor & 0xFF, accentColor & 0xFF, accentPercent);

        return (red << 16) | (green << 8) | blue;
    }

    hidden function getWeatherCycleAccentPercent(phase as Number) as Number {
        if (phase <= 0) { return 0; }
        if (phase == 1) { return 40; }
        if (phase == 2) { return 70; }
        if (phase == 3) { return 80; }
        return 90;
    }

    hidden function getWeatherCycleChangeCount(activeChange as Array?, activeSecondChange as Array?, activeThirdChange as Array?, activeFourthChange as Array?) as Number {
        if (getForecastEventWeather(activeChange) == null) { return 0; }
        if (getForecastEventWeather(activeSecondChange) == null) { return 1; }
        if (getForecastEventWeather(activeThirdChange) == null) { return 2; }
        if (getForecastEventWeather(activeFourthChange) == null) { return 3; }
        return 4;
    }

    hidden function getWeatherCycleEventForPhase(phase as Number, activeChange as Array?, activeSecondChange as Array?, activeThirdChange as Array?, activeFourthChange as Array?) as Array? {
        if (phase == 1) { return activeChange; }
        if (phase == 2) { return activeSecondChange; }
        if (phase == 3) { return activeThirdChange; }
        if (phase == 4) { return activeFourthChange; }
        return null;
    }

    hidden function getWeatherCycleState(activeWeather as ForecastWeather or Null, activeChange as Array?, activeSecondChange as Array?, activeThirdChange as Array?, activeFourthChange as Array?) as Array {
        var changeCount = getWeatherCycleChangeCount(activeChange, activeSecondChange, activeThirdChange, activeFourthChange);
        if (changeCount == 0) {
            return [formatWeatherConditionFeelsLike(activeWeather), 0];
        }

        // Current conditions are the first phase when available, followed by
        // every retained forecast event. The current phase points to the first
        // event's start. Forecast-only fallback data still starts at event one.
        var hasCurrentWeather = activeWeather != null && activeWeather.condition != null;
        var phase = getWeatherPhase(hasCurrentWeather ? changeCount + 1 : changeCount);
        if (hasCurrentWeather && phase == 0) {
            return [
                formatWeatherConditionFeelsLike(activeWeather) + formatForecastPointer(getForecastEventPointer(activeChange, 1)),
                getWeatherCycleAccentPercent(phase)
            ];
        }

        var forecastPhase = hasCurrentWeather ? phase : phase + 1;
        var event = getWeatherCycleEventForPhase(forecastPhase, activeChange, activeSecondChange, activeThirdChange, activeFourthChange);
        var displayWeather = getForecastEventWeather(event);
        if (displayWeather == null) {
            return [formatWeatherConditionFeelsLike(activeWeather), 0];
        }

        return [formatWeatherConditionFeelsLike(displayWeather) + formatForecastPointer(getForecastEventPointer(event, 2)), getWeatherCycleAccentPercent(forecastPhase)];
    }

    hidden function getWeatherCycleValue(activeWeather as ForecastWeather or Null, activeChange as Array?, activeSecondChange as Array?, activeThirdChange as Array?, activeFourthChange as Array?) as String {
        return getWeatherCycleState(activeWeather, activeChange, activeSecondChange, activeThirdChange, activeFourthChange)[0] as String;
    }

    hidden function getWeatherGroup(condition as Number) as Number {
        condition = normalizeWeatherCondition(condition, cachedWeatherResIds.size());
        if (condition == 53) { return WEATHER_GROUP_UNKNOWN; }
        if (condition == 0 || condition == 1 || condition == 2 || condition == 5 || condition == 20 || condition == 22 || condition == 23 || condition == 40 || condition == 52) { return 0; }
        if (condition == 3 || condition == 11 || condition == 14 || condition == 15 || condition == 24 || condition == 25 || condition == 26 || condition == 27 || condition == 31 || condition == 45) { return 2; }
        if (condition == 4 || condition == 7 || condition == 16 || condition == 17 || condition == 18 || condition == 19 || condition == 21 || condition == 34 || condition == 43 || condition == 44 || condition == 46 || condition == 47 || condition == 48 || condition == 49 || condition == 50 || condition == 51) { return 3; }
        return 1;
    }

    hidden function getForecastEventHour(forecast as ForecastWeather or Null) as Number {
        if (forecast == null) { return -1; }
        var forecastHour = forecast.forecastHour;
        if (forecastHour == null) { return -1; }
        return forecastHour as Number;
    }

    hidden function buildForecastEvent(forecast as ForecastWeather or Null) as Array? {
        if (forecast == null) { return null; }
        return [buildMergedForecastWeather(forecast), getForecastEventHour(forecast), -1];
    }

    hidden function collectFeelsLikeExcursions(candidates as Array, startIdx as Number, endIdx as Number, group as Number, baseline as Float?, now as Number) as Void {
        if (startIdx > endIdx) { return; }

        var searchStart = startIdx;
        var activeBaseline = baseline;
        var prerequisiteCandidateIdx = -1;

        if (activeBaseline == null) {
            for (var baselineIdx = searchStart; baselineIdx <= endIdx; baselineIdx++) {
                var baselineForecast = cachedHourlyForecast[baselineIdx];
                var baselineTime = baselineForecast.forecastTime;
                if (baselineTime != null && (baselineTime as Number) <= now) { continue; }
                if (baselineForecast.condition == null) { return; }
                if (getWeatherGroup(baselineForecast.condition as Number) != group) { return; }
                if (baselineForecast.feelsLikeTemperature == null) { continue; }

                activeBaseline = baselineForecast.feelsLikeTemperature as Float;
                searchStart = baselineIdx + 1;
                break;
            }
        }

        while (activeBaseline != null && searchStart <= endIdx) {
            var excursionForecast = null;
            var excursionValue = null;
            var excursionDelta = -1.0f;
            var excursionIdx = -1;

            for (var i = searchStart; i <= endIdx; i++) {
                var forecast = cachedHourlyForecast[i];
                var forecastTime = forecast.forecastTime;
                if (forecastTime != null && (forecastTime as Number) <= now) { continue; }
                if (forecast.condition == null) { break; }
                if (getWeatherGroup(forecast.condition as Number) != group) { break; }
                if (forecast.feelsLikeTemperature == null) { continue; }

                var forecastFeelsLike = forecast.feelsLikeTemperature as Float;
                var delta = forecastFeelsLike - (activeBaseline as Float);
                if (delta < 0.0f) { delta = -delta; }
                if (delta > excursionDelta) {
                    excursionForecast = forecast;
                    excursionValue = forecastFeelsLike;
                    excursionDelta = delta;
                    excursionIdx = i;
                }
            }

            if (excursionForecast == null || excursionValue == null || excursionDelta < WEATHER_CYCLE_FEELS_LIKE_THRESHOLD_C) {
                break;
            }

            var candidateIdx = candidates.size();
            candidates.add([excursionForecast, excursionIdx, excursionDelta, false, prerequisiteCandidateIdx]);
            prerequisiteCandidateIdx = candidateIdx;
            activeBaseline = excursionValue as Float;
            searchStart = excursionIdx + 1;
        }
    }

    hidden function buildForecastTimeline(baseCondition as Number, baseFeelsLike as Float?, startIdx as Number, includeBaseEvent as Boolean) as Array {
        var timeline = [null, null, null, null];
        var conditionCandidates = [];
        var feelsLikeCandidates = [];
        var previousGroup = getWeatherGroup(baseCondition);
        var segmentStartIdx = startIdx + 1;
        var segmentBaseline = baseFeelsLike;
        var finalForecastHour = -1;
        var firstOmittedConditionHour = -1;
        var now = Time.now().value();

        if (includeBaseEvent && startIdx >= 0 && startIdx < cachedHourlyForecast.size()) {
            conditionCandidates.add([cachedHourlyForecast[startIdx], startIdx]);
        }

        for (var i = startIdx + 1; i < cachedHourlyForecast.size(); i++) {
            var forecast = cachedHourlyForecast[i];
            var forecastTime = forecast.forecastTime;
            if (forecastTime != null && (forecastTime as Number) <= now) { continue; }
            var forecastHour = getForecastEventHour(forecast);
            if (forecastHour >= 0) { finalForecastHour = forecastHour; }
            var condition = forecast.condition;
            if (condition == null) {
                if (previousGroup >= 0 && previousGroup != WEATHER_GROUP_UNKNOWN) {
                    collectFeelsLikeExcursions(feelsLikeCandidates, segmentStartIdx, i - 1, previousGroup, segmentBaseline, now);
                }
                // A missing condition is a hard boundary. The next known row
                // establishes a new baseline rather than implying a transition.
                previousGroup = -1;
                segmentStartIdx = i + 1;
                segmentBaseline = null;
                continue;
            }

            var group = getWeatherGroup(condition as Number);
            if (previousGroup < 0) {
                // Do not promote an unknown row encountered inside a missing-data
                // gap into a displayed state.
                if (group != WEATHER_GROUP_UNKNOWN) {
                    previousGroup = group;
                    segmentStartIdx = i + 1;
                    segmentBaseline = (forecast.feelsLikeTemperature == null) ? null : forecast.feelsLikeTemperature as Float;
                } else {
                    segmentStartIdx = i + 1;
                    segmentBaseline = null;
                }
                continue;
            }
            if (group == previousGroup) { continue; }

            if (previousGroup != WEATHER_GROUP_UNKNOWN) {
                collectFeelsLikeExcursions(feelsLikeCandidates, segmentStartIdx, i - 1, previousGroup, segmentBaseline, now);
            }
            if (conditionCandidates.size() == weatherCycleMaxChanges) {
                firstOmittedConditionHour = forecastHour;
            }
            conditionCandidates.add([forecast, i]);
            previousGroup = group;
            segmentStartIdx = i + 1;
            segmentBaseline = (group == WEATHER_GROUP_UNKNOWN || forecast.feelsLikeTemperature == null)
                ? null
                : forecast.feelsLikeTemperature as Float;
        }

        if (previousGroup >= 0 && previousGroup != WEATHER_GROUP_UNKNOWN) {
            collectFeelsLikeExcursions(
                feelsLikeCandidates,
                segmentStartIdx,
                cachedHourlyForecast.size() - 1,
                previousGroup,
                segmentBaseline,
                now
            );
        }

        // Condition changes always take precedence over temperature-only
        // excursions when the four display slots are contested.
        var selectedCandidates = [];
        var conditionLimit = conditionCandidates.size();
        if (conditionLimit > weatherCycleMaxChanges) { conditionLimit = weatherCycleMaxChanges; }
        for (var conditionIdx = 0; conditionIdx < conditionLimit; conditionIdx++) {
            selectedCandidates.add(conditionCandidates[conditionIdx]);
        }

        while (selectedCandidates.size() < weatherCycleMaxChanges) {
            var strongestIdx = -1;
            var strongestDelta = -1.0f;
            var availableSlots = weatherCycleMaxChanges - selectedCandidates.size();
            for (var feelsLikeIdx = 0; feelsLikeIdx < feelsLikeCandidates.size(); feelsLikeIdx++) {
                var feelsLikeCandidate = feelsLikeCandidates[feelsLikeIdx] as Array;
                if (feelsLikeCandidate[3] as Boolean) { continue; }

                var requiredSlots = 0;
                var requiredIdx = feelsLikeIdx;
                while (requiredIdx >= 0) {
                    var requiredCandidate = feelsLikeCandidates[requiredIdx] as Array;
                    if (!(requiredCandidate[3] as Boolean)) { requiredSlots = requiredSlots + 1; }
                    requiredIdx = requiredCandidate[4] as Number;
                }
                if (requiredSlots > availableSlots) { continue; }

                var candidateDelta = feelsLikeCandidate[2] as Float;
                if (candidateDelta > strongestDelta) {
                    strongestIdx = feelsLikeIdx;
                    strongestDelta = candidateDelta;
                }
            }

            if (strongestIdx < 0) { break; }

            // Add the winning candidate's unselected prerequisites first so
            // every retained delta is measured from a state that is displayed.
            var requiredChain = [];
            var selectedFeelsLikeIdx = strongestIdx;
            while (selectedFeelsLikeIdx >= 0) {
                var selectedFeelsLikeCandidate = feelsLikeCandidates[selectedFeelsLikeIdx] as Array;
                if (!(selectedFeelsLikeCandidate[3] as Boolean)) {
                    requiredChain.add(selectedFeelsLikeIdx);
                }
                selectedFeelsLikeIdx = selectedFeelsLikeCandidate[4] as Number;
            }

            for (var chainIdx = requiredChain.size() - 1; chainIdx >= 0; chainIdx--) {
                var chainCandidateIdx = requiredChain[chainIdx] as Number;
                var chainCandidate = feelsLikeCandidates[chainCandidateIdx] as Array;
                chainCandidate[3] = true;
                selectedCandidates.add([chainCandidate[0], chainCandidate[1]]);
            }
        }

        // The display order remains chronological after priority selection.
        for (var sortEnd = selectedCandidates.size() - 1; sortEnd > 0; sortEnd--) {
            for (var sortIdx = 0; sortIdx < sortEnd; sortIdx++) {
                var leftCandidate = selectedCandidates[sortIdx] as Array;
                var rightCandidate = selectedCandidates[sortIdx + 1] as Array;
                if ((leftCandidate[1] as Number) > (rightCandidate[1] as Number)) {
                    selectedCandidates[sortIdx] = rightCandidate;
                    selectedCandidates[sortIdx + 1] = leftCandidate;
                }
            }
        }

        for (var selectedIdx = 0; selectedIdx < selectedCandidates.size(); selectedIdx++) {
            var selectedCandidate = selectedCandidates[selectedIdx] as Array;
            var selectedForecast = selectedCandidate[0] as ForecastWeather;
            timeline[selectedIdx] = buildForecastEvent(selectedForecast);
            if (selectedIdx > 0) {
                var previousChange = timeline[selectedIdx - 1] as Array;
                previousChange[2] = getForecastEventHour(selectedForecast);
            }
        }

        if (selectedCandidates.size() > 0) {
            var finalChange = timeline[selectedCandidates.size() - 1] as Array;
            var finalPointerHour = finalForecastHour;
            if (conditionCandidates.size() > weatherCycleMaxChanges) {
                finalPointerHour = firstOmittedConditionHour;
            }
            finalChange[2] = finalPointerHour;
        }

        return timeline;
    }

    hidden function updateForecastChanges() as Void {
        cachedForecastChange = null;
        cachedForecastSecondChange = null;
        cachedForecastThirdChange = null;
        cachedForecastFourthChange = null;

        if (cachedHourlyForecast.size() == 0) { return; }

        var timeline = null;
        if (weatherCondition != null && weatherCondition.condition != null) {
            var baseFeelsLike = (weatherCondition.feelsLikeTemperature == null) ? null : weatherCondition.feelsLikeTemperature as Float;
            timeline = buildForecastTimeline(weatherCondition.condition as Number, baseFeelsLike, -1, false);
        } else {
            // When current conditions cannot establish a baseline, use the first
            // usable future row and display it as the first forecast event.
            var now = Time.now().value();
            for (var i = 0; i < cachedHourlyForecast.size(); i++) {
                var forecast = cachedHourlyForecast[i];
                var forecastTime = forecast.forecastTime;
                if (forecastTime != null && (forecastTime as Number) <= now) { continue; }
                if (forecast.condition == null) { continue; }
                if (getWeatherGroup(forecast.condition as Number) == WEATHER_GROUP_UNKNOWN) { continue; }

                var baseFeelsLike = (forecast.feelsLikeTemperature == null) ? null : forecast.feelsLikeTemperature as Float;
                timeline = buildForecastTimeline(forecast.condition as Number, baseFeelsLike, i, true);
                break;
            }
        }

        if (timeline == null) { return; }
        cachedForecastChange = timeline[0];
        cachedForecastSecondChange = timeline[1];
        cachedForecastThirdChange = timeline[2];
        cachedForecastFourthChange = timeline[3];
    }

    hidden function hasWeatherCycleForecastChanges() as Boolean {
        return getForecastEventWeather(getActiveForecastChange()) != null;
    }

    hidden function formatForecastPointer(hour as Number?) as String {
        if (hour == null || hour < 0) { return ""; }
        return "  c" + formatHour(hour) + "H";
    }

    hidden function getForecastEventWeather(event as Array?) as ForecastWeather or Null {
        if (event == null || event.size() == 0) { return null; }
        if (event[0] == null) { return null; }
        return event[0] as ForecastWeather;
    }

    hidden function getForecastEventPointer(event as Array?, pointerIndex as Number) as Number? {
        if (event == null || event.size() <= pointerIndex) { return null; }
        if (event[pointerIndex] == null) { return null; }
        return event[pointerIndex] as Number;
    }

    hidden function formatWeatherConditionForWeather(activeWeather as ForecastWeather or Null, includePrecipitation as Boolean) as String {
        if (activeWeather == null || activeWeather.condition == null) {
            return "";
        }

        var perp = "";
        if(includePrecipitation &&
            activeWeather has :precipitationChance &&
            activeWeather.precipitationChance instanceof Number) {
            var precipitationChance = activeWeather.precipitationChance as Number;
            if (precipitationChance > 0) {
                perp = " (" + precipitationChance.format("%02d") + "%)";
            }
        }

        var idx = normalizeWeatherCondition(activeWeather.condition as Number, cachedWeatherResIds.size());

        return Application.loadResource(cachedWeatherResIds[idx]) + perp;
    }

    hidden function formatFeelsLikeForWeather(activeWeather as ForecastWeather or Null, includeLabel as Boolean) as String {
        if(activeWeather == null || activeWeather.feelsLikeTemperature == null) {
            return "";
        }

        var fltemp = convertTemperatureFloat(activeWeather.feelsLikeTemperature, cachedTempUnit);
        if(includeLabel) {
            return cachedTextResources[7] + formatTemperature(fltemp);
        }
        return formatTemperature(fltemp);
    }

    hidden function formatWeatherConditionFeelsLike(activeWeather as ForecastWeather or Null) as String {
        return join([
            formatWeatherConditionForWeather(activeWeather, false),
            formatFeelsLikeForWeather(activeWeather, false)
        ]);
    }

    hidden function formatWeatherCycleValue(activeWeather as ForecastWeather or Null, activeChange as Array?, activeSecondChange as Array?, activeThirdChange as Array?, activeFourthChange as Array?) as String {
        return getWeatherCycleValue(activeWeather, activeChange, activeSecondChange, activeThirdChange, activeFourthChange);
    }

    hidden function getWeatherCondition(includePrecipitation as Boolean) as String {
        return formatWeatherConditionForWeather(getActiveWeatherCondition(), includePrecipitation);
    }

    hidden function getTemperature() as String {
        var activeWeather = getActiveWeatherCondition();
        if(activeWeather != null and activeWeather.temperature != null) {
            var temp_val = activeWeather.temperature;
            return formatTemperature(convertTemperature(temp_val, cachedTempUnit));
        }
        return "";
    }

    hidden function getTempUnit() as String {
        var deviceSettings = getCachedDeviceSettings();
        var temp_unit_setting = (deviceSettings != null && deviceSettings has :temperatureUnits) ? deviceSettings.temperatureUnits : System.UNIT_METRIC;
        var propTempUnit = (propBitmapA >> 29) & 0x3;
        if((temp_unit_setting == System.UNIT_METRIC and (propTempUnit == 0 or propTempUnit == 3)) or propTempUnit == 1) {
            return "C";
        } else {
            return "F";
        }
    }

    hidden function formatTemperature(temp) as String {
        var propShowTempUnit = (propBitmapB & 0x1) == 1;
        var propTempUnit = (propBitmapA >> 29) & 0x3;
        if(propShowTempUnit) {
            if(propTempUnit == 3 or (propTempUnit == 0 and cachedTempUnit.equals("C"))) {
                return temp.format("%d") + "\u00B0";
            }
            return temp.format("%d") + cachedTempUnit;
        }
        return temp.format("%d");
    }

    hidden function convertTemperature(temp as Number, unit as String) as Number {
        if(unit.equals("C")) {
            return temp;
        } else {
            return ((temp * 9/5) + 32);
        }
    }

    hidden function convertTemperatureFloat(temp as Float, unit as String) as Float {
        if(unit.equals("C")) {
            return temp;
        } else {
            return ((temp * 9/5) + 32);
        }
    }

    hidden function getWind() as String {
        var windspeed = "";
        var bearing = "";
        var activeWeather = getActiveWeatherCondition();
        var propWindUnit = (propBitmapB >> 1) & 0x7;

        if(activeWeather != null and activeWeather.windSpeed != null) {
            var windspeed_mps = activeWeather.windSpeed;
            if(propWindUnit == 0) { // m/s
                windspeed = Math.round(windspeed_mps).format("%01d");
            } else if (propWindUnit == 1) { // km/h
                var windspeed_kmh = Math.round(windspeed_mps * 3.6);
                windspeed = windspeed_kmh.format("%01d");
            } else if (propWindUnit == 2) { // mph
                var windspeed_mph = Math.round(windspeed_mps * 2.237);
                windspeed = windspeed_mph.format("%01d");
            } else if (propWindUnit == 3) { // knots
                var windspeed_kt = Math.round(windspeed_mps * 1.944);
                windspeed = windspeed_kt.format("%01d");
            } else if(propWindUnit == 4) { // beufort
                if (windspeed_mps < 0.5f) {
                    windspeed = "0";  // Calm
                } else if (windspeed_mps < 1.5f) {
                    windspeed = "1";  // Light air
                } else if (windspeed_mps < 3.3f) {
                    windspeed = "2";  // Light breeze
                } else if (windspeed_mps < 5.5f) {
                    windspeed = "3";  // Gentle breeze
                } else if (windspeed_mps < 7.9f) {
                    windspeed = "4";  // Moderate breeze
                } else if (windspeed_mps < 10.7f) {
                    windspeed = "5";  // Fresh breeze
                } else if (windspeed_mps < 13.8f) {
                    windspeed = "6";  // Strong breeze
                } else if (windspeed_mps < 17.1f) {
                    windspeed = "7";  // Near gale
                } else if (windspeed_mps < 20.7f) {
                    windspeed = "8";  // Gale
                } else if (windspeed_mps < 24.4f) {
                    windspeed = "9";  // Strong gale
                } else if (windspeed_mps < 28.4f) {
                    windspeed = "10";  // Storm
                } else if (windspeed_mps < 32.6f) {
                    windspeed = "11";  // Violent storm
                } else {
                    windspeed = "12";  // Hurricane force
                }
            }
        }

        if(activeWeather != null and activeWeather.windBearing != null) {
            bearing = ((Math.round((activeWeather.windBearing.toFloat() + 180) / 45.0).toNumber() % 8) + 97).toChar().toString();
        }

        if (windspeed.equals("0")) {
            bearing = "\u2248"; // Calm / no meaningful direction
        }
        return bearing + windspeed;
    }

    hidden function getFeelsLike(include_label as Boolean) as String {
        return formatFeelsLikeForWeather(getActiveWeatherCondition(), include_label);
    }

    hidden function getHumidity() as String {
        var ret = "";
        var activeWeather = getActiveWeatherCondition();
        if(activeWeather != null and activeWeather.relativeHumidity != null) {
            ret = "\u25CF" + activeWeather.relativeHumidity.format("%d") + "%";
        }
        return ret;
    }

    hidden function getUVIndex() as String {
        var ret = "";
        var activeWeather = getActiveWeatherCondition();
        if(activeWeather != null and activeWeather has :uvIndex and activeWeather.uvIndex != null) {
            ret = "\u2600" + activeWeather.uvIndex.format("%d");
        }
        return ret;
    }

    hidden function getHighLow() as String {
        var ret = "";
        var activeWeather = getActiveWeatherCondition();
        if(activeWeather != null) {
            if(activeWeather.highTemperature != null or activeWeather.lowTemperature != null) {
                var high = (activeWeather.highTemperature != null) ? formatTemperature(convertTemperature(activeWeather.highTemperature, cachedTempUnit)) : "";
                var low = (activeWeather.lowTemperature != null) ? formatTemperature(convertTemperature(activeWeather.lowTemperature, cachedTempUnit)) : "";
                if (high.length() > 0 && low.length() > 0) {
                    ret = high + "/" + low;
                } else {
                    ret = high + low;
                }
            }
        }
        return ret;
    }

    hidden function getPrecip() as String {
        var ret = "";
        var activeWeather = getActiveWeatherCondition();
        if(activeWeather != null and activeWeather.precipitationChance != null) {
            ret = "\u26C6" + activeWeather.precipitationChance.format("%d") + "%";
        }
        return ret;
    }

    hidden function hoursToNextSunEvent() as String {
        var nextSunEventArray = getNextSunEvent();
        if(nextSunEventArray != null && nextSunEventArray.size() == 2) {
            var nextSunEvent = nextSunEventArray[0] as Time.Moment;
            var now = Time.now();
            // Converting seconds to hours
            var diff = (nextSunEvent.subtract(now)).value();
            if(diff >= 36000) { // No decimals if 10+ hours
                return (diff / 3600.0).format("%d");
            }
            return (diff / 3600.0).format("%.1f");
        }
        return "";
    }

    hidden function getNextSunEvent() as Array {
        if(refreshCache has :nextSunEventLoaded) {
            return (refreshCache as Dictionary).get(:nextSunEvent) as Array;
        }

        var result = [];
        var now = Time.now();
        var todaySunEvents = getCachedSunEvents(now, "today");
        if (todaySunEvents != null && todaySunEvents.size() == 2) {
            var sunrise = todaySunEvents[0] as Time.Moment;
            var sunset = todaySunEvents[1] as Time.Moment;
            if (sunrise.lessThan(now)) {
                var tomorrowSunEvents = getCachedSunEvents(Time.today().add(new Time.Duration(86401)), "tomorrow");
                if (tomorrowSunEvents != null && tomorrowSunEvents.size() == 2) {
                    sunrise = tomorrowSunEvents[0] as Time.Moment;
                }
            }
            if (sunset.lessThan(now)) {
                var tomorrowSunEvents = getCachedSunEvents(Time.today().add(new Time.Duration(86401)), "tomorrow");
                if (tomorrowSunEvents != null && tomorrowSunEvents.size() == 2) {
                    sunset = tomorrowSunEvents[1] as Time.Moment;
                }
            }
            if (sunrise != null && sunset != null) {
                result = sunrise.lessThan(sunset) ? [sunrise, true] : [sunset, false];
            }
        }

        refreshCache[:nextSunEventLoaded] = true;
        refreshCache[:nextSunEvent] = result;
        return result;
    }

    hidden function getRestCalories() as Number {
        if(refreshCache has :restCaloriesLoaded) {
            return (refreshCache as Dictionary).get(:restCalories) as Number;
        }

        var today = Time.Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var profile = getCachedUserProfile();
        var restCalories = -1;

        if (profile != null
            && profile has :weight && profile.weight != null
            && profile has :height && profile.height != null
            && profile has :birthYear && profile.birthYear != null) {
            var age = today.year - profile.birthYear;
            var weight = profile.weight / 1000.0;
            restCalories = 0;

            if (profile has :gender && profile.gender == UserProfile.GENDER_MALE) {
                restCalories = 5.2 - 6.116 * age + 7.628 * profile.height + 12.2 * weight;
            } else {
                restCalories = -197.6 - 6.116 * age + 7.628 * profile.height + 12.2 * weight;
            }

            // Calculate rest calories for the current time of day
            restCalories = Math.round((today.hour * 60 + today.min) * restCalories / 1440).toNumber();
        }

        refreshCache[:restCaloriesLoaded] = true;
        refreshCache[:restCalories] = restCalories;
        return restCalories;
    }

    hidden function getWeeklyDistance(activityInfo) as Number {
        if(refreshCache has :weeklyDistanceLoaded) {
            return (refreshCache as Dictionary).get(:weeklyDistance) as Number;
        }

        var weekly_distance = 0;
        if(activityInfo != null && activityInfo has :distance) {
            var history = ActivityMonitor.getHistory();
            if (history != null) {
                // Only take up to 6 previous days from history
                var daysToCount = history.size() < 6 ? history.size() : 6;
                for (var i = 0; i < daysToCount; i++) {
                    if (history[i].distance instanceof Number) {
                        weekly_distance += history[i].distance as Number;
                    }
                }
            }
            // Add today's distance
            if(activityInfo.distance != null) {
                weekly_distance += activityInfo.distance;
            }
        }

        refreshCache[:weeklyDistanceLoaded] = true;
        refreshCache[:weeklyDistance] = weekly_distance;
        return weekly_distance;
    }

    hidden function getWeeklyDistanceFromComplication(isRun as Boolean, conversionFactor as Float, width as Number) as String {
        var val = "";
        var hasComplications = ((runtimeBitmap >> 8) & 0x1) == 1;
        if (hasComplications) {
            try {
                var compType = isRun ? Complications.COMPLICATION_TYPE_WEEKLY_RUN_DISTANCE : Complications.COMPLICATION_TYPE_WEEKLY_BIKE_DISTANCE;
                var complication = Complications.getComplication(new Id(compType));
                var distance = (complication == null) ? null : toFloatIfNumeric(complication.value);
                if (distance != null) {
                    val = formatDistanceByWidth((distance as Float) * conversionFactor, width);
                }
            } catch(e) {
                // Complication not found or type not supported on this device
            }
        }
        return val;
    }

    // CGM Connect Widget helper functions
    hidden function getCgmComplicationByLabel(targetLabel as String) as Complications.Id? {
        var hasComplications = ((runtimeBitmap >> 8) & 0x1) == 1;
        if (!hasComplications) { return null; }
        try {
            var iter = Complications.getComplications();
            var comp = iter.next();
            while (comp != null) {
                var compType = comp.getType();
                var compLabel = comp.shortLabel;
                if (compType == Complications.COMPLICATION_TYPE_INVALID && compLabel != null) {
                    if (compLabel.equals(targetLabel)) {
                        Complications.subscribeToUpdates(comp.complicationId);
                        return comp.complicationId;
                    }
                }
                comp = iter.next();
            }
        } catch (e) {}
        return null;
    }

    hidden function convertCgmTrendToArrow(trend as String) as String {
        if (trend.equals("R")) { return "a"; }  // Rapidly rising ↑
        if (trend.equals("r")) { return "b"; }  // Rising ↗
        if (trend.equals("n")) { return "c"; }  // Neutral →
        if (trend.equals("d")) { return "d"; }  // Falling ↘
        if (trend.equals("D")) { return "e"; }  // Rapidly falling ↓
        return "";
    }

    hidden function getCgmReading() as String {
        var hasComplications = ((runtimeBitmap >> 8) & 0x1) == 1;
        if (!hasComplications) { return ""; }
        try {
            if (cgmComplicationIds[0] == null) {
                cgmComplicationIds[0] = getCgmComplicationByLabel("CGM");
            }
            var cgmComplicationId = cgmComplicationIds[0] as Complications.Id?;
            if (cgmComplicationId == null) { return ""; }

            var comp = Complications.getComplication(cgmComplicationId);
            if (comp == null || comp.value == null) { return ""; }

            var valueStr = valueToStringOrNull(comp.value);
            if (valueStr == null) { return ""; }
            if (valueStr.equals("---")) { return "---"; }

            var spaceIndex = valueStr.find(" ");
            if (spaceIndex == null) { return valueStr; }

            var reading = valueStr.substring(0, spaceIndex);
            var trend = valueStr.substring(spaceIndex + 1, valueStr.length());
            var arrow = convertCgmTrendToArrow(trend);
            return reading + arrow;
        } catch (e) {}
        return "";
    }

    hidden function getCgmAge() as String {
        var hasComplications = ((runtimeBitmap >> 8) & 0x1) == 1;
        if (!hasComplications) { return ""; }
        try {
            if (cgmComplicationIds[1] == null) {
                cgmComplicationIds[1] = getCgmComplicationByLabel("CGM Age");
            }
            var cgmAgeComplicationId = cgmComplicationIds[1] as Complications.Id?;
            if (cgmAgeComplicationId == null) { return ""; }
            var comp = Complications.getComplication(cgmAgeComplicationId);
            if (comp == null || comp.value == null) { return ""; }
            var valueStr = valueToStringOrNull(comp.value);
            if (valueStr == null) { return ""; }
            var timestamp = valueStr.toLong();
            if (timestamp == null || timestamp < 0) { return "---"; }
            var ageMin = (Time.now().value() - timestamp) / 60;
            if (ageMin < 0) { return "---"; }
            return ageMin.format("%d");
        } catch (e) {}
        return "";
    }


    hidden function dayName(day_of_week as Number) as String {
        if(weekNames == null) { init_week_month_names(); }
        if (weekNames == null) { return ""; }
        return weekNames[day_of_week - 1];
    }

    hidden function monthName(month as Number) as String {
        if(monthNames == null) { init_week_month_names(); }
        if (monthNames == null) { return ""; }
        return monthNames[month - 1];
    }

    hidden function init_week_month_names() as Void {
        weekNames = [Application.loadResource(Rez.Strings.DAY_OF_WEEK_SUN), Application.loadResource(Rez.Strings.DAY_OF_WEEK_MON),
                     Application.loadResource(Rez.Strings.DAY_OF_WEEK_TUE), Application.loadResource(Rez.Strings.DAY_OF_WEEK_WED),
                     Application.loadResource(Rez.Strings.DAY_OF_WEEK_THU), Application.loadResource(Rez.Strings.DAY_OF_WEEK_FRI),
                     Application.loadResource(Rez.Strings.DAY_OF_WEEK_SAT)];
        monthNames = [Application.loadResource(Rez.Strings.MONTH_JAN), Application.loadResource(Rez.Strings.MONTH_FEB), Application.loadResource(Rez.Strings.MONTH_MAR),
                      Application.loadResource(Rez.Strings.MONTH_APR), Application.loadResource(Rez.Strings.MONTH_MAY), Application.loadResource(Rez.Strings.MONTH_JUN),
                      Application.loadResource(Rez.Strings.MONTH_JUL), Application.loadResource(Rez.Strings.MONTH_AUG), Application.loadResource(Rez.Strings.MONTH_SEP),
                      Application.loadResource(Rez.Strings.MONTH_OCT), Application.loadResource(Rez.Strings.MONTH_NOV), Application.loadResource(Rez.Strings.MONTH_DEC)];
    }

    hidden function isoWeekNumber(year as Number, month as Number, day as Number) as Number {
        var first_day_of_year = julianDay(year, 1, 1);
        var given_day_of_year = julianDay(year, month, day);
        var day_of_week = (first_day_of_year + 3) % 7;
        var week_of_year = (given_day_of_year - first_day_of_year + day_of_week + 4) / 7;
        var ret = 0;
        if (week_of_year == 53) {
            if (day_of_week == 6) {
                ret = week_of_year;
            } else if (day_of_week == 5 && isLeapYear(year)) {
                ret = week_of_year;
            } else {
                ret = 1;
            }
        } else if (week_of_year == 0) {
            first_day_of_year = julianDay(year - 1, 1, 1);
            day_of_week = (first_day_of_year + 3) % 7;
            ret = (given_day_of_year - first_day_of_year + day_of_week + 4) / 7;
        } else {
            ret = week_of_year;
        }
        if(propWeekOffset != 0) {
            ret = ret + propWeekOffset;
        }
        return ret;
    }

    hidden function julianDay(year as Number, month as Number, day as Number) as Number {
        var a = (14 - month) / 12;
        var y = (year + 4800 - a);
        var m = (month + 12 * a - 3);
        return day + ((153 * m + 2) / 5) + (365 * y) + (y / 4) - (y / 100) + (y / 400) - 32045;
    }

    hidden function isLeapYear(year as Number) as Boolean {
        if (year % 4 != 0) {
            return false;
           } else if (year % 100 != 0) {
            return true;
        } else if (year % 400 == 0) {
            return true;
        }
        return false;
    }

    // Square helper functions - only compiled for square devices
    (:Square)
    hidden function loadBottomField2Property() as Void {
        propBottomField2Shows = getValueOrDefault("bottomField2Shows", -2) as Number;
    }

    (:Square)
    hidden function getBottomField2Shows() as Number {
        return propBottomField2Shows;
    }

    (:Square)
    hidden function computeBottomField2Values(values as Dictionary, now as Gregorian.Info, activityInfo, sysStats as System.Stats) as Void {
        values[:dataBottom2] = getDisplayValueByType(propBottomField2Shows, 5, now, activityInfo, sysStats);
        values[:dataBottom2Color] = hrGetDisplayValueColor(propBottomField2Shows, themeColors[dataVal], themeColors[bg]);
        if (propBottomFieldShows != -2 and propBottomField2Shows != -2) {
            values[:dataLabelBottom] = getLabelByType(propBottomFieldShows, 2);
            values[:dataLabelBottom2] = getLabelByType(propBottomField2Shows, 2);
        }
    }

    (:Square)
    hidden function calculateSquareLayout() as Void {
        var dualBottomFieldActive = (propBottomFieldShows != -2 and propBottomField2Shows != -2);
        bottomFiveYOriginal = bottomFiveY;

        if (dualBottomFieldActive) {
            layoutBitmap |= 0x40000000;
            // Position two 5-digit fields with 40px gap between them, centered
            var fieldWidth = bottomDataWidth * 5;
            var gap = 20;

            bottomFive1X = centerX - (gap / 2) - (fieldWidth / 2);
            bottomFive2X = centerX + (gap / 2) + (fieldWidth / 2);

            // Shift the entire row DOWN to make room for labels above.
            bottomFiveY = bottomFiveY + labelHeight + labelMargin;
        } else {
            layoutBitmap &= ~0x40000000;
            // Single field mode - center position
            bottomFive1X = centerX;
            bottomFive2X = centerX;
        }
    }

    (:Square)
    hidden function drawSquares(dc as Dc, values as Dictionary) as Void {
        var dualBottomFieldActive = (layoutBitmap & 0x40000000) != 0;
        var iconYAdj = ((layoutBitmap >> 20) & 0x1F) - 16;
        if (dualBottomFieldActive) {
            var field1Width = bottomDataWidth * 5;
            var field2Width = bottomDataWidth * 5;
            var field1Left = bottomFive1X - (field1Width / 2);
            var field2Left = bottomFive2X - (field2Width / 2);

            // Draw labels above fields using the same alignment rules as the standard fields.
            drawFieldLabel(dc, bottomFive1X, bottomFiveYOriginal, 0, values[:dataLabelBottom], field1Width);
            drawFieldLabel(dc, bottomFive2X, bottomFiveYOriginal, 0, values[:dataLabelBottom2], field2Width);

            // Draw both fields
            drawDataField(dc, bottomFive1X, bottomFiveY, 0,
                null, values[:dataBottom], 5,
                fontBottomData, values[:dataBottomColor]);

            drawDataField(dc, bottomFive2X, bottomFiveY, 0,
                null, values[:dataBottom2], 5,
                fontBottomData, values[:dataBottom2Color]);

            // Icons on outer edges
            dc.setColor(themeColors[dataVal], Graphics.COLOR_TRANSPARENT);
            dc.drawText(field1Left - (marginX / 2),
                bottomFiveY + (largeDataHeight / 2) + iconYAdj,
                fontIcons, values[:dataIcon1],
                Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);
            dc.drawText(field2Left + field2Width + (marginX / 2) - 2,
                bottomFiveY + (largeDataHeight / 2) + iconYAdj,
                fontIcons, values[:dataIcon2],
                Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        } else {
            // Single field - original behavior
            var step_width = drawDataField(dc, centerX, bottomFiveY, 0, null,
                values[:dataBottom], 5, fontBottomData, values[:dataBottomColor]);

            dc.setColor(themeColors[dataVal], Graphics.COLOR_TRANSPARENT);
            dc.drawText(centerX - (step_width / 2) - (marginX / 2),
                bottomFiveY + (largeDataHeight / 2) + iconYAdj,
                fontIcons, values[:dataIcon1],
                Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);
            dc.drawText(centerX + (step_width / 2) + (marginX / 2) - 2,
                bottomFiveY + (largeDataHeight / 2) + iconYAdj,
                fontIcons, values[:dataIcon2],
                Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }

    // Non-Square stubs for other devices
    (:Round)
    hidden function calculateSquareLayout() as Void {
        // No-op for non-square devices
    }

    (:Round)
    hidden function loadBottomField2Property() as Void {
        // No-op for non-square devices devices
    }

    (:Round)
    hidden function getBottomField2Shows() as Number {
        return -2; // Hidden by default for non-square devices devices
    }

    (:Round)
    hidden function computeBottomField2Values(values as Dictionary, now as Gregorian.Info, activityInfo, sysStats as System.Stats) as Void {
        // No-op for non-square devices devices
    }

    (:Square)
    hidden function drawBottomFieldsWithIcons(dc as Dc, values as Dictionary) as Void {
        drawSquares(dc, values);
    }

    (:Round)
    hidden function drawBottomFieldsWithIcons(dc as Dc, values as Dictionary) as Void {
        // Original single field behavior
        var iconYAdj = ((layoutBitmap >> 20) & 0x1F) - 16;
        var step_width = 0;
        if(screenHeight == 240) {
            step_width = drawDataField(dc, centerX - 19, bottomFiveY + 3, 0, null, values[:dataBottom], 5, fontBottomData, values[:dataBottomColor]);
        } else {
            step_width = drawDataField(dc, centerX, bottomFiveY, 0, null, values[:dataBottom], 5, fontBottomData, values[:dataBottomColor]);
        }

        // Draw icons
        dc.setColor(themeColors[dataVal], Graphics.COLOR_TRANSPARENT);
        if(screenHeight == 240) { step_width += 30; }
        dc.drawText(centerX - (step_width / 2) - (marginX / 2), bottomFiveY + (largeDataHeight / 2) + iconYAdj, fontIcons, values[:dataIcon1], Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(centerX + (step_width / 2) + (marginX / 2) - 2, bottomFiveY + (largeDataHeight / 2) + iconYAdj, fontIcons, values[:dataIcon2], Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
    }

}

class Segment34Delegate extends WatchUi.WatchFaceDelegate {
    var view as Segment34View;

    public function initialize(v as Segment34View) {
        WatchFaceDelegate.initialize();
        view = v;
    }

    public function onPress(clickEvent as WatchUi.ClickEvent) {
        view.toggleTouchAlternative();
        return true;
    }

}

class ForecastWeather {
    public var observationLocationPosition as Position.Location or Null;
    public var precipitationChance as Lang.Number or Null;
    public var temperature as Lang.Number or Null;
    public var windBearing as Lang.Number or Null;
    public var windSpeed as Lang.Float or Null;
    public var highTemperature as Lang.Number or Null;
    public var lowTemperature as Lang.Number or Null;
    public var feelsLikeTemperature as Lang.Float or Null;
    public var relativeHumidity as Lang.Number or Null;
    public var condition as Lang.Number or Null;
    public var uvIndex as Lang.Float or Null;
    public var forecastTime as Lang.Number or Null;
    public var forecastHour as Lang.Number or Null;
}

(:WeatherCache)
class StoredWeather {
    public var observationLocationPosition as Position.Location or Null;
    public var precipitationChance as Lang.Number or Null;
    public var temperature as Lang.Numeric or Null;
    public var windBearing as Lang.Number or Null;
    public var windSpeed as Lang.Float or Null;
    public var highTemperature as Lang.Numeric or Null;
    public var lowTemperature as Lang.Numeric or Null;
    public var feelsLikeTemperature as Lang.Float or Null;
    public var relativeHumidity as Lang.Number or Null;
    public var condition as Lang.Number or Null;
    public var uvIndex as Lang.Float or Null;
}
