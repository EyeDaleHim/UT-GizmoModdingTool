package utils.tools;

class ArrayUtils
{
	public inline static function indexOfCustom<T>(arr:Array<T>, x:T, ?fromIndex:Int = 0, ?toIndex:Int = null):Int
	{
		if (fromIndex < 0)
			fromIndex = 0;
		if (toIndex == null || toIndex > arr.length)
			toIndex = arr.length;

		for (i in fromIndex...toIndex)
		{
			if (arr[i] == x)
				return i;
		}

		return -1; // If not found
	}
}
