package states;

class IntroState extends MainState
{
	static final narrationList:Array<DialogueData> = [
		{
			content: "",
			speaker: ""
		},
		null
	];

	private var _narrationIndex:Int = 0;

	private var _time:Float = 0.0;

	public var typeText:TypeText;
	public var imageBox:FlxSprite;

	override public function create()
	{
		typeText = new TypeText(0, 340, 6, narrationList[_narrationIndex], false);
		typeText.screenCenter(X);
		typeText.startTyping(0.10, 1, ["normal-loud"]);
        typeText.ignoreTypeSound.splice(0, 30);
		add(typeText);

		imageBox = new FlxSprite().makeGraphic(400, 215, FlxColor.BLUE);
		imageBox.screenCenter();
		imageBox.y -= 70;
		add(imageBox);

		typeText.x = imageBox.x;
		typeText.y = imageBox.getBottom() + 50;

		super.create();
	}

	override public function update(elapsed:Float)
	{
		_time += elapsed;

		if (Controls.getControl(accept).justPressed())
		{
			proceed();
		}

		super.update(elapsed);
	}

	public function fadeIn(?endCallback:Void->Void):Void
	{
		FlxTween.num(0, 1.0, 0.7, {
			onComplete: function(twn:FlxTween)
			{
				if (endCallback != null)
					endCallback();
			}
		}, function(v:Float)
		{
            if (MainState._illusionFrames == 0)
                imageBox.alpha = v;
		});
	}

	public function fadeOut(?endCallback:Void->Void):Void
	{
		FlxTween.num(1.0, 0.0, 0.7, {
			onComplete: function(twn:FlxTween)
			{
				if (endCallback != null)
					endCallback();
			}
		}, function(v:Float)
		{
            if (MainState._illusionFrames == 0)
                imageBox.alpha = v;
		});
	}

	public function proceed():Void
	{
		if (typeText.finished)
		{
			trace(_time);

			if (narrationList[++_narrationIndex] == null)
			{
				if (_narrationIndex > narrationList.length - 1)
					FlxG.switchState(new PlayState());
				else
				{
					fadeOut(fadeIn.bind(proceed));
				}
			}
			else
			{
				typeText.resetRawText(narrationList[_narrationIndex].content);
				typeText.formatText(narrationList[_narrationIndex].attributes);

				typeText.startTyping(0.10, 1, []);
			}
		}
	}
}
