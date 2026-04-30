# Segment34Plus - Frequently asked Questions

### How do I change the settings? Where are the settings?
The settings is only available through the Garmin Connect IQ app. Go to [the page for the watch face](https://apps.garmin.com/apps/38417f58-d9a2-4d76-a10d-ad2263acdf6b) and look for the big blue Settings button. You can also find it if you go to Device -> My Watch Faces -> Segment34Plus.

The settings can not be changed on the watch itself.

### How does the custom themes work?
Custom themes are best created with the [Theme designer](https://ludw.github.io). When it looks they way you want just copy the string of color codes at the bottom and enter them into the "Custom colors" field in settings for the watchface. Make sure to also select "Custom colors" as the theme.

### What are that field called in settings? What is that number?
Most fields can be configures in settings what data they should display. This picture explains what everything is called:

![explainer](explainer.png)

For watches with an AMOLED screen you have two more fields shown in the Always On Display (if activated). These are called "Always On (below clock)" and "Second Always On Field (to the right)".

## Dissapearing or hidden fields

### Why are seconds disappearing?
Seconds are shown while the watch face is active and stop updating when the watch face goes inactive or enters low-power mode.

If you have an AMOLED screen you can enable the Always On Display to always see the hours and minutes, but updating the screen every second is not possible (this is a limitation from Garmins side, not with this watch face).

### I added the value X, and it doesn't show up, why?
If a specific value does not show up (you see an empty spot instead) it's most likely because your watch does not have that value available. As a watch face developer there is nothing I can do to make it available. 

### Why is weather (or sunset/sunrise) disappearing after a while? Why is the top part of the screen empty?
The weather fields, including sunrise and sunset, need weather data to display anything.

If you use `Garmin Weather`, the data comes from Garmin's Weather API through the Garmin Connect app on your phone. If it does not show up, make sure the watch is connected to the phone over Bluetooth and that Garmin Connect has location access.

If you use `Open-Meteo`, the watch face fetches weather in a Garmin background service. This mode is automatic-location only. It will try the device position first, then Garmin Weather's current observation location. If a refresh fails for any reason, the last saved Open-Meteo forecast stays visible until a newer refresh succeeds or the normal 8-hour cache window expires.

Open-Meteo uses Open-Meteo's generic forecast endpoint with automatic best-model selection for the current location.

### How do I change the weather provider?
Open the watch face settings in Garmin Connect IQ and look for `Weather provider`. `Open-Meteo` is the default. `Garmin Weather` keeps the same layouts and weather fields, but switches the data source back to Garmin's Weather API.

## Commonly requested features

### Can you translate the watch to <language>?
I might do that in the future, but it's a lot of work. I have it on my list but no promises for when this might happen.

### Will you add support for Open Weather API?
Not short term at least. I don't want to add the complexity having multiple weather data sources would mean. I've also seen that other watch faces with support for it have recieved quite a lot of negative reviews from users that can't figure out how to get a API token which makes me a bit less keen on working on this...

### Can you make the font larger / configurable?
You can check out my other watchface Segment34 MAX, it is basically the same but with larger text.
