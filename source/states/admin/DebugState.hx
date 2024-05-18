package states.admin;

class DebugState extends MainState
{
	private static final name:Array<String> = ["Control State", "Animation Editor", "Room Editor"];

	private static final states:Array<Void->Void> = [
		function()
		{
			FlxG.switchState(new states.admin.ControlsState());
		},
		function()
		{
			FlxG.switchState(new states.editors.AnimationEditorState());
		},
		function()
		{
			FlxG.switchState(new states.editors.RoomEditorState());
		}
	];

	private static var selected:Int = 0;

	private static var textGroup:FlxTypedGroup<FlxText>;

	override function create()
	{
		textGroup = new FlxTypedGroup<FlxText>();
		add(textGroup);

		for (i in 0...states.length)
		{
			var newText:FlxText = new FlxText(60, 60 + 32 * i, 0, name[i], 16);
			newText.ID = i;
			textGroup.add(newText);
		}

		changeSelect();

		super.create();
	}

	override function update(elapsed:Float)
	{
		if (FlxG.keys.justPressed.ENTER)
		{
			if (states[selected] != null)
				states[selected]();
		}
		else
		{
			if (FlxG.keys.justPressed.W)
				changeSelect(-1);
			else if (FlxG.keys.justPressed.S)
				changeSelect(1);
		}
	}

	public function changeSelect(diff:Int = 0)
	{
		selected = FlxMath.wrap(selected + diff, 0, textGroup.length - 1);

		for (text in textGroup)
		{
			if (text.ID == selected)
				text.color = FlxColor.YELLOW;
			else
				text.color = FlxColor.WHITE;
		}
	}
}
