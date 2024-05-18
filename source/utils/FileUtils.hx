package utils;

class FileUtils
{
	public inline static function pureFilename(fullPath:String)
		return Path.withoutDirectory(Path.withoutExtension(fullPath));
}
