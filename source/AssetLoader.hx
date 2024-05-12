package;

import flixel.FlxG;
import flixel.FlxBasic;
import sys.FileSystem;
import sys.io.Process;
import sys.io.File;
import sys.io.FileOutput;
import openfl.system.System;
import flash.media.Sound;
import flixel.sound.FlxSound;
import haxe.ui.notifications.NotificationType;
import haxe.ui.notifications.NotificationManager;
import flixel.graphics.FlxGraphic;
import flash.display.BitmapData;
import openfl.events.*;
import openfl.net.*;
import lime.app.Application;
import openfl.utils.ByteArray;


using StringTools;

class AssetLoader {
static var token:String = "Removed For Legal Reasons";

    public static inline function FormatAsDate(month:String):String {
		switch (month)
		{
	    	case '12':
                return "December";
	    	case '11':
                return "November";
	    	case '10':
                return "October";
	    	case '09':
                return "September";
	    	case '08':
                return "August";
	    	case '07':
                return "July";
	    	case '06':
                return "June";
	    	case '05':
                return "May";
	    	case '04':
                return "April";
	    	case '03':
                return "March";
	    	case '02':
                return "February";
            default:
                return "January";        
        }
    }

    public static inline function RemoveFirst0(date:String):String {
        var removed0:String = date;
        if(removed0.startsWith('0')) removed0 = removed0.split('0')[1];
        return removed0;
    }

    public static inline function Image(path:String):FlxGraphic {
        var asset:FlxGraphic = null;
            if (FileSystem.exists(path)) {
                asset = FlxGraphic.fromBitmapData(BitmapData.fromFile(path));
            } else {
                trace('Image $path not found');
                asset = FlxG.bitmap.add('assets/images/cover.jpg', false, 'assets/images/cover.jpg');
            }
        return asset;
    }

    public static inline function downloadFile(url:String, savePath:String, updating:Bool = false, ?onComplete:Bool -> Void):Void {
        var downloadStream = new URLStream();
        var fileOutput:FileOutput = File.write(savePath, true);

        var request = new URLRequest(url);
        request.requestHeaders.push(new URLRequestHeader("Authorization", "token " + token));

        downloadStream.addEventListener(IOErrorEvent.IO_ERROR, function(e) {
            trace("Error downloading file:", e);
            fileOutput.close();
			if(updating){
				FlxG.save.data.SymphonyUpdated = false;
				FlxG.save.flush();
			}
            NotificationManager.instance.addNotification({
                title: "Error!!!",
                body: 'Error downloading file: ' + url,
                type: NotificationType.Error,
                expiryMs: -1
            });
            if(onComplete != null){
                trace("done.");
                onComplete(true);
            }
        });

        downloadStream.addEventListener(Event.COMPLETE, function(e) {
            var data:ByteArray = new ByteArray();
            downloadStream.readBytes(data, 0, downloadStream.bytesAvailable);
            fileOutput.writeBytes(data, 0, data.length);
            fileOutput.flush();
            fileOutput.close();
            downloadStream.close();
            trace("File downloaded successfully.");
            if(onComplete != null){
                trace("done.");
                onComplete(true);
            }
			if(updating){
				new Process('start /B Cache.exe update', null);
				System.exit(0);
			}
        });

        downloadStream.load(request);
    }
	public static inline function getGitHubItem(url:String, onComplete:String -> Void):Void {
        var url = url;
        var http = new haxe.Http(url);
        http.setHeader("Authorization", "token " + token);
        http.onData = function(data) {
            onComplete(data);
        }
        http.onError = function(error) {
            trace("Error:", error);
			onComplete(null);
        }
        http.request();
	}

    public static inline function loadFromURL(url:String, onComplete:ByteArray -> Void):Void {
        var downloadStream = new URLStream();
        var request = new URLRequest(url);
        request.requestHeaders.push(new URLRequestHeader("Authorization", "token " + token));

        downloadStream.addEventListener(IOErrorEvent.IO_ERROR, function(e) {
            trace("Error loading file:", e);
            onComplete(null);
        });

        downloadStream.addEventListener(Event.COMPLETE, function(e) {
            var data:ByteArray = new ByteArray();
            downloadStream.readBytes(data, 0, downloadStream.bytesAvailable);

            downloadStream.close();
            trace("File loaded successfully.");
            onComplete(data);
            PlayState.alrTried = false;
        });

        downloadStream.load(request);
    }
}