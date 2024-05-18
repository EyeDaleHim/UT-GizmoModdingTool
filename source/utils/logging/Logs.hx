package utils.logging;

import flixel.util.typeLimit.OneOfTwo;
import openfl.events.IOErrorEvent;
import openfl.system.Capabilities;
import lime.system.System;
import sys.io.FileOutput;

class Logs
{
	private static final LOG_STARTER:String = "
[START OF LOG]

NOTES:
    - Undertale is created by Toby Fox. Buy the game here: https://undertale.com/
    - Gizmo Engine is part of Undertale Purple. The framework used to develop Undertale Purple. Check out the repository there: ???
    - Gizmo Engine and Undertale Purple are created by EyeDaleHim. https://twitter.com/eye_dalehim

[%a] [STARTUP]: Loading %b - %c

_____ [[  SYSTEM INFO  ]] _____

> Operating System: %d
> Executable location: %e
> Device Vendor: %f
> CPU Architecture: %g

_______________________________\n
";

	private static var _INIT:Bool = false;

	private static var _STORED_MESSAGES:Array<Message> = [];

	// sometimes it can be annoying to see the same error with the same graphic path
	private static var _CANNOT_RENDER_GRAPHIC_CACHE:Array<CommonLogs> = [];

	private static var logFile:FileOutput;

	public static var BUFFER_SIZE:Int = 50; // How big should our logs be in memory before we write

	private static function _print(log:OneOfTwo<CommonLogs, String>, type:Type):Void
	{
		var time:String = DateTools.format(Date.now(), "%H-%M-%S");

		var outputLog:Message = null;

		if (Std.isOfType(log, String))
			outputLog = {log: Custom(cast(log, String)), time: time, type: type};
		else
			outputLog = {log: log, time: time, type: type};

		if (outputLog.log.getName() == "CannotFindRoomItem")
			_CANNOT_RENDER_GRAPHIC_CACHE.push(outputLog.log.getParameters()[0]);

		_STORED_MESSAGES.push(outputLog);

		var line:String = "";

		switch (outputLog.log)
		{
			case Custom(message):
				line = message;
			case CannotFindRoomItem(graphic, roomItem):
				line = 'Couldn\'t check $graphic. Check for overworlds/${roomItem.getName()}/$graphic';
			case FileNotFound(path):
				line = 'Could not find $path';
			case IOError(e):
				line = e.toString();
		}

		trace(line);

		if (_STORED_MESSAGES.length > BUFFER_SIZE)
		{
			trace('buffer overfill...');
			for (i in 0..._STORED_MESSAGES.length)
			{
				var logItem:CommonLogs = _STORED_MESSAGES[i].log;

				switch (logItem)
				{
					case Custom(message):
						line = '$message';
					case CannotFindRoomItem(graphic, roomItem):
						if (!_CANNOT_RENDER_GRAPHIC_CACHE.contains(logItem))
							line = 'Couldn\'t check $graphic. Check for overworlds/${roomItem.getName()}/$graphic';
					case FileNotFound(path):
						line = 'Could not find $path';
					case IOError(e):
						line = e.toString();
				}
				if (line.length > 0)
					logFile.writeString('[$time] [$type]: $line\n');
			}

			logFile.flush();
			_STORED_MESSAGES.resize(0);
		}
	}

	public static function init():Void
	{
		if (!_INIT)
		{
			_INIT = true;

			var date:String = DateTools.format(Date.now(), "%Y-%m-%d_%H-%M-%S");

			var directory = Path.join([System.applicationStorageDirectory, 'logs']);
			var file:String = '$date.log';

			var meta = openfl.Lib.current.stage.application.meta;

			if (!FileSystem.exists(directory))
			{
				FileSystem.createDirectory(directory);
			}

			logFile = File.write(Path.join([directory, file]));

			var starterOutput:String = LOG_STARTER;
			starterOutput = starterOutput.replace('%a', date);
			starterOutput = starterOutput.replace('%b', meta["name"]);
			starterOutput = starterOutput.replace('%c', meta["version"]);
			starterOutput = starterOutput.replace('%d', '${System.platformLabel} - ${System.platformVersion} (${System.platformName})');
			starterOutput = starterOutput.replace('%e', System.applicationDirectory);
			starterOutput = starterOutput.replace('%f', '${System.deviceVendor} (${System.deviceModel})');
			starterOutput = starterOutput.replace('%g', Capabilities.cpuArchitecture);

			starterOutput = starterOutput.trim();

			logFile.writeString(starterOutput, UTF8);
			logFile.flush();
		}
	}

	public static function warn(log:OneOfTwo<CommonLogs, String>):Void
	{
		_print(log, WARNING);
	}

	public static function info(log:OneOfTwo<CommonLogs, String>):Void
	{
		_print(log, INFO);
	}
}

typedef Message =
{
	var type:Type;
	var time:String;
	var log:CommonLogs;
};

enum abstract Type(String)
{
	var INFO:Type;
	var NOTICE:Type;
	var WARNING:Type;
	var ERROR:Type;
	var STARTUP:Type;
}

enum RoomItem
{
	TILES;
	DECALS;
}

enum CommonLogs
{
	CannotFindRoomItem(graphic:String, roomItem:RoomItem);
	IOError(error:IOErrorEvent);
	FileNotFound(path:String);
	Custom(message:String);
}
