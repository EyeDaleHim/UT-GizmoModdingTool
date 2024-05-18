package ui.text;

@:allow(ui.text.TypeCharacter)
class TypeText extends FlxTypedGroup<TypeCharacter>
{
	static final defaultIgnores:Array<String> = ['*', '(', ')', ',', '.'];

	public var x(default, set):Float = 0.0;
	public var y(default, set):Float = 0.0;

	public var width(default, null):Float = 0.0;
	public var height(default, null):Float = 0.0;

	public var defaultGap:Int = 4;

	public var delay:Float = 0.04;
	public var charsToType:Int = 1;
	public var sounds:Array<FlxSound> = [];

	public var text:String = "";

	public var characters:Array<TypeCharacter> = [];

	public var finished:Bool = false;

	public var ignoreTypeSound:Array<String> = defaultIgnores.copy();

	public var typeCallback:Void->String;
	public var endCallback:Void->String;

	private var _soundList:Array<String> = [];

	function set_x(Value:Float):Float
	{
		for (member in members)
		{
			member.x += Value - x;
		}

		return (x = Value);
	}

	function set_y(Value:Float):Float
	{
		for (member in members)
		{
			member.y += Value - y;
		}

		return (y = Value);
	}

	public override function new(?x:Float = 0, ?y:Float = 0, defaultGap:Int = 4, dialog:DialogueData, activate:Bool = false)
	{
		super();

		this.x = x;
		this.y = y;

		this.defaultGap = defaultGap;

		_startPos = FlxPoint.get(x, y);

		resetRawText(dialog.content);
		formatText(dialog.attributes);

		for (member in members)
		{
			width = Math.max(width, member.x + member.width);
			height = Math.max(height, member.y + member.height);
		}

		width -= x;
		height -= y;

		_activated = activate;
	}

	var _time:Float = 0.0;
	var _index:Int = 0;
	var _len:Int = 0;

	public override function update(elapsed:Float)
	{
		if (_activated && !finished)
		{
			var actualDelay:Float = delay;

			if (members[_index]?.useLocalDelay)
				actualDelay = members[_index].localDelay;

			if (members[_index]?.wipeLastChars)
				resetRawText(text.substr(_index));

			_time += elapsed;

			while (_time > actualDelay)
			{
				if (_index >= _len)
				{
					finished = true;
					if (endCallback != null)
					{
						endCallback();
					}
					break;
				}

				members[_index].exists = true;

				if (typeCallback != null)
					typeCallback();

				if (!ignoreTypeSound.contains(members[_index].char))
				{
					if (sounds.length == 1)
					{
						sounds[0].play(true);
					}
					else if (sounds.length > 1)
					{
						var random:Int = FlxG.random.int(0, sounds.length);
						for (i in 0...sounds.length)
						{
							var sound = sounds[i];

							if (i == random)
								sound.play(true);
							else
								sound.stop();
						}
					}
				}

				_time -= actualDelay;

				_index++;
			}
		}

		super.update(elapsed);
	}

	public function screenCenter(axes:FlxAxes = XY)
	{
		if (axes.x)
			x = (FlxG.width - width) / 2;

		if (axes.y)
			y = (FlxG.height - height) / 2;
	}

	// delay - how many seconds should each char display
	// charsToType - how many chars to type for every 'delay' seconds
	// sounds - what sounds to play for every char
	public function startTyping(?delay:Float = 0.04, ?charsToType:Int = 1, sounds:Array<String>, ?typeCallback:Void->String, ?endCallback:Void->String):Void
	{
		_activated = true;

		this.delay = delay;
		this.charsToType = charsToType;

		if (sounds.length > 0)
		{
			for (sound in this.sounds.splice(0, this.sounds.length))
			{
				sound.kill();
			}

			for (sound in sounds)
			{
				if (FileSystem.exists(Assets.sfxPath('dialogue/$sound.ogg')))
				{
					var soundObj:FlxSound = FlxG.sound.list.recycle(FlxSound.new);
					soundObj.loadEmbedded(Assets.sound('dialogue/$sound.ogg', 'sfx'));
					FlxG.sound.list.add(soundObj);
					this.sounds.push(soundObj);
				}
			}
		}

		this.typeCallback = typeCallback;
		this.endCallback = endCallback;
	}

	public function forceFinish():Void
	{
		for (i in _index...members.length)
		{
			_index = members.length - 1;

			finished = true;

			if (members[i] != null)
				members[i].exists = true;
			if (endCallback != null)
				endCallback();
		}
	}

	public function resetRawText(newText:String)
	{
		finished = false;

		_len = 0;
		_index = 0;

		this.text = newText;

		_startPos.set(x, y);

		for (member in members)
			member.destroy();
		clear();

		characters = [];

		var i:Int = 0;
		while (i < newText.length)
		{
			var char:String = newText.charAt(i);

			switch (char)
			{
				case " ":
					_startPos.x += 16;
					characters.push(null);
				case "\t":
					_startPos.x += 24;
					characters.push(null);
				case "\n":
					if (members[0].char != '*')
						_startPos.x = members[0].x;
					else
						_startPos.x = members[1].x;
					_startPos.y += 36;
					characters.push(null);
				default:
					var typeChar:TypeCharacter = new TypeCharacter(this, "dtm", char);
					typeChar.exists = false;
					if (i == 0 && char == '*')
						typeChar.exists = true;
					add(typeChar);
					characters.push(typeChar);

					_lastChar = char;

					_len++;
			}
			i++;
		}

		_lastChar = null;
		_nextChar = null;
	}

	public function formatText(attributeList:Array<DialogueAttributes>)
	{
		if (attributeList == null)
			return;

		for (i in 0...attributeList.length)
		{
			var attributes:DialogueAttributes = attributeList[i];

			switch (attributes.name)
			{
				case "color":
					{
						for (i in (attributes.startIndex - 1)...attributes.endIndex)
						{
							if (characters[i] != null)
								characters[i].color = attributes.data[0];
						}
					}
				case "delay":
					{
						var trueStartIndex:Int = attributes.startIndex;
						if (attributes.startIndexString != null)
							trueStartIndex = text.indexOf(attributes.startIndexString);
						if (attributes.endIndex == null)
						{
							if (characters[trueStartIndex] != null)
							{
								characters[trueStartIndex].useLocalDelay = true;
								characters[trueStartIndex].localDelay = attributes.data[0];
							}
						}
						else
						{
							for (i in (attributes.startIndex - 1)...attributes.endIndex)
							{
								if (characters[i] != null)
								{
									characters[i].useLocalDelay = true;
									characters[i].localDelay = attributes.data[0];
								}
							}
						}
					}
				case "wipe":
				{
					if (characters[attributes.startIndex] != null)
						characters[attributes.startIndex].wipeLastChars = true;
				}
			}
		}
	}

	private var _activated:Bool = false;

	private var _lastChar:String;
	private var _nextChar:String;

	private var _startPos:FlxPoint;
}
