// JXA script to get today's calendar events
// Called via: osascript -l JavaScript helpers/get_todays_events.js
// Uses bulk property access (fast) instead of iterating events (slow)

var app = Application("Calendar");
var cals = app.calendars();
var now = new Date();
var startOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 0, 0, 0);
var endOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59);

var skip = ["Holidays in United States", "Birthdays", "US Holidays", "Siri Suggestions"];
var results = [];

for (var c = 0; c < cals.length; c++) {
    var cal = cals[c];
    var calName = cal.name();
    if (skip.indexOf(calName) >= 0) continue;

    try {
        // Bulk access: get ALL start dates and summaries as arrays (fast)
        var allDates = cal.events.startDate();
        var allSummaries = cal.events.summary();
        var allAllDay = cal.events.alldayEvent();

        for (var i = 0; i < allDates.length; i++) {
            var sd = allDates[i];
            if (sd >= startOfDay && sd <= endOfDay) {
                var h = sd.getHours();
                var m = sd.getMinutes();
                var ampm = h >= 12 ? "PM" : "AM";
                h = h % 12 || 12;
                var timeStr = allAllDay[i] ? "ALL_DAY" : (h + ":" + (m < 10 ? "0" : "") + m + " " + ampm);
                results.push(calName + "|||" + (allSummaries[i] || "No Title") + "|||" + timeStr + "|||" + allAllDay[i]);
            }
        }
    } catch(e) {
        // Skip calendars that error
    }
}

results.join("\n") || "NO_EVENTS";
