package ui.editor.animation;

import flixel.util.FlxArrayUtil;
import openfl.geom.Point;
import flixel.graphics.frames.FlxImageFrame;
import openfl.geom.Rectangle;

class Track extends FlxSprite
{
	public var tracker:FlxSprite;

	public var borderList:Array<BorderSprite> = [];
	public var frameList:Array<FrameSprite> = [];

	public static var emptyBorderBitmap:BitmapData; // odd frames
	public static var emptyBorderBitmap2:BitmapData; // even frames

	public var tileWidth:Int = 96;

	override public function new(?X:Float = 0, ?Y:Float = 0, tileWidth:Int = 96, height:Int = 28)
	{
		super(X, Y);

		makeGraphic(28, 28, 0);

		emptyBorderBitmap = new BitmapData(28, 28, true, 0xFF000000);
		emptyBorderBitmap2 = new BitmapData(28, 28, true, 0xFF000000);

		emptyBorderBitmap.lock();
		emptyBorderBitmap2.lock();

		emptyBorderBitmap.fillRect(new Rectangle(2, 2, 24, 24), 0xFFB2B7BD);
		emptyBorderBitmap2.fillRect(new Rectangle(2, 2, 24, 24), 0xFF8F979E);

		emptyBorderBitmap.unlock();
		emptyBorderBitmap2.unlock();

		for (i in 0...tileWidth + 1)
		{
			var tileBorder:BorderSprite = new BorderSprite(X + (26 * i), Y);
			tileBorder.darkTile = FlxMath.isEven(i);
			tileBorder.ID = i;
			tileBorder.tileX = i;
			tileBorder.active = false;
			borderList.push(tileBorder);
		}

		tracker = new FlxSprite().loadGraphic(Assets.image('_debug/frame_ui/pointer'));
		tracker.active = false;
		tracker.antialiasing = false;

		this.tileWidth = tileWidth;

		_firstRange = 0;
		_lastRange = tileWidth;

		updateList();
	}

	private var _firstRange:Int = 0;
	private var _lastRange:Int = 0;

	private var _endPoint(get, null):Int;

	function get__endPoint():Int
	{
		return (tileWidth - endRange);
	}

	public var startPoint(default, set):Int = 0;

	public var endRange:Int = 4;

	public function updateList():Void
	{
		if (startPoint > _lastRange)
			for (border in borderList)
				border.darkTile = !border.darkTile;

		for (frames in frameList)
		{
			if (frames.frameIndex < _firstRange || frames.frameIndex > _lastRange)
				frames.exists = false;
			else
				frames.exists = true;

			for (frame in frameList)
				frame.x = (borderList[frame.frameIndex - (_lastRange - tileWidth).max(0).floor()]).x + 2;
		}

		tracker.centerOverlay(borderList[(Math.min(startPoint, _endPoint)).floor()]);
		tracker.y -= borderList[(Math.min(startPoint, _endPoint)).floor()].height;
	}

	function set_startPoint(Value:Int):Int
	{
		if (startPoint != Value)
		{
			if (startPoint >= _endPoint)
			{
				if (Value > startPoint)
				{
					_firstRange++;
					_lastRange++;
				}
				else
				{
					_firstRange--;
					_lastRange--;
				}
			}
			_firstRange = Math.max(0, _firstRange).floor();
			_lastRange = Math.max(tileWidth, _lastRange).floor();
		}

		startPoint = Value;

		updateList();

		return Value;
	}

	public function addFrame(frame:FrameSprite, index:Int = -1)
	{
		if (index == -1)
			index = frameList.length;
		frameList.insert(index, frame);
		frame.camera = camera;

		updateList();
	}

	override public function draw()
	{
		for (border in borderList)
			border.draw();
		for (frame in frameList)
		{
			if (frame.exists && frame.visible)
				frame.draw();
		}

		tracker.draw();
	}

	override function set_x(Value:Float):Float
	{
		for (border in borderList)
			border.x = x + (26 * border.tileX);
		for (frame in frameList)
			frame.x = (borderList[(Math.max(frame.frameIndex - (_lastRange - tileWidth), 0)).floor()].x) + 2;

		return x = Value;
	}

	override function set_y(Value:Float):Float
	{
		for (border in borderList)
			border.y = y;
		for (frame in frameList)
			frame.y = y + 2;

		return y = Value;
	}

	override function set_camera(Value:FlxCamera):FlxCamera
	{
		if (_cameras == null)
			_cameras = [Value];
		else
			_cameras[0] = Value;

		for (border in borderList)
			border.camera = Value;
		for (frame in frameList)
			frame.camera = Value;
		tracker.camera = Value;

		return Value;
	}
}

class BorderSprite extends FlxSprite
{
	public var tileX:Int = 0;
	public var darkTile(default, set):Bool = false;

	function set_darkTile(Value:Bool):Bool
	{
		if (Value)
			loadGraphic(Track.emptyBorderBitmap2);
		else
			loadGraphic(Track.emptyBorderBitmap);
		return (darkTile = Value);
	}
}

class FrameSprite extends FlxSprite
{
	public static final bgColor:FlxColor = 0xFF262729;
	public var changeFrameSpr:FlxSprite;

	public var frameIndex:Int = 0;

	override public function new(?frameIndex:Int = 0)
	{
		changeFrameSpr = new FlxSprite(Assets.image("_debug/frame"));

		super();
		makeGraphic(24, 24, bgColor);

		this.frameIndex = frameIndex;
	}

	override function set_camera(Value:FlxCamera)
	{
		if (_cameras == null)
			_cameras = [Value];
		else
			_cameras[0] = Value;

		changeFrameSpr.camera = Value;
		return Value;
	}

	override function set_x(Value:Float):Float
	{
		if (changeFrameSpr != null)
			changeFrameSpr.x = (Value + width) - changeFrameSpr.width;
		return x = Value;
	}

	override function set_y(Value:Float):Float
	{
		if (changeFrameSpr != null)
			changeFrameSpr.y = Value;
		return y = Value;
	}

	override function draw()
	{
		super.draw();
		if (changeFrameSpr.exists && changeFrameSpr.visible)
			changeFrameSpr.draw();
	}

	override public function destroy()
	{
		super.destroy();
		changeFrameSpr?.destroy();
	}
}
