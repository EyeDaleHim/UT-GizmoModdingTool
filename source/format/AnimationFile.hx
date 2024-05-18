package format;

typedef AnimationFile = Array<Animation>;

typedef Animation =
{
    var name:String;
    var frames:Array<SourceHash>;

    var offsetsX:Array<Int>;
    var offsetsY:Array<Int>;

    var fps:Float;
    var looped:Bool;
}