package ui.text;

class Textbox extends FlxSprite
{
    public var borderColor(default, set):FlxColor = 0xFFFFFFFF;
    public var bgColor(default, set):FlxColor = 0xFF000000;
    public var borderSize(default, set):Int = 6;

    public override function new(?X:Float = 0, ?Y:Float = 0, ?Width:Int = 578, ?Height:Int = 152, bgColor:Int = 0xFF000000)
    {
        super(X, Y);

        makeGraphic(Width, Height, FlxColor.TRANSPARENT, true);
        setBorderFormat(this.borderColor, this.borderSize);
    }

    public function setBorderFormat(borderColor:FlxColor, borderSize:Int):Void
    {
        if (borderSize <= 0 || borderColor.alpha == 0)
            return;

        makeGraphic(width.floor(), height.floor(), borderColor);

        this.borderColor = borderColor;
        this.borderSize = borderSize;
    }

    function set_borderColor(Value:FlxColor)
    {
        pixels.lock();
        pixels.fillRect(new Rectangle(0, 0, borderSize, height), Value); // left border
        pixels.fillRect(new Rectangle(0, 0, width, borderSize), Value); // top border
        pixels.fillRect(new Rectangle(0, height - borderSize, width, borderSize), Value); // bottom border
        pixels.fillRect(new Rectangle(width - borderSize, 0, borderSize, height), Value); // right border
        pixels.unlock();

        return (borderColor = Value);
    }

    function set_bgColor(Value:FlxColor)
    {
        pixels.lock();
        pixels.fillRect(new Rectangle(borderSize, borderSize, width - (borderSize * 2), height - (borderSize * 2)), Value);
        pixels.unlock();

        return (bgColor = Value);
    }

    function set_borderSize(Value:Int)
    {
        borderSize = Value;

        borderColor = borderColor;
        bgColor = bgColor;
        
        return Value;
    }
}