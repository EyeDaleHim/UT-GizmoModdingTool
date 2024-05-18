package;


class MainState extends FlxState
{
	public static var illusionFrameNum:Int = 1; // to give the illusion of 30FPS

	override function create()
	{
		super.create();

		FlxG.autoPause = false;

		FlxG.camera.pixelPerfectRender = true;
	}

	private static var _illusionFrames:Int = illusionFrameNum;

	public var stateTime:Float = 0.0;

	override function tryUpdate(elapsed:Float)
	{
		stateTime += elapsed;

		var leftOverElapsed:Float = elapsed;

		while (leftOverElapsed > 0)
		{
			if (_illusionFrames > 0)
				_illusionFrames--;
			else
				_illusionFrames = illusionFrameNum;

			leftOverElapsed -= 1 / FlxG.updateFramerate;
		}

		super.tryUpdate(elapsed);
	}
}
