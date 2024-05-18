package utils.tools;

class CameraUtils
{
	public static function fromWheelZoom(?camera:FlxCamera, mult:Float = 1.0, ?min:Float, ?max:Float):Void
	{
        if (camera == null)
            camera = FlxG.camera;

		if (FlxG.mouse.wheel != 0)
			camera.zoom += (FlxG.mouse.wheel * mult);

		if (min != null)
			camera.zoom = Math.max(camera.zoom, min);
		if (max != null)
			camera.zoom = Math.min(camera.zoom, max);
	}
}
