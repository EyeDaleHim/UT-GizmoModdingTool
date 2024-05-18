package ui.editor;

class ResizableSprite extends FlxSprite
{
	public var leftAnchor:FlxSprite;
	public var botAnchor:FlxSprite;
	public var topAnchor:FlxSprite;
	public var rightAnchor:FlxSprite;

	public var leftRect:FlxRect;
	public var botRect:FlxRect;
	public var topRect:FlxRect;
	public var rightRect:FlxRect;

	// slightly bigger
	public var topLeftRect:FlxRect;
	public var botLeftRect:FlxRect;
	public var topRightRect:FlxRect;
	public var botRightRect:FlxRect;

	public var canDrag:Bool = true;

	public var held:FlxDirectionFlags = NONE;
	public var lastHeld:FlxDirectionFlags = NONE;

	public var mouseHeld:Bool = false;

	public var onModify:Void->Void = null;

	private var _anchorsVisible:Bool = false;

	override public function new(?x:Float = 0.0, ?y:Float = 0.0, width:Int = 50, height:Int = 50, color:FlxColor = 0xFFBDBDBD, outline:FlxColor = 0xFFECECEC,
			?bitmap:FlxGraphicAsset = null, anchorsVisible:Bool = true)
	{
		super(x, y);

		moves = false;

		if (bitmap == null)
			makeGraphic(width, height, color);
		else
			loadGraphic(bitmap);

		if (anchorsVisible)
		{
			leftAnchor = new FlxSprite(x - 1, y - 1).makeGraphic(1, height + 2, outline);
			botAnchor = new FlxSprite(x - 1, y + height).makeGraphic(width + 2, 1, outline);
			topAnchor = new FlxSprite(x - 1, y - 1).makeGraphic(width + 2, 1, outline);
			rightAnchor = new FlxSprite(x + width - 1, y - 1).makeGraphic(1, height + 2, outline);
		}

		leftRect = FlxRect.get(x - 2, y, 4, height);
		botRect = FlxRect.get(x, y - 2, width, 4);
		topRect = FlxRect.get(x, y + height - 2, width, 4);
		rightRect = FlxRect.get(x + width - 2, y, 4, height);

		topLeftRect = FlxRect.get(x - 3, y - 3, 6, 6);
		botLeftRect = FlxRect.get(x - 3, y + height - 3, 6, 6);
		topRightRect = FlxRect.get(x + width - 3, y - 3, 6, 6);
		botRightRect = FlxRect.get(x + width - 3, y + height - 3, 6, 6);

		_anchorsVisible = anchorsVisible;

		updateSize();
	}

	var mouseLocation:FlxRect = FlxRect.get(FlxG.mouse.x - 2, FlxG.mouse.y - 2, 4, 4);

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		mouseLocation = FlxRect.get(FlxG.mouse.x - 2, FlxG.mouse.y - 2, 4, 4);

		var waitHeld:FlxDirectionFlags = NONE;

		if (canDrag)
		{
			if (FlxG.mouse.justPressed && mouseOverlaps())
			{
				mouseHeld = true;
			}

			if (FlxG.mouse.justReleased && held != NONE)
			{
				held = NONE;
			}
			else
			{
				if (held == NONE)
				{
					if (FlxG.mouse.justMoved)
					{
						var horizontalFlag:FlxDirectionFlags = NONE;
						var verticalFlag:FlxDirectionFlags = NONE;

						if (leftRect.overlaps(mouseLocation))
							horizontalFlag |= FlxDirectionFlags.LEFT;
						else if (rightRect.overlaps(mouseLocation))
							horizontalFlag |= FlxDirectionFlags.RIGHT;

						if (horizontalFlag == LEFT | RIGHT)
							horizontalFlag &= ~RIGHT;

						if (botRect.overlaps(mouseLocation))
							verticalFlag |= FlxDirectionFlags.DOWN;
						else if (topRect.overlaps(mouseLocation))
							verticalFlag |= FlxDirectionFlags.UP;

						if (verticalFlag == UP | DOWN)
							verticalFlag &= ~DOWN;

						waitHeld = horizontalFlag | verticalFlag;
					}

					if (lastHeld != waitHeld)
					{
						if (waitHeld.hasAny(LEFT) || waitHeld.hasAny(RIGHT))
							Main.cursor.loadSkin('lr-arrow', -13);
						else if (waitHeld.hasAny(DOWN) || waitHeld.hasAny(UP))
							Main.cursor.loadSkin('ud-arrow', 0, -13);

						if (mouseHeld)
							held = waitHeld;
						lastHeld = held;
					}
				}

				if (mouseHeld
					&& (held != NONE || mouseOverlaps())
					&& (FlxG.mouse.deltaX != 0 || FlxG.mouse.deltaY != 0))
				{
					if (held.hasAny(LEFT) && (FlxG.mouse.deltaX < 0 || width - Math.abs(FlxG.mouse.deltaX) > 2))
					{
						x += FlxG.mouse.deltaX;
						width -= FlxG.mouse.deltaX;
					}
					if (held.hasAny(RIGHT) && (FlxG.mouse.deltaX > 0 || width + Math.abs(FlxG.mouse.deltaX) > 2))
					{
						width += FlxG.mouse.deltaX;
					}

					if (held.hasAny(DOWN) && (FlxG.mouse.deltaY > 0 || height - Math.abs(FlxG.mouse.deltaY) > 2))
					{
						y += FlxG.mouse.deltaY;
						height -= FlxG.mouse.deltaY;
					}
					if (held.hasAny(UP) && (FlxG.mouse.deltaY < 0 || height + Math.abs(FlxG.mouse.deltaY) > 2))
					{
						height += FlxG.mouse.deltaY;
					}

					width.round();
					height.round();

					updateSize();

					if (onModify != null)
						onModify();
				}
			}
		}

		if (held == NONE)
		{
			leftRect.set(x - 2, y, 4, height);
			botRect.set(x, y - 2, width, 4);
			topRect.set(x, y + height - 2, width, 4);
			rightRect.set(x + width - 2, y, 4, height);

			topLeftRect.set(x - 3, y - 3, 6, 6);
			botLeftRect.set(x - 3, y + height - 3, 6, 6);
			topRightRect.set(x + width - 3, y - 3, 6, 6);
			botRightRect.set(x + width - 3, y + height - 3, 6, 6);

			if (FlxG.mouse.justMoved && (waitHeld == NONE || FlxG.mouse.justReleased))
				Main.cursor.loadSkin('cursor');

			if (!FlxG.mouse.pressed)
				mouseHeld = false;
			lastHeld = NONE;
		}

		mouseLocation.put();
	}

	public function updateSize():Void
	{
		setGraphicSize(width, height);
		centerOffsets();

		if (_anchorsVisible)
		{
			leftAnchor.setPosition(x - 1, y - 1);
			botAnchor.setPosition(x - 1, y + height);
			topAnchor.setPosition(x - 1, y - 1);
			rightAnchor.setPosition(x + width, y - 1);

			leftAnchor.setGraphicSize(1, height + 2);
			botAnchor.setGraphicSize(width + 2, 1);
			topAnchor.setGraphicSize(width + 2, 1);
			rightAnchor.setGraphicSize(1, height + 2);

			leftAnchor.updateHitbox();
			botAnchor.updateHitbox();
			topAnchor.updateHitbox();
			rightAnchor.updateHitbox();
		}
	}

	public function mouseOverlaps():Bool
	{
		mouseLocation = FlxRect.get(FlxG.mouse.x - 2, FlxG.mouse.y - 2, 4, 4);
		var rectHelper:FlxRect = FlxRect.get(x - 2, y - 2, width + 4, height + 4);

		return rectHelper.overlaps(mouseLocation);
	}

	override public function destroy()
	{
		super.destroy();

		FlxDestroyUtil.destroy(leftAnchor);
		FlxDestroyUtil.destroy(botAnchor);
		FlxDestroyUtil.destroy(topAnchor);
		FlxDestroyUtil.destroy(rightAnchor);
	}

	override public function draw()
	{
		super.draw();

		if (_anchorsVisible)
		{
			leftAnchor.draw();
			botAnchor.draw();
			topAnchor.draw();
			rightAnchor.draw();
		}
	}
}
