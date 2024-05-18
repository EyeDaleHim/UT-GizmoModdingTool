package ui.editor;

// Literally allows for high-quality text lol, kinda hacky
class TextObject extends FlxText
{
    override public function new(X:Float = 0, Y:Float = 0, FieldWidth:Float = 0, ?Text:String, Size:Int = 8, EmbeddedFont:Bool = true)
    {
        super(X, Y, FieldWidth, Text, EmbeddedFont);

        active = false;

        size = (Size * 4).floor();
        font = Assets.font("editor").fontName;

        scale.set(0.25, 0.25);
        updateHitbox();
        setPosition(X, Y);

        antialiasing = true;
    }
}