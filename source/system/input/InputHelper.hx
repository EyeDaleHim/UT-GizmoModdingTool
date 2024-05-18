package system.input;

class InputHelper
{
	private static final _keyInfo:Array<KeyInfo> = [];
	private static final _activeKeys:Array<Int> = [];

	private static var _lastTick:Float = 0.0;

	private static var loaded:Bool = false;

	public static function load():Void
	{
		if (loaded)
			return;

		loaded = true;

		FlxG.signals.postUpdate.add(function()
		{
			for (key in _activeKeys)
			{
				if (FlxG.keys.checkStatus(key, RELEASED))
				{
					if (_keyInfo[key] != null)
					{
						if (!_keyInfo[key]?.hadLooped)
							_keyInfo[key].action();
						_activeKeys.splice(_activeKeys[key], 1);
						_keyInfo[key] = null;
					}
				}
			}
		});

		FlxG.signals.postUpdate.add(function()
		{
			var elapsed:Float = (FlxG.game.ticks - _lastTick) * 0.001;

			for (key in _activeKeys)
			{
				var origKey:KeyInfo = _keyInfo[key];

				if (origKey != null)
				{
					origKey.time -= elapsed;

					if (origKey.time <= 0.0)
					{
						if (origKey.action != null)
							origKey.action();
						origKey.time = origKey.loopDelay;
						origKey.hadLooped = true;
					}
				}
			}

			_lastTick = FlxG.game.ticks;
		});
	}

	public static function addKey(key:FlxKey, action:Void->Void, startDelay:Float, loopDelay:Float)
	{
		if (![-1, -2].contains(key) && !_activeKeys.contains(key))
		{
			_keyInfo[key] = {
				action: action,
				time: startDelay,
				loopDelay: loopDelay,
				hadLooped: false
			};
			_activeKeys.push(key);
		}
	}
}

typedef KeyInfo =
{
	var action:Void->Void;
	var loopDelay:Float;
	var time:Float;
	var hadLooped:Bool;
}