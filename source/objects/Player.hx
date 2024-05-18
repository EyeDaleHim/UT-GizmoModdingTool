package objects;

class Player extends AnimatedSprite
{
	public var char:String = "";

	public var baseSpeed:Float = 90;
	public var speedMult:Float = 1.0;
	public var running:Bool = false;

	public var controllable:Bool = true;

	public var hitbox:FlxObject;

	override public function new(?x:Float = 0.0, ?y:Float = 0.0, char:String)
	{
		super(x, y, 'player/$char/$char');

		hitbox = new FlxObject(x, y, 16, 4);
		hitbox.centerOverlay(this, X);
		hitbox.y = y + height - hitbox.height;

		animation.play("moveDOWN", 1);
		animation.pause();
	}

	override public function setPosition(x:Float = 0.0, y:Float = 0.0)
	{
		this.hitbox.x = x;
		this.hitbox.y = y;
	}

	private var firstFacing:FlxDirectionFlags = NONE;

	override public function update(elapsed:Float)
	{
		var pressedMovements:Array<Bool> = [
			Controls.getControl(left_move).pressed(),
			Controls.getControl(down_move).pressed(),
			Controls.getControl(up_move).pressed(),
			Controls.getControl(right_move).pressed()
		];

		var lastRunning:Bool = running;

		running = Controls.getControl(sprint).pressed();
		if (running)
			speedMult = 1.5;
		else
			speedMult = 1.0;

		if (!controllable)
			pressedMovements.splice(0, pressedMovements.length);

		var up:Bool = pressedMovements[2];
		var down:Bool = pressedMovements[1];
		var left:Bool = pressedMovements[0];
		var right:Bool = pressedMovements[3];

		if (up && down)
			up = down = false;
		if (left && right)
			left = right = false;

		var moved:Bool = (up || down || left || right);

		if (moved)
		{
			var realFacing:FlxDirectionFlags = FlxDirectionFlags.fromBools(left, right, up, down);
			facing = FlxDirectionFlags.fromBools(left && !hitbox.touching.hasAny(LEFT), right && !hitbox.touching.hasAny(RIGHT), up && !hitbox.touching.hasAny(UP), down
				&& !hitbox.touching.hasAny(DOWN));

			if (!facing.hasAny(firstFacing))
			{
				// fuck man
				if ((left && up) || (left && down))
				{
					firstFacing = LEFT;
				}
				else if ((right && up) || (right && down))
				{
					firstFacing = RIGHT;
				}
				else
				{
					firstFacing = realFacing;
				}
			}

			if (up)
				hitbox.velocity.y = -baseSpeed * speedMult;
			else if (down)
				hitbox.velocity.y = baseSpeed * speedMult;
			else
				hitbox.velocity.y = 0.0;

			if (left)
				hitbox.velocity.x = -baseSpeed * speedMult;
			else if (right)
				hitbox.velocity.x = baseSpeed * speedMult;
			else
				hitbox.velocity.x = 0.0;
		}
		else
			hitbox.velocity.set();

		this.centerOverlay(hitbox, X);
		y = hitbox.y - (height - 4);

		if (facing != NONE && (hitbox.velocity.x != 0 || hitbox.velocity.y != 0))
		{
			var action:String = "move";

			if (running)
				action = "run";

			if (lastRunning != running)
				animation.stop();

			var outputFacing:FlxDirectionFlags = facing;

			if (hitbox.touching != NONE)
			{
				var initialFacing:FlxDirectionFlags = outputFacing;

				outputFacing = outputFacing.without(hitbox.touching);
				if (outputFacing == NONE)
				{
					outputFacing = initialFacing;
					action = "move";
				}
			}
			else if (outputFacing != firstFacing)
				outputFacing = firstFacing;

			animation.play(action + outputFacing.toString(), 2);
		}
		else if (animation.curAnim != null)
		{
			animation.play("move" + firstFacing.toString());

			animation.pause();
			animation.curAnim.curFrame = 1;
		}

		if (!moved)
		{
			animation.play("move" + firstFacing.toString(), true);

			animation.pause();
			animation.curAnim.curFrame = 1;

			facing = firstFacing;
			firstFacing = NONE;
		}

		hitbox.update(elapsed);
		super.update(elapsed);
	}

	override public function draw()
	{
		super.draw();
		hitbox.draw();
	}
}
