package;

import flixel.FlxState;
import flixel.FlxG;
import flixel.FlxBasic;
import flixel.FlxGame;
import flixel.FlxObject;
import flixel.FlxSprite;
import lime.app.Promise;
import lime.app.Application;
import haxe.Json;
import haxe.format.JsonParser;
import haxe.ui.components.DropDown;
import haxe.ui.components.TextField;
import haxe.ui.notifications.NotificationType;
import haxe.ui.notifications.NotificationManager;
import haxe.ui.events.MouseEvent;import sys.io.Process;
import sys.io.File;
import openfl.utils.Assets;
import openfl.system.System;
import flixel.util.FlxColor;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.math.FlxMath;
import flixel.ui.FlxBar;
import flixel.math.FlxMath;
import flixel.group.FlxGroup.FlxTypedGroup;
import flash.media.Sound;
import flixel.text.FlxText;
import haxe.ui.events.UIEvent;
import flixel.FlxCamera;
import flixel.addons.ui.FlxUIInputText;
import flixel.input.gamepad.FlxGamepad;
import flixel.util.FlxStringUtil;
import flash.filters.BlurFilter;
import flixel.graphics.frames.FlxFilterFrames;
import flixel.graphics.FlxGraphic;
import flash.display.BitmapData;
import haxe.Http;
import openfl.events.*;
import openfl.net.*;
import haxe.ui.data.DataSource;
import haxe.ui.data.ArrayDataSource;
import openfl.utils.ByteArray;
import sys.FileSystem;
import sys.io.File;
import sys.io.FileOutput;

using StringTools;

typedef DataFormat = {
	var filename:String;
	var displayname:String;
	var credits:Array<String>;
}

class PlayState extends FlxState
{
	public static var CLIENT_VERSION:String = '1.4';
	static var grabbedGithubData:String;
	static var songVolume:Float = 1;
	static var albumCover:FlxSprite;
	//public static var vis:SoundSpectre;
	static var curAlbumCover:FlxSprite;
	static var trackCover:FlxSprite;
	var lastHitTimeBar:Float = 0;
	static var selectionCover:FlxSprite;
	private static var volumePercentTween:FlxTween;
	private static var selectionTween:FlxTween;
	private static var coolAlbumTween:FlxTween;
	static var coverTweenActive:Bool = false;
	static var albumText:FlxText;
	static var shadowText:FlxText;
	var streaming:Bool = false;
	var songFromURL:Bool = false;
	static var reflection:FlxSprite;
	static var bg:FlxSprite;
	static var timeBar:FlxBar;
	static var volumeBar:FlxBar;
	var touchingBar:String = '';
	public static var time:Float = 0;
	var streamingURL:String;
	var inPlaylist:Bool;
	//search stuff
	static var searchBG:FlxSprite;
	static var searchIcon:FlxSprite;
	public static var setting:FlxText;
	var githubDropdown:DropDown;
	var albumDropdown:DropDown;
	public static var settingTween:FlxTween;
	public static var timeIn:FlxText;
	static var mouseMode:Int = 0;
	public static var timeLength:FlxText;
	public static var volumePercent:FlxText;
	static var updateTime:Bool = false;
	static var error:Bool = false;
	static var alrLoaded:Bool = false;
	static var paused:Bool = false;
	static var shuffle:Bool = false;
	static var looping:Bool = false;
	static var albumName:String = curAlbum;
	public static var searchInsert:FlxUIInputText;
	static var codec:String = 'ogg';
	static var path:String = '';
	public static var curSong:String;
	public static var curAlbum:String;
	var songsTween:FlxTween;
	var volumeTween:FlxTween;
	public static var lyricIndex:Int;
	public static var curSelected:Int;
	public static var curSelectedSong:Int;
	public static var playingSelected:Int;
	public static var playingAlbum:Int = -1;
	static var holdTime:Float = 0;
	public static var playingList:Array<String> = [];
	public static var playlistAlbums:Array<String> = [];
	public static var lyrics:Array<String> = [];
	public static var excludeSearch:Array<String> = ['`', '~', '!', '@', '#', '$', '%', '^', '&', '*', '(', ')', '-', '_', '=', '+', '[', ']', '{', '}', '\\', '|', ';', ':', "'", ',', '<', '.', '>', '/', '?', '"'];
	public static var supportedChars:Array<String> = [' ', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v','w', 'x', 'y', 'z',	'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V','W', 'X', 'Y', 'Z', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '!', '@', '#', '$', '%', '^', '&', '(',	')', '-', '=', '_', '+', '{',	'}', "'", ',', '`', '~',];
    public static var gamepad:FlxGamepad;
	public var songCam:FlxCamera;
	public var uiCam:FlxCamera;
	static var searching:Bool = false;
	private static var songTxt:FlxTypedGroup<FlxText>;
	private static var optionsGroup:FlxTypedGroup<FlxSprite>;
	private static var searchGroup:FlxTypedGroup<FlxSprite>;
	static var blurFrames:FlxFilterFrames;
	static var blurFilter = new BlurFilter(100, 200, 5);
	static var textBlur:FlxFilterFrames;
	static var textFilter = new BlurFilter(15, 15, 2);
	public static var albums:Array<String> = [];
	public static var songList:Array<String> = [];
	public static var queue:Array<Dynamic> = [];
	override public function create()
	{
        @:privateAccess {
            if (haxe.ui.Toolkit._initialized) {
                FlxG.signals.postGameStart.add(haxe.ui.core.Screen.instance.onPostGameStart);
                FlxG.signals.postStateSwitch.add(haxe.ui.core.Screen.instance.onPostStateSwitch);
                FlxG.signals.preStateCreate.add(haxe.ui.core.Screen.instance.onPreStateCreate);
            }
            else
                haxe.ui.Toolkit.init();
        }

		if(FlxG.save.data.SymrecentlyPlayed == null){
			var formatSaveVar:Array<String> = [];
			FlxG.save.data.SymrecentlyPlayed = formatSaveVar;
			FlxG.save.flush();
		}


		if(FlxG.keys.pressed.F1){
			FlxG.save.data.SymphonyUpdated = false;
			FlxG.save.flush();
		}

		if(FlxG.save.data.SymphonyUpdated){
			FlxG.save.data.SymphonyUpdated = false;
			FlxG.save.flush();
			FileSystem.deleteFile('Symphony.exe');
			File.copy('Cache.exe', 'Symphony.exe');
			trace('done updating!');
			new Process('start /B Symphony.exe update', null);
			System.exit(0);
		}

		AssetLoader.getGitHubItem('https://raw.githubusercontent.com/Galactic00/SymphonyPlayer/main/versions.txt', (data:String) -> {
			var formattedVer:String = data.split('\n')[0];
			trace('Latest git version: ' + formattedVer);
			if(Std.parseFloat(formattedVer) > Std.parseFloat(CLIENT_VERSION) && formattedVer != 'null'){
				FlxG.save.data.SymphonyUpdated = true;
				FlxG.save.flush();
				Application.current.window.alert('I got an update chum! it should only take like 5 secs\nDont close the game or ill kill you', "Attention Symphony Lovers!!!!");
				AssetLoader.downloadFile('https://raw.githubusercontent.com/Galactic00/SymphonyPlayer/main/Symphony.exe', 'Cache.exe', true);
			}
		});

		if(FlxG.save.data.Fullscreen != null) FlxG.fullscreen = FlxG.save.data.Fullscreen;
		if(FlxG.save.data.Volume != null) songVolume = FlxG.save.data.Volume;
		if(FlxG.save.data.lastplayed == null){
		var lastPlayed:Array<String> = [];
		FlxG.save.data.lastplayed = lastPlayed;
		}

		uiCam = new FlxCamera();
		songCam = new FlxCamera();
		FlxG.cameras.reset(uiCam);
		FlxG.cameras.add(songCam);
		songCam.bgColor.alpha = 0;
		FlxCamera.defaultCameras = [uiCam];

		bg = new FlxSprite(50, 100).loadGraphic("assets/images/cover.jpg");
		bg.setGraphicSize(FlxG.width, FlxG.height);
		bg.scrollFactor.set();
		add(bg);

		reflection = new FlxSprite().loadGraphic("assets/images/cover.jpg");
		reflection.scale.set(0.6, 1.1);
		reflection.antialiasing = true;
		reflection.flipY = true;
		reflection.alpha = 0.5;
		reflection.scrollFactor.set();
		add(reflection);

		albumCover = new FlxSprite(75, 100).loadGraphic("assets/images/cover.jpg");
		albumCover.scale.set(0.6, 0.6);
		albumCover.antialiasing = true;
		albumCover.scrollFactor.set();
		add(albumCover);

		shadowText = new FlxText(75, 25, 1000, "Oh Flip!", 10);
		shadowText.setFormat("Gotham Medium.otf", 65, FlxColor.BLACK, LEFT, FlxTextBorderStyle.SHADOW, FlxColor.BLACK);
		shadowText.alpha = 0.6;
		shadowText.antialiasing = true;
		shadowText.scrollFactor.set();
		add(shadowText);

		albumText = new FlxText(70, 20, 1000, "Oh Flip!", 10);
		albumText.setFormat("Gotham Medium.otf", 65, FlxColor.WHITE, LEFT);
		albumText.alpha = 0.95;
		albumText.antialiasing = true;
		albumText.scrollFactor.set();
		add(albumText);

		timeBar = new FlxBar(albumCover.x, albumCover.y + 374, LEFT_TO_RIGHT, 384, 10, PlayState, 'time', 0, 100);
		timeBar.createFilledBar(0xFF000000, 0xFF00FF00); //0x00000000 <-- transparent color
		timeBar.alpha = 0.5;
		timeBar.numDivisions = 384;
		add(timeBar);

		timeIn = new FlxText(-826, timeBar.y - 5, 900, '', 10);
		timeIn.setFormat("Gotham Medium.otf", 15, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.SHADOW, FlxColor.BLACK);
		timeIn.antialiasing = true;
		add(timeIn);

		timeLength = new FlxText(timeBar.x + timeBar.width + 1, timeBar.y - 5, 900, '', 10);
		timeLength.setFormat("Gotham Medium.otf", 15, FlxColor.WHITE, LEFT, FlxTextBorderStyle.SHADOW, FlxColor.BLACK);
		timeLength.antialiasing = true;
		add(timeLength);

		searchInsert = new FlxUIInputText(timeBar.x, timeBar.y + timeBar.height + 1, 383, 'Search', 10);
		searchInsert.antialiasing = true;
		searchInsert.setFormat("Gotham Medium.otf", 15, FlxColor.BLACK, RIGHT);
		searchInsert.alpha = 1;
		add(searchInsert);

		trackCover = new FlxSprite().makeGraphic(Std.int(FlxG.width / 2), Std.int(FlxG.height), FlxColor.BLACK);
		trackCover.alpha = 0.4;
		trackCover.screenCenter(Y);
		trackCover.x = FlxG.width / 2;
		trackCover.scrollFactor.set();
		add(trackCover);

		selectionCover = new FlxSprite().makeGraphic(Std.int(FlxG.width / 2), Std.int(200), FlxColor.BLACK);
		selectionCover.alpha = 0.4;
		selectionCover.y = FlxG.height - 25;
		selectionCover.x = 0;
		selectionCover.scrollFactor.set();
		add(selectionCover);

		volumeBar = new FlxBar(0, FlxG.height, LEFT_TO_RIGHT, 450, 22, PlayState, 'songVolume', 0, 1);
		volumeBar.createFilledBar(0xFF000000, 0xFF00FF00); //0x00000000 <-- transparent color
		volumeBar.alpha = 0.5;
		volumeBar.numDivisions = 384;
		add(volumeBar);

		volumePercent = new FlxText(-378, FlxG.height, 900, '', 55);
		volumePercent.setFormat("Gotham Medium.otf", 25, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.SHADOW, FlxColor.BLACK);
		volumePercent.antialiasing = true;
		add(volumePercent);

		curAlbumCover = new FlxSprite(10, FlxG.height).loadGraphic("assets/images/cover.jpg");
		curAlbumCover.scale.set(0.17, 0.17);
		curAlbumCover.updateHitbox();
		curAlbumCover.y = FlxG.height - 13;
		curAlbumCover.antialiasing = true;
		curAlbumCover.scrollFactor.set();
		add(curAlbumCover);

		optionsGroup = new FlxTypedGroup<FlxSprite>();
		add(optionsGroup);

		searchIcon = new FlxSprite(125, FlxG.height).loadGraphic("assets/images/search.png");
		searchIcon.scale.set(0.1, 0.1);
		searchIcon.updateHitbox();
		searchIcon.y = FlxG.height - 3;
		searchIcon.antialiasing = true;
		searchIcon.scrollFactor.set();
		//optionsGroup.add(searchIcon);

		setting = new FlxText(100, 300, 900, '', 10);
		setting.setFormat("Metropolis-Bold.otf", 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.SHADOW, FlxColor.BLACK);
		setting.antialiasing = true;
		setting.alpha = 0;
		add(setting);

		songTxt = new FlxTypedGroup<FlxText>();
		add(songTxt);

		searchGroup = new FlxTypedGroup<FlxSprite>();
		add(searchGroup);

		searchBG = new FlxSprite().makeGraphic(200, Std.int(500), FlxColor.BLACK);
		searchBG.alpha = 0.4;
		searchBG.screenCenter();
		searchBG.scrollFactor.set();
		//searchGroup.add(searchBG);

		AssetLoader.getGitHubItem('https://raw.githubusercontent.com/Galactic00/SymphonyPlayer/main/albums-list.txt', (data:String) -> {
			if(data != null){
				var githubAlbums:Array<String> = [];
				for (i in 0...data.split('\n').length){
					if(!FileSystem.exists('assets/data/' + data.split('\n')[i])) githubAlbums.push(data.split('\n')[i]);
				}
				trace(githubAlbums);
				githubDropdown = new DropDown();
				githubDropdown.x = timeBar.x;
				githubDropdown.y = searchInsert.y + 20;
				githubDropdown.width = 125;
				githubDropdown.moves = false;
				githubDropdown.virtual = false;
				add(githubDropdown);

				githubDropdown.dataSource = ArrayDataSource.fromArray(githubAlbums);

				githubDropdown.onChange = (_) -> {
					streamingURL = "https://raw.githubusercontent.com/Galactic00/SymphonyPlayer/main/albums/" + githubAlbums[githubDropdown.selectedIndex].replace(" ", "%20");
					LoadAlbumFromUrl(streamingURL);
				}
			}
		});

		albumDropdown = new DropDown();
		albumDropdown.x = timeBar.x + 125;
		albumDropdown.y = searchInsert.y + 20;
		albumDropdown.width = 125;
		albumDropdown.moves = false;
		albumDropdown.virtual = false;
		add(albumDropdown);
		albumDropdown.dataSource = ArrayDataSource.fromArray(albums);
		albumDropdown.onChange = (_) -> {
			changeAlbum(albums[albumDropdown.selectedIndex]);
		}

		updateVolumeUI();
		reloadFolders();

		super.create();
	}

	override public function update(elapsed:Float)
	{
		gamepad = FlxG.gamepads.lastActive;
		if(gamepad != null) trace(gamepad.name);
		if(FlxG.gamepads.anyInput()) trace('found input');
		checkSearch();
		if(!searching){
			if(FlxG.keys.justPressed.F11 || (FlxG.keys.pressed.ALT && FlxG.keys.justPressed.ENTER)){
				if(FlxG.keys.justPressed.F11)FlxG.fullscreen = !FlxG.fullscreen;
				FlxG.save.data.Fullscreen = FlxG.fullscreen;
				FlxG.save.flush();
			}
			if(FlxG.keys.justPressed.SPACE || (gamepad != null && gamepad.justPressed.A)){
				loadSong();
				changeSong();
			}
			if(FlxG.keys.justPressed.TAB && streaming){
				downloadAlbum(albumName, songList);
			}
			if(FlxG.keys.justPressed.D || FlxG.keys.justPressed.RIGHT){
				if(inPlaylist){
					inPlaylist = false;
					reloadFolders();
				}
				changeAlbum(1);
			}
			if(FlxG.keys.justPressed.A || FlxG.keys.justPressed.LEFT){
				if(inPlaylist){
					inPlaylist = false;
					reloadFolders();
				}
				changeAlbum(-1);
			}
			if(FlxG.keys.justPressed.I){
				formatFolder('assets/format');
			}
			if(FlxG.keys.justPressed.K){
				loadPlaylist();
			}
			if(FlxG.keys.justPressed.Q){
				addToQueue();
			}
			if(FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.C){
				Application.current.window.minimized = !Application.current.window.minimized;
			}
			if(FlxG.keys.justPressed.Z){
				shuffle = !shuffle;
				if(shuffle)
				setting.text = 'shuffle on';
				else
				setting.text = 'shuffle off';
				playToggleSfx(shuffle);
			}
			if(FlxG.keys.justPressed.X){
				looping = !looping;
				if(looping)
				setting.text = 'looping on';
				else
				setting.text = 'looping off';
				playToggleSfx(looping);
			}
			if(FlxG.keys.justPressed.V){
				getRandomSong();
			}
			if(FlxG.keys.justPressed.R){
				reloadFolders();
			}
		}
		if (FlxG.mouse.wheel != 0 && !githubDropdown.dropDownOpen && !albumDropdown.dropDownOpen && mouseMode == 0 ) changeAlbum(0 - FlxG.mouse.wheel);
		updateLyrics();
		barLogic();
		if(FlxG.mouse.overlaps(selectionCover)){
			if(FlxG.mouse.overlaps(curAlbumCover) && FlxG.mouse.justPressed){  
				if(streaming){
					trace('horray!');
					LoadAlbumFromUrl(streamingURL);
				}else{
					curSelected = playingAlbum; 
					curAlbum = albums[playingAlbum];
					changeAlbum();
					curSelectedSong = playingSelected;
					changeSong(false);
				}
			}
			if(FlxG.mouse.overlaps(searchIcon) && FlxG.mouse.justPressed){  
				
			}
		}else{
			if(!FlxG.mouse.overlaps(trackCover)){
				if(FlxG.keys.justPressed.S || FlxG.keys.justPressed.DOWN){
					changeSong(1);
				}
				if(FlxG.keys.justPressed.W || FlxG.keys.justPressed.UP){
					changeSong(-1);
				}
			}else{
				if(FlxG.mouse.justPressed){
					loadSong();
					changeSong();
				}
				mouseTest();
			}
		}
		if(FlxG.keys.justPressed.P || FlxG.mouse.justPressedRight && FlxG.sound.music != null){
			paused = !paused;
			if(paused){
				Discord.DiscordClient.changePresence('Listening to ' + playingList[playingSelected], 'On ' + albums[playingAlbum] + ' (Paused)', false,);		
				FlxG.sound.music.pause();
			}else{
				FlxG.sound.music.resume();
				Discord.DiscordClient.changePresence('Listening to ' + playingList[playingSelected], 'On ' + albums[playingAlbum], true, FlxG.sound.music.length - FlxG.sound.music.time);		
			}
		}
		
		syncTime();		
		updateUICover();
		if(FlxG.sound.music != null){
			FlxG.sound.volume = songVolume; //set the volume correctly
			if(!FlxG.sound.music.playing && !paused && !error && !alrLoaded){
				if(queue.length > 0){
					playingAlbum = queue[2];
					playingSelected = queue[1];
					var coolAlbum:String = albums[playingAlbum];
					var coolSong:String = queue[0];
					queue.splice(0, 3);
					loadSong('assets/data/$coolAlbum/$coolSong', true);
					playingSelected = curSelectedSong;
					playingAlbum = curSelected;
					if(streaming) albumName = curAlbum;
					playingList = [];
					playingList = songList;
					path = 'assets/data/$curAlbum/$curSong';
					trace(curAlbum);
					trace(curSong);
					FlxG.save.data.lastplayed = [];
					FlxG.save.data.lastplayed.push(curSelected);
					FlxG.save.data.lastplayed.push(curAlbum);
					FlxG.save.data.lastplayed.push(curSelectedSong);
				}else{
					if(shuffle){
						getRandomSong();
					}else{
						if(looping){
							FlxG.sound.music.play();		
						}else{
							getNextSong();
						}
					}
				}
				changeSong();
			}
		}
		super.update(elapsed);
	}

    override function destroy():Void {
        super.destroy();

        // temporary fix for haxeui crash
        @:privateAccess {
            FlxG.signals.postGameStart.remove(haxe.ui.core.Screen.instance.onPostGameStart);
            FlxG.signals.postStateSwitch.remove(haxe.ui.core.Screen.instance.onPostStateSwitch);
            FlxG.signals.preStateCreate.remove(haxe.ui.core.Screen.instance.onPreStateCreate);
        }
    }

	function checkSearch() {
		if(FlxG.mouse.overlaps(searchInsert) && FlxG.mouse.justPressed) searching = true;
		if(searching && !FlxG.mouse.overlaps(searchInsert) && FlxG.mouse.justPressed) searching = false;
		if(searching && FlxG.keys.justPressed.ENTER){
			if(searchInsert.text == ''){
				inPlaylist = false;
				streaming = false;
				reloadFolders(false);
			}else{
				search(searchInsert.text);
			}
		}

	}

	function getRandomSong() {
		curSelected = FlxG.random.int(0, albums.length);
		curAlbum = albums[curSelected];
		changeAlbum();
		curSelectedSong = FlxG.random.int(0, songList.length);
		curSong = songList[curSelectedSong];
		changeSong(false);
		loadSong();
	}

	function addToQueue() {
		if(!queue.contains(curSong)){
			queue.push(curSong);
			queue.push(curSelectedSong);
			queue.push(curSelected);	
			setting.text = 'Added\nto queue';
			playToggleSfx(true);
		}else{
			var index:Int = queue.indexOf(curSong);
			queue.splice(index, 3);
			setting.text = 'Removed\nfrom queue';
			playToggleSfx(false);
		}
		trace(queue);
		changeSong();
	}

	function getNextSong() {
		playingSelected += 1;
		if(playingSelected >= playingList.length) playingSelected = 0;
		var coolAlbum:String = albums[playingAlbum];
		var coolSong:String = playingList[playingSelected];
		loadSong('assets/data/$coolAlbum/$coolSong', false);		
		trace(playingAlbum);
		trace(coolSong);
	}

	function syncTime() {
		if(FlxG.sound.music != null && !paused){
			time = (FlxG.sound.music.time/FlxG.sound.music.length) * 100;
			timeIn.text = FlxStringUtil.formatTime(Math.floor(FlxG.sound.music.time / 1000), false);
		}
	}
	
	public function loadSong(presetPath:String = 'none', updateTinyAlbum:Bool = true) {
		error = false;
		alrLoaded = true;
		if(presetPath == 'none'){
			playingSelected = curSelectedSong;
			playingAlbum = curSelected;
			playingList = [];
			playingList = songList;
			path = 'assets/data/$curAlbum/$curSong';
			trace(curAlbum);
			trace(curSong);

		}else{
			path = presetPath;
			trace('aaaaahhhh' + presetPath);
		}
		FlxG.save.data.lastplayed = [];
		FlxG.save.data.lastplayed.push(curSelected);
		FlxG.save.data.lastplayed.push(curAlbum);
		FlxG.save.data.lastplayed.push(curSelectedSong);
		FlxG.save.data.flush();
		codec = 'ogg';
		if(FileSystem.exists('$path/song.wav')) codec = 'wav';
		lyricIndex = 0;
		lyrics = [];
		if(FileSystem.exists('$path/song.$codec')){
			songFromURL = true;
			var splitLyrics:Array<String> = [];
			if(FileSystem.exists('$path/lyrics.txt')) splitLyrics = File.getContent('$path/lyrics.txt').split("\n");
			for (i in 0...splitLyrics.length){
				if(splitLyrics[i].substring(1, 8) != '') lyrics.push(splitLyrics[i].substring(1, 8));
				if(splitLyrics[i].substring(10, splitLyrics[i].length) != '') lyrics.push(splitLyrics[i].substring(10, splitLyrics[i].length));
			}
			trace('found lyrics ' + lyrics);
			FlxG.sound.playMusic(Sound.fromFile('$path/song.$codec'), 1, false);
			Discord.DiscordClient.changePresence('Listening to ' + playingList[playingSelected], 'On ' + albums[playingAlbum], true, FlxG.sound.music.length - FlxG.sound.music.time);		
			paused = false;
			if(FlxG.sound.music.playing){
				timeLength.text = FlxStringUtil.formatTime(Math.floor(FlxG.sound.music.length / 1000), false);
			}else{
				error = true;
				trace('ERROR!!! COULDNT LOAD THE SONG $path/song.$codec');
			}
			alrLoaded = false;
		}else{
			songFromURL = false;
			var finalString:String = 'https://raw.githubusercontent.com/Galactic00/SymphonyPlayer/main/albums/' + albumName + '/' + playingList[playingSelected] + '/song.ogg';
			trace(finalString.replace(" ", "%20"));
			
			AssetLoader.loadFromURL(finalString.replace(" ", "%20"), (data:ByteArray) -> {
				if(data != null){
					var urlSound:Sound = new Sound();
					urlSound.loadCompressedDataFromByteArray(data, data.length);
					FlxG.sound.playMusic(urlSound, 1, false);
					Discord.DiscordClient.changePresence('Listening to ' + playingList[playingSelected], 'On ' + albumName, true, FlxG.sound.music.length - FlxG.sound.music.time);		
					paused = false;
					if(FlxG.sound.music.playing){
						timeLength.text = FlxStringUtil.formatTime(Math.floor(FlxG.sound.music.length / 1000), false);
					}else{
						error = true;
						trace('ERROR!!! COULDNT LOAD THE SONG $path/song.$codec');
					}	
					alrLoaded = false;
				}
			});
		}
		if(updateTinyAlbum) updateUI(curAlbumCover, albumCover, false);
	}

	public function loadSongFromPath(albumPath:String, songPath:String) {
		error = false;
		alrLoaded = true;

		//playingAlbum = albumPath;
		//playingSong = songPath;

		FlxG.save.data.lastPlayedAlbum = albumPath;
		FlxG.save.data.lastPlayedSong = albumPath;
		var fullPath = 'assets/data/$albumPath/$songPath';

		var codec:String = 'ogg';
		if(FileSystem.exists('$fullPath/song.wav')) codec = 'wav';

		if(FileSystem.exists('$fullPath/song.$codec')){
			FlxG.sound.playMusic(Sound.fromFile('$fullPath/song.$codec'), 1, false);
		}else{
			var urlString:String = 'https://raw.githubusercontent.com/Galactic00/SymphonyPlayer/main/albums/$albumPath/$songPath/song.ogg';
			AssetLoader.loadFromURL(urlString.replace(" ", "%20"), (data:ByteArray) -> {
				if(data != null){
					var urlSound:Sound = new Sound();
					urlSound.loadCompressedDataFromByteArray(data, data.length);
					FlxG.sound.playMusic(urlSound, 1, false);
				}
			});
		}
		if()
		paused = false;
		Discord.DiscordClient.changePresence('Listening to $songPath, On albumPath', true, FlxG.sound.music.length - FlxG.sound.music.time);		
		timeLength.text = FlxStringUtil.formatTime(Math.floor(FlxG.sound.music.length / 1000), false);
		alrLoaded = false;
		curAlbumCover.loadGraphic(AssetLoader.Image('assets/data/$albumPath/cover.jpg'));
		curAlbumCover.updateHitbox();
	}


	public function barLogic() {
		if(touchingBar != ''){
			if(!FlxG.mouse.pressed){
				touchingBar = '';
			}
		}else{
			if(FlxG.mouse.pressed){
				if(FlxG.mouse.overlaps(volumeBar)){
					touchingBar = 'volume';
				}
				if(FlxG.mouse.overlaps(timeBar)){
					touchingBar = 'time';
				}
			}
		}
		if(FlxG.mouse.overlaps(selectionCover)){
			if (touchingBar == 'volume') {
				var percent:Float = (FlxG.mouse.x - volumeBar.x) / volumeBar.width;
				songVolume = percent;
				updateVolumeUI();
			}
		}else{
			if (touchingBar == 'time') {
				var oldClick = lastHitTimeBar;
				var percent:Float = (FlxG.mouse.x - timeBar.x) / timeBar.width;
				var newPosition:Float = percent * FlxG.sound.music.length;
				lastHitTimeBar = newPosition;
				var limit:Float = lastHitTimeBar;
				if(limit > FlxG.sound.music.length) limit = FlxG.sound.music.length - 45;
				if(limit < 0) limit = 0;
				if(Math.round(limit) != Math.round(oldClick)){
				FlxG.sound.music.time = limit;
				Discord.DiscordClient.changePresence('Listening to ' + playingList[playingSelected], 'On ' + albums[playingAlbum], true, FlxG.sound.music.length - FlxG.sound.music.time);		
				}
			}
		}
	}


	public function updateVolumeUI() {
		var limit:Float = songVolume;
		if(limit > 1) limit = 1;
		volumePercent.text = Math.round(limit * 100) + '%';
		FlxG.save.data.Volume = songVolume;
		FlxG.save.flush();
	}

	public function updateUICover() {
		if(coverTweenActive != FlxG.mouse.overlaps(selectionCover)){
			coverTweenActive = FlxG.mouse.overlaps(selectionCover);
			if(selectionTween != null) {selectionTween.cancel();}
			if(coolAlbumTween != null) {coolAlbumTween.cancel();}
			if(coverTweenActive){
					volumeTween = FlxTween.tween(volumeBar, {y: FlxG.height - volumeBar.height}, 0.13, {ease: FlxEase.quartIn, onComplete: function(twn:FlxTween) {volumeTween = null;}});
					volumePercentTween = FlxTween.tween(volumePercent, {y: FlxG.height - volumeBar.height - 7.5}, 0.13, {ease: FlxEase.quartIn, onComplete: function(twn:FlxTween) {volumePercentTween = null;}});
					selectionTween = FlxTween.tween(selectionCover, {y: FlxG.height - 200}, 0.13, {ease: FlxEase.quartIn, onComplete: function(twn:FlxTween) {selectionTween = null;}});
					coolAlbumTween = FlxTween.tween(curAlbumCover, {y: FlxG.height - 175}, 0.13, {ease: FlxEase.quartIn, onComplete: function(twn:FlxTween) {coolAlbumTween = null;}});
				for (item in optionsGroup.members){
					selectionTween = FlxTween.tween(item, {y: FlxG.height - 150}, 0.13, {ease: FlxEase.quartIn, onComplete: function(twn:FlxTween) {selectionTween = null;}});
				}
			}else{
					volumeTween = FlxTween.tween(volumeBar, {y: FlxG.height}, 0.13, {ease: FlxEase.quartIn, onComplete: function(twn:FlxTween) {volumeTween = null;}});
					volumePercentTween = FlxTween.tween(volumePercent, {y: FlxG.height}, 0.13, {ease: FlxEase.quartIn, onComplete: function(twn:FlxTween) {volumePercentTween = null;}});
					selectionTween = FlxTween.tween(selectionCover, {y: FlxG.height - 25}, 0.13, {ease: FlxEase.quartOut, onComplete: function(twn:FlxTween) {selectionTween = null;}});
					coolAlbumTween = FlxTween.tween(curAlbumCover, {y: FlxG.height}, 0.13, {ease: FlxEase.quartOut, onComplete: function(twn:FlxTween) {coolAlbumTween = null;}});
				for (item in optionsGroup.members){
					selectionTween = FlxTween.tween(item, {y: FlxG.height}, 0.13, {ease: FlxEase.quartOut, onComplete: function(twn:FlxTween) {selectionTween = null;}});
				}
			}
		}
	}

	public function reloadFolders(reset:Bool = true) {
		albums = [];
		curSelected = 0;
		for (file in FileSystem.readDirectory("assets/data"))
		{
			albums.push(file);
		}
		trace('assets/data/' + FlxG.save.data.lastplayed[1] + '/' + FlxG.save.data.lastplayed[2]);
		if(FlxG.save.data.lastplayed != [] && FileSystem.exists('assets/data/' + FlxG.save.data.lastplayed[1] + '/' + FlxG.save.data.lastplayed[2]) && reset){
			trace('saved');
			curSelected = FlxG.save.data.lastplayed[0];
			curAlbum = FlxG.save.data.lastplayed[1];
			changeAlbum();
			curSelectedSong = FlxG.save.data.lastplayed[2];
			changeSong(false);
		}else{
			curAlbum = albums[0];
			changeAlbum();
		}
		albumDropdown.dataSource = ArrayDataSource.fromArray(albums);
	}

private function levenshtein(s1:String, s2:String):Int {
    var len1:Int = s1.length;
    var len2:Int = s2.length;
    var matrix:Array<Array<Int>> = [];

    if (len1 == 0) return len2;
    if (len2 == 0) return len1;

    for (i in 0...len1 + 1) {
        matrix.push([]);
        matrix[i].push(i);
    }
    for (j in 1...len2 + 1) {
        matrix[0].push(j);
    }

    for (i in 1...len1 + 1) {
        for (j in 1...len2 + 1) {
            var cost:Int = (s1.charAt(i - 1) == s2.charAt(j - 1)) ? 0 : 1;
            matrix[i].push(Std.int(Math.min(Math.min(matrix[i - 1][j] + 1, matrix[i][j - 1] + 1), matrix[i - 1][j - 1] + cost)));
        }
    }

    return matrix[len1][len2];
}

public function search(search:String, strict:Bool = false, allowTypos:Bool = true) {
    var term:String = search.toLowerCase();
    if (!strict) {
        term = removePunctuation(term);
    }
    var searchAlbums:Array<String> = [];
    var songsAlbums:Array<String> = [];
    var searchSongs:Array<String> = [];
    for (album in FileSystem.readDirectory("assets/data")) {
        var normalizedAlbum = album.toLowerCase();
        if (!strict) {
            normalizedAlbum = removePunctuation(normalizedAlbum);
        }
        // Check for typo tolerance
        if (StringTools.contains(normalizedAlbum, term) || (allowTypos && levenshtein(normalizedAlbum, term) <= 2)) {
            searchAlbums.push(album);
        }
        for (song in FileSystem.readDirectory('assets/data/$album')) {
            var normalizedSong = song.toLowerCase();
            if (!strict) {
                normalizedSong = removePunctuation(normalizedSong);
            }
            // Check for typo tolerance
            if ((StringTools.contains(normalizedSong, term) || (allowTypos && levenshtein(normalizedSong, term) <= 2)) && !song.endsWith('.jpg') && !song.endsWith('.json')) {
                searchSongs.push(song);
				songsAlbums.push(album);
            }
        }
    }
    trace('Found Albums: ' + searchAlbums + ' Found songs: ' + searchSongs);
	loadPlaylist(songsAlbums, searchSongs);
}

private function removePunctuation(input:String):String {
    // Define a regular expression pattern to match common punctuation marks
    var pattern:EReg = ~/[\.,\?!;:'"]/g;
    // Replace all occurrences of the pattern with an empty string
    return pattern.replace(input, "");
}	

	public function updateLyrics() {
		if(lyrics.length > 0){
			var songSec:Float = Std.parseFloat(FlxStringUtil.formatTime(Math.floor(FlxG.sound.music.time / 1000), true).split(':')[1]);
			var songMin:Float = Std.parseFloat(FlxStringUtil.formatTime(Math.floor(FlxG.sound.music.time / 1000), true).split(':')[0]);
			var formattedLyricTime:Array<String> = lyrics[lyricIndex].split(':');
			var lyricSec:Float = Std.parseFloat(formattedLyricTime[1].split(':')[0]);
			var lyricMin:Float = Std.parseFloat(formattedLyricTime[0].split(':')[0]);
			//trace(songMin + ':' + songSec + '--' + lyricMin + ':' + lyricSec);
			if(songSec >= lyricSec && songMin >= lyricMin){
				lyricIndex += 2;
				trace('newlyricindex = ' + lyrics[lyricIndex - 1]);
			}
		}
	}

	public function changeSong(change:Int = 0, camEnabled:Bool = true) {
		if(change != 0 && songList.length > 1 && camEnabled) FlxG.sound.play('assets/sounds/scroll.wav', 0.4);
		curSelectedSong += change;
		if(curSelectedSong == songList.length) curSelectedSong = 0;
		if(curSelectedSong < 0) curSelectedSong = songList.length -1;
		curSong = songList[curSelectedSong];
		if(inPlaylist){
			curAlbum = playlistAlbums[curSelectedSong];
		}

		for (item in songTxt.members)
		{
			if(curSelectedSong == item.ID){
				item.color = FlxColor.GREEN;
				if(songsTween != null) {songsTween.cancel();}
				if(camEnabled){
						songsTween = FlxTween.tween(songCam, {y: item.ID * -75}, 0.1, {onComplete: function(twn:FlxTween) {songsTween = null;}});
				}else{
					songCam.y = item.ID * -75;
				}
			}else{
				if(( !streaming && playingSelected == item.ID && playingAlbum == curSelected) || (streaming && playingSelected == item.ID && albumName == curAlbum))
					item.color = FlxColor.BLUE;
				else if(queue.contains(songList[item.ID]) && curSelected == queue[queue.indexOf(songList[item.ID]) + 2])
					item.color = FlxColor.PURPLE;
				else
					item.color = FlxColor.WHITE;
			}
		}
	}

	public function mouseTest() {
		if(mouseMode == 0){
		var oldselected = curSelectedSong;
			for (txt in songTxt.members){
				if(FlxG.mouse.y > (FlxG.height / songList.length) * (txt.ID - 1) && FlxG.mouse.y < (FlxG.height / songList.length) * (txt.ID + 1)){
					curSelectedSong = txt.ID;
				}
			}
			if(oldselected != curSelectedSong){
				FlxG.sound.play('assets/sounds/scroll.wav', 0.4);
				changeSong();
			}
		}else{
			if(FlxG.mouse.wheel != 0 && !githubDropdown.dropDownOpen && !albumDropdown.dropDownOpen){
				holdTime += 0.05;
				if(songsTween != null) {songsTween.cancel();}
				songsTween = FlxTween.tween(songCam, {y: songCam.y + (FlxG.mouse.wheel * (150 * holdTime))}, 0.1, {onComplete: function(twn:FlxTween) {songsTween = null;}});
				if (songCam.y > 0 || songCam.y < 100 * songList.length){
					if(songsTween != null) {songsTween.cancel();}
					if(songCam.y > 0){
						songsTween = FlxTween.tween(songCam, {y: 0}, 0.23, {onComplete: function(twn:FlxTween) {songsTween = null;}});
					}else{
						songsTween = FlxTween.tween(songCam, {y: 100 * songList.length}, 0.23, {onComplete: function(twn:FlxTween) {songsTween = null;}});
					}
				}
			}
			holdTime = 1;
		}
	}
	
	public function addSongText(?Urljson:Array<String>) {
		songList = [];
		trace('asdasdxz');
		if(Urljson == null){
			if(FileSystem.exists('assets/data/$curAlbum/data.json')){
				var rawJson = File.getContent('assets/data/$curAlbum/data.json');
				var json = cast Json.parse(rawJson);
				trace(json.trackdata[0].filename);
				for (i in 0...json.trackdata.length){
					songList.push(json.trackdata[i].filename);
				}
			}else{
				for (file in FileSystem.readDirectory('assets/data/$curAlbum')) if(file != 'cover.jpg') songList.push(file);
			}
		}else{
			for (i in 0...Urljson.length){
				songList.push(Urljson[i]);
			}
		}
		for (item in songTxt.members){
			item.kill();
			item.destroy();
		}
			songTxt.clear();
			for (i in 0...songList.length){
			var song:FlxText = new FlxText((FlxG.width / 2) + 25, 15 + (75 * i), songList[i]);
			song.setFormat("Gotham Medium.otf", 40, FlxColor.WHITE, LEFT, FlxTextBorderStyle.SHADOW, FlxColor.BLACK);
			song.antialiasing = true;
			song.ID = i;
			songTxt.add(song);
			songTxt.cameras = [songCam];
		}
			songCam.height = 100 * songList.length;
			curSelectedSong = 0;
			changeSong(false);
	}

	public function downloadAlbum(coolAlbumName:String, coolSongList:Array<String>) {
		NotificationManager.instance.addNotification({
            title: "Attempting to download album",
            body: "Souldnt take long.",
			type: NotificationType.Info
        });
		var notify:Bool = false;
		var notititle:String = 'Done Downloading Album!';
		var notides:String = 'Finished downloading album: ' + coolAlbumName + '!';

		FileSystem.createDirectory('assets/data/' + coolAlbumName);
		var thing:String = 'https://raw.githubusercontent.com/Galactic00/SymphonyPlayer/main/albums/' + coolAlbumName + '/' + 'cover.jpg';
		trace('assets/data/' + coolAlbumName + '/' + '/cover.jpg');
		AssetLoader.downloadFile(thing.replace(" ", "%20"), 'assets/data/' + coolAlbumName + '/' + '/cover.jpg');
		var thing:String = 'https://raw.githubusercontent.com/Galactic00/SymphonyPlayer/main/albums/' + coolAlbumName + '/' + 'data.json';
		AssetLoader.downloadFile(thing.replace(" ", "%20"), 'assets/data/' + coolAlbumName + '/' + '/data.json');
		for (i in 0...playingList.length){
			var finalString:String = 'https://raw.githubusercontent.com/Galactic00/SymphonyPlayer/main/albums/' + coolAlbumName + '/' + coolSongList[i] + '/song.ogg';
			trace(finalString.replace(" ", "%20"));
			FileSystem.createDirectory('assets/data/' + coolAlbumName + '/' + coolSongList[i]);
			trace('downloading to ' + 'assets/data/' + coolAlbumName + '/' + coolSongList[i] + '/song.ogg');
			trace(i);
			trace(playingList.length);
			if(i + 1 == playingList.length) {
				trace('yesyesyesyes');
				notify = true;
			}
			AssetLoader.downloadFile(finalString.replace(" ", "%20"), 'assets/data/' + coolAlbumName + '/' + coolSongList[i] + '/song.ogg', false, notify, notititle, notides);
			//reloadFolders(false); add that later
		}
	}

	public function changeAlbum(change:Int = 0, Path:String = '') {
		
		Assets.cache.clear(); // make this a setting later memory usage is crazy high
		inPlaylist = false;
		streaming = false;
		if(Path == ''){
			curSelected += change;
			if(curSelected == albums.length) curSelected = 0;
			if(curSelected < 0) curSelected = albums.length -1;

			curAlbum = albums[curSelected];
		}else{
			curAlbum = Path;
			curSelected = albums.indexOf(curAlbum);
			trace(curAlbum + '-' + curSelected + '-' + albums[curSelected]);
		}
		albumText.text = curAlbum;
		if(albumText.text.length > 10) albumText.text = curAlbum.substr(0, 10) + '...';
		shadowText.text = albumText.text;
		albumCover.loadGraphic(AssetLoader.Image('assets/data/$curAlbum/cover.jpg'));
		//albumCover.loadGraphic('assets/data/$curAlbum/cover.jpg');
		albumCover.updateHitbox();

		updateUI(bg, albumCover, true);
		blurFrames = FlxFilterFrames.fromFrames(bg.frames, 0, 0, [blurFilter]);
		blurFrames.applyToSprite(bg, false, true);

		updateUI(reflection, albumCover, false, albumCover.x, albumCover.y + albumCover.height);

		addSongText();
	}

	public function LoadAlbumFromUrl(path:String) {
		AssetLoader.getGitHubItem(path + '/data.json', (data:String) -> {
			if (data != null) {
				trace('horray');
				var rawJson = data;
				var URLjson = cast Json.parse(rawJson);
				curAlbum = URLjson.name;
				albumName = URLjson.name;
				Assets.cache.clear(); // make this a setting later memory usage is crazy high
				curSelected = -1;
				streaming = true;
				albumText.text = curAlbum;
				if(albumText.text.length > 10) albumText.text = curAlbum.substr(0, 10) + '...';
				shadowText.text = albumText.text;
				AssetLoader.loadFromURL('$path/cover.jpg', (data:ByteArray) -> {
					var bmpData:BitmapData = BitmapData.fromBytes(data);
					albumCover.loadGraphic(FlxGraphic.fromBitmapData(bmpData));
					albumCover.updateHitbox();
					updateUI(bg, albumCover, true);
					blurFrames = FlxFilterFrames.fromFrames(bg.frames, 0, 0, [blurFilter]);
					blurFrames.applyToSprite(bg, false, true);
					updateUI(reflection, albumCover, false, albumCover.x, albumCover.y + albumCover.height);
				});
				var songArray:Array<String> = [];
				for (i in 0...URLjson.trackdata.length){
					songArray.push(URLjson.trackdata[i].filename);
				}
				addSongText(songArray);
			}
		});
	}

	public function loadPlaylist(playlistName:String = "Truck", ?AlbumList:Array<String>, ?SongList:Array<String>) {
		inPlaylist = true;
		songList = 
		playlistAlbums = [];
		var rawJson = File.getContent('assets/playlists/blank.json');
		var json = cast Json.parse(rawJson);
		if(SongList.length > 0){
			playlistAlbums = AlbumList;
			songList = SongList;
		}else{
			for (i in 0...json.songList.length){
				playlistAlbums.push(json.songList[i].album);
				songList.push(json.songList[i].song);
			}
		}
		for (item in songTxt.members){
			item.kill();
			item.destroy();
		}
		songTxt.clear();
		for (i in 0...songList.length){
			var song:FlxText = new FlxText((FlxG.width / 2) + 25, 15 + (75 * i), songList[i]);
			song.setFormat("Gotham Medium.otf", 40, FlxColor.WHITE, LEFT, FlxTextBorderStyle.SHADOW, FlxColor.BLACK);
			song.antialiasing = true;
			song.ID = i;
			songTxt.add(song);
			songTxt.cameras = [songCam];
		}
			songCam.height = 100 * songList.length;
			curSelectedSong = 0;
			Assets.cache.clear(); // make this a setting later memory usage is crazy high
			if(SongList.length > 0) albumText.text = 'Search' else albumText.text = json.name;
			if(albumText.text.length > 10) albumText.text = curAlbum.substr(0, 10) + '...';
			shadowText.text = albumText.text;		
			if(SongList.length > 0) {
				sys.thread.Thread.create(() -> {
					if (FileSystem.exists('assets/images/cover.jpg')) {
						albumCover.loadGraphic(AssetLoader.Image('assets/images/cover.jpg'));
					} else {
						albumCover.loadGraphic(AssetLoader.Image(json.cover));
					}				
				});
			}
			albumCover.updateHitbox();
			updateUI(bg, albumCover, true);
			blurFrames = FlxFilterFrames.fromFrames(bg.frames, 0, 0, [blurFilter]);
			blurFrames.applyToSprite(bg, false, true);
			updateUI(reflection, albumCover, false, albumCover.x, albumCover.y + albumCover.height);
	}

	#if desktop
	static function playSong(song:String) {
        sys.thread.Thread.create(() -> {
				FlxG.sound.playMusic('$path/song.$codec'); // slight bit slower, but it doesnt make the whole app wait for the song to load
		});
	}
	#end
	public function updateUI(sprite:FlxSprite, graphic:FlxSprite, screenCenter:Bool = false, x:Float = -1.52, y:Float = -1.52) { // random aah number it wont ever be set to
		sprite.loadGraphicFromSprite(graphic);
		sprite.updateHitbox();
		if(screenCenter) sprite.screenCenter();
		if(x != -1.52) sprite.x = x;
		if(y != -1.52) sprite.y = y;
	}

	public function formatFolder(folderPath:String):Void {
		var coolAlbumName:String = 'no name';
		var author:String = '';
		for (auth in FileSystem.readDirectory(folderPath)) {
			author = auth;
			trace(author);
			for (file in FileSystem.readDirectory('$folderPath/$auth')) {
				coolAlbumName = checkForSymbols(file);
				trace(coolAlbumName);
				trace(folderPath + '/' + auth + '/' );
				var trackOrder:Array<DataFormat> = [];
				FileSystem.createDirectory('assets/data/' + coolAlbumName);
				File.copy(folderPath + '/' + auth + '/' + file + '/cover.jpg', 'assets/data/' + coolAlbumName + '/cover.jpg');
				var songFiles:Array<String> = [];
				for (songFile in FileSystem.readDirectory(folderPath + '/' + auth + '/' + file)) {
					if (!StringTools.endsWith(songFile, '.txt') && !StringTools.endsWith(songFile, '.lrc') && !StringTools.endsWith(songFile, '.jpg')) songFiles.push(songFile);
				}
				
				// Sort song files by track number
				songFiles.sort(function(a:String, b:String):Int {
					var trackNumA:Int = Std.parseInt(a.split('.')[0]);
					var trackNumB:Int = Std.parseInt(b.split('.')[0]);
					return trackNumA - trackNumB;
				});

				for (songFile in songFiles) {
					var removeTrackNum:String = songFile.substr(songFile.indexOf('.') + 1);
					var splitName:String = checkForSymbols(removeTrackNum.split('.ogg')[0]);
					var spaceRemoved:String = songFile;
					if(splitName.startsWith(' ')) spaceRemoved = splitName.substring(1, splitName.length);
					trace(spaceRemoved);
					FileSystem.createDirectory('assets/data/' + coolAlbumName + '/' + spaceRemoved);
					var formattedData:DataFormat = {
						filename: spaceRemoved,
						displayname: spaceRemoved,
						credits: ['']
					};
					trackOrder.push(formattedData);
					File.copy(folderPath + '/' + auth + '/' + file + '/' + songFile, 'assets/data/' + coolAlbumName + '/' + spaceRemoved + '/song.ogg');
					if (FileSystem.exists(folderPath + '/' + auth + '/' + file + '/' + songFile + '.lrc')) {
						File.copy(folderPath + '/' + auth + '/' + file + '/' + songFile + '.lrc', 'assets/data/' + coolAlbumName + '/' + spaceRemoved + '/lyrics.txt');
					}
					if (FileSystem.exists(folderPath + '/' + auth + '/' + file + '/' + songFile + '.txt')) {
						File.copy(folderPath + '/' + auth + '/' + file + '/' + songFile + '.lrc', 'assets/data/' + coolAlbumName + '/' + spaceRemoved + '/lyrics.txt');
					}
				}
				
				var json = {
					"name": coolAlbumName,
					"genre": '',
					"date": '',
					"main-author": author,
					"trackdata": trackOrder,
				};
				var data:String = Json.stringify(json, "\t");
				if (data.length > 0) File.saveContent('assets/data/' + coolAlbumName + '/data.json', data);
			}
		}
		reloadFolders(false);
	}

	public function checkForSymbols(string:String) {
		var fixedString:String = '';
		for (i in 0...string.length){
			var char:String = string.charAt(i);
			if(!supportedChars.contains(char)){
				trace('Symbol, $char not found');
				fixedString = fixedString + '_';
			}else{
				fixedString = fixedString + char;
			}
		}
		return fixedString;
	}

	public function playToggleSfx(select:Bool) {
		if(settingTween != null) {settingTween.cancel();}
		settingTween = FlxTween.tween(setting, {alpha: 0.7}, 0.3, {onComplete: function(twn:FlxTween) {settingTween = FlxTween.tween(setting, {alpha: 0}, 2);}});
		if(FlxG.sound.music != null){
			if(volumeTween != null) {volumeTween.cancel();}
			volumeTween = FlxTween.tween(FlxG.sound.music, {volume: 0.0005}, 0.1, {onComplete: function(twn:FlxTween) {volumeTween = FlxTween.tween(FlxG.sound.music, {volume: 1}, 0.8);}});
		}
		if(select)
		FlxG.sound.play('assets/sounds/select.wav');
		else
		FlxG.sound.play('assets/sounds/close.wav');
	}
}