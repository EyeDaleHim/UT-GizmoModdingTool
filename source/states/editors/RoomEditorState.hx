package states.editors;

import openfl.display.PNGEncoderOptions;
import ui.editor.TextObject;
import ui.editor.List;
import ui.editor.Button;
import ui.editor.Stepper;
import ui.editor.Checkbox;
import ui.editor.TextInput;
import ui.editor.animation.Track;
import ui.editor.room.ImageList;
import flixel.addons.display.FlxBackdrop;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.events.FileListEvent;
import openfl.geom.Rectangle;
import openfl.filesystem.File;
import haxe.io.Bytes;

typedef Clipboard =
{
	var content:Dynamic;
};

// not my best work but alright
class RoomEditorState extends BaseEditorState
{
	static var cursorType:String = "normal";

	static var speed:Float = 120;

	static var loadedFromSource:Bool = false;

	static var collisionNames:Map<CollisionType, String> = [
		WALL => "wall",
		TOP_LEFT_STAIR => "stair_top_left",
		TOP_RIGHT_STAIR => "stair_top_right",
		BOT_LEFT_STAIR => "stair_bottom_left",
		BOT_RIGHT_STAIR => "stair_bottom_right"
	];

	static var sortedCollisions:Array<CollisionType> = [WALL, TOP_LEFT_STAIR, TOP_RIGHT_STAIR, BOT_LEFT_STAIR, BOT_RIGHT_STAIR];

	// settings

	/**
		Determines if a tile is selected on the Tile Window, you can
		hold and drag on the world to place as many tiles. This will
		not replace any tiles.
	**/
	public static var quickPlace:Bool = true;

	// pools
	public static var collisionSpritePools:FlxTypedGroup<ResizableSprite>;

	// colors
	public static final bgHudColor:FlxColor = 0xFF2C2D2E;
	public static final bgHudColor2:FlxColor = 0xFF1F2225;
	public static final mainTextColor:FlxColor = 0xFFF2F8FF;

	// room
	public static var selectedRoom:String = "";
	public static var roomList(get, set):Map<String, Room>;
	public static var curRoom(get, set):Room;

	static function get_roomList():Map<String, Room>
	{
		return World.roomList;
	}

	static function set_roomList(newList:Map<String, Room>):Map<String, Room>
	{
		return (World.roomList = newList);
	}

	static function get_curRoom():Room
	{
		if (roomList.exists(selectedRoom))
			return roomList.get(selectedRoom);
		return null;
	}

	static function set_curRoom(room:Room):Room
	{
		roomList.set(selectedRoom, room);
		return roomList.get(selectedRoom);
	}

	// cameras
	public var mainCamera:FlxCamera;
	public var hudCamera:FlxCamera;

	public var camSpeed:FlxPoint = FlxPoint.get();

	// data
	public var roomIndex:Int = 0;
	public var viewMode:ViewMode = TILES;
	public var file:File;

	public var gridPos:FlxPoint = FlxPoint.get();
	public var decalPos:FlxPoint = FlxPoint.get();
	public var collisionPos:FlxPoint = FlxPoint.get();
	public var nodePos:FlxPoint = FlxPoint.get();

	public var selectedTiles:Array<Tile> = [];
	public var selectedDecals:Array<Decal> = [];
	public var selectedNodes:Array<Node> = [];

	public var selectedCollisionType:Int = 0;
	public var collisionRect:Collision; // rushed, so it only supports one collision per selection yet
	public var collisionType:CollisionType = WALL;

	public var currentNode:String = "";

	public var selectedLayer:Int = 0; // -1 = all layers
	public var afterPlayerLayer:Int = 5; // 5 is default

	public var cameraLockVisible:Bool = true;
	public var cursorVisible:Bool = false;

	public var decalListData:Map<String, FlxGraphic> = [];

	public var decalSnap:Int = 20;
	public var collisionSnap:Int = 1;
	public var nodeSnap:Int = 5;

	public var clipboard:Clipboard;

	// // modes
	public var selectMode:FlxSprite;

	public var tileModeButton:Button;
	public var decalModeButton:Button;
	public var collisionModeButton:Button;
	public var nodeModeButton:Button;

	public var cursorToggleCheckbox:Checkbox;

	// sprites
	// // world
	public var tileCursor:FlxSprite;
	public var decalCursor:FlxSprite;
	public var collisionCursor:FlxSprite;
	public var nodeCursor:FlxSprite;

	public var dragSpr:FlxSprite;

	public var resizableCamSpr:ResizableSprite;
	public var camSpr:FlxSprite;

	// // ui
	public var hudElements:FlxGroup;

	public var roomListUI:List;
	public var newRoomUI:Button;
	public var roomNameInput:TextInput;

	public var saveRoomButton:Button;
	public var loadRoomButton:Button;

	// // // camera lock controls
	public var camPropertyBG:FlxSprite;

	public var editorCamVisibleCheckbox:Checkbox;

	public var editorCamXPropertyStepper:Stepper;
	public var editorCamYPropertyStepper:Stepper;
	public var editorCamWidthPropertyStepper:Stepper;
	public var editorCamHeightPropertyStepper:Stepper;

	public var editorCamXPropertyStepperText:TextObject;
	public var editorCamYPropertyStepperText:TextObject;
	public var editorCamWidthPropertyStepperText:TextObject;
	public var editorCamHeightPropertyStepperText:TextObject;

	// // // camera reference controls
	public var editorCamReferenceSectionText:TextObject;

	public var editorCamReferenceVisibleCheckbox:Checkbox;
	public var editorCamReferencePropertyZoom:Stepper;

	// we're not really using these as steppers :P
	public var editorCamReferenceXInfo:Stepper;
	public var editorCamReferenceYInfo:Stepper;
	public var editorCamReferenceWidthInfo:Stepper;
	public var editorCamReferenceHeightInfo:Stepper;

	// // // utilities
	public var copyButton:Button;
	public var pasteButton:Button;

	// // // info
	public var infoText:TextObject;
	public var coordLocation:TextObject;
	public var snapTitleText:TextObject;

	public var objectInfoBG:FlxSprite;

	// // // room
	// // // // tileset
	public var tilesetList:ImageList;
	public var addTilesButton:Button;
	public var tileNameInput:TextInput;

	// // // // decals
	public var decalList:List;

	public var snapDecalDecButton:Button;
	public var snapDecalText:TextObject;
	public var snapDecalIncButton:Button;

	public var addDecalButton:Button;

	// // // // collisions
	public var collisionPropertyBG:FlxSprite;

	public var snapCollisionDecButton:Button;
	public var snapCollisionText:TextObject;
	public var snapCollisionIncButton:Button;

	public var collisionXInfo:TextObject;
	public var collisionYInfo:TextObject;
	public var collisionWidthInfo:TextObject;
	public var collisionHeightInfo:TextObject;

	public var collisionXStepper:Stepper;
	public var collisionYStepper:Stepper;
	public var collisionWidthStepper:Stepper;
	public var collisionHeightStepper:Stepper;

	public var collisionTypeSprite:FlxSprite;

	public var collisionTypeArrowLeft:Button;
	public var collisionTypeArrowRight:Button;

	// // // // nodes
	public var nodeList:ImageList;

	public var nodeContextBG:FlxSprite;

	public var nodeTagTitle:TextObject;
	public var nodeTagInput:TextInput;

	// // // // // event node
	public var nodeEventTagInput:TextInput;

	// public var
	// // // // // interact node
	// public var
	// // // // // spawn node
	public var spawnOriginTitle:TextObject;

	public var spawnOriginInput:TextInput;

	// // // // // room node
	public var nextRoomTitle:TextObject;
	public var targetSpawnTitle:TextObject;

	public var nextRoomInput:TextInput;
	public var targetSpawnInput:TextInput;

	// // // // layers
	public var layerDecButton:Button;
	public var layerIncButton:Button;
	public var layerAllButton:Button;

	public var setLayerPlayerButton:Button;

	public var layerText:TextObject;

	override function create()
	{
		super.preCreate();

		mainCamera = FlxG.camera;

		hudCamera = new FlxCamera(0, 0, 1600, 900);
		hudCamera.bgColor.alpha = 0;
		FlxG.cameras.add(hudCamera, false);

		FlxG.console.registerObject("roomVar", curRoom);
		FlxG.console.registerObject("listVar", roomList);

		if (collisionSpritePools == null)
		{
			collisionSpritePools = new FlxTypedGroup<ResizableSprite>();
			for (i in 0...20) // preallocate 20
			{
				var collisionSprite:ResizableSprite = new ResizableSprite(false);
				collisionSprite.kill();
				collisionSprite.customData.set("parentCollision", null);
				collisionSpritePools.add(collisionSprite);
			}
			collisionSpritePools.active = false;
		}
		add(collisionSpritePools);

		tileCursor = new FlxSprite().makeGraphic(20, 20);
		tileCursor.active = tileCursor.moves = false;
		add(tileCursor);

		decalCursor = new FlxSprite();
		decalCursor.active = decalCursor.moves = false;
		decalCursor.visible = false;
		add(decalCursor);

		collisionCursor = new FlxSprite();
		collisionCursor.active = decalCursor.moves = false;
		collisionCursor.loadGraphic(Assets.image('_debug/room/collisions/${collisionNames.get(sortedCollisions[selectedCollisionType])}'));
		add(collisionCursor);

		nodeCursor = new FlxSprite();
		nodeCursor.active = nodeCursor.moves = false;
		nodeCursor.visible = false;
		add(nodeCursor);

		dragSpr = new FlxSprite().makeGraphic(1, 1, FlxColor.CYAN);
		dragSpr.alpha = 0.3;
		dragSpr.blend = ADD;
		dragSpr.active = dragSpr.moves = false;
		dragSpr.kill();
		add(dragSpr);

		resizableCamSpr = new ResizableSprite(0, 0, 20, 20, 0x5DBDBDBD, 0x5DFFFFFF);
		resizableCamSpr.onModify = function()
		{
			editorCamXPropertyStepper.updateValue();
			editorCamYPropertyStepper.updateValue();
			editorCamWidthPropertyStepper.updateValue();
			editorCamHeightPropertyStepper.updateValue();

			if (curRoom != null)
			{
				if (curRoom.cameraLock == null)
					curRoom.cameraLock = FlxRect.get();
				curRoom.cameraLock.set(resizableCamSpr.x, resizableCamSpr.y, resizableCamSpr.width, resizableCamSpr.height);
			}
		};

		camSpr = new FlxSprite();

		hudElements = new FlxGroup();

		addRoomListUI();
		addCameraUI();

		add(resizableCamSpr); // update order matters

		addInfoUI();
		addTilesetUI();
		addDecalUI();
		addCollisionUI();
		addNodeUI();
		addLayerUI();

		// lazy af workaround
		selectNewMode(NODES);
		selectNewMode(NODES);
		selectNewMode(COLLISIONS);
		selectNewMode(DECALS);
		selectNewMode(TILES);

		var decalHash:Array<String> = [];

		for (k => v in roomList)
		{
			for (layer in v.grid)
			{
				if (layer.tiles?.length > 0)
				{
					for (row in layer.tiles)
					{
						if (row?.length > 0)
						{
							for (tile in row)
							{
								if (tile != null)
								{
									if (!tilesetList.bitmapHash.contains(tile.graphic.trim()))
									{
										var path:String = 'overworld/tiles/${tile.graphic.trim()}';

										if (FileSystem.exists(Assets.imagePath(path)))
											tilesetList.addImage(tile.graphic.trim(), Assets.image(path, false).bitmap);
									}
								}
							}
						}
					}
				}

				if (layer.decals?.length > 0)
				{
					for (decal in layer.decals)
					{
						if (!decalHash.contains(decal.graphic.trim()))
						{
							var path:String = 'overworld/decals/${decal.graphic.trim()}';

							if (FileSystem.exists(Assets.imagePath(path)))
							{
								if (!decalListData.exists(decal.graphic))
									decalListData.set(decal.graphic, Assets.image(path, false));
								decalList.add(decal.graphic, decalList.children.length);
								decalList.children[decalList.children.length - 1].customData.set("name", decal.graphic);
							}
						}

						if (decalListData.exists(decal.graphic))
							decal.graphReplacement = decalListData.get(decal.graphic);
					}
				}
			}

			for (collision in v.collisions)
			{
				// stairs don't need resizable sprites
				if (collision == null || collision.type != WALL)
					continue;

				collision.resizableSpr = collisionSpritePools.recycle(ResizableSprite, function()
				{
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

					var object:ResizableSprite = new ResizableSprite(collision.x, collision.y, collision.width.floor(), collision.height.floor(), graph, false);
					object.canDrag = viewMode == COLLISIONS;

					return object;
				});
				collision.resizableSpr.onModify = function()
				{
					collision.x = collision.resizableSpr.x;
					collision.y = collision.resizableSpr.y;
					collision.width = collision.resizableSpr.width;
					collision.height = collision.resizableSpr.height;

					collisionXStepper.setValue(collision.resizableSpr.x);
					collisionYStepper.setValue(collision.resizableSpr.y);
					collisionWidthStepper.setValue(collision.resizableSpr.width);
					collisionHeightStepper.setValue(collision.resizableSpr.height);

					collisionXStepper.updateValue();
					collisionYStepper.updateValue();
					collisionWidthStepper.updateValue();
					collisionHeightStepper.updateValue();
				}
				collision.resizableSpr.updateSize();
				collision.resizableSpr.kill(); // rooms are not selected first time

				collision.resizableSpr.customData.set("parentCollision", collision);
			}

			roomListUI.add(k, roomListUI.children.length);
		}
	}

	public function addCameraUI():Void
	{
		camPropertyBG = new FlxSprite(10, 280).makeGraphic(250, 300, FlxColor.TRANSPARENT);
		FlxSpriteUtil.drawRoundRect(camPropertyBG, 0, 0, camPropertyBG.width, camPropertyBG.height, 4, 4, bgHudColor);
		camPropertyBG.camera = hudCamera;
		add(camPropertyBG);

		editorCamVisibleCheckbox = new Checkbox(15, 290, 24, 24, 0xFFFFFFFF, "Visible", function()
		{
			return cameraLockVisible;
		}, function(value:Bool)
		{
			cameraLockVisible = value;

			resizableCamSpr.exists = value;
			camSpr.exists = value;
		});
		editorCamVisibleCheckbox.camera = hudCamera;
		add(editorCamVisibleCheckbox);

		editorCamXPropertyStepper = new Stepper(15, 345, 50, "", function()
		{
			return resizableCamSpr.x;
		}, function(value:Float)
		{
			resizableCamSpr.x = value;

			resizableCamSpr.updateSize();
		});
		editorCamXPropertyStepper.camera = hudCamera;
		add(editorCamXPropertyStepper);

		editorCamYPropertyStepper = new Stepper(150, 345, 50, "", function()
		{
			return resizableCamSpr.y;
		}, function(value:Float)
		{
			resizableCamSpr.y = value;

			resizableCamSpr.updateSize();
		});
		editorCamYPropertyStepper.camera = hudCamera;
		add(editorCamYPropertyStepper);

		editorCamWidthPropertyStepper = new Stepper(15, 415, 50, "", function()
		{
			return resizableCamSpr.width;
		}, function(value:Float)
		{
			resizableCamSpr.width = value;

			resizableCamSpr.updateSize();
		});
		editorCamWidthPropertyStepper.camera = hudCamera;
		add(editorCamWidthPropertyStepper);

		editorCamHeightPropertyStepper = new Stepper(150, 415, 50, "", function()
		{
			return resizableCamSpr.height;
		}, function(value:Float)
		{
			resizableCamSpr.height = value;

			resizableCamSpr.updateSize();
		});
		editorCamHeightPropertyStepper.camera = hudCamera;
		add(editorCamHeightPropertyStepper);

		editorCamXPropertyStepperText = new TextObject(15, 325, 0, "X", 12);
		editorCamXPropertyStepperText.active = false;
		editorCamXPropertyStepperText.camera = hudCamera;
		add(editorCamXPropertyStepperText);

		editorCamYPropertyStepperText = new TextObject(150, 325, 0, "Y", 12);
		editorCamYPropertyStepperText.active = false;
		editorCamYPropertyStepperText.camera = hudCamera;
		add(editorCamYPropertyStepperText);

		editorCamWidthPropertyStepperText = new TextObject(15, 395, 0, "Width", 12);
		editorCamWidthPropertyStepperText.active = false;
		editorCamWidthPropertyStepperText.camera = hudCamera;
		add(editorCamWidthPropertyStepperText);

		editorCamHeightPropertyStepperText = new TextObject(150, 395, 0, "Height", 12);
		editorCamHeightPropertyStepperText.active = false;
		editorCamHeightPropertyStepperText.camera = hudCamera;
		add(editorCamHeightPropertyStepperText);
	}

	public function addInfoUI():Void
	{
		infoText = new TextObject(110, 260, 0, "", 14);
		infoText.camera = hudCamera;
		add(infoText);

		coordLocation = new TextObject("X: 0, Y: 0", 14);
		coordLocation.setPosition(FlxG.width - (coordLocation.width + 4), FlxG.height - (coordLocation.height + 4));
		coordLocation.camera = hudCamera;
		add(coordLocation);

		tileModeButton = new Button(100, 80, "Tiles", 16, true);
		tileModeButton.onClick = function()
		{
			selectNewMode(TILES);
		};

		decalModeButton = new Button("Decals", 16, true);
		decalModeButton.onClick = function()
		{
			selectNewMode(DECALS);
		};

		collisionModeButton = new Button("Collisions", 16, true);
		collisionModeButton.onClick = function()
		{
			selectNewMode(COLLISIONS);
		};

		nodeModeButton = new Button("Nodes", 16, true);
		nodeModeButton.onClick = function()
		{
			selectNewMode(NODES);
		};

		decalModeButton.setPosition(tileModeButton.getRight() + 2, tileModeButton.y);
		collisionModeButton.setPosition(decalModeButton.getRight() + 2, tileModeButton.y);
		nodeModeButton.setPosition(collisionModeButton.getRight() + 2, tileModeButton.y);

		var rect:FlxRect = FlxRect.get();

		var ptA:FlxPoint = tileModeButton.getPosition().subtract(2, 8);
		var ptB:FlxPoint = nodeModeButton.getPosition().add(nodeModeButton.width + 2, nodeModeButton.height + 8);

		rect.fromTwoPoints(ptA, ptB);

		selectMode = new FlxSprite(rect.x, rect.y).makeGraphic(rect.width.floor(), rect.height.floor(), 0);
		FlxSpriteUtil.drawRoundRect(selectMode, 0, 0, rect.width, rect.height, 4, 4, bgHudColor);
		selectMode.camera = hudCamera;
		add(selectMode);

		cursorToggleCheckbox = new Checkbox(selectMode.x, selectMode.getBottom() + 8, 24, 24, 0xFFFFFFFF, "Cursors", function()
		{
			return cursorVisible;
		}, function(value:Bool)
		{
			switch (viewMode)
			{
				case TILES:
					tileCursor.exists = value;
				case DECALS:
					decalCursor.exists = value;
				case COLLISIONS:
					collisionCursor.exists = value;
				case NODES:
					nodeCursor.exists = value;
			}

			cursorVisible = value;
		});

		tileModeButton.camera = hudCamera;
		decalModeButton.camera = hudCamera;
		collisionModeButton.camera = hudCamera;
		nodeModeButton.camera = hudCamera;

		cursorToggleCheckbox.camera = hudCamera;

		add(tileModeButton);
		add(decalModeButton);
		add(collisionModeButton);
		add(nodeModeButton);
		add(cursorToggleCheckbox);

		hudElements.add(selectMode);
		hudElements.add(cursorToggleCheckbox);
	}

	public function addTilesetUI():Void
	{
		tilesetList = new ImageList(1320, 100, 240, 226);
		tilesetList.camera = hudCamera;
		tilesetList.selectBitmap = function(bitmap:BitmapData)
		{
			tileCursor.loadGraphic(bitmap);
		};
		tilesetList.selectTile = function(name:String)
		{
			tileNameInput.active = true;
			tileNameInput.changeText(name);
		};
		add(tilesetList);

		addTilesButton = new Button(tilesetList.getRight(), tilesetList.getBottom() + 4, "Add Tile", 14);
		addTilesButton.camera = hudCamera;
		addTilesButton.x -= addTilesButton.width;
		addTilesButton.onClick = function()
		{
			file = new File();

			file.addEventListener(Event.SELECT, onSelect);
			file.addEventListener(FileListEvent.SELECT_MULTIPLE, onSelectMultiple);
			file.addEventListener(Event.COMPLETE, onComplete);
			file.addEventListener(Event.CANCEL, onCancel);
			file.addEventListener(IOErrorEvent.IO_ERROR, onError);

			file.browseForOpenMultiple("Open Files - Tiles");
		};
		add(addTilesButton);

		tileNameInput = new TextInput(tilesetList.x, tilesetList.getBottom() + 4, "");
		tileNameInput.camera = hudCamera;
		tileNameInput.active = false;
		tileNameInput.onChange = function(name:String)
		{
			var tileIndex:FlxSprite = tilesetList.bitmapList[tilesetList.selected];

			tileIndex.customData.set("name", name);
		};
		add(tileNameInput);

		hudElements.add(tilesetList);
		hudElements.add(tileNameInput);
		hudElements.add(addTilesButton);
	}

	public function addDecalUI():Void
	{
		decalList = new List(1320, 100, 240, 226);
		decalList.camera = hudCamera;
		add(decalList);

		decalList.onClick = function(select:Int)
		{
			decalCursor.loadGraphic(decalListData.get(decalList.children[select].customData.get("name")));
			decalCursor.visible = true;
		}

		addDecalButton = new Button(decalList.getRight(), decalList.getBottom() + 4, "Add Decals", 14);
		addDecalButton.camera = hudCamera;
		addDecalButton.x -= addDecalButton.width;
		addDecalButton.onClick = function()
		{
			file = new File();

			file.addEventListener(Event.SELECT, onSelect);
			file.addEventListener(FileListEvent.SELECT_MULTIPLE, onSelectMultiple);
			file.addEventListener(Event.COMPLETE, onComplete);
			file.addEventListener(Event.CANCEL, onCancel);
			file.addEventListener(IOErrorEvent.IO_ERROR, onError);

			file.browseForOpenMultiple("Open Files - Decals");
		};
		add(addDecalButton);

		snapTitleText = new TextObject(1200, 110, 0, "Snap X/Y", 16);
		snapTitleText.camera = hudCamera;
		add(snapTitleText);

		snapDecalText = new TextObject(1100, 145, 0, '$decalSnap', 18);
		snapDecalText.camera = hudCamera;
		snapDecalText.centerOverlay(snapTitleText, X);
		add(snapDecalText);

		snapDecalDecButton = new Button(snapDecalText.x, 145, "<", 18, true);
		snapDecalDecButton.x -= snapDecalDecButton.width + 8;
		snapDecalDecButton.camera = hudCamera;
		snapDecalDecButton.onClick = function()
		{
			changeSnap(-1);
		};
		snapDecalDecButton.centerOverlay(snapDecalText, Y);
		add(snapDecalDecButton);

		snapDecalIncButton = new Button(snapDecalText.getRight() + 8, 145, ">", 18, true);
		snapDecalIncButton.camera = hudCamera;
		snapDecalIncButton.onClick = function()
		{
			changeSnap(1);
		};
		snapDecalIncButton.centerOverlay(snapDecalText, Y);
		add(snapDecalIncButton);

		changeSnap();

		hudElements.add(decalList);
		hudElements.add(snapDecalText);
		hudElements.add(snapTitleText);
		hudElements.add(addDecalButton);
		hudElements.add(snapDecalDecButton);
		hudElements.add(snapDecalIncButton);
	}

	public function addCollisionUI():Void
	{
		collisionPropertyBG = new FlxSprite(1250, 100).makeGraphic(300, 290, FlxColor.TRANSPARENT);
		FlxSpriteUtil.drawRoundRect(collisionPropertyBG, 0, 0, collisionPropertyBG.width, collisionPropertyBG.height, 4, 4, bgHudColor);
		collisionPropertyBG.camera = hudCamera;
		add(collisionPropertyBG);

		snapCollisionText = new TextObject(1000, 145, 0, '$collisionSnap', 18);
		snapCollisionText.camera = hudCamera;
		snapTitleText.x = 1150;
		snapCollisionText.centerOverlay(snapTitleText, X);
		add(snapCollisionText);

		snapCollisionDecButton = new Button(snapCollisionText.x, 145, "<", 18, true);
		snapCollisionDecButton.x -= snapCollisionDecButton.width + 8;
		snapCollisionDecButton.camera = hudCamera;
		snapCollisionDecButton.onClick = function()
		{
			changeSnap(-1);
		};
		snapCollisionDecButton.centerOverlay(snapCollisionText, Y);
		add(snapCollisionDecButton);

		snapCollisionIncButton = new Button(snapCollisionText.getRight() + 8, 145, ">", 18, true);
		snapCollisionIncButton.camera = hudCamera;
		snapCollisionIncButton.onClick = function()
		{
			changeSnap(1);
		};
		snapCollisionIncButton.centerOverlay(snapCollisionText, Y);
		add(snapCollisionIncButton);

		collisionXInfo = new TextObject(collisionPropertyBG.x + 30, collisionPropertyBG.y + 30, "X", 14);
		collisionXInfo.camera = hudCamera;
		add(collisionXInfo);

		collisionYInfo = new TextObject(collisionPropertyBG.x + 150, collisionPropertyBG.y + 30, "Y", 14);
		collisionYInfo.camera = hudCamera;
		add(collisionYInfo);

		collisionWidthInfo = new TextObject(collisionPropertyBG.x + 30, collisionPropertyBG.y + 90, "Width", 14);
		collisionWidthInfo.camera = hudCamera;
		add(collisionWidthInfo);

		collisionHeightInfo = new TextObject(collisionPropertyBG.x + 150, collisionPropertyBG.y + 90, "Height", 14);
		collisionHeightInfo.camera = hudCamera;
		add(collisionHeightInfo);

		collisionXStepper = new Stepper(collisionPropertyBG.x + 30, collisionPropertyBG.y + 50, 60, "", function()
		{
			return collisionRect?.x ?? 0.0;
		}, function(value:Float)
		{
			if (collisionRect != null)
			{
				collisionRect.x = value;

				if (collisionRect.resizableSpr != null)
				{
					collisionRect.resizableSpr.x = value;
					collisionRect.resizableSpr.updateSize();
				}
			}
		});

		collisionXStepper.camera = hudCamera;
		add(collisionXStepper);

		collisionYStepper = new Stepper(collisionPropertyBG.x + 150, collisionPropertyBG.y + 50, 60, "", function()
		{
			return collisionRect?.y ?? 0.0;
		}, function(value:Float)
		{
			if (collisionRect != null)
			{
				collisionRect.y = value;

				if (collisionRect.resizableSpr != null)
				{
					collisionRect.resizableSpr.y = value;
					collisionRect.resizableSpr.updateSize();
				}
			}
		});
		collisionYStepper.camera = hudCamera;
		add(collisionYStepper);

		collisionWidthStepper = new Stepper(collisionPropertyBG.x + 30, collisionPropertyBG.y + 110, 60, new FlxBounds<Float>(0, Math.POSITIVE_INFINITY), "",
			function()
			{
				return collisionRect?.width ?? 0;
			}, function(value:Float)
		{
			if (collisionRect != null)
			{
				collisionRect.width = value;

				if (collisionRect.resizableSpr != null)
				{
					collisionRect.resizableSpr.width = value;
					collisionRect.resizableSpr.updateSize();
				}
			}
		});
		collisionWidthStepper.camera = hudCamera;
		add(collisionWidthStepper);

		collisionHeightStepper = new Stepper(collisionPropertyBG.x + 150, collisionPropertyBG.y + 110, 60, new FlxBounds<Float>(0, Math.POSITIVE_INFINITY),
			"", function()
		{
			return collisionRect?.height ?? 0;
		}, function(value:Float)
		{
			if (collisionRect != null)
			{
				collisionRect.height = value;

				if (collisionRect.resizableSpr != null)
				{
					collisionRect.resizableSpr.height = value;
					collisionRect.resizableSpr.updateSize();
				}
			}
		});
		collisionHeightStepper.camera = hudCamera;
		add(collisionHeightStepper);

		collisionTypeSprite = new FlxSprite(Assets.image('_debug/room/collisions/wall'));
		collisionTypeSprite.scale.set(2, 2);
		collisionTypeSprite.updateHitbox();
		collisionTypeSprite.centerOverlay(collisionPropertyBG, XY);
		collisionTypeSprite.y += 60;
		collisionTypeSprite.camera = hudCamera;
		add(collisionTypeSprite);

		inline function setButtonOpacity()
		{
			if (selectedCollisionType > 0)
			{
				collisionWidthStepper.alpha = collisionHeightStepper.alpha = 0.7;
				collisionWidthInfo.alpha = collisionHeightInfo.alpha = 0.7;

				collisionWidthStepper.decrementButton.alpha = collisionWidthStepper.incrementButton.alpha = 0.7;
				collisionHeightStepper.decrementButton.alpha = collisionHeightStepper.incrementButton.alpha = 0.7;
			}
			else
			{
				collisionWidthStepper.alpha = collisionHeightStepper.alpha = 1.0;
				collisionWidthInfo.alpha = collisionHeightInfo.alpha = 1.0;

				collisionWidthStepper.decrementButton.alpha = collisionWidthStepper.incrementButton.alpha = 1.0;
				collisionHeightStepper.decrementButton.alpha = collisionHeightStepper.incrementButton.alpha = 1.0;
			}
		}

		collisionTypeArrowLeft = new Button(collisionTypeSprite.x - 8, "<", 18, true);
		collisionTypeArrowLeft.x -= collisionTypeArrowLeft.width;
		collisionTypeArrowLeft.camera = hudCamera;
		collisionTypeArrowLeft.centerOverlay(collisionTypeSprite, Y);
		collisionTypeArrowLeft.onClick = function()
		{
			selectedCollisionType = FlxMath.wrap(selectedCollisionType - 1, 0, sortedCollisions.length - 1);

			collisionTypeSprite.loadGraphic(Assets.image('_debug/room/collisions/${collisionNames.get(sortedCollisions[selectedCollisionType])}'));
			collisionCursor.pixels = collisionTypeSprite.pixels;

			setButtonOpacity();

			collisionWidthStepper.active = collisionHeightStepper.active = selectedCollisionType == 0;
		};
		add(collisionTypeArrowLeft);

		collisionTypeArrowRight = new Button(collisionTypeSprite.getRight() + 8, ">", 18, true);
		collisionTypeArrowRight.camera = hudCamera;
		collisionTypeArrowRight.centerOverlay(collisionTypeSprite, Y);
		collisionTypeArrowRight.onClick = function()
		{
			selectedCollisionType = FlxMath.wrap(selectedCollisionType + 1, 0, sortedCollisions.length - 1);

			collisionTypeSprite.loadGraphic(Assets.image('_debug/room/collisions/${collisionNames.get(sortedCollisions[selectedCollisionType])}'));
			collisionCursor.pixels = collisionTypeSprite.pixels;

			setButtonOpacity();

			collisionWidthStepper.active = collisionHeightStepper.active = selectedCollisionType == 0;
		};
		add(collisionTypeArrowRight);

		hudElements.add(collisionPropertyBG);
		hudElements.add(snapCollisionText);
		hudElements.add(snapCollisionDecButton);
		hudElements.add(snapCollisionIncButton);
	}

	public function addNodeUI():Void
	{
		nodeList = new ImageList(1320, 100, 240, 226);
		nodeList.camera = hudCamera;
		nodeList.selectTile = function(name:String)
		{
			if (currentNode != name)
			{
				if (name.length > 0)
					nodeCursor.loadGraphic(Assets.image('_debug/room/$name'));
				nodeCursor.visible = name.length > 0;

				onNodeChange(name);
			}
		};
		add(nodeList);

		nodeList.addImage("event", Assets.image("_debug/room/event").bitmap);
		nodeList.addImage("interact", Assets.image("_debug/room/interact").bitmap);
		nodeList.addImage("spawn", Assets.image("_debug/room/spawn").bitmap);
		nodeList.addImage("room", Assets.image("_debug/room/room").bitmap);

		nodeContextBG = new FlxSprite(10, 600).makeGraphic(180, 290, FlxColor.TRANSPARENT);
		FlxSpriteUtil.drawRoundRect(nodeContextBG, 0, 0, nodeContextBG.width, nodeContextBG.height, 4, 4, bgHudColor);
		nodeContextBG.camera = hudCamera;
		add(nodeContextBG);

		nodeTagTitle = new TextObject(14, 614, "Tag", 14);
		nodeTagTitle.camera = hudCamera;
		add(nodeTagTitle);

		nodeTagInput = new TextInput(14, 634, "");
		nodeTagInput.camera = hudCamera;
		add(nodeTagInput);

		nextRoomTitle = new TextObject(14, 674, "Next Room", 14);
		nextRoomTitle.camera = hudCamera;
		add(nextRoomTitle);

		nextRoomInput = new TextInput(14, 694, "");
		nextRoomInput.camera = hudCamera;
		add(nextRoomInput);

		targetSpawnTitle = new TextObject(14, 734, "Spawn Target", 14);
		targetSpawnTitle.camera = hudCamera;
		add(targetSpawnTitle);

		targetSpawnInput = new TextInput(14, 754, "");
		targetSpawnInput.camera = hudCamera;
		add(targetSpawnInput);

		spawnOriginTitle = new TextObject(14, 674, "Spawn Origin", 14);
		spawnOriginTitle.camera = hudCamera;
		add(spawnOriginTitle);

		spawnOriginInput = new TextInput(14, 694, "");
		spawnOriginInput.camera = hudCamera;
		add(spawnOriginInput);

		hudElements.add(nodeList);
		hudElements.add(nodeContextBG);

		onNodeChange("spawn");
		onNodeChange("spawn");
		onNodeChange("room");
		onNodeChange("interact");
		onNodeChange("event");
	}

	public function addLayerUI():Void
	{
		var changeLayerText = function()
		{
			var newText:String = '$selectedLayer';
			if (selectedLayer == -1)
			{
				newText = 'ALL';
			}
			else
			{
				if (selectedLayer >= afterPlayerLayer)
					newText += ' [>]';
				else
					newText += ' [<]';
			}
			layerText.text = newText;
			layerText.updateHitbox();
			layerText.centerOverlay(tilesetList, X);
		}

		// lazy way to determine max width i guess
		layerText = new TextObject(1400, 400, 0, "9999", 18);
		layerText.camera = hudCamera;
		layerText.centerOverlay(tilesetList, X);
		add(layerText);

		layerDecButton = new Button(layerText.x, 400, "<", 18, true);
		layerDecButton.x -= layerDecButton.width + 8;
		layerDecButton.camera = hudCamera;
		layerDecButton.centerOverlay(layerText, Y);
		layerDecButton.onClick = function()
		{
			if (selectedLayer == -1 || selectedLayer > 0)
				changeLayer(selectedLayer == -1 ? 0 : selectedLayer - 1);

			layerAllButton.revive();
			layerAllButton.update(0.0);

			changeLayerText();
		};
		add(layerDecButton);

		layerAllButton = new Button(layerDecButton.x - 8, 400, "<|", 18, true);
		layerAllButton.x -= layerAllButton.width;
		layerAllButton.camera = hudCamera;
		layerAllButton.centerOverlay(layerText, Y);
		layerAllButton.onClick = function()
		{
			changeLayer(-1);

			layerAllButton.kill();

			changeLayerText();
		};
		add(layerAllButton);

		layerIncButton = new Button(layerText.getRight() + 8, 400, ">", 18, true);
		layerIncButton.camera = hudCamera;
		layerIncButton.centerOverlay(layerText, Y);
		layerIncButton.onClick = function()
		{
			changeLayer(selectedLayer + 1);

			layerAllButton.revive();
			layerAllButton.update(0.0);

			changeLayerText();
		};
		add(layerIncButton);

		changeLayerText();

		setLayerPlayerButton = new Button(0, layerText.getBottom() + 16, "Set Layer Above Player", 14);
		setLayerPlayerButton.camera = hudCamera;
		setLayerPlayerButton.centerOverlay(tilesetList, X);
		setLayerPlayerButton.onClick = function()
		{
			if (afterPlayerLayer == selectedLayer)
				return;
			afterPlayerLayer = selectedLayer;

			changeLayerText();
		};
		add(setLayerPlayerButton);

		hudElements.add(layerText);
		hudElements.add(layerAllButton);
		hudElements.add(layerDecButton);
		hudElements.add(layerIncButton);
		hudElements.add(setLayerPlayerButton);
	}

	public function addRoomListUI():Void
	{
		roomListUI = new List(1320, 500, 240);
		roomListUI.camera = hudCamera;
		roomListUI.onClick = function(index:Int)
		{
			if (curRoom != null)
			{
				for (collision in curRoom.collisions)
				{
					if (collision.resizableSpr != null)
					{
						collision.resizableSpr.kill();
					}
				}
			}

			selectedRoom = roomListUI.children[index].textObj.text;

			if ((roomNameInput.customData.exists("modified") && !roomNameInput.customData.get("modified")) || roomNameInput.length == 0)
				roomNameInput.changeText(selectedRoom);

			replace(curRoom, curRoom);

			if (curRoom != null)
			{
				for (collision in curRoom.collisions)
				{
					if (collision == null || collision.type != WALL)
						continue;

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

					var load:Bool = false;

					collision.resizableSpr = collisionSpritePools.recycle(ResizableSprite, function()
					{
						load = true;

						var object:ResizableSprite = new ResizableSprite(collision.x, collision.y, collision.width.floor(), collision.height.floor(), graph,
							false);
						object.canDrag = viewMode == COLLISIONS;

						return object;
					});
					collision.resizableSpr.onModify = function()
					{
						collision.x = collision.resizableSpr.x;
						collision.y = collision.resizableSpr.y;
						collision.width = collision.resizableSpr.width;
						collision.height = collision.resizableSpr.height;

						collisionXStepper.setValue(collision.resizableSpr.x);
						collisionYStepper.setValue(collision.resizableSpr.y);
						collisionWidthStepper.setValue(collision.resizableSpr.width);
						collisionHeightStepper.setValue(collision.resizableSpr.height);

						collisionXStepper.updateValue();
						collisionYStepper.updateValue();
						collisionWidthStepper.updateValue();
						collisionHeightStepper.updateValue();
					}

					if (!load)
						collision.resizableSpr.loadGraphic(graph);

					collision.resizableSpr.setPosition(collision.x, collision.y);
					collision.resizableSpr.setSize(collision.width, collision.height);
					collision.resizableSpr.updateSize();

					collision.resizableSpr.customData.set("parentCollision", collision);
				}
			}

			if (curRoom.cameraLock != null)
			{
				resizableCamSpr.setPosition(curRoom.cameraLock.x, curRoom.cameraLock.y);
				resizableCamSpr.setSize(curRoom.cameraLock.width, curRoom.cameraLock.height);

				if (resizableCamSpr.onModify != null)
					resizableCamSpr.onModify();
				resizableCamSpr.updateSize();
			}
		};
		add(roomListUI);

		newRoomUI = new Button(roomListUI.getRight(), roomListUI.getBottom() + 8, "New Room", 14);
		newRoomUI.x -= newRoomUI.width;
		newRoomUI.camera = hudCamera;
		newRoomUI.onClick = newRoom.bind();
		add(newRoomUI);

		roomNameInput = new TextInput(roomListUI.x, roomListUI.getBottom() + 8, "");
		roomNameInput.camera = hudCamera;
		roomNameInput.onChange = function(name:String)
		{
			if (roomListUI.selected != -1)
				roomListUI.children[roomListUI.selected].textObj.text = roomNameInput.actualText;

			if (curRoom != null)
				curRoom.name = roomNameInput.actualText;

			roomNameInput.customData.set("modified", true);
		};
		roomNameInput.customData.set("modified", false);
		add(roomNameInput);

		saveRoomButton = new Button(roomListUI.getRight(), newRoomUI.getBottom() + 8, "Save Room", 14);
		saveRoomButton.x -= saveRoomButton.width;
		saveRoomButton.camera = hudCamera;
		saveRoomButton.onClick = saveRoom;
		add(saveRoomButton);

		hudElements.add(roomListUI);
		hudElements.add(newRoomUI);
		hudElements.add(roomNameInput);
		hudElements.add(saveRoomButton);
	}

	public function changeLayer(newLayer:Int = 0)
	{
		if (selectedLayer != newLayer)
		{
			for (i in 0...curRoom.grid.length)
			{
				if (curRoom.grid[i] != null)
					curRoom.grid[i].alpha = (i == newLayer || newLayer == -1) ? 1.0 : 0.6;
			}

			selectedLayer = newLayer;
		}
	}

	public function changeSnap(change:Int = 0)
	{
		if (viewMode == DECALS)
		{
			decalSnap += change;

			decalSnap = FlxMath.bound(decalSnap, 1, 100).floor();

			snapDecalText.text = '$decalSnap';
			snapDecalText.updateHitbox();
			snapDecalText.centerOverlay(snapTitleText, X);
		}
		else if (viewMode == COLLISIONS)
		{
			collisionSnap += change;

			collisionSnap = FlxMath.bound(collisionSnap, 1, 100).floor();

			snapCollisionText.text = '$collisionSnap';
			snapCollisionText.updateHitbox();
			snapCollisionText.centerOverlay(snapTitleText, X);
		}
	}

	public function selectNewMode(newMode:ViewMode)
	{
		switch (viewMode)
		{
			case TILES:
				{
					tileModeButton.active = true;
					tileModeButton.update(0);

					tileCursor.kill();
					tilesetList.kill();
					addTilesButton.kill();
					tileNameInput.kill();
				}
			case DECALS:
				{
					decalModeButton.active = true;
					decalModeButton.update(0);

					decalCursor.kill();

					decalList.kill();
					addDecalButton.kill();

					snapTitleText.kill();
					snapDecalText.kill();
					snapDecalDecButton.kill();
					snapDecalIncButton.kill();
				}
			case COLLISIONS:
				{
					collisionModeButton.active = true;
					collisionModeButton.update(0);

					collisionCursor.kill();

					collisionPropertyBG.kill();

					snapTitleText.kill();
					snapCollisionText.kill();
					snapCollisionDecButton.kill();
					snapCollisionIncButton.kill();

					collisionXInfo.kill();
					collisionYInfo.kill();
					collisionWidthInfo.kill();
					collisionHeightInfo.kill();

					collisionXStepper.kill();
					collisionYStepper.kill();
					collisionWidthStepper.kill();
					collisionHeightStepper.kill();

					collisionTypeSprite.kill();
					collisionTypeArrowLeft.kill();
					collisionTypeArrowRight.kill();

					if (collisionRect != null)
					{
						collisionRect.editorSelected = false;

						if (collisionRect?.resizableSpr != null)
							collisionRect.resizableSpr.canDrag = false;

						collisionRect = null;
					}
				}
			case NODES:
				{
					nodeModeButton.active = true;
					nodeModeButton.update(0);

					nodeCursor.kill();

					nodeList.kill();
					nodeContextBG.kill();

					nodeTagTitle.kill();
					nodeTagInput.kill();

					onNodeChange("");
				}
		}

		switch (newMode)
		{
			case TILES:
				{
					tileModeButton.active = false;
					tileModeButton.color = tileModeButton.pressColor;

					tileCursor.revive();
					tilesetList.revive();
					addTilesButton.revive();
					tileNameInput.revive();
				}
			case DECALS:
				{
					decalModeButton.active = false;
					decalModeButton.color = decalModeButton.pressColor;

					decalCursor.revive();

					decalList.revive();
					addDecalButton.revive();

					snapTitleText.revive();
					snapDecalText.revive();
					snapDecalDecButton.revive();
					snapDecalIncButton.revive();

					snapTitleText.x = 1200;
				}
			case COLLISIONS:
				{
					collisionModeButton.active = false;
					collisionModeButton.color = collisionModeButton.pressColor;

					collisionCursor.revive();

					snapTitleText.revive();
					snapCollisionText.revive();
					snapCollisionDecButton.revive();
					snapCollisionIncButton.revive();

					collisionPropertyBG.revive();

					collisionXInfo.revive();
					collisionYInfo.revive();
					collisionWidthInfo.revive();
					collisionHeightInfo.revive();

					collisionXStepper.revive();
					collisionYStepper.revive();
					collisionWidthStepper.revive();
					collisionHeightStepper.revive();

					collisionTypeSprite.revive();
					collisionTypeArrowLeft.revive();
					collisionTypeArrowRight.revive();

					if (collisionRect?.resizableSpr != null)
						collisionRect.resizableSpr.canDrag = true;

					snapTitleText.x = 1150;
				}
			case NODES:
				{
					nodeModeButton.active = false;
					nodeModeButton.color = nodeModeButton.pressColor;

					nodeCursor.revive();

					nodeList.revive();
					nodeContextBG.revive();

					nodeTagTitle.revive();
					nodeTagInput.revive();

					var actualNode:String = currentNode;

					nodeList.selectTile("spawn");
					nodeList.selectTile("room");
					nodeList.selectTile("interact");
					nodeList.selectTile("event");

					nodeList.selectTile(actualNode);
					onNodeChange(actualNode);
				}
		}

		switch (newMode)
		{
			case TILES:
				tileCursor.exists = cursorVisible;
			case DECALS:
				decalCursor.exists = cursorVisible;
			case COLLISIONS:
				collisionCursor.exists = cursorVisible;
			case NODES:
				nodeCursor.exists = cursorVisible;
		}

		if (newMode == COLLISIONS)
		{
			emptyInfoText = true;
			changeInfoText = false;
		}

		viewMode = newMode;
	}

	private var _lastGridPos:FlxPoint = FlxPoint.get();
	private var _lastDragPos:FlxPoint = FlxPoint.get();
	private var _lastDecalPos:FlxPoint = FlxPoint.get();
	private var _lastWorldTileDragPos:FlxPoint = FlxPoint.get();
	private var _lastWorldDecalDragPos:FlxPoint = FlxPoint.get();

	public var holdingSelected:Bool = false;

	// used for info text
	public var gridTileNames:Array<String> = [];
	public var gridDecalNames:Array<String> = [];
	public var gridNodeNames:Array<String> = [];

	public var nodeTagCount:Map<String, Int> = [];

	public var layerList:Array<Int> = [];

	public var changeInfoText:Bool = false;
	public var emptyInfoText:Bool = false;

	public var draggingSpr:Bool = false;

	override public function update(elapsed:Float)
	{
		draggingSpr = FlxG.mouse.pressedRight;

		gridTileNames.splice(0, gridTileNames.length);
		gridDecalNames.splice(0, gridDecalNames.length);
		gridNodeNames.splice(0, gridNodeNames.length);
		nodeTagCount.clear();

		layerList.splice(0, layerList.length);
		changeInfoText = false;
		emptyInfoText = false;

		if (collisionRect?.resizableSpr != null)
			collisionRect.resizableSpr.update(elapsed);

		if (FlxG.mouse.justPressedRight && viewMode != COLLISIONS)
		{
			FlxG.mouse.getWorldPosition(mainCamera, _lastDragPos);

			var snap:Int = 20;

			if (viewMode != TILES)
			{
				if (viewMode == DECALS)
					snap = decalSnap;
				else if (viewMode == NODES)
					snap = nodeSnap;
			}

			if (snap > 1)
			{
				_lastDragPos.x /= snap;
				_lastDragPos.y /= snap;

				_lastDragPos.floor();
			}

			dragSpr.revive();
			dragSpr.setPosition(_lastDragPos.x * snap, _lastDragPos.y * snap);

			dragSpr.setGraphicSize(1, 1);
			dragSpr.updateHitbox();

			if (viewMode == TILES)
				tileCursor.visible = false;
			else if (viewMode == DECALS)
				decalCursor.visible = false;
			else if (viewMode == NODES)
				nodeCursor.visible = false;
		}

		if (!FlxG.mouse.overlaps(hudElements, hudCamera))
		{
			if (FlxG.mouse.justPressed && (selectedTiles.length > 0 || selectedDecals.length > 0 || collisionRect != null))
			{
				if (collisionRect?.resizableSpr != null && !collisionRect.resizableSpr.mouseOverlaps())
				{
					collisionRect.editorSelected = false;
					collisionRect.resizableSpr.canDrag = false;

					collisionRect = null;
				}

				if (selectedTiles.length > 0)
				{
					for (tile in selectedTiles)
					{
						if (FlxG.mouse.x >= (tile.tileX * 20).floor()
							&& FlxG.mouse.y >= (tile.tileY * 20).floor()
								&& FlxG.mouse.x <= (tile.tileX * 20).floor() + 20 && FlxG.mouse.y <= (tile.tileY * 20).floor() + 20)
						{
							holdingSelected = true;
							break;
						}
					}
				}

				if (!holdingSelected && selectedDecals.length > 0)
				{
					for (decal in selectedDecals)
					{
						if (FlxG.mouse.x >= decal.x
							&& FlxG.mouse.y >= decal.y
							&& FlxG.mouse.x <= decal.x + decal.graphReplacement.width
							&& FlxG.mouse.y <= decal.y + decal.graphReplacement.height)
						{
							holdingSelected = true;
							break;
						}
					}
				}

				if (!holdingSelected)
				{
					var i:Int = selectedTiles.length;

					if (viewMode == TILES)
					{
						if (i != 0)
						{
							while (i >= 0)
							{
								var tile:Tile = selectedTiles[i];
								if (tile != null)
									tile.editorSelected = false;
								selectedTiles.splice(i, 1);
								i--;
							}

							selectedTiles = [];
						}
					}

					if (viewMode == DECALS)
					{
						i = selectedDecals.length;

						if (i != 0)
						{
							while (i >= 0)
							{
								var decal:Decal = selectedDecals[i];
								if (decal != null)
									decal.editorSelected = false;
								selectedDecals.splice(i, 1);
								i--;
							}

							selectedDecals = [];
						}

						i = selectedNodes.length;

						if (i != 0)
						{
							while (i >= 0)
							{
								var node:Node = selectedNodes[i];
								if (node != null)
									node.editorSelected = false;
								selectedNodes.splice(i, 1);
								i--;
							}

							selectedNodes = [];
						}
					}
				}
				else
				{
					FlxG.mouse.getWorldPosition(mainCamera, _lastWorldTileDragPos);

					_lastWorldTileDragPos.x /= 20;
					_lastWorldTileDragPos.y /= 20;

					_lastWorldTileDragPos.floor();

					FlxG.mouse.getWorldPosition(mainCamera, _lastWorldDecalDragPos);

					if (viewMode == TILES)
						tileCursor.visible = false;
					else if (viewMode == DECALS)
						decalCursor.visible = false;
					else if (viewMode == NODES)
						nodeCursor.visible = false;
				}
			}
			else
			{
				if (curRoom == null)
				{
					if (FlxG.mouse.pressed && !FlxG.mouse.overlaps(hudElements))
						FlxG.log.error("You need to have an existing room first.");
				}
				else
				{
					switch (viewMode)
					{
						case TILES:
							{
								if (cursorVisible && !draggingSpr && !holdingSelected)
								{
									FlxG.mouse.getWorldPosition(mainCamera, gridPos);
									gridPos.x /= 20;
									gridPos.y /= 20;

									gridPos.floor();

									tileCursor.setPosition(gridPos.x * 20, gridPos.y * 20);

									if (tilesetList.selected != -1)
									{
										if (quickPlace && FlxG.mouse.pressed)
										{
											var tile:Tile = {
												graphic: tilesetList.bitmapList[tilesetList.selected].customData.get("name"),
												tileX: gridPos.x.floor(),
												tileY: gridPos.y.floor(),
												tileLayer: (selectedLayer == -1 ? 0 : selectedLayer)
											};

											if (FlxG.mouse.justPressed
												|| (!_lastGridPos.equals(gridPos)
													&& !curRoom.tileEquals(tile, curRoom.getTile(tile.tileLayer, tile.tileX, tile.tileY))))
											{
												tile.graphReplacement = FlxGraphic.fromBitmapData(tileCursor.pixels);
												curRoom.addTile(tile, true);
											}
										}
										else if (!quickPlace && FlxG.mouse.justPressed)
										{
										}
									}

									if (!_lastGridPos.equals(gridPos))
									{
										if (gridPos.x < 0 || gridPos.y < 0)
											coordLocation.color = FlxColor.RED;
										else
											coordLocation.color = FlxColor.WHITE;

										coordLocation.text = 'X: ${gridPos.x}, Y: ${gridPos.y}';
										coordLocation.updateHitbox();

										coordLocation.setPosition(FlxG.width - (coordLocation.width + 4), FlxG.height - (coordLocation.height + 4));
									}

									_lastGridPos.copyFrom(gridPos);
								}
							}
						case DECALS:
							{
								if (cursorVisible && !draggingSpr && !holdingSelected)
								{
									FlxG.mouse.getWorldPosition(mainCamera, decalPos);

									var topLeftPos:FlxPoint = decalPos.clone();
									topLeftPos /= decalSnap;

									topLeftPos.floor();

									decalPos.subtract(decalCursor.width / 2, decalCursor.height / 2);
									decalPos.x /= decalSnap;
									decalPos.y /= decalSnap;

									decalPos.floor();

									decalCursor.setPosition(decalPos.x * decalSnap, decalPos.y * decalSnap);

									if (decalList.selected != -1 && FlxG.mouse.justPressed)
									{
										var decal:Decal = {
											graphic: decalList.children[decalList.selected].customData.get("name"),
											x: decalCursor.x,
											y: decalCursor.y,
											scrollX: 1.0,
											scrollY: 1.0,
											layer: (selectedLayer == -1 ? 0 : selectedLayer)
										};

										decal.graphReplacement = decalCursor.graphic;
										curRoom.addDecal(decal);
									}

									if (!_lastDecalPos.equals(decalPos))
									{
										coordLocation.color = FlxColor.WHITE;

										coordLocation.text = '(TOP LEFT) X: ${topLeftPos.x}, Y: ${topLeftPos.y} || X: ${decalPos.x}, Y: ${decalPos.y}';
										coordLocation.updateHitbox();

										coordLocation.setPosition(FlxG.width - (coordLocation.width + 4), FlxG.height - (coordLocation.height + 4));
									}

									_lastDecalPos.copyFrom(decalPos);
								}
							}
						case COLLISIONS:
							{
								FlxG.mouse.getWorldPosition(mainCamera, collisionPos);

								collisionPos /= collisionSnap;
								collisionPos.floor();

								collisionCursor.setPosition(collisionPos.x * collisionSnap, collisionPos.y * collisionSnap);

								if (FlxG.mouse.justPressed && !collisionSpritePools.members.foreach(function(item:ResizableSprite)
								{
									return FlxG.mouse.overlaps(item);
								}))
								{
									if (FlxG.keys.pressed.CONTROL)
									{
										var mousePoint:FlxPoint = FlxG.mouse.getWorldPosition();

										for (collision in curRoom.collisions)
										{
											if (mousePoint.x >= collision.x && mousePoint.x <= collision.x + collision.width)
											{
												if (mousePoint.y >= collision.y && mousePoint.y <= collision.y + collision.height)
												{
													collisionRect = collision;
													collision.editorSelected = true;

													if (collision.resizableSpr != null)
														collision.resizableSpr.canDrag = true;

													break;
												}
											}
										}
									}
									else if (cursorVisible)
									{
										if (collisionRect != null)
										{
											collisionRect.editorSelected = false;

											if (collisionRect?.resizableSpr != null)
												collisionRect.resizableSpr.canDrag = false;

											collisionRect = null;
										}

										var collision:Collision = {
											x: collisionCursor.x,
											y: collisionCursor.y,
											width: 20,
											height: 20,
											type: sortedCollisions[selectedCollisionType]
										};
										collisionRect = collision;
										collision.editorSelected = true;
										curRoom.addCollision(collision);
									}

									if (collisionRect != null)
									{
										collisionXStepper.setValue(Math.floor(collisionRect.x));
										collisionYStepper.setValue(Math.floor(collisionRect.y));
										collisionWidthStepper.setValue(Math.floor(collisionRect.width));
										collisionHeightStepper.setValue(Math.floor(collisionRect.height));

										collisionXStepper.decrementButton.onClick();
										collisionXStepper.incrementButton.onClick();

										collisionYStepper.decrementButton.onClick();
										collisionYStepper.incrementButton.onClick();

										collisionWidthStepper.decrementButton.onClick();
										collisionWidthStepper.incrementButton.onClick();

										collisionHeightStepper.decrementButton.onClick();
										collisionHeightStepper.incrementButton.onClick();

										if (collisionRect.resizableSpr != null)
										{
											collisionRect.resizableSpr.setPosition(collisionRect.resizableSpr.x, collisionRect.resizableSpr.y);
											collisionRect.resizableSpr.setSize(collisionRect.resizableSpr.width, collisionRect.resizableSpr.height);

											if (collisionRect.resizableSpr.onModify != null)
												collisionRect.resizableSpr.onModify();
											collisionRect.resizableSpr.updateSize();
										}
									}
								}
							}
						case NODES:
							{
								if (cursorVisible)
								{
									FlxG.mouse.getWorldPosition(mainCamera, nodePos);
									nodePos /= 5;

									nodePos.floor();

									nodeCursor.setPosition(nodePos.x * 5, nodePos.y * 5);

									if (nodeList.selected != -1 && FlxG.mouse.justPressed)
									{
										var preventPlace:Bool = false;
										var tag:String = "";
										var contextData:Array<Dynamic> = [];

										switch (currentNode)
										{
											case "spawn":
												{}
											case "room":
												{
													if (nextRoomInput?.actualText.length > 0)
														contextData.push(nextRoomInput.actualText);
												}
										}

										tag = nodeTagInput.actualText;

										if (nodeTagInput.length == 0)
										{
											preventPlace = true;
											FlxG.log.error("You need to have a tag for this node.");
										}

										if (!preventPlace)
										{
											var node:Node = {
												x: nodeCursor.x,
												y: nodeCursor.y,
												tag: tag,
												type: Room.nodeTypes.indexOf(currentNode),
												contexts: contextData
											};

											node.graphReplacement = nodeCursor.graphic;
											curRoom.addNode(node);
										}
									}
								}
							}
						default:
							{}
					}
				}
			}

			if (holdingSelected)
			{
				if (FlxG.mouse.pressed && FlxG.mouse.justMoved)
				{
					var tileOffset:FlxPoint = FlxG.mouse.getWorldPosition(mainCamera);
					var decalOffset:FlxPoint = tileOffset.clone();

					tileOffset.x /= 20;
					tileOffset.y /= 20;

					tileOffset.floor();

					decalOffset.x /= decalSnap;
					decalOffset.y /= decalSnap;

					decalOffset.floor();

					decalOffset *= decalSnap;
					decalOffset.floor();

					if (tileOffset.x > 0 && tileOffset.y > 0)
					{
						if (!_lastWorldTileDragPos.equals(tileOffset))
						{
							for (tile in selectedTiles)
							{
								curRoom.removeTile(tile);
								tile.tileX = (tile.tileX + (tileOffset.x - _lastWorldTileDragPos.x)).floor();
								tile.tileY = (tile.tileY + (tileOffset.y - _lastWorldTileDragPos.y)).floor();
								curRoom.addTile(tile);
							}
						}

						_lastWorldTileDragPos.copyFrom(tileOffset);
					}

					if (!_lastWorldDecalDragPos.equals(decalOffset))
					{
						for (decal in selectedDecals)
						{
							decal.x = (decal.x + (decalOffset.x - _lastWorldDecalDragPos.x)).floor();
							decal.y = (decal.y + (decalOffset.y - _lastWorldDecalDragPos.y)).floor();
						}
					}

					_lastWorldDecalDragPos.copyFrom(decalOffset);
				}
				else if (!FlxG.mouse.pressed)
					holdingSelected = false;
			}

			mainCamera.fromWheelZoom(0.1, 0.75, 5);

			if (FlxG.keys.anyPressed([W, A, S, D]))
			{
				var up:Bool = FlxG.keys.pressed.W;
				var down:Bool = FlxG.keys.pressed.S;

				if (up && down)
					up = down = false;

				var left:Bool = FlxG.keys.pressed.A;
				var right:Bool = FlxG.keys.pressed.D;

				if (left && right)
					left = right = false;

				if (right)
					camSpeed.x = speed;
				else if (left)
					camSpeed.x = -speed;

				if (down)
					camSpeed.y = speed;
				else if (up)
					camSpeed.y = -speed;

				var magnitude = camSpeed.length;
				if (magnitude > speed)
					camSpeed.scale(speed / magnitude);

				FlxG.camera.scroll.add(camSpeed.x * elapsed * 7, camSpeed.y * elapsed * 7);

				camSpeed.set();
			}
		}

		if (draggingSpr && (FlxG.mouse.justMoved || FlxG.mouse.justPressedRight))
		{
			var dragPos:FlxPoint = FlxG.mouse.getWorldPosition(mainCamera);

			var snap:Int = 20;

			if (viewMode != TILES)
			{
				if (viewMode == DECALS)
					snap = decalSnap;
				else if (viewMode == COLLISIONS)
					snap = 1;
				else if (viewMode == NODES)
					snap = nodeSnap;
			}

			if (snap > 1)
			{
				dragPos.x /= snap;
				dragPos.y /= snap;

				dragPos.floor();
			}

			var rectangle:FlxRect = FlxRect.get().fromTwoPoints(dragPos, _lastDragPos);
			rectangle.width += 1;
			rectangle.height += 1;

			dragSpr.setPosition(rectangle.x * snap, rectangle.y * snap);
			dragSpr.setGraphicSize(rectangle.width * snap, rectangle.height * snap);
			dragSpr.updateHitbox();

			rectangle.put();
		}
		else if (FlxG.mouse.justReleasedRight && viewMode != COLLISIONS && curRoom != null)
		{
			if (viewMode == TILES)
				tileCursor.visible = true;
			if (viewMode == DECALS)
				decalCursor.visible = true;
			if (viewMode == NODES)
				nodeCursor.visible = nodeList.selected != -1;

			var dragPos:FlxPoint = FlxG.mouse.getWorldPosition(mainCamera);

			dragPos.x /= 20;
			dragPos.y /= 20;

			dragPos.floor();

			var rectangle:FlxRect = FlxRect.get().fromTwoPoints(dragPos, _lastDragPos);

			var diff:FlxPoint = FlxPoint.get(rectangle.x, rectangle.y);

			rectangle.x = Math.max(0, rectangle.x);
			rectangle.y = Math.max(0, rectangle.y);

			diff.subtract(rectangle.x, rectangle.y);
			diff.set(Math.abs(diff.x), Math.abs(diff.y));

			rectangle.setSize(rectangle.width - diff.x, rectangle.height - diff.y);

			diff.put();

			rectangle.floor();

			if (!FlxG.keys.pressed.SHIFT)
			{
				var i:Int = selectedTiles.length;

				if (i != 0)
				{
					while (i >= 0)
					{
						var tile:Tile = selectedTiles[i];
						if (tile != null)
							tile.editorSelected = false;
						selectedTiles.splice(i, 1);
						i--;
					}

					selectedTiles = [];
				}

				var i = selectedDecals.length;

				if (i != 0)
				{
					while (i >= 0)
					{
						var decal:Decal = selectedDecals[i];
						if (decal != null)
							decal.editorSelected = false;
						selectedDecals.splice(i, 1);
						i--;
					}

					selectedDecals = [];
				}

				var i = selectedNodes.length;

				if (i != 0)
				{
					while (i >= 0)
					{
						var node:Node = selectedNodes[i];
						if (node != null)
							node.editorSelected = false;
						selectedNodes.splice(i, 1);
						i--;
					}

					selectedNodes = [];
				}
			}

			if (selectedLayer == -1)
			{
				for (i in 0...curRoom.grid.length)
					iterateOverGrid(i, rectangle);
			}
			else
				iterateOverGrid(selectedLayer, rectangle);

			dragSpr.kill();

			rectangle.put();
		}

		if (FlxG.keys.justPressed.DELETE)
		{
			if (viewMode == COLLISIONS && collisionRect != null)
			{
				if (collisionRect.resizableSpr != null)
				{
					collisionRect.resizableSpr.kill();
					collisionRect.resizableSpr = null;
				}

				curRoom.removeCollision(collisionRect, true);
				collisionRect = null;

				collisionXStepper.setValue(0.0);
				collisionYStepper.setValue(0.0);
				collisionWidthStepper.setValue(0);
				collisionHeightStepper.setValue(0);

				collisionXStepper.decrementButton.onClick();
				collisionXStepper.incrementButton.onClick();

				collisionYStepper.decrementButton.onClick();
				collisionYStepper.incrementButton.onClick();

				collisionWidthStepper.decrementButton.onClick();
				collisionWidthStepper.incrementButton.onClick();

				collisionHeightStepper.decrementButton.onClick();
				collisionHeightStepper.incrementButton.onClick();
			}

			if (selectedTiles.length != 0)
			{
				for (tile in selectedTiles)
				{
					var index:Int = selectedTiles.indexOf(tile);

					if (index == -1 || tile == null)
						continue;

					curRoom.removeTile(tile);
				}

				selectedTiles.splice(0, selectedTiles.length);
			}

			if (selectedDecals.length != 0)
			{
				for (decal in selectedDecals)
				{
					var index:Int = selectedDecals.indexOf(decal);

					if (index == -1 || decal == null)
						continue;

					curRoom.removeDecal(decal, true);
				}

				selectedDecals.splice(0, selectedDecals.length);
			}

			if (selectedNodes.length != 0)
			{
				for (node in selectedNodes)
				{
					var index:Int = selectedNodes.indexOf(node);

					if (index == -1 || node == null)
						continue;

					curRoom.removeNode(node, true);
				}

				selectedNodes.splice(0, selectedNodes.length);
			}

			emptyInfoText = true;
		}

		var infoString:String = "";
		var lineLength:Int = 0;

		if (changeInfoText)
		{
			if (viewMode == NODES && selectedNodes.length > 0)
			{
				infoString = "Nodes: ";
				infoString += '${selectedNodes.length}\n';

				if (gridNodeNames.length > 0)
				{
					infoString += "Tags: ";
					for (tag in gridNodeNames)
					{
						infoString += tag;

						if (gridNodeNames.indexOf(tag) != gridNodeNames.length - 1)
							infoString += ", ";
					}
				}

				infoString += '\n';

				var uniques:Array<String> = [];

				for (item in Room.nodeTypes)
				{
					for (node in selectedNodes)
					{
						if (Room.nodeTypes[node.type] == item)
						{
							if (!uniques.contains(item))
							{
								infoString += '\n${item.toUpperCase()}: \n';
								uniques.push(item);
							}

							switch (item)
							{
								case "spawn":
									{}
								case "room":
									{
										infoString += node.contexts[0];
									}
							}

							if (selectedNodes.indexOf(node) != selectedNodes.length - 1)
								infoString += ', ';
						}
						else
							continue;
					}
				}
			}
			else if (selectedTiles.length > 0 || selectedDecals.length > 0)
			{
				if (gridTileNames.length > 0)
				{
					infoString = "Tile Names: ";
					for (tileName in gridTileNames)
					{
						if (lineLength > 128)
						{
							lineLength = 0;
							infoString += "\n";
						}
						infoString += tileName;

						if (gridTileNames.indexOf(tileName) != gridTileNames.length - 1)
							infoString += ", ";

						lineLength += tileName.length + 2;
					}
				}

				infoString += "\n";

				if (gridDecalNames.length > 0)
				{
					infoString += "Decal Names: ";
					for (decalName in gridDecalNames)
					{
						if (lineLength > 128)
						{
							lineLength = 0;
							infoString += "\n";
						}
						infoString += decalName;

						if (gridDecalNames.indexOf(decalName) != gridDecalNames.length - 1)
							infoString += ", ";

						lineLength += decalName.length + 2;
					}
				}

				lineLength = 0;

				if (infoString.length > 0)
					infoString += '\n';

				if (layerList.length > 0)
				{
					infoString += "Layers: ";
					for (layerObj in layerList)
					{
						if (lineLength > 32)
						{
							lineLength = 0;
							infoString += "\n";
						}
						infoString += '$layerObj';

						if (layerList.indexOf(layerObj) != layerList.length - 1)
							infoString += ", ";

						lineLength += 2;
					}
				}

				if (infoString.length > 0)
					infoString += '\n';

				if (selectedTiles.length > 0)
					infoString += 'Tiles: ${selectedTiles.length}\n';
				if (selectedDecals.length > 0)
					infoString += 'Decals: ${selectedDecals.length}\n';
			}
			else
				emptyInfoText = true;
		}

		if (emptyInfoText)
		{
			infoText.text = "";
			infoText.updateHitbox();
		}
		else if (changeInfoText)
		{
			infoText.text = infoString;
			infoText.updateHitbox();
		}

		if (tileCursor.visible)
			tileCursor.alpha = 0.9 - ((Math.cos(stateTime * 6.5)) * 0.5);
		if (decalCursor.visible)
			decalCursor.alpha = 0.9 - ((Math.cos(stateTime * 6.5)) * 0.5);
		if (collisionCursor.visible)
			collisionCursor.alpha = 0.9 - ((Math.cos(stateTime * 6.5)) * 0.5);
		if (nodeCursor.visible)
			nodeCursor.alpha = 0.9 - ((Math.cos(stateTime * 6.5)) * 0.5);

		super.update(elapsed);
	}

	public override function draw()
	{
		if (roomList.exists(selectedRoom))
			roomList.get(selectedRoom).draw(); // brute-force
		super.draw();
	}

	public function onNodeChange(newNode:String)
	{
		switch (currentNode)
		{
			case "event":
				{}
			case "interact":
				{}
			case "room":
				{
					nextRoomTitle.kill();
					nextRoomInput.kill();

					targetSpawnTitle.kill();
					targetSpawnInput.kill();
				}
			case "spawn":
				{
					spawnOriginTitle.kill();
					spawnOriginInput.kill();
				}
		}

		switch (newNode)
		{
			case "event":
				{}
			case "interact":
				{}
			case "room":
				{
					nextRoomTitle.revive();
					nextRoomInput.revive();

					targetSpawnTitle.revive();
					targetSpawnInput.revive();
				}
			case "spawn":
				{
					spawnOriginTitle.revive();
					spawnOriginInput.revive();
				}
		}

		currentNode = newNode;
	}

	private function iterateOverGrid(layer:Int = 0, rectangle:FlxRect)
	{
		var actualRect:FlxRect = FlxRect.get(dragSpr.x, dragSpr.y, dragSpr.width, dragSpr.height);

		for (i in 0...curRoom.nodes.length)
		{
			var node:Node = curRoom.nodes[i];

			var nodeRect:FlxRect = FlxRect.get(node.x, node.y, 20, 20);

			if (actualRect.overlaps(nodeRect) && selectedNodes.indexOf(node) == -1)
			{
				node.editorSelected = true;
				selectedNodes.push(node);

				if (!gridNodeNames.contains(node.tag))
					gridNodeNames.push(node.tag);

				changeInfoText = true;
			}

			nodeRect.put();
		}

		if (viewMode != COLLISIONS && viewMode != NODES)
		{
			for (tileX in rectangle.x.floor()...(rectangle.x + rectangle.width + 1).floor())
			{
				if (curRoom.grid[layer] != null && curRoom.grid[layer].tiles[tileX] != null && curRoom.grid[layer].tiles[tileX].length > 0)
				{
					for (tileY in rectangle.y.floor()...(rectangle.y + rectangle.height + 1).floor())
					{
						var tile:Tile = curRoom.grid[layer].tiles[tileX][tileY];
						if (tile != null && selectedTiles.indexOf(tile) == -1)
						{
							tile.editorSelected = true;
							selectedTiles.push(curRoom.grid[layer].tiles[tileX][tileY]);

							if (!gridTileNames.contains(tile.graphic))
								gridTileNames.push(tile.graphic);

							if (!layerList.contains(tile.tileLayer))
								layerList.push(tile.tileLayer);

							changeInfoText = true;
						}
					}
				}
			}

			if (curRoom.grid[layer] != null && curRoom.grid[layer].decals.length > 0)
			{
				for (decal in curRoom.grid[layer].decals)
				{
					if (decal != null && selectedDecals.indexOf(decal) == -1)
					{
						var decalRect:FlxRect = FlxRect.get(decal.x * decal.scrollX, decal.y * decal.scrollY, decal.graphReplacement.width,
							decal.graphReplacement.height);

						if (actualRect.overlaps(decalRect))
						{
							decal.editorSelected = true;
							selectedDecals.push(decal);

							if (!gridDecalNames.contains(decal.graphic))
								gridDecalNames.push(decal.graphic);

							if (!layerList.contains(decal.layer))
								layerList.push(decal.layer);

							changeInfoText = true;
						}

						decalRect.put();
					}
				}
			}
		}
	}

	public function newRoom(?text:String):Void
	{
		if (text == null)
			text = roomNameInput.actualText;

		selectedRoom = text;

		if (text.length == 0)
		{
			FlxG.log.error("Room name can't be empty");
			return;
		}

		if (roomList.exists(text))
		{
			FlxG.log.error("A room of that name already exists.");
			return;
		}

		var roomInstance:Room = new Room();
		roomInstance.name = text;
		roomList.set(text, roomInstance);

		if (roomListUI != null)
		{
			roomListUI.add(text, roomListUI.children.length);

			var button = roomListUI.children[roomListUI.children.length - 1];
			button.status = 2;
			button.update(0);

			roomListUI.refreshList();
		}
	}

	public function saveRoom()
	{
		var data:RoomFile = {};

		data.name = curRoom.name;
		if (curRoom.cameraLock != null)
			data.cameraLock = {
				x: curRoom.cameraLock.x,
				y: curRoom.cameraLock.y,
				width: curRoom.cameraLock.width,
				height: curRoom.cameraLock.height
			};

		for (i in 0...curRoom.grid.length)
		{
			// layer
			for (layer in curRoom.grid)
			{
				// tiles
				for (row in curRoom.grid[i].tiles)
				{
					if (row != null)
					{
						for (tile in row)
						{
							if (tile == null)
								continue;

							if (data.tiles == null)
								data.tiles = [];

							data.tiles.push({
								x: tile.tileX,
								y: tile.tileY,
								img: tile.graphic,
								layer: tile.tileLayer
							});
						}
					}
				}

				// decals
				for (decal in curRoom.grid[i].decals)
				{
					if (data.decals == null)
						data.decals = [];

					data.decals.push({
						x: decal.x,
						y: decal.y,
						img: decal.graphic,
						layer: decal.layer,
						scrollX: 1.0,
						scrollY: 1.0
					});
				}

				// collisions
				for (collision in curRoom.collisions)
				{
					if (data.collisions == null)
						data.collisions = [];

					data.collisions.push({
						x: collision.x,
						y: collision.y,
						width: collision.width,
						height: collision.height,
						type: cast collision.type
					});
				}

				// nodes
				for (node in curRoom.nodes)
				{
					if (data.nodes == null)
						data.nodes = [];

					data.nodes.push({
						x: node.x,
						y: node.y,
						tag: node.tag,
						type: node.type,
						context: node.contexts
					});
				}
			}
		}

		file = new File();

		file.addEventListener(Event.COMPLETE, onComplete);
		file.addEventListener(Event.CANCEL, onCancel);
		file.addEventListener(IOErrorEvent.IO_ERROR, onError);

		file.save(Json.stringify(data, "\t"), '${curRoom.name}.json');
	}

	private function onComplete(e:Event)
	{
		if (file?.hasEventListener(Event.SELECT))
			file?.removeEventListener(Event.SELECT, onSelect);
		if (file?.hasEventListener(FileListEvent.SELECT_MULTIPLE))
			file?.removeEventListener(FileListEvent.SELECT_MULTIPLE, onSelectMultiple);
		file?.removeEventListener(Event.COMPLETE, onComplete);
		file?.removeEventListener(Event.CANCEL, onCancel);
		file?.removeEventListener(IOErrorEvent.IO_ERROR, onError);

		file = null;
	}

	private function onSelect(e:Event)
	{
		if (file?.hasEventListener(Event.SELECT))
			file?.removeEventListener(Event.SELECT, onSelect);
		if (file?.hasEventListener(FileListEvent.SELECT_MULTIPLE))
			file?.removeEventListener(FileListEvent.SELECT_MULTIPLE, onSelectMultiple);
		file?.removeEventListener(Event.COMPLETE, onComplete);
		file?.removeEventListener(Event.CANCEL, onCancel);
		file?.removeEventListener(IOErrorEvent.IO_ERROR, onError);

		file = null;
	}

	private function onSelectMultiple(e:FileListEvent)
	{
		if (file?.hasEventListener(Event.SELECT))
			file?.removeEventListener(Event.SELECT, onSelect);
		if (file?.hasEventListener(FileListEvent.SELECT_MULTIPLE))
			file?.removeEventListener(FileListEvent.SELECT_MULTIPLE, onSelectMultiple);
		file?.removeEventListener(Event.COMPLETE, onComplete);
		file?.removeEventListener(Event.CANCEL, onCancel);
		file?.removeEventListener(IOErrorEvent.IO_ERROR, onError);

		for (newFile in e.files)
		{
			newFile.load();

			var actualCwd:String = Sys.getCwd();
			actualCwd = actualCwd.substring(0, actualCwd.length - 1);
			actualCwd += "\\";

			if (!newFile.nativePath.startsWith(actualCwd))
			{
				FlxG.log.error('Your asset (${newFile.nativePath}) has to be in the executable\'s directory');
				continue;
			}

			var suffix:Int = 0;

			var name:String = Path.withoutExtension(newFile.nativePath);
			name = name.substr(name.indexOf("assets\\images", actualCwd.length), name.length);

			var start:String = "overworld\\tiles";
			if (viewMode == DECALS)
				start = "overworld\\decals";

			name = name.substr(name.indexOf(start) + start.length + 1, name.length);

			trace(name);
			#if (windows || hl)
			name = Path.normalize(name);
			#end
			trace(name);

			if (viewMode == DECALS)
			{
				if (decalListData.exists(name))
				{
					while (suffix == 0 || decalListData.exists(name + '_$suffix'))
					{
						suffix++;
					}
				}
			}

			if (suffix > 0)
				name = name + '_$suffix';

			var imageGraphic:FlxGraphic = FlxGraphic.fromBitmapData(BitmapData.fromBytes(Bytes.ofData(newFile.data)), false, name);
			imageGraphic.persist = true;

			if (viewMode == TILES)
				tilesetList.addImage(name, imageGraphic.bitmap);
			else if (viewMode == DECALS)
			{
				decalListData.set(name, imageGraphic);
				decalList.add(name, decalList.children.length);
				decalList.children[decalList.children.length - 1].customData.set("name", name);
			}
		}

		file = null;
	}

	private function onError(e:IOErrorEvent)
	{
		if (file?.hasEventListener(Event.SELECT))
			file?.removeEventListener(Event.SELECT, onSelect);
		if (file?.hasEventListener(FileListEvent.SELECT_MULTIPLE))
			file?.removeEventListener(FileListEvent.SELECT_MULTIPLE, onSelectMultiple);
		file?.removeEventListener(Event.COMPLETE, onComplete);
		file?.removeEventListener(Event.CANCEL, onCancel);
		file?.removeEventListener(IOErrorEvent.IO_ERROR, onError);

		file = null;
	}

	private function onCancel(e:Event)
	{
		if (file?.hasEventListener(Event.SELECT))
			file?.removeEventListener(Event.SELECT, onSelect);
		if (file?.hasEventListener(FileListEvent.SELECT_MULTIPLE))
			file?.removeEventListener(FileListEvent.SELECT_MULTIPLE, onSelectMultiple);
		file?.removeEventListener(Event.COMPLETE, onComplete);
		file?.removeEventListener(Event.CANCEL, onCancel);
		file?.removeEventListener(IOErrorEvent.IO_ERROR, onError);

		file = null;
	}

	override public function destroy()
	{
		remove(collisionSpritePools); // we could end up removing the pool here, we have to remove it!

		collisionSpritePools.forEach(function(spr:FlxSprite)
		{
			if (spr.customData.exists("parentCollision"))
			{
				var collisionObj:Collision = spr.customData.get("parentCollision");
				if (collisionObj != null)
				{
					collisionObj.editorSelected = false;
					collisionObj.resizableSpr = null;
				}
			}

			spr.kill();
		});

		super.destroy();
	}
}

enum ViewMode
{
	TILES;
	DECALS;
	COLLISIONS;
	NODES;
}

enum ManipulationMode
{
	MOVE;
	EDIT;
	DELETE;
}
