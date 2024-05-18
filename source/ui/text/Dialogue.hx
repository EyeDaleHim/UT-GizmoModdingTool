package ui.text;

import ui.text.Textbox;
import ui.text.TypeText;

class Dialogue extends FlxGroup
{
	public var textBox:BoxSprite;
	public var typeText:TypeText;

	public var dialogue:Array<DialogueData> = [];

	override public function new(?x:Float = 0.0, ?y:Float = 0.0, dialogue:Array<DialogueData>)
	{
		super();

		this.dialogue = dialogue;

		textBox = new BoxSprite(x, y, 578, 152, 6);
		add(textBox);

		typeText = new TypeText(textBox.x + 6 + 22, textBox.y + 6 + 22, dialogue.shift());
		add(typeText);
	}

	public function screenCenter(axes:FlxAxes = XY)
	{
		if (axes.x)
		{
			if (textBox != null)
			{
				textBox.screenCenter(X);
				typeText.x = textBox.x + 6 + 22;
			}
			else
				typeText.screenCenter(X);
		}

		if (axes.y)
		{
			if (textBox != null)
			{
				textBox.screenCenter(Y);
				typeText.y = textBox.y + 6 + 22;
			}
			else
				typeText.screenCenter(Y);
		}
	}

	override public function update(elapsed:Float)
	{
		if (Controls.getControl(back).justReleased() && !typeText.finished)
			typeText.forceFinish();
		else if (Controls.getControl(accept).justPressed() && typeText.finished)
		{
			if (dialogue.length == 0)
				kill();
			else
			{
				var dialog:DialogueData = dialogue.shift();

				typeText.resetRawText(dialog.content);
				typeText.formatText(dialog.attributes);
			}
		}

		super.update(elapsed);
	}
}

typedef DialogueData =
{
	var speaker:String;
	var content:String;
	@:optional var attributes:Array<DialogueAttributes>;
};

typedef DialogueAttributes =
{
	@:optional var startIndex:Int;
	@:optional var endIndex:Int;

	@:optional var startIndexString:String;
	@:optional var endIndexString:String;

	var name:String;
	@:optional var data:Array<Dynamic>;
}
