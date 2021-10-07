package;

import flixel.FlxSprite;
import flixel.FlxG;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
#if polymod
import polymod.format.ParseRules.TargetSignatureElement;
#end
import PlayState;
import Shaders;

using StringTools;

class Note extends FlxSprite
{
	public var strumTime:Float = 0;
	public var baseStrum:Float = 0;
	
	public var charterSelected:Bool = false;

	public var rStrumTime:Float = 0;

	public var mustPress:Bool = false;
	public var noteData:Int = 0;
	public var canBeHit:Bool = false;
	public var tooLate:Bool = false;
	public var wasGoodHit:Bool = false;
	public var prevNote:Note;
	public var noteType:Int = 0;

	public var sustainLength:Float = 0;
	public var isSustainNote:Bool = false;
	public var noteColor:Int;

	var HSV:HSVEffect = new HSVEffect();


	public var regular:Bool = false; //just a regular note
	public var burning:Bool = false; //fire
	public var death:Bool = false;    //halo/death
	public var warning:Bool = false; //warning
	public var angel:Bool = false; //angel
	public var alt:Bool = false; //alt animation note
	public var bob:Bool = false; //bob arrow
	public var glitch:Bool = false; //glitch

	public var noteScore:Float = 1;
	public static var mania:Int = 0;

	public static var swagWidth:Float = 160 * 0.7;
	public static var noteScale:Float;
	public static var newNoteScale:Float = 0;
	public static var prevNoteScale:Float = 0.5;
	public static var pixelnoteScale:Float;
	public static var scaleSwitch:Bool = true;
	public static var tooMuch:Float = 30;
	public var rating:String = "shit";
	public var modAngle:Float = 0;
	public var localAngle:Float = 0; 
	public static var frameN:Array<String> = ['purple', 'blue', 'green', 'red'];

	var pathList:Array<String> = [
        'noteassets/NOTE_assets',
        'noteassets/PURPLE_NOTE_assets',
        'noteassets/BLUE_NOTE_assets',
        'noteassets/GREEN_NOTE_assets',
        'noteassets/RED_NOTE_assets'
    ];
	public var style:String = "";
	public var sustainActive:Bool = true;
	public var noteColors:Array<String> = ['purple', 'blue', 'green', 'red', 'white', 'yellow', 'violet', 'darkred', 'dark'];
	//var pixelnoteColors:Array<String> = ['purple', 'blue', 'green', 'red', 'white', 'yellow', 'violet', 'black', 'dark'];

	public static var noteScales:Array<Float> = [0.7, 0.6, 0.5, 0.65, 0.58, 0.55, 0.7, 0.7, 0.7];
	public static var pixelNoteScales:Array<Float> = [1, 0.83, 0.7, 0.9, 0.8, 0.74, 1, 1, 1];
	public static var noteWidths:Array<Float> = [112, 84, 66.5, 91, 77, 70, 140, 126, 119];
	public var sustainOffset:Float = 0;
	public var sustainEndOffset:Float = 0;
	public var isSustainEnd:Bool = false;

	var colorShit:Array<Float>;
	var pathToUse:Int = 0;
	public var scaleMulti:Float = 1;


	
	public var changedSpeed:Bool = false;
	public var velocityData:Array<Float>;
	public var speedMulti:Float = 1;
	public var velocityChangeTime:Float;
	public var startPos:Float = 0;


	public var speed:Float = 1; //yes this is happening, per note speed

	public function new(strumTime:Float, noteData:Int, ?noteType:Int = 0, ?sustainNote:Bool = false, ?_speed:Float = 1, ?_velocityData:Array<Float>, ?_mustPress:Bool = false, ?prevNote:Note)
	{
		swagWidth = 160 * 0.7; //factor not the same as noteScale
		noteScale = 0.7;
		pixelnoteScale = 1;
		mania = 0;
		if (PlayState.SONG.mania != 0)
			{
				mania = PlayState.SONG.mania;
				swagWidth = noteWidths[mania];
				noteScale = noteScales[mania];
				pixelnoteScale = pixelNoteScales[mania];
				
			}
			if (_speed == 1)
				speed = PlayState.SongSpeed;
			else
				speed = _speed;

		super();

		if (prevNote == null)
			prevNote = this;
		this.noteType = noteType;
		this.prevNote = prevNote; 
		isSustainNote = sustainNote;

		velocityData = _velocityData;
		mustPress = _mustPress;

		//speed = FlxMath.roundDecimal(FlxG.random.float(1.5, 3.8), 2);
		speed = FlxMath.roundDecimal((speed / 0.7) * (noteScale * scaleMulti), 2); //adjusts speed based on note size

		


		x += 50;

		if (PlayState.SONG.mania == 2)
		{
			x -= tooMuch;
		}


		// MAKE SURE ITS DEFINITELY OFF SCREEN?
		y -= 2000;
		if (Main.editor)
			this.strumTime = strumTime;
		else 
			this.strumTime = Math.round(strumTime);

		if (this.strumTime < 0 )
			this.strumTime = 0;


		if (velocityData != null)
		{
			speedMulti = _velocityData[0];
			velocityChangeTime = _velocityData[1];
		}
		//speedMulti = FlxMath.roundDecimal(FlxG.random.float(0.5, 2.5), 2);
		//velocityChangeTime = FlxMath.roundDecimal(FlxG.random.float(0, 800), 2);

		this.noteData = noteData % 9;




		regular = noteType == 0;
		burning = noteType == 1;
		death = noteType == 2;
		warning = noteType == 3;
		angel = noteType == 4;
		alt = noteType == 5;
		bob = noteType == 6;
		glitch = noteType == 7;

		this.shader = HSV.shader;


		switch (mania)
		{
			case 0: 
				frameN = ['purple', 'blue', 'green', 'red'];
			case 1: 
				frameN = ['purple', 'green', 'red', 'yellow', 'blue', 'dark'];
			case 2: 
				frameN = ['purple', 'blue', 'green', 'red', 'white', 'yellow', 'violet', 'darkred', 'dark'];
			case 3: 
				frameN = ['purple', 'blue', 'white', 'green', 'red'];
			case 4: 
				frameN = ['purple', 'green', 'red', 'white', 'yellow', 'blue', 'dark'];
			case 5: 
				frameN = ['purple', 'blue', 'green', 'red', 'yellow', 'violet', 'darkred', 'dark'];
			case 6: 
				frameN = ['white'];
			case 7: 
				frameN = ['purple', 'red'];
			case 8: 
				frameN = ['purple', 'white', 'red'];

		}

		if (!_mustPress)
		{
			ColorPresets.fixColorArray(mania);
			colorShit = ColorPresets.ccolorArray[noteData];
		}
		else
		{
			SaveData.fixColorArray(mania);
			colorShit = SaveData.colorArray[noteData];
		}

		pathToUse = Std.int(colorShit[3]);

		if (pathToUse == 5)
			style = 'pixel';

		if (SaveData.middlescroll && !_mustPress)
			scaleMulti = 0.6;


		switch (style)
		{
			case 'pixel':
				loadGraphic(Paths.image('noteassets/pixel/arrows-pixels'), true, 17, 17);
				if (isSustainNote && noteType == 0)
					loadGraphic(Paths.image('noteassets/pixel/arrowEnds'), true, 7, 6);

				for (i in 0...9)
				{
					animation.add(noteColors[i] + 'Scroll', [i + 9]); // Normal notes
					animation.add(noteColors[i] + 'hold', [i]); // Holds
					animation.add(noteColors[i] + 'holdend', [i + 9]); // Tails
				}
				if (burning)
					{
						loadGraphic(Paths.image('noteassets/pixel/firenotes/arrows-pixels'), true, 17, 17);
						if (isSustainNote && burning)
							loadGraphic(Paths.image('noteassets/pixel/firenotes/arrowEnds'), true, 7, 6);
						for (i in 0...9)
							{
								animation.add(noteColors[i] + 'Scroll', [i + 9]); // Normal notes
								animation.add(noteColors[i] + 'hold', [i]); // Holds
								animation.add(noteColors[i] + 'holdend', [i + 9]); // Tails
							}
					}
				else if (death)
					{
						loadGraphic(Paths.image('noteassets/pixel/halo/arrows-pixels'), true, 17, 17);
						if (isSustainNote && death)
							loadGraphic(Paths.image('noteassets/pixel/halo/arrowEnds'), true, 7, 6);
						for (i in 0...9)
							{
								animation.add(noteColors[i] + 'Scroll', [i + 9]); // Normal notes
								animation.add(noteColors[i] + 'hold', [i]); // Holds
								animation.add(noteColors[i] + 'holdend', [i + 9]); // Tails
							}
					}
				else if (warning)
					{
						loadGraphic(Paths.image('noteassets/pixel/warning/arrows-pixels'), true, 17, 17);
						if (isSustainNote && warning)
							loadGraphic(Paths.image('noteassets/pixel/warning/arrowEnds'), true, 7, 6);
						for (i in 0...9)
							{
								animation.add(noteColors[i] + 'Scroll', [i + 9]); // Normal notes
								animation.add(noteColors[i] + 'hold', [i]); // Holds
								animation.add(noteColors[i] + 'holdend', [i + 9]); // Tails
							}
					}
				else if (angel)
					{
						loadGraphic(Paths.image('noteassets/pixel/angel/arrows-pixels'), true, 17, 17);
						if (isSustainNote && angel)
							loadGraphic(Paths.image('noteassets/pixel/angel/arrowEnds'), true, 7, 6);
						for (i in 0...9)
							{
								animation.add(noteColors[i] + 'Scroll', [i + 9]); // Normal notes
								animation.add(noteColors[i] + 'hold', [i]); // Holds
								animation.add(noteColors[i] + 'holdend', [i + 9]); // Tails
							}
					}
				else if (bob)
					{
						loadGraphic(Paths.image('noteassets/pixel/bob/arrows-pixels'), true, 17, 17);
						if (isSustainNote && bob)
							loadGraphic(Paths.image('noteassets/pixel/bob/arrowEnds'), true, 7, 6);
						for (i in 0...9)
							{
								animation.add(noteColors[i] + 'Scroll', [i + 9]); // Normal notes
								animation.add(noteColors[i] + 'hold', [i]); // Holds
								animation.add(noteColors[i] + 'holdend', [i + 9]); // Tails
							}
					}
				else if (glitch)
					{
						loadGraphic(Paths.image('noteassets/pixel/glitch/arrows-pixels'), true, 17, 17);
						if (isSustainNote && glitch)
							loadGraphic(Paths.image('noteassets/pixel/glitch/arrowEnds'), true, 7, 6);
						for (i in 0...9)
							{
								animation.add(noteColors[i] + 'Scroll', [i + 9]); // Normal notes
								animation.add(noteColors[i] + 'hold', [i]); // Holds
								animation.add(noteColors[i] + 'holdend', [i + 9]); // Tails
							}
					}

				

				setGraphicSize(Std.int(width * PlayState.daPixelZoom * pixelnoteScale * scaleMulti));
				updateHitbox();
			default:
				var color:String = frameN[noteData];
                
				frames = Paths.getSparrowAtlas(pathList[pathToUse]);
				for (i in 0...9)
					{
						animation.addByPrefix(noteColors[i] + 'Scroll', noteColors[i] + '0'); // Normal notes
						animation.addByPrefix(noteColors[i] + 'hold', noteColors[i] + ' hold piece'); // Hold
						animation.addByPrefix(noteColors[i] + 'holdend', noteColors[i] + ' hold end'); // Tails
					}
				if (burning || death || warning || angel || bob || glitch)
					{
						frames = Paths.getSparrowAtlas('noteassets/notetypes/NOTE_types');
						switch(noteType)
						{
							case 1: 
								for (i in 0...9)
									{
										animation.addByPrefix(noteColors[i] + 'Scroll', 'fire ' + noteColors[i] + '0'); // Normal notes
										animation.addByPrefix(noteColors[i] + 'hold', 'fire hold piece'); // Hold
										animation.addByPrefix(noteColors[i] + 'holdend', 'fire hold end'); // Tails
									}
							case 2: 
								for (i in 0...9)
									{
										animation.addByPrefix(noteColors[i] + 'Scroll', 'halo ' + noteColors[i] + '0'); // Normal notes
										animation.addByPrefix(noteColors[i] + 'hold', 'halo hold piece'); // Hold
										animation.addByPrefix(noteColors[i] + 'holdend', 'halo hold end'); // Tails
									}
							case 3: 
								for (i in 0...9)
									{
										animation.addByPrefix(noteColors[i] + 'Scroll', 'warning ' + noteColors[i] + '0'); // Normal notes
										animation.addByPrefix(noteColors[i] + 'hold', 'warning hold piece'); // Hold
										animation.addByPrefix(noteColors[i] + 'holdend', 'warning hold end'); // Tails
									}
							case 4: 
								for (i in 0...9)
									{
										animation.addByPrefix(noteColors[i] + 'Scroll', 'angel ' + noteColors[i] + '0'); // Normal notes
										animation.addByPrefix(noteColors[i] + 'hold', 'angel hold piece'); // Hold
										animation.addByPrefix(noteColors[i] + 'holdend', 'angel hold end'); // Tails
									}
							case 6: 
								for (i in 0...9)
									{
										animation.addByPrefix(noteColors[i] + 'Scroll', 'bob ' + noteColors[i] + '0'); // Normal notes
										animation.addByPrefix(noteColors[i] + 'hold', 'bob hold piece'); // Hold
										animation.addByPrefix(noteColors[i] + 'holdend', 'bob hold end'); // Tails
									}
							case 7:
								for (i in 0...9)
									{
										animation.addByPrefix(noteColors[i] + 'Scroll', 'glitch ' + noteColors[i] + '0'); // Normal notes
										animation.addByPrefix(noteColors[i] + 'hold', 'glitch hold piece'); // Hold
										animation.addByPrefix(noteColors[i] + 'holdend', 'glitch hold end'); // Tails
									}
						}
					}


				setGraphicSize(Std.int(width * noteScale * scaleMulti));
				updateHitbox();
				antialiasing = true;
		}
		if (regular || alt)
		{
			HSV.hue = colorShit[0];
			HSV.saturation = colorShit[1];
			HSV.brightness = colorShit[2];
			HSV.update();
		}



		x += swagWidth * noteData;
		animation.play(frameN[noteData] + 'Scroll');
		noteColor = noteData;

		if (isSustainNote && prevNote != null)
		{
			speed = prevNote.speed;
			speedMulti = prevNote.speedMulti;
			velocityChangeTime = prevNote.velocityChangeTime;
			noteScore * 0.2;
			alpha = 0.6;

			x += width / 2;

			animation.play(frameN[noteData] + 'holdend');

			updateHitbox();

			x -= width / 2;

			if (PlayState.curStage.startsWith('school'))
				x += 30;

			if (prevNote.isSustainNote)
			{
				prevNote.animation.play(frameN[prevNote.noteData] + 'hold');
				prevNote.updateHitbox();
				prevNote.scale.y *= Conductor.stepCrochet / 100 * 1.5 * speed * speedMulti * (0.7 / (noteScale * scaleMulti));
				prevNote.updateHitbox();

				prevNote.sustainOffset = Math.round(-prevNote.offset.y);
				sustainOffset = Math.round(-offset.y);

			}


		}

		if ((SaveData.downscroll && _mustPress && !isSustainNote) || (SaveData.P2downscroll && !_mustPress && !isSustainNote))
			scale.y *= -1;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (animation.curAnim.name.endsWith('holdend') && prevNote.isSustainNote)
		{
			isSustainEnd = true;
		}
		else
		{
			isSustainEnd = false;
		}
		/*if (animation.curAnim.name != frameN[noteData] + "Scroll" && animation.curAnim.name.endsWith('Scroll')) //this fixes the note colors when they switch
			animation.play(frameN[noteData] + 'Scroll');
			
		if (animation.curAnim.name != frameN[noteData] + "hold" && animation.curAnim.name.endsWith('hold'))
			animation.play(frameN[noteData] + 'hold');

		if (animation.curAnim.name != frameN[noteData] + "holdend" && animation.curAnim.name.endsWith('holdend'))
			animation.play(frameN[noteData] + 'holdend');*/

		if (!scaleSwitch)
			{
				if (!isSustainNote && noteType == 0)
					setGraphicSize(Std.int((width / prevNoteScale) * newNoteScale)); //this fixes the note scale
				else if (!isSustainNote && noteType != 0)
				{
					//setGraphicSize(Std.int((width / prevNoteScale) * newNoteScale)); //they smal for some reason
					//updateHitbox();
				}
				


				switch(PlayState.maniaToChange)
				{
					case 10: 
						switch (noteColor)
						{
							case 0: 
								noteData = 0;
							case 1: 
								noteData = 1;
							case 2: 
								noteData = 2;
							case 3: 
								noteData = 3;
							case 4: 
								noteData = 2;
							case 5: 
								noteData = 0;
							case 6: 
								noteData = 1;
							case 7:
								noteData = 2;
							case 8:
								noteData = 3;
						}

					case 11: 
						switch (noteColor)
						{
							case 0: 
								noteData = 0;
							case 1: 
								noteData = 1;
							case 2: 
								noteData = 2;
							case 3: 
								noteData = 3;
							case 4: 
								noteData = 2;
							case 5: 
								noteData = 5;
							case 6: 
								noteData = 1;
							case 7:
								noteData = 2;
							case 8:
								noteData = 8;
						}

					case 12: 
						switch (noteColor)
						{
							case 0: 
								noteData = 0;
							case 1: 
								noteData = 1;
							case 2: 
								noteData = 2;
							case 3: 
								noteData = 3;
							case 4: 
								noteData = 4;
							case 5: 
								noteData = 5;
							case 6: 
								noteData = 6;
							case 7:
								noteData = 7;
							case 8:
								noteData = 8;
						}
					case 13: 
						switch (noteColor)
						{
							case 0: 
								noteData = 0;
							case 1: 
								noteData = 1;
							case 2: 
								noteData = 2;
							case 3: 
								noteData = 3;
							case 4: 
								noteData = 4;
							case 5: 
								noteData = 0;
							case 6: 
								noteData = 1;
							case 7:
								noteData = 2;
							case 8:
								noteData = 3;
						}


					case 14: 
						switch (noteColor)
						{
							case 0: 
								noteData = 0;
							case 1: 
								noteData = 1;
							case 2: 
								noteData = 2;
							case 3: 
								noteData = 3;
							case 4: 
								noteData = 4;
							case 5: 
								noteData = 5;
							case 6: 
								noteData = 1;
							case 7:
								noteData = 2;
							case 8:
								noteData = 8;
						}


					case 15: 
						switch (noteColor)
						{
							case 0: 
								noteData = 0;
							case 1: 
								noteData = 1;
							case 2: 
								noteData = 2;
							case 3: 
								noteData = 3;
							case 4: 
								noteData = 2;
							case 5: 
								noteData = 5;
							case 6: 
								noteData = 6;
							case 7:
								noteData = 7;
							case 8:
								noteData = 8;
						}


					case 16: 
						noteData = 4;
					case 17: 
						switch (noteColor)
						{
							case 0: 
								noteData = 0;
							case 1: 
								noteData = 0;
							case 2: 
								noteData = 3;
							case 3: 
								noteData = 3;
							case 4: 
								noteData = 0;
							case 5: 
								noteData = 0;
							case 6: 
								noteData = 0;
							case 7:
								noteData = 3;
							case 8:
								noteData = 3;
						}


					case 18: 
						switch (noteColor)
						{
							case 0: 
								noteData = 0;
							case 1: 
								noteData = 0;
							case 2: 
								noteData = 4;
							case 3: 
								noteData = 3;
							case 4: 
								noteData = 4;
							case 5: 
								noteData = 0;
							case 6: 
								noteData = 0;
							case 7:
								noteData = 4;
							case 8:
								noteData = 3;
						}


				}
				//scaleSwitch = true;
			}

		if ((mustPress && !PlayState.flipped) || (!mustPress && PlayState.flipped))
		{
			if (burning || death)
			{
				if (strumTime - Conductor.songPosition <= (100 * Conductor.timeScale)
					&& strumTime - Conductor.songPosition >= (-50 * Conductor.timeScale))
					canBeHit = true;
				else
					canBeHit = false;	
			}
			else
			{
				if (strumTime - Conductor.songPosition <= (145 * Conductor.timeScale)
					&& strumTime - Conductor.songPosition >= (-166 * Conductor.timeScale))
					canBeHit = true;
				else
					canBeHit = false;
			}
			if (strumTime - Conductor.songPosition < -166 && !wasGoodHit)
				tooLate = true;
		}
		else
		{
			canBeHit = false;

			if (strumTime <= Conductor.songPosition)
				wasGoodHit = true;
		}

		if (tooLate && !wasGoodHit)
		{
			if (alpha > 0.3)
				alpha = 0.3;
		}
	}



	public function fixSustains():Void
	{
		if (animation.curAnim.name.endsWith('hold') && isSustainNote)
		{
			scale.y = 1;
			scale.y *= Conductor.stepCrochet / 100 * 1.5 * FlxMath.roundDecimal(speed * speedMulti, 2) * (0.7 / (noteScale * scaleMulti));
			updateHitbox();
		}
	} 
}