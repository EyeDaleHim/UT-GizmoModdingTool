package format;

// note to self: if they're animated, they're handled automatically so don't bother
typedef RoomFile =
{
    @:optional var tiles:Array<TileData>;
    @:optional var decals:Array<DecalData>;
    @:optional var collisions:Array<CollisionData>;
    @:optional var nodes:Array<NodeData>;

    @:optional var cameraLock:CameraLock;

    @:optional var bg_music:String;
    @:optional var name:String;
};

typedef CameraLock = {
    @:optional var x:Float;
    @:optional var y:Float;
    @:optional var width:Float;
    @:optional var height:Float;
}

typedef TileData = {
    @:optional var img:String;
    @:optional var x:Int; // in tile pos
    @:optional var y:Int;
    @:optional var layer:Int;
};

typedef DecalData = {
    @:optional var img:String;
    @:optional var x:Float;
    @:optional var y:Float;
    @:optional var layer:Int;
    @:optional var scrollX:Float;
    @:optional var scrollY:Float;
};


typedef CollisionData = {
    @:optional var x:Float;
    @:optional var y:Float;
    @:optional var width:Float;
    @:optional var height:Float;
    @:optional var type:Int;
}

typedef NodeData = {
    @:optional var x:Float;
    @:optional var y:Float;

    @:optional var tag:String;
    @:optional var type:Int;
    @:optional var context:Array<Dynamic>;
};