package ui.battle;

class BattleButton extends FlxSprite
{
    public var selectedGraph:FlxGraphic;
    public var normalGraph:FlxGraphic;

    override public function new(?x:Float = 0, ?y:Float = 0, button:String)
    {
        normalGraph = Assets.image('battle/ui/${button}_button');
        selectedGraph = Assets.image('battle/ui/${button}_select_button');

        super(x, y, normalGraph);
    }

    public var selected(default, set):Bool = false;

    function set_selected(Value:Bool):Bool
    {
        if (selected == Value)
            return selected;

        if (Value)
            loadGraphic(selectedGraph);
        else
            loadGraphic(normalGraph);

        return (selected = Value);
    }
}