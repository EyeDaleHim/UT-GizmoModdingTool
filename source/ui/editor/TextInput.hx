package ui.editor;

import openfl.ui.Keyboard;
import states.editors.AnimationEditorState;

class TextInput extends FlxSprite
{
	public var length(get, never):Int;

	public var back:FlxSprite;
	public var textObject:FlxText;

	public var selected:Bool = false;

	public var actualText:String = "";

	public var onChange:String->Void;

	override public function new(?X:Float = 0, ?Y:Float = 0, Width:Int = 110, Size:Int = 14, DefaultText:String)
	{
		super(X, Y);

		actualText = DefaultText;

		textObject = new FlxText(X, Y, 0, DefaultText, Size);
		textObject.setFormat(null, Size);
		textObject.font = Assets.font("editor").fontName;
		textObject.antialiasing = true;
		textObject.color = AnimationEditorState.mainTextColor;

		makeGraphic(Width, (textObject.height + 4).floor(), 0xFFFFFFFF);
		color = 0xFF3B3B3B;

		back = new FlxSprite(x, y).makeGraphic(width.floor(), height.floor(), 0xFF1B1B1B);

		pixels.lock();
		pixels.fillRect(new Rectangle(0, 0, width, height - 1), 0);
		pixels.unlock();
	}

	public function changeText(NewText:String)
	{
		actualText = NewText;
		textObject.text = actualText;
		/*if (_caretShown)
			{
				textObject.text += "|";
		}*/
	}

	private var _caretShown:Bool = false;
	private var _caretTimer:Float = 1.2;
	private var _caretPosition:Int = 0;

	private var _backspaceTime:Float = 0.0;

	override public function update(elapsed:Float)
	{
		if (selected)
		{
			if (FlxKey.toStringMap.exists(FlxG.keys.firstJustPressed()))
			{
				var key:Int = FlxG.keys.firstJustPressed();

				if (key == 16 || key == 17 || key == 220 || key == 27) // Default keys, ignore
				{
				}
				else if (key == 8) // Backspace
				{
					actualText = actualText.substring(0, actualText.length - 1);
					if (onChange != null)
						onChange(actualText);
				}
				else if (key == 13) // Enter
				{
					selected = false;
					color = 0xFF3B3B3B;
					if (onChange != null)
						onChange(actualText);
				}
				else
				{
					var newText:String = filterChar(key);
					if (newText.length > 0)
					{
						actualText += newText;
					}

					if (onChange != null)
						onChange(actualText);
				}
				textObject.text = actualText;
			}
		}

		if (FlxG.mouse.pressed)
		{
			selected = FlxG.mouse.overlaps(this, camera);
			if (selected)
				color = 0xFFFFFFFF;
			else
				color = 0xFF3B3B3B;
		}
		else if (FlxG.mouse.pressedRight && !FlxG.mouse.overlaps(this, camera))
			selected = false;

		FlxG.sound.soundTrayEnabled = !selected;

		/*_caretTimer -= elapsed;
			if (_caretTimer <= 0.0)
			{
				_caretTimer = 1.2;
				_caretShown = !_caretShown;
			}

			if (_caretShown)
			{

			}
			else
			{
				
		}*/

		super.update(elapsed);
	}

	public override function draw()
	{
		back.draw();
		super.draw();
		textObject.draw();
	}

	private function filterChar(key:FlxKey):String
	{
		var text:String = "";

		if (FlxG.keys.pressed.SHIFT)
		{
			switch (key)
			{
				case MINUS:
					return "_";
				case SLASH:
					return "/";
				case SPACE:
					return " ";
				default:
					text = InputUtils.format(key).toUpperCase();
			}
		}
		else
		{
			switch (key)
			{
				case MINUS:
					return "-";
				case SLASH:
					return "/";
				case SPACE:
					return " ";
				default:
					text = InputUtils.format(key).toLowerCase();
			}
		}

		var alphaNumericFilter:EReg = ~/[^a-zA-Z0-9]*/g;
		text = alphaNumericFilter.replace(text, "");
		return text;
	}

	function get_length():Int
	{
		return actualText.length;
	}

	override function set_camera(Value:FlxCamera):FlxCamera
	{
		if (_cameras == null)
			_cameras = [Value];
		else
			_cameras[0] = Value;

		if (back != null)
			back.camera = Value;

		if (textObject != null)
			textObject.camera = Value;

		return Value;
	}
}
