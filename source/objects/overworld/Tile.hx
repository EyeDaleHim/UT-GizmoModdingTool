package objects.overworld;

typedef Tile =
{
    var graphic:String; // path, usually "overworld/tiles/$graphic"

    var tileX:Int;
    var tileY:Int;
    var tileLayer:Int;

    @:optional var unique:Bool;

    @:optional var graphReplacement:FlxGraphic; // used for the editor
    @:optional var editorSelected:Bool;
    @:optional var frame:FlxImageFrame; // auto defined
}