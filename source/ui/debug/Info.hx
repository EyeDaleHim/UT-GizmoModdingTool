package ui.debug;

import macros.Version;
import openfl.display.StageAlign;
import openfl.events.Event;
import openfl.text.TextFormat;
import openfl.text.TextField;

class Info extends TextField
{
	static final updateTimer:Int = 200;

	public var curFPS:Int = 0;

	public var align(default, set):StageAlign;

	private var _timer:Float = 0;
	private var _lastTick:Int = 0;
	private var _wrongFrames:Int = 0;

	override public function new(?x:Float = 0.0, ?y:Float = 0.0)
	{
		super();

		this.x = x;
		this.y = y;

		defaultTextFormat = new TextFormat(Assets.font("fps").fontName, 12, 0xFFFFFF);
	
		autoSize = LEFT;

		antiAliasType = ADVANCED;
		sharpness = 400;

		addEventListener(Event.ENTER_FRAME, enterFrame);
	}

	function enterFrame(e:Event)
	{
		var delta:Int = openfl.Lib.getTimer() - _lastTick;
		var convert:Float = delta / 1000;

		_lastTick = openfl.Lib.getTimer();

		_timer += delta;

		if (_timer > updateTimer)
		{
			var fps:Int = (1 / convert).floor();
			fps = fps.min(FlxG.drawFramerate).floor();

			if (_wrongFrames == 4)
			{
				text = 'FPS: $fps - ${Version.getGitCommitHash()}';
				_timer -= updateTimer;

				curFPS = fps;

				_wrongFrames = 0;
			}
			else if (fps != curFPS)
			{
				_wrongFrames++;
			}
			else
				_wrongFrames = 0;
		}

		align = align;
	}

	function set_align(newAlign:StageAlign):StageAlign
	{
		switch (newAlign)
		{
			case TOP_LEFT:
				x = 1;
				y = 1;
			case TOP_RIGHT:
				x = FlxG.stage.window.width - (width + 1);
				y = 12;
			case BOTTOM_RIGHT:
				x = FlxG.stage.window.width - (width + 1);
				y = FlxG.stage.window.height - (height + 1);
			default:
				return set_align(TOP_LEFT);
		}

		return (align = newAlign);
	}
}
