package system.world;

class Layer
{
	public var alpha(default, set):Float = 1.0;
	public var tiles:Array<Array<Tile>> = [];
	public var decals:Array<Decal> = [];

	// -_-
	public function new()
	{
	}

	function set_alpha(Value:Float = 1.0):Float
	{
		return (alpha = FlxMath.bound(Value, 0.0, 1.0));
	}
}

@:allow(states.PlayState)
class Room extends FlxObject
{
	private static var _cacheTileList:Array<String> = [];
	private static var _cacheDecalList:Array<String> = [];

	// as far as i'm aware, preloading is threaded, but it may cause crashes because of graphics!
	// this variable will store the image paths for reference so we'll cache them in one single thread
	public static var preCacheMode:Bool = false;

	public static function cacheList():Void
	{
		if (_cacheTileList.length > 0)
		{
			for (graphic in _cacheTileList)
			{
				World.tileBitmapCache.set(graphic, Assets.image('overworld/tiles/${graphic.trim()}'));
			}
		}

		if (_cacheDecalList.length > 0)
		{
			for (graphic in _cacheDecalList)
			{
				World.decalBitmapCache.set(graphic, Assets.image('overworld/decals/${graphic.trim()}'));
			}
		}

		for (room in World.roomList)
		{
			for (layer in room.grid)
			{
				for (tileGroup in layer.tiles)
				{
					if (tileGroup == null || tileGroup.length == 0)
						continue;

					for (tile in tileGroup)
					{
						if (tile == null)
							continue;
						tile.frame = FlxImageFrame.fromGraphic(World.tileBitmapCache.get(tile.graphic));
					}
				}

				for (decal in layer.decals)
				{
					decal.frame = FlxImageFrame.fromGraphic(World.decalBitmapCache.get(decal.graphic));
				}
			}
		}
	}

	public static var debugView:Bool = true;

	public static final nodeTypes:Array<String> = ["event", "interact", "room", "spawn"];

	public var globalAlpha:Float = 1.0;
	public var antialiasing:Bool = FlxSprite.defaultAntialiasing;

	public var colorTransform:ColorTransform;

	public var defaultTileWidth:Int = 20;
	public var defaultTileHeight:Int = 20;

	public var data:RoomFile;

	public var name:String = "";

	public var grid:Array<Layer> = [];
	public var collisions:Array<Collision> = [];
	public var nodes:Array<Node> = [];

	public var cameraLock:FlxRect = null;

	private var _collisionGroup:FlxTypedGroup<FlxObject>;

	private var _flashPoint:Point = new Point();
	private var _flashRect:Rectangle = new Rectangle();

	private var _matrix:FlxMatrix = new FlxMatrix();

	private var _selectedColorTransform:ColorTransform;

	override public function new(file:Null<RoomFile> = null)
	{
		super();

		colorTransform = new ColorTransform();

		_selectedColorTransform = new ColorTransform();
		_selectedColorTransform.greenOffset = 255;

		if (file == null)
		{
			FlxG.log.error("Couldn't load a room, is your room null?");
		}
		else
		{
			if (file.cameraLock != null)
			{
				cameraLock = FlxRect.get(file.cameraLock.x, file.cameraLock.y, file.cameraLock.width, file.cameraLock.height);
			}

			if (file.tiles?.length > 0)
			{
				for (tile in file.tiles)
				{
					if (tile.x == null)
						tile.x = 0;
					if (tile.y == null)
						tile.y = 0;

					var tile:Tile = {
						graphic: tile.img ?? "",
						tileX: tile.x ?? FlxMath.MAX_VALUE_INT,
						tileY: tile.y ?? FlxMath.MAX_VALUE_INT,
						tileLayer: tile.layer ?? 0
					};
					addTile(tile);
				}
			}

			if (file.decals?.length > 0)
			{
				for (decal in file.decals)
				{
					if (decal.x == null)
						decal.x = Math.NEGATIVE_INFINITY;
					if (decal.y == null)
						decal.y = Math.NEGATIVE_INFINITY;

					var decal:Decal = {
						graphic: decal.img ?? "",
						x: decal.x,
						y: decal.y,
						scrollX: 1.0,
						scrollY: 1.0,
						layer: decal.layer
					};
					addDecal(decal);
				}
			}

			if (file.collisions?.length > 0)
			{
				for (collision in file.collisions)
				{
					var collision:Collision = {
						x: collision.x ?? Math.NEGATIVE_INFINITY,
						y: collision.y ?? Math.NEGATIVE_INFINITY,
						width: collision.width ?? 20,
						height: collision.height ?? 20,
						type: cast collision.type
					}
					addCollision(collision);
				}
			}

			if (file.nodes?.length > 0)
			{
				for (node in file.nodes)
				{
					var node:Node = {
						x: node.x ?? Math.NEGATIVE_INFINITY,
						y: node.y ?? Math.NEGATIVE_INFINITY,
						type: node.type ?? 0,
						tag: node.tag ?? "unknown",
						contexts: node.context ?? []
					}
					addNode(node);
				}
			}
		}
	}

	// typically used in room editor, but also works outside of it
	public function addTile(tile:Tile, replace:Bool = true)
	{
		if (tile.tileX < 0 || tile.tileY < 0 || Math.isNaN(tile.tileX) || Math.isNaN(tile.tileY))
		{
			FlxG.log.error("That tile can't be placed because it is out of bounds.");
			return;
		}

		if (grid[tile.tileLayer] == null)
			grid[tile.tileLayer] = new Layer();

		if (grid[tile.tileLayer].tiles[tile.tileX] == null)
			grid[tile.tileLayer].tiles[tile.tileX] = [];

		if (grid[tile.tileLayer].tiles[tile.tileX][tile.tileY] != null && !replace)
		{
			FlxG.log.error("You cannot replace that tile.");
			return;
		}

		if (tile.graphReplacement == null)
		{
			if (!World.tileBitmapCache.exists(tile.graphic.trim()))
			{
				if (FileSystem.exists(Assets.imagePath('overworld/tiles/${tile.graphic.trim()}')))
				{
					if (preCacheMode)
					{
						if (_cacheTileList.indexOf(tile.graphic) == -1)
							_cacheTileList.push(tile.graphic);
					}
					else
					{
						World.tileBitmapCache.set(tile.graphic, Assets.image('overworld/tiles/${tile.graphic.trim()}'));
						tile.frame = FlxImageFrame.fromGraphic(World.tileBitmapCache.get(tile.graphic));
					}
				}
			}
			else
				tile.frame = FlxImageFrame.fromGraphic(World.tileBitmapCache.get(tile.graphic));
		}
		else
			tile.frame = FlxImageFrame.fromGraphic(tile.graphReplacement);

		grid[tile.tileLayer].tiles[tile.tileX][tile.tileY] = null;
		grid[tile.tileLayer].tiles[tile.tileX][tile.tileY] = tile;
	}

	public function removeTile(tile:Tile, splice = false):Tile
	{
		if (grid[tile.tileLayer].tiles[tile.tileX] == null)
			return tile;

		if (grid[tile.tileLayer].tiles[tile.tileX].indexOf(tile) == tile.tileY)
		{
			if (splice)
				grid[tile.tileLayer].tiles[tile.tileX].splice(tile.tileY, 1);
			else
				grid[tile.tileLayer].tiles[tile.tileX][tile.tileY] = null;
		}

		return tile;
	}

	public function addDecal(decal:Decal)
	{
		if (Math.isNaN(decal.x) || Math.isNaN(decal.y))
		{
			FlxG.log.error("For some reason, your decal's positions are invalid.");
			return;
		}

		if (grid[decal.layer] == null)
			grid[decal.layer] = new Layer();

		if (decal.graphReplacement == null)
		{
			if (!World.decalBitmapCache.exists(decal.graphic))
			{
				if (FileSystem.exists(Assets.imagePath('overworld/decals/${decal.graphic}')))
				{
					if (preCacheMode)
					{
						if (_cacheDecalList.indexOf(decal.graphic) == -1)
							_cacheDecalList.push(decal.graphic);
					}
					else
					{
						World.decalBitmapCache.set(decal.graphic, Assets.image('overworld/decals/${decal.graphic}'));
						decal.frame = FlxImageFrame.fromGraphic(World.decalBitmapCache.get(decal.graphic));
					}
				}
			}
			else
				decal.frame = FlxImageFrame.fromGraphic(World.decalBitmapCache.get(decal.graphic));
		}
		else
			decal.frame = FlxImageFrame.fromGraphic(decal.graphReplacement);

		grid[decal.layer].decals.push(decal);
	}

	public function removeDecal(decal:Decal, splice:Bool = false):Decal
	{
		if (grid[decal.layer].decals == null || grid[decal.layer].decals.length == 0)
			return decal;

		var index:Int = grid[decal.layer].decals.indexOf(decal);

		if (index >= 0)
		{
			if (splice)
				grid[decal.layer].decals.splice(index, 1);
			else
				grid[decal.layer].decals[index] = null;
		}

		return decal;
	}

	public function addCollision(collision:Collision)
	{
		if (Math.isNaN(collision.x) || Math.isNaN(collision.y))
		{
			FlxG.log.error("what the fuck man, your collision's positions are invalid");
			return;
		}

		if (collision.width <= 0 || collision.height <= 0)
		{
			FlxG.log.error("what the fuck man, your collision's position can't be 0 or below");
			return;
		}

		collisions.push(collision);

		collisions.sort(sortByXY);
	}

	public function removeCollision(collision:Collision, splice:Bool = true)
	{
		if (collisions?.length == 0)
			return;

		var index:Int = collisions.indexOf(collision);

		if (index >= 0)
		{
			if (splice)
				collisions.splice(index, 1);
			else
				collisions[index] = null;
		}

		collisions.sort(sortByXY);
	}

	public function addNode(node:Node)
	{
		if (Math.isNaN(node.x) || Math.isNaN(node.y))
		{
			FlxG.log.error("For some reason, your node's positions are invalid.");
			return;
		}

		nodes.push(node);
	}

	public function removeNode(node:Node, splice:Bool = false):Node
	{
		if (nodes == null || nodes.length == 0)
			return node;

		var index:Int = nodes.indexOf(node);

		if (index >= 0)
		{
			if (splice)
				nodes.splice(index, 1);
			else
				nodes[index] = null;
		}

		return node;
	}

	public function clear()
	{
		for (layer in grid)
		{
			for (i in 0...layer.tiles.length)
			{
				var row = layer.tiles[i];

				if (row != null)
				{
					for (j in 0...layer.tiles[i].length)
					{
						var col = layer.tiles[i][j];

						col = null;
					}

					row = null;
				}
			}

			layer.tiles = null;

			for (i in 0...layer.decals.length)
			{
				var decal = layer.decals[i];

				decal = null;
			}

			layer = null;
		}

		grid.splice(0, grid.length);
	}

	function sortByXY(a:Collision, b:Collision):Int
	{
		if (a.x < b.x)
			return -1;
		if (a.x > b.x)
			return 1;

		if (a.y < b.y)
			return -1;
		if (a.y > b.y)
			return 1;

		return 0;
	}

	override public function draw()
	{
		if (globalAlpha == 0)
			return;

		for (camera in cameras)
		{
			if (!camera.visible || !camera.exists)
				continue;

			for (layer in grid)
			{
				if (layer == null)
					continue;
				for (row in 0...layer.tiles.length)
				{
					if (layer.tiles[row] == null)
						continue;
					for (col in 0...layer.tiles[row].length)
					{
						var tile:Tile = layer.tiles[row][col];

						if (tile != null)
						{
							var _tileFrame:FlxFrame;

							if (tile.frame == null)
							{
								FlxG.log.error('Couldn\'t render ${tile.graphic}. Check for "overworld/tiles/${tile.graphic}"');
								continue;
							}
							else
								_tileFrame = tile.frame.frame;

							var currentTransform:ColorTransform = colorTransform;

							if (tile.editorSelected)
								currentTransform = _selectedColorTransform;

							currentTransform.alphaMultiplier = layer.alpha * globalAlpha;

							var pixels:BitmapData = _tileFrame.parent.bitmap;

							_flashRect.setTo(0, 0, pixels.width, pixels.height);
							getScreenPosition(_point, camera);
							_point.add(defaultTileWidth * tile.tileX, defaultTileHeight * tile.tileY);

							if (isPixelPerfectRender(camera))
								_point.floor();

							if (!camera.containsPoint(_point, _flashRect.width, _flashRect.height))
								continue;

							_point.copyToFlash(_flashPoint);

							camera.copyPixels(_tileFrame, pixels, _flashRect, _flashPoint, currentTransform, null, antialiasing);
						}
					}
				}

				if (layer.decals.length > 0)
				{
					for (decal in layer.decals)
					{
						var _decalFrame:FlxFrame;

						if (decal.frame == null)
						{
							FlxG.log.error('Couldn\'t render ${decal.graphic}. Check for "overworld/decals/${decal.graphic}"');
							continue;
						}
						else
							_decalFrame = decal.frame.frame;

						var currentTransform:ColorTransform = colorTransform;

						if (decal.editorSelected)
							currentTransform = _selectedColorTransform;

						currentTransform.alphaMultiplier = layer.alpha * globalAlpha;

						var pixels:BitmapData = _decalFrame.parent.bitmap;

						_flashRect.setTo(0, 0, pixels.width, pixels.height);
						getScreenPosition(_point, camera);
						_point.add(decal.x, decal.y);
						_point.scale(decal.scrollX, decal.scrollY);

						if (isPixelPerfectRender(camera))
							_point.floor();

						if (!camera.containsPoint(_point, _flashRect.width, _flashRect.height))
							continue;

						_point.copyToFlash(_flashPoint);

						camera.copyPixels(_decalFrame, pixels, _flashRect, _flashPoint, currentTransform, null, antialiasing);
					}
				}
			}

			if (Room.debugView)
			{
				for (collision in collisions)
				{
					if (collision.resizableSpr != null)
					{
						var currentTransform:ColorTransform = colorTransform;

						if (collision.editorSelected)
						{
							currentTransform = new ColorTransform();
							currentTransform.blueOffset = 255;
						}
						collision.resizableSpr.colorTransform.blueOffset = currentTransform.blueOffset;

						collision.resizableSpr.draw();

						continue;
					}

					var _frame:FlxFrame = null;
					var graph:FlxGraphic = null;

					var prefix:String = "_debug/room/collisions";

					switch (collision.type)
					{
						case WALL:
							graph = Assets.image('$prefix/wall');
						case BOT_LEFT_STAIR:
							graph = Assets.image('$prefix/stair_bottom_left');
						case BOT_RIGHT_STAIR:
							graph = Assets.image('$prefix/stair_bottom_right');
						case TOP_LEFT_STAIR:
							graph = Assets.image('$prefix/stair_top_left');
						case TOP_RIGHT_STAIR:
							graph = Assets.image('$prefix/stair_top_right');
					}

					_frame = graph.imageFrame.frame;

					var currentTransform:ColorTransform = colorTransform;

					if (collision.editorSelected)
					{
						currentTransform = new ColorTransform();
						currentTransform.blueOffset = 255;
					}

					currentTransform.alphaMultiplier = globalAlpha;

					var _pixels:BitmapData = _frame.parent.bitmap;

					_flashRect.setTo(0, 0, _frame.sourceSize.x, _frame.sourceSize.y);

					var scale:FlxPoint = FlxPoint.get(collision.width / _pixels.width, collision.height / _pixels.height);

					_frame.prepareMatrix(_matrix, FlxFrameAngle.ANGLE_0, false, false);
					_matrix.scale(scale.x, scale.y);

					getScreenPosition(_point, camera);
					_point.add(collision.x, collision.y);

					_matrix.translate(_point.x, _point.y);

					if (isPixelPerfectRender(camera))
					{
						_matrix.tx = Math.floor(_matrix.tx);
						_matrix.ty = Math.floor(_matrix.ty);
					}

					if (!camera.containsPoint(_point, _flashRect.width * scale.x, _flashRect.height * scale.y))
					{
						scale.put();
						continue;
					}

					scale.put();

					_point.copyToFlash(_flashPoint);
					camera.drawPixels(_frame, _pixels, _matrix, currentTransform, null, false);
				}

				for (node in nodes)
				{
					var _frame:FlxFrame = null;
					var graph:FlxGraphic = Assets.image('_debug/room/${Room.nodeTypes[node.type]}');

					_frame = graph.imageFrame.frame;

					var currentTransform:ColorTransform = colorTransform;

					if (node.editorSelected)
						currentTransform = _selectedColorTransform;

					currentTransform.alphaMultiplier = globalAlpha;

					var pixels:BitmapData = graph.bitmap;

					_flashRect.setTo(0, 0, pixels.width, pixels.height);
					getScreenPosition(_point, camera);
					_point.add(node.x, node.y);

					if (isPixelPerfectRender(camera))
						_point.floor();

					if (!camera.containsPoint(_point, _flashRect.width, _flashRect.height))
						continue;

					_point.copyToFlash(_flashPoint);

					camera.copyPixels(_frame, pixels, _flashRect, _flashPoint, currentTransform, null, antialiasing);
				}
			}

			#if FLX_DEBUG
			FlxBasic.visibleCount++;
			#end
		}
	}

	public inline function getTile(layer:Int = 0, gridX:Int, gridY:Int):Tile
	{
		if (grid[layer] == null)
			return null;

		if (grid[layer].tiles[gridX] == null)
			return null;

		if (grid[layer].tiles[gridX] == null)
			return null;

		if (grid[layer].tiles[gridX][gridY] == null)
			return null;

		return grid[layer].tiles[gridX][gridY];
	}

	public inline function tileEquals(tileA:Tile, tileB:Tile):Bool
	{
		if (tileA == null || tileB == null)
			return false;

		return tileA.frame == tileB.frame && tileA.tileX == tileB.tileX && tileA.tileY == tileB.tileY;
	}

	function set_globalAlpha(Value:Float = 1.0):Float
	{
		return (globalAlpha = FlxMath.bound(Value, 0.0, 1.0));
	}
}
