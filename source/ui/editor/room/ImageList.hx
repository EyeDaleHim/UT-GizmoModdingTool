package ui.editor.room;

import openfl.geom.Point;

class ImageList extends FlxSprite
{
	public var bitmapList:Array<FlxSprite> = [];
	public var posList:Array<FlxPoint> = [];

	public var bitmapHash:Array<String> = [];

	public var bgColor:FlxColor = 0xFF222529;

	public var selectBitmap:BitmapData->Void = null;
	public var selectTile:String->Void = null;

	public var selectionSpr:FlxSprite;

	public function new(?x:Float = 0, ?y:Float = 0, ?width:Int = 320, ?height:Int = 226)
	{
		super(x, y);

		height = height + 16;

		makeGraphic(width, height, 0x0);
		FlxSpriteUtil.drawRoundRect(this, 0.0, 0.0, width, height, 8.0, 8.0, 0xFFFFFFFF);
		color = bgColor;

		selectionSpr = new FlxSprite().makeGraphic(1, 1, FlxColor.TRANSPARENT);

		refreshList();
	}

	public var selected:Int = -1;

	private var rows:Int = 0;

	override public function update(elapsed:Float)
	{
		if (FlxG.mouse.overlaps(this, camera))
		{
			var i:Int = 0;
			var skip:Bool = false; // no need to check the list again and because its sorted anyway

			while (i < bitmapList.length)
			{
				if (!bitmapList[i].exists)
				{
					i++;
					if (skip)
						break;
					else
						continue;
				}
				else
				{
					skip = true;

					if (FlxG.mouse.overlaps(bitmapList[i], camera))
					{
						bitmapList[i].setColorTransform(1.0, 1.0, 1.0, 1.0, 60, 60, 60, 0.0);

						if (FlxG.mouse.justReleased)
						{
							selected = i;

							if (selectionSpr.width != (bitmapList[i].width + 8).floor()
								|| selectionSpr.height != (bitmapList[i].height + 8).floor())
							{
								selectionSpr.makeGraphic((bitmapList[i].width + 8).floor(), (bitmapList[i].height + 8).floor(),
									FlxColor.WHITE);

								selectionSpr.pixels.lock();
								selectionSpr.pixels.fillRect(new Rectangle(4, 4, bitmapList[i].width, bitmapList[i].height),
									FlxColor.TRANSPARENT);
								selectionSpr.pixels.unlock();
							}

							selectionSpr.setPosition(bitmapList[i].x - 4, bitmapList[i].y - 4);

							if (selectBitmap != null)
								selectBitmap(bitmapList[i].pixels);
							if (selectTile != null)
								selectTile(bitmapList[i].customData.get('name'));
						}
					}
					else
						bitmapList[i].setColorTransform(1.0, 1.0, 1.0, 1.0, 0.0, 0.0, 0.0, 0.0);
					i++;
				}
			}

			if (FlxG.mouse.wheel != 0 && rows > 5)
			{
				var _lastScroll:Int = _scrollVert;

				_scrollVert = FlxMath.bound(_scrollVert - FlxG.mouse.wheel, 0, rows - 4).floor();

				if (_lastScroll != _scrollVert)
					refreshList();
			}
		}

		super.update(elapsed);
	}

	override public function draw()
	{
		super.draw();

		for (spr in bitmapList)
		{
			if (spr.exists && spr.visible)
				spr.draw();
		}

		if (bitmapList[selected]?.exists && bitmapList[selected].visible)
			selectionSpr.draw();
	}

	public function addImage(name:String, bitmap:BitmapData)
	{
		var spr:FlxSprite = new FlxSprite(bitmap);
		spr.scale.set(2, 2);
		spr.updateHitbox();
		spr.cameras = cameras;

		if (bitmapList.length == 0)
		{
			var point:FlxPoint = FlxPoint.get(12, 15);
			spr.setPosition(this.x + point.x, this.y + point.y);

			bitmapList[0] = spr;
			posList[0] = point;
		}
		else
		{
			var index:Int = bitmapList.length - 1;
			var lastSpr:FlxSprite = bitmapList[index];
			var point:FlxPoint = posList[index].clone();

			point.x += lastSpr.width + 4;

			spr.setPosition(this.x + point.x, this.y + point.y);

			if (spr.getRight() >= this.getRight())
			{
				point.x = 12;
				point.y += lastSpr.height + 4;

				rows++;
			}

			spr.setPosition(this.x + point.x, this.y + point.y);

			bitmapList.push(spr);
			posList.push(point);
		}

		if (!bitmapHash.contains(name))
			bitmapHash.push(name);

		spr.customData.set("row", rows);
		spr.customData.set("name", name);

		refreshList();
	}

	private var _scrollVert:Int = 0;

	public function refreshList():Void
	{
		for (i in 0...bitmapList.length)
		{
			var child:FlxSprite = bitmapList[i];
			var point:FlxPoint = posList[i];

			point.y = 15 + ((child.height + 4) * (child.customData.get("row") - _scrollVert));

			child.y = this.y + point.y;

			child.exists = (child.y > y && child.getBottom() < this.getBottom());
		}
	}

	override function set_camera(Value:FlxCamera):FlxCamera
	{
		if (_cameras == null)
			_cameras = [Value];
		else
			_cameras[0] = Value;
		selectionSpr.camera = Value;
		return Value;
	}
}
