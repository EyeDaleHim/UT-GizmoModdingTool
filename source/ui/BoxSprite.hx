package ui;

// idk how inefficient this is, i just dont like flxslicesprite due to its bad documentation
class BoxSprite extends FlxSprite
{
	public static final LEFT:Int = 0;
	public static final TOP:Int = 1;
	public static final BOT:Int = 2;
	public static final RIGHT:Int = 3;

	public var borderColor(default, set):FlxColor = 0xFFFFFFFF;
	public var bgColor(default, set):FlxColor = 0xFF000000;
	public var borderSize:Int = 6;

	public var list:Array<FlxSprite> = [];

	public override function new(?x:Float, ?y:Float, width:Int, height:Int, borderSize:Int)
	{
		var left:FlxSprite = new FlxSprite().makeGraphic(borderSize, borderSize, borderColor, true);
		left.active = false;
		left.setGraphicSize(borderSize, height);
		left.updateHitbox();
		list[LEFT] = left;

		var top:FlxSprite = new FlxSprite().makeGraphic(borderSize, borderSize, borderColor, true);
		top.active = false;
		top.setGraphicSize(width, borderSize);
		top.updateHitbox();
		list[TOP] = top;

		var bot:FlxSprite = new FlxSprite().makeGraphic(borderSize, borderSize, borderColor, true);
		bot.active = false;
		bot.setGraphicSize(width, borderSize);
		bot.updateHitbox();
		list[BOT] = bot;

		var right:FlxSprite = new FlxSprite().makeGraphic(borderSize, borderSize, borderColor, true);
		right.active = false;
		right.setGraphicSize(borderSize, (height + borderSize).floor());
		right.updateHitbox();
		list[RIGHT] = right;

		super(x, y);
		makeGraphic(width, height, 0xFF000000);
	}

	function set_bgColor(color:FlxColor):FlxColor
	{
		this.color = color;

		return (bgColor = color);
	}

	function set_borderColor(color:FlxColor):FlxColor
	{
		list[LEFT].color = list[BOT].color = list[TOP].color = list[RIGHT].color = color;

		return (borderColor = color);
	}

	override function set_x(Value:Float):Float
	{
		list[LEFT].x = list[TOP].x = list[BOT].x = Value;
		list[RIGHT].x = list[TOP].getRight();

		return (x = Value);
	}

	override function set_y(Value:Float):Float
	{
		list[LEFT].y = list[TOP].y = list[RIGHT].y = Value;
		list[BOT].y = list[LEFT].getBottom();

		return (y = Value);
	}

	override public function draw():Void
	{
		super.draw();

		list[LEFT].draw();
		list[BOT].draw();
		list[TOP].draw();
		list[RIGHT].draw();
	}
}
