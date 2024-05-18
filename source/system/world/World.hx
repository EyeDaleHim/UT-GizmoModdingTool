package system.world;

class World extends FlxObject
{
	public static var tileBitmapCache(default, never):Map<String, FlxGraphic> = [];
	public static var decalBitmapCache(default, never):Map<String, FlxGraphic> = [];

	public static var roomList:Map<String, Room> = [];

	public var objectPool:FlxTypedGroup<FlxObject> = new FlxTypedGroup<FlxObject>();

	public var collisionGroup:FlxTypedGroup<FlxObject> = new FlxTypedGroup<FlxObject>();
	public var nodeGroups:Array<FlxTypedGroup<FlxObject>> = [];

	public var currentRoom:Room;

	public function new()
	{
		super();

		for (i in 0...4)
			nodeGroups[i] = new FlxTypedGroup<FlxObject>();
	}

	public function setNewRoom(roomName:String)
	{
		if (roomList.exists(roomName))
		{
			var room:Room = roomList.get(roomName);

			if (currentRoom != null)
				currentRoom.kill();

			currentRoom = room;
			room.revive();
		}
		else
		{
			FlxG.log.error('Could not find $roomName');
			return;
		}

		collisionGroup.clear();

		for (group in nodeGroups)
			group.clear();

		objectPool.forEachAlive((collision:FlxObject) ->
		{
			collision.kill();
			collision.allowCollisions = NONE;
		});

		if (objectPool.length > 32)
		{
			for (i in 32...objectPool.length)
				FlxDestroyUtil.destroy(objectPool.remove(objectPool.members[i], true));
		}

		for (i in 0...currentRoom.collisions.length)
		{
			var collisionObj:FlxObject = objectPool.recycle(FlxObject);
			var collision = currentRoom.collisions[i];

			collisionObj.allowCollisions = ANY;
			collisionObj.setPosition(collision.x, collision.y);
			collisionObj.last.copyFrom(collisionObj.getPosition());
			collisionObj.setSize(collision.width, collision.height);

			collisionObj.immovable = true;
			collisionGroup.add(collisionObj);

			FlxG.worldBounds.set(
				Math.min(collision.x, FlxG.worldBounds.x), 
				Math.min(collision.y, FlxG.worldBounds.y),
				Math.max(collision.x + collision.width, FlxG.worldBounds.width),
				Math.max(collision.y + collision.height, FlxG.worldBounds.height)
			);
		}

		for (i in 0...currentRoom.nodes.length)
		{
			var nodeObj:FlxObject = objectPool.recycle(FlxObject);
			var node = currentRoom.nodes[i];

			nodeObj.customData.clear();
			nodeObj.customData.set("node", node);

			nodeObj.revive();

			nodeObj.allowCollisions = ANY;
			nodeObj.setPosition(node.x, node.y);
			nodeObj.last.copyFrom(nodeObj.getPosition());
			nodeObj.setSize(20, 20);

			nodeObj.immovable = true;
			nodeGroups[node.type].add(nodeObj);

			FlxG.worldBounds.set(
				Math.min(node.x, FlxG.worldBounds.x), 
				Math.min(node.y, FlxG.worldBounds.y),
				Math.max(node.x + 20, FlxG.worldBounds.width),
				Math.max(node.y + 20, FlxG.worldBounds.height)
			);
		}

		if (currentRoom.cameraLock == null)
		{
			FlxG.camera.minScrollX = FlxG.worldBounds.x;
			FlxG.camera.minScrollY = FlxG.worldBounds.y;
			FlxG.camera.maxScrollX = FlxG.worldBounds.width;
			FlxG.camera.maxScrollY = FlxG.worldBounds.height;
		}
		else
		{
			FlxG.camera.minScrollX = currentRoom.cameraLock.x;
			FlxG.camera.minScrollY = currentRoom.cameraLock.y;
			FlxG.camera.maxScrollX = currentRoom.cameraLock.width;
			FlxG.camera.maxScrollY = currentRoom.cameraLock.height;
			trace(FlxG.worldBounds);
			trace(currentRoom.cameraLock);
		}

		// offset of 20 for safe measure
		FlxG.worldBounds.x -= 20;
		FlxG.worldBounds.y -= 20;
		FlxG.worldBounds.width += 40;
		FlxG.worldBounds.height += 40;
	}

	override public function update(elapsed:Float)
	{
		if (currentRoom != null)
			currentRoom.update(elapsed);

		super.update(elapsed);
	}

	override public function draw()
	{
		if (currentRoom != null)
			currentRoom.draw();

		super.draw();
	}
}
