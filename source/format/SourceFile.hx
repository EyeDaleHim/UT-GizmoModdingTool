package format;

typedef SourceFile = {
    var list:Array<SourceImage>;
    var hash:Array<SourceHash>;
};

typedef SourceImage = {
    var x:Int;
    var y:Int;
    var width:Int;
    var height:Int;
};

typedef SourceHash = {
    var name:String;
    var index:Int;
}