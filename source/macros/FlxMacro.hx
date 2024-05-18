package macros;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Expr.Field;
import haxe.macro.Type.ClassType;

class FlxMacro
{
	/**
	 * A macro to be called targeting the `FlxBasic` class.
	 * @return An array of fields that the class contains.
	 */
	public static macro function buildFlxBasic():Array<Field>
	{
		var pos:Position = Context.currentPos();
		// The FlxBasic class. We can add new properties to this class.
		var cls:haxe.macro.Type.ClassType = Context.getLocalClass().get();
		// The fields of the FlxClass.
		var fields:Array<Field> = Context.getBuildFields();

		fields = fields.concat([
			{
				name: "customData", // Field name.
				access: [Access.APublic], // Access level
				kind: FieldType.FVar(macro :Map<String, Dynamic>, macro $v{new Map<String, Dynamic>()}), // Variable type and default value
				pos: pos, // The field's position in code.
			}
		]);

		return fields;
	}

	/**
	 * A macro to be called targeting the `FlxObject` class.
	 * @return An array of fields that the class contains.
	 */
	public static macro function buildFlxObject():Array<Field>
	{
		var pos:Position = Context.currentPos();
		// The FlxObject class. We can add new properties to this class.
		var cls:haxe.macro.Type.ClassType = Context.getLocalClass().get();
		// The fields of the FlxClass.
		var fields:Array<Field> = Context.getBuildFields();

		var xProp:Expr;
		var yProp:Expr;
		var widthProp:Expr;
		var heightProp:Expr;

		for (field in fields)
		{
			switch (field.kind)
			{
				case FVar(t, e):
				case _:
			}
		}

		return fields;
	}
}
