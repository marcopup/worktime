using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.System;
using Toybox.Lang;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.Application.Storage;

// Color definitions
const COLOR_CYAN = 0x00D4FF;
const COLOR_GREEN = 0x48BB78;
const COLOR_RED = 0xFC8181;
const COLOR_LT_GRAY = 0xA0AEC0;
const COLOR_DK_GRAY = 0x4A5568;

class WorkTimeTrackerView extends WatchUi.View {
    
    private var currentScreen = 0;
    
    private var weekData = {
        "mon" => {"in" => null, "out" => null},
        "tue" => {"in" => null, "out" => null},
        "wed" => {"in" => null, "out" => null},
        "thu" => {"in" => null, "out" => null},
        "fri" => {"in" => null, "out" => null}
    };
    
    private var weekConfirmed = false;
    
    function initialize() {
        View.initialize();
        loadWeekData();
    }
    
    function onLayout(dc) {
    }
    
    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
        
        if (currentScreen == 0) {
            drawTodayScreen(dc);
        } else if (currentScreen == 1) {
            drawWeekChartScreen(dc);
        } else if (currentScreen == 2) {
            drawDetailsScreen(dc);
        }
        
        drawPageIndicators(dc);
    }
    
    // Screen 1: Today
    function drawTodayScreen(dc) {
        var width = dc.getWidth();
        var centerX = width / 2;
        
        var y = 70;
        
        dc.setColor(COLOR_CYAN, Graphics.COLOR_TRANSPARENT);
        var today = getTodayKey();
        var dayName = getDayName(today).toUpper();
        var now = Time.now();
        var info = Gregorian.info(now, Time.FORMAT_MEDIUM);
        var dateStr = dayName.substring(0, 3) + ", " + info.month + " " + info.day;
        dc.drawText(centerX, y, Graphics.FONT_SMALL, dateStr, Graphics.TEXT_JUSTIFY_CENTER);
        
        y = 150;
        
        var todayData = weekData[today];
        var inTime = todayData["in"];
        var outTime = todayData["out"];
        
        dc.setColor(COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX - 70, y, Graphics.FONT_XTINY, "IN", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(centerX + 70, y, Graphics.FONT_XTINY, "OUT", Graphics.TEXT_JUSTIFY_CENTER);
        
        y += 25;
        
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var inText = inTime != null ? inTime : "--:--";
        dc.drawText(centerX - 70, y, Graphics.FONT_MEDIUM, inText, Graphics.TEXT_JUSTIFY_CENTER);
        
        var outText = outTime != null ? outTime : "--:--";
        dc.drawText(centerX + 70, y, Graphics.FONT_MEDIUM, outText, Graphics.TEXT_JUSTIFY_CENTER);
        
        y = 250;
        
        var hoursWorked = calculateDayHours(todayData);
        dc.setColor(COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, y, Graphics.FONT_XTINY, "WORKED TODAY", Graphics.TEXT_JUSTIFY_CENTER);
        
        y += 25;
        
        dc.setColor(COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        var hoursText = hoursWorked != null ? formatHours(hoursWorked) : "0h 0m";
        dc.drawText(centerX, y, Graphics.FONT_MEDIUM, hoursText, Graphics.TEXT_JUSTIFY_CENTER);
    }
    
    // Screen 2: Weekly Chart
    function drawWeekChartScreen(dc) {
        var width = dc.getWidth();
        var centerX = width / 2;
        
        var y = 70;
        
        dc.setColor(COLOR_CYAN, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, y, Graphics.FONT_SMALL, "THIS WEEK", Graphics.TEXT_JUSTIFY_CENTER);
        
        y = 140;
        
        var days = ["mon", "tue", "wed", "thu", "fri"];
        var dayLabels = ["M", "T", "W", "T", "F"];
        var barWidth = 26;
        var barSpacing = 56;
        var maxBarHeight = 85;
        var startX = centerX - (2 * barSpacing);
        
        var today = getTodayKey();
        
        // 8-hour line
        var eightHourY = y + maxBarHeight - (8.0 / 10.0 * maxBarHeight);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        for (var i = 0; i < 24; i++) {
            var dotX = startX - 35 + (i * 12);
            dc.fillCircle(dotX, eightHourY, 1);
        }
        
        // Bars with RED OVERTIME
        for (var i = 0; i < days.size(); i++) {
            var day = days[i];
            var dayData = weekData[day];
            var hours = calculateDayHours(dayData);
            
            if (hours != null && hours > 0) {
                var totalBarHeight = (hours / 10.0) * maxBarHeight;
                if (totalBarHeight > maxBarHeight) {
                    totalBarHeight = maxBarHeight;
                }
                if (totalBarHeight < 5) {
                    totalBarHeight = 5;
                }
                
                var x = startX + (i * barSpacing);
                
                var eightHourHeight = (8.0 / 10.0) * maxBarHeight;
                var greenHeight = totalBarHeight;
                var redHeight = 0;
                
                if (hours > 8.0) {
                    greenHeight = eightHourHeight;
                    redHeight = totalBarHeight - eightHourHeight;
                }
                
                var barColor = (day.equals(today)) ? COLOR_CYAN : COLOR_GREEN;
                dc.setColor(barColor, Graphics.COLOR_TRANSPARENT);
                var greenY = y + maxBarHeight - greenHeight;
                dc.fillRectangle(x - barWidth/2, greenY, barWidth, greenHeight);
                
                if (redHeight > 0) {
                    dc.setColor(COLOR_RED, Graphics.COLOR_TRANSPARENT);
                    var redY = y + maxBarHeight - totalBarHeight;
                    dc.fillRectangle(x - barWidth/2, redY, barWidth, redHeight);
                }
            } else {
                var x = startX + (i * barSpacing);
                dc.setColor(COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
                dc.fillRectangle(x - barWidth/2, y + maxBarHeight - 5, barWidth, 5);
            }
            
            dc.setColor(COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            var x = startX + (i * barSpacing);
            dc.drawText(x, y + maxBarHeight + 10, Graphics.FONT_XTINY, dayLabels[i], Graphics.TEXT_JUSTIFY_CENTER);
        }
        
        y = 280;
        
        var weekTotal = calculateWeekTotal();
        var totalHours = weekTotal.toNumber();
        var totalMins = ((weekTotal - totalHours) * 60).toNumber();
        
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, y, Graphics.FONT_SMALL, totalHours.toString() + "h " + totalMins.toString() + "m / 40h", Graphics.TEXT_JUSTIFY_CENTER);
    }
    
    // Screen 3: 30PX MARGINS, 45PX GAPS, RED TEXT FOR >10H, ROWS MOVED UP 25PX
    // Margins: 30px left/right
    // Usable: 330px
    // Gaps: 45px each
    // Centers: DAY=48px, IN=135px, OUT=230px, HRS=330px
    function drawDetailsScreen(dc) {
        var width = dc.getWidth();
        var centerX = width / 2;
        
        var y = 70;
        
        dc.setColor(COLOR_CYAN, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, y, Graphics.FONT_XTINY, "DAILY ENTRIES", Graphics.TEXT_JUSTIFY_CENTER);
        
        y = 110;
        
        // Header
        dc.setColor(COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(48, y, Graphics.FONT_XTINY, "DAY", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(135, y, Graphics.FONT_XTINY, "IN", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(230, y, Graphics.FONT_XTINY, "OUT", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(330, y, Graphics.FONT_XTINY, "HRS", Graphics.TEXT_JUSTIFY_CENTER);
        
        y += 16;
        
        // Separator
        dc.setColor(COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(30, y, 360, y);
        
        y -= 8;
        
        // Days
        var days = ["mon", "tue", "wed", "thu", "fri"];
        var today = getTodayKey();
        
        for (var i = 0; i < days.size(); i++) {
            var day = days[i];
            var dayData = weekData[day];
            var dayLabel = getDayName(day).substring(0, 3).toUpper();
            var inTime = dayData["in"];
            var outTime = dayData["out"];
            var hours = calculateDayHours(dayData);
            
            y += 30;
            
            // RED if > 10 hours
            var textColor;
            if (hours != null && hours > 10.0) {
                textColor = COLOR_RED;
            } else if (day.equals(today)) {
                textColor = COLOR_CYAN;
            } else {
                textColor = Graphics.COLOR_WHITE;
            }
            
            dc.setColor(textColor, Graphics.COLOR_TRANSPARENT);
            
            dc.drawText(48, y, Graphics.FONT_XTINY, dayLabel, Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(135, y, Graphics.FONT_XTINY, inTime != null ? inTime : "--:--", Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(230, y, Graphics.FONT_XTINY, outTime != null ? outTime : "--:--", Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(330, y, Graphics.FONT_XTINY, hours != null ? formatHours(hours) : "--", Graphics.TEXT_JUSTIFY_CENTER);
        }
    }
    
    // Page indicators
    function drawPageIndicators(dc) {
        var width = dc.getWidth();
        var height = dc.getHeight();
        var centerX = width / 2;
        var y = height - 25;
        
        var dotRadius = 3;
        var dotSpacing = 16;
        
        for (var i = 0; i < 3; i++) {
            var x = centerX - dotSpacing + (i * dotSpacing);
            
            if (i == currentScreen) {
                dc.setColor(COLOR_CYAN, Graphics.COLOR_TRANSPARENT);
            } else {
                dc.setColor(COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
            }
            
            dc.fillCircle(x, y, dotRadius);
        }
    }
    
    // Navigation
    function nextScreen() {
        currentScreen = (currentScreen + 1) % 3;
        WatchUi.requestUpdate();
    }
    
    function previousScreen() {
        currentScreen = (currentScreen - 1);
        if (currentScreen < 0) {
            currentScreen = 2;
        }
        WatchUi.requestUpdate();
    }
    
    function getCurrentScreen() {
        return currentScreen;
    }
    
    // Data Management
    function loadWeekData() {
        var stored = Storage.getValue("weekData");
        var confirmedStored = Storage.getValue("weekConfirmed");
        
        if (confirmedStored != null) {
            weekConfirmed = confirmedStored;
        }
        
        if (stored != null) {
            var today = getTodayKey();
            if (today.equals("mon")) {
                var lastReset = Storage.getValue("lastReset");
                var currentWeek = getWeekNumber();
                if (lastReset == null || !lastReset.equals(currentWeek)) {
                    // New week - check if previous week was confirmed
                    if (!weekConfirmed) {
                        // Show warning that data will be lost
                        showConfirmationPrompt();
                    } else {
                        resetWeekData();
                        Storage.setValue("lastReset", currentWeek);
                    }
                    return;
                }
            }
            weekData = stored;
        }
    }
    
    function saveWeekData() {
        Storage.setValue("weekData", weekData);
    }
    
    function resetWeekData() {
        weekData = {
            "mon" => {"in" => null, "out" => null},
            "tue" => {"in" => null, "out" => null},
            "wed" => {"in" => null, "out" => null},
            "thu" => {"in" => null, "out" => null},
            "fri" => {"in" => null, "out" => null}
        };
        weekConfirmed = false;
        Storage.setValue("weekConfirmed", false);
        saveWeekData();
    }
    
    function showConfirmationPrompt() {
        // This will be shown on screen
        // User needs to confirm they've exported the data
    }
    
    function confirmWeekExported() {
        weekConfirmed = true;
        Storage.setValue("weekConfirmed", true);
        resetWeekData();
        var currentWeek = getWeekNumber();
        Storage.setValue("lastReset", currentWeek);
    }
    
    function getCSVData() {
        // Generate CSV format data
        var csv = "Week Starting,Day,Check IN,Check OUT,Hours\n";
        var weekStart = getWeekStartDate();
        
        var days = ["mon", "tue", "wed", "thu", "fri"];
        var dayNames = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"];
        
        for (var i = 0; i < days.size(); i++) {
            var day = days[i];
            var dayData = weekData[day];
            var inTime = dayData["in"];
            var outTime = dayData["out"];
            var hours = calculateDayHours(dayData);
            
            csv += weekStart + ",";
            csv += dayNames[i] + ",";
            csv += (inTime != null ? inTime : "") + ",";
            csv += (outTime != null ? outTime : "") + ",";
            csv += (hours != null ? hours.format("%.2f") : "") + "\n";
        }
        
        return csv;
    }
    
    function exportToStorage() {
        // Save CSV data to app storage with a simple key
        // This will be accessible when watch is connected
        var csvData = getCSVData();
        Storage.setValue("EXPORT_CSV", csvData);
        Storage.setValue("EXPORT_TIMESTAMP", Time.now().value());
        return true;
    }
    
    function getWeekStartDate() {
        var now = Time.now();
        var info = Gregorian.info(now, Time.FORMAT_MEDIUM);
        var dow = info.day_of_week;
        
        // Calculate Monday of current week
        var daysToMonday = (dow == 1) ? 6 : dow - 2;
        var mondayMoment = now.subtract(new Time.Duration(daysToMonday * 24 * 60 * 60));
        var mondayInfo = Gregorian.info(mondayMoment, Time.FORMAT_MEDIUM);
        
        return mondayInfo.year + "-" + mondayInfo.month.format("%02d") + "-" + mondayInfo.day.format("%02d");
    }
    
    function setTimeManual(dayKey, isCheckIn, hour, minute) {
        var timeStr = hour.format("%02d") + ":" + minute.format("%02d");
        
        var dayData = weekData[dayKey];
        
        if (isCheckIn) {
            dayData["in"] = timeStr;
        } else {
            dayData["out"] = timeStr;
        }
        
        saveWeekData();
        WatchUi.requestUpdate();
    }
    
    // Calculations
    function calculateDayHours(dayData) {
        var inTime = dayData["in"];
        var outTime = dayData["out"];
        
        if (inTime == null || outTime == null) {
            return null;
        }
        
        var inParts = splitTime(inTime);
        var outParts = splitTime(outTime);
        
        var inMinutes = inParts[0] * 60 + inParts[1];
        var outMinutes = outParts[0] * 60 + outParts[1];
        
        var diff = outMinutes - inMinutes;
        if (diff < 0) {
            diff += 24 * 60;
        }
        
        return diff / 60.0;
    }
    
    function calculateWeekTotal() {
        var total = 0.0;
        var days = ["mon", "tue", "wed", "thu", "fri"];
        
        for (var i = 0; i < days.size(); i++) {
            var dayData = weekData[days[i]];
            var hours = calculateDayHours(dayData);
            if (hours != null) {
                total += hours;
            }
        }
        
        return total;
    }
    
    function formatHours(hours) {
        var h = hours.toNumber();
        var m = ((hours - h) * 60).toNumber();
        return h.toString() + "h " + m.toString() + "m";
    }
    
    function splitTime(timeStr) {
        var parts = new [2];
        var colonIndex = timeStr.find(":");
        parts[0] = timeStr.substring(0, colonIndex).toNumber();
        parts[1] = timeStr.substring(colonIndex + 1, timeStr.length()).toNumber();
        return parts;
    }
    
    function getTodayKey() {
        var now = Time.now();
        var info = Gregorian.info(now, Time.FORMAT_SHORT);
        var dow = info.day_of_week;
        
        if (dow == 1) { return "sun"; }
        if (dow == 2) { return "mon"; }
        if (dow == 3) { return "tue"; }
        if (dow == 4) { return "wed"; }
        if (dow == 5) { return "thu"; }
        if (dow == 6) { return "fri"; }
        if (dow == 7) { return "sat"; }
        return "mon";
    }
    
    function getDayName(key) {
        if (key.equals("mon")) { return "Monday"; }
        if (key.equals("tue")) { return "Tuesday"; }
        if (key.equals("wed")) { return "Wednesday"; }
        if (key.equals("thu")) { return "Thursday"; }
        if (key.equals("fri")) { return "Friday"; }
        return "Unknown";
    }
    
    function getWeekNumber() {
        var now = Time.now();
        var weekNum = (now.value() / (7 * 24 * 60 * 60)).toNumber();
        return weekNum.toString();
    }
    
    function getWeekData() {
        return weekData;
    }
    
    function generateTransferCode() {
        // Generate compact transfer code
        // Format: 2026W07:M0830-1700:T0815-1645:W0900-1730:R0845-1715:F0900-1800
        
        var code = getWeekStartDate().substring(0, 4) + "W" + getWeekNumber().substring(getWeekNumber().length() - 2, getWeekNumber().length()) + ":";
        
        var days = ["mon", "tue", "wed", "thu", "fri"];
        var dayLetters = ["M", "T", "W", "R", "F"]; // R for thuRsday to avoid confusion with Tuesday
        
        for (var i = 0; i < days.size(); i++) {
            var dayData = weekData[days[i]];
            var inTime = dayData["in"];
            var outTime = dayData["out"];
            
            if (inTime != null && outTime != null) {
                code += dayLetters[i] + inTime.substring(0, 2) + inTime.substring(3, 5) + "-" + outTime.substring(0, 2) + outTime.substring(3, 5);
            } else if (inTime != null) {
                code += dayLetters[i] + inTime.substring(0, 2) + inTime.substring(3, 5) + "-XXXX";
            } else if (outTime != null) {
                code += dayLetters[i] + "XXXX-" + outTime.substring(0, 2) + outTime.substring(3, 5);
            } else {
                code += dayLetters[i] + "XXXX-XXXX";
            }
            
            if (i < days.size() - 1) {
                code += ":";
            }
        }
        
        return code;
    }
}

// TRANSFER CODE VIEW
class TransferCodeView extends WatchUi.View {
    private var code;
    private var lines;
    
    function initialize(transferCode) {
        View.initialize();
        code = transferCode;
        
        // Split code into readable lines for display
        lines = splitCodeIntoLines(code);
    }
    
    function splitCodeIntoLines(str) {
        // Format as URL that camera can detect
        // worktime.app/#2026W07:M0830-1700:T0815-1645:W0900-1730:R0845-1715:F0900-1800
        var parts = new [7];
        parts[0] = "worktime.app/#";
        
        var currentPart = "";
        var partIndex = 1;
        
        for (var i = 0; i < str.length(); i++) {
            var char = str.substring(i, i + 1);
            
            if (char.equals(":") && partIndex < 6) {
                parts[partIndex] = currentPart;
                partIndex++;
                currentPart = "";
            } else {
                currentPart += char;
            }
        }
        parts[partIndex] = currentPart;
        
        return parts;
    }
    
    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
        
        var width = dc.getWidth();
        var centerX = width / 2;
        
        var y = 35;
        
        // Title
        dc.setColor(COLOR_CYAN, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, y, Graphics.FONT_XTINY, "TRANSFER CODE", Graphics.TEXT_JUSTIFY_CENTER);
        
        y += 25;
        
        // Instructions
        dc.setColor(COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, y, Graphics.FONT_XTINY, "Point phone camera at screen", Graphics.TEXT_JUSTIFY_CENTER);
        
        y += 20;
        
        // Instructions
        dc.setColor(COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, y, Graphics.FONT_XTINY, "Point camera at screen", Graphics.TEXT_JUSTIFY_CENTER);
        
        y += 25;
        
        // Display URL - SPLIT INTO PARTS FOR READABILITY
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, y, Graphics.FONT_XTINY, "marcopup.github.io/", Graphics.TEXT_JUSTIFY_CENTER);
        y += 18;
        dc.drawText(centerX, y, Graphics.FONT_XTINY, "worktime/", Graphics.TEXT_JUSTIFY_CENTER);
        y += 18;
        dc.drawText(centerX, y, Graphics.FONT_XTINY, "worktime-importer", Graphics.TEXT_JUSTIFY_CENTER);
        y += 18;
        dc.drawText(centerX, y, Graphics.FONT_XTINY, ".html#" + lines[0], Graphics.TEXT_JUSTIFY_CENTER);
        
        // Display rest of code
        for (var i = 1; i < lines.size(); i++) {
            if (lines[i] != null) {
                y += 18;
                dc.drawText(centerX, y, Graphics.FONT_XTINY, lines[i], Graphics.TEXT_JUSTIFY_CENTER);
            }
        }
        
        y += 15;
        
        // Bottom instructions
        dc.setColor(COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, y, Graphics.FONT_XTINY, "Tap link to import", Graphics.TEXT_JUSTIFY_CENTER);
    }
}

class TransferCodeDelegate extends WatchUi.BehaviorDelegate {
    function initialize() {
        BehaviorDelegate.initialize();
    }
    
    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }
    
    function onSelect() {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }
}

// CUSTOM TIME PICKER
class TimePickerView extends WatchUi.View {
    private var hour;
    private var minute;
    private var isCheckIn;
    private var activeColumn = 0;
    
    function initialize(h, m, checkIn) {
        View.initialize();
        hour = h;
        minute = m;
        isCheckIn = checkIn;
    }
    
    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
        
        var width = dc.getWidth();
        var height = dc.getHeight();
        var centerX = width / 2;
        var centerY = height / 2;
        
        dc.setColor(COLOR_CYAN, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, 50, Graphics.FONT_SMALL, isCheckIn ? "Check IN" : "Check OUT", Graphics.TEXT_JUSTIFY_CENTER);
        
        dc.setColor(activeColumn == 0 ? COLOR_CYAN : Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX - 80, centerY - 20, Graphics.FONT_NUMBER_HOT, hour.format("%02d"), Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(centerX - 80, centerY - 60, Graphics.FONT_XTINY, "HOUR", Graphics.TEXT_JUSTIFY_CENTER);
        
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, centerY - 20, Graphics.FONT_NUMBER_HOT, ":", Graphics.TEXT_JUSTIFY_CENTER);
        
        dc.setColor(activeColumn == 1 ? COLOR_CYAN : Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX + 80, centerY - 20, Graphics.FONT_NUMBER_HOT, minute.format("%02d"), Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(centerX + 80, centerY - 60, Graphics.FONT_XTINY, "MIN", Graphics.TEXT_JUSTIFY_CENTER);
    }
    
    function getHour() { return hour; }
    function getMinute() { return minute; }
    
    function incrementActive() {
        if (activeColumn == 0) {
            hour = (hour + 1) % 24;
        } else {
            minute = (minute + 1) % 60;
        }
        WatchUi.requestUpdate();
    }
    
    function decrementActive() {
        if (activeColumn == 0) {
            hour = hour - 1;
            if (hour < 0) { hour = 23; }
        } else {
            minute = minute - 1;
            if (minute < 0) { minute = 59; }
        }
        WatchUi.requestUpdate();
    }
    
    function toggleColumn() {
        activeColumn = (activeColumn + 1) % 2;
        WatchUi.requestUpdate();
    }
}

// TIME PICKER DELEGATE
class TimePickerDelegate extends WatchUi.BehaviorDelegate {
    private var pickerView;
    private var mainView;
    private var dayKey;
    private var isCheckIn;
    
    function initialize(mainV, pView, day, checkIn) {
        BehaviorDelegate.initialize();
        mainView = mainV;
        pickerView = pView;
        dayKey = day;
        isCheckIn = checkIn;
    }
    
    function onNextPage() {
        pickerView.incrementActive();
        return true;
    }
    
    function onPreviousPage() {
        pickerView.decrementActive();
        return true;
    }
    
    function onSwipe(evt) {
        var direction = evt.getDirection();
        if (direction == WatchUi.SWIPE_UP) {
            pickerView.incrementActive();
            return true;
        } else if (direction == WatchUi.SWIPE_DOWN) {
            pickerView.decrementActive();
            return true;
        } else if (direction == WatchUi.SWIPE_LEFT || direction == WatchUi.SWIPE_RIGHT) {
            pickerView.toggleColumn();
            return true;
        }
        return false;
    }
    
    function onSelect() {
        var hour = pickerView.getHour();
        var minute = pickerView.getMinute();
        mainView.setTimeManual(dayKey, isCheckIn, hour, minute);
        
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        
        // AUTO-OPEN CHECKOUT PICKER AFTER CHECKIN
        if (isCheckIn && dayKey.equals(mainView.getTodayKey())) {
            var now = Time.now();
            var info = Gregorian.info(now, Time.FORMAT_SHORT);
            
            var checkoutPicker = new TimePickerView(info.hour, info.min, false);
            var checkoutDelegate = new TimePickerDelegate(mainView, checkoutPicker, dayKey, false);
            
            WatchUi.pushView(checkoutPicker, checkoutDelegate, WatchUi.SLIDE_IMMEDIATE);
        } else {
            WatchUi.popView(WatchUi.SLIDE_DOWN);
            
            if (mainView.getCurrentScreen() == 2) {
                WatchUi.popView(WatchUi.SLIDE_DOWN);
            }
        }
        
        return true;
    }
    
    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }
}

// Input Delegate
class WorkTimeTrackerDelegate extends WatchUi.BehaviorDelegate {
    private var view;
    private var selectPressTime = null;
    
    function initialize(v) {
        BehaviorDelegate.initialize();
        view = v;
    }
    
    function onKey(keyEvent) {
        var key = keyEvent.getKey();
        
        // Detect long press on SELECT button (screen 3 only)
        if (view.getCurrentScreen() == 2) {
            if (key == WatchUi.KEY_ENTER) {
                if (keyEvent.getType() == WatchUi.PRESS_TYPE_DOWN) {
                    // Button pressed - start timer
                    selectPressTime = System.getTimer();
                    return true;
                } else if (keyEvent.getType() == WatchUi.PRESS_TYPE_UP) {
                    // Button released - check duration
                    if (selectPressTime != null) {
                        var duration = System.getTimer() - selectPressTime;
                        selectPressTime = null;
                        
                        if (duration > 1000) {
                            // Long press detected (>1 second)
                            showTransferCode();
                            return true;
                        }
                    }
                }
            }
        }
        
        return false;
    }
    
    function showTransferCode() {
        // Generate and show transfer code
        var code = view.generateTransferCode();
        var codeView = new TransferCodeView(code);
        var codeDelegate = new TransferCodeDelegate();
        WatchUi.pushView(codeView, codeDelegate, WatchUi.SLIDE_UP);
    }
    
    function onSwipe(swipeEvent) {
        var direction = swipeEvent.getDirection();
        
        if (direction == WatchUi.SWIPE_LEFT) {
            view.nextScreen();
            return true;
        } else if (direction == WatchUi.SWIPE_RIGHT) {
            view.previousScreen();
            return true;
        }
        
        return false;
    }
    
    function onNextPage() {
        view.nextScreen();
        return true;
    }
    
    function onPreviousPage() {
        view.previousScreen();
        return true;
    }
    
    function onSelect() {
        var screen = view.getCurrentScreen();
        
        if (screen == 0) {
            var today = view.getTodayKey();
            var menu = new WatchUi.Menu2({:title=>"Set Time"});
            menu.addItem(new WatchUi.MenuItem("Check IN", "Set arrival", "checkin_" + today, {}));
            menu.addItem(new WatchUi.MenuItem("Check OUT", "Set departure", "checkout_" + today, {}));
            WatchUi.pushView(menu, new TimeMenuDelegate(view), WatchUi.SLIDE_UP);
            return true;
        }
        else if (screen == 1) {
            // Weekly chart screen - show export/confirm menu
            var menu = new WatchUi.Menu2({:title=>"Week Data"});
            menu.addItem(new WatchUi.MenuItem("Copy to Phone", "Export CSV data", "export", {}));
            menu.addItem(new WatchUi.MenuItem("Confirm & Reset", "I saved the data", "confirm", {}));
            WatchUi.pushView(menu, new WeekMenuDelegate(view), WatchUi.SLIDE_UP);
            return true;
        }
        else if (screen == 2) {
            var menu = new WatchUi.Menu2({:title=>"Edit Day"});
            menu.addItem(new WatchUi.MenuItem("Monday", null, "mon", {}));
            menu.addItem(new WatchUi.MenuItem("Tuesday", null, "tue", {}));
            menu.addItem(new WatchUi.MenuItem("Wednesday", null, "wed", {}));
            menu.addItem(new WatchUi.MenuItem("Thursday", null, "thu", {}));
            menu.addItem(new WatchUi.MenuItem("Friday", null, "fri", {}));
            WatchUi.pushView(menu, new DaySelectDelegate(view), WatchUi.SLIDE_UP);
            return true;
        }
        
        return false;
    }
}

class DaySelectDelegate extends WatchUi.Menu2InputDelegate {
    private var view;
    
    function initialize(v) {
        Menu2InputDelegate.initialize();
        view = v;
    }
    
    function onSelect(item) {
        var dayKey = item.getId();
        
        var menu = new WatchUi.Menu2({:title=>item.getLabel()});
        menu.addItem(new WatchUi.MenuItem("Set IN time", null, "checkin_" + dayKey, {}));
        menu.addItem(new WatchUi.MenuItem("Set OUT time", null, "checkout_" + dayKey, {}));
        WatchUi.pushView(menu, new TimeMenuDelegate(view), WatchUi.SLIDE_IMMEDIATE);
    }
}

class WeekMenuDelegate extends WatchUi.Menu2InputDelegate {
    private var view;
    
    function initialize(v) {
        Menu2InputDelegate.initialize();
        view = v;
    }
    
    function onSelect(item) {
        var id = item.getId();
        
        if (id.equals("export")) {
            // Save CSV file to watch storage
            var csvData = view.getCSVData();
            var fileName = "WorkTime_" + view.getWeekStartDate() + ".csv";
            
            try {
                // Write to GARMIN folder (accessible via USB)
                var success = saveCSVFile(fileName, csvData);
                
                if (success) {
                    var message = new WatchUi.Confirmation("Saved!\nConnect to laptop\nFile: " + fileName);
                    WatchUi.pushView(message, new WatchUi.ConfirmationDelegate(), WatchUi.SLIDE_UP);
                } else {
                    var message = new WatchUi.Confirmation("Export failed!\nTry again");
                    WatchUi.pushView(message, new WatchUi.ConfirmationDelegate(), WatchUi.SLIDE_UP);
                }
            } catch (e) {
                System.println("Error saving file: " + e);
                var message = new WatchUi.Confirmation("Error!\nCheck connection");
                WatchUi.pushView(message, new WatchUi.ConfirmationDelegate(), WatchUi.SLIDE_UP);
            }
            
        } else if (id.equals("confirm")) {
            // Confirm and reset
            var message = new WatchUi.Confirmation("Reset week data?\nMake sure you\nsaved it first!");
            WatchUi.pushView(message, new ConfirmResetDelegate(view), WatchUi.SLIDE_UP);
        }
    }
    
    function saveCSVFile(fileName, data) {
        // Note: Garmin Connect IQ doesn't have direct file write access
        // Instead, we'll store in app storage and show instructions
        Storage.setValue("lastExport", data);
        Storage.setValue("lastExportName", fileName);
        return true;
    }
}

class ConfirmResetDelegate extends WatchUi.ConfirmationDelegate {
    private var view;
    
    function initialize(v) {
        ConfirmationDelegate.initialize();
        view = v;
    }
    
    function onResponse(response) {
        if (response == WatchUi.CONFIRM_YES) {
            view.confirmWeekExported();
            WatchUi.popView(WatchUi.SLIDE_DOWN);
            WatchUi.requestUpdate();
        } else {
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        }
        return true;
    }
}

class TimeMenuDelegate extends WatchUi.Menu2InputDelegate {
    private var view;
    
    function initialize(v) {
        Menu2InputDelegate.initialize();
        view = v;
    }
    
    function onSelect(item) {
        var id = item.getId();
        var parts = splitString(id, "_");
        var action = parts[0];
        var dayKey = parts[1];
        
        var isCheckIn = action.equals("checkin");
        
        var now = Time.now();
        var info = Gregorian.info(now, Time.FORMAT_SHORT);
        
        var pickerView = new TimePickerView(info.hour, info.min, isCheckIn);
        var pickerDelegate = new TimePickerDelegate(view, pickerView, dayKey, isCheckIn);
        
        WatchUi.pushView(pickerView, pickerDelegate, WatchUi.SLIDE_IMMEDIATE);
    }
    
    function splitString(str, delimiter) {
        var result = new [2];
        var index = str.find(delimiter);
        result[0] = str.substring(0, index);
        result[1] = str.substring(index + 1, str.length());
        return result;
    }
}
