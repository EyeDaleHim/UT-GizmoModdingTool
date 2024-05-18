package objects.overworld;

typedef Decal =
{
    var graphic:String; // path, usually "overworld/tiles/$graphic"

    var x:Float;
    var y:Float;
    var layer:Int;

    var scrollX:Float;
    var scrollY:Float;

    @:optional var graphReplacement:FlxGraphic; // used for the editor
    @:optional var editorSelected:Bool;
    @:optional var frame:FlxImageFrame; // auto defined
};