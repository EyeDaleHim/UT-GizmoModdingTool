package ui.editor;

import openfl.geom.Rectangle;
import states.editors.AnimationEditorState;

class Stepper extends FlxSprite
{
	public static final NORMAL:Int = 0;
	public static final HIGHLIGHT:Int = 1;
	public static final PRESS:Int = 2;

	public var getValue:Void->Float = null;
	public var setValue:Float->Void = null;

	public var value:Float = 0.0;

	public var displayString:String = "";

	public var status:Int = NORMAL;

	public var buttonColor:FlxColor = 0xFF222529;
	public var hoverColor:FlxColor = 0xFF777E85;
	public var pressColor:FlxColor = 0xFF101113;

	public var bounds:FlxBounds<Float>;

	// sprites
	public var decrementButton:Button;
	public var incrementButton:Button;

	public var displayText:FlxText;

	public override function new(?x:Float = 0.0, ?y:Float = 0.0, ?width:Int = 80, ?bounds:FlxBounds<Float>, ?displayString:String = "", ?getValue:Void->Float,
			?setValue:Float->Void)
	{
		super(x, y);

		this.getValue = getValue;
		this.setValue = setValue;

		this.bounds = bounds;

		this.displayString = displayString ?? "";

		makeGraphic(width, 22, 0);
		FlxSpriteUtil.drawRoundRect(this, 0, 0, width, 22, 8.0, 8.0, buttonColor);

		decrementButton = new Button(this.getRight() + 4, y, "-", 14);
		decrementButton.onClick = function()
		{
			var boundMin:Float = Math.NEGATIVE_INFINITY;
			var boundMax:Float = Math.POSITIVE_INFINITY;

			if (bounds != null)
			{
				boundMin = bounds.min;
				boundMax = bounds.max;
			}

			var trueValue:Float = value;

			if (getValue != null)
				trueValue = getValue();

			var output:Float = trueValue - 1;
			if (output <= boundMin)
				output = boundMin;

			value = output;
				
			if (setValue != null)
				setValue(output);

			displayText.text = '${value} $displayString';
			displayText.updateHitbox();

			displayText?.centerOverlay(this);
		};
		decrementButton.hold = true;
		FlxSpriteUtil.drawRoundRect(decrementButton, 0, 0, 22, 22, 8.0, 8.0, 0xFFFFFFFF);

		decrementButton.pixels.lock();
		decrementButton.pixels.fillRect(new Rectangle(decrementButton.width - 4, 0, 4, decrementButton.height), 0xFFFFFFFF);
		decrementButton.pixels.unlock();

		decrementButton.color = buttonColor;

		incrementButton = new Button(decrementButton.getRight() + 2, y, "+", 14);
		incrementButton.onClick = function()
		{
			var boundMin:Float = Math.NEGATIVE_INFINITY;
			var boundMax:Float = Math.POSITIVE_INFINITY;

			if (bounds != null)
			{
				boundMin = bounds.min;
				boundMax = bounds.max;
			}

			var trueValue:Float = value;

			if (getValue != null)
				trueValue = getValue();

			var output:Float = trueValue + 1;
			if (output >= boundMax)
				output = boundMax;

			value = output;
				
			if (setValue != null)
				setValue(output);

			displayText.text = '${value} $displayString';
			displayText.updateHitbox();

			displayText?.centerOverlay(this);
		};
		incrementButton.hold = true;
		FlxSpriteUtil.drawRoundRect(incrementButton, 0, 0, 22, 22, 8.0, 8.0, 0xFFFFFFFF);

		incrementButton.pixels.lock();
		incrementButton.pixels.fillRect(new Rectangle(0, 0, 4, decrementButton.height), 0xFFFFFFFF);
		incrementButton.pixels.unlock();

		incrementButton.color = buttonColor;

		var trueValue:Float = value;

		if (getValue != null)
			trueValue = getValue();

		displayText = new FlxText(x, y, 0, '${trueValue} $displayString');
		displayText.setFormat(null, 56);
		displayText.font = Assets.font("editor").fontName;
		displayText.scale.set(0.25, 0.25);
		displayText.updateHitbox();
		displayText.antialiasing = true;
		displayText.color = AnimationEditorState.mainTextColor;

		displayText.centerOverlay(this);
	}

	public function updateValue():Void
	{
		if (getValue != null)
			displayText.text = '${getValue()} $displayString';	
		else
			displayText.text = '$value $displayString';

		displayText.updateHitbox();
		displayText?.centerOverlay(this);
	}

	private var _hovered:Bool = false;

	public override function update(elapsed:Float)
	{
		displayText?.centerOverlay(this);

		if (decrementButton.exists && decrementButton.active)
			decrementButton.update(elapsed);

		if (incrementButton.exists && incrementButton.active)
			incrementButton.update(elapsed);

		super.update(elapsed);
	}

	public override function draw()
	{
		super.draw();

		decrementButton.draw();
		incrementButton.draw();

		displayText.draw();
	}

	override function set_camera(Value:FlxCamera):FlxCamera
	{
		if (_cameras == null)
			_cameras = [Value];
		else
			_cameras[0] = Value;

		if (displayText != null)
			displayText.camera = Value;

		if (decrementButton != null)
			decrementButton.camera = Value;
		if (incrementButton != null)
			incrementButton.camera = Value;

		return Value;
	}

	override public function loadGraphic(graphic:FlxGraphicAsset, animated = false, frameWidth = 0, frameHeight = 0, unique = false, ?key:String):FlxSprite
	{
		throw "Cannot call loadGraphic() on editor.Stepper";
	}
}
