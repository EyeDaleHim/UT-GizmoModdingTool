package states.editors;

import openfl.display.PNGEncoderOptions;
import ui.editor.TextObject;
import ui.editor.List;
import ui.editor.Button;
import ui.editor.Stepper;
import ui.editor.Checkbox;
import ui.editor.TextInput;
import ui.editor.animation.Track;
import flixel.addons.display.FlxBackdrop;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.events.FileListEvent;
import openfl.geom.Rectangle;
import openfl.filesystem.File;
import haxe.io.Bytes;

// the way this class handles bitmap data is kinda stupid because it allocates 2x the bitmap data per bitmap, im too lazy to fix it but since
// this is an editor, i dont care
class AnimationEditorState extends BaseEditorState
{
	static var cursorType:String = "normal";

	// data
	public var file:File;
	public var imageDataList:Array<ImageData> = [];
	public var mapHash:Map<String, FlxGraphic> = [];

	// colors
	public static final bgHudColor:FlxColor = 0xFF333435;
	public static final bgHudColor2:FlxColor = 0xFF222529;
	public static final mainTextColor:FlxColor = 0xFFF2F8FF;

	// camera setup
	public var mainCamera:FlxCamera;
	public var hudCamera:FlxCamera;

	// anim info
	private var _selectedAnim:Int = 0;

	public var animations:Array<AnimationInfo> = [
		{
			name: "",
			frames: [],
			offsets: [],
			fps: 6,
			looped: false,
		}
	];
	public var nameList:Array<String> = [""];

	public var name:String = "";

	public var frameList(get, set):Array<String>;
	public var frameOffset(get, set):Array<SimplePoint>;

	public var animName(get, set):String;
	public var looped(get, set):Bool;
	public var playing:Bool = false;
	public var fps(get, set):Float;
	public var curFrame(default, set):Int = 0;

	// // private info
	private var _remainderElapsed:Float = 0.0;

	// sprites
	// // helpers
	public var hudElements:FlxGroup;

	// // bg
	private var _back:FlxBackdrop;

	// // current sprite
	public var lastFrameSpr:FlxSprite;
	public var curFrameSpr:FlxSprite;
	public var trueOriginSpr:FlxSprite;

	// // ui
	// // // hud bg elements
	public var fileManageBG:FlxSprite;
	public var fileText:TextObject;

	public var frameManageBG:FlxSprite;
	public var frameText:TextObject;

	public var spriteManageBG:FlxSprite;
	public var spriteText:TextObject;

	public var animList:List;
	public var addAnim:Button;
	public var trashAnim:Button;

	public var export:Button;

	// // // file category
	public var imageList:List;

	public var imagePreview:FlxSprite;

	public var trashButton:Button;
	public var imageButton:Button;
	public var addButton:Button;

	// // // frame category
	public var fpsStepper:Stepper;
	public var curFrameText:TextObject;

	public var trackFrame:Track;

	public var trashFrameButton:Button;

	// // // properties category
	public var nameInput:TextInput;

	public var loopButton:Checkbox;

	override function create()
	{
		super.preCreate();

		// camera setup
		mainCamera = FlxG.camera;

		hudCamera = new FlxCamera(0, 0, 1600, 900);
		hudCamera.bgColor.alpha = 0;
		FlxG.cameras.add(hudCamera, false);

		// should i make this on the spot? whatever
		var bitmap:BitmapData = new BitmapData(32, 32, false, 0x00000000);
		bitmap.lock();

		var primary:Int = 0xFF72A2C2;
		var secondary:Int = 0xFF777E86;

		bitmap.fillRect(new Rectangle(0, 0, 16, 16), primary); // top-left
		bitmap.fillRect(new Rectangle(16, 0, 16, 16), secondary); // top-right

		bitmap.fillRect(new Rectangle(16, 16, 16, 16), primary); // bottom-right
		bitmap.fillRect(new Rectangle(0, 16, 16, 16), secondary); // bottom-left

		bitmap.unlock();

		hudElements = new FlxGroup();

		_back = new FlxBackdrop(bitmap);
		add(_back);

		lastFrameSpr = new FlxSprite();
		lastFrameSpr.colorTransform.redMultiplier = lastFrameSpr.colorTransform.blueMultiplier = lastFrameSpr.colorTransform.greenMultiplier = 0.1;
		lastFrameSpr.alpha = 0.8;
		lastFrameSpr.antialiasing = false;

		curFrameSpr = new FlxSprite();
		curFrameSpr.antialiasing = false;

		lastFrameSpr.exists = lastFrameSpr.active = curFrameSpr.exists = curFrameSpr.active = false;

		trueOriginSpr = new FlxSprite();
		trueOriginSpr.exists = false;

		add(lastFrameSpr);
		add(curFrameSpr);
		add(trueOriginSpr);

		addFileManageUI();
		addFrameManageUI();
		addSpriteManageUI();

		animList = new List(1400, 30, 190);
		animList.camera = hudCamera;
		animList.onClick = function(selected:Int)
		{
			_selectedAnim = selected;

			if (animations[_selectedAnim] != null)
			{
				FlxDestroyUtil.destroyArray(trackFrame.frameList);
				trackFrame.frameList = [];

				for (i in 0...frameList.length)
				{
					trackFrame.addFrame(new FrameSprite(i), i);
					trackFrame.frameList[i].exists = frameList[i] != null;
				}
				reloadSprites();
			}
		};

		animList.add("", 0);
		animList.onClick(0);

		addAnim = new Button(animList.getRight(), animList.getBottom() + 2, "Add New...", 14);
		addAnim.x -= addAnim.width;
		addAnim.camera = hudCamera;
		addAnim.onClick = function()
		{
			animList.add("", animList.children.length);

			animations.push({
				name: "",
				offsets: [],
				frames: [],
				looped: false,
				fps: 6.0
			});

			_selectedAnim = animList.children.length - 1;

			reloadSprites();
			FlxDestroyUtil.destroyArray(trackFrame.frameList.splice(0, frameList.length));
			trackFrame.frameList = [];

			for (i in 0...frameList.length)
			{
				if (trackFrame.frameList[i] == null)
					trackFrame.addFrame(new FrameSprite(i), i);

				if (frameList[i] == null)
					trackFrame.frameList[i].changeFrameSpr.exists = false;
				else
					trackFrame.frameList[i].changeFrameSpr.exists = true;
			}

			loopButton.toggleValue(true);

			nameInput.changeText("");
			nameInput.textObject.text = "";

			animList.children[_selectedAnim].color = animList.buttonSelectedColor;
			animList.children[_selectedAnim].status = Children.PRESS;
		};

		trashAnim = new Button(addAnim.x, addAnim.y, Assets.image("_debug/trash").bitmap);
		trashAnim.x -= trashAnim.width + 4;
		trashAnim.camera = hudCamera;
		trashAnim.onClick = function()
		{
			if (animations.length < 2)
			{
				FlxG.log.error("This is the only animation. You can't delete it.");
				return;
			}

			animList.remove(_selectedAnim);
			animations.splice(_selectedAnim, 1);

			while (animations[_selectedAnim] == null)
			{
				_selectedAnim--;
			}

			reloadSprites();
			FlxDestroyUtil.destroyArray(trackFrame.frameList.splice(0, frameList.length));
			trackFrame.frameList = [];

			for (i in 0...frameList.length)
			{
				if (trackFrame.frameList[i] == null)
					trackFrame.addFrame(new FrameSprite(i), i);

				if (frameList[i] == null)
					trackFrame.frameList[i].changeFrameSpr.exists = false;
				else
					trackFrame.frameList[i].changeFrameSpr.exists = true;
			}

			loopButton.toggleValue(true);

			nameInput.changeText("");
			nameInput.textObject.text = "";
		};

		export = new Button(animList.getRight(), animList.getBottom() + 80, "Export", null, 14);
		export.x -= export.width;
		export.camera = hudCamera;
		export.onClick = function()
		{
			if (animations.length == 1 && animations[0].frames.length == 0)
			{
				FlxG.log.error("You can't export with no animations.");
				return;
			}

			var animationFile:AnimationFile = [];

			for (i in 0...animations.length)
			{
				var animationOffsets:Array<SimplePoint> = animations[i].offsets;

				animationFile[i] = {
					name: nameList[i],
					frames: [
						for (j in 0...animations[i].frames.length)
							{name: animations[i].frames[j], index: -1}
					],
					fps: animations[i].fps,
					looped: animations[i].looped,
					offsetsX: [for (j in 0...animationOffsets.length) animationOffsets[j].x],
					offsetsY: [for (j in 0...animationOffsets.length) animationOffsets[j].y]
				};

				for (k in 0...animationFile[i].frames.length)
				{
					for (l in 0...imageDataList.length)
					{
						if (imageDataList[l].name == animationFile[i].frames[k].name)
						{
							animationFile[i].frames[k].index = l;
							break;
						}
					}
				}
			}

			file = new File();

			file.addEventListener(Event.SELECT, onSelect);
			file.addEventListener(Event.COMPLETE, onComplete);
			file.addEventListener(Event.CANCEL, onCancel);
			file.addEventListener(IOErrorEvent.IO_ERROR, onError);

			_save = true;

			file.save(Json.stringify(animationFile), Path.withExtension(name, 'json'));
		}

		add(trashAnim);
		add(addAnim);
		add(export);
		add(animList);

		hudElements.add(animList);
		hudElements.add(export);
		hudElements.add(addAnim);
		hudElements.add(trashAnim);

		designOutlines();
	}

	private function addSpriteManageUI():Void
	{
		spriteManageBG = new FlxSprite(frameManageBG.getRight()).makeGraphic(370, 350, bgHudColor);
		spriteManageBG.y = hudCamera.height - spriteManageBG.height;
		spriteManageBG.camera = hudCamera;

		spriteText = new TextObject(spriteManageBG.x + 2, spriteManageBG.y + 2, 0, "Properties", 14);
		spriteText.camera = hudCamera;

		spriteManageBG.pixels.lock();
		spriteManageBG.pixels.fillRect(new Rectangle(0, 0, spriteText.width + 4, spriteText.height + 4), bgHudColor2);
		spriteManageBG.pixels.unlock();

		loopButton = new Checkbox(spriteManageBG.x + 30, spriteManageBG.y + 60, 24, 24, 0xFFFFFFFF, "Looped", function()
		{
			return looped;
		}, function(Value:Bool)
		{
			looped = Value;
			if (playing)
				playing = false;
		});
		loopButton.camera = hudCamera;

		nameInput = new TextInput(spriteManageBG.x + 30, spriteManageBG.y + 30, 100, 12, "");
		nameInput.camera = hudCamera;
		nameInput.onChange = function(text:String)
		{
			animName = text;
			animList.children[_selectedAnim].textObj.text = text;
		};

		hudElements.add(spriteManageBG);

		add(spriteManageBG);
		add(spriteText);
		add(loopButton);
		add(nameInput);
	}

	private function addFrameManageUI():Void
	{
		frameManageBG = new FlxSprite(fileManageBG.width).makeGraphic(1000, 240, bgHudColor);
		frameManageBG.y = hudCamera.height - frameManageBG.height;
		frameManageBG.camera = hudCamera;

		frameText = new TextObject(frameManageBG.x, frameManageBG.y + 2, 0, "Frames", 14);
		frameText.camera = hudCamera;

		frameManageBG.pixels.lock();
		frameManageBG.pixels.fillRect(new Rectangle(0, 0, frameText.width + 4, frameText.height + 4), bgHudColor2);
		frameManageBG.pixels.unlock();

		trackFrame = new Track(230, 760, 30, 28);
		trackFrame.camera = hudCamera;

		trashFrameButton = new Button(trackFrame.x + ((trackFrame.tileWidth + 1) * 26), trackFrame.getBottom() + 4, Assets.image("_debug/trash").bitmap);
		trashFrameButton.camera = hudCamera;
		trashFrameButton.x -= trashFrameButton.width;
		trashFrameButton.onClick = function()
		{
			if (curFrame < frameList.length)
			{
				frameList[curFrame] = null;

				var wipe:Bool = true;

				if (curFrame == frameList.length - 1)
				{
					var i:Int = curFrame;
					while (i > 0)
					{
						if (frameList[i] == null)
						{
							trackFrame.frameList.splice(i, 1)[0].destroy();
							frameOffset.remove(frameOffset[curFrame]);
							frameList.remove(frameList[curFrame]);
						}
						else
							break;
						i--;
					}
				}
				else
				{
					for (i in curFrame...frameList.length)
					{
						if (frameList[i] != null)
						{
							wipe = false;
							break;
						}
					}

					if (wipe)
					{
						frameList.splice(curFrame, frameList.length);
						frameOffset.splice(curFrame, frameList.length);
						FlxDestroyUtil.destroyArray(trackFrame.frameList.splice(curFrame, frameList.length));
					}
				}

				var clearArray:Bool = true;
				for (frame in frameList)
				{
					if (frame != null)
					{
						clearArray = false;
						break;
					}
				}

				if (clearArray)
				{
					frameList = [];
					frameOffset = [];

					FlxDestroyUtil.destroyArray(trackFrame.frameList);
					trackFrame.frameList = [];
				}
			}

			if (frameList.length == 0)
			{
				FlxDestroyUtil.destroyArray(trackFrame.frameList);
				trackFrame.frameList = [];
			}

			for (frame in trackFrame.frameList)
			{
				frame.frameIndex = trackFrame.frameList.indexOf(frame);
				frame.changeFrameSpr.exists = frameList[frame.frameIndex] != null;
			}
		};

		fpsStepper = new Stepper(trackFrame.x, trackFrame.y + trackFrame.height + 8, new FlxBounds<Float>(1, 100), "FPS", function()
		{
			return fps;
		}, function(value:Float)
		{
			if (playing)
			{
				playing = false;
				reloadSprites();
			}
			fps = value;
		});
		fpsStepper.camera = hudCamera;

		curFrameText = new TextObject(230, 700, 0, "Frames: 1 / 1", 14);
		curFrameText.camera = hudCamera;

		hudElements.add(frameManageBG);

		add(frameManageBG);
		add(trackFrame);
		add(trashFrameButton);
		add(curFrameText);
		add(frameText);
		add(fpsStepper);
	}

	private function addFileManageUI():Void
	{
		fileManageBG = new FlxSprite(0, 650).makeGraphic(230, 500, bgHudColor);
		fileManageBG.y = hudCamera.height - fileManageBG.height;
		fileManageBG.camera = hudCamera;

		fileText = new TextObject(2, fileManageBG.y + 2, 0, "Files", 14);
		fileText.camera = hudCamera;

		fileManageBG.pixels.lock();
		fileManageBG.pixels.fillRect(new Rectangle(0, 0, fileText.width + 4, fileText.height + 4), bgHudColor2);
		fileManageBG.pixels.unlock();

		imageList = new List(40, 600, 190);
		imageList.centerOverlay(fileManageBG, X);
		imageList.camera = hudCamera;

		imageList.onHover = function(select:Int)
		{
			if (imageDataList[select] != null)
			{
				imagePreview.loadGraphic(imageDataList[select].image, false, 0, 0, false, imageDataList[select].name);
				imagePreview.visible = true;
				imagePreview.alpha = 0.6;
			}

			if (imagePreview.width < 128 || imagePreview.height < 128)
			{
				imagePreview.setGraphicSize(Math.min(imagePreview.width * 4.0, 128), Math.min(imagePreview.height * 4.0, 128));
				imagePreview.updateHitbox();
				imagePreview.setPosition(fileManageBG.x + 50, fileManageBG.y + 50);
			}

			if (select == imageList.selected)
				imagePreview.alpha = 1.0;
		};

		imageList.onClick = function(select:Int)
		{
			imagePreview.alpha = 1.0;
		}

		imageButton = new Button(20, fileManageBG.y + (fileManageBG.height - 16), "Add Images", 12);
		imageButton.y -= imageButton.height;
		imageButton.camera = hudCamera;
		imageButton.onClick = function()
		{
			persistentUpdate = false;

			file = new File();

			file.addEventListener(Event.COMPLETE, onComplete);
			file.addEventListener(FileListEvent.SELECT_MULTIPLE, onSelectMultiple);
			file.addEventListener(Event.CANCEL, onCancel);
			file.addEventListener(IOErrorEvent.IO_ERROR, onError);

			file.browseForOpenMultiple("Open Files");
		};

		addButton = new Button(fileManageBG.width - 20, fileManageBG.y + (fileManageBG.height - 16), "Set Frame", 12);
		addButton.x -= addButton.width;
		addButton.y -= addButton.height;
		addButton.camera = hudCamera;

		addButton.onClick = function()
		{
			if (imageList.selected != -1)
			{
				insertFrame(imageDataList[imageList.selected].name);
				reloadSprites();

				curFrameText.text = 'Frames: ${curFrame + 1} / ${Math.max(1, frameList.length)}';
				curFrameText.updateHitbox();
			}
		}

		trashButton = new Button((imageList.x + imageList.width) - 22, imageList.y - 26, Assets.image("_debug/trash").bitmap);
		trashButton.camera = hudCamera;
		trashButton.onClick = function()
		{
			if (imageList.selected != -1)
			{
				imagePreview.makeGraphic(1, 1, 0);
				imagePreview.visible = false;

				// Load to the nearest available frame on the left, right if unsuccessful, otherwise, just make it invisible
				var i:Int = curFrame;
				while (i != 0)
				{
					i--;
				}

				var imageData:ImageData = imageDataList[imageList.selected];

				imageList.remove(imageList.selected);

				imageData.image.dump();
				imageData.image.destroy();

				imageDataList.remove(imageData);
				mapHash.remove(imageData.name);
			}
		};

		imagePreview = new FlxSprite(80, 80);
		imagePreview.visible = false;
		imagePreview.camera = hudCamera;

		hudElements.add(fileManageBG);

		add(fileManageBG);
		add(fileText);
		add(imageList);
		add(imageButton);
		add(addButton);
		add(trashButton);
		add(imagePreview);
	}

	private function designOutlines():Void
	{
		var bitmapTarget:BitmapData;

		bitmapTarget = fileManageBG.pixels;

		bitmapTarget.lock();
		bitmapTarget.fillRect(new Rectangle(0, 0, bitmapTarget.width, 4), bgHudColor2);
		bitmapTarget.fillRect(new Rectangle(0, 0, 4, bitmapTarget.height), bgHudColor2);
		bitmapTarget.fillRect(new Rectangle(bitmapTarget.width - 4, 0, 4, (fileManageBG.height - frameManageBG.height) + frameText.height + 4), bgHudColor2);
		bitmapTarget.fillRect(new Rectangle(0, bitmapTarget.height - 4, bitmapTarget.width, 4), bgHudColor2);
		bitmapTarget.unlock();

		bitmapTarget = frameManageBG.pixels;

		bitmapTarget.lock();
		bitmapTarget.fillRect(new Rectangle(0, 0, bitmapTarget.width, 4), bgHudColor2);
		bitmapTarget.fillRect(new Rectangle(0, bitmapTarget.height - 4, bitmapTarget.width, 4), bgHudColor2);
		bitmapTarget.unlock();

		bitmapTarget = spriteManageBG.pixels;

		bitmapTarget.lock();
		bitmapTarget.fillRect(new Rectangle(0, 0, bitmapTarget.width, 4), bgHudColor2);
		bitmapTarget.fillRect(new Rectangle(0, 0, 4, (frameManageBG.y - spriteManageBG.y) + 4), bgHudColor2);
		bitmapTarget.fillRect(new Rectangle(0, bitmapTarget.height - 4, bitmapTarget.width, 4), bgHudColor2);
		bitmapTarget.fillRect(new Rectangle(bitmapTarget.width - 4, 0, 4, bitmapTarget.height), bgHudColor2);
		bitmapTarget.unlock();
	}

	private var _lastMovement:FlxPoint = FlxPoint.get();
	private var _newMovement:FlxPoint = FlxPoint.get();

	// drag preview
	private var _selectedSpr:Bool = false;

	private var _distOriginFromMouse:FlxPoint = FlxPoint.get();

	override function update(elapsed:Float)
	{
		var overlappingHud:Bool = FlxG.mouse.overlaps(hudElements, hudCamera);

		var updatePriority:UpdateInputPriority = DRAG_CAMERA;
		if (_selectedSpr)
			updatePriority = DRAG_PREVIEW;

		switch (updatePriority)
		{
			case DRAG_PREVIEW:
				{
					if (cursorType != "drag")
					{
						Main.cursor.loadSkin("drag");
						cursorType = "drag";
					}

					hudCamera.alpha -= elapsed * 8;
					if (hudCamera.alpha < 0.5)
						hudCamera.alpha = 0.5;

					if (playing)
					{
						playing = false;
						reloadSprites();
					}

					if (FlxG.mouse.released)
						_selectedSpr = false;
					else
					{
						if (frameOffset[curFrame] == null)
							frameOffset[curFrame] = {x: 0, y: 0};

						frameOffset[curFrame].x = ((_distOriginFromMouse.x + FlxG.mouse.x) / 4).floor();
						frameOffset[curFrame].y = ((_distOriginFromMouse.y + FlxG.mouse.y) / 4).floor();

						curFrameSpr.setPosition(frameOffset[curFrame].x * 4, frameOffset[curFrame].y * 4);
					}
				}
			case DRAG_CAMERA:
				{
					hudCamera.alpha += elapsed * 8;

					if (!nameInput.selected)
					{
						if (FlxG.keys.anyJustPressed([A, D]))
						{
							if (FlxG.keys.justPressed.A)
								InputHelper.addKey(A, cycleFrame.bind(-1), 0.6, 0.07);
							if (FlxG.keys.justPressed.D)
								InputHelper.addKey(D, cycleFrame.bind(1), 0.6, 0.07);
						}

						if (FlxG.keys.justReleased.SPACE)
						{
							_remainderElapsed = 0.0;
							playing = !playing;

							if (!looped && curFrame >= frameList.length)
								curFrame = 0;

							reloadSprites();
						}
					}

					if (!overlappingHud && FlxG.mouse.wheel != 0)
						mainCamera.fromWheelZoom(0.1, 0.75, 2);

					if (!overlappingHud && FlxG.mouse.pressedRight)
					{
						if (cursorType != "drag")
						{
							Main.cursor.loadSkin("drag");
							cursorType = "drag";
						}

						FlxG.mouse.getPositionInCameraView(mainCamera, _newMovement);
						if (FlxG.mouse.justPressedRight)
							_lastMovement.copyFrom(_newMovement);
					}
					else if (FlxG.mouse.justReleasedMiddle)
					{
						if (cursorType != "drag")
						{
							Main.cursor.loadSkin("drag");
							cursorType = "drag";
						}
						mainCamera.focusOn(FlxPoint.get());
					}
					else
					{
						if (cursorType != "normal")
						{
							Main.cursor.loadSkin("cursor");
							cursorType = "normal";
						}
					}

					if (!_lastMovement.equals(_newMovement))
					{
						var diff:FlxPoint = FlxPoint.get(_newMovement.x - _lastMovement.x, _newMovement.y - _lastMovement.y);

						mainCamera.scroll.x -= diff.x;
						mainCamera.scroll.y -= diff.y;

						_lastMovement.copyFrom(_newMovement);
					}

					if (FlxG.mouse.pressed && FlxG.mouse.overlaps(curFrameSpr, camera))
					{
						_selectedSpr = true;
						_distOriginFromMouse.set(curFrameSpr.x - FlxG.mouse.x, curFrameSpr.y - FlxG.mouse.y);
					}
				}
		}

		if (playing)
		{
			_remainderElapsed += elapsed;
			while (_remainderElapsed > 0)
			{
				if (_remainderElapsed < 1 / fps)
					break;

				_remainderElapsed -= 1 / fps;
				curFrame++;
				if (curFrame >= frameList.length)
				{
					if (looped)
						curFrame = 0;
					else
					{
						curFrame--;
						playing = false;
					}
				}
			}
		}

		super.update(elapsed);
	}

	public function insertFrame(name:String):Void
	{
		frameList[curFrame] = name;

		for (i in 0...frameList.length)
		{
			if (trackFrame.frameList[i] == null)
				trackFrame.addFrame(new FrameSprite(i), i);

			if (frameList[i] == null)
				trackFrame.frameList[i].changeFrameSpr.exists = false;
			else
				trackFrame.frameList[i].changeFrameSpr.exists = true;
		}
	}

	public function reloadSprites():Void
	{
		if (!playing)
		{
			lastFrameSpr.exists = false;
			if (curFrame != 0
				&& frameList[curFrame - 1] != null
				&& frameList[curFrame] != null
				&& mapHash.exists(frameList[curFrame - 1]))
			{
				lastFrameSpr.exists = true;
				lastFrameSpr.loadGraphic(mapHash.get(frameList[curFrame - 1]));
				lastFrameSpr.scale.set(4, 4);

				lastFrameSpr.setColorTransform(0.1, 0.1, 0.1);
				lastFrameSpr.alpha = 0.8;

				lastFrameSpr.updateHitbox();

				if (frameOffset[curFrame - 1] == null)
					frameOffset[curFrame - 1] = {x: 0, y: 0};
				lastFrameSpr.setPosition(frameOffset[curFrame - 1].x * 4, frameOffset[curFrame - 1].y * 4);
			}
		}
		if (frameList[curFrame] != null && mapHash.exists(frameList[curFrame]))
		{
			curFrameSpr.exists = true;
			curFrameSpr.loadGraphic(mapHash.get(frameList[curFrame]));
			curFrameSpr.scale.set(4, 4);
			curFrameSpr.updateHitbox();

			if (frameOffset[curFrame] == null)
				frameOffset[curFrame] = {x: 0, y: 0};
			curFrameSpr.setPosition(frameOffset[curFrame].x * 4, frameOffset[curFrame].y * 4);
		}

		trueOriginSpr.makeGraphic((curFrameSpr.frameWidth + 2).floor(), (curFrameSpr.frameHeight + 2).floor(), 0xFFFF0000);

		trueOriginSpr.pixels.lock();
		trueOriginSpr.pixels.fillRect(new Rectangle(1, 1, trueOriginSpr.frameWidth - 2, trueOriginSpr.frameHeight - 2), 0);
		trueOriginSpr.pixels.unlock();

		trueOriginSpr.scale.set(4.0, 4.0);
		trueOriginSpr.updateHitbox();
		trueOriginSpr.setPosition(-4, -4);
		trueOriginSpr.alpha = 0.5;

		trueOriginSpr.exists = curFrameSpr.exists;
	}

	private function cycleFrame(change:Int = 0)
	{
		if (change != 0)
		{
			playing = false; //
			if (FlxG.keys.pressed.SHIFT && change < 0)
				curFrame = 0;
			else if (change < 0 && curFrame != 0)
				curFrame--;
			else if (change > 0)
			{
				if (FlxG.keys.pressed.SHIFT)
					curFrame = frameList.length;
				else
					curFrame++;
			}
		}
	}

	function set_curFrame(Value:Int)
	{
		trackFrame.startPoint = Value;
		curFrameText.text = 'Frames: ${Value + 1} / ${Math.max(1, frameList.length)}';
		curFrameText.updateHitbox();

		curFrame = Value;

		reloadSprites();

		return curFrame;
	}

	// truly this is the worst code i've ever written
	private var _save:Bool = false;

	private function onSelect(e:Event):Void
	{
		persistentUpdate = true;

		if (_save)
		{
			FlxG.log.notice("Successfully saved animation data.");

			file?.removeEventListener(Event.SELECT, onSelect);
			file?.removeEventListener(Event.COMPLETE, onComplete);
			file?.removeEventListener(Event.CANCEL, onCancel);
			file?.removeEventListener(IOErrorEvent.IO_ERROR, onError);

			var graphList:Array<FlxGraphic> = [];

			for (graph in imageDataList)
			{
				if (graph.image.bitmap != null)
					graphList.push(graph.image);
			}

			if (_saveToPhases == 0)
			{
				file = null;

				haxe.Timer.delay(function()
				{
					_saveToPhases = 1;

					file = new File();

					file.addEventListener(Event.COMPLETE, onComplete);
					file.addEventListener(Event.CANCEL, onCancel);
					file.addEventListener(IOErrorEvent.IO_ERROR, onError);

					var fullBitmap:BitmapData = ImageUtils.mergeBitmaps(graphList, _localFile);

					file.save(fullBitmap.encode(new Rectangle(0, 0, fullBitmap.width, fullBitmap.height), new PNGEncoderOptions()),
						Path.withExtension(name, 'png'));

					onSelect(new Event(Event.SELECT));
				}, 2000);

				_saveToPhases = 1;
			}
			else if (_saveToPhases == 1)
			{
				file = null;

				haxe.Timer.delay(function()
				{
					_saveToPhases = 0;
					_save = false;

					file = new File();

					file.addEventListener(Event.COMPLETE, onComplete);
					file.addEventListener(Event.CANCEL, onCancel);
					file.addEventListener(IOErrorEvent.IO_ERROR, onError);

					file.save(Serializer.run(_localFile), Path.withExtension(name, 'hash'));

					_localFile = {list: [], hash: []};
				}, 2000);
			}
		}
		else
		{
			file?.removeEventListener(Event.SELECT, onSelect);
			file?.removeEventListener(Event.COMPLETE, onComplete);
			file?.removeEventListener(Event.CANCEL, onCancel);
			file?.removeEventListener(IOErrorEvent.IO_ERROR, onError);

			file.load();

			var suffix:Int = 0;
			if (imageDataList.length > 0)
			{
				for (image in imageDataList)
				{
					if (image.name == Path.withoutExtension(file.name))
						suffix++;
				}
			}

			var name:String = Path.withoutExtension(file.name);

			if (suffix > 0)
				name += '_$suffix';

			var imageGraphic:FlxGraphic = FlxGraphic.fromBitmapData(BitmapData.fromBytes(Bytes.ofData(file.data)), false, name);
			imageGraphic.persist = true;

			if (!mapHash.exists(name))
				mapHash.set(name, imageGraphic);
			imageDataList.push({name: name, image: imageGraphic});
			imageList.add(name, imageList.children.length);

			_saveToPhases = 0;
		}

		file = null;
	}

	private function onSelectMultiple(e:FileListEvent):Void
	{
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
			if (imageDataList.length > 0)
			{
				for (image in imageDataList)
				{
					if (image.name == Path.withoutExtension(newFile.name))
						suffix++;
				}
			}

			var name:String = Path.withoutExtension(newFile.name);

			if (suffix > 0)
				name += '_$suffix';

			var imageGraphic:FlxGraphic = FlxGraphic.fromBitmapData(BitmapData.fromBytes(Bytes.ofData(newFile.data)), false, name);
			imageGraphic.persist = true;

			if (!mapHash.exists(name))
				mapHash.set(name, imageGraphic);
			imageDataList.push({name: name, image: imageGraphic});
			imageList.add(name, imageList.children.length);
		}

		file = null;
	}

	private var _saveToPhases:Int = 0;
	private var _localFile:SourceFile = {list: [], hash: []};

	private function onComplete(e:Event):Void
	{
		persistentUpdate = true;

		file.removeEventListener(Event.COMPLETE, onComplete);
		if (file.hasEventListener(FileListEvent.SELECT_MULTIPLE))
			file.removeEventListener(FileListEvent.SELECT_MULTIPLE, onSelectMultiple);
		file.removeEventListener(Event.CANCEL, onCancel);
		file.removeEventListener(IOErrorEvent.IO_ERROR, onError);

		file = null;
	}

	private function onCancel(e:Event):Void
	{
		persistentUpdate = true;

		file?.removeEventListener(Event.COMPLETE, onComplete);
		file?.removeEventListener(Event.CANCEL, onCancel);
		file?.removeEventListener(IOErrorEvent.IO_ERROR, onError);

		_saveToPhases = 0;

		file = null;
	}

	private function onError(e:IOErrorEvent):Void
	{
		persistentUpdate = true;

		file?.removeEventListener(Event.COMPLETE, onComplete);
		file?.removeEventListener(Event.CANCEL, onCancel);
		file?.removeEventListener(IOErrorEvent.IO_ERROR, onError);

		_saveToPhases = 0;

		FlxG.log.error('There was an issue saving, message: ${e.toString()}');

		file = null;
	}

	function get_animName():String
	{
		return nameList[_selectedAnim];
	}

	function set_animName(Value:String):String
	{
		return (nameList[_selectedAnim] = Value);
	}

	function get_looped():Bool
	{
		return animations[_selectedAnim].looped;
	}

	function set_looped(Value:Bool):Bool
	{
		return (animations[_selectedAnim].looped = Value);
	}

	function get_fps():Float
	{
		return animations[_selectedAnim].fps;
	}

	function set_fps(Value:Float):Float
	{
		return (animations[_selectedAnim].fps = Value);
	}

	function get_frameList():Array<String>
	{
		return animations[_selectedAnim].frames;
	}

	function set_frameList(Value:Array<String>):Array<String>
	{
		return (animations[_selectedAnim].frames = Value);
	}

	function get_frameOffset():Array<SimplePoint>
	{
		return animations[_selectedAnim].offsets;
	}

	function set_frameOffset(Value:Array<SimplePoint>):Array<SimplePoint>
	{
		return (animations[_selectedAnim].offsets = Value);
	}
}

typedef AnimationInfo =
{
	var name:String;
	var offsets:Array<SimplePoint>;
	var frames:Array<String>;
	var looped:Bool;
	var fps:Float;
}

typedef SimplePoint =
{
	var x:Int;
	var y:Int;
}

typedef ImageData =
{
	var name:String;
	var image:FlxGraphic;
}

enum UpdateInputPriority
{
	DRAG_PREVIEW;
	DRAG_CAMERA;
}
