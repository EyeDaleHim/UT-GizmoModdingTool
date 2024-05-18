package system.save;

@:allow(Main)
class Story
{
    private static var _save:FlxSave;

    public static function save():Bool
        return _save.flush();

    public static function getData(name:String, ?defaultData:Dynamic):Dynamic
    {
        var data = Reflect.getProperty(_save.data, name);

        if (data == null)
            return defaultData;
        return data;
    }

    public static function setData(name:String, data:Dynamic)
        Reflect.setProperty(_save.data, name, data);

    public static function load():Void
        _save.bind("story", "underfell");
}