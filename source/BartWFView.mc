using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.Lang as Lang;
using Toybox.Time as Time;
using Toybox.Time.Gregorian as Date;
using Toybox.ActivityMonitor as ActivityMonitor;
using Toybox.Activity as Activity;
using Toybox.Sensor as Sensor;
using Toybox.WatchUi;


class BartWFView extends Ui.WatchFace {

	//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// CONSTANTS
	//////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	const COLOR_BACKGROUND 		= Gfx.COLOR_BLACK;
	const COLOR_HOURS_MINUTES 	= Gfx.COLOR_WHITE;
	const COLOR_SECONDS			= Gfx.COLOR_GREEN;
	const COLOR_DATE 			= Gfx.COLOR_BLUE;

	const TIME_Y = 110;

	const STATS_ICON_OFFSET_X 	= 10;
	const STATS_VALUE_OFFSET_X 	= 68;
	const STATS_UNIT_OFFSET_X 	= 73;
	
	//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// VARIABLES
	//////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	var clockTime;

	// Screen dimensions
	var width;
	var height;
	var centerX;
	var centerY;

	// Icons
	var bluetoothIcon_on;
	var bluetoothIcon_off;
	var stepsIcon;
	var stairsIcon;
	var activeIcon;
	var heartIcon;

	//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// LIFECYCLE FUNCTIONS
	//////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    function initialize() {
        WatchFace.initialize();
        
        bluetoothIcon_on = Ui.loadResource(Rez.Drawables.bluetooth_on);
        bluetoothIcon_off = Ui.loadResource(Rez.Drawables.bluetooth_off);
        stepsIcon = Ui.loadResource(Rez.Drawables.steps);        
        stairsIcon = Ui.loadResource(Rez.Drawables.stairs);
        activeIcon = Ui.loadResource(Rez.Drawables.active);
        heartIcon = Ui.loadResource(Rez.Drawables.heart);
    }

    // The entry point for the View is onLayout(). This is called before the
    // View is shown to load resources and set up the layout of the View.
    // @param [Graphics.Dc] dc The drawing context
    // @return [Boolean] true if handled, false otherwise
    function onLayout(dc) {
        setLayout(Rez.Layouts.WatchFace(dc));
        
        width = dc.getWidth();
        height = dc.getHeight();
		centerX = width * 0.5;
		centerY = height * 0.5; 
		
        dc.setColor(COLOR_BACKGROUND, COLOR_BACKGROUND);
        dc.fillCircle(width / 2, height / 2, width / 2 + 2);
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() {
    }

    // When a View is active, onUpdate() is used to update dynamic content.
    // This function is called when the View is brought to the foreground.
    // For watchfaces it is called once a minute. 
    // @param [Graphics.Dc] dc The drawing context
    // @return [Boolean] true if handled, false otherwise
    function onUpdate(dc) {
        dc.clearClip();
                
		clockTime = Sys.getClockTime();
		if (clockTime.hour == 0 && clockTime.min == 0) {
			// midnight reset
			dc.setColor(COLOR_BACKGROUND, COLOR_BACKGROUND);
			dc.fillCircle(width / 2, height / 2, width / 2 + 2);
		}

		drawHourAndMinute(dc, clockTime);
		drawDate(dc);
		
		var activityMonitorInfo = ActivityMonitor.getInfo();
		drawActivityStats(dc, activityMonitorInfo);
		drawArcs(dc, activityMonitorInfo);
				
		drawBatteryLevel(dc, System.getSystemStats().battery);
		drawStatusIcons(dc, System.getDeviceSettings());

		drawSeparator(dc);

		drawSecond(dc, clockTime);
		drawHeartRate(dc, getHeartRate());
    }

	function onPartialUpdate(dc) {
        clockTime = Sys.getClockTime();
		drawSecond(dc, clockTime);
		drawHeartRate(dc, getHeartRate());
	}

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() {
    }

	function getHeartRate() {
		var heartRate = null;
		var activityInfo = Activity.getActivityInfo();

		if (activityInfo != null && activityInfo.currentHeartRate != null) {
			heartRate = (activityInfo.currentHeartRate).format("%5d");
		}

		if (null == heartRate) {
			var hrSample = ActivityMonitor.getHeartRateHistory(1, true).next();
			if ( (hrSample != null) && (hrSample.heartRate != ActivityMonitor.INVALID_HR_SAMPLE) ) {
				heartRate = (hrSample.heartRate).format("%5d");
			} else {
				heartRate =  "----";
			}
		}
		return heartRate;
	}

	//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// DRAWING FUNCTIONS
	//////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	// 1 Hz
	function drawSecond(dc, clockTime) {
		var secX = centerX + 85;
		var secY = TIME_Y + 16;
		dc.setClip(secX, secY, 30, 30);
        dc.setColor(COLOR_SECONDS, COLOR_BACKGROUND);
        dc.drawText(secX, secY, Gfx.FONT_SYSTEM_MEDIUM, clockTime.sec.format("%02d"), Gfx.TEXT_JUSTIFY_LEFT);
	}

	function drawHeartRate(dc, heartRate) {
		dc.setClip(centerX + 34, centerY - 77, 39, 15);
		dc.setColor(Gfx.COLOR_YELLOW, COLOR_BACKGROUND);
		dc.drawText(centerX + STATS_VALUE_OFFSET_X, centerY - 81, Gfx.FONT_XTINY, heartRate, Gfx.TEXT_JUSTIFY_RIGHT);
	}

	// 1/60 Hz
	function drawSeparator(dc) {
		dc.setColor(Gfx.COLOR_DK_GRAY, Gfx.COLOR_TRANSPARENT);
        dc.drawLine(0, centerY + 1, width, centerY + 1);
        dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);
        dc.drawLine(0, centerY, width, centerY);
	}

	function drawHourAndMinute(dc, clockTime) {
		dc.setColor(COLOR_HOURS_MINUTES, COLOR_BACKGROUND);
		var timeString = clockTime.hour.format("%02d") + ":" + clockTime.min.format("%02d");
		dc.drawText(centerX - 96, TIME_Y, Gfx.FONT_SYSTEM_NUMBER_THAI_HOT, timeString, Gfx.TEXT_JUSTIFY_LEFT);
	}

	function drawDate(dc) {
		var info = Date.info(Time.now(), Time.FORMAT_LONG);
        var dateString = Lang.format("$1$ $2$ $3$", [info.day_of_week, info.day, info.month]);
		dc.setColor(COLOR_DATE, COLOR_BACKGROUND);
		dc.drawText(centerX, height - 48, Gfx.FONT_SYSTEM_SMALL, dateString, Gfx.TEXT_JUSTIFY_CENTER);
	}

	function drawStatusIcons(dc, deviceSettings) {
		if (deviceSettings.phoneConnected) {
			dc.drawBitmap(centerX + 22, 4, bluetoothIcon_on);
		} else {
			dc.setColor(COLOR_BACKGROUND, COLOR_BACKGROUND);
			dc.fillRectangle(centerX + 22, 4, 16, 16); 
		}
	}
	
	function drawBatteryLevel(dc, batteryLevel) {
		// Draw battery
		dc.setColor(COLOR_BACKGROUND, COLOR_BACKGROUND);
		dc.fillRectangle(centerX - 32, 6, 44, 12);
		
		dc.setColor(Gfx.COLOR_DK_GRAY, COLOR_BACKGROUND);
		dc.drawRectangle(centerX - 32, 6, 44, 12);
		dc.fillRectangle(centerX + 12, 9, 2, 6);
		
		// Draw battery level indicator
		if (batteryLevel < 10.0) {
			dc.setColor(Gfx.COLOR_RED, COLOR_BACKGROUND);
		} else if (batteryLevel < 20.0) {
			dc.setColor(Gfx.COLOR_ORANGE, COLOR_BACKGROUND);
		} else {
			dc.setColor(Gfx.COLOR_GREEN, COLOR_BACKGROUND);
		}
		dc.fillRectangle(centerX - 30, 8, (batteryLevel / 2.5), 8);
	}

	function drawActivityStats(dc, activityMonitorInfo) {
		// Draw values
		dc.setColor(Gfx.COLOR_YELLOW, COLOR_BACKGROUND);
		dc.drawText(centerX + STATS_VALUE_OFFSET_X, centerY - 59, Gfx.FONT_XTINY, (activityMonitorInfo.distance / 100000.0).format("%5.1f"), Gfx.TEXT_JUSTIFY_RIGHT);
			
		dc.drawText(centerX + STATS_VALUE_OFFSET_X, centerY - 37, Gfx.FONT_XTINY, activityMonitorInfo.calories, Gfx.TEXT_JUSTIFY_RIGHT);

		// Draw units
		dc.drawBitmap(centerX + STATS_UNIT_OFFSET_X + 1, centerY - 76, heartIcon);
		dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);
		dc.drawText(centerX + STATS_UNIT_OFFSET_X, centerY - 59, Gfx.FONT_XTINY, "km", Gfx.TEXT_JUSTIFY_LEFT);
		dc.drawText(centerX + STATS_UNIT_OFFSET_X, centerY - 37, Gfx.FONT_XTINY, "kCal", Gfx.TEXT_JUSTIFY_LEFT);
	}

	function drawArc(dc, centerX, centerY, radius, lineWidth, color, value, goal) {
		var startAngle = 240;
		var fullAngle = 300;
		
		var toppedValue = value > goal ? goal : value;
		var toppedValueAngle = (startAngle - (fullAngle * toppedValue / goal)) % 360;
		
		dc.setColor(Gfx.COLOR_DK_GRAY, COLOR_BACKGROUND);
		dc.setPenWidth(lineWidth);	
		dc.drawArc(centerX, centerY, radius, Gfx.ARC_CLOCKWISE, startAngle, fullAngle); 
		
		if (toppedValueAngle != startAngle) {
			dc.setPenWidth(lineWidth + 3);
			dc.setColor(color, COLOR_BACKGROUND);
			dc.drawArc(centerX, centerY, radius, Gfx.ARC_CLOCKWISE, startAngle, toppedValueAngle);
		}
	}
	
	function drawArcs(dc, activityMonitorInfo) {		
		var stepStatsCenterX = 60;
		var stepStatsCenterY = 72;
		var activeMinutesCenterX = 120;
		var activeMinutesCenterY = 50;
		var floorsClimbedCenterX = 120;
		var floorsClimbedCenterY = 92;
		var bigArcRadius = 32;
		var smallArcRadius = 18;
	
		// Draw icons
		dc.drawBitmap(stepStatsCenterX - 12, stepStatsCenterY + 15, stepsIcon);
		dc.drawBitmap(activeMinutesCenterX - 8, activeMinutesCenterY - 8, activeIcon);
		dc.drawBitmap(floorsClimbedCenterX - 8, floorsClimbedCenterY - 8, stairsIcon);

		// Draw arcs
		drawArc(dc, stepStatsCenterX, stepStatsCenterY, bigArcRadius, 3, Gfx.COLOR_GREEN, 
			activityMonitorInfo.steps, activityMonitorInfo.stepGoal);
		drawArc(dc, activeMinutesCenterX, activeMinutesCenterY, smallArcRadius, 2, Gfx.COLOR_PURPLE, 
			activityMonitorInfo.activeMinutesWeek.total, activityMonitorInfo.activeMinutesWeekGoal);
		drawArc(dc, floorsClimbedCenterX, floorsClimbedCenterY, smallArcRadius, 2, Gfx.COLOR_YELLOW, 
			activityMonitorInfo.floorsClimbed, activityMonitorInfo.floorsClimbedGoal);
		 
		// Draw #steps
		dc.setPenWidth(1);
		dc.setColor(Gfx.COLOR_GREEN, COLOR_BACKGROUND);
		dc.drawText(stepStatsCenterX, stepStatsCenterY - 11, Gfx.FONT_SYSTEM_XTINY, activityMonitorInfo.steps, Gfx.TEXT_JUSTIFY_CENTER);
	}
}

