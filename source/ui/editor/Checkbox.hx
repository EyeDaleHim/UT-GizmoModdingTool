package ui.editor;

import states.editors.AnimationEditorState;

class Checkbox extends FlxSprite
{
	public var checkText:FlxText;

	private var _getValue:Void->Bool = function()
	{
		return true;
	};

	private var _setValue:Bool->Void = function(value:Bool)
	{
		
	};

	private var _primaryColor:FlxColor;

	public override function new(?X:Float = 0, ?Y:Float = 0, Width:Int, Height:Int, Color:FlxColor, Text:String, ?getValue:Void->Bool, ?setValue:Bool->Void)
	{
		super(X, Y);

		if (getValue != null)
			_getValue = getValue;
		if (setValue != null)
			_setValue = setValue;

		makeGraphic(Width, Height, Color, true, 'chkbox_${Width}_${Height}_${Color.toHexString()}');

		_primaryColor = Color;

		checkText = new FlxText(this.getRight() + 4, y, 0, '$Text');
		checkText.setFormat(null, 56);
		checkText.font = Assets.font("editor").fontName;
		checkText.scale.set(0.25, 0.25);
		checkText.updateHitbox();
		checkText.antialiasing = true;
		checkText.color = AnimationEditorState.mainTextColor;
		checkText.x = this.getRight() + 4;
		checkText.centerOverlay(this, FlxAxes.Y);

		// uhh
		_setValue(!_getValue());
		toggleValue();
	}

	public override function update(elapsed:Float)
	{
		if (FlxG.mouse.justReleased && FlxG.mouse.overlaps(this, camera))
			toggleValue();

		super.update(elapsed);
	}

	public override function draw()
	{
		super.draw();
		checkText.draw();
	}

	public function toggleValue(?ignore:Bool = false):Void
	{
		if (_getValue != null && _setValue != null)
		{
			if (!ignore)
				_setValue(!_getValue());

			pixels.lock();
			if (_getValue())
			{
				pixels.fillRect(new Rectangle(2, 2, width - 4, width - 4), 0);
				pixels.fillRect(new Rectangle(4, 4, width - 6, width - 6), _primaryColor);
			}
			else
				pixels.fillRect(new Rectangle(2, 2, width - 4, width - 4), 0);
			pixels.unlock();
		}
	}

	override function set_camera(Value:FlxCamera):FlxCamera
	{
		if (_cameras == null)
			_cameras = [Value];
		else
			_cameras[0] = Value;

		if (checkText != null)
			checkText.camera = Value;

		return Value;
	}

	override public function loadGraphic(graphic:FlxGraphicAsset, animated = false, frameWidth = 0, frameHeight = 0, unique = false, ?key:String):FlxSprite
	{
		throw "Cannot call loadGraphic() on editor.Checkbox";
	}
}
