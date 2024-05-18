package objects;

class Splash extends FlxSprite
{
	public override function new(?X:Float = 0, ?Y:Float = 0)
	{
		super(X, Y);
		loadGraphic(Assets.image("splash"));

		active = false;
		antialiasing = false;
		scale.set(0.5, 0.5);
        updateHitbox();
		screenCenter();
	}
}
