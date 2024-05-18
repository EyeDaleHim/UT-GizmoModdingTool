package objects.overworld;

typedef Node =
{
    @:optional var x:Float;
    @:optional var y:Float;

    @:optional var tag:String;

    @:optional var type:Int; // 0 = event, 1 = interact, 2 = room, 3 = spawn
    @:optional var contexts:Array<Dynamic>;

    @:optional var graphReplacement:FlxGraphic; // used for the editor
    @:optional var editorSelected:Bool;
}