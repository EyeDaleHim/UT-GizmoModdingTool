package system.input;

import openfl.display.Bitmap;
import openfl.display.Sprite;

// FlxG.mouse is unreliable!!! this is a nasty workaround!
class Cursor extends Sprite
{
    public var skins:Map<String, BitmapData> = [];

    public var bitmap:Bitmap;

    override public function new()
    {
        super();

        bitmap = new Bitmap();
        loadSkin('cursor');
        addChild(bitmap);
    }

    public function loadSkin(cursor:String, XOffset:Float = 0.0, YOffset:Float = 0.0)
    {
        if (skins.exists(cursor))
        {
            bitmap.bitmapData = skins.get(cursor);

            x = XOffset;
            y = YOffset;
        }
        else if (Assets.exists(Assets.imagePath('_debug/cursors/$cursor')))
        {
            skins.set(cursor, BitmapData.fromBytes(Assets.getBytes(Assets.imagePath('_debug/cursors/$cursor'))));
            inline loadSkin(cursor, XOffset, YOffset);
        }
        // else Logs.
    }
}