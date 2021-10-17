package;

import lime.utils.Assets;
import flixel.FlxG;

#if sys
import sys.io.File;
import sys.FileSystem;
#end

using StringTools;

class CoolUtil
{
	public static var difficultyArray:Array<String> = ['EASY', "NORMAL", "HARD"]; //old stinky one

	public static var CurSongDiffs:Array<String> = ['EASY', "NORMAL", "HARD"];

	public static function difficultyString():String
	{
		return CurSongDiffs[PlayState.storyDifficulty];
	}

	public static function coolTextFile(path:String):Array<String>
	{
		var daList:Array<String> = File.getContent(path).trim().split('\n');

		for (i in 0...daList.length)
		{
			daList[i] = daList[i].trim();
		}

		return daList;
	}

	public static function getSongFromJsons(song:String, diff:Int, customChart:Bool = false)
	{
		var path = "assets/data/charts/" + song;
		if (customChart)
			path = "assets/data/customChart/" + song;
		if (FileSystem.exists(path))
		{
			var diffs:Array<String> = [];
			var sortedDiffs:Array<String> = [];
			diffs = FileSystem.readDirectory(path);

			var easy:String = "";
			var normal:String = "";
			var hard:String = "";
			var extra:Array<String> = [];
			var extraCount = 0;
			
			for (file in diffs)
			{
				if (!file.endsWith(".json")) //get rid of non json files
					diffs.remove(file);
				else if (file.endsWith("-easy.json")) //add easy first
				{
					easy = file;
				}
				else if (file.endsWith(song + ".json")) //add normal
				{
					normal = file;
				}
				else if (file.endsWith("-hard.json")) //add hard
				{
					hard = file;
				}
				else
				{
					extra.push(file);
					extraCount++;
				}
			}
			var textDiffs:Array<String> = [];
			if (easy != "")
			{
				sortedDiffs.push(easy); //pushes them in correct order
				textDiffs.push("Easy");
			}
			if (normal != "")
			{
				sortedDiffs.push(normal);
				textDiffs.push("Normal");
			}
			if (hard != "")
			{
				sortedDiffs.push(hard);
				textDiffs.push("Hard");
			}
			if (extraCount != 0)
				for (i in extra)
				{
					sortedDiffs.push(i);
				}
					


			var outputDiffs:Array<String> = [];
			for (file in sortedDiffs)
			{
				var noJson = StringTools.replace(file,".json", "");
				var noSongName = StringTools.replace(noJson,song.toLowerCase(), "");
				outputDiffs.push(noSongName); //gets just the difficulty on the end of the file
			}
			trace(outputDiffs);
			
			if (extraCount != 0)
				for (file in extra)
				{
					var noJson = StringTools.replace(file,".json", "");
					var noSongName = StringTools.replace(noJson,song.toLowerCase(), "");
					var fixedShit = StringTools.replace(noSongName,"-", "");
					textDiffs.push(fixedShit.toUpperCase()); //upper cases the difficulty to use them in the array
				}
			CurSongDiffs = textDiffs;
			return song + outputDiffs[diff];
		}
		else 
			return "tutorial"; //in case it dont work lol
	}

	public static function bindCheck(mania:Int)
	{
		var binds:Array<String> = [FlxG.save.data.leftBind,FlxG.save.data.downBind, FlxG.save.data.upBind, FlxG.save.data.rightBind];
		switch(mania)
		{
			case 0: 
				binds = [FlxG.save.data.leftBind,FlxG.save.data.downBind, FlxG.save.data.upBind, FlxG.save.data.rightBind];
			case 1: 
				binds = [FlxG.save.data.L1Bind, FlxG.save.data.U1Bind, FlxG.save.data.R1Bind, FlxG.save.data.L2Bind, FlxG.save.data.D1Bind, FlxG.save.data.R2Bind];
			case 2: 
				binds = [FlxG.save.data.N0Bind, FlxG.save.data.N1Bind, FlxG.save.data.N2Bind, FlxG.save.data.N3Bind, FlxG.save.data.N4Bind, FlxG.save.data.N5Bind, FlxG.save.data.N6Bind, FlxG.save.data.N7Bind, FlxG.save.data.N8Bind];
			case 3: 
				binds = [FlxG.save.data.leftBind,FlxG.save.data.downBind, FlxG.save.data.N4Bind, FlxG.save.data.upBind, FlxG.save.data.rightBind];
			case 4: 
				binds = [FlxG.save.data.L1Bind, FlxG.save.data.U1Bind, FlxG.save.data.R1Bind,FlxG.save.data.N4Bind, FlxG.save.data.L2Bind, FlxG.save.data.D1Bind, FlxG.save.data.R2Bind];
			case 5: 
				binds = [FlxG.save.data.N0Bind, FlxG.save.data.N1Bind, FlxG.save.data.N2Bind, FlxG.save.data.N3Bind, FlxG.save.data.N5Bind, FlxG.save.data.N6Bind, FlxG.save.data.N7Bind, FlxG.save.data.N8Bind];
			case 6: 
				binds = [FlxG.save.data.N4Bind];
			case 7:
				binds = [FlxG.save.data.leftBind, FlxG.save.data.rightBind];
			case 8: 
				binds = [FlxG.save.data.leftBind, FlxG.save.data.N4Bind, FlxG.save.data.rightBind];
		}
		return binds;
	}

	public static function P2bindCheck(mania:Int)
		{
			var P2binds:Array<String> = [FlxG.save.data.P2leftBind,FlxG.save.data.P2downBind, FlxG.save.data.P2upBind, FlxG.save.data.P2rightBind];
			switch(mania)
			{
				case 0: 
					P2binds = [FlxG.save.data.P2leftBind,FlxG.save.data.P2downBind, FlxG.save.data.P2upBind, FlxG.save.data.P2rightBind];
				case 1: 
					P2binds = [FlxG.save.data.P2L1Bind, FlxG.save.data.P2U1Bind, FlxG.save.data.P2R1Bind, FlxG.save.data.P2L2Bind, FlxG.save.data.P2D1Bind, FlxG.save.data.P2R2Bind];
				case 2: 
					P2binds = [FlxG.save.data.P2N0Bind, FlxG.save.data.P2N1Bind, FlxG.save.data.P2N2Bind, FlxG.save.data.P2N3Bind, FlxG.save.data.P2N4Bind, FlxG.save.data.P2N5Bind, FlxG.save.data.P2N6Bind, FlxG.save.data.P2N7Bind, FlxG.save.data.P2N8Bind];
				case 3: 
					P2binds = [FlxG.save.data.P2leftBind,FlxG.save.data.P2downBind, FlxG.save.data.P2N4Bind, FlxG.save.data.P2upBind, FlxG.save.data.P2rightBind];
				case 4: 
					P2binds = [FlxG.save.data.P2L1Bind, FlxG.save.data.P2U1Bind, FlxG.save.data.P2R1Bind,FlxG.save.data.P2N4Bind, FlxG.save.data.P2L2Bind, FlxG.save.data.P2D1Bind, FlxG.save.data.P2R2Bind];
				case 5: 
					P2binds = [FlxG.save.data.P2N0Bind, FlxG.save.data.P2N1Bind, FlxG.save.data.P2N2Bind, FlxG.save.data.P2N3Bind, FlxG.save.data.P2N5Bind, FlxG.save.data.P2N6Bind, FlxG.save.data.P2N7Bind, FlxG.save.data.P2N8Bind];
				case 6: 
					P2binds = [FlxG.save.data.P2N4Bind];
				case 7:
					P2binds = [FlxG.save.data.P2leftBind, FlxG.save.data.P2rightBind];
				case 8: 
					P2binds = [FlxG.save.data.P2leftBind, FlxG.save.data.P2N4Bind, FlxG.save.data.P2rightBind];
			}
			return P2binds;
		}

	public static function complexAssKeybindSaving(maniaToChange:Int, key:String, curSelectedNote:Int, player:Int = 1) //wait shouldnt i put this in save data?? who cares lol
	{
		var binds = bindCheck(maniaToChange);
		if (player != 1)
			binds = P2bindCheck(maniaToChange);

		binds[curSelectedNote] = key;

		if (player == 1)
		{
			switch (maniaToChange) //i hate this //i fix it, am happy now
			{
				case 0: 
					FlxG.save.data.leftBind = binds[0];
					FlxG.save.data.downBind = binds[1];
					FlxG.save.data.upBind = binds[2];
					FlxG.save.data.rightBind = binds[3];
				case 1: 
					FlxG.save.data.L1Bind = binds[0];
					FlxG.save.data.U1Bind = binds[1];
					FlxG.save.data.R1Bind = binds[2];
					FlxG.save.data.L2Bind = binds[3];
					FlxG.save.data.D1Bind = binds[4];
					FlxG.save.data.R2Bind = binds[5];
				case 2: 
					FlxG.save.data.N0Bind = binds[0];
					FlxG.save.data.N1Bind = binds[1];
					FlxG.save.data.N2Bind = binds[2];
					FlxG.save.data.N3Bind = binds[3];
					FlxG.save.data.N4Bind = binds[4];
					FlxG.save.data.N5Bind = binds[5];
					FlxG.save.data.N6Bind = binds[6];
					FlxG.save.data.N7Bind = binds[7];
					FlxG.save.data.N8Bind = binds[8];
				case 3: 
					FlxG.save.data.leftBind = binds[0];
					FlxG.save.data.downBind = binds[1];
					FlxG.save.data.N4Bind = binds[2];
					FlxG.save.data.upBind = binds[3];
					FlxG.save.data.rightBind = binds[4];
				case 4: 
					FlxG.save.data.L1Bind = binds[0];
					FlxG.save.data.U1Bind = binds[1];
					FlxG.save.data.R1Bind = binds[2];
					FlxG.save.data.N4Bind = binds[3];
					FlxG.save.data.L2Bind = binds[4];
					FlxG.save.data.D1Bind = binds[5];
					FlxG.save.data.R2Bind = binds[6];
				case 5: 
					FlxG.save.data.N0Bind = binds[0];
					FlxG.save.data.N1Bind = binds[1];
					FlxG.save.data.N2Bind = binds[2];
					FlxG.save.data.N3Bind = binds[3];
					FlxG.save.data.N5Bind = binds[4];
					FlxG.save.data.N6Bind = binds[5];
					FlxG.save.data.N7Bind = binds[6];
					FlxG.save.data.N8Bind = binds[7];
				case 6: 
					FlxG.save.data.N4Bind = binds[0];
				case 7: 
					FlxG.save.data.leftBind = binds[0];
					FlxG.save.data.rightBind = binds[1];
				case 8: 
					FlxG.save.data.leftBind = binds[0];
					FlxG.save.data.N4Bind = binds[1];
					FlxG.save.data.rightBind = binds[2];
			}
		}
		else 
		{
			switch (maniaToChange) //for player 2
			{
				case 0: 
					FlxG.save.data.P2leftBind = binds[0];
					FlxG.save.data.P2downBind = binds[1];
					FlxG.save.data.P2upBind = binds[2];
					FlxG.save.data.P2rightBind = binds[3];
				case 1: 
					FlxG.save.data.P2L1Bind = binds[0];
					FlxG.save.data.P2U1Bind = binds[1];
					FlxG.save.data.P2R1Bind = binds[2];
					FlxG.save.data.P2L2Bind = binds[3];
					FlxG.save.data.P2D1Bind = binds[4];
					FlxG.save.data.P2R2Bind = binds[5];
				case 2: 
					FlxG.save.data.P2N0Bind = binds[0];
					FlxG.save.data.P2N1Bind = binds[1];
					FlxG.save.data.P2N2Bind = binds[2];
					FlxG.save.data.P2N3Bind = binds[3];
					FlxG.save.data.P2N4Bind = binds[4];
					FlxG.save.data.P2N5Bind = binds[5];
					FlxG.save.data.P2N6Bind = binds[6];
					FlxG.save.data.P2N7Bind = binds[7];
					FlxG.save.data.P2N8Bind = binds[8];
				case 3: 
					FlxG.save.data.P2leftBind = binds[0];
					FlxG.save.data.P2downBind = binds[1];
					FlxG.save.data.P2N4Bind = binds[2];
					FlxG.save.data.P2upBind = binds[3];
					FlxG.save.data.P2rightBind = binds[4];
				case 4: 
					FlxG.save.data.P2L1Bind = binds[0];
					FlxG.save.data.P2U1Bind = binds[1];
					FlxG.save.data.P2R1Bind = binds[2];
					FlxG.save.data.P2N4Bind = binds[3];
					FlxG.save.data.P2L2Bind = binds[4];
					FlxG.save.data.P2D1Bind = binds[5];
					FlxG.save.data.P2R2Bind = binds[6];
				case 5: 
					FlxG.save.data.P2N0Bind = binds[0];
					FlxG.save.data.P2N1Bind = binds[1];
					FlxG.save.data.P2N2Bind = binds[2];
					FlxG.save.data.P2N3Bind = binds[3];
					FlxG.save.data.P2N5Bind = binds[4];
					FlxG.save.data.P2N6Bind = binds[5];
					FlxG.save.data.P2N7Bind = binds[6];
					FlxG.save.data.P2N8Bind = binds[7];
				case 6: 
					FlxG.save.data.P2N4Bind = binds[0];
				case 7: 
					FlxG.save.data.P2leftBind = binds[0];
					FlxG.save.data.P2rightBind = binds[1];
				case 8: 
					FlxG.save.data.P2leftBind = binds[0];
					FlxG.save.data.P2N4Bind = binds[1];
					FlxG.save.data.P2rightBind = binds[2];
			}
		}
		
	}
	public static function numberArray(max:Int, ?min = 0):Array<Int>
	{
		var dumbArray:Array<Int> = [];
		for (i in min...max)
		{
			dumbArray.push(i);
		}
		return dumbArray;
	}
}
