package objects.overworld;

typedef Collision = {
    @:optional var x:Float;
    @:optional var y:Float;
    @:optional var width:Float;
    @:optional var height:Float;

    @:optional var type:CollisionType;
    @:optional var editorSelected:Bool;

    @:optional var resizableSpr:ResizableSprite; // used for editor
}

enum abstract CollisionType(Int)
{
    var WALL:CollisionType = 0;
    var TOP_LEFT_STAIR:CollisionType = 1;
    var TOP_RIGHT_STAIR:CollisionType = 2;
    var BOT_LEFT_STAIR:CollisionType = 3;
    var BOT_RIGHT_STAIR:CollisionType = 4;
}