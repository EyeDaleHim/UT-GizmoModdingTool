package utils;

import openfl.geom.Point;

class ImageUtils
{
	public static function mergeBitmaps(list:Array<FlxGraphic>, ?sourceFile:SourceFile):BitmapData
	{
		var spaceBitmap:BitmapData = new BitmapData(2048, 2048, true, 0);

		var saveToSource:Bool = sourceFile != null;

		if (saveToSource)
		{
			sourceFile.hash.splice(0, sourceFile.hash.length);
			sourceFile.list.splice(0, sourceFile.list.length);
		}

		var totalWidth:Int = 0;
		var totalHeight:Int = 0;

		var maxSprHeight:Int = 0;

		var numSprites:Int = list.length;

		var spritesPerRow:Int = Math.ceil(Math.sqrt(numSprites)); // row
		var numRows:Int = Math.ceil(numSprites / spritesPerRow); // col

		var rect:Rectangle = new Rectangle();
		var point:Point = new Point();

		spaceBitmap.lock();

		var spriteIndex:Int = 0;

		for (row in 0...numRows)
		{
			point.x = 0;
			point.y += maxSprHeight;
			for (col in 0...spritesPerRow)
			{
				if (spriteIndex >= numSprites)
					break;

				maxSprHeight = Math.max(maxSprHeight, list[spriteIndex].bitmap.height).floor();

				rect.width = list[spriteIndex].width;
				rect.height = list[spriteIndex].height;

				totalWidth = Math.max(totalWidth, point.x + list[spriteIndex].bitmap.width).floor();
				totalHeight = Math.max(totalHeight, point.y + list[spriteIndex].bitmap.height).floor();

				if (saveToSource)
				{
					sourceFile.list.push({
						x: point.x.floor(),
						y: point.y.floor(),
						width: rect.width.floor(),
						height: rect.height.floor()
					});

					var noMatch:Bool = false;
					var trueIndex:Int = -1;

					for (i in 0...sourceFile.hash.length)
					{
						if (sourceFile.hash[i].name == list[spriteIndex].key.pureFilename())
						{
							noMatch = true;
							trueIndex = i;
							break;
						}
					}

					if (!noMatch)
						sourceFile.hash.push({name: list[spriteIndex].key.pureFilename(), index: spriteIndex});
					else
						sourceFile.hash[trueIndex].index = spriteIndex;
				}

				spaceBitmap.copyPixels(list[spriteIndex].bitmap, rect, point, null, null, true);

				spriteIndex++;

				if (list[spriteIndex] != null)
					point.x += list[spriteIndex].width;
			}
		}

		spaceBitmap.unlock();

		var newBitmap:BitmapData = new BitmapData(totalWidth, totalHeight, true, 0);
		newBitmap.lock();
		newBitmap.copyPixels(spaceBitmap, new Rectangle(0, 0, totalWidth, totalHeight), new Point(), null, null, true);
		newBitmap.unlock();

		spaceBitmap.disposeImage();
		spaceBitmap.dispose();

		return newBitmap;
	}
}
