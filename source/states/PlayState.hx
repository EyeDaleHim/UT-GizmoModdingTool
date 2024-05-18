package states;

import ui.text.Dialogue;

class PlayState extends MainState
{
	public static var instance:PlayState;

	public var battleSubstate:BattleSubState;

	// cameras
	public var gameCamera:FlxCamera;
	public var hudCamera:FlxCamera;
	public var battleCamera:FlxCamera;

	// sounds
	public var areaMusic:FlxSound;

	// world
	public var world:World;
	public var sortGroup:FlxTypedGroup<FlxObject>;

	// player and shit
	public var player:Player;
	public var soul:Soul;

	public var encounter:FlxSprite;

	// movement handling
	public var transition:Bool = false;

	// ui
	public var textBox:Dialogue = new Dialogue(0.0, 8.0, [
		{
			speaker: "",
			content: "",
		},
		{
			speaker: "",
			content: "* It's your book!",
		},
		{
			speaker: "",
			content: "* It's been a while since you've\nlast seen it.",
		},
		{
			speaker: "",
			content: "* You decide to sit and read it.\nIt reads...",
			attributes: [
				{
					name: "delay",
					startIndexString: "and",
					data: [0.2]
				},
				{
					name: "delay",
					startIndexString: "It reads...",
					data: [0.6]
				}
			]
		},
		{
			speaker: "",
			content: "* \"This is the story of",
			attributes: [
				{
					name: "delay",
					startIndex: 0,
					endIndex: "* \"This is the story of".length,
					data: [0.24]
				}
			]
		}
	]);

	private var __firstInit:Bool = false;

	override function create()
	{
		instance = this;

		gameCamera = FlxG.camera;
		gameCamera.zoom = 2;

		hudCamera = new FlxCamera();
		hudCamera.bgColor.alpha = 0;
		FlxG.cameras.add(hudCamera, false);

		battleCamera = new FlxCamera();
		battleCamera.kill();
		FlxG.cameras.add(battleCamera, false);

		areaMusic = FlxG.sound.list.recycle(FlxSound);
		areaMusic.customData.set("name", "");

		soul = new Soul();
		soul.kill();
		soul.controllable = false;
		soul.camera = battleCamera;
		add(soul);

		battleSubstate = new BattleSubState(soul);

		player = new Player("frisk");
		player.hitbox.allowCollisions = NONE;

		// i
		textBox.kill();
		textBox.screenCenter(X);
		textBox.camera = hudCamera;
		textBox.typeText.startTyping(0.08, 1, ['normal']);
		add(textBox);

		textBox.textBox.y = FlxG.height - textBox.textBox.height - 8;
		textBox.typeText.y = textBox.textBox.y + 6 + 22;

		sortGroup = new FlxTypedGroup<FlxObject>();

		world = new World();
		nextRoom("beginning");

		encounter = new FlxSprite().loadGraphic(Assets.image('battle/alert'));
		encounter.active = false;
		encounter.kill();

		add(sortGroup);

		sortGroup.add(world);
		sortGroup.add(encounter);
		sortGroup.add(player);
		sortGroup.add(soul);

		add(world.collisionGroup);
		for (i in 0...4)
			add(world.nodeGroups[i]);

		gameCamera.follow(player, LOCKON, 999);

		super.create();

		__firstInit = true;
	}

	override public function update(elapsed:Float)
	{
		if (FlxG.keys.justPressed.F5)
			encounterEnemy();

		if (FlxG.keys.justPressed.F3)
			textBox.revive();

		sortGroup.sort(byDepth);

		if (world?.currentRoom != null && !transition)
		{
			FlxG.collide(player.hitbox, world.collisionGroup);

			var triggered:Bool = false;

			FlxG.overlap(player.hitbox, world.nodeGroups[2], (obj1, obj2) ->
			{
				if (!triggered)
				{
					var node:Node = cast(obj2, FlxObject).customData.get("node");

					if (node?.contexts != null && node.contexts.length > 0)
					{
						nextRoom(node.contexts[0], node.contexts[1]);
						triggered = true;
					}
					else
						trace(node);
				}
			});
		}

		super.update(elapsed);
	}

	public function nextRoom(room:Null<String>, ?spawnTarget:Null<String> = null)
	{
		transition = true;
		player.controllable = false;
		player.hitbox.allowCollisions = NONE;

		var roomFunc:() -> Void = function()
		{
			// implement room switch here...
			world.setNewRoom(room);

			var bgMusic:String = world?.currentRoom?.data?.bg_music ?? "";
			var play:Bool = false;

			if (bgMusic.length > 0 && bgMusic != areaMusic?.customData.get("name"))
			{
				areaMusic.loadEmbedded(Assets.sound('areas/$bgMusic', 'music'), true);
				FlxG.sound.list.add(areaMusic);

				play = true;
			}

			if (world.currentRoom?.nodes?.length > 0)
			{
				var spawnNodes:Array<Node> = [];

				for (node in world.currentRoom.nodes)
				{
					if (node == null)
						continue;

					switch (node.type)
					{
						case 3:
							{
								if (spawnTarget == null || (node.contexts != null && node.contexts[1] == spawnTarget))
									spawnNodes.push(node);
							}
					}
				}

				var spawnNode:Node = spawnNodes[FlxG.random.int(0, spawnNodes.length - 1)];
				if (spawnNode != null)
					player.setPosition(spawnNode.x + 10 - (player.hitbox.width / 2), spawnNode.y + 20 - player.hitbox.height);

				player.hitbox.allowCollisions = ANY;
			}

			if (__firstInit)
				FlxG.camera.fade(0.25, true, () ->
				{
					player.controllable = true;
					transition = false;
				}, true);
			else
			{
				player.controllable = true;
				transition = false;
			}

			if (play)
				areaMusic.play();
		};

		if (!__firstInit)
			roomFunc();
		else
			FlxG.camera.fade(0.25, false, roomFunc, true);
	}

	public function encounterEnemy():Void
	{
		player.controllable = false;

		encounter.revive();
		encounter.centerOverlay(player, X);
		encounter.y = player.y - encounter.height;

		battleCamera.revive();
		battleCamera.bgColor.alphaFloat = 0;

		var pos:FlxPoint = player.getScreenPosition();
		soul.setPosition(pos.x + (soul.width / 2), pos.y + (soul.height / 2));

		FlxG.sound.play(Assets.sound('battle/encounter', 'sfx'), 0.4);
		new FlxTimer().start(1, function(parentTmr:FlxTimer)
		{
			areaMusic.pause();
			encounter.kill();

			soul.revive();
			soul.visible = true;

			new FlxTimer().start(1 / 16, function(tmr:FlxTimer)
			{
				soul.visible = !soul.visible;
			}, 8);

			new FlxTimer().start(1 / 8, function(tmr:FlxTimer)
			{
				if (tmr.loopsLeft == 0)
				{
					soul.revive();
					battleCamera.revive();
					FlxTween.num(0, 1.0, 0.5, {
						onComplete: function(twn:FlxTween)
						{
							battleSubstate.forEach(function(mem)
							{
								if (mem.ID != soul.ID)
									mem.visible = true;
							});
						}
					}, function(value:Float)
					{
						if (MainState._illusionFrames == 0)
							battleCamera.bgColor.alphaFloat = value;
					});

					FlxTween.tween(soul, {x: battleSubstate.buttons[0].x + 8, y: battleSubstate.buttons[0].y + 14}, 0.5, {
						onComplete: function(twn:FlxTween)
						{
							battleSubstate.start();
							battleSubstate.changeSelect();
						}
					});

					openSubState(battleSubstate);
					battleSubstate.forEach(function(mem)
					{
						if (mem.ID != soul.ID)
							mem.visible = false;
					});

					FlxG.sound.play(Assets.sound('battle/battle_start', 'sfx'), 0.4);
				}
				else
					FlxG.sound.play(Assets.sound('interact', 'sfx'), 0.3);
			}, 4);
		});
	}

	function byDepth(Order:Int, Obj1:FlxObject, Obj2:FlxObject):Int
	{
		return FlxSort.byValues(Order, Obj1.y + Obj1.height, Obj2.y + Obj2.height);
	}
}
