package states;

import sys.thread.Thread;
import sys.thread.FixedThreadPool;
import sys.thread.Mutex;

class SplashIntro extends MainState
{
	final _minTime:Float = 2.0;

	public var logo:Splash;
	public var loading:Array<FlxSprite> = [];

	public var tasks:Int = 0;
	public var taskList:Int = 0;

	private var _index:Int = 0;
	private var _reverse:Bool = false;
	private var _timer:Float = 0.0;

	private static var _cellSize:Int = 12;

	private var _roomCacheThread:Thread;
	private var _graphicCacheThread:Thread;

	private var _mutex:Mutex;

	private var activate:Bool = false;

	// for flxgame to see it and shit
	override public function new()
	{
		super();

		FlxTimer.wait(0.01, function()
		{
			_mutex = new Mutex();

			Room.preCacheMode = true;
			if (FileSystem.exists(Assets.assetPath('data/rooms')))
			{
				var list:Array<String> = FileSystem.readDirectory(Assets.assetPath('data/rooms'));

				if (list.length > 0)
				{
					taskList += list.length;

					var roomCacheCondition:Bool = false;

					_roomCacheThread = Thread.create(function()
					{
						while (true)
						{
							if (activate)
							{
								for (item in list)
								{
									var data:RoomFile = null;
									var content:String = Assets.getContent(Assets.assetPath('data/rooms/$item')).trim();
									if (content.length > 0)
										data = cast Json.parse(content);

									_mutex.acquire();

									if (data != null)
										World.roomList.set(Path.withoutExtension(item), new Room(data));
									tasks++;

									_mutex.release();
								}

								Room.preCacheMode = false;

								roomCacheCondition = true;
								break;
							}
						}
					});

					taskList++;

					_graphicCacheThread = Thread.create(function()
					{
						while (true)
						{
							if (activate && roomCacheCondition)
							{
								Room.cacheList();
								Room.preCacheMode = true;

								tasks++;

								break;
							}
						}
					});
				}
			}
		});

		FlxG.console.registerFunction("worldDebug", () ->
		{
			Room.debugView = !Room.debugView;
		});

		FlxG.console.registerObject("cursor", Main.cursor);
	}

	override public function create()
	{
		FlxG.camera.pixelPerfectRender = true;

		logo = new Splash();
		add(logo);

		for (i in 0...3)
		{
			var bitmap:BitmapData = new BitmapData(_cellSize * 5, _cellSize, false);

			bitmap.lock();
			bitmap.fillRect(new Rectangle(_cellSize * (i * 2), 0, _cellSize, _cellSize), 0xFFFF00);

			bitmap.fillRect(new Rectangle(_cellSize, 0, _cellSize, _cellSize), 0x000000);
			bitmap.fillRect(new Rectangle(_cellSize * 3, 0, _cellSize, _cellSize), 0x000000);
			bitmap.unlock();

			var graph:FlxGraphic = FlxGraphic.fromBitmapData(bitmap, true, 'loading$i');

			var spr:FlxSprite = new FlxSprite(graph);
			spr.active = spr.exists = false;
			spr.antialiasing = false;
			spr.screenCenter();
			spr.y += 100;

			loading.push(spr);
			add(spr);
		}

		loading[0].exists = true;

		activate = true;

		super.create();
	}

	override public function update(elapsed:Float)
	{
		if (stateTime > _minTime && tasks >= taskList)
			FlxG.switchState(new IntroState());

		if (_timer < 0.4)
			_timer += elapsed;
		else
		{
			_timer = 0;
			var _lastIndex = _index;

			if (_reverse)
			{
				_index--;
				if (_index == 0)
					_reverse = !_reverse;
			}
			else
			{
				_index++;
				if (_index == 2)
					_reverse = !_reverse;
			}

			loading[_lastIndex].exists = false;
			loading[_index].exists = true;
		}

		super.update(elapsed);
	}
}
