package states.admin;

class ControlsState extends MainState
{
	public static var selected:Int = 0;
	public static var onAltKeys:Bool = false;

	public var textDisplayGrp:FlxTypedGroup<FlxText>;

	public var mainKeyGrp:FlxTypedGroup<FlxText>;
	public var altKeyGrp:FlxTypedGroup<FlxText>;

	override function create()
	{
		textDisplayGrp = new FlxTypedGroup<FlxText>();
		textDisplayGrp.active = false;
		add(textDisplayGrp);

		mainKeyGrp = new FlxTypedGroup<FlxText>();
		mainKeyGrp.active = false;
		add(mainKeyGrp);

		altKeyGrp = new FlxTypedGroup<FlxText>();
		altKeyGrp.active = false;
		add(altKeyGrp);

		var i:Int = 0;
		for (displayList in Controls.schemeOrder)
		{
			var displayTxt:FlxText = new FlxText(20, 20 * i, 0, Controls.getControl(displayList).display, 8);
			textDisplayGrp.add(displayTxt);

			var mainTxt:FlxText = new FlxText(100, 20 * i, 0, Controls.getControl(displayList).mainKey.toString(), 8);
			mainKeyGrp.add(mainTxt);

			var altTxt:FlxText = new FlxText(180, 20 * i, 0, Controls.getControl(displayList).altKey.toString(), 8);
			altKeyGrp.add(altTxt);

			i++;
		}

        Assets.sound('menu/select', 'sfx');
        Assets.sound('menu/confirm', 'sfx');

		changeSelection();
	}

	public var listen:Bool = false;
	public var waitTime:Float = 0.0;

	override function update(elapsed:Float)
	{
		if (listen)
		{
            if (FlxG.keys.justPressed.ESCAPE)
            {
                listen = false;
            }
			else if (waitTime > 1.0)
			{
				if (FlxG.keys.firstJustReleased() != -1)
				{
					listen = false;

					Controls.setControl(Controls.getControl(Controls.schemeOrder[selected]).name, FlxG.keys.firstJustReleased(), onAltKeys);

					var key:String = (onAltKeys ? Controls.getControl(Controls.schemeOrder[selected])
						.altKey : Controls.getControl(Controls.schemeOrder[selected]).mainKey).toString();

					(onAltKeys ? altKeyGrp : mainKeyGrp).members[selected].text = key;

                    changeSelection();

                    Controls.save();
				}
			}
			else
				waitTime += elapsed;
		}
		else if (FlxG.keys.justPressed.ESCAPE)
			FlxG.switchState(new states.PlayState());
		else
		{
			if (FlxG.keys.justPressed.R)
			{
				Controls.reset();

				FlxG.resetState();
			}
			else if (Controls.getControl(accept).justPressed())
			{
				listen = true;
                waitTime = 0.0;

                FlxG.sound.play(Assets.sound('menu/confirm', 'sfx'), 0.7);
			}
			else if (Controls.getControl(left_move).justPressed() || Controls.getControl(right_move).justPressed())
			{
				onAltKeys = !onAltKeys;

                FlxG.sound.play(Assets.sound('menu/select', 'sfx'), 0.7);

				changeSelection();
			}
			else if (Controls.getControl(down_move).justPressed())
				changeSelection(1);
			else if (Controls.getControl(up_move).justPressed())
				changeSelection(-1);
		}

		super.update(elapsed);
	}

	public function changeSelection(change:Int = 0):Void
	{
        if (change != 0)
            FlxG.sound.play(Assets.sound('menu/select', 'sfx'), 0.7);

		var group:FlxTypedGroup<FlxText> = onAltKeys ? altKeyGrp : mainKeyGrp;
		var oppositeGrp:FlxTypedGroup<FlxText> = onAltKeys ? mainKeyGrp : altKeyGrp;

		oppositeGrp.members[selected].color = FlxColor.WHITE;
		group.members[selected].color = FlxColor.WHITE;

		selected = FlxMath.wrap(selected + change, 0, textDisplayGrp.length - 1);

		group.members[selected].color = FlxColor.YELLOW;
	}
}
