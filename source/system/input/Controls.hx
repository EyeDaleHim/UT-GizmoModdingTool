package system.input;

import flixel.input.FlxInput.FlxInputState;

@:allow(Main)
class Controls
{
	private static var _emptyControl:Control = new Control(none, "", NONE, NONE);

	public static var schemeOrder:Array<KeyShortcut> = [up_move, left_move, down_move, right_move, sprint, accept, back];

	private static final _defaultScheme:Map<KeyShortcut, Control> = [
		up_move => new Control(up_move, "UP", FlxKey.W, FlxKey.UP),
		left_move => new Control(left_move, "LEFT", FlxKey.A, FlxKey.LEFT),
		down_move => new Control(down_move, "DOWN", FlxKey.S, FlxKey.DOWN),
		right_move => new Control(right_move, "RIGHT", FlxKey.D, FlxKey.RIGHT),
		sprint => new Control(sprint, "SPRINT", FlxKey.SHIFT, FlxKey.X),
		accept => new Control(accept, "ACCEPT", FlxKey.Z, FlxKey.ENTER),
		back => new Control(back, "BACK", FlxKey.X, FlxKey.BACKSPACE)
	];

	private static var _scheme:Map<KeyShortcut, Control> = [];

	private static var _save:FlxSave;

	public static function save():Bool
	{
		if (_save.isEmpty())
			load();

		_save.data.scheme = _scheme;

		return _save.flush();
	}

	public static function checkList(names:Array<KeyShortcut>, state:FlxInputState):Bool
	{
		for (name in names)
		{
			switch (state)
			{
				case JUST_PRESSED:
					if (Controls.getControl(name).justPressed())
						return true;
				case PRESSED:
					if (Controls.getControl(name).pressed())
						return true;
				case JUST_RELEASED:
					if (Controls.getControl(name).justReleased())
						return true;
				case RELEASED:
					if (Controls.getControl(name).released())
						return true;
			}
		}

		return false;
	}

	public static function getControl(key:KeyShortcut):Control
	{
		if (_scheme.exists(key))
			return _scheme.get(key);
		FlxG.log.warn("Control not recognized!");
		return _emptyControl;
	}

	public static function setControl(name:KeyShortcut, key:FlxKey, alt:Bool = false)
	{
		if (_scheme.exists(name))
		{
			if (!alt)
				_scheme.get(name).mainKey = key;
			else
				_scheme.get(name).altKey = key;
		}
		else
			FlxG.log.warn('Could not save Control $name to scheme');
	}

	public static function load():Void
	{
		_save.bind("controls", "underfell");

		if (_save.data.scheme != null)
			_scheme = _save.data.scheme;
		else
		{
			trace("Scheme is default!");
			_scheme = _defaultScheme;
		}
	}

	public static function reset():Void
	{
		_save.erase();

		_scheme = _defaultScheme;
	}
}

class Control
{
	public var name:KeyShortcut;
	public var display:String;

	public var mainKey:FlxKey = NONE;
	public var altKey:FlxKey = NONE;

	public function new(name:KeyShortcut, display:String, mainKey:FlxKey = NONE, ?altKey:FlxKey = null)
	{
		this.name = name;
		this.display = display;

		this.mainKey = mainKey;
		if (altKey != null)
			this.altKey = altKey;
	}

	public function pressed():Bool
		return FlxG.keys.checkStatus(mainKey, PRESSED) || FlxG.keys.checkStatus(altKey, PRESSED);

	public function justPressed():Bool
		return FlxG.keys.checkStatus(mainKey, JUST_PRESSED) || FlxG.keys.checkStatus(altKey, JUST_PRESSED);

	public function released():Bool
		return FlxG.keys.checkStatus(mainKey, RELEASED) || FlxG.keys.checkStatus(altKey, RELEASED);

	public function justReleased():Bool
		return FlxG.keys.checkStatus(mainKey, JUST_RELEASED) || FlxG.keys.checkStatus(altKey, JUST_RELEASED);
}

enum abstract KeyShortcut(String)
{
	var up_move;
	var left_move;
	var down_move;
	var right_move;

	var sprint;
	var accept;
	var back;

	var none;
}
