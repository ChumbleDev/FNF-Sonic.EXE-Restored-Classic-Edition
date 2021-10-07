package;

#if desktop
import Discord.DiscordClient;
#end

import openfl.ui.KeyLocation;
import openfl.events.Event;
import haxe.EnumTools;
import openfl.ui.Keyboard;
import openfl.events.KeyboardEvent;
import flixel.input.keyboard.FlxKey;
import haxe.Exception;
import openfl.geom.Matrix;
import openfl.display.BitmapData;
import openfl.utils.AssetType;
import lime.graphics.Image;
import flixel.graphics.FlxGraphic;
import openfl.utils.AssetManifest;
import openfl.utils.AssetLibrary;
import flixel.system.FlxAssets;

import lime.app.Application;
import lime.media.AudioContext;
import lime.media.AudioManager;
import openfl.Lib;
import Section.SwagSection;
import Song.SwagSong;
import SongEvent.EventsList;
import SongEvent.SwagEvent;
import WiggleEffect.WiggleEffectType;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.effects.FlxTrail;
import flixel.addons.effects.FlxTrailArea;
import flixel.addons.effects.chainable.FlxEffectSprite;
import flixel.addons.effects.chainable.FlxWaveEffect;
import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.atlas.FlxAtlas;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.util.FlxCollision;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import flixel.util.FlxTimer;
import haxe.Json;
import lime.utils.Assets;
import openfl.display.BlendMode;
import openfl.display.StageQuality;
import openfl.filters.ShaderFilter;
import Shaders;
import ModchartUtil;

#if sys
import flash.media.Sound;
#end

using StringTools;

class PlayState extends MusicBeatState
{
	//song stuff
	public static var curStage:String = '';
	public static var SONG:SwagSong;
	public static var isStoryMode:Bool = false;
	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var storyDifficulty:Int = 1;
	public static var mania:Int = 0;
	public static var maniaToChange:Int = 0;
	public static var keyAmmo:Array<Int> = [4, 6, 9, 5, 7, 8, 1, 2, 3];
	public static var EVENT:EventsList; //not added events yet
	public static var SongSpeed:Float;
	var songLength:Float = 0;
	private var vocals:FlxSound;
	private var curSong:String = "";

	//characters
	public static var dad:Boyfriend; //made dad a boyfriend class for flip mode and multiplayer, to fix anim stuff because it be like that
	public static var gf:Character;
	public static var boyfriend:Boyfriend;
	var oppenentColors:Array<Array<Float>>; //oppenents arrow colors and assets
	private var gfSpeed:Int = 1;
	private var health:Float = 1;
	private var P2health:Float = 1;

	//note stuff
	private var P1notes:FlxTypedGroup<Note>;
	private var P2notes:FlxTypedGroup<Note>;
	private var unspawnNotes:Array<Note> = []; //notes that are not rendered yet
	var noteSplashes:FlxTypedGroup<NoteSplash>;
	var P2noteSplashes:FlxTypedGroup<NoteSplash>;

	//sing animation arrays
	private var sDir:Array<String> = ['LEFT', 'DOWN', 'UP', 'RIGHT']; //regular singing animations
	private var bfsDir:Array<String> = ['LEFT', 'DOWN', 'UP', 'RIGHT']; //just for playing hey animation as bf

	//some more song stuff
	private var strumLine:FlxSprite; //the strumline (just for static arrow placement)
	private var curSection:Int = 0; //current section
	public var currentSection:SwagSection; //the current section again lol, but its actually the section not just a number

	//static arrows
	public static var strumLineNotes:FlxTypedGroup<BabyArrow> = null;
	public static var playerStrums:FlxTypedGroup<BabyArrow> = null;
	public static var cpuStrums:FlxTypedGroup<BabyArrow> = null;

	//score and stats
	public static var campaignScore:Int = 0;
	private var combo:Int = 0;
	var fc:Bool = true;
	var songScore:Int = 0;

	public var accuracy:Float = 0.00;
	public var ranksList:Array<String> = ["Skill Issue", "E", "D", "C", "B", "A", "S"]; //for score text
	public var curRank:String = "None"; //for score text
	public static var misses:Int = 0;
	public var sicks:Int = 0;
	public var goods:Int = 0;
	public var bads:Int = 0;
	public var shits:Int = 0;
	public var totalNotesHit:Int = 0;

	var scoreTxt:FlxText;
	var TimeText:FlxText;
	var songtext:String; //for time text
	
	//song stuff
	private var generatedMusic:Bool = false;
	private var startingSong:Bool = false;

	//hud shit
	public var iconP1:HealthIcon; 
	public var iconP2:HealthIcon;
	private var healthBarBG:FlxSprite;
	private var healthBar:FlxBar;

	//camera shit
	public var camHUD:FlxCamera;
	public var camSustains:FlxCamera;
	public var camP1Notes:FlxCamera;
	public var camP2Notes:FlxCamera;
	public var camOnTop:FlxCamera;
	private var camGame:FlxCamera;

	private var camZooming:Bool = false;
	private var camFollow:FlxObject;
	private static var prevCamFollow:FlxObject;
	var defaultCamZoom:Float = 1.05;

	//dialogue
	var dialogue:Array<String> = ['blah blah blah', 'coolswag'];
	var talking:Bool = true;
	var inCutscene:Bool = false;

	//stages
	public var dancingStagePieces:FlxTypedGroup<StagePiece>; //for stage pieces that bop/dance/whatever every beat, no need for a variable/hx
	var stageException:Bool = false; //just used for week 6 stage, because of its weird set graphic size shit
	var stageOffsets:Map<String, Array<Dynamic>>;
	var phillyCityLights:FlxTypedGroup<FlxSprite>;
	var phillyTrain:FlxSprite;
	var trainSound:FlxSound;
	var limo:StagePiece; //for the shitty layering

	//some extra random stuff i didnt know where to put
	var wiggleShit:WiggleEffect = new WiggleEffect();
	var grace:Bool = false;
	var maniaChanged:Bool = false;

	// how big to stretch the pixel art assets
	public static var daPixelZoom:Float = 6;

	//for testing
	var NormalInput:Bool = true;
	var CustomInput:Bool = false;

	//for flip and multiplayer
	public static var flipped:Bool = false;
	public static var multiplayer:Bool = false;
	var player:Boyfriend;
	var player2:Boyfriend;
	var cpu:Boyfriend;


	#if desktop
	// Discord RPC variables
	var storyDifficultyText:String = "";
	var iconRPC:String = "";
	var detailsText:String = "";
	var detailsPausedText:String = "";
	#end
	override public function create()
	{
		FlxG.mouse.visible = false;

		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		var songLowercase = PlayState.SONG.song.toLowerCase();

		songtext = PlayState.SONG.song + " - " + CoolUtil.CurSongDiffs[storyDifficulty];

		noteSplashes = new FlxTypedGroup<NoteSplash>(); //note splash spawning before the song
		var daSplash = new NoteSplash(100, 100, 0);
		daSplash.alpha = 0;
		noteSplashes.add(daSplash);

		misses = 0; //reset that shit

		camGame = new FlxCamera();
		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		camSustains = new FlxCamera();
		camSustains.bgColor.alpha = 0;
		camP1Notes = new FlxCamera();
		camP1Notes.bgColor.alpha = 0;
		camP2Notes = new FlxCamera();
		camP2Notes.bgColor.alpha = 0;
		camOnTop = new FlxCamera();
		camOnTop.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD);
		FlxG.cameras.add(camSustains);
		FlxG.cameras.add(camP1Notes);
		FlxG.cameras.add(camP2Notes);
		FlxG.cameras.add(camOnTop);
		

		FlxCamera.defaultCameras = [camGame];

		PlayerSettings.player1.controls.loadKeyBinds();

		if (FlxG.save.data.flip)
			flipped = true;
		else
			flipped = false;

		persistentUpdate = true;
		persistentDraw = true;

		if (SaveData.downscroll) //im not sure if this is the smartest or the stupidest way of doing downscroll
		{
			camP1Notes.flashSprite.scaleY *= -1;
		}
		if (SaveData.P2downscroll) //im not sure if this is the smartest or the stupidest way of doing downscroll
		{
			camP2Notes.flashSprite.scaleY *= -1;
		}

		mania = SONG.mania; //setting the manias

		//if (PlayStateChangeables.bothSide)
			//mania = 5;
		//else if (FlxG.save.data.mania != 0 && PlayStateChangeables.randomNotes)
			//mania = FlxG.save.data.mania;

		maniaToChange = mania;

		Note.scaleSwitch = true;

		if (SONG == null)
			SONG = Song.loadFromJson('tutorial');

		Conductor.mapBPMChanges(SONG);
		Conductor.changeBPM(SONG.bpm);

		SongSpeed = FlxMath.roundDecimal(SONG.speed, 2);

		var EventFile:String = Paths.json(SONG.song.toLowerCase() + '/events');
		if (Assets.exists(EventFile))											//unfinished event code!
		{
			PlayState.EVENT = SongEvent.loadFromJson('events', SONG.song.toLowerCase());
			eventsEnabled = true;
		}

		switch (SONG.song.toLowerCase()) //dialogue
		{
			case 'tutorial':
				dialogue = ["Hey you're pretty cute.", 'Use the arrow keys to keep up \nwith me singing.'];
			case 'bopeebo':
				dialogue = [
					'HEY!',
					"You think you can just sing\nwith my daughter like that?",
					"If you want to date her...",
					"You're going to have to go \nthrough ME first!"
				];
			case 'fresh':
				dialogue = ["Not too shabby boy.", ""];
			case 'dadbattle':
				dialogue = [
					"gah you think you're hot stuff?",
					"If you can beat me here...",
					"Only then I will even CONSIDER letting you\ndate my daughter!"
				];
			case 'senpai':
				dialogue = CoolUtil.coolTextFile(Paths.txt('charts/senpai/senpaiDialogue'));
			case 'roses':
				dialogue = CoolUtil.coolTextFile(Paths.txt('charts/roses/rosesDialogue'));
			case 'thorns':
				dialogue = CoolUtil.coolTextFile(Paths.txt('charts/thorns/thornsDialogue'));
		}

		#if desktop
		// Making difficulty text for Discord Rich Presence.
		switch (storyDifficulty)
		{
			case 0:
				storyDifficultyText = "Easy";
			case 1:
				storyDifficultyText = "Normal";
			case 2:
				storyDifficultyText = "Hard";
		}

		iconRPC = SONG.player2;

		// To avoid having duplicate images in Discord assets
		switch (iconRPC)
		{
			case 'senpai-angry':
				iconRPC = 'senpai';
			case 'monster-christmas':
				iconRPC = 'monster';
			case 'mom-car':
				iconRPC = 'mom';
		}

		// String that contains the mode defined here so it isn't necessary to call changePresence for each mode
		if (isStoryMode)
		{
			detailsText = "Story Mode: Week " + storyWeek;
		}
		else
		{
			detailsText = "Freeplay";
		}

		// String for when the game is paused
		detailsPausedText = "Paused - " + detailsText;
		
		// Updating Discord Rich Presence.
		DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconRPC);
		#end

		dancingStagePieces = new FlxTypedGroup<StagePiece>();
		add(dancingStagePieces);

		stageOffsets = new Map<String, Array<Dynamic>>();

		var stageCheck:String = 'stage';

		var pieceArray = ['stageBG', 'stageFront', 'stageCurtains'];

		switch (SONG.song.toLowerCase())
		{
			case 'spookeez' | 'monster' | 'south': 
			{
				curStage = 'spooky';
				pieceArray = ['halloweenBG'];
			}
			case 'pico' | 'blammed' | 'philly': 
				{
					curStage = 'philly';

					var bg:FlxSprite = new FlxSprite(-100).loadGraphic(Paths.image('philly/sky'));
					bg.scrollFactor.set(0.1, 0.1);
					add(bg);

						var city:FlxSprite = new FlxSprite(-10).loadGraphic(Paths.image('philly/city'));
					city.scrollFactor.set(0.3, 0.3);
					city.setGraphicSize(Std.int(city.width * 0.85));
					city.updateHitbox();
					add(city);

					phillyCityLights = new FlxTypedGroup<FlxSprite>();
					add(phillyCityLights);

					for (i in 0...5)
					{
							var light:FlxSprite = new FlxSprite(city.x).loadGraphic(Paths.image('philly/win' + i));
							light.scrollFactor.set(0.3, 0.3);
							light.visible = false;
							light.setGraphicSize(Std.int(light.width * 0.85));
							light.updateHitbox();
							light.antialiasing = true;
							phillyCityLights.add(light);
					}

					var streetBehind:FlxSprite = new FlxSprite(-40, 50).loadGraphic(Paths.image('philly/behindTrain'));
					add(streetBehind);

						phillyTrain = new FlxSprite(2000, 360).loadGraphic(Paths.image('philly/train'));
					add(phillyTrain);

					trainSound = new FlxSound().loadEmbedded(Paths.sound('train_passes'));
					FlxG.sound.list.add(trainSound);

					// var cityLights:FlxSprite = new FlxSprite().loadGraphic(AssetPaths.win0.png);

					var street:FlxSprite = new FlxSprite(-40, streetBehind.y).loadGraphic(Paths.image('philly/street'));
						add(street);
			}
			case 'milf' | 'satin-panties' | 'high':
			{
					curStage = 'limo';
					defaultCamZoom = 0.90;
					stageOffsets['bf'] = [260, -220];
					pieceArray = ['limoSkyBG', 'limoBG', 'bgDancer', 'bgDancer', 'bgDancer', 'bgDancer', 'bgDancer', 'fastCar'];

					limo = new StagePiece(0, 0, 'limo'); //for the shitty layering
					limo.x += limo.newx;
					limo.y += limo.newy;

			}
			case 'cocoa' | 'eggnog':
			{
					curStage = 'mall';
					defaultCamZoom = 0.80;
					stageOffsets['bf'] = [200, 0];
					pieceArray = ['mallBG', 'mallUpperBoppers', 'mallEscalator', 'mallTree', 'mallBottomBoppers', 'mallSnow', 'mallSanta'];
			}
			case 'winter-horrorland':
			{
					curStage = 'mallEvil';
					stageOffsets['bf'] = [320, 0];
					stageOffsets['dad'] = [0, -80];
					pieceArray = ['mallEvilBG', 'mallEvilTree', 'mallEvilSnow'];

				}
			case 'senpai' | 'roses':
			{
				curStage = 'school';
				stageException = true; //week 6 has some weird shit goin on with its stage

				var bgSky:StagePiece = new StagePiece(0, 0, 'school-bgSky');
				add(bgSky);

				stageOffsets['bf'] = [200, 220];
				stageOffsets['gf'] = [180, 300];

				var repositionShit = -200;

				pieceArray = ['school-bgSchool', 'school-bgStreet', 'school-fgTrees', 'school-bgTrees', 'school-treeLeaves', 'bgGirls'];
				for (i in 0...pieceArray.length) //x and y are optional and set in StagePiece.hx, so epic for loop can be used
				{
					var piece:StagePiece = new StagePiece(repositionShit, 0, pieceArray[i]);
					piece.x += piece.newx;
					piece.y += piece.newy;
					var modif:Float = 1;
					var widShit = Std.int(bgSky.width * 6);
					add(piece);
					if (piece.dancable)
						dancingStagePieces.add(piece);

					if (pieceArray[i] != 'bgGirls')
					{
						if (pieceArray[i] == 'school-bgTrees')
							piece.setGraphicSize(Std.int(widShit * 1.4));
						else if (pieceArray[i] == 'school-fgTrees')
							piece.setGraphicSize(Std.int(widShit * 0.8));
						else
							piece.setGraphicSize(widShit);
						
						piece.updateHitbox();
					}
				}
				bgSky.setGraphicSize(Std.int(bgSky.width * 6));
				bgSky.updateHitbox();
			}
			case 'thorns':
			{
				curStage = 'schoolEvil';
				stageOffsets['bf'] = [200, 220];
				stageOffsets['gf'] = [180, 300];
				var waveEffectBG = new FlxWaveEffect(FlxWaveMode.ALL, 2, -1, 3, 2);
				var waveEffectFG = new FlxWaveEffect(FlxWaveMode.ALL, 2, -1, 5, 2);
				pieceArray = ['schoolEvilBG'];
			}
			default:
			{
				defaultCamZoom = 0.9;
				curStage = 'stage';
				pieceArray = ['stageBG', 'stageFront', 'stageCurtains'];	
			}
        }
		if (!stageException)
		{
			for (i in 0...pieceArray.length) //x and y are optional and set in StagePiece.hx, so for loop can be used
			{
				var piece:StagePiece = new StagePiece(0, 0, pieceArray[i]);
				if (piece.dancable)
					dancingStagePieces.add(piece);


				if (pieceArray[i] == 'bgDancer')
					piece.x += (370 * (i - 2));
				
				piece.x += piece.newx;
				piece.y += piece.newy;
				add(piece);
			}
		}

		var gfVersion:String = 'gf';

		switch (curStage)
		{
			case 'limo':
				gfVersion = 'gf-car';
			case 'mall' | 'mallEvil':
				gfVersion = 'gf-christmas';
			case 'school' | 'schoolEvil':
				gfVersion = 'gf-pixel';
		}

		gf = new Character(400, 130, gfVersion);
		gf.scrollFactor.set(0.95, 0.95);
		var dadcharacter = SONG.player2;
		var bfcharacter = SONG.player1;

		var characterList:Array<String> = CoolUtil.coolTextFile(Paths.txt('characterList'));
		if (!characterList.contains(dadcharacter)) //stop the fucking game from crashing when theres a character that doesnt exist
			dadcharacter = "dad";
		if (!characterList.contains(bfcharacter))
			bfcharacter = "bf";

		var isbfPlayer = true;
		var isdadPlayer = false;

		if (multiplayer)
		{
			isbfPlayer = true;
			isdadPlayer = true;
		}
		else if (flipped)
		{
			isbfPlayer = !isbfPlayer;
			isdadPlayer = !isdadPlayer;
		}


		dad = new Boyfriend(100, 100, dadcharacter, isdadPlayer, false);
		boyfriend = new Boyfriend(770, 450, bfcharacter, isbfPlayer, true);

		if (multiplayer)
		{
			player = boyfriend;
			player2 = dad;
		}
		else if (flipped)
		{
			player = dad;
			cpu = boyfriend;
		}
		else
		{
			player = boyfriend;
			cpu = dad;
		}


		//general offsets are now inside character.hx, go there for some examples

		// general offset for dad character
		var dadOffset = dad.posOffsets.get('pos');
		if (dad.posOffsets.exists('pos'))
		{
			dad.x += dadOffset[0];
			dad.y += dadOffset[1];
		}
		//general offset for bf (none by default lol)
		var bfOffset = boyfriend.posOffsets.get('pos');
		if (boyfriend.posOffsets.exists('pos'))
		{
			boyfriend.x += bfOffset[0];
			boyfriend.y += bfOffset[1];
		}


		//stage offsets are above inside the case statement for stages

		var stupidArray:Array<String> = ['dad', 'bf', 'gf'];
		var stupidCharArray:Array<Dynamic> = [dad, boyfriend, gf];
		//stage offsets (uses a for loop)
		for (i in 0...stupidArray.length)
		{
			var offset = stageOffsets.get(stupidArray[i]);
			if (stageOffsets.exists(stupidArray[i]))
			{
				stupidCharArray[i].x += offset[0];
				stupidCharArray[i].y += offset[1];
			}
		}

		var camPos:FlxPoint = new FlxPoint(dad.getGraphicMidpoint().x, dad.getGraphicMidpoint().y);

		var camOffset = dad.posOffsets.get('startCam'); //offset in character.hx
		if (dad.posOffsets.exists('startCam'))
		{
			camPos.set(dad.getGraphicMidpoint().x + camOffset[0], dad.getGraphicMidpoint().y + camOffset[1]);
		}

		switch (SONG.player2)
		{
			case 'gf':
				dad.setPosition(gf.x, gf.y);
				gf.visible = false;
				if (isStoryMode)
				{
					camPos.x += 600;
					tweenCamIn();
				}
		}
		
		ColorPresets.setColors(dad.curCharacter, mania);

		

		// REPOSITIONING PER STAGE (not anymore, now moved to maps!)
		switch (curStage)
		{
			case 'schoolEvil':
				var evilTrail = new FlxTrail(dad, null, 4, 24, 0.3, 0.069);
				add(evilTrail);
		}

		add(gf);

		// Shitty layering but whatev it works LOL
		if (curStage == 'limo')
			add(limo);

		add(dad);
		add(boyfriend);

		
		

		var doof:DialogueBox = new DialogueBox(false, dialogue);
		doof.scrollFactor.set();
		doof.finishThing = startCountdown;

		Conductor.songPosition = -5000;

		strumLine = new FlxSprite(0, 50).makeGraphic(FlxG.width, 10);
		strumLine.scrollFactor.set();





		strumLineNotes = new FlxTypedGroup<BabyArrow>();
		//add(strumLineNotes);
		add(noteSplashes);
		playerStrums = new FlxTypedGroup<BabyArrow>();
		cpuStrums = new FlxTypedGroup<BabyArrow>();
		add(playerStrums);
		add(cpuStrums);

		// startCountdown();

		generateSong(SONG.song);

		// add(strumLine);

		camFollow = new FlxObject(0, 0, 1, 1);

		camFollow.setPosition(camPos.x, camPos.y);

		if (prevCamFollow != null)
		{
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}

		add(camFollow);

		FlxG.camera.follow(camFollow, LOCKON, 0.04);
		// FlxG.camera.setScrollBounds(0, FlxG.width, 0, FlxG.height);
		FlxG.camera.zoom = defaultCamZoom;
		FlxG.camera.focusOn(camFollow.getPosition());

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		FlxG.fixedTimestep = false;

		healthBarBG = new FlxSprite(0, FlxG.height * 0.9).loadGraphic(Paths.image('healthBar'));
		healthBarBG.screenCenter(X);
		healthBarBG.scrollFactor.set();
		add(healthBarBG);
		if (SaveData.downscroll)
			healthBarBG.y = FlxG.height * 0.1;

		healthBar = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 4, RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8), this,
			'health', 0, 2);
		healthBar.scrollFactor.set();
		healthBar.createFilledBar(0xFFFF0000, 0xFF66FF33);
		// healthBar
		add(healthBar);

		scoreTxt = new FlxText(healthBarBG.x + healthBarBG.width - 640, healthBarBG.y + 30, 0, "", 20);
		scoreTxt.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		scoreTxt.scrollFactor.set();

		TimeText = new FlxText((FlxG.width / 2) - 250, healthBarBG.y - 60, 0, "", 20);
		TimeText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		TimeText.scrollFactor.set();
		

		iconP1 = new HealthIcon(bfcharacter, true);
		iconP1.y = healthBar.y - (iconP1.height / 2);
		add(iconP1);

		iconP2 = new HealthIcon(dadcharacter, false);
		iconP2.y = healthBar.y - (iconP2.height / 2);
		add(iconP2);
		add(scoreTxt);
		add(TimeText);
		noteSplashes.cameras = [camP1Notes];
		//strumLineNotes.cameras = [camP1Notes];
		playerStrums.cameras = [camP1Notes];
		cpuStrums.cameras = [camP2Notes];
		P1notes.cameras = [camP1Notes];
		P2notes.cameras = [camP2Notes];
		healthBar.cameras = [camHUD];
		healthBarBG.cameras = [camHUD];
		iconP1.cameras = [camHUD];
		iconP2.cameras = [camHUD];
		scoreTxt.cameras = [camHUD];
		TimeText.cameras = [camHUD];
		doof.cameras = [camHUD];

		// if (SONG.song == 'South')
		// FlxG.camera.alpha = 0.7;
		// UI_camera.zoom = 1;

		// cameras = [FlxG.cameras.list[1]];
		startingSong = true;

		if (isStoryMode)
		{
			switch (curSong.toLowerCase())
			{
				case "winter-horrorland":
					var blackScreen:FlxSprite = new FlxSprite(0, 0).makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
					add(blackScreen);
					blackScreen.scrollFactor.set();
					camHUD.visible = false;

					new FlxTimer().start(0.1, function(tmr:FlxTimer)
					{
						remove(blackScreen);
						FlxG.sound.play(Paths.sound('Lights_Turn_On'));
						camFollow.y = -2050;
						camFollow.x += 200;
						FlxG.camera.focusOn(camFollow.getPosition());
						FlxG.camera.zoom = 1.5;

						new FlxTimer().start(0.8, function(tmr:FlxTimer)
						{
							camHUD.visible = true;
							remove(blackScreen);
							FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 2.5, {
								ease: FlxEase.quadInOut,
								onComplete: function(twn:FlxTween)
								{
									startCountdown();
								}
							});
						});
					});
				case 'senpai':
					schoolIntro(doof);
				case 'roses':
					FlxG.sound.play(Paths.sound('ANGRY'));
					schoolIntro(doof);
				case 'thorns':
					schoolIntro(doof);
				default:
					startCountdown();
			}
		}
		else
		{
			switch (curSong.toLowerCase())
			{
				default:
					startCountdown();
			}
		}

		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN,handleInput);
		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, releaseInput);

		super.create();
	}

	function schoolIntro(?dialogueBox:DialogueBox):Void
	{
		var black:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
		black.scrollFactor.set();
		add(black);

		var red:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, 0xFFff1b31);
		red.scrollFactor.set();

		var senpaiEvil:FlxSprite = new FlxSprite();
		senpaiEvil.frames = Paths.getSparrowAtlas('weeb/senpaiCrazy');
		senpaiEvil.animation.addByPrefix('idle', 'Senpai Pre Explosion', 24, false);
		senpaiEvil.setGraphicSize(Std.int(senpaiEvil.width * 6));
		senpaiEvil.scrollFactor.set();
		senpaiEvil.updateHitbox();
		senpaiEvil.screenCenter();

		if (SONG.song.toLowerCase() == 'roses' || SONG.song.toLowerCase() == 'thorns')
		{
			remove(black);

			if (SONG.song.toLowerCase() == 'thorns')
			{
				add(red);
			}
		}

		new FlxTimer().start(0.3, function(tmr:FlxTimer)
		{
			black.alpha -= 0.15;

			if (black.alpha > 0)
			{
				tmr.reset(0.3);
			}
			else
			{
				if (dialogueBox != null)
				{
					inCutscene = true;

					if (SONG.song.toLowerCase() == 'thorns')
					{
						add(senpaiEvil);
						senpaiEvil.alpha = 0;
						new FlxTimer().start(0.3, function(swagTimer:FlxTimer)
						{
							senpaiEvil.alpha += 0.15;
							if (senpaiEvil.alpha < 1)
							{
								swagTimer.reset();
							}
							else
							{
								senpaiEvil.animation.play('idle');
								FlxG.sound.play(Paths.sound('Senpai_Dies'), 1, false, null, true, function()
								{
									remove(senpaiEvil);
									remove(red);
									FlxG.camera.fade(FlxColor.WHITE, 0.01, true, function()
									{
										add(dialogueBox);
									}, true);
								});
								new FlxTimer().start(3.2, function(deadTime:FlxTimer)
								{
									FlxG.camera.fade(FlxColor.WHITE, 1.6, false);
								});
							}
						});
					}
					else
					{
						add(dialogueBox);
					}
				}
				else
					startCountdown();

				remove(black);
			}
		});
	}

	var startTimer:FlxTimer;
	var perfectMode:Bool = false;


	var keys = [false, false, false, false, false, false, false, false, false];

	function startCountdown():Void
	{
		inCutscene = false;

		generateStaticArrows(0);
		generateStaticArrows(1);

		talking = false;
		startedCountdown = true;
		Conductor.songPosition = 0;
		Conductor.songPosition -= Conductor.crochet * 5;

		var swagCounter:Int = 0;

		startTimer = new FlxTimer().start(Conductor.crochet / 1000, function(tmr:FlxTimer)
		{
			dad.dance();
			gf.dance();
			boyfriend.dance();

			var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
			introAssets.set('default', ['ready', "set", "go"]);
			introAssets.set('school', ['weeb/pixelUI/ready-pixel', 'weeb/pixelUI/set-pixel', 'weeb/pixelUI/date-pixel']);
			introAssets.set('schoolEvil', ['weeb/pixelUI/ready-pixel', 'weeb/pixelUI/set-pixel', 'weeb/pixelUI/date-pixel']);

			var introAlts:Array<String> = introAssets.get('default');
			var altSuffix:String = "";

			for (value in introAssets.keys())
			{
				if (value == curStage)
				{
					introAlts = introAssets.get(value);
					altSuffix = '-pixel';
				}
			}

			switch (swagCounter)

			{
				case 0:
					FlxG.sound.play(Paths.sound('intro3'), 0.6);
				case 1:
					var ready:FlxSprite = new FlxSprite().loadGraphic(Paths.image(introAlts[0]));
					ready.scrollFactor.set();
					ready.updateHitbox();

					if (curStage.startsWith('school'))
						ready.setGraphicSize(Std.int(ready.width * daPixelZoom));

					ready.screenCenter();
					add(ready);
					FlxTween.tween(ready, {y: ready.y += 100, alpha: 0}, Conductor.crochet / 1000, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween)
						{
							ready.destroy();
						}
					});
					FlxG.sound.play(Paths.sound('intro2'), 0.6);
				case 2:
					var set:FlxSprite = new FlxSprite().loadGraphic(Paths.image(introAlts[1]));
					set.scrollFactor.set();

					if (curStage.startsWith('school'))
						set.setGraphicSize(Std.int(set.width * daPixelZoom));

					set.screenCenter();
					add(set);
					FlxTween.tween(set, {y: set.y += 100, alpha: 0}, Conductor.crochet / 1000, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween)
						{
							set.destroy();
						}
					});
					FlxG.sound.play(Paths.sound('intro1'), 0.6);
				case 3:
					var go:FlxSprite = new FlxSprite().loadGraphic(Paths.image(introAlts[2]));
					go.scrollFactor.set();

					if (curStage.startsWith('school'))
						go.setGraphicSize(Std.int(go.width * daPixelZoom));

					go.updateHitbox();

					go.screenCenter();
					add(go);
					FlxTween.tween(go, {y: go.y += 100, alpha: 0}, Conductor.crochet / 1000, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween)
						{
							go.destroy();
						}
					});
					FlxG.sound.play(Paths.sound('introGo'), 0.6);
				case 4:
			}

			swagCounter += 1;
			// generateSong('fresh');
		}, 5);
	}

	var previousFrameTime:Int = 0;
	var lastReportedPlayheadPosition:Int = 0;
	var songTime:Float = 0;

	private function getKey(charCode:Int):String
		{
			for (key => value in FlxKey.fromStringMap)
			{
				if (charCode == value)
					return key;
			}
			return null;
		}

	/////////////////////////////////////////////////////////// input code - originally from kade engine, i modified it a bit
	private function releaseInput(evt:KeyboardEvent):Void
	{
		@:privateAccess
		var key = FlxKey.toStringMap.get(evt.keyCode);

		var binds:Array<String> = [FlxG.save.data.leftBind,FlxG.save.data.downBind, FlxG.save.data.upBind, FlxG.save.data.rightBind];
		var data = -1;
		
		binds = CoolUtil.bindCheck(maniaToChange);
		data = CoolUtil.arrowKeyCheck(maniaToChange, evt.keyCode);

		for (i in 0...binds.length) // binds
		{
			if (binds[i].toLowerCase() == key.toLowerCase())
				data = i;
		}

		if (data == -1)
			return;

		keys[data] = false;
	}

	public var closestNotes:Array<Note> = [];

	private function handleInput(evt:KeyboardEvent):Void 
	{
		if (paused)
			return;

		@:privateAccess
		var key = FlxKey.toStringMap.get(evt.keyCode);
		var data = -1;
		var binds:Array<String> = [FlxG.save.data.leftBind,FlxG.save.data.downBind, FlxG.save.data.upBind, FlxG.save.data.rightBind];
		binds = CoolUtil.bindCheck(maniaToChange); //finally got rid of that fucking huge case statement, its still inside coolutil, but theres only 1, not like 4 lol
		data = CoolUtil.arrowKeyCheck(maniaToChange, evt.keyCode);

		for (i in 0...binds.length) // binds
		{
			if (binds[i].toLowerCase() == key.toLowerCase())
				data = i;
		}
		if (keys[data] || data == -1)
		{
			return;
		}
	
		keys[data] = true;


		if (NormalInput)
		{
			var hittableNotes = [];
			for(i in closestNotes)
				if (i.noteData == data)
					hittableNotes.push(i);
	
	
			if (hittableNotes.length != 0)
			{
				var daNote = null;
	
				for (i in hittableNotes)
					if (!i.isSustainNote)
					{
						daNote = i;
						break;
					}
	
				if (daNote == null)
					return;
	
				if (hittableNotes.length > 1) // gets rid of stacked notes
				{
					for (i in 0...hittableNotes.length)
					{
						if (i == 0)
							continue;
						var note = hittableNotes[i];
						if (!note.isSustainNote && (note.strumTime - daNote.strumTime) < 2)
						{
							removeNote(note);
						}
					}
				}
	
				goodNoteHit(daNote);
			}
			else if (!SaveData.ghost && songStarted && !grace)
			{
				trace("you mispressed you dumbass");
				missPress(data);
			}
		}
		//else		//testin new input systems (want a more spammable one for casual mode)
		//{
			/*closestNotes = [];

			P1notes.forEachAlive(function(daNote:Note)
			{
				if (daNote.canBeHit && daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit)
					closestNotes.push(daNote);
			}); // Collect notes that can be hit
			closestNotes.sort((a, b) -> Std.int(a.strumTime - b.strumTime));

			if (closestNotes.length > 0)
				{
					var daNote = closestNotes[0];

					if (closestNotes.length >= 2)
					{
						if (closestNotes[0].strumTime == closestNotes[1].strumTime)
						{
							for (coolNote in closestNotes)
							{
								if (coolNote.noteData == data)
									goodNoteHit(coolNote);
							}
						}
						else if (closestNotes[0].noteData == closestNotes[1].noteData)
						{
							if (daNote.noteData == data)
								goodNoteHit(daNote);
						}
						else
						{
							for (coolNote in closestNotes)
							{
								if (coolNote.noteData == data)
									goodNoteHit(coolNote);
							}
						}
					}
					else // regular notes?
					{
						if (daNote.noteData == data)
							goodNoteHit(daNote);
					}

					if (daNote.wasGoodHit)
					{
						removeNote(daNote);
					}
				}
				else if (!SaveData.ghost && songStarted && !grace)
					{
						noteMiss(data, null);
					}
		}*/



		/*if (closestNotes.length > 0) //basic ass input system, it doesnt need to be complicated
		{
			for (daNote in closestNotes)
			{
				if (daNote.noteData == data)
					goodNoteHit(daNote);

				/*if (closestNotes.length > 1) // gets rid of silly stacked notes
				{							  //apparently this creates the god awful input system from mfm, so yeah dont use this
					for (i in 0...closestNotes.length)
					{
						if (i == 0)
							continue;
						var sillyNote = closestNotes[i]; 
						if (!sillyNote.isSustainNote && (sillyNote.strumTime - daNote.strumTime) < 12)
						{
							removeNote(sillyNote);
						}
					}
				}
			}
		}
		else if (!SaveData.ghost && songStarted && !grace)
		{
			trace("you mispressed you dumbass");
			missPress(data);
		}*/

		
				
		
	}
	/////////////////////////////////////////////////////////////////////////////////////////

	var songStarted = false;
	function startSong():Void
	{
		startingSong = false;
		songStarted = true;

		previousFrameTime = FlxG.game.ticks;
		lastReportedPlayheadPosition = 0;

		if (!paused)
			FlxG.sound.playMusic(Sound.fromFile(Paths.inst(PlayState.SONG.song)), 1, false);

		if (SaveData.noteSplash)
			{
				switch (maniaToChange)
				{
					case 0: 
						NoteSplash.colors = ['purple', 'blue', 'green', 'red'];
					case 1: 
						NoteSplash.colors = ['purple', 'green', 'red', 'yellow', 'blue', 'darkblue'];	
					case 2: 
						NoteSplash.colors = ['purple', 'blue', 'green', 'red', 'white', 'yellow', 'violet', 'darkred', 'darkblue'];
					case 3: 
						NoteSplash.colors = ['purple', 'blue', 'white', 'green', 'red'];
					case 4: 
						NoteSplash.colors = ['purple', 'green', 'red', 'white', 'yellow', 'blue', 'darkblue'];
					case 5: 
						NoteSplash.colors = ['purple', 'blue', 'green', 'red', 'yellow', 'violet', 'darkred', 'darkblue'];
					case 6: 
						NoteSplash.colors = ['white'];
					case 7: 
						NoteSplash.colors = ['purple', 'red'];
					case 8: 
						NoteSplash.colors = ['purple', 'white', 'red'];
				}
			}
		
		SaveData.fixColorArray(maniaToChange);

		FlxG.sound.music.onComplete = endSong;
		vocals.play();

		songLength = FlxG.sound.music.length;
		#if desktop
		// Song duration in a float, useful for the time left feature

		// Updating Discord Rich Presence (with Time Left)
		DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconRPC, true, songLength);
		#end
	}

	var debugNum:Int = 0;

	private function generateSong(dataPath:String):Void
	{
		// FlxG.log.add(ChartParser.parse());

		var songData = SONG;
		Conductor.changeBPM(songData.bpm);

		curSong = songData.song;

		if (SONG.needsVoices)
			vocals = new FlxSound().loadEmbedded(Sound.fromFile(Paths.voices(PlayState.SONG.song)));
		else
			vocals = new FlxSound();

		FlxG.sound.list.add(vocals);

		P1notes = new FlxTypedGroup<Note>();
		add(P1notes);

		P2notes = new FlxTypedGroup<Note>();
		add(P2notes);

		var noteData:Array<SwagSection>;

		// NEW SHIT
		noteData = songData.notes;

		var playerCounter:Int = 0;

		var daBeats:Int = 0; // Not exactly representative of 'daBeats' lol, just how much it has looped
		for (section in noteData)
		{
			var mn:Int = keyAmmo[mania];
			var coolSection:Int = Std.int(section.lengthInSteps / 4);

			for (songNotes in section.sectionNotes)
			{
				var daStrumTime:Float = songNotes[0];
				if (daStrumTime < 0)
					daStrumTime = 0;
				var daNoteData:Int = Std.int(songNotes[1] % mn);

				var gottaHitNote:Bool = section.mustHitSection;

				if (songNotes[1] >= mn)
				{
					gottaHitNote = !section.mustHitSection;
				}

				var oldNote:Note;
				if (unspawnNotes.length > 0)
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
				else
					oldNote = null;

				var daType = songNotes[3];

				var daSpeed = songNotes[4];

				var daVelocityData = songNotes[5];

				var t = Std.int(songNotes[1] / 18); //compatibility with god mode final destination
				switch(t)
				{
					case 1: 
						daType = 2;
						gottaHitNote = !gottaHitNote;
					case 2: 
						daType = 3;
						gottaHitNote = !gottaHitNote;
				}

				var swagNote:Note = new Note(daStrumTime, daNoteData, daType, false, daSpeed, daVelocityData, gottaHitNote, oldNote);
				swagNote.sustainLength = songNotes[2];
				swagNote.scrollFactor.set(0, 0);
				swagNote.startPos = calculateStrumtime(swagNote, daStrumTime);

				var susLength:Float = swagNote.sustainLength;

				susLength = susLength / Conductor.stepCrochet;
				unspawnNotes.push(swagNote);



				for (susNote in 0...Math.floor(susLength))
				{
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
					var susStrum = daStrumTime + (Conductor.stepCrochet * susNote) + Conductor.stepCrochet;

					var sustainNote:Note = new Note(susStrum, daNoteData, daType, true, daSpeed, daVelocityData, gottaHitNote, oldNote);
					sustainNote.scrollFactor.set();
					unspawnNotes.push(sustainNote);
					sustainNote.startPos = calculateStrumtime(sustainNote, susStrum);

					if (sustainNote.mustPress)
					{
						sustainNote.x += FlxG.width / 2; // general offset
					}
				}

				if (swagNote.mustPress)
				{
					swagNote.x += FlxG.width / 2; // general offset
				}
				else {}
			}
			daBeats += 1;
		}

		unspawnNotes.sort(sortByShit);

		generatedMusic = true;
	}

	function sortByShit(Obj1:Note, Obj2:Note):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	private function generateStaticArrows(player:Int):Void
	{
		for (i in 0...keyAmmo[maniaToChange])
		{
			var style:String = "normal";

			var babyArrow:BabyArrow = new BabyArrow(strumLine.y, player, i, style, true);

			babyArrow.ID = i;

			switch (player)
			{
				case 0:
					cpuStrums.add(babyArrow);
					//if (PlayStateChangeables.bothSide)
						//babyArrow.x -= 500;
				case 1:
					playerStrums.add(babyArrow);
			}

			cpuStrums.forEach(function(spr:BabyArrow)
				{					
					spr.centerOffsets();
				});
	
			strumLineNotes.add(babyArrow);
		}
	}

	function tweenCamIn():Void
	{
		FlxTween.tween(FlxG.camera, {zoom: 1.3}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut});
	}

	override function openSubState(SubState:FlxSubState)
	{
		if (paused)
		{
			if (FlxG.sound.music != null)
			{
				FlxG.sound.music.pause();
				vocals.pause();
			}

			if (!startTimer.finished)
				startTimer.active = false;
		}

		super.openSubState(SubState);
	}

	override function closeSubState()
	{
		if (paused)
		{
			if (FlxG.sound.music != null && !startingSong)
			{
				resyncVocals();
			}

			if (!startTimer.finished)
				startTimer.active = true;
			paused = false;

			#if desktop
			if (startTimer.finished)
			{
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconRPC, true, songLength - Conductor.songPosition);
			}
			else
			{
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconRPC);
			}
			#end
		}

		super.closeSubState();
	}

	override public function onFocus():Void
	{
		#if desktop
		if (health > 0 && !paused)
		{
			if (Conductor.songPosition > 0.0)
			{
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconRPC, true, songLength - Conductor.songPosition);
			}
			else
			{
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconRPC);
			}
		}
		#end

		super.onFocus();
	}
	
	override public function onFocusLost():Void
	{
		#if desktop
		if (health > 0 && !paused)
		{
			DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", iconRPC);
		}
		#end

		super.onFocusLost();
	}

	function resyncVocals():Void
	{
		vocals.pause();

		FlxG.sound.music.play();
		Conductor.songPosition = FlxG.sound.music.time;
		vocals.time = Conductor.songPosition;
		vocals.play();
	}

	private var paused:Bool = false;
	var startedCountdown:Bool = false;
	var canPause:Bool = true;

	function calculateStrumtime(daNote:Note, Strumtime:Float) //for note velocity shit, used andromeda engine as a guide for this https://github-dotcom.gateway.web.tr/nebulazorua/andromeda-engine
	{
		var ChangeTime:Float = daNote.strumTime - daNote.velocityChangeTime;
		var StrumDiff = Strumtime - ChangeTime;
		var Multi:Float = 1;
		if (Strumtime >= ChangeTime)
			Multi = daNote.speedMulti;

		var pos = ChangeTime * daNote.speed;
		pos += (StrumDiff * (daNote.speed * Multi));
		return pos;
	}

	function NotePositionShit(daNote:Note, strums:String)
	{
		if (daNote.y > FlxG.height)
		{
			daNote.active = false;
			daNote.visible = false;
		}
		else
		{
			daNote.visible = true;
			daNote.active = true;
		}

		var NoteY:Float = 0;
		var NoteX:Float = 0;
		var NoteAngle:Float = 0;
		var NoteAlpha:Float = 1;
		var NoteVisible:Bool = true;

		var WasGoodHit:Bool = daNote.wasGoodHit; //so it doesnt have to check multiple times
		var IsSustainNote:Bool = daNote.isSustainNote; //its running this shit every frame for every note
		var MustPress:Bool = daNote.mustPress;
		var CanBeHit:Bool = daNote.canBeHit;
		var TooLate:Bool = daNote.tooLate;
		var NoteData:Int = daNote.noteData;
		
		if (strums == 'player') //playerStrums
		{
			NoteX = playerStrums.members[Math.floor(Math.abs(daNote.noteData))].x;
			NoteY = playerStrums.members[Math.floor(Math.abs(daNote.noteData))].y;
			NoteAngle = playerStrums.members[Math.floor(Math.abs(daNote.noteData))].angle;
			NoteAlpha = playerStrums.members[Math.floor(Math.abs(daNote.noteData))].alpha;
			NoteVisible = playerStrums.members[Math.floor(Math.abs(daNote.noteData))].visible;
		}
		else //cpuStrums
		{
			NoteX = cpuStrums.members[Math.floor(Math.abs(daNote.noteData))].x;
			NoteY = cpuStrums.members[Math.floor(Math.abs(daNote.noteData))].y;
			NoteAngle = cpuStrums.members[Math.floor(Math.abs(daNote.noteData))].angle;
			NoteAlpha = cpuStrums.members[Math.floor(Math.abs(daNote.noteData))].alpha;
			NoteVisible = cpuStrums.members[Math.floor(Math.abs(daNote.noteData))].visible;
		}
		var MiddleOfNote:Float = NoteY + Note.swagWidth / 2;
		var calculatedStrumtime = calculateStrumtime(daNote, Conductor.songPosition);
		


		daNote.y = (NoteY + 0.45 * (daNote.startPos - calculatedStrumtime));
		if (IsSustainNote)
			daNote.y -= daNote.sustainOffset;
		if (daNote.isSustainEnd)
			daNote.y -= daNote.height - daNote.sustainOffset;
			
		if (flipped)
			MustPress = !MustPress; //this is just for detecting it, not actually a must press note lol
		
		// i am so fucking sorry for this if condition
		if (IsSustainNote
			&& daNote.y + daNote.offset.y <= MiddleOfNote
			&& (!MustPress || (WasGoodHit || (daNote.prevNote.wasGoodHit && !CanBeHit))))
		{
			var swagRect = new FlxRect(0, MiddleOfNote - daNote.y, daNote.width * 2, daNote.height * 2);
			swagRect.y /= daNote.scale.y;
			swagRect.height -= swagRect.y;

			daNote.clipRect = swagRect;
		}

		daNote.x = NoteX;
		daNote.visible = NoteVisible;
		if (IsSustainNote)
		{
			daNote.alpha = NoteAlpha * 0.6;

			daNote.x += daNote.width / 2 + 20;
			if (daNote.style == 'pixel')
				daNote.x -= 11;
		}
		else
		{
			daNote.alpha = NoteAlpha;
			daNote.angle = NoteAngle;
		}
		if (SaveData.downscroll && (daNote.burning || daNote.death || daNote.warning || daNote.angel || daNote.bob || daNote.glitch))
			daNote.y += 75; //y offset of notetypes  (only downscroll for some reason, weird shit with the graphic flip)

	}

	function NoteMissDetection(daNote:Note, strums:String)
	{
		var WasGoodHit:Bool = daNote.wasGoodHit; //so it doesnt have to check multiple times
		var IsSustainNote:Bool = daNote.isSustainNote; //its running this shit every frame for every note
		var MustPress:Bool = daNote.mustPress;
		var CanBeHit:Bool = daNote.canBeHit;
		var TooLate:Bool = daNote.tooLate;
		var NoteData:Int = daNote.noteData;

		if (flipped)
			MustPress = !MustPress; //this is just for detecting it, not actually a must press note lol

		if (IsSustainNote && WasGoodHit && Conductor.songPosition >= daNote.strumTime)
			removeNote(daNote, strums);
		else if (MustPress && (TooLate && !WasGoodHit))
		{
			switch (daNote.noteType)
			{
				case 0 | 5: //normal and alt anim note
				{
					if (IsSustainNote && WasGoodHit) //to 100% make sure the sustain is gone
					{
						daNote.kill();
						removeNote(daNote, strums);
					}
					else
					{
						vocals.volume = 0;
						noteMiss(NoteData, daNote);								
					}

					removeNote(daNote, strums);
				}
				case 1: //fire notes - makes missing them not count as one
				{
					removeNote(daNote, strums);
				}
				case 2: //halo notes, same as fire
				{
					removeNote(daNote, strums);
				}
				case 3:  //warning notes, removes half health and then removed so it doesn't repeatedly deal damage
				{
					health -= 1;
					vocals.volume = 0;
					misses++;
					badNoteHit();
					removeNote(daNote, strums);
				}
				case 4: //angel notes
				{
					removeNote(daNote, strums);
				}
				case 6:  //bob notes
				{
					removeNote(daNote, strums);
				}
				case 7: //gltich notes
				{
					HealthDrain();
					misses++;
					removeNote(daNote, strums);
				}
			}
		}
	}

	function NoteCpuHit(daNote:Note, strums:String)
	{
		var WasGoodHit:Bool = daNote.wasGoodHit;
		var NoteData:Int = daNote.noteData;

		if (WasGoodHit)
		{
			if (SONG.song != 'Tutorial')
				camZooming = true;

			var altAnim:String = "";

			if (currentSection != null)
			{
				if (currentSection.altAnim)
					altAnim = '-alt';
			}

			if (daNote.alt)
				altAnim = '-alt';

			cpu.playAnim('sing' + sDir[NoteData] + altAnim, true);


			if (flipped)
			{
				playerStrums.forEach(function(spr:BabyArrow)
				{
					if (Math.abs(NoteData) == spr.ID)
					{
						spr.playAnim('confirm', true, spr.ID);
					}
				});
			}
			else
			{
				cpuStrums.forEach(function(spr:BabyArrow)
				{
					if (Math.abs(NoteData) == spr.ID)
					{
						spr.playAnim('confirm', true, spr.ID);
					}
				});
			}

			cpu.holdTimer = 0;

			if (SONG.needsVoices)
				vocals.volume = 1;

			daNote.active = false;


			removeNote(daNote, strums);
		}
	}

	override public function update(elapsed:Float)
	{
		#if !debug
		perfectMode = false;
		#end

		if (FlxG.keys.justPressed.NINE)
		{
			if (iconP1.animation.curAnim.name == 'bf-old')
				iconP1.animation.play(SONG.player1);
			else
				iconP1.animation.play('bf-old');
		}

		switch (curStage)
		{
			case 'philly':
				if (trainMoving)
				{
					trainFrameTiming += elapsed;

					if (trainFrameTiming >= 1 / 24)
					{
						updateTrainPos();
						trainFrameTiming = 0;
					}
				}
				// phillyCityLights.members[curLight].alpha -= (Conductor.crochet / 1000) * FlxG.elapsed;
		}

		super.update(elapsed);

		scoreTxt.text = "Score:" + songScore + "  Rank: " + curRank + "  Accuracy: " + accuracy + "%   Misses: " + misses; 

		var timeLeft = songLength - FlxG.sound.music.time;
		var time:Date = Date.fromTime(timeLeft);
		var mins = time.getMinutes();
		var secs = time.getSeconds();
		if (secs < 10) //so it looks right
			TimeText.text = songtext + " - " + mins + ":" + "0" + secs; 
		else
			TimeText.text = songtext + " - " + mins + ":" + secs; 
		

		var currentBeat = (Conductor.songPosition / 1000)*(SONG.bpm/60);

		playerStrums.forEach(function(spr:BabyArrow)
		{
			if (ModchartUtil.pXEnabled)
			{
				ModchartUtil.ChangeArrowX(spr, ModchartUtil.CalculateArrowShit(
					spr,
					spr.ID,
					ModchartUtil.pXnum,
					0,
					currentBeat + ModchartUtil.pXbeatShit,
					ModchartUtil.pXExtra,
					ModchartUtil.pXPi,
					ModchartUtil.pXSin
				));
			}
			if (ModchartUtil.pYEnabled)
			{
				ModchartUtil.ChangeArrowY(spr, ModchartUtil.CalculateArrowShit(
					spr,
					spr.ID,
					ModchartUtil.pYnum,
					1,
					currentBeat + ModchartUtil.pYbeatShit,
					ModchartUtil.pYExtra,
					ModchartUtil.pYPi,
					ModchartUtil.pYSin
				));
			}
			if (ModchartUtil.pAngleEnabled)
			{
				ModchartUtil.ChangeArrowAngle(spr, ModchartUtil.CalculateArrowShit(
					spr,
					spr.ID,
					ModchartUtil.pAnglenum,
					2,
					currentBeat + ModchartUtil.pAnglebeatShit,
					ModchartUtil.pAngleExtra,
					ModchartUtil.pAnglePi,
					ModchartUtil.pAngleSin
				));
			}
		});
		cpuStrums.forEach(function(spr:BabyArrow)
		{
			if (ModchartUtil.cpuXEnabled)
			{
				ModchartUtil.ChangeArrowX(spr, ModchartUtil.CalculateArrowShit(
					spr,
					spr.ID,
					ModchartUtil.cpuXnum,
					0,
					currentBeat + ModchartUtil.cpuXbeatShit,
					ModchartUtil.cpuXExtra,
					ModchartUtil.cpuXPi,
					ModchartUtil.cpuXSin
				));
			}
			if (ModchartUtil.cpuYEnabled)
			{
				ModchartUtil.ChangeArrowX(spr, ModchartUtil.CalculateArrowShit(
					spr,
					spr.ID,
					ModchartUtil.cpuYnum,
					1,
					currentBeat + ModchartUtil.cpuYbeatShit,
					ModchartUtil.cpuYExtra,
					ModchartUtil.cpuYPi,
					ModchartUtil.cpuYSin
				));
			}
			if (ModchartUtil.cpuAngleEnabled)
			{
				ModchartUtil.ChangeArrowX(spr, ModchartUtil.CalculateArrowShit(
					spr,
					spr.ID,
					ModchartUtil.cpuAnglenum,
					2,
					currentBeat + ModchartUtil.cpuAnglebeatShit,
					ModchartUtil.cpuAngleExtra,
					ModchartUtil.cpuAnglePi,
					ModchartUtil.cpuAngleSin
				));
			}

		});




		if (FlxG.keys.justPressed.ENTER && startedCountdown && canPause)
		{

			persistentUpdate = false;
			persistentDraw = true;
			paused = true;



			// 1 / 1000 chance for Gitaroo Man easter egg
			if (FlxG.random.bool(0.1))
			{
				// gitaroo man easter egg
				FlxG.switchState(new GitarooPause());
			}
			else
				openSubState(new PauseSubState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
		
			#if desktop
			DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", iconRPC);
			#end
		}

		if (FlxG.keys.justPressed.SEVEN && songStarted)
		{
			FlxG.switchState(new ChartingState());

			#if desktop
			DiscordClient.changePresence("Chart Editor", null, null, true);
			#end
			Main.editor = true;
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN,handleInput);
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, releaseInput);
		}

		// FlxG.watch.addQuick('VOL', vocals.amplitudeLeft);
		// FlxG.watch.addQuick('VOLRight', vocals.amplitudeRight);

		iconP1.setGraphicSize(Std.int(FlxMath.lerp(150, iconP1.width, 0.50)));
		iconP2.setGraphicSize(Std.int(FlxMath.lerp(150, iconP2.width, 0.50)));

		iconP1.updateHitbox();
		iconP2.updateHitbox();

		var iconOffset:Int = 26;

		iconP1.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01) - iconOffset);
		iconP2.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) - (iconP2.width - iconOffset);

		if (health > 2)
			health = 2;

		if (healthBar.percent < 20)
			iconP1.animation.curAnim.curFrame = 1;
		else
			iconP1.animation.curAnim.curFrame = 0;

		if (healthBar.percent > 80)
			iconP2.animation.curAnim.curFrame = 1;
		else
			iconP2.animation.curAnim.curFrame = 0;

		/* if (FlxG.keys.justPressed.NINE)
			FlxG.switchState(new Charting()); */

		#if debug
		if (FlxG.keys.justPressed.EIGHT)
			FlxG.switchState(new AnimationDebug(SONG.player2));
		#end

		if (startingSong)
		{
			if (startedCountdown)
			{
				Conductor.songPosition += FlxG.elapsed * 1000;
				if (Conductor.songPosition >= 0)
					startSong();
			}
		}
		else
		{
			// Conductor.songPosition = FlxG.sound.music.time;
			Conductor.songPosition += FlxG.elapsed * 1000;

			currentSection = SONG.notes[Std.int(curStep / 16)];

			if (!paused)
			{
				songTime += FlxG.game.ticks - previousFrameTime;
				previousFrameTime = FlxG.game.ticks;

				// Interpolation type beat
				if (Conductor.lastSongPos != Conductor.songPosition)
				{
					songTime = (songTime + Conductor.songPosition) / 2;
					Conductor.lastSongPos = Conductor.songPosition;
					// Conductor.songPosition += FlxG.elapsed * 1000;
					// trace('MISSED FRAME');
				}
			}

			// Conductor.lastSongPos = FlxG.sound.music.time;
		}

		if (generatedMusic && currentSection != null)
		{
			closestNotes = [];

			if (flipped)
			{
				P2notes.forEachAlive(function(daNote:Note)
				{
					if (daNote.canBeHit && !daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit)
						closestNotes.push(daNote);
				}); // Collect notes that can be hit
			}
			else
			{
				P1notes.forEachAlive(function(daNote:Note)
				{
					if (daNote.canBeHit && daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit)
						closestNotes.push(daNote);
				}); // Collect notes that can be hit
			}

			closestNotes.sort((a, b) -> Std.int(a.strumTime - b.strumTime));

			if (curBeat % 4 == 0)
			{
				// trace(PlayState.SONG.notes[Std.int(curStep / 16)].mustHitSection);
			}

			if (camFollow.x != dad.getMidpoint().x + 150 && !currentSection.mustHitSection)
			{

				var camOffset = dad.posOffsets.get('cam'); //offset in character.hx
				if (dad.posOffsets.exists('cam'))
				{
					camFollow.setPosition(dad.getMidpoint().x + camOffset[0], dad.getMidpoint().y + camOffset[1]);
				}
				else
					camFollow.setPosition(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);

				

				if (dad.curCharacter == 'mom')
					vocals.volume = 1;

				if (SONG.song.toLowerCase() == 'tutorial')
				{
					tweenCamIn();
				}
			}

			if (currentSection.mustHitSection && camFollow.x != boyfriend.getMidpoint().x - 100)
			{
				var yoffset:Float = -100;
				var xoffset:Float = -100;
				switch (curStage) //offset is where stages are
				{
					case 'limo':
						xoffset = -300;
					case 'mall':
						yoffset = -200;
					case 'school' | 'schoolEvil':
						xoffset = -200;
						yoffset = -200;
				}

				camFollow.setPosition(boyfriend.getMidpoint().x + xoffset, boyfriend.getMidpoint().y + yoffset);

				if (SONG.song.toLowerCase() == 'tutorial')
				{
					FlxTween.tween(FlxG.camera, {zoom: 1}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut});
				}
			}
		}

		if (camZooming)
		{
			FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, 0.95);
			camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, 0.95);

			camP1Notes.zoom = camHUD.zoom;
			camP2Notes.zoom = camHUD.zoom;
			camSustains.zoom = camHUD.zoom;
		}
		camP1Notes.x = camHUD.x; //so they match up when it moves, pretty much will just be for modcharts and shit
		camP1Notes.y = camHUD.y;
		camP1Notes.angle = camHUD.angle;
		camP2Notes.x = camHUD.x;
		camP2Notes.y = camHUD.y;
		camP2Notes.angle = camHUD.angle;
		camOnTop.x = camHUD.x;
		camOnTop.y = camHUD.y;
		camOnTop.angle = camHUD.angle;

		FlxG.watch.addQuick("beatShit", curBeat);
		FlxG.watch.addQuick("stepShit", curStep);

		if (curSong == 'Fresh')
		{
			switch (curBeat)
			{
				case 16:
					camZooming = true;
					gfSpeed = 2;
				case 48:
					gfSpeed = 1;
				case 80:
					gfSpeed = 2;
				case 112:
					gfSpeed = 1;
				case 163:
					// FlxG.sound.music.stop();
					// FlxG.switchState(new TitleState());
			}
		}

		if (curSong == 'Bopeebo')
		{
			switch (curBeat)
			{
				case 128, 129, 130:
					vocals.volume = 0;
					// FlxG.sound.music.stop();
					// FlxG.switchState(new PlayState());
			}
		}

		if (health <= 0)
		{
			player.stunned = true;

			persistentUpdate = false;
			persistentDraw = false;
			paused = true;

			vocals.stop();
			FlxG.sound.music.stop();

			openSubState(new GameOverSubstate(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));

			// FlxG.switchState(new GameOverState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
			
			#if desktop
			// Game Over doesn't get his own variable because it's only used here
			DiscordClient.changePresence("Game Over - " + detailsText, SONG.song + " (" + storyDifficultyText + ")", iconRPC);
			#end
		}

		if (unspawnNotes[0] != null)
		{
			if (unspawnNotes[0].strumTime - Conductor.songPosition < 3500)
			{
				var dunceNote:Note = unspawnNotes[0];
				if (dunceNote.mustPress)
					P1notes.add(dunceNote);
				else
					P2notes.add(dunceNote);

				var index:Int = unspawnNotes.indexOf(dunceNote);
				unspawnNotes.splice(index, 1);
			}
		}

		switch(maniaToChange)
		{
			case 0: 
				sDir = ['LEFT', 'DOWN', 'UP', 'RIGHT'];
				bfsDir = ['LEFT', 'DOWN', 'UP', 'RIGHT'];
			case 1: 
				sDir = ['LEFT', 'UP', 'RIGHT', 'LEFT', 'DOWN', 'RIGHT'];
				bfsDir = ['LEFT', 'UP', 'RIGHT', 'LEFT', 'DOWN', 'RIGHT'];
			case 2: 
				sDir = ['LEFT', 'DOWN', 'UP', 'RIGHT', 'UP', 'LEFT', 'DOWN', 'UP', 'RIGHT'];
				bfsDir = ['LEFT', 'DOWN', 'UP', 'RIGHT', 'hey', 'LEFT', 'DOWN', 'UP', 'RIGHT'];
			case 3: 
				sDir = ['LEFT', 'DOWN', 'UP', 'UP', 'RIGHT'];
				bfsDir = ['LEFT', 'DOWN', 'hey', 'UP', 'RIGHT'];
			case 4: 
				sDir = ['LEFT', 'UP', 'RIGHT', 'UP', 'LEFT', 'DOWN', 'RIGHT'];
				bfsDir = ['LEFT', 'UP', 'RIGHT', 'hey', 'LEFT', 'DOWN', 'RIGHT'];
			case 5: 
				sDir = ['LEFT', 'DOWN', 'UP', 'RIGHT', 'LEFT', 'DOWN', 'UP', 'RIGHT'];
				bfsDir = ['LEFT', 'DOWN', 'UP', 'RIGHT', 'LEFT', 'DOWN', 'UP', 'RIGHT'];
			case 6: 
				sDir = ['UP'];
				bfsDir = ['hey'];
			case 7: 
				sDir = ['LEFT', 'RIGHT'];
				bfsDir = ['LEFT', 'RIGHT'];
			case 8:
				sDir = ['LEFT', 'UP', 'RIGHT'];
				bfsDir = ['LEFT', 'hey', 'RIGHT'];
		}


		if (generatedMusic)
		{
			P1notes.forEachAlive(function(daNote:Note)
			{
				NotePositionShit(daNote, "player");
				if (flipped)
					NoteCpuHit(daNote, "player");
				else
					NoteMissDetection(daNote, "player");
			});
			P2notes.forEachAlive(function(daNote:Note)
			{
				NotePositionShit(daNote, "cpu");
				if (flipped)
					NoteMissDetection(daNote, "cpu");
				else
					NoteCpuHit(daNote, "cpu");
			});
		}
		if (flipped)
		{
			playerStrums.forEach(function(spr:BabyArrow)
			{
				if (spr.animation.finished)
				{
					spr.playAnim('static',false , spr.ID);
					spr.centerOffsets();
				}
			});
		}
		else
		{
			cpuStrums.forEach(function(spr:BabyArrow)
			{
				if (spr.animation.finished)
				{
					spr.playAnim('static',false , spr.ID);
					spr.centerOffsets();
				}
			});
		}


		if (!inCutscene)
			keyShit();

		#if debug
		if (FlxG.keys.justPressed.ONE)
			endSong();
		#end
	}

	function endSong():Void
	{
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN,handleInput);
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, releaseInput);
		canPause = false;
		FlxG.sound.music.volume = 0;
		vocals.volume = 0;
		FlxG.sound.music.pause();
		vocals.pause();
		if (SONG.validScore)
		{
			#if !switch
			Highscore.saveScore(SONG.song, songScore, storyDifficulty);
			#end
		}

		if (isStoryMode)
		{
			campaignScore += songScore;

			storyPlaylist.remove(storyPlaylist[0]);

			if (storyPlaylist.length <= 0)
			{
				FlxG.sound.playMusic(Paths.music('freakyMenu'));

				transIn = FlxTransitionableState.defaultTransIn;
				transOut = FlxTransitionableState.defaultTransOut;

				FlxG.switchState(new StoryMenuState());

				// if ()
				StoryMenuState.weekUnlocked[Std.int(Math.min(storyWeek + 1, StoryMenuState.weekUnlocked.length - 1))] = true;

				if (SONG.validScore)
				{
					NGio.unlockMedal(60961);
					Highscore.saveWeekScore(storyWeek, campaignScore, storyDifficulty);
				}

				FlxG.save.data.weekUnlocked = StoryMenuState.weekUnlocked;
				FlxG.save.flush();
			}
			else
			{
				var difficulty:String = "";

				var formmatedShit = CoolUtil.getSongFromJsons(PlayState.storyPlaylist[0].toLowerCase(), storyDifficulty);

				trace('LOADING NEXT SONG');
				trace(PlayState.storyPlaylist[0].toLowerCase() + difficulty);

				if (SONG.song.toLowerCase() == 'eggnog')
				{
					var blackShit:FlxSprite = new FlxSprite(-FlxG.width * FlxG.camera.zoom,
						-FlxG.height * FlxG.camera.zoom).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
					blackShit.scrollFactor.set();
					add(blackShit);
					camHUD.visible = false;

					FlxG.sound.play(Paths.sound('Lights_Shut_off'));
				}

				FlxTransitionableState.skipNextTransIn = true;
				FlxTransitionableState.skipNextTransOut = true;
				prevCamFollow = camFollow;

				PlayState.SONG = Song.loadFromJson(formmatedShit, PlayState.storyPlaylist[0]);
				FlxG.sound.music.stop();

				LoadingState.loadAndSwitchState(new PlayState());
			}
		}
		else
		{
			trace('WENT BACK TO FREEPLAY??');
			FlxG.switchState(new FreeplayState());
		}
	}

	var endingSong:Bool = false;

	private function popUpScore(note:Note = null):Void
	{
		var noteDiff:Float = Math.abs(note.strumTime - Conductor.songPosition);
		// boyfriend.playAnim('hey');
		vocals.volume = 1;

		var placement:String = Std.string(combo);

		var coolText:FlxText = new FlxText(0, 0, 0, placement, 32);
		coolText.screenCenter();
		coolText.x = FlxG.width * 0.55;
		//

		var rating:FlxSprite = new FlxSprite();
		var score:Int = 350;

		var daRating:String = "sick";

		if (noteDiff > Conductor.safeZoneOffset * 0.85)
		{
			daRating = 'shit';
			score = 50;
		}
		else if (noteDiff > Conductor.safeZoneOffset * 0.70)
		{
			daRating = 'bad';
			score = 100;
		}
		else if (noteDiff > Conductor.safeZoneOffset * 0.3)
		{
			daRating = 'good';
			score = 200;
		}

		note.rating = daRating;

		totalNotesHit++;

		switch (daRating)
		{
			case "sick": 
				sicks++;
				scoreTxt.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
				health += 0.15;
			case "good": 
				goods++;
				scoreTxt.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.GREEN, LEFT, OUTLINE, FlxColor.BLACK);
				health += 0.1;
			case "bad": 
				bads++;
				scoreTxt.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.RED, LEFT, OUTLINE, FlxColor.BLACK);
				health -= 0.04;
			case "shit":
				shits++;
				scoreTxt.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.GRAY, LEFT, OUTLINE, FlxColor.BLACK);
				health -= 0.1;
		}

		

		songScore += score;

		var pixelShitPart1:String = "";
		var pixelShitPart2:String = '';

		if (curStage.startsWith('school'))
		{
			pixelShitPart1 = 'weeb/pixelUI/';
			pixelShitPart2 = '-pixel';
		}

		rating.loadGraphic(Paths.image(pixelShitPart1 + daRating + pixelShitPart2));
		rating.screenCenter();
		rating.x = coolText.x - 40;
		rating.y -= 60;
		rating.acceleration.y = 550;
		rating.velocity.y -= FlxG.random.int(140, 175);
		rating.velocity.x -= FlxG.random.int(0, 10);

		var comboSpr:FlxSprite = new FlxSprite().loadGraphic(Paths.image(pixelShitPart1 + 'combo' + pixelShitPart2));
		comboSpr.screenCenter();
		comboSpr.x = coolText.x;
		comboSpr.acceleration.y = 600;
		comboSpr.velocity.y -= 150;

		comboSpr.velocity.x += FlxG.random.int(1, 10);
		add(rating);

		if (!curStage.startsWith('school'))
		{
			rating.setGraphicSize(Std.int(rating.width * 0.7));
			rating.antialiasing = true;
			comboSpr.setGraphicSize(Std.int(comboSpr.width * 0.7));
			comboSpr.antialiasing = true;
		}
		else
		{
			rating.setGraphicSize(Std.int(rating.width * daPixelZoom * 0.7));
			comboSpr.setGraphicSize(Std.int(comboSpr.width * daPixelZoom * 0.7));
		}

		comboSpr.updateHitbox();
		rating.updateHitbox();

		var seperatedScore:Array<Int> = [];

		seperatedScore.push(Math.floor(combo / 100));
		seperatedScore.push(Math.floor((combo - (seperatedScore[0] * 100)) / 10));
		seperatedScore.push(combo % 10);

		var daLoop:Int = 0;
		for (i in seperatedScore)
		{
			var numScore:FlxSprite = new FlxSprite().loadGraphic(Paths.image(pixelShitPart1 + 'num' + Std.int(i) + pixelShitPart2));
			numScore.screenCenter();
			numScore.x = coolText.x + (43 * daLoop) - 90;
			numScore.y += 80;

			if (!curStage.startsWith('school'))
			{
				numScore.antialiasing = true;
				numScore.setGraphicSize(Std.int(numScore.width * 0.5));
			}
			else
			{
				numScore.setGraphicSize(Std.int(numScore.width * daPixelZoom));
			}
			numScore.updateHitbox();

			numScore.acceleration.y = FlxG.random.int(200, 300);
			numScore.velocity.y -= FlxG.random.int(140, 160);
			numScore.velocity.x = FlxG.random.float(-5, 5);

			if (combo >= 10 || combo == 0)
				add(numScore);

			FlxTween.tween(numScore, {alpha: 0}, 0.2, {
				onComplete: function(tween:FlxTween)
				{
					numScore.destroy();
				},
				startDelay: Conductor.crochet * 0.002
			});

			daLoop++;
		}
		/* 
			trace(combo);
			trace(seperatedScore);
		 */

		coolText.text = Std.string(seperatedScore);
		// add(coolText);

		FlxTween.tween(rating, {alpha: 0}, 0.2, {
			startDelay: Conductor.crochet * 0.001
		});

		FlxTween.tween(comboSpr, {alpha: 0}, 0.2, {
			onComplete: function(tween:FlxTween)
			{
				coolText.destroy();
				comboSpr.destroy();

				rating.destroy();
			},
			startDelay: Conductor.crochet * 0.001
		});

		curSection += 1;
	}

	private function keyShit():Void
	{

		// HOLDS, check for sustain notes
		var holdArray:Array<Bool> = hold;
		if (keys.contains(true) && /*!boyfriend.stunned && */ generatedMusic)
		{
			if (flipped)
			{
				P2notes.forEachAlive(function(daNote:Note)
					{
						if (daNote.isSustainNote && daNote.canBeHit && !daNote.mustPress && keys[daNote.noteData])
							goodNoteHit(daNote);
					});
			}
			else
			{
				P1notes.forEachAlive(function(daNote:Note)
					{
						if (daNote.isSustainNote && daNote.canBeHit && daNote.mustPress && keys[daNote.noteData])
							goodNoteHit(daNote);
					});
			}

		}

		if (player.holdTimer > Conductor.stepCrochet * 4 * 0.001 && (!keys.contains(true)))
		{
			if (player.animation.curAnim.name.startsWith('sing') && !player.animation.curAnim.name.endsWith('miss'))
				player.dance();
		}

		if (flipped)
		{
			cpuStrums.forEach(function(spr:BabyArrow)
			{
				if (keys[spr.ID] && spr.animation.curAnim.name != 'confirm' && spr.animation.curAnim.name != 'pressed')
					spr.playAnim('pressed', false, spr.ID);
				if (!keys[spr.ID])
					spr.playAnim('static', false, spr.ID);
			});
		}
		else
		{
			playerStrums.forEach(function(spr:BabyArrow)
			{
				if (keys[spr.ID] && spr.animation.curAnim.name != 'confirm' && spr.animation.curAnim.name != 'pressed')
					spr.playAnim('pressed', false, spr.ID);
				if (!keys[spr.ID])
					spr.playAnim('static', false, spr.ID);
			});
		}

	}

	function noteMiss(direction:Int = 1, daNote:Note):Void
	{
		if (!player.stunned)
		{
			if (daNote.isSustainNote)
				health -= 0.03;
			else
				health -= 0.2;

			if (combo > 5 && gf.animOffsets.exists('sad'))
			{
				gf.playAnim('sad');
			}
			combo = 0;

			if (!daNote.isSustainNote)
				misses++; //so you dont get like 20 misses from a long note

			totalNotesHit++; //not actually missing, just for working out the accuracy

			CalculateAccuracy();

			songScore -= 10;

			FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));
			// FlxG.sound.play(Paths.sound('missnote1'), 1, false);
			// FlxG.log.add('played imss note');
			player.playAnim('sing' + sDir[direction] + 'miss', true);
			scoreTxt.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.RED, LEFT, OUTLINE, FlxColor.BLACK);

			player.stunned = true;


			// get stunned for 5 seconds
			new FlxTimer().start(5 / 60, function(tmr:FlxTimer)
			{
				player.stunned = false;
			});

		}
	}
	function missPress(direction:Int = 1):Void //copied, just to stop game from crashing
		{
			if (!player.stunned)
			{
				health -= 0.05;
	
				if (combo > 5 && gf.animOffsets.exists('sad'))
				{
					gf.playAnim('sad');
				}
				combo = 0;
				
				misses++; //so you dont get like 20 misses from a long note
	
				totalNotesHit++; //not actually missing, just for working out the accuracy
	
				CalculateAccuracy();
	
				songScore -= 10;
	
				FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));
				player.playAnim('sing' + sDir[direction] + 'miss', true);
				scoreTxt.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.RED, LEFT, OUTLINE, FlxColor.BLACK);
	
				player.stunned = true;
				// get stunned for 5 seconds
				new FlxTimer().start(5 / 60, function(tmr:FlxTimer)
				{
					player.stunned = false;
				});
	
			}
		}



	function goodNoteHit(note:Note):Void
	{
		if (!note.wasGoodHit)
		{
			if (!note.isSustainNote)
			{
				popUpScore(note);
				combo += 1;
			}
			else
			{
				note.rating = "sick";
				health += 0.02;
				sicks++;
				totalNotesHit++;
			}


			



			var altAnim:String = "";

			if (currentSection != null)
				{
					if (currentSection.altAnim)
						altAnim = '-alt';
				}	
			if (note.alt)
				altAnim = '-alt';

			player.playAnim('sing' + sDir[note.noteData] + altAnim, true);
			player.holdTimer = 0;


			if (note.burning) //fire note
				{
					badNoteHit();
					health -= 0.45;
				}

			else if (note.death) //halo note
				{
					badNoteHit();
					health -= 2.2;
				}
			else if (note.angel) //angel note
				{
					switch(note.rating)
					{
						case "shit": 
							badNoteHit();
							health -= 2;
						case "bad": 
							badNoteHit();
							health -= 0.5;
						case "good": 
							health += 0.5;
						case "sick": 
							health += 1;

					}
				}
			else if (note.bob) //bob note
				{
					HealthDrain();
				}

			CalculateAccuracy();


			


			if (flipped)
			{
				cpuStrums.forEach(function(spr:BabyArrow)
				{
					if (Math.abs(note.noteData) == spr.ID)
					{
						spr.playAnim('confirm', true, spr.ID);
					}
				});
			}
			else
			{
				playerStrums.forEach(function(spr:BabyArrow)
				{
					if (Math.abs(note.noteData) == spr.ID)
					{
						spr.playAnim('confirm', true, spr.ID);
					}
				});
			}

			note.wasGoodHit = true;
			vocals.volume = 1;
			var strums = "player";
			if (flipped)
				strums = "cpu";

			if (!note.isSustainNote)
			{
				if (note.rating == "sick")
					doNoteSplash(note.x, note.y, note.noteData);
				removeNote(note, strums);
			}
			grace = true;
			new FlxTimer().start(0.15, function(tmr:FlxTimer)
			{
				grace = false;
			});
		}
	}
	function doNoteSplash(noteX:Float, noteY:Float, nData:Int)
		{
			var recycledNote = noteSplashes.recycle(NoteSplash);
			var xPos:Float = 0;
			var yPos:Float = 0;
			if (flipped)
			{
				xPos = cpuStrums.members[nData].x;
				yPos = cpuStrums.members[nData].y;
			}
			else
			{
				xPos = playerStrums.members[nData].x;
				yPos = playerStrums.members[nData].y;
			}
			recycledNote.makeSplash(xPos, yPos, nData);
			noteSplashes.add(recycledNote);
			
		}

	function HealthDrain():Void //code from vs bob
		{
			badNoteHit();
			new FlxTimer().start(0.01, function(tmr:FlxTimer)
			{
				health -= 0.005;
			}, 300);
		}

	function badNoteHit():Void
		{
			player.playAnim('hit', true);
			FlxG.sound.play(Paths.soundRandom('badnoise', 1, 3), FlxG.random.float(0.7, 1));
		}

	function removeNote(daNote:Note, strums:String = 'player'):Void
	{
		daNote.kill();
		if (strums == 'player')
			P1notes.remove(daNote, true);
		else
			P2notes.remove(daNote, true);
		daNote.destroy();
	}

	function updateRank():Void
	{
		var accuracyToRank:Array<Bool> = [
			accuracy <= 40,
			accuracy <= 50,
			accuracy <= 60,
			accuracy <= 70,
			accuracy <= 80,
			accuracy <= 90,
			accuracy <= 100,
		];

		if(misses == 0)
			curRank = "FC";
		else
		{
			for (i in 0...accuracyToRank.length)
			{
				if (accuracyToRank[i])
				{
					curRank = ranksList[i];
					break;
				}
			}
		}

	}
	
	function CalculateAccuracy():Void
	{
		var notesAddedUp = sicks + (goods * 0.85) + (bads * 0.5) + (shits * 0.25);
		accuracy = Math.floor((notesAddedUp / totalNotesHit) * 100);

		updateRank();
	}
	var justChangedMania:Bool = false;

	public function switchMania(newMania:Int) //i know this is pretty big, ive tried a lot of things, this is the one that works
	{
		if (mania == 2) //so it doesnt break the fucking game
		{
			maniaToChange = newMania;
			justChangedMania = true;
			new FlxTimer().start(10, function(tmr:FlxTimer)
				{
					justChangedMania = false; //cooldown timer
				});
			switch(newMania)
			{
				case 10: 
					Note.newNoteScale = 0.7; //fix the note scales pog
				case 11: 
					Note.newNoteScale = 0.6;
				case 12: 
					Note.newNoteScale = 0.5;
				case 13: 
					Note.newNoteScale = 0.65;
				case 14: 
					Note.newNoteScale = 0.58;
				case 15: 
					Note.newNoteScale = 0.55;
				case 16: 
					Note.newNoteScale = 0.7;
				case 17: 
					Note.newNoteScale = 0.7;
				case 18: 
					Note.newNoteScale = 0.7;
			}
	
			strumLineNotes.forEach(function(spr:FlxSprite)
			{
				spr.animation.play('static'); //changes to static because it can break the scaling of the static arrows if they are doing the confirm animation
				spr.setGraphicSize(Std.int((spr.width / Note.prevNoteScale) * Note.newNoteScale));
				spr.centerOffsets();
				Note.scaleSwitch = false;
			});
	
			cpuStrums.forEach(function(spr:BabyArrow)
			{
				spr.moveKeyPositions(spr, newMania, 0);
			});
			playerStrums.forEach(function(spr:BabyArrow)
			{
				spr.moveKeyPositions(spr, newMania, 1);
			});
	
		}
	}

	var trainMoving:Bool = false;
	var trainFrameTiming:Float = 0;

	var trainCars:Int = 8;
	var trainFinishing:Bool = false;
	var trainCooldown:Int = 0;

	function trainStart():Void
	{
		trainMoving = true;
		if (!trainSound.playing)
			trainSound.play(true);
	}

	var startedMoving:Bool = false;

	function updateTrainPos():Void
	{
		if (trainSound.time >= 4700)
		{
			startedMoving = true;
			gf.playAnim('hairBlow');
		}

		if (startedMoving)
		{
			phillyTrain.x -= 400;

			if (phillyTrain.x < -2000 && !trainFinishing)
			{
				phillyTrain.x = -1150;
				trainCars -= 1;

				if (trainCars <= 0)
					trainFinishing = true;
			}

			if (phillyTrain.x < -4000 && trainFinishing)
				trainReset();
		}
	}

	function trainReset():Void
	{
		gf.playAnim('hairFall');
		phillyTrain.x = FlxG.width + 200;
		trainMoving = false;
		// trainSound.stop();
		// trainSound.time = 0;
		trainCars = 8;
		trainFinishing = false;
		startedMoving = false;
	}

	override function stepHit()
	{
		super.stepHit();
		if (FlxG.sound.music.time > Conductor.songPosition + 20 || FlxG.sound.music.time < Conductor.songPosition - 20)
		{
			resyncVocals();
		}

		if (dad.curCharacter == 'spooky' && curStep % 4 == 2)
		{
			// dad.dance();
		}
	}



	override function beatHit()
	{
		super.beatHit();

		if (generatedMusic)
		{
			P1notes.sort(FlxSort.byY, FlxSort.DESCENDING);
			P2notes.sort(FlxSort.byY, FlxSort.DESCENDING);
		}
		StagePiece.daBeat = curBeat;
		for (piece in dancingStagePieces.members)
		{
			piece.dance();
		}


		if (currentSection != null)
		{
			if (currentSection.changeBPM)
			{
				Conductor.changeBPM(currentSection.bpm);
				FlxG.log.add('CHANGED BPM!');
			}
			// else
			// Conductor.changeBPM(SONG.bpm);

			// Dad doesnt interupt his own notes
			if (currentSection.mustHitSection)
				cpu.dance();
		}
		// FlxG.log.add('change bpm' + SONG.notes[Std.int(curStep / 16)].changeBPM);
		wiggleShit.update(Conductor.crochet);

		// HARDCODING FOR MILF ZOOMS!
		if (curSong.toLowerCase() == 'milf' && curBeat >= 168 && curBeat < 200 && camZooming && FlxG.camera.zoom < 1.35)
		{
			FlxG.camera.zoom += 0.015;
			camHUD.zoom += 0.03;
		}

		if (camZooming && FlxG.camera.zoom < 1.35 && curBeat % 4 == 0)
		{
			FlxG.camera.zoom += 0.015;
			camHUD.zoom += 0.03;
		}

		iconP1.setGraphicSize(Std.int(iconP1.width + 30));
		iconP2.setGraphicSize(Std.int(iconP2.width + 30));

		iconP1.updateHitbox();
		iconP2.updateHitbox();

		if (curBeat % gfSpeed == 0)
		{
			gf.dance();
		}

		if (!player.animation.curAnim.name.startsWith("sing"))
		{
			player.dance();
		}

		if (curBeat % 8 == 7 && curSong == 'Bopeebo')
		{
			boyfriend.playAnim('hey', true);
		}

		if (curBeat % 16 == 15 && SONG.song == 'Tutorial' && dad.curCharacter == 'gf' && curBeat > 16 && curBeat < 48)
		{
			boyfriend.playAnim('hey', true);
			dad.playAnim('cheer', true);
		}

		switch (curStage)
		{		
			case "philly":
				if (!trainMoving)
					trainCooldown += 1;

				if (curBeat % 4 == 0)
				{
					phillyCityLights.forEach(function(light:FlxSprite)
					{
						light.visible = false;
					});

					curLight = FlxG.random.int(0, phillyCityLights.length - 1);

					phillyCityLights.members[curLight].visible = true;
					// phillyCityLights.members[curLight].alpha = 1;
				}

				if (curBeat % 8 == 4 && FlxG.random.bool(30) && !trainMoving && trainCooldown > 8)
				{
					trainCooldown = FlxG.random.int(-4, 0);
					trainStart();
				}
		}
	}

	var curLight:Int = 0;
}
