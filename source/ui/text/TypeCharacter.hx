package ui.text;

class TypeCharacter extends FlxSprite
{
	private static final charMap:Map<String, String> = [
		'`' => 'backtick', '-' => 'dash', '_' => 'bottomdash', ',' => 'comma', '.' => 'period', '=' => 'equal', '+' => 'plus', '!' => 'exclamation',
		'?' => 'question', '/' => 'slash', '\'' => 'quote', '\"' => 'twoquote', ':' => 'colon', ';' => 'semicolon', '@' => 'at', '#' => 'tag',
		'$' => 'dollar', '%' => 'percent', '^' => 'caret', '&' => 'and', '*' => 'star', '(' => 'lbracket', ')' => 'rbracket', '[' => 'sqbracket',
		']' => 'sqrbracket', '{' => 'advlbracket', '}' => 'advrbracket'
	];

	// affects characters after it
	private static var paddingOffset:Map<String, FlxPoint> = [
		'M' => FlxPoint.get(-2),
		'W' => FlxPoint.get(-2),
		'm' => FlxPoint.get(-2),
		'o' => FlxPoint.get(-2),
		'q' => FlxPoint.get(2),
		'w' => FlxPoint.get(-2),
		'*' => FlxPoint.get(-4),
		'{' => FlxPoint.get(-4)
	];

	// only affects itself
	private static var glyphOffset:Map<String, FlxPoint> = [
		'i' => FlxPoint.get(0, 2),
		'j' => FlxPoint.get(0, 2),
		'p' => FlxPoint.get(0, -4),
		'q' => FlxPoint.get(0, -4),
		'y' => FlxPoint.get(0, -4),
		'!' => FlxPoint.get(0, 2),
		',' => FlxPoint.get(-1, -2),
		':' => FlxPoint.get(0, -2)
	];

	// only affects itself
	private function offsetWithCombination():Void
	{
		switch ([char, parent._nextChar])
		{
			case ['a', 'p']:
				parent._startPos.subtract(2);
			default:
		}
		/*switch ([parent._lastChar, char])
			{
				case ['a', 'p']:
					parent._startPos.add(2);
				default:
		}*/
	}

	private var _lockedPos:FlxPoint;

	public var nextOffset:Int = 0;

	public var char:String = "";
	public var parent:TypeText;

	public var localDelay:Float = 0.0;
	public var useLocalDelay:Bool = false;

	public var wipeLastChars:Bool = false;

	override public function new(parent:TypeText, font:String = "dtm", char:String)
	{
		super();

		active = false;
		moves = false;

		this.parent = parent;

		this.char = char;

		localDelay = parent.delay;

		var lowercase:String = char.toLowerCase();

		if (charMap.exists(char))
			loadGraphic(Assets.image('ui/text/$font/special_${charMap.get(char)}'));
		else if (char != lowercase)
			loadGraphic(Assets.image('ui/text/$font/capital_${char}'));
		else if (char == lowercase)
			loadGraphic(Assets.image('ui/text/$font/lower_${char.toLowerCase()}'));

		setPosition(parent._startPos.x, parent._startPos.y);
		getPosition().copyTo(_lockedPos);

		if (glyphOffset.exists(char))
			offset.copyFrom(glyphOffset.get(char));

		parent._startPos.x += width + parent.defaultGap;
		if (paddingOffset.exists(char))
			parent._startPos.add(paddingOffset.get(char).x, paddingOffset.get(char).y);
		offsetWithCombination();
	}
}