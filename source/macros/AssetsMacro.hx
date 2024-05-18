package macros;

import haxe.io.Bytes;
import haxe.io.Path;
import haxe.macro.*;
import haxe.macro.Expr.Access;
import haxe.macro.Expr.Case;
import haxe.macro.Expr.Field;
import haxe.macro.Expr.MetadataEntry;
import openfl.utils.ByteArray;

class AssetsMacro
{
	private static var cwd:String = Sys.getCwd();
	private static var ignoredExtensions:Array<String> = ['mp3'];

	public static macro function build()
	{
		var _mappedAssets:Map<String, Bytes> = [];

		var exportLocation:String = 'export/x64/';

		#if debug
		exportLocation += 'debug/';
		#elseif release
		exportLocation += 'release/';
		#else
		exportLocation += 'final/';
		#end
		exportLocation += 'hl/bin/';

		function embedFile(filePath:String)
		{
			if (!ignoredExtensions.contains(Path.extension(filePath)))
				File.copy(filePath, Path.join([cwd, exportLocation, filePath.substring(cwd.length)]));
		}

		var parentPath = Path.join([cwd, 'assets']);

		function readDirectory(fullPath)
		{
			for (path in FileSystem.readDirectory(fullPath))
			{
				var actual = Path.join([fullPath, path]);

				if (FileSystem.isDirectory(actual))
				{
					if (!FileSystem.exists(Path.join([cwd, exportLocation, actual.substring(cwd.length)])))
						FileSystem.createDirectory(Path.join([cwd, exportLocation, actual.substring(cwd.length)]));
					readDirectory(actual);
				}
				else
					embedFile(actual);
			}
		}

		readDirectory(parentPath);

		return macro
		{};
	}
}
