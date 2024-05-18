package ui.editor;

import states.editors.AnimationEditorState;

class List extends FlxSprite
{
	public var children:Array<Children> = [];

	public var bgColor:FlxColor = 0xFF222529;
	public var buttonColor:FlxColor = 0xFF111213;
	public var buttonHoverColor:FlxColor = 0xFF5788C0;
	public var buttonSelectColor:FlxColor = 0xFF707070;
	public var buttonSelectedColor:FlxColor = 0xFF383F46;

	public var onClick:Int->Void;
	public var onHover:Int->Void;

	public var globalClipRect:FlxRect;

	public var selected:Int = -1;

	override public function new(?x:Float = 0, ?y:Float = 0, ?width:Int = 160, ?height:Int = 226)
	{
		super(x, y);

		height = height + 16;

		globalClipRect = FlxRect.get(x, y, width, height);

		makeGraphic(width, height, 0x0);
		FlxSpriteUtil.drawRoundRect(this, 0.0, 0.0, width, height, 8.0, 8.0, 0xFFFFFFFF);
		color = bgColor;
	}

	override public function update(elapsed:Float)
	{
		if (FlxG.mouse.overlaps(this, camera))
		{
			if (FlxG.mouse.wheel != 0)
			{
				var _lastScroll:Int = _scrollVert;

				_scrollVert = (FlxMath.bound(_scrollVert - FlxG.mouse.wheel, 0, children.length - 7)).floor();

				if (_lastScroll != _scrollVert)
					refreshList();
			}

			if (FlxG.mouse.justPressed)
			{
				if (selected != -1)
					selected = -1;

				return;
			}
		}

		for (child in children)
		{
			if (child.exists && child.active)
				child.update(elapsed);
		}
	}

	override public function draw()
	{
		super.draw();

		for (child in children)
		{
			if (child.exists && child.visible)
				child.draw();
		}
	}

	public function add(name:String, index:Int):Void
	{
		var child:Children = new Children(4.0, 4.0, this, name);
		child.ID = children.length;
		children.insert(index, child);

		child.camera = this.camera;

		refreshList();
	}

	public function remove(index:Int):Void
	{
		if (children.indexOf(children[index]) != -1)
		{
			var actualChild:Children = children[index];
			children.remove(children[index]);

			for (i in 0...children.length)
				children[i].ID = i;

			if (selected == index)
				selected = -1;

			actualChild.destroy();

			refreshList();
		}
	}

	private var _scrollVert:Int = 0;

	public function refreshList():Void
	{
		globalClipRect.set(x, y, width, height);

		var actualStart:Int = 0;

		for (i in 0...children.length)
		{
			var child:Children = children[i];

			child.y = y + 4 + ((child.height + 4) * actualStart);
			child.clipRect = Utilities.calcRelativeRect(child, globalClipRect);

			child.exists = (child.ID >= _scrollVert && child.y < y + height);

			if (child.exists)
				actualStart++;
		}
	}

	override function set_camera(Value:FlxCamera):FlxCamera
	{
		if (_cameras == null)
			_cameras = [Value];
		else
			_cameras[0] = Value;

		for (child in children)
			child.camera = Value;

		return Value;
	}

	override public function loadGraphic(graphic:FlxGraphicAsset, animated = false, frameWidth = 0, frameHeight = 0, unique = false, ?key:String):FlxSprite
	{
		throw "Cannot call loadGraphic() on editor.List";
	}
}

class Children extends FlxSprite
{
	public static final NORMAL:Int = 0;
	public static final HIGHLIGHT:Int = 1;
	public static final PRESS:Int = 2;

	public var status:Int = NORMAL;

	public var parent:List;
	public var textObj:TextList;

	public var objOffset:FlxPoint;

	override public function new(?xOffset:Float = 0, ?yOffset:Float = 0, parent:List, name:String)
	{
		super(parent.x + xOffset, parent.y + yOffset);

		objOffset = FlxPoint.get(xOffset, yOffset);

		this.parent = parent;

		makeGraphic((parent.width - 8).floor(), 30, 0x0);
		FlxSpriteUtil.drawRoundRect(this, 0.0, 0.0, (parent.width - 8).floor(), 30, 8.0, 8.0, 0xFFFFFFFF);
		color = parent.buttonColor;

		textObj = new TextList(parent.x + xOffset + 4, y, 0, name);
		textObj.setFormat(null, (12 * 4).floor());
		textObj.font = Assets.font("editor").fontName;
		textObj.scale.set(0.25, 0.25);
		textObj.updateHitbox();
		textObj.setPosition(parent.x + xOffset + 4, y);
		textObj.antialiasing = true;
		textObj.color = AnimationEditorState.mainTextColor;

		Utilities.centerOverlay(textObj, this, Y);

		moves = false;
		textObj.active = false;
	}

	private var _hovered:Bool = false;

	override public function update(elapsed:Float)
	{
		Utilities.centerOverlay(textObj, this, Y);
		textObj.x = parent.x + objOffset.x;

		if (FlxG.mouse.overlaps(this, camera))
		{
			status = HIGHLIGHT;

			if (!_hovered)
			{
				if (parent.onHover != null)
					parent.onHover(ID);

				_hovered = true;
			}

			if (FlxG.mouse.pressed)
				status = PRESS;

			if (FlxG.mouse.justReleased)
			{
				status = PRESS;
				parent.selected = ID;

				if (parent.onClick != null)
					parent.onClick(ID);
			}
		}
		else
		{
			status = NORMAL;

			_hovered = false;
		}

		switch (status)
		{
			case NORMAL:
				if (parent.selected == ID)
					color = parent.buttonSelectedColor;
				else
					color = parent.buttonColor;
			case HIGHLIGHT:
				color = parent.buttonHoverColor;
			case PRESS:
				color = parent.buttonSelectedColor;
		}
	}

	override function draw()
	{
		super.draw();

		textObj.draw();
	}

	override function set_camera(Value:FlxCamera):FlxCamera
	{
		if (_cameras == null)
			_cameras = [Value];
		else
			_cameras[0] = Value;

		textObj.camera = Value;

		return Value;
	}

	override public function destroy()
	{
		textObj?.destroy();
		super.destroy();
	}
}

class TextList extends FlxText
{
	override function set_text(Text:String):String
	{
		super.set_text(Text);
		updateHitbox();

		return (text = Text);
	}
}
