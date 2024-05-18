package objects;

class Soul extends FlxSprite
{
    public static final speed:Float = 120;

	public var currentImage:FlxGraphic;
	public var hurtImage:FlxGraphic;

	public var controllable:Bool = false;

	override public function new(?x:Float = 0, ?y:Float = 0)
	{
		currentImage = Assets.image('battle/soul');
		hurtImage = Assets.image('battle/soul_hurt');

		super(x, y, currentImage);
	}

	override public function update(elapsed:Float)
	{
		moves = controllable && Controls.checkList([left_move, down_move, up_move, right_move], PRESSED);

		if (moves)
		{
			var left:Bool = Controls.getControl(left_move).pressed();
			var down:Bool = Controls.getControl(down_move).pressed();
			var up:Bool = Controls.getControl(up_move).pressed();
			var right:Bool = Controls.getControl(right_move).pressed();

			if (up && down)
				up = down = false;
			if (left && right)
				left = right = false;

			var newAngle:Float = 0;

			if (up)
			{
				newAngle = -90;
				if (left)
					newAngle -= 45;
				else if (right)
					newAngle += 45;
			}
			else if (down)
			{
				newAngle = 90;
				if (left)
					newAngle += 45;
				else if (right)
					newAngle -= 45;
			}
			else if (left)
				newAngle = 180;
			else if (right)
				newAngle = 0;

			velocity.setPolarDegrees(speed, newAngle);
		}

		var oldPos = getPosition();
		super.update(elapsed);

		if (moves)
			trace(getPosition().subtractPoint(oldPos));
	}
}
