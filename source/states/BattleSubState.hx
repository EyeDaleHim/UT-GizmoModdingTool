package states;

class BattleSubState extends FlxSubState
{
	static final buttonList:Array<String> = ['fight', 'act', 'item', 'mercy'];

	// sprites
	public var buttons:Array<BattleButton> = [];
	public var soul:Soul;

	public var music:FlxSound;

	private var _fadeOutSpr:FlxSprite;

	override public function new(soul:Soul)
	{
		super(0xFF000000);

		music = FlxG.sound.list.recycle(FlxSound.new);
		music.loadEmbedded(Assets.sound('battle/enemy_approach', 'music'), true);
		music.volume = 0.4;
		FlxG.sound.list.add(music);

		for (i in 0...buttonList.length)
		{
			var button = buttonList[i];

			var buttonSpr:BattleButton = new BattleButton(32 + (153 * i), 432, button);

			if (i > 1)
			{
				buttonSpr.x += 7;
				if (i >= 3)
					buttonSpr.x += 2;
			}
			buttonSpr.ID = i;
			buttonSpr.active = false;

			buttons.push(buttonSpr);
			add(buttonSpr);
		}

		this.soul = soul;
		add(soul);

		_fadeOutSpr = new FlxSprite().makeGraphic(2, 2, 0xFF000000);
		_fadeOutSpr.scale.set(FlxG.width, FlxG.height);
		_fadeOutSpr.camera = PlayState.instance.battleCamera;
		_fadeOutSpr.kill();

		camera = PlayState.instance.battleCamera;
	}

	public var selectIndex:Int = 0;

	public override function update(elapsed:Float)
	{
		if (Controls.getControl(left_move).justPressed())
			changeSelect(-1);
		else if (Controls.getControl(right_move).justPressed())
			changeSelect(1);

		super.update(elapsed);
	}

	public function changeSelect(change:Int = 0)
	{
		if (change != 0)
		{
			FlxG.sound.play(Assets.sound("menu/select", "sfx"), 0.7);

			selectIndex = FlxMath.wrap(selectIndex + change, 0, buttons.length - 1);
		}

		for (button in buttons)
		{
			if (button.ID == selectIndex)
				button.selected = true;
			else
				button.selected = false;
		}

		if (buttons[selectIndex] != null)
			soul.setPosition(buttons[selectIndex].x + 8, buttons[selectIndex].y + 14);
	}

	public function start():Void
	{
		_fadeOutSpr.revive();

		FlxTween.num(1.0, 0.0, 0.25, {
			onComplete: function(twn:FlxTween)
			{
				_fadeOutSpr.kill();
			}
		}, function(value:Float)
		{
			_fadeOutSpr.alpha = value;
		});

		this.music.play();

		changeSelect();
	}

	override public function draw()
	{
		super.draw();

		if (_fadeOutSpr.exists)
		{
			_fadeOutSpr.draw();
			soul.draw();
		}
	}
}
