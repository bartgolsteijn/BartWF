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

	const STATS_ICON_OFFSET_X 	= 6;
	const STATS_VALUE_OFFSET_X 	= 67;
	const STATS_UNIT_OFFSET_X 	= 72;

	
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
	var distanceIcon;
	var flameIcon;


	//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// LIFECYCLE FUNCTIONS
	//////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    function initialize() {
        WatchFace.initialize();
        
        bluetoothIcon_on = Ui.loadResource(Rez.Drawables.bluetooth_on);
        bluetoothIcon_off = Ui.loadResource(Rez.Drawables.bluetooth_off);
        stepsIcon = Ui.loadResource(Rez.Drawables.steps);        
        distanceIcon = Ui.loadResource(Rez.Drawables.distance);
        flameIcon = Ui.loadResource(Rez.Drawables.flame);
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
		drawHourAndMinute(dc, clockTime);
		drawDate(dc);
		
		var activityMonitorInfo = ActivityMonitor.getInfo();
		drawActivityStats(dc, activityMonitorInfo);
		drawStepStats(dc, activityMonitorInfo);
				
		drawBatteryLevel(dc, System.getSystemStats().battery);
		drawStatusIcons(dc, System.getDeviceSettings());

		drawSeparator(dc);

		drawSecond(dc, clockTime);
    }

	function onPartialUpdate(dc) {
        clockTime = Sys.getClockTime();
		drawSecond(dc, clockTime);
	}

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() {
    }

	//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// DRAWING FUNCTIONS
	//////////////////////////////////////////////////////////////////////////////////////////////////////////////////

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

	function drawSecond(dc, clockTime) {
		var secX = centerX + 85;
		var secY = TIME_Y + 16;
		dc.setClip(secX, secY, 30, 30);
        dc.setColor(COLOR_SECONDS, COLOR_BACKGROUND);
        dc.drawText(secX, secY, Gfx.FONT_SYSTEM_MEDIUM, clockTime.sec.format("%02d"), Gfx.TEXT_JUSTIFY_LEFT);				
	}

	function drawDate(dc) {
		var info = Date.info(Time.now(), Time.FORMAT_LONG);
        var dateString = Lang.format("$1$ $2$ $3$", [info.day_of_week, info.day, info.month]);
		dc.setColor(COLOR_DATE, COLOR_BACKGROUND);
		dc.drawText(centerX, height - 48, Gfx.FONT_SYSTEM_SMALL, dateString, Gfx.TEXT_JUSTIFY_CENTER);
	}

	function drawStatusIcons(dc, deviceSettings) {
		dc.setColor(Gfx.COLOR_BLUE, Gfx.COLOR_TRANSPARENT);
		if (deviceSettings.phoneConnected) {
			dc.drawBitmap(centerX - 36, 6, bluetoothIcon_on);
		} else {
			dc.drawBitmap(centerX - 36, 6, bluetoothIcon_off);
		}
	}
	
	function drawBatteryLevel(dc, batteryLevel) {
		// Draw battery
		dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);
		dc.drawRectangle(centerX - 8, 9, 44, 12);
		dc.fillRectangle(centerX + 36, 12, 2, 6);
		
		// Draw battery level indicator
		if (batteryLevel < 15.0) {
			dc.setColor(Gfx.COLOR_RED, COLOR_BACKGROUND);
		} else if (batteryLevel < 25.0) {
			dc.setColor(Gfx.COLOR_ORANGE, COLOR_BACKGROUND);
		} else {
			dc.setColor(Gfx.COLOR_GREEN, COLOR_BACKGROUND);
		}
		dc.fillRectangle(centerX - 6, 11, (batteryLevel / 2.5), 8);
	}

	function drawActivityStats(dc, activityMonitorInfo) {
		// Draw icons
		dc.drawBitmap(centerX + STATS_ICON_OFFSET_X, centerY - 67, distanceIcon);
		dc.drawBitmap(centerX + STATS_ICON_OFFSET_X, centerY - 45, flameIcon);

		// Draw values
		dc.setColor(Gfx.COLOR_YELLOW, COLOR_BACKGROUND);
		dc.drawText(centerX + STATS_VALUE_OFFSET_X, centerY - 71, Gfx.FONT_XTINY, (activityMonitorInfo.distance / 100000.0).format("%5.1f"), Gfx.TEXT_JUSTIFY_RIGHT);
		dc.drawText(centerX + STATS_VALUE_OFFSET_X, centerY - 49, Gfx.FONT_XTINY, activityMonitorInfo.calories, Gfx.TEXT_JUSTIFY_RIGHT);

		// Draw units
		dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);
		dc.drawText(centerX + STATS_UNIT_OFFSET_X, centerY - 71, Gfx.FONT_XTINY, "km", Gfx.TEXT_JUSTIFY_LEFT);
		dc.drawText(centerX + STATS_UNIT_OFFSET_X, centerY - 49, Gfx.FONT_XTINY, "kCal", Gfx.TEXT_JUSTIFY_LEFT);
		
		// Draw border
		dc.setColor(Gfx.COLOR_DK_GRAY, Gfx.COLOR_TRANSPARENT);
		dc.drawRectangle(centerX, centerY - 71, 120, 46);
	}
	
	function drawStepStats(dc, activityMonitorInfo) {
		var stepStatsCenterX = centerX - 60;
		var stepStatsCenterY = 72;
		var startAngle = 240;
		var fullAngle = 300;
		var actualSteps = (activityMonitorInfo.steps > activityMonitorInfo.stepGoal ? activityMonitorInfo.stepGoal : activityMonitorInfo.steps);		
		var targetAngle = (startAngle - (fullAngle * actualSteps / activityMonitorInfo.stepGoal)) % 360;
		
		dc.drawBitmap(stepStatsCenterX - 12, stepStatsCenterY + 15, stepsIcon);
		dc.setColor(Gfx.COLOR_DK_GRAY, COLOR_BACKGROUND);
		dc.setPenWidth(5);	
		dc.drawArc(stepStatsCenterX, stepStatsCenterY, 32, Gfx.ARC_CLOCKWISE, startAngle, fullAngle); 
		if (targetAngle != startAngle) {
			dc.setColor(Gfx.COLOR_GREEN, COLOR_BACKGROUND);
			dc.drawArc(stepStatsCenterX, stepStatsCenterY, 32, Gfx.ARC_CLOCKWISE, startAngle, targetAngle);
		} 
		dc.setPenWidth(1);
		dc.setColor(Gfx.COLOR_GREEN, Gfx.COLOR_BLACK);
		dc.drawText(stepStatsCenterX, stepStatsCenterY - 11, Gfx.FONT_SYSTEM_XTINY, activityMonitorInfo.steps, Gfx.TEXT_JUSTIFY_CENTER);
	}
}

