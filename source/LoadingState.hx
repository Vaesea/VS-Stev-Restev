package;

import flixel.FlxSprite;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.util.FlxTimer;
import haxe.io.Path;
import lime.app.Future;
import lime.app.Promise;
import lime.utils.AssetLibrary;
import lime.utils.AssetManifest;
import lime.utils.Assets as LimeAssets;
import openfl.utils.Assets;

/**
* State used to load between certain states.
*/
class LoadingState extends MusicBeatState
{
	inline static final MIN_TIME = 1.0;

	// Browsers will load create(), you can make your song load a custom directory there
	// If you're compiling to desktop (or something that doesn't use NO_PRELOAD_ALL), search for getNextState instead
	// I'd recommend doing it on both actually lol
	
	// TO DO: Make this easier
	
	var target:FlxState;
	var stopMusic = false;
	var directory:String;
	public static var globeTrans:Bool = true;
	public static var silentLoading:Bool = false;
	var callbacks:MultiCallback;
	var targetShit:Float = 0;

	function new(target:FlxState, stopMusic:Bool, directory:String)
	{
		super();
		this.target = target;
		this.stopMusic = stopMusic;
		this.directory = directory;
	}
	
	var loadBar:FlxSprite;
	var callbackTxt:FlxText;
	var loadingTxt:FlxSprite;
	var loadingCirc:FlxSprite;
	var loadingCircSpeed = FlxG.random.int(50,200);
	var tipTxt:FlxText;
	var tips:Array<String> = [
		"If you're stuck on this screen for longer than 10 seconds, your pc sucks or the game crashed.\nThe Latter is most likely, not trying to insult your PC.\n(Your PC sucks)",
		"ERROR 404 - NOT FOUND",
		"Press the keys to win. They are customizable in the Options Menu.",
		"You have a total of 2 health. Let it reach 0 and you will be Blueballed.",
		"Uh oh! Your tryin to kiss ur hot girlfriend, but her MEAN and EVIL dad is trying to KILL you! \nHe's an ex-rockstar, the only way to get to his heart? The power of music...",
		"sgrdnfiuhgdzsbngzsdbnhgbsfsubdfbngjkldghszznsfnsfihebsobsrfnesl;sbfse;ikfbsenselkfsedlkfsnefewsnriogrheioswfdjnsweiofehwa\nwhat was i doing again",
		"The Freeze modifer's penalty lasts for 2 seconds.",
		"The Poison modifer's penalty stacks with every miss.",
		"The Flip modifer flips your strums AND the note patterns!",
		"Quartiz.",
		"VS Stev is made by Your Average FNF Pro.",
		"Play SuperTux",
		"oh my fucking god",
		"waht the fuck",
		"what the fuck?",
		"thats a crime against humanity",
		"what",
		"oh no its returning null NOOOO",
		"//this is the only way this terribleness will work. Why? Has i ever?",
		"making bugs"
	];
	var silent:Bool = false;
	
	override function create()
	{
		Paths.clearUnusedCache();
		silent = silentLoading;
		silentLoading = false;

		flixel.addons.transition.FlxTransitionableState.skipNextTransIn = false;
		flixel.addons.transition.FlxTransitionableState.skipNextTransOut = false;
		if (!globeTrans) {
			flixel.addons.transition.FlxTransitionableState.skipNextTransIn = true;
			flixel.addons.transition.FlxTransitionableState.skipNextTransOut = true;
		}
		globeTrans = true;

		if (!silent) {
			var loading:FlxSprite = new FlxSprite(0, 0).loadGraphic(Paths.image('loadingscreen'));
			loading.active = false;
			loading.setGraphicSize(0, FlxG.height);
			loading.updateHitbox();
			loading.x = FlxG.width - loading.width;
			add(loading);
	
			loadingTxt = new FlxSprite(100, 0).loadGraphic(Paths.image('loading'));
			loadingTxt.scale.set(0.45,0.45);
			loadingTxt.updateHitbox();
			loadingTxt.screenCenter(Y);
			loadingTxt.active = false;
			add(loadingTxt);
			flixel.tweens.FlxTween.angle(loadingTxt, -5, 5, 1, {ease:flixel.tweens.FlxEase.quadInOut, type:flixel.tweens.FlxTween.FlxTweenType.PINGPONG});
			flixel.tweens.FlxTween.tween(loadingTxt, {"scale.x": 0.47, "scale.y": 0.47}, 0.5, {ease:flixel.tweens.FlxEase.quadInOut, type:flixel.tweens.FlxTween.FlxTweenType.PINGPONG});
	
			loadingCirc = new FlxSprite(loadingTxt.x, 0).loadGraphic(Paths.image('loadingicon'));
			loadingCirc.x += loadingTxt.width;
			loadingCirc.scale.set(0.45,0.45);
			loadingCirc.updateHitbox();
			loadingCirc.screenCenter(Y);
			loadingCirc.active = false;
			add(loadingCirc);
	
			loadBar = new FlxSprite(10, 0).makeGraphic(10, FlxG.height - 150, 0xffffffff);
			loadBar.screenCenter(Y);
			loadBar.color = 0xffff00ff;
			loadBar.active = false;
			add(loadBar);
	
			final loadColors:Array<flixel.util.FlxColor> = [0xffff0000, 0xffff7b00, 0xffffff00, 0xff00ff00, 0xff0000ff, 0xffff00ff];
			var loadIncrement:Int = 0;
			clrBarTwn(loadIncrement, loadBar, loadColors, 1);
	
			callbackTxt = new FlxText(30, 0, 0, "");
			callbackTxt.scrollFactor.set();
			callbackTxt.setFormat("VCR OSD Mono", 16, 0xffffffff, CENTER);
			callbackTxt.screenCenter(Y);
			callbackTxt.active = false;
			add(callbackTxt);
	
			tipTxt = new FlxText(0, FlxG.height - 48, 0, tips[FlxG.random.int(0,tips.length-1)]);
			tipTxt.scrollFactor.set();
			tipTxt.setFormat("VCR OSD Mono", 16, 0xffffffff, LEFT);
			tipTxt.active = false;
			add(tipTxt);
	
			var timer = new FlxTimer().start(4, function(tmr:FlxTimer) {
				tipTxt.text = tips[FlxG.random.int(0,tips.length-1)];
			}, 0);
		}
		
		initSongsManifest().onComplete
		(
			function (lib)
			{
				callbacks = new MultiCallback(onLoad);
				var introComplete = callbacks.add("introComplete");
				checkLibrary("shared");
				if(directory != null && directory.length > 0 && directory != 'shared') {
					checkLibrary(directory);
				}

				var fadeTime = 0.5;
				FlxG.camera.fade(FlxG.camera.bgColor, fadeTime, true);
				new FlxTimer().start(fadeTime + MIN_TIME, function(_) introComplete());
			}
		);
	}
	
	function checkLoadSong(path:String)
	{
		if (!Assets.cache.hasSound(path))
		{
			var library = Assets.getLibrary("songs");
			final symbolPath = path.split(":").pop();
			var callback = callbacks.add("song:" + path);
			Assets.loadSound(path).onComplete(function (_) { callback(); });
		}
	}
	
	function checkLibrary(library:String) {
		//trace(Assets.hasLibrary(library));
		if (Assets.getLibrary(library) == null)
		{
			@:privateAccess
			if (!LimeAssets.libraryPaths.exists(library))
				throw "Missing library: " + library;

			var callback = callbacks.add("library:" + library);
			Assets.loadLibrary(library).onComplete(function (_) { callback(); });
		}
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (silent) return;

		loadingCirc.angle += elapsed*loadingCircSpeed;

		if(callbacks != null) {
			targetShit = FlxMath.remapToRange(callbacks.numRemaining / callbacks.length, 1, 0, 0, 1);
			loadBar.scale.y += 0.5 * (targetShit - loadBar.scale.y);
			callbackTxt.text = (callbacks.length - callbacks.numRemaining) + '/' + callbacks.length;
		}
	}

	function clrBarTwn(incrementor:Int, sprite:FlxSprite, clrArray:Array<flixel.util.FlxColor>, duration:Int) {
		flixel.tweens.FlxTween.color(sprite, duration, sprite.color, clrArray[incrementor], {onComplete: function(_) {
			incrementor++;
			if (incrementor > 5) incrementor = 0;
			clrBarTwn(incrementor, sprite, clrArray, duration);
		}});
	}
	
	inline function onLoad()
	{
		if (stopMusic && FlxG.sound.music != null)
			FlxG.sound.music.stop();
			
		MusicBeatState.switchState(target);
	}

	inline static function getSongPath()
	{
		return Paths.inst(PlayState.SONG.header.song);
	}
	
	inline static function getVocalPath()
	{
		return Paths.voices(PlayState.SONG.header.song);
	}
	
	inline static public function loadAndSwitchState(target:FlxState, stopMusic = false)
	{
		MusicBeatState.switchState(getNextState(target, stopMusic));
	}
	
	static function getNextState(target:FlxState, stopMusic = false):FlxState
	{
		var directory:String = 'shared';
		var weekDir:String = StageData.forceNextDirectory;
		StageData.forceNextDirectory = null;

		if(weekDir != null && weekDir.length > 0 && weekDir != '') directory = weekDir;

		Paths.setCurrentLevel(directory);
		//trace('Setting asset folder to ' + directory);

		#if NO_PRELOAD_ALL
		var loaded:Bool = false;
		if (PlayState.SONG != null) {
			loaded = isSoundLoaded(getSongPath()) && (!PlayState.SONG.header.needsVoices || isSoundLoaded(getVocalPath())) && isLibraryLoaded("shared") && isLibraryLoaded(directory);
		}
		
		if (!loaded)
			return new LoadingState(target, stopMusic, directory);
		#end
		if (stopMusic && FlxG.sound.music != null)
			FlxG.sound.music.stop();
		
		return target;
	}
	
	#if NO_PRELOAD_ALL
	inline static function isSoundLoaded(path:String):Bool
	{
		return Assets.cache.hasSound(path);
	}
	
	inline static function isLibraryLoaded(library:String):Bool
	{
		return Assets.getLibrary(library) != null;
	}
	#end
	
	override function destroy()
	{
		super.destroy();
		callbacks = null;
	}
	
	static function initSongsManifest()
	{
		var id = "songs";
		var promise = new Promise<AssetLibrary>();

		var library = LimeAssets.getLibrary(id);

		if (library != null)
		{
			return Future.withValue(library);
		}

		var path = id;
		var rootPath = null;

		@:privateAccess
		var libraryPaths = LimeAssets.libraryPaths;
		if (libraryPaths.exists(id))
		{
			path = libraryPaths[id];
			rootPath = Path.directory(path);
		}
		else
		{
			if (StringTools.endsWith(path, ".bundle"))
			{
				rootPath = path;
				path += "/library.json";
			}
			else
			{
				rootPath = Path.directory(path);
			}
			@:privateAccess
			path = LimeAssets.__cacheBreak(path);
		}

		AssetManifest.loadFromFile(path, rootPath).onComplete(function(manifest)
		{
			if (manifest == null)
			{
				promise.error("Cannot parse asset manifest for library \"" + id + "\"");
				return;
			}

			var library = AssetLibrary.fromManifest(manifest);

			if (library == null)
			{
				promise.error("Cannot open library \"" + id + "\"");
			}
			else
			{
				@:privateAccess
				LimeAssets.libraries.set(id, library);
				library.onChange.add(LimeAssets.onChange.dispatch);
				promise.completeWith(Future.withValue(library));
			}
		}).onError(function(_)
		{
			promise.error("There is no asset library with an ID of \"" + id + "\"");
		});

		return promise.future;
	}
}

class MultiCallback
{
	public var callback:Void->Void;
	public var logId:String = null;
	public var length(default, null) = 0;
	public var numRemaining(default, null) = 0;
	
	var unfired = new Map<String, Void->Void>();
	var fired = new Array<String>();
	
	public function new (callback:Void->Void, logId:String = null)
	{
		this.callback = callback;
		this.logId = logId;
	}
	
	public function add(id = "untitled")
	{
		id = '$length:$id';
		length++;
		numRemaining++;
		var func:Void->Void = null;
		func = function ()
		{
			if (unfired.exists(id))
			{
				unfired.remove(id);
				fired.push(id);
				numRemaining--;
				
				if (logId != null)
					log('fired $id, $numRemaining remaining');
				
				if (numRemaining == 0)
				{
					if (logId != null)
						log('all callbacks fired');
					callback();
				}
			}
			else
				log('already fired $id');
		}
		unfired[id] = func;
		return func;
	}
	
	inline function log(msg):Void
	{
		if (logId != null)
		{
			trace('$logId: $msg');
		}
	}
	
	public function getFired() return fired.copy();
	public function getUnfired() return [for (id in unfired.keys()) id];
}
