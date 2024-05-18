package ui.editor;

import states.editors.AnimationEditorState;

class Button extends FlxSprite
{
	public static final NORMAL:Int = 0;
	public static final HIGHLIGHT:Int = 1;
	public static final PRESS:Int = 2;

	public var status:Int = NORMAL;

	public var onClick:Void->Void;
	public var onHover:Void->Void;

	public var hold:Bool = false;

	public var buttonColor:FlxColor = 0xFF222529;
	public var hoverColor:FlxColor = 0xFF777E85;
	public var pressColor:FlxColor = 0xFF101113;

	// sprites
	public var textObj:FlxText;
	public var iconSpr:FlxSprite;

	override public function new(?x:Float = 0.0, ?y:Float = 0.0, ?text:String = "", ?icon:BitmapData, ?size:Int = 8, fixed:Bool = false)
	{
		super(x, y);

		if (icon != null)
		{
			iconSpr = new FlxSprite(icon);
			iconSpr.setGraphicSize(16, 16);
			iconSpr.updateHitbox();
		}
		else
		{
			textObj = new FlxText(x, y, 0, text);
			textObj.setFormat(null, (size * 4).floor());
			textObj.font = Assets.font("editor").fontName;
			textObj.scale.set(0.25, 0.25);
			textObj.updateHitbox();
			textObj.antialiasing = true;
			textObj.color = AnimationEditorState.mainTextColor;
		}

		var makeWidth:Int = 1;
		var makeHeight:Int = 1;

		if (text.length == 1 || icon != null)
		{
			makeWidth = 22;
			makeHeight = 22;
		}
		else if (textObj != null)
		{
			makeWidth = (80.max(textObj.width + 8 * 4)).floor();
			makeHeight = (textObj.height + 4 * 4).floor();
			if (fixed)
			{
				makeWidth = (textObj.width + 8).floor();
				makeHeight = (textObj.height + 4).floor();
			}
		}

		makeGraphic(makeWidth, makeHeight, 0x0, true);
		FlxSpriteUtil.drawRoundRect(this, 0.0, 0.0, makeWidth, makeHeight, 8.0, 8.0, 0xFFFFFFFF);
		color = buttonColor;

		Utilities.centerOverlay(textObj, this);

		moves = false;
		if (textObj != null)
			textObj.active = false;
		if (iconSpr != null)
			iconSpr.active = false;
	}

	private var _hovered:Bool = false;

	private var _holdTimer:Float = 0.0;
	private var _holdDelay:Float = 0.02;
	private var _holdStart:Float = 1.0;

	private var _isHolding:Bool = false;

	public override function update(elapsed:Float)
	{
		if (textObj != null)
			Utilities.centerOverlay(textObj, this);
		if (iconSpr != null)
			Utilities.centerOverlay(iconSpr, this);

		if (FlxG.mouse.overlaps(this, camera))
		{
			status = HIGHLIGHT;

			if (!_hovered)
			{
				if (onHover != null)
					onHover();

				_hovered = true;
			}

			if (FlxG.mouse.pressed)
			{
				if (hold)
				{
					var localDelay:Float = _isHolding ? _holdDelay : _holdStart;

					while (_holdTimer >= localDelay)
					{
						_isHolding = true;

						status = PRESS;

						_holdTimer -= localDelay;
						if (onClick != null)
							onClick();
					}

					_holdTimer += elapsed;
				}
				else
					status = PRESS;
			}

			if (FlxG.mouse.justReleased)
			{
				if (_isHolding)
					_isHolding = false;
				else if (onClick != null)
					onClick();
			}
		}
		else
		{
			status = NORMAL;

			_hovered = false;
		}

		switch (status)
		{
			case NORMAL:
				color = buttonColor;
			case PRESS:
				color = pressColor;
			case HIGHLIGHT:
				color = hoverColor;
		}
	}

	override function draw()
	{
		super.draw();

		textObj?.draw();
		iconSpr?.draw();
	}

	override function set_camera(Value:FlxCamera):FlxCamera
	{
		if (_cameras == null)
			_cameras = [Value];
		else
			_cameras[0] = Value;

		if (textObj != null)
			textObj.camera = Value;
		if (iconSpr != null)
			iconSpr.camera = Value;

		return Value;
	}
}
