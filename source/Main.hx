package;

import system.input.Cursor;
import states.editors.RoomEditorState;
import ui.debug.Info;
import openfl.events.KeyboardEvent;
import lime.app.Application;
import macros.*;
import openfl.Lib;
import openfl.display.Sprite;
import lime.system.CFFI;

class Main extends Sprite
{
	public static var gameWidth:Int = 640; // Width of the game in pixels (might be less / more in actual pixels depending on your zoom).
	public static var gameHeight:Int = 480; // Height of the game in pixels (might be less / more in actual pixels depending on your zoom).
	public static var framerate:Int = 60; // How many frames per second the game should run at.
	public static var skipSplash:Bool = true; // Whether to skip the flixel splash screen that appears in release mode.
	public static var startFullscreen:Bool = false; // Whether to start the game in fullscreen on desktop targets

	public static var game:FlxGame;
	public static var cursor:system.input.Cursor;
	public static var debugInfo:Info;

	public static function main():Void
	{
		Lib.current.addChild(new Main());
	}

	public function new()
	{
		super();

		debugInfo = new Info(1, 1);

		FlxG.stage.quality = LOW;

		Controls._save = new FlxSave();
		Controls.load();

		InputHelper.load();

		Story._save = new FlxSave();

		Logs.init();

		DiscordHandler.init();

		Application.current.window.resizable = false;

		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, function(e)
		{
			var code = e.keyCode;

			if (code == F4)
				FlxG.fullscreen = !FlxG.fullscreen;
			if (code == F6)
				FlxG.switchState(new states.admin.DebugState());
		});

		game = new FlxGame(gameWidth, gameHeight, states.SplashIntro.new, framerate, framerate, skipSplash, startFullscreen);
		cursor = new Cursor();
		addChild(game);
		addChild(debugInfo);
		addChild(cursor);

		addEventListener(openfl.events.MouseEvent.MOUSE_MOVE, function(e)
		{
			cursor.bitmap.x = e.stageX;
			cursor.bitmap.y = e.stageY;
		});

		FlxG.mouse.visible = false;

		// Application.current.window.vsync = true;

		// sys.thread.Thread.createWithEventLoop
	}
}
