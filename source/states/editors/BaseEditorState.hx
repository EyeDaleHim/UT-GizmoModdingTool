package states.editors;

import openfl.display.Screen;

class BaseEditorState extends MainState
{
	public function preCreate():Void
	{
		FlxG.resizeGame(1600, 900);
		FlxG.resizeWindow(1600, 900);

		FlxG.stage.window.x = ((Screen.mainScreen.bounds.right / 2) - (FlxG.stage.window.width / 2)).floor();
		FlxG.stage.window.y = ((Screen.mainScreen.bounds.bottom / 2) - (FlxG.stage.window.height / 2)).floor();

		Reflect.setProperty(FlxG, "initialWidth", 1600);
		Reflect.setProperty(FlxG, "initialHeight", 900);

		Reflect.setProperty(FlxG, "width", 1600);
		Reflect.setProperty(FlxG, "height", 900);

		var newCam:FlxCamera = new FlxCamera(0, 0, 1600, 900, 1.0);
		FlxG.cameras.reset(newCam);

		Main.debugInfo.align = TOP_RIGHT;

		Main.cursor.loadSkin('cursor');
	}

	override public function destroy()
	{
		FlxG.resizeGame(Main.gameWidth, Main.gameHeight);
		FlxG.resizeWindow(Main.gameWidth, Main.gameHeight);

		FlxG.stage.window.x = ((Screen.mainScreen.bounds.right / 2) - (FlxG.stage.window.width / 2)).floor();
		FlxG.stage.window.y = ((Screen.mainScreen.bounds.bottom / 2) - (FlxG.stage.window.height / 2)).floor();

		Reflect.setProperty(FlxG, "initialWidth", Main.gameWidth);
		Reflect.setProperty(FlxG, "initialHeight", Main.gameHeight);

		Reflect.setProperty(FlxG, "width", Main.gameWidth);
		Reflect.setProperty(FlxG, "height", Main.gameHeight);

		var newCam:FlxCamera = new FlxCamera(0, 0, Main.gameWidth, Main.gameHeight, 1.0);
		FlxG.cameras.reset(newCam);

		Main.debugInfo.align = TOP_LEFT;

		super.destroy();
	}
}
