package;

import flixel.FlxState;
import flixel.FlxG;
import flixel.FlxSprite;
import haxe.Json;
import haxe.format.JsonParser;
import sys.io.Process;
import sys.io.File;
import openfl.utils.Assets;
import openfl.system.System;
import flixel.util.FlxColor;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.math.FlxMath;
import flixel.group.FlxGroup.FlxTypedGroup;
import flash.media.Sound;
import flixel.text.FlxText;
import flixel.FlxCamera;
import flixel.util.FlxStringUtil;
import flash.filters.BlurFilter;
import flixel.graphics.frames.FlxFilterFrames;
import flixel.graphics.FlxGraphic;
import flash.display.BitmapData;
import haxe.Http;
import openfl.events.*;
import openfl.net.*;
import openfl.utils.ByteArray;
import sys.FileSystem;
import sys.io.FileOutput;
import FlxVideoSprite;
import flixel.sound.FlxSound;
import lime.app.Application;
import lime.graphics.Image;
//haxeui libraries
import haxe.ui.components.Button;
import haxe.ui.components.DropDown;
import haxe.ui.components.NumberStepper;
import haxe.ui.components.TextField;
import haxe.ui.notifications.NotificationType;
import haxe.ui.notifications.NotificationManager;
import haxe.ui.events.MouseEvent;
import haxe.ui.containers.ScrollView;
import haxe.ui.containers.menus.Menu;
import haxe.ui.containers.menus.MenuItem;
import haxe.ui.containers.dialogs.MessageBox;
import haxe.ui.containers.dialogs.Dialog;
import haxe.ui.containers.dialogs.Dialogs;
import haxe.ui.util.Color;
import haxe.ui.events.UIEvent;
import haxe.ui.data.DataSource;
import haxe.ui.data.ArrayDataSource;
import haxe.ui.core.Screen;
import haxe.ui.containers.windows.WindowManager;
import haxe.ui.containers.windows.Window;
import haxe.ui.containers.windows.WindowManager;

using StringTools;

typedef DataFormat = {
	var filename:String;
	var displayname:String;
	var credits:Array<String>;
}

typedef PlaylistFormat = {
	var albumName:String;
	var trackName:String;
}

class PlayState extends FlxState
{
//miss
	public static var CLIENT_VERSION:String = '2.7';
	static public var music:FlxSound = new FlxSound();
	static var uiCam:FlxCamera;
	static var haxeUICam:FlxCamera;
	static var windowFocus:Bool = true;
	static var paused:Bool = false;
	static var shuffle:Bool = false;
	static var looping:Bool = false;
	static var queue:Array<String> = [];
	public static var alrTried:Bool = false;
	static var albumMenOpen:Bool = false;
	static var smartCache:Array<Sound> = [];
	static var cacheNames:Array<String> = [];
	static var lyricalIndex:Int = 0 ;
	static var lyricTimes:Array<String> = [];
	static var formattedLyrics:Array<String> = [];
	static var lyricTxt:FlxText;
	static var lyricTween:FlxTween;
	static var songFinished:Bool = false;
//main ui
	static var bg:FlxSprite;
	static var albumCover:FlxSprite;
	static var reflection:FlxSprite;
	static var albumText:FlxText;
	static var shadowText:FlxText;
	public static var albumDropdown:DropDown;
	static var githubDropdown:DropDown;
	static var playlistDropdown:DropDown;
	static var minimizeWindow:Button;
//selection cover prob redo this eventually 
	static var selectionCover:FlxSprite;
	static var selectionTween:FlxTween;
	static var coverTweenActive:Bool = false;
	static var volumeBar:FlxBar;
	static var volumeTween:FlxTween;
	static var volumePercent:FlxText;
	static var volumePercentTween:FlxTween;
	static var curAlbumCover:FlxSprite;
	static var coolAlbumTween:FlxTween;
//bg blur
	static var blurFrames:FlxFilterFrames;
	static var blurFilter = new BlurFilter(100, 200, 10);
	static var textBlur:FlxFilterFrames;
	static var textFilter = new BlurFilter(15, 15, 2);
//finding albums and songs
	static var curAlbum:String;
	static var curSong:String;
	static var albumIndex:Int; 
	static var songIndex:Int;
	static var playingSong:String;
	static var playingAlbum:String;
	static var playingList:Array<String> = [];
	static var albums:Array<String> = [];
//playlists
	static var playlistAlbumList:Array<String> = [];
	static var playlistSongList:Array<String> = [];
	static var storedPlaylist:Array<String> = [];
	static var storedPlaylistSongs:Array<String> = [];
	static var loadAlbum:String = '';
	static var inPlaylist:String = '';
//song text stuff
	static var songCam:FlxCamera;
	static var songList:Array<String> = [];
	static var trackCover:FlxSprite;
	static var songTxt:FlxTypedGroup<FlxText>;
	static var songsTween:FlxTween;
//themes
	public static var theme:String = 'blur';
	var video:FlxVideoSprite;
//bar logic + time bar specifics
	static var lastHitTimeBar:Float = 0;
	static var timeBar:FlxBar;
	static var time:Float = 0;
	static var timeIn:FlxText;
	static var mouseMode:Int = 0;
	static var timeLength:FlxText;
	static var updateTime:Bool = false;
	static var holdTime:Float = 0;
	static var touchingBar:String = '';
//Ui Buttons
	static var uiButtons:FlxTypedGroup<FlxSprite>;
	//static var playButton:FlxSprite;
	static var selectionArrow:FlxSprite;


	override public function create()
	{

        haxe.ui.Toolkit.init();

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

		//save data stuff
		if(FlxG.save.data.Fullscreen != null) FlxG.fullscreen = FlxG.save.data.Fullscreen;
		if(FlxG.save.data.Volume != null) music.volume = FlxG.save.data.Volume;
		if(FlxG.save.data.SymphTheme != null) theme = FlxG.save.data.SymphTheme;

		//set up the music var
		music.persist = true;
		FlxG.sound.list.add(music);

		uiCam = new FlxCamera();
		songCam = new FlxCamera();
		haxeUICam = new FlxCamera();
		FlxG.cameras.reset(uiCam);
		FlxG.cameras.add(songCam);
		FlxG.cameras.add(haxeUICam);
		songCam.bgColor.alpha = 0;
		uiCam.bgColor.alpha = 0;
		haxeUICam.bgColor.alpha = 0;
		FlxCamera.defaultCameras = [uiCam];

		bg = new FlxSprite().loadGraphic("assets/images/cover.jpg");
		bg.setGraphicSize(FlxG.width, FlxG.height);
		bg.screenCenter();
		bg.scrollFactor.set();
		add(bg); //no need to apply blur yet it does that in a seprate function!

		video = new FlxVideoSprite();
		add(video);

		albumCover = new FlxSprite().loadGraphic("assets/images/cover.jpg");
		albumCover.scale.set(0.65, 0.65);
		albumCover.antialiasing = true;
		albumCover.scrollFactor.set();
		albumCover.updateHitbox();
		albumCover.screenCenter();
		albumCover.x -= FlxG.width / 4; 
		albumCover.alpha = 0.95;

		reflection = new FlxSprite(albumCover.x, albumCover.y + albumCover.height).loadGraphic("assets/images/cover.jpg");
		reflection.scale.set(0.65, 1.1);
		reflection.antialiasing = true;
		reflection.flipY = true;
		reflection.alpha = 0.5;
		reflection.scrollFactor.set();
		reflection.updateHitbox();
		add(reflection);
		add(albumCover);

		timeBar = new FlxBar(albumCover.x, albumCover.y + albumCover.width - Std.int(albumCover.height / 30), LEFT_TO_RIGHT, Std.int(albumCover.width), Std.int(albumCover.height / 30), PlayState, 'time', 0, 100);
		timeBar.createFilledBar(0xFF000000, 0xFF00FF00); //0x00000000 <-- transparent color
		timeBar.alpha = 0.5;
		timeBar.numDivisions = 384;
		add(timeBar);

		timeIn = new FlxText(timeBar.x - (timeBar.width * 2.165), timeBar.y - 2.5, 900, '', 10);
		timeIn.setFormat("Gotham Medium.otf", 15, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.SHADOW, FlxColor.BLACK);
		timeIn.antialiasing = true;
		add(timeIn);

		timeLength = new FlxText(timeBar.x + timeBar.width + 1, timeBar.y - 2.5, 900, '', 10);
		timeLength.setFormat("Gotham Medium.otf", 15, FlxColor.WHITE, LEFT, FlxTextBorderStyle.SHADOW, FlxColor.BLACK);
		timeLength.antialiasing = true;
		add(timeLength);

		trackCover = new FlxSprite().makeGraphic(Std.int(FlxG.width / 2), Std.int(FlxG.height), FlxColor.BLACK);
		trackCover.alpha = 0.4;
		trackCover.screenCenter(Y);
		trackCover.x = FlxG.width / 2;
		trackCover.scrollFactor.set();
		add(trackCover);

		shadowText = new FlxText(0, albumCover.y - 65, 1000, "Album Name", 10);
		shadowText.setFormat("Gotham Medium.otf", 60, FlxColor.BLACK, LEFT, FlxTextBorderStyle.SHADOW, FlxColor.BLACK);
		shadowText.alpha = 0.6;
		shadowText.antialiasing = true;
		shadowText.scrollFactor.set();
		add(shadowText);

		uiButtons = new FlxTypedGroup<FlxSprite>();
		add(uiButtons);

		/*playButton = new FlxSprite().loadGraphic("assets/images/Play.png");
		playButton.scale.set(0.1, 0.1);
		playButton.antialiasing = true;
		playButton.updateHitbox();
		playButton.x = albumCover.x + albumCover.width + (playButton.width / 10);
		playButton.y = albumCover.y + (albumCover.width / 2);
		//playButton.x = albumCover.x + albumCover.width + playButton.width;
		uiButtons.add(playButton);
		*/

		albumText = new FlxText(0, albumCover.y - 65, "Album Name", 10);
		albumText.setFormat("Gotham Medium.otf", 60, FlxColor.WHITE, CENTER);
		albumText.alpha = 0.95;
		albumText.antialiasing = true;
		albumText.scrollFactor.set();
		add(albumText);

		songTxt = new FlxTypedGroup<FlxText>();
		add(songTxt);

		githubDropdown = new DropDown();
		add(githubDropdown);
		githubDropdown.x = timeBar.x;
		githubDropdown.y = timeBar.y + githubDropdown.height;
		githubDropdown.width = albumCover.width / 3;
		githubDropdown.dropdownWidth = albumCover.width;
		githubDropdown.moves = false;
		githubDropdown.virtual = true;
		githubDropdown.searchable = true;

		AssetLoader.getGitHubItem('https://raw.githubusercontent.com/Galactic00/SymphonyPlayer/main/albums-list.txt', (data:String) -> {
			if(data != null){
				var githubAlbums:Array<String> = [];
				for (i in 0...data.split('\n').length){
					if(!FileSystem.exists('assets/data/' + data.split('\n')[i])) githubAlbums.push(data.split('\n')[i]);
				}
				trace(githubAlbums);
			
				githubDropdown.dataSource = ArrayDataSource.fromArray(githubAlbums);

				githubDropdown.onChange = (_) -> {
					LoadAlbumFromUrl(encodeURIComponent("https://raw.githubusercontent.com/Galactic00/SymphonyPlayer/main/albums/" + githubAlbums[githubDropdown.selectedIndex]));
				}
				
				if(githubAlbums.contains(FlxG.save.data.lastSongSuggested)){
					NotificationManager.instance.addNotification({
						title: "The Album You Suggested Was Added!",
						body: "The album: " + FlxG.save.data.lastSongSuggested + " was added!",
						type: NotificationType.Success,
						expiryMs: 10000
					});
					FlxG.save.data.lastSongSuggested = "<null>";
					FlxG.save.flush();
				}
			}
		});

		albumDropdown = new DropDown();
		add(albumDropdown);
		albumDropdown.x = timeBar.x + albumCover.width / 3;
		albumDropdown.y = timeBar.y + albumDropdown.height;
		albumDropdown.width = albumCover.width / 3;
		albumDropdown.dropdownWidth = albumCover.width / 2;

		albumDropdown.dropdownWidth = 350;
		albumDropdown.dataSource = ArrayDataSource.fromArray(albums);
		albumDropdown.onChange = (_) -> {
			changeAlbum(albums[albumDropdown.selectedIndex]);
		}
		albumDropdown.searchable = true;
		albumDropdown.virtual = true;

		playlistDropdown = new DropDown();
		add(playlistDropdown);
		playlistDropdown.x = albumDropdown.x + albumCover.width / 3;
		playlistDropdown.y = timeBar.y + playlistDropdown.height;
		playlistDropdown.width = albumCover.width / 3;
		playlistDropdown.dropdownWidth = albumCover.width / 3;
		playlistDropdown.dataSource = ArrayDataSource.fromArray(FileSystem.readDirectory('assets/playlists'));
		playlistDropdown.onChange = (_) -> {
			LoadFromPlayList(FileSystem.readDirectory('assets/playlists')[playlistDropdown.selectedIndex]);
		}
		playlistDropdown.virtual = true;
		playlistDropdown.searchable = true;

		lyricTxt = new FlxText(0, albumCover.y + albumCover.width + 85, "", 10);
		lyricTxt.setFormat("Gotham Medium.otf", 15, FlxColor.WHITE, CENTER);
		lyricTxt.alpha = 1;
		lyricTxt.antialiasing = true;
		lyricTxt.setBorderStyle(OUTLINE, FlxColor.BLACK, 2, 3);
		add(lyricTxt);

		selectionCover = new FlxSprite(0, FlxG.height - 25).makeGraphic(Std.int(FlxG.width / 2), Std.int(200), FlxColor.BLACK);
		selectionCover.alpha = 0.4;
		selectionCover.scrollFactor.set();
		add(selectionCover);

		selectionArrow = new FlxSprite().loadGraphic("assets/images/Arrow.png");
		selectionArrow.scale.set(0.1, 0.1);
		selectionArrow.antialiasing = true;
		selectionArrow.updateHitbox();
		selectionArrow.x = selectionCover.x + (selectionCover.width / 2) - (selectionArrow.width / 2); 
		selectionArrow.y = selectionCover.y + (selectionArrow.width / 2); 
		selectionArrow.color = FlxColor.WHITE;
		add(selectionArrow);

		volumeBar = new FlxBar(0, FlxG.height, LEFT_TO_RIGHT, 450, 22, music, 'volume', 0, 1);
		volumeBar.createFilledBar(0xFF000000, 0xFF00FF00); //0x00000000 <-- transparent color
		volumeBar.alpha = 0.5;
		volumeBar.numDivisions = 384;
		add(volumeBar);

		volumePercent = new FlxText(-378, FlxG.height, 900, Math.round(FlxG.save.data.Volume * 100) + '%', 55);
		volumePercent.setFormat("Gotham Medium.otf", 25, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.SHADOW, FlxColor.BLACK);
		volumePercent.antialiasing = true;
		add(volumePercent);

		curAlbumCover = new FlxSprite(10, FlxG.height).loadGraphic("assets/images/cover.jpg");
		curAlbumCover.scale.set(0.17, 0.17);
		curAlbumCover.updateHitbox();
		curAlbumCover.antialiasing = true;
		curAlbumCover.scrollFactor.set();
		add(curAlbumCover);

		var minimizeWindow:Button = new Button();
		add(minimizeWindow);
		minimizeWindow.text = "Minimize";
		minimizeWindow.cameras = [haxeUICam];
		minimizeWindow.onClick = function(e) Application.current.window.minimized = true;

		AssetLoader.getGitHubItem('https://raw.githubusercontent.com/Galactic00/SymphonyPlayer/main/versions.txt', (data:String) -> {
			var formattedVer:String = data.split('\n')[0];
			trace('Latest git version: ' + formattedVer);
			if(Std.parseFloat(formattedVer) > Std.parseFloat(CLIENT_VERSION) && formattedVer != 'null'){
				NotificationManager.instance.addNotification({
					title: "Update Found!",
					body: "Currently Updating\nPlease Wait...",
					type: NotificationType.Info,
					expiryMs: -1
				});
				AssetLoader.downloadFile('https://raw.githubusercontent.com/Galactic00/SymphonyPlayer/main/Symphony.exe', 'Cache.exe', true);
				FlxG.save.data.SymphonyUpdated = true;
				FlxG.save.flush();
			}
		});

		reloadFolders();
		super.create();

		if(theme != 'blur'){ // down here cause of volume issues and also its not high priority so it can wait a bit
			if(theme.endsWith('.mp4') || theme.endsWith('.mov')){
				video.play('assets/themes/$theme');
			}else{
				if(theme.endsWith('.jpg') || theme.endsWith('.png')){
					bg.loadGraphic(AssetLoader.Image("assets/themes/" + theme));
					bg.setGraphicSize(FlxG.width, FlxG.height);
					bg.updateHitbox();
					bg.screenCenter();
				}
			}
		}

	}

	override public function update(elapsed:Float)
	{
		if(songFinished){
			songFinished = false;
			playNext();
		}
		
		checkLyrics();
		if(!Application.current.window.minimized){
			syncTime();
		}
		if(!Application.current.window.minimized && windowFocus){
			//function stuff
				barLogic();
				updateUICover();
			//fullscreen logic
			if(FlxG.keys.justPressed.F11 || (FlxG.keys.pressed.ALT && FlxG.keys.justPressed.ENTER)){
				if(FlxG.keys.justPressed.F11)FlxG.fullscreen = !FlxG.fullscreen;
				FlxG.save.data.Fullscreen = FlxG.fullscreen;
				FlxG.save.flush();
			}
			//the little album option menu that pops up whehn you right click the album cover
			if(FlxG.mouse.overlaps(albumCover) && FlxG.mouse.justPressedRight && !albumMenOpen){ 
				albumMenOpen = true;
				var albumMenu:Menu = new Menu();
				Screen.instance.addComponent(albumMenu);
				albumMenu.x = FlxG.mouse.x;
				albumMenu.y = FlxG.mouse.y;

					var close:MenuItem = new MenuItem();
					close.text = "Close";
					close.onClick = function(e) {
						albumMenOpen = false;
					};
					albumMenu.addComponent(close);

					if(FileSystem.exists('assets/data/$curAlbum')){
						var fileLocationButton:MenuItem = new MenuItem();
						fileLocationButton.text = "Open File Location";
						fileLocationButton.onClick = function(e) {
							albumMenOpen = false;
							var programPath:String = Sys.programPath().split('Symphony.exe')[0];
							var folderPath = 'assets/data/$curAlbum';
							folderPath = programPath + folderPath.replace("/", "\\");
							trace(folderPath);
							#if windows
							new Process("explorer.exe", [folderPath]);
							#elseif mac
							new Process("open", [folderPath]);
							#elseif linux
							new Process("xdg-open", [folderPath]);
							#end
						};
						albumMenu.addComponent(fileLocationButton);

						var deleteAlbumOp:MenuItem = new MenuItem();
						deleteAlbumOp.text = "Delete Album";
						deleteAlbumOp.color = FlxColor.RED;
						deleteAlbumOp.onClick = function(e) {
							var deleteAlbumConfirm:Dialog = Dialogs.messageBox(
								'Delete the Album\n$curAlbum?',
								"Question",
								"yesno",
								true,
								function(clickedButton:DialogButton) {
									albumMenOpen = false;
									if(clickedButton == DialogButton.YES){
										removeAlbum(curAlbum);
									}
								}
							);
							deleteAlbumConfirm.cameras = [haxeUICam];
							deleteAlbumConfirm.x = FlxG.mouse.x;
							deleteAlbumConfirm.y = FlxG.mouse.y;
						};
						albumMenu.addComponent(deleteAlbumOp);
					}else{
						var downloadAlbumOp:MenuItem = new MenuItem();
						downloadAlbumOp.text = "Download Album";
						downloadAlbumOp.onClick = function(e) {
							downloadAlbum(curAlbum, songList);
							albumMenOpen = false;
						};
						albumMenu.addComponent(downloadAlbumOp);
					}
					
					var format:MenuItem = new MenuItem();
					format.text = "Format Folders";
					format.onClick = function(e) {
						albumMenOpen = false;
						formatFolder('assets/format');
					};
					albumMenu.addComponent(format);

					#if debug
						var updateGit:MenuItem = new MenuItem();
						updateGit.text = "UpdateGitHub Folders";
						updateGit.onClick = function(e) {
							albumMenOpen = false;
							var albumListTxt:String = '';
							for (file in FileSystem.readDirectory('C:/Users/Chase/Documents/Github/SymphonyPlayer/albums')){
								albumListTxt = albumListTxt + '\n' + file;
							}
							File.saveContent('C:/Users/Chase/Documents/Github/SymphonyPlayer/albums-list.txt', albumListTxt);
						};
						albumMenu.addComponent(updateGit);
					#end

					var suggestSong:MenuItem = new MenuItem();
					suggestSong.text = "Suggest Albums/Songs";
					suggestSong.onClick = function(e) {
						var suggestBg:FlxSprite = new FlxSprite().makeGraphic(350, 500, FlxColor.WHITE);
						suggestBg.screenCenter();
						suggestBg.scrollFactor.set();
						suggestBg.cameras = [haxeUICam];
						add(suggestBg);

						var albumNameButton:TextField = new TextField();
						add(albumNameButton);		
						albumNameButton.width = 345;
						albumNameButton.screenCenter();
						albumNameButton.y -= 200;
						albumNameButton.placeholder = "Album or song name (should be the exact same as the spotify name, copy and paste it)";
						albumNameButton.cameras = [haxeUICam];							

						var linkButton:TextField = new TextField();
						add(linkButton);
						linkButton.width = 345;
						linkButton.screenCenter();
						linkButton.y -= 150;
						linkButton.placeholder = "Link to album";
						linkButton.cameras = [haxeUICam];			

						var sendButton:Button = new Button();
						add(sendButton);
						sendButton.screenCenter();
						sendButton.x -= 25;
						sendButton.text = "Send";
						sendButton.cameras = [haxeUICam];
						
						var closeSuggestButton:Button = new Button();
						add(closeSuggestButton);
						closeSuggestButton.screenCenter();
						closeSuggestButton.x -= 75;
						closeSuggestButton.text = "Close";
						closeSuggestButton.cameras = [haxeUICam];
						closeSuggestButton.onClick = function(e) {
							suggestBg.kill();
							Screen.instance.removeComponent(sendButton);
							linkButton.kill();
							albumNameButton.kill();
							linkButton.disposeComponent();
							albumNameButton.disposeComponent();
							albumMenOpen = false;
							Screen.instance.removeComponent(closeSuggestButton);
						}

						sendButton.onClick = function(e) {
							sys.thread.Thread.create(() -> {
								var discordWebHook = new Http("https://discord.com/api/webhooks/1231619611548581959/X_gkixDjwkoP9Au4IhZ2AErgeKl6zyWzhcwhmXaXIRfT6OAGVbKtd_H5ut248TzBPIBV");
								discordWebHook.setParameter("content", '<@859593766206046230> Album: ' + albumNameButton.text + '\nLink: ' + linkButton.text);
								discordWebHook.addParameter("username", 'cool dude');
								discordWebHook.addParameter("avatar_url", "https://static.wikia.nocookie.net/youtube/images/2/2b/Penguinz0gallery.jpg/revision/latest/scale-to-width-down/250?cb=20210129030616");
								discordWebHook.request(true);
								FlxG.save.data.lastSongSuggested = albumNameButton.text;
								FlxG.save.flush();
								trace('did it');
								suggestBg.kill();
								Screen.instance.removeComponent(sendButton);
								linkButton.kill();
								albumNameButton.kill();
								linkButton.disposeComponent();
								albumNameButton.disposeComponent();
								albumMenOpen = false;
								Screen.instance.removeComponent(closeSuggestButton);
							});
						}
					};

					albumMenu.addComponent(suggestSong);

					var changeTheme:MenuItem = new MenuItem();
					albumMenu.addComponent(changeTheme);
					changeTheme.text = "Change Theme";
					changeTheme.onClick = function(e) {
						albumMenOpen = false;
						var themeWindow:Window = new Window();
						WindowManager.instance.addWindow(themeWindow);
						themeWindow.x = FlxG.mouse.x;
						themeWindow.y = FlxG.mouse.y;
						themeWindow.cameras = [haxeUICam];
						themeWindow.title = 'Theme Editor';
						themeWindow.minimizable = false;
						themeWindow.collapsable = false;

						var addTheme:Button = new Button();
						themeWindow.addComponent(addTheme);
						addTheme.text = "Add Theme";
						addTheme.color = FlxColor.LIME;
						addTheme.cameras = [haxeUICam];
						addTheme.onClick = function(e) {
							albumMenOpen = true;
							var playlistBg:FlxSprite = new FlxSprite().makeGraphic(500, 500, FlxColor.WHITE);
							playlistBg.screenCenter();
							playlistBg.scrollFactor.set();
							playlistBg.cameras = [haxeUICam];
							add(playlistBg);

							var rename:TextField = new TextField();
							add(rename);				
							rename.width = 485;
							rename.screenCenter();
							rename.y -= 200;
							rename.placeholder = "Theme Name";
							rename.cameras = [haxeUICam];

							var imagePathText:TextField = new TextField();
							add(imagePathText);				
							imagePathText.width = 485;
							imagePathText.screenCenter();
							imagePathText.y -= 100;
							imagePathText.placeholder = "Folder Path For Image (Can not be blank) (Will look weird if not 1920x1080)";
							imagePathText.cameras = [haxeUICam];

							var createThemeButton:Button = new Button();
							add(createThemeButton);
							createThemeButton.screenCenter();
							createThemeButton.x -= 25;
							createThemeButton.text = "Create";
							createThemeButton.cameras = [haxeUICam];
							
							var closeCreateButton:Button = new Button();
							add(closeCreateButton);
							closeCreateButton.screenCenter();
							closeCreateButton.x -= 75;
							closeCreateButton.text = "Close";
							closeCreateButton.cameras = [haxeUICam];
							closeCreateButton.onClick = function(e) {
								playlistBg.kill();
								Screen.instance.removeComponent(createThemeButton);
								rename.kill();
								rename.disposeComponent();
								imagePathText.kill();
								imagePathText.disposeComponent();
								albumMenOpen = false;
								Screen.instance.removeComponent(closeCreateButton);
							}

							createThemeButton.onClick = function(e) {
								var finalImgPath:String = imagePathText.text;
								if(finalImgPath.startsWith("\"")) finalImgPath = finalImgPath.substring(1, finalImgPath.length - 1);
								var length:Int = finalImgPath.split('.').length - 1;
								File.copy(finalImgPath, 'assets/themes/' + rename.text + '.' + finalImgPath.split('.')[length]);
								playlistBg.kill();
								Screen.instance.removeComponent(createThemeButton);
								rename.kill();
								rename.disposeComponent();
								imagePathText.kill();
								imagePathText.disposeComponent();
								albumMenOpen = false;
								Screen.instance.removeComponent(closeCreateButton);
							}
						};

						var deleteTheme:Button = new Button();
						themeWindow.addComponent(deleteTheme);
						deleteTheme.text = "Delete Selected Theme";
						deleteTheme.color = FlxColor.RED;
						deleteTheme.cameras = [haxeUICam];
						deleteTheme.onClick = function(e) {
							FileSystem.deleteFile('assets/themes/$theme');
						}

						var themeList = new DropDown();
						themeWindow.addComponent(themeList);
						themeList.width = 125;
						themeList.cameras = [haxeUICam];
						var themeButtons:Array<String> = ['blur'];
						for (file in FileSystem.readDirectory('assets/themes')) themeButtons.push(file);
						themeList.dataSource = ArrayDataSource.fromArray(themeButtons);
						if(themeButtons[themeList.selectedIndex] == 'blur') {
							deleteTheme.disabled = true;
							deleteTheme.alpha = 0.5;
						}

						themeList.virtual = true;
						themeList.searchable = true;

						themeList.onChange = (_) -> {
							sys.thread.Thread.create(() -> {
								theme = themeButtons[themeList.selectedIndex];
								FlxG.save.data.SymphTheme = theme;
								FlxG.save.flush();
								if(theme != 'blur'){
									deleteTheme.disabled = false;
									deleteTheme.alpha = 1;
									if(theme.endsWith('.mp4') || theme.endsWith('.mov')){
											video.stop();
											video.play('assets/themes/$theme');
											video.visible = true;
									}else{
										if(theme.endsWith('.jpg') || theme.endsWith('.png')){
											bg.loadGraphic(AssetLoader.Image("assets/themes/" + theme));
											bg.setGraphicSize(FlxG.width, FlxG.height);
											bg.updateHitbox();
											bg.screenCenter();
											video.visible = false;
											video.stop();
										}
									}
								}else{
									deleteTheme.disabled = true;
									deleteTheme.alpha = 0.5;
									video.visible = false;
									video.stop();
									bg.setGraphicSize(FlxG.width, FlxG.height);
									bg.updateHitbox();
									updateUI(bg, albumCover, true);
								}
							});
						}
					};

					if(!FileSystem.exists('assets/playlists/$curAlbum')){ // if you are NOT in a playlist
						var addSongToPlayList:MenuItem = new MenuItem();
						albumMenu.addComponent(addSongToPlayList);
						addSongToPlayList.text = "Add The Song You Are Viewing To Playlist";
						addSongToPlayList.onClick = function(e) {
							var playlistList:Menu = new Menu();
							Screen.instance.addComponent(playlistList);
							playlistList.x = FlxG.mouse.x;
							playlistList.y = FlxG.mouse.y;

							var close:MenuItem = new MenuItem();
							close.text = "Close";
							close.onClick = function(e) {
								albumMenOpen = false;
							};
							playlistList.addComponent(close);

						var createPlaylist:MenuItem = new MenuItem();
						playlistList.addComponent(createPlaylist);
						createPlaylist.text = "Create Playlist";
						createPlaylist.color = FlxColor.LIME;
						createPlaylist.onClick = function(e) {
							var playlistBg:FlxSprite = new FlxSprite().makeGraphic(500, 500, FlxColor.WHITE);
							add(playlistBg);
							playlistBg.screenCenter();
							playlistBg.scrollFactor.set();
							playlistBg.cameras = [haxeUICam];

							var listNameText:TextField = new TextField();
							add(listNameText);				
							listNameText.width = 485;
							listNameText.screenCenter();
							listNameText.y -= 200;
							listNameText.placeholder = "Playlist name";
							listNameText.cameras = [haxeUICam];

							var imagePathText:TextField = new TextField();
							add(imagePathText);				
							imagePathText.width = 485;
							imagePathText.screenCenter();
							imagePathText.y -= 100;
							imagePathText.placeholder = "Folder Path For Image (Can be blank) (Will look weird if not 640x640)";
							imagePathText.cameras = [haxeUICam];

							var createPlaylistButton:Button = new Button();
							add(createPlaylistButton);
							createPlaylistButton.screenCenter();
							createPlaylistButton.x -= 25;
							createPlaylistButton.text = "Create";
							createPlaylistButton.cameras = [haxeUICam];
							
							var closeCreateButton:Button = new Button();
							add(closeCreateButton);
							closeCreateButton.screenCenter();
							closeCreateButton.x -= 75;
							closeCreateButton.text = "Close";
							closeCreateButton.cameras = [haxeUICam];
							closeCreateButton.onClick = function(e) {
								playlistBg.kill();
								Screen.instance.removeComponent(createPlaylistButton);
								listNameText.kill();
								listNameText.disposeComponent();
								imagePathText.kill();
								imagePathText.disposeComponent();
								albumMenOpen = false;
								Screen.instance.removeComponent(closeCreateButton);
							}

							createPlaylistButton.onClick = function(e) {
								var data:String = '';
								FileSystem.createDirectory('assets/playlists/' + listNameText.text);
								File.saveContent('assets/playlists/' + listNameText.text + '/data.txt', data);
								var finalImgPath:String = imagePathText.text;
								if(finalImgPath.startsWith("\"")) finalImgPath = finalImgPath.substring(1, finalImgPath.length - 1);
								File.copy(finalImgPath, 'assets/playlists/' + listNameText.text + '/cover.jpg');
								playlistDropdown.dataSource = ArrayDataSource.fromArray(FileSystem.readDirectory('assets/playlists'));
								playlistBg.kill();
								Screen.instance.removeComponent(createPlaylistButton);
								listNameText.kill();
								listNameText.disposeComponent();
								imagePathText.kill();
								imagePathText.disposeComponent();
								albumMenOpen = false;
								Screen.instance.removeComponent(closeCreateButton);
							}
						};
						


							for (file in FileSystem.readDirectory('assets/playlists')){
								var item:MenuItem = new MenuItem();
								item.text = file;
								item.onClick = function(e) {
									var thing:String = File.getContent('assets/playlists/' + file + '/data.txt') + '\n' + curAlbum + '/' + curSong + '/' + songList[songIndex];
									if(File.getContent('assets/playlists/' + file + '/data.txt') == '') thing = curAlbum + '/' + curSong + '/' + songList[songIndex];
									trace(thing);
									File.saveContent('assets/playlists/' + file + '/data.txt', thing);
									albumMenOpen = false;
								};
								playlistList.addComponent(item);
							}
						};
					}else{												//if you are IN a playlist
						var deletePlaylist:MenuItem = new MenuItem();
						deletePlaylist.text = "Delete This Playlist";
						deletePlaylist.color = FlxColor.RED;
						deletePlaylist.onClick = function(e) {
							removeAlbum(curAlbum, 'assets/playlists/');
							playlistDropdown.dataSource = ArrayDataSource.fromArray(FileSystem.readDirectory('assets/playlists'));
							albumMenOpen = false;
						}
						albumMenu.addComponent(deletePlaylist);

						var removeSongFromPlayList:MenuItem = new MenuItem();
						removeSongFromPlayList.text = "Remove The Song You Are Viewing From Playlist";
						removeSongFromPlayList.color = FlxColor.RED;
						removeSongFromPlayList.onClick = function(e) {
							var thing:String = File.getContent('assets/playlists/' + curAlbum + '/data.txt');
							var thing2:String = thing.split('$curAlbum/$curSong/' + songList[songIndex])[0];
							var thing3:String = thing.split('$curAlbum/$curSong/' + songList[songIndex])[1];
							var thing4:String = thing2 + '\n' + thing3;
							trace(thing);
							trace(thing2);
							trace(thing3);
							trace(thing4);						
							File.saveContent('assets/playlists/' + curAlbum + '/data.txt', thing4);
							albumMenOpen = false;
						}
						//albumMenu.addComponent(removeSongFromPlayList);
					}
			}
			//make sure we only let you use controls for the player if there arent any popups on screen
			if(!albumMenOpen && !albumDropdown.dropDownOpen && !githubDropdown.dropDownOpen){
				if(FlxG.keys.justPressed.SPACE){
					loadSong(true);
				}
				if(FlxG.keys.justPressed.D || FlxG.keys.justPressed.RIGHT){
					changeAlbum(1);
				}
				if(FlxG.keys.justPressed.A || FlxG.keys.justPressed.LEFT){
					changeAlbum(-1);
				}
				if((FlxG.keys.justPressed.P || FlxG.mouse.justPressedRight && !FlxG.mouse.overlaps(albumCover)) && music != null){
				//if((FlxG.keys.justPressed.P || (FlxG.mouse.justPressedRight && !FlxG.mouse.overlaps(albumCover) && !FlxG.mouse.overlaps(trackCover)) || (FlxG.mouse.overlaps(playButton) && FlxG.mouse.justPressed)) && music != null){
					paused = !paused;
					if(paused){
						//playButton.loadGraphic('assets/images/Play.png');
						music.pause();
						Discord.DiscordClient.changePresence('Listening to $playingSong', 'On $playingAlbum (Paused)', false);
					}else{
						//playButton.loadGraphic('assets/images/Pause.png');
						music.resume();
						Discord.DiscordClient.changePresence('Listening to $playingSong', 'On $playingAlbum', true, music.length - music.time);	
					}
				}
				if(FlxG.keys.justPressed.X){
					looping = !looping;
					playToggleSfx(looping);
				}
				if(FlxG.keys.justPressed.Z){
					shuffle = !shuffle;
					playToggleSfx(shuffle);
				}
				if(FlxG.keys.justPressed.Q){
					addToQueue();
				}
			//specificly if the mouse is hovering over the track cover
				if(FlxG.mouse.overlaps(trackCover)){
					if(FlxG.mouse.justPressed){
						loadSong(true);
					}
					if(FlxG.mouse.justPressedRight){
						albumMenOpen = true;
						var likeWindow:Window = new Window();
						WindowManager.instance.addWindow(likeWindow);
						likeWindow.x = FlxG.mouse.x;
						likeWindow.y = FlxG.mouse.y;
						likeWindow.cameras = [haxeUICam];
						likeWindow.title = 'Add Song To Playlist\n' + curSong;
						likeWindow.minimizable = false;
						likeWindow.collapsable = false;
						likeWindow.moveComponentToFront();
						var addPlaylist:Button = new Button();
						likeWindow.addComponent(addPlaylist);
						addPlaylist.text = "Create Playlist";
						addPlaylist.color = FlxColor.LIME;
						addPlaylist.cameras = [haxeUICam];
						addPlaylist.onClick = function(e) {
							var playlistBg:FlxSprite = new FlxSprite().makeGraphic(500, 500, FlxColor.WHITE);
							playlistBg.screenCenter();
							playlistBg.scrollFactor.set();
							playlistBg.cameras = [haxeUICam];
							add(playlistBg);

							var listNameText:TextField = new TextField();
							add(listNameText);		
							listNameText.width = 485;
							listNameText.screenCenter();
							listNameText.y -= 200;
							listNameText.placeholder = "Playlist name";
							listNameText.cameras = [haxeUICam];
									
							var imagePathText:TextField = new TextField();
							add(imagePathText);				
							imagePathText.width = 485;
							imagePathText.screenCenter();
							imagePathText.y -= 100;
							imagePathText.placeholder = "Folder Path For Image (Can be blank) (Will look weird if not 640x640)";
							imagePathText.cameras = [haxeUICam];

							var createPlaylistButton:Button = new Button();
							add(createPlaylistButton);
							createPlaylistButton.screenCenter();
							createPlaylistButton.x -= 25;
							createPlaylistButton.text = "Create";
							createPlaylistButton.cameras = [haxeUICam];
							
							var closeCreateButton:Button = new Button();
							add(closeCreateButton);
							closeCreateButton.screenCenter();
							closeCreateButton.x -= 75;
							closeCreateButton.text = "Close";
							closeCreateButton.cameras = [haxeUICam];
							closeCreateButton.onClick = function(e) {
								playlistBg.kill();
								Screen.instance.removeComponent(createPlaylistButton);
								listNameText.kill();
								listNameText.disposeComponent();
								imagePathText.kill();
								imagePathText.disposeComponent();
								albumMenOpen = false;
								Screen.instance.removeComponent(closeCreateButton);
							}

							createPlaylistButton.onClick = function(e) {
								var data:String = '';
								FileSystem.createDirectory('assets/playlists/' + listNameText.text);
								File.saveContent('assets/playlists/' + listNameText.text + '/data.txt', data);
								var finalImgPath:String = imagePathText.text;
								if(finalImgPath.startsWith("\"")) finalImgPath = finalImgPath.substring(1, finalImgPath.length - 1);
								File.copy(finalImgPath, 'assets/playlists/' + listNameText.text + '/cover.jpg');
								playlistDropdown.dataSource = ArrayDataSource.fromArray(FileSystem.readDirectory('assets/playlists'));
								playlistBg.kill();
								Screen.instance.removeComponent(createPlaylistButton);
								listNameText.kill();
								listNameText.disposeComponent();
								imagePathText.kill();
								imagePathText.disposeComponent();
								albumMenOpen = false;
								Screen.instance.removeComponent(closeCreateButton);
							}							
						};

						var plList = new DropDown();
						likeWindow.addComponent(plList);
						plList.width = 125;
						plList.searchable = false;
						plList.moves = true;
						plList.cameras = [haxeUICam];
						plList.dataSource = ArrayDataSource.fromArray(FileSystem.readDirectory('assets/playlists'));
						plList.virtual = true;
						plList.searchable = true;
						plList.onChange = (_) -> {
							var selected:String = FileSystem.readDirectory('assets/playlists')[plList.selectedIndex]; 
							var thing:String = File.getContent('assets/playlists/' + selected + '/data.txt') + '\n' + curAlbum + '/' + curSong + '/' + songList[songIndex];
							if(File.getContent('assets/playlists/' + selected + '/data.txt') == '') thing = curAlbum + '/' + curSong + '/' + songList[songIndex];
							trace(thing);
							File.saveContent('assets/playlists/' + selected + '/data.txt', thing);
							albumMenOpen = false;
							//likeWindow.close();
						}
					}
					if(FlxG.mouse.wheel != 0) changeAlbum(0 - FlxG.mouse.wheel);
					mouseTest();
				}else{
			//specificly if the mouse is NOT hovering over the track cover
					if(FlxG.keys.justPressed.W || FlxG.keys.justPressed.UP){
						changeSong(-1);
					}
					if(FlxG.keys.justPressed.S || FlxG.keys.justPressed.DOWN){
						changeSong(1);
					}
					if(FlxG.mouse.wheel != 0) changeSong(0 - FlxG.mouse.wheel);
				
					if(FlxG.mouse.overlaps(selectionCover)){
						if(FlxG.mouse.overlaps(curAlbumCover) && FlxG.mouse.justPressed){ 
							if(FileSystem.exists('assets/playlists/$playingAlbum')) // if you are in a playlist
								LoadFromPlayList(playingAlbum);
							else 													 // not in a playlist
								changeAlbum(playingAlbum);

							curSong = playingSong;
							songIndex = songList.indexOf(playingSong);
							changeSong(false);
						}
					}
				}
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

	function getNextSong() {
		var playingIndex:Int = playingList.indexOf(playingSong) + 1;
		if(playingIndex >= playingList.length) playingIndex = 0;
		loadSong(playingAlbum, playingList[playingIndex]);		
	}

	function getRandomSong() {
		loadSong(playingAlbum, playingList[FlxG.random.int(0, playingList.length)]);		
	}

	function addToQueue() {
		var queueName = curAlbum + '<|>' + curSong;
		if(!queue.contains(queueName)){
			queue.push(queueName);
			playToggleSfx(true);
		}else{
			queue.remove(queueName);
			playToggleSfx(false);
		}
		changeSong(false);
	}

	function playSongFromQueue() {
		loadSong(queue[0].split('<|>')[0], queue[0].split('<|>')[1]);
		queue.shift();
	}

	public function updateUICover() {
		if(coverTweenActive != FlxG.mouse.overlaps(selectionCover)){
			coverTweenActive = FlxG.mouse.overlaps(selectionCover);
			if(selectionTween != null) {selectionTween.cancel();}
			if(coolAlbumTween != null) {coolAlbumTween.cancel();}
			if(coverTweenActive){
				selectionTween = FlxTween.tween(selectionCover, {y: FlxG.height - 200}, 0.13, {ease: FlxEase.quartIn, onComplete: function(twn:FlxTween) {selectionTween = null;}});
				volumeTween = FlxTween.tween(volumeBar, {y: FlxG.height - volumeBar.height}, 0.13, {ease: FlxEase.quartIn, onComplete: function(twn:FlxTween) {volumeTween = null;}});
				volumePercentTween = FlxTween.tween(volumePercent, {y: FlxG.height - volumeBar.height}, 0.13, {ease: FlxEase.quartIn, onComplete: function(twn:FlxTween) {volumePercentTween = null;}});
				coolAlbumTween = FlxTween.tween(curAlbumCover, {y: FlxG.height - 175}, 0.13, {ease: FlxEase.quartIn, onComplete: function(twn:FlxTween) {coolAlbumTween = null;}});
			}else{
				selectionTween = FlxTween.tween(selectionCover, {y: FlxG.height - 25}, 0.13, {ease: FlxEase.quartOut, onComplete: function(twn:FlxTween) {selectionTween = null;}});
				volumeTween = FlxTween.tween(volumeBar, {y: FlxG.height}, 0.13, {ease: FlxEase.quartIn, onComplete: function(twn:FlxTween) {volumeTween = null;}});
				volumePercentTween = FlxTween.tween(volumePercent, {y: FlxG.height}, 0.13, {ease: FlxEase.quartIn, onComplete: function(twn:FlxTween) {volumePercentTween = null;}});
				coolAlbumTween = FlxTween.tween(curAlbumCover, {y: FlxG.height}, 0.13, {ease: FlxEase.quartOut, onComplete: function(twn:FlxTween) {coolAlbumTween = null;}});
			}
		}
	}

	function updateAlbumNameText(?temptext:String) {
		var nameText:String = curAlbum;
		if (temptext != null) nameText = temptext;
		if(nameText.length > 15) nameText = nameText.substr(0, 12) + '...';
		albumText.text = nameText;
		shadowText.text = nameText;
		albumText.x = albumCover.x + (albumCover.width - albumText.width) / 2;
		shadowText.x = albumText.x + 4;
		shadowText.y = albumText.y + 4;
	}

	function playNext() {
		if(looping){
			music.play();
		}else{
			if(queue.length > 0){
				playSongFromQueue();
			}else{
				if(shuffle){
					getRandomSong();
				}else{
					getNextSong();
				}
			}
		}
		trace(music);
	}


	public inline function loadSong(?albumPath:String, ?songPath:String, reloadPreload:Bool = false) {
		alrTried = true;
		if(albumPath != null && songPath != null){
			playingAlbum = albumPath;
			playingSong = songPath;
		}else{
			playingAlbum = albums[albumIndex];
			playingSong = songList[songIndex];
			if(playingAlbum == null) playingAlbum = curAlbum; //fail save for url loading
		}
		trace('playingAlbum: ' + playingAlbum);
		trace('playingSong: ' + playingSong);
		trace('playinglist: ' + playingList);

		loadAlbum = playingAlbum;
		if(FileSystem.exists('assets/playlists/$playingAlbum')){
			inPlaylist = playingAlbum;
			trace('is a playlist');
			loadAlbum = playlistAlbumList[playlistSongList.indexOf(playingSong)];
			trace(playingSong);
			trace(playlistSongList.indexOf(playingSong));
			trace(playlistAlbumList[playlistSongList.indexOf(playingSong)]);
		} 


		if(reloadPreload) loadSongListFromAlbum(loadAlbum);
		trace('new playinglist: ' + playingList);
		changeSong(false);
		FlxG.save.data.lastPlayedAlbum = loadAlbum;
		FlxG.save.data.lastPlayedSong = playingSong;
		FlxG.save.flush();
		
		var fullPath:String = 'assets/data/$loadAlbum/$playingSong';

		var codec:String = 'ogg';
		if (FileSystem.exists('$fullPath/song.wav')) codec = 'wav';
		//playButton.loadGraphic('assets/images/Play.png');
		lyricTxt.text = '';
		
		//if it found the song cached
		if(cacheNames.contains(playingSong)){
			trace('found song in cache');
			
			music.loadEmbedded(smartCache[cacheNames.indexOf(playingSong)], false, false, function() {songFinished = true;});
			music.volume = FlxG.save.data.Volume;
			music.play();
			//playButton.loadGraphic('assets/images/Pause.png');
			//music = FlxG.sound.load(smartCache[cacheNames.indexOf(playingSong)], 1.0, false, null, false, true, null, function() {songFinished = true;});
			Discord.DiscordClient.changePresence('Listening to $playingSong', 'On $loadAlbum', true, music.length - music.time);	
			timeLength.text = FlxStringUtil.formatTime(Math.floor(music.length / 1000), false);
			if (FileSystem.exists('$fullPath/song.$codec')){
				curAlbumCover.loadGraphic(AssetLoader.Image('assets/data/$loadAlbum/cover.jpg'));
				curAlbumCover.updateHitbox();
				formattedLyrics = [];
				if(FileSystem.exists('$fullPath/lyrics.txt')) loadLyrics(File.getContent('$fullPath/lyrics.txt'));
			}else{
				AssetLoader.loadFromURL(encodeURIComponent('https://raw.githubusercontent.com/Galactic00/SymphonyPlayer/main/albums/$loadAlbum/cover.jpg'), (data:ByteArray) -> {
					if(data != null){
						var bmpData:BitmapData = BitmapData.fromBytes(data);
						curAlbumCover.loadGraphic(FlxGraphic.fromBitmapData(bmpData));
						curAlbumCover.updateHitbox();
						alrTried = false;
					}
				});
			}
			paused = false;
			alrTried = false;
			cacheNext();
			Application.current.window.setIcon(Image.fromBitmapData(curAlbumCover.pixels));
			AssetLoader.getGitHubItem(encodeURIComponent('https://raw.githubusercontent.com/Galactic00/SymphonyPlayer/main/albums/$loadAlbum/$playingSong/lyrics.txt'), (data:String) -> {
				formattedLyrics = [];
				if(data != null) loadLyrics(data);
			});
		}else{
			//song was not in cache
			if (FileSystem.exists('$fullPath/song.$codec')){
				
				music.loadEmbedded(Sound.fromFile('$fullPath/song.$codec'), false, false, function() {songFinished = true;});
				music.volume = FlxG.save.data.Volume;
				music.play();
				//playButton.loadGraphic('assets/images/Pause.png');
				//music = FlxG.sound.load(Sound.fromFile('$fullPath/song.$codec'), 1.0, false, null, false, true, null, function() {songFinished();});
				Discord.DiscordClient.changePresence('Listening to $playingSong', 'On $loadAlbum', true, music.length - music.time);	
				timeLength.text = FlxStringUtil.formatTime(Math.floor(music.length / 1000), false);
				curAlbumCover.loadGraphic(AssetLoader.Image('assets/data/$loadAlbum/cover.jpg'));
				curAlbumCover.updateHitbox();
				paused = false;
				alrTried = false;
				cacheCurrent();
				cacheNext();
				Application.current.window.setIcon(Image.fromBitmapData(curAlbumCover.pixels));
				formattedLyrics = [];
				if(FileSystem.exists('$fullPath/lyrics.txt')) loadLyrics(File.getContent('$fullPath/lyrics.txt'));
			}else{
				//cant find local path using url
				AssetLoader.loadFromURL(encodeURIComponent('https://raw.githubusercontent.com/Galactic00/SymphonyPlayer/main/albums/$loadAlbum/$playingSong/song.ogg'), (data:ByteArray) -> {
					if (data != null){
						var urlSound:Sound = new Sound();
						urlSound.loadCompressedDataFromByteArray(data, data.length);
						music.loadEmbedded(urlSound, false, false, function() {songFinished = true;});
						music.volume = FlxG.save.data.Volume;
						music.play();
						//playButton.loadGraphic('assets/images/Pause.png');
						//music = FlxG.sound.load(urlSound, 1.0, false, null, false, true, null, function() {songFinished();});
						
						Discord.DiscordClient.changePresence('Listening to $playingSong', 'On $loadAlbum', true, music.length - music.time);	
						timeLength.text = FlxStringUtil.formatTime(Math.floor(music.length / 1000), false);
						paused = false;
						AssetLoader.loadFromURL(encodeURIComponent('https://raw.githubusercontent.com/Galactic00/SymphonyPlayer/main/albums/$loadAlbum/cover.jpg'), (data:ByteArray) -> {
							if(data != null){
								var bmpData:BitmapData = BitmapData.fromBytes(data);
								curAlbumCover.loadGraphic(FlxGraphic.fromBitmapData(bmpData));
							}else{
								curAlbumCover.loadGraphic(AssetLoader.Image('assets/data/$loadAlbum/cover.jpg'));
							}
							curAlbumCover.updateHitbox();
							alrTried = false;
						});
						cacheCurrent();
						cacheNext();
						Application.current.window.setIcon(Image.fromBitmapData(curAlbumCover.pixels));
						trace('https://raw.githubusercontent.com/Galactic00/SymphonyPlayer/main/albums/$loadAlbum/$playingSong/lyrics.txt');
						AssetLoader.getGitHubItem(encodeURIComponent('https://raw.githubusercontent.com/Galactic00/SymphonyPlayer/main/albums/$loadAlbum/$playingSong/lyrics.txt'), (data:String) -> {
							formattedLyrics = [];
							if(data != null) loadLyrics(data);
						});
					}else{
						trace('cound not load $fullPath from local files or url');
						alrTried = false;
					}
				});
			}
		}
	}
	
	static inline function loadSongListFromAlbum(songListAlbum:String) {
		playingList = [];
		if(!FileSystem.exists('assets/playlists/$playingAlbum')){
			if(FileSystem.exists('assets/data/$songListAlbum')){
				if(FileSystem.exists('assets/data/$songListAlbum/data.json')){
					var rawJson = File.getContent('assets/data/$songListAlbum/data.json');
					var json = cast Json.parse(rawJson);
					for (i in 0...json.trackdata.length){
						playingList.push(json.trackdata[i].filename);
					}
				}else{
					for (file in FileSystem.readDirectory('assets/data/$songListAlbum')) if(file != 'cover.jpg') playingList.push(file);
				}
			}else{
				AssetLoader.getGitHubItem(encodeURIComponent('https://raw.githubusercontent.com/Galactic00/SymphonyPlayer/main/albums/$songListAlbum/data.json'), (data:String) -> {
					if (data != null) {
						var rawJson = data;
						var json = cast Json.parse(rawJson);
						for (i in 0...json.trackdata.length){
							playingList.push(json.trackdata[i].filename);
						}
					}
				});
			}
		}else{
			playingList = playlistSongList;
		}
	}

	static function loadLyrics(lyricList:String) { //formats lyrics correctly
		sys.thread.Thread.create(() -> {
			trace('loading lyrics');
			var splitLyrics:Array<String> = lyricList.split('\n');
			formattedLyrics = [];
			lyricalIndex = 0;
			lyricTimes = [];
			for (i in 0...splitLyrics.length){
				lyricTimes.push(splitLyrics[i].split("[")[1].split("]")[0]);
				formattedLyrics.push(splitLyrics[i].split("]")[1]);
			}
			trace(lyricTimes);
			trace(formattedLyrics);
		});
	}
	
	static function checkLyrics() {
		if(formattedLyrics.length > 0){
			var songSec:Float = Std.parseFloat(FlxStringUtil.formatTime(Math.floor(music.time / 1000)).split(':')[1]);
			var songMin:Float = Std.parseFloat(FlxStringUtil.formatTime(Math.floor(music.time / 1000)).split(':')[0]);

			var lyricSec:Float = Std.parseFloat(lyricTimes[lyricalIndex].split(':')[1].split('.')[0]);
			var lyricMin:Float = Std.parseFloat(lyricTimes[lyricalIndex].split(':')[0]);

			//trace('|' + songSec + '|' + songMin + '| ---- |' + lyricSec + '|' + lyricMin);

			if(songSec >= lyricSec && songMin >= lyricMin){
				lyricTxt.text = formattedLyrics[lyricalIndex];
				lyricTxt.x = albumCover.x + (albumCover.width - lyricTxt.width) / 2;
				lyricalIndex ++;
			}
		}
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
				var limit:Float = percent;
				if(limit > 1) limit = 1;
				if(limit < 0.01) limit = 0;
				volumePercent.text = Math.round(limit * 100) + '%';
				music.volume = limit;
				FlxG.save.data.Volume = limit;
				FlxG.save.flush();
			}
		}else{
			if (touchingBar == 'time'&& music != null) {
				var oldClick = lastHitTimeBar;
				var percent:Float = (FlxG.mouse.x - timeBar.x) / timeBar.width;
				var newPosition:Float = percent * music.length;
				lastHitTimeBar = newPosition;
				var limit:Float = lastHitTimeBar;
				if(limit > music.length) limit = music.length - 45;
				if(limit < 0) limit = 0;
				if(Math.round(limit) != Math.round(oldClick)){
					var oldTime:Float = music.time;
					music.time = limit;
					lyricalIndex = 0;
					Discord.DiscordClient.changePresence('Listening to $playingSong', 'On $playingAlbum', true, music.length - music.time);
				}
			}
		}
	}

	/*function buttonGlow() {
		for (item in uiButtons.members){
			if(FlxG.mouse.overlaps(item) && item.ID == 0){
				item.ID = 1;
				FlxTween.globalManager.cancelTweensOf(item);
				FlxTween.tween(item, {y: FlxG.height - 200}, 0.13, {ease: FlxEase.quartIn});
				FlxTween.color(item, 1, FlxColor.BLACK, FlxColor.LIME);
			}else{
				if(!FlxG.mouse.overlaps(item) && item.ID == 1){
					item.ID = 0;
					FlxTween.globalManager.cancelTweensOf(item);
					FlxTween.color(item, 1, FlxColor.LIME, FlxColor.BLACK);
				}
			}
		}
	}*/

	public function playToggleSfx(select:Bool) {
		if(select)
		FlxG.sound.play('assets/sounds/select.wav');
		else
		FlxG.sound.play('assets/sounds/close.wav');
	}

	public function reloadFolders(reset:Bool = true) {
		albums = [];
		albumIndex = 0;
		for (file in FileSystem.readDirectory("assets/data"))
		{
			albums.push(file);
		}
		trace(FlxG.save.data.lastPlayedAlbum != null && FlxG.save.data.lastPlayedSong != null && reset);
		if (FlxG.save.data.lastPlayedAlbum != null && FlxG.save.data.lastPlayedSong != null && reset){ 
			changeAlbum(0, FlxG.save.data.lastPlayedAlbum);
			curSong = FlxG.save.data.lastPlayedSong;
			songIndex = songList.indexOf(curSong);
			changeSong(false);
		}else{
			curAlbum = albums[0];
			changeAlbum();
		}
		albumDropdown.dataSource = ArrayDataSource.fromArray(albums);
		//DropdownSearch.fullAlbumSearch = albums;
		AssetLoader.getGitHubItem('https://raw.githubusercontent.com/Galactic00/SymphonyPlayer/main/albums-list.txt', (data:String) -> {
			if(data != null){
				var githubAlbums:Array<String> = [];
				for (i in 0...data.split('\n').length){
					if(!FileSystem.exists('assets/data/' + data.split('\n')[i])) githubAlbums.push(data.split('\n')[i]);
				}
				trace(githubAlbums);
				if(githubAlbums.contains(FlxG.save.data.lastSongSuggested)){
					NotificationManager.instance.addNotification({
						title: "The Album You Suggested Was Added!",
						body: "The album: " + FlxG.save.data.lastSongSuggested + " was added!",
						type: NotificationType.Success,
						expiryMs: 10000
					});
					FlxG.save.data.lastSongSuggested = "<null>";
					FlxG.save.flush();
				}
				//githubDropdown.dataSource = ArrayDataSource.fromArray(githubAlbums); broken fr
			}
		});
	}

	public function changeAlbum(change:Int = 0, changePath:String = '') {
		Assets.cache.clear(); // make this a setting later memory usage is crazy high
		if (changePath == ''){
			albumIndex += change;
			if (albumIndex == albums.length) albumIndex = 0;
			if (albumIndex < 0) albumIndex = albums.length -1;
			curAlbum = albums[albumIndex];
		}else{
			curAlbum = changePath;
			albumIndex = albums.indexOf(curAlbum);
		}

		if(!FileSystem.exists('assets/data/$curAlbum')){
			trace(encodeURIComponent('https://raw.githubusercontent.com/Galactic00/SymphonyPlayer/main/albums/$curAlbum'));
			LoadAlbumFromUrl(encodeURIComponent('https://raw.githubusercontent.com/Galactic00/SymphonyPlayer/main/albums/$curAlbum'));
		}else{
			updateAlbumNameText(curAlbum);

			albumCover.loadGraphic(AssetLoader.Image('assets/data/$curAlbum/cover.jpg'));
			albumCover.updateHitbox();

			if(theme == 'blur') updateUI(bg, albumCover, true);
			updateUI(reflection, albumCover, false, albumCover.x, albumCover.y + albumCover.height);

			addSongText();
		}
	}

	public function LoadAlbumFromUrl(path:String) {
		AssetLoader.getGitHubItem(path + '/data.json', (data:String) -> {
			if (data != null) {
				var rawJson = data; 
				var URLjson = cast Json.parse(rawJson);
				curAlbum = URLjson.name;
				Assets.cache.clear(); // make this a setting later memory usage is crazy high
				albumIndex = -1;
				updateAlbumNameText();
				AssetLoader.loadFromURL('$path/cover.jpg', (data:ByteArray) -> {
					var bmpData:BitmapData = BitmapData.fromBytes(data);
					albumCover.loadGraphic(FlxGraphic.fromBitmapData(bmpData));
					albumCover.updateHitbox();
					if(theme == 'blur') updateUI(bg, albumCover, true);
					updateUI(reflection, albumCover, false, albumCover.x, albumCover.y + albumCover.height);
				});
				var songArray:Array<String> = [];
				for (i in 0...URLjson.trackdata.length){
					songArray.push(URLjson.trackdata[i].filename);
				}
				//display names!
				var displayNameArray:Array<String> = [];
				for (i in 0...URLjson.trackdata.length){
					displayNameArray.push(URLjson.trackdata[i].displayname);
				}
				addSongText(songArray, displayNameArray);
			}
		});
	}
	
	public function LoadFromPlayList(playlistName:String) {
		Assets.cache.clear(); // make this a setting later memory usage is crazy high
		curAlbum = playlistName;
		playlistAlbumList = [];
		playlistSongList = [];
		var displayNameList:Array<String> = [];
		for (i in 0...File.getContent('assets/playlists/' + curAlbum + '/data.txt').split('\n').length){
			playlistAlbumList.push(File.getContent('assets/playlists/' + curAlbum + '/data.txt').split('\n')[i].split('/')[0]);
			playlistSongList.push(File.getContent('assets/playlists/' + curAlbum + '/data.txt').split('\n')[i].split('/')[1]);
			displayNameList.push(File.getContent('assets/playlists/' + curAlbum + '/data.txt').split('\n')[i].split('/')[2]);
		}
		albumIndex = -1;
		updateAlbumNameText(curAlbum);
		albumCover.loadGraphic(AssetLoader.Image('assets/playlists/$playlistName/cover.jpg'));
		albumCover.updateHitbox();
		if(theme == 'blur') updateUI(bg, albumCover, true);
		updateUI(reflection, albumCover, false, albumCover.x, albumCover.y + albumCover.height);
		addSongText(playlistSongList, displayNameList);
	}

	public static function cacheNext() { // caches the current and next song
		sys.thread.Thread.create(() -> {
			var cacheIndex:Int = playingList.indexOf(playingSong) + 1;
			if(cacheIndex >= playingList.length) cacheIndex = 0;
			if(!cacheNames.contains(playingList[playingList.indexOf(playingSong) + 1])){
				var cacheName:String = playingList[cacheIndex];
				if(FileSystem.exists('assets/data/$loadAlbum')){
					smartCache.push(Sound.fromFile('assets/data/$loadAlbum/$cacheName/song.ogg'));
					cacheNames.push(cacheName);
					if(smartCache.length > 10) {
						smartCache.shift(); 
						cacheNames.shift();
					}
				}else{
					AssetLoader.loadFromURL(encodeURIComponent('https://raw.githubusercontent.com/Galactic00/SymphonyPlayer/main/albums/$loadAlbum/$cacheName/song.ogg'), (data:ByteArray) -> {
						if(data != null){
							var cacheSound:Sound = new Sound();
							cacheSound.loadCompressedDataFromByteArray(data, data.length);
							smartCache.push(cacheSound);
							cacheNames.push(cacheName);
							if(smartCache.length > 10) {
								smartCache.shift(); 
								cacheNames.shift();
							}
						}
					});
				}
			}
			trace(cacheNames);
		});
	}

	public static function cacheCurrent() { // caches the current and next song
		sys.thread.Thread.create(() -> {
			if(!cacheNames.contains(playingList[playingList.indexOf(playingSong)])){
				if(FileSystem.exists('assets/data/$loadAlbum')){
					smartCache.push(Sound.fromFile('assets/data/$loadAlbum/$playingSong/song.ogg'));
					cacheNames.push(playingSong);
					if(smartCache.length > 10) {
						smartCache.shift(); 
						cacheNames.shift();
					}
				}else{
					AssetLoader.loadFromURL(encodeURIComponent('https://raw.githubusercontent.com/Galactic00/SymphonyPlayer/main/albums/$loadAlbum/$playingSong/song.ogg'), (data:ByteArray) -> {
						if(data != null){
							var cacheSound:Sound = new Sound();
							cacheSound.loadCompressedDataFromByteArray(data, data.length);
							smartCache.push(cacheSound);
							cacheNames.push(playingSong);
							if(smartCache.length > 10) {
								smartCache.shift(); 
								cacheNames.shift();
							}
						}
					});
				}
			}
			trace(cacheNames);
		});
	}

	public function updateUI(sprite:FlxSprite, graphic:FlxSprite, screenCenter:Bool = false, ?x:Float, ?y:Float) {
		sprite.loadGraphicFromSprite(graphic);
		sprite.updateHitbox();
		if (screenCenter) sprite.screenCenter();
		if (x != null) sprite.x = x;
		if (y != null) sprite.y = y;
		if (sprite == bg && theme == 'blur'){ //reapply blur to the bg asset
			blurFrames = FlxFilterFrames.fromFrames(bg.frames, 0, 0, [blurFilter]);
			blurFrames.applyToSprite(bg, false, true);
		}
	}

	public function addSongText(?urlJsonTxt:Array<String>, ?displayList:Array<String>) {
		songList = [];
		var displayNameList:Array<String> = [];
		if(urlJsonTxt == null){
			if(FileSystem.exists('assets/data/$curAlbum/data.json')){
				var rawJson = File.getContent('assets/data/$curAlbum/data.json');
				var json = cast Json.parse(rawJson);
				for (i in 0...json.trackdata.length){
					songList.push(json.trackdata[i].filename);
					displayNameList.push(json.trackdata[i].displayname);
				}
			}else{
				for (file in FileSystem.readDirectory('assets/data/$curAlbum')) if(file != 'cover.jpg') songList.push(file);
			}
		}else{
			for (i in 0...urlJsonTxt.length){
				songList.push(urlJsonTxt[i]);
			}
			if(displayList != null) displayNameList = displayList;
		}
		for (item in songTxt.members){
			item.kill();
			item.destroy();
		}
		songTxt.clear();
		var sillyList:Array<String> = songList;
		if(displayNameList.length > 0) sillyList = displayNameList;
		for (i in 0...sillyList.length){
			var song:FlxText = new FlxText((FlxG.width / 2) + 25, 15 + (75 * i), sillyList[i]);
			song.setFormat("Gotham Medium.otf", 40, FlxColor.WHITE, LEFT, FlxTextBorderStyle.SHADOW, FlxColor.BLACK);
			song.antialiasing = true;
			song.ID = i;
			songTxt.add(song);
			songTxt.cameras = [songCam];
		}
		songCam.height = 100 * songList.length;
		songIndex = 0;
		curSong = songList[0];
		changeSong(false);
	}

	public function changeSong(?change:Int, camEnabled:Bool = true) {
		if(change != null && songList.length > 1 && camEnabled) FlxG.sound.play('assets/sounds/scroll.wav', 0.4);
		if(change != null) songIndex += change;
		if(songIndex == songList.length) songIndex = 0;
		if(songIndex < 0) songIndex = songList.length -1;
		curSong = songList[songIndex];
		for (item in songTxt.members)
		{
			if(playingSong == songList[item.ID] && playingAlbum == curAlbum){
				item.color = FlxColor.BLUE;
				item.underline = true;
			}else{
				if(queue.contains(curAlbum + '<|>' + songList[item.ID])) 
					item.color = FlxColor.PURPLE;
				else
					item.color = FlxColor.WHITE;
					
				item.underline = false;
			}

			if(songIndex == item.ID){
				item.color = FlxColor.GREEN;
				if(songsTween != null) {songsTween.cancel();}
				if(camEnabled){
						songsTween = FlxTween.tween(songCam, {y: item.ID * -75}, 0.1, {onComplete: function(twn:FlxTween) {songsTween = null;}});
				}else{
					songCam.y = item.ID * -75;
				}
			}
		}
	}
	
	public function downloadAlbum(coolAlbumName:String, coolSongList:Array<String>) {
		var downloadCounter:Int = 0;
		var failedDownloads:Int = 0;
		NotificationManager.instance.addNotification({
            title: "Attempting to download album",
            body: "Might take a while. Don't close the game until you get the finished pop-up!",
			type: NotificationType.Info,
			expiryMs: 5000
        });
		FileSystem.createDirectory('assets/data/' + coolAlbumName);
		var thing:String = 'https://raw.githubusercontent.com/Galactic00/SymphonyPlayer/main/albums/' + coolAlbumName + '/' + 'cover.jpg';
		AssetLoader.downloadFile(encodeURIComponent(thing), 'assets/data/' + coolAlbumName + '/' + '/cover.jpg');
		var thing:String = 'https://raw.githubusercontent.com/Galactic00/SymphonyPlayer/main/albums/' + coolAlbumName + '/' + 'data.json';
		AssetLoader.downloadFile(encodeURIComponent(thing), 'assets/data/' + coolAlbumName + '/' + '/data.json');
		for (i in 0...coolSongList.length){
			var finalString:String = encodeURIComponent('https://raw.githubusercontent.com/Galactic00/SymphonyPlayer/main/albums/' + coolAlbumName + '/' + coolSongList[i] + '/song.ogg');
			FileSystem.createDirectory('assets/data/' + coolAlbumName + '/' + coolSongList[i]);			
			AssetLoader.downloadFile(finalString, 'assets/data/' + coolAlbumName + '/' + coolSongList[i] + '/song.ogg', false, (idek:Bool) -> {
				downloadCounter ++;
				if(!idek) failedDownloads ++;
				if(downloadCounter == coolSongList.length){
					if(failedDownloads > 0){
						NotificationManager.instance.addNotification({
							title: "Album Done Downloading.",
							body: 'The Album: ' + coolAlbumName + ' Had $failedDownloads failed downloads.\n You might want to delete and try to redownload the album.',
							type: NotificationType.Warning,
							expiryMs: 5000
						});
					}else{
						NotificationManager.instance.addNotification({
							title: "Done Downloading Album!",
							body: 'Finished downloading album: ' + coolAlbumName + '!',
							type: NotificationType.Success,
							expiryMs: 5000
						});					
					}
					reloadFolders(false);
				}
			});
		}
	}

	public function removeAlbum(coolAlbumName:String, deletePath:String = 'assets/data/') {
		trace(deletePath + coolAlbumName);
		if(coolAlbumName == curAlbum) changeAlbum(1);
		try {
			// Delete the contents of the directory
			var directoryPath:String = deletePath + coolAlbumName;
			var files = FileSystem.readDirectory(directoryPath);
			for (file in files) {
				var filePath = '$directoryPath/$file';
				if (FileSystem.isDirectory(filePath)) {
					// If the file is a directory, recursively delete its contents
					deleteDirectoryContents(filePath);
					FileSystem.deleteDirectory(filePath);
				} else {
					// If the file is a regular file, delete it
					FileSystem.deleteFile(filePath);
				}
			}

			// Delete the directory
			FileSystem.deleteDirectory(directoryPath);
		} catch (e:Dynamic) {
			trace('Error deleting directory: $e');
		}
		reloadFolders(false);
	}

	private function deleteDirectoryContents(directoryPath:String) {
		var files = FileSystem.readDirectory(directoryPath);
		for (file in files) {
			var filePath = '$directoryPath/$file';
			if (FileSystem.isDirectory(filePath)) {
				// If the file is a directory, recursively delete its contents
				deleteDirectoryContents(filePath);
				FileSystem.deleteDirectory(filePath);
			} else {
				// If the file is a regular file, delete it
				FileSystem.deleteFile(filePath);
			}
		}
	}
    public static function encodeURIComponent(str:String):String {
		var newStr:String = str;
		var unsafeChars = ["%",    " ",   "#",   "$",   "&"];
		var replaceChars = ["%25", "%20", "%23", "%24", "%26"];
		for (i in 0...unsafeChars.length){
			if(newStr.contains(unsafeChars[i])) newStr = newStr.replace(unsafeChars[i], replaceChars[i]);
		}
		trace("finished url string = " + newStr);
		trace("old url string = " + str);
		return newStr;
	}

	public function mouseTest() {
		var oldselected = curSong;
		var optionHeight = FlxG.height / songList.length; // Height of each song option

		for (txt in songTxt.members) {
			var topBound = optionHeight * txt.ID; // Top boundary of the current option
			var bottomBound = topBound + optionHeight; // Bottom boundary of the current option

			// Check if the mouse Y position is within the current option's boundaries
			if (FlxG.mouse.y > topBound && FlxG.mouse.y < bottomBound) {
				songIndex = txt.ID;
				curSong = songList[songIndex];
			}
		}

		if (oldselected != curSong) {
			FlxG.sound.play('assets/sounds/scroll.wav', 0.4);
			changeSong();
		}
	}

	function syncTime() {
		if(music != null && !paused){
			time = (music.time/music.length) * 100;
			timeIn.text = FlxStringUtil.formatTime(Math.floor(music.time / 1000), false);
		}
	}

	public function formatFolder(folderPath:String):Void {
		var coolAlbumName:String = 'no name';
		var author:String = '';
		var date:String = '';
		for (auth in FileSystem.readDirectory(folderPath)) {
			author = auth;
			trace(author);
			for (fileDate in FileSystem.readDirectory('$folderPath/$auth')) {
				date = fileDate;
				var formattedDate:String = AssetLoader.FormatAsDate(fileDate.split('-')[1]) + ' ' + AssetLoader.RemoveFirst0(fileDate.split('-')[2]) + ', ' + fileDate.split('-')[0];
				for (file in FileSystem.readDirectory('$folderPath/$auth/$date')) {
					coolAlbumName = checkForSymbols(file);
					trace(coolAlbumName);
					trace(folderPath + '/' + auth + '/' );
					var trackOrder:Array<DataFormat> = [];
					FileSystem.createDirectory('assets/data/' + coolAlbumName);
					File.copy(folderPath + '/' + auth + '/' + date + '/' + file + '/cover.jpg', 'assets/data/' + coolAlbumName + '/cover.jpg');
					var songFiles:Array<String> = [];
					for (songFile in FileSystem.readDirectory(folderPath + '/' + auth + '/' + date + '/' + file)) {
						if (!StringTools.endsWith(songFile, '.txt') && !StringTools.endsWith(songFile, '.lrc') && !StringTools.endsWith(songFile, '.jpg')) songFiles.push(songFile);
					}
					
					// Sort song files by track number
					songFiles.sort(function(a:String, b:String):Int {
						var trackNumA:Int = Std.parseInt(a.split('.')[0]);
						var trackNumB:Int = Std.parseInt(b.split('.')[0]);
						return trackNumA - trackNumB;
					});

					for (songFile in songFiles) {
						var autoCreds:Array<String> = [];
						var removeTrackNum:String = songFile.substr(songFile.indexOf('.') + 1);
						if(StringTools.contains(removeTrackNum, " .creds. ")) { //auto add credits
							trace(removeTrackNum.split(" .creds. ")[1]);
							trace(removeTrackNum.split(" .creds. ")[1].split(', '));
							autoCreds = removeTrackNum.split(".ogg")[0].split(" .creds. ")[1].split(', ');
							removeTrackNum = removeTrackNum.split(" .creds. ")[0];
						}
						var splitName:String = checkForSymbols(removeTrackNum.split('.ogg')[0]);					
						var displayNameThing:String = removeTrackNum.split('.ogg')[0];
						if(displayNameThing.startsWith(' ')) displayNameThing = displayNameThing.substring(1, displayNameThing.length);
						var spaceRemoved:String = splitName;
						if(splitName.startsWith(" ")) spaceRemoved = splitName.substring(1, splitName.length);
						trace(spaceRemoved);
						FileSystem.createDirectory('assets/data/' + coolAlbumName + '/' + spaceRemoved);
						var formattedData:DataFormat = {
							filename: spaceRemoved,
							displayname: displayNameThing,
							credits: autoCreds
						};
						trackOrder.push(formattedData);
						File.copy(folderPath + '/' + auth + '/' + date + '/' + file + '/' + songFile, 'assets/data/' + coolAlbumName + '/' + spaceRemoved + '/song.ogg');
						if (FileSystem.exists(folderPath + '/' + auth + '/' + date + '/' + file + '/' + songFile.split('.ogg')[0] + '.lrc')) {
							File.copy(folderPath + '/' + auth + '/' + date + '/' + file + '/' + songFile.split('.ogg')[0] + '.lrc', 'assets/data/' + coolAlbumName + '/' + spaceRemoved + '/lyrics.txt');
						}
						if (FileSystem.exists(folderPath + '/' + auth + '/' + date + '/' + file + '/' + songFile.split('.ogg')[0] + '.txt')) {
							File.copy(folderPath + '/' + auth + '/' + date + '/' + file + '/' + songFile.split('.ogg')[0] + '.txt', 'assets/data/' + coolAlbumName + '/' + spaceRemoved + '/lyrics.txt');
						}
					}
					
					var json = {
						"name": coolAlbumName,
						"genre": '',
						"mainauthor": author,
						"date": formattedDate,
						"quality": 'ogg/HD',
						"extramaincreds": [''],
						"trackdata": trackOrder,
					};
					var data:String = Json.stringify(json, "\t");
					if (data.length > 0) File.saveContent('assets/data/' + coolAlbumName + '/data.json', data);
				}
			}
		}
		reloadFolders(false);
	}

	public function checkForSymbols(string:String) {
	var supportedChars:Array<String> = [' ', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v','w', 'x', 'y', 'z', 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V','W', 'X', 'Y', 'Z', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '!', '@', '#', '$', '%', '^', '&', '(',	')', '-', '=', '_', '+', '{',	'}', "'", ',', '`', '~',];
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

	override function onFocusLost():Void
	{
		trace('fps change');
		windowFocus = false;
		FlxG.updateFramerate = 15;
		FlxG.drawFramerate = 15;
	}

	override function onFocus():Void
	{
		trace('fps change');
		windowFocus = true;
		FlxG.updateFramerate = 60;
		FlxG.drawFramerate = 60;
	}
}
