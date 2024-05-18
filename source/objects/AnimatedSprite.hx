package objects;

import format.AnimationFile;
import flixel.graphics.frames.FlxImageFrame;

class AnimatedSprite extends FlxSprite
{
    public var animationList:AnimationFile;
    public var offsetMap:Map<String, Array<FlxPoint>> = [];

    override public function new(?X:Float = 0, ?Y:Float = 0, name:String)
    {
        super(X, Y);

        frames = Assets.frames(name);

        var file:String = Path.withExtension(Path.withoutExtension(Assets.imagePath(name)), "json");
        if (FileSystem.exists(file))
            animationList = Json.parse(File.getContent(file));

        for (anim in animationList)
        {
            var frameList:Array<String> = [];

            for (frame in anim.frames)
                frameList.push(frame.name);

            var maxOffsetsLen:Int = Std.int(Math.max(anim.offsetsX.length, anim.offsetsY.length));
            offsetMap.set(anim.name, [for (i in 0...maxOffsetsLen) FlxPoint.get()]);

            for (i in 0...anim.offsetsX.length)
                offsetMap.get(anim.name)[i].x = anim.offsetsX[i];

            for (i in 0...anim.offsetsY.length)
                offsetMap.get(anim.name)[i].y = anim.offsetsY[i];


            animation.addByStringIndices(anim.name, "", frameList, "", anim.fps, anim.looped);
        }
    }

    override public function update(elapsed:Float)
    {
        if (animation.curAnim != null && offsetMap.exists(animation.curAnim.name))
        {
            offset.copyFrom(offsetMap.get(animation.curAnim.name)[animation.curAnim.curFrame]);
            offset.negate();
        }

        super.update(elapsed);
    }
}

typedef AnimationFrames = {
    var name:String;
    var framerate:Float;
    var offsets:{x:Int, y:Int};
    var scale:{x:Float, y:Float};
    var looped:Bool;
    var graphics:Array<String>;
}