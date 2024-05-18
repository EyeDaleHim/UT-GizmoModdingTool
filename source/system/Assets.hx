package system;

import flixel.graphics.frames.FlxFrame.FlxFrameAngle;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.FlxGraphic;
import lime.media.AudioBuffer;
import openfl.display.BitmapData;
import openfl.display3D.Context3D;
import openfl.display3D.textures.RectangleTexture;
import openfl.media.Sound;
import openfl.text.Font;
import openfl.system.System;

class Assets
{
	private static final soundExt:Array<String> = ['ogg', 'wav', 'mp3']; // whichever comes first, lol!

	private static var fonts:Map<String, Font> = [];

	private static var trackedGraphs:Map<String, FlxGraphic> = [];
	private static var trackedSounds:Map<String, Sound> = [];

	private static var permanentCache:Array<String> = [];

	public static function cleanMemory():Void
	{
		for (key => graph in trackedGraphs)
		{
			if (!permanentCache.contains(key) && graph.useCount <= 0)
			{
				graph.dump();
				graph.destroy();

				trackedGraphs.remove(key);

				graph = null;
			}
		}

		for (key => sound in trackedSounds)
		{
			if (!permanentCache.contains(key))
			{
				sound.close();
				sound = null;

				trackedSounds.remove(key);

				sound = null;
			}
		}

		System.gc();
	}

	// path functions
	inline public static function assetPath(path:String):String
		return 'assets/$path';

	inline public static function imagePath(path:String):String
		return assetPath('images/$path.png');

	inline public static function soundPath(path:String):String
		return assetPath('sounds/$path');

	inline public static function musicPath(path:String):String
		return soundPath('music/$path');

	inline public static function sfxPath(path:String):String
		return soundPath('sfx/$path');

	inline public static function fontPath(path:String):String
		return assetPath('fonts/$path.ttf');

	public static function exists(path:String):Bool
	{
		#if sys
		return FileSystem.exists(path);
		#elseif web
		return OpenFlAssets.exists(path);
		#else
		return false;
		#end
	}

	public static function getContent(path:String):String
	{
		var content:String = "";
		#if sys
		content = File.getContent(path);
		#elseif web
		content = OpenFlAssets.getText(path);
		#end

		return content;
	}

	public static function getBytes(path:String):Bytes
	{
		var bytes:Bytes = null;
		#if sys
		bytes = File.getBytes(path);
		#elseif web
		bytes = OpenFlAssets.getBytes(path);
		#end

		return bytes;
	}

	// general functions
	public static function image(path:String, hardware:Bool = true, cacheForever:Bool = false):FlxGraphic
	{
		var bitmap:BitmapData = null;
		var file:String = imagePath(path);

		if (trackedGraphs.exists(file))
		{
			var graph:FlxGraphic = trackedGraphs.get(file);

			return graph;
		}
		else if (Assets.exists(file))
			bitmap = BitmapData.fromBytes(Assets.getBytes(file));

		if (bitmap != null)
		{
			#if sys
			/*if (hardware)
			{
				@:privateAccess {
					bitmap.lock();
					if (bitmap.__texture == null) {
						bitmap.image.premultiplied = true;
						bitmap.getTexture(FlxG.stage.context3D);
					}
					bitmap.getSurface();
					bitmap.disposeImage();
					bitmap.image.data = null;
					bitmap.image = null;
					bitmap.readable = true;
				}
			}*/
			#end

			var graph:FlxGraphic = FlxGraphic.fromBitmapData(bitmap, false, file);
			graph.persist = true;
			graph.destroyOnNoUse = false;

			if (cacheForever && !permanentCache.contains(path))
				permanentCache.push(path);

			return graph;
		}

		trace('Could not find $path ($file)');

		return FlxGraphic.fromBitmapData(FlxAssets.getBitmapData("flixel/images/logo/default.png"));
	}

	public static function sound(path:String, category:String, cacheForever:Bool = false):Sound
	{
		var soundObj:Sound = new Sound();
		var file:String = "";

		switch (category)
		{
			case "music":
				file = musicPath(path);
			case "sfx":
				file = sfxPath(path);
			default:
				file = soundPath(path);
		}

		if (!trackedSounds.exists(path))
		{
			for (ext in soundExt)
			{
				var fileExt:String = Path.withExtension(file, ext);
				if (Assets.exists(fileExt))
				{
					var buffer:AudioBuffer = AudioBuffer.fromBytes(Assets.getBytes(fileExt));
					soundObj = Sound.fromAudioBuffer(buffer);

					trackedSounds.set(path, soundObj);

					if (cacheForever && !permanentCache.contains(path))
						permanentCache.push(path);

					break;
				}
			}
		}
		else
			soundObj = trackedSounds.get(path);

		if (soundObj == null)
			trace('Could not find $path');

		return soundObj;
	}

	public static function font(path:String):Font
	{
		var font:Font = null;
		var file:String = fontPath(path);

		if (fonts.exists(path))
			font = fonts.get(path);
		else
		{
			fonts.set(path, Font.fromBytes(Assets.getBytes(file)));
			font = Assets.font(path);

			Font.registerFont(font);
		}

		return font;
	}

	public static function frames(imagePath:String):FlxAtlasFrames
	{
		var imageSrc:FlxGraphic = image(imagePath);
		if (imageSrc == null)
			return null;

		var frames:FlxAtlasFrames = FlxAtlasFrames.findFrame(imageSrc);
		if (frames != null)
			return frames;

		var hashSrc:SourceFile = null;
		var hashPath:String = Path.withExtension(Path.withoutExtension(Assets.imagePath(imagePath)), 'hash');

		if (Assets.exists(hashPath))
			hashSrc = Unserializer.run(Assets.getContent(hashPath));
		else
			trace(hashPath);

		if (hashSrc == null)
			return null;

		frames = new FlxAtlasFrames(imageSrc);

		for (texture in hashSrc.hash)
		{
			var textureInList:SourceImage = hashSrc.list[texture.index];

			var name = texture.name;
			var rect = FlxRect.get(textureInList.x, textureInList.y, textureInList.width, textureInList.height);

			frames.addAtlasFrame(rect, FlxPoint.get(rect.width, rect.height), FlxPoint.get(), name, FlxFrameAngle.ANGLE_0, false, false);
		}

		return frames;
	}
}