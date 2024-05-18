#if !macro
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.FlxObject;

import flixel.addons.ui.FlxUIState; // import this cuz its not being detected by the console?

import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxImageFrame;
import flixel.graphics.frames.FlxFrame;

import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;

import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.math.FlxMatrix;

import flixel.text.FlxText;

import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

import flixel.util.FlxAxes;
import flixel.util.FlxColor;
import flixel.util.FlxSave;
import flixel.util.FlxSort;
import flixel.util.FlxSpriteUtil;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxDirectionFlags;
import flixel.util.FlxTimer;
import flixel.util.helpers.FlxBounds;

import flixel.sound.FlxSound;

import flixel.system.FlxAssets;
import flixel.system.FlxAssets.FlxGraphicAsset;

import flixel.input.keyboard.FlxKey;

import format.AnimationFile;
import format.RoomFile;
import format.SourceFile;

import objects.AnimatedSprite;
import objects.Player;
import objects.Soul;
import objects.Splash;

import objects.overworld.Tile;
import objects.overworld.Decal;
import objects.overworld.Collision;
import objects.overworld.Node;

import system.Assets;
import system.api.DiscordHandler;

import system.input.Controls;
import system.input.Controls.KeyShortcut;
import system.input.InputHelper;

import system.save.Story;

import system.world.World;
import system.world.Room;

import ui.BoxSprite;

import ui.battle.BattleButton;

import ui.text.Dialogue;
import ui.text.Textbox;
import ui.text.TypeText;
import ui.text.TypeCharacter;

import utils.logging.Logs;

import utils.ImageUtils;

import ui.editor.*;
#end

import openfl.display.BitmapData;
import openfl.geom.Rectangle;
import openfl.geom.Point;
import openfl.geom.ColorTransform;

import sys.FileSystem;
import sys.io.File;

import haxe.io.Bytes;
import haxe.io.Path;
import haxe.Json;

import haxe.Serializer;
import haxe.Unserializer;

using Math;
using StringTools;
using Lambda;

#if !macro
using utils.tools.ArrayUtils;
using utils.tools.CameraUtils;

using utils.FileUtils;
using utils.InputUtils;
using utils.Utilities;
#end