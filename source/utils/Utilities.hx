package utils;

class Utilities
{
	public static function getBottom(spr:FlxSprite):Float
	{
		if (spr == null)
			return 0.0;
		return spr.y + spr.height;
	}

	public static function getRight(spr:FlxSprite):Float
	{
		if (spr == null)
			return 0.0;
		return spr.x + spr.width;
	}

	public static function centerOverlay(object:FlxObject, base:FlxObject, axes:FlxAxes = XY):FlxObject
	{
		if (object == null || base == null)
			return object;

		if (axes.x)
			object.x = base.x + (base.width / 2) - (object.width / 2);

		if (axes.y)
			object.y = base.y + (base.height / 2) - (object.height / 2);

		return object;
	}

	public static function calcRelativeRect(spr:FlxSprite, rect:FlxRect):FlxRect
		return FlxRect.get(rect.x - spr.x, rect.y - spr.y, rect.width, rect.height);
}
