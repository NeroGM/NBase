package nb;

using nb.ext.ArrayExt;
using nb.ext.PointExt;
import haxe.ds.Map;
import hxd.Event.EventKind as EK;
import nb.Key;
#if sys
import sys.FileSystem as FS;
#end

/**
 * It's in charge of calling the `update` functions of NBase's
 * classes and instances and contains some useful functions.
 *
 * @since 0.1.0
 **/
class Manager {
	/** The associated `hxd.App` instance. **/
	public static var app(default, null):hxd.App = null;
	
	/** The `nb.Object` instances to be updated. **/
	private static final updateQueue:Array<Object> = [];
	/** The `nb.Scene` instances to be updated. **/
	private static final sceneUpdateQueue:Array<Scene> = [];
	/** The `nb.Interactive` instances to be updated. **/
	private static final interUpdateQueue:Array<Interactive> = [];
	private static var eventJustTriggered:Bool = false;
	
	/** The window size. **/
	public static var windowSize(default, null):{w:Int, h:Int} = null;
	
	/** Contains all the scenes active, mapped to their name at creation. **/
	public static final scenes:Map<String, Scene> = [];
	/** All `nb.Scene`s classes in the project's "src/scenes" folder. **/
	public static final sceneClasses = Macros.makeScenes();
	/** The current/main scene. **/
	public static var currentScene(default, null):Scene = null;
	/** The current/main scene name. **/
	public static var currentSceneName(default, null):String = null;
	/** The scene's main camera. **/
	public static var mainCamera(default, null):Camera = null;
	
	/** All `nb.Object`s instances active. **/
	public static final nbObjects:Array<Object> = [];

	/** Time elapsed modifier. At `0.5`, `dt` is halved. **/
	public static var speed:Float = 1;
	/** If `true`, most classes and instances won't be updated. **/
	public static var pause:Bool = false;
	/** If `pause` is set to `true`, classes and instances will still be updated for this amount of frames. **/
	public static var nextFrames:Int = 0;

	/** Whether this class is initialised. **/
	private static var initialised:Bool = false;

	/** A shortcut to the `nb.fs.NFileSystem` made at the start of the application. **/
	public static var neroFS:nb.fs.NFileSystem;

	/** All `nb.Scene`s instances active. **/
	public static var createdScenes:Array<Scene> = [];

	/** Whether this class should use traces. `true` by default if compiler flag `debug` is defined. **/
	public static var logging:Bool = #if debug true #else false #end;

	public static var spaces:Array<nb.phys.Space> = [];
	
	/** Initializes this class. It needs to be done once before being used and have `neroFS` set. **/
	public static function init(app:hxd.App, ?w:Int=300, ?h:Int=300, onFinished:Void->Void) {
		if (initialised) return;

		Manager.app = app;

		windowSize = {w:w,h:h};

		var f:Array<nb.fs.NFileSystem.NFileEntry>->Void = (_) -> {  
			nb.ResManager.init(() -> {
				Timer.addDelayedThread((_) -> {
					Window.init();
					
					currentScene = new nb.Scene();
					currentSceneName = "s2d";
					mainCamera = currentScene.cam;
					scenes.set("s2d", currentScene);
					currentScene.onFirstLoad();
					currentScene.addBgInteractive();
				
					app.setScene(currentScene);
					initWindowEventTarget();
					
					initialised = true;					
					onFinished();
				});
			});
		}

		Manager.neroFS.loadResFromPaths(["defaultUI/"],null,f);
	}
	
	/** Adds an `nb.Object` instance to the update queue. **/
	public static function addObjectUpdate(obj:Object, pos:Int=-1, force:Bool=false) {
		if (obj.nUpdateQueue > 0 && !force) return;
		obj.nUpdateQueue++;
		updateQueue.insert(pos, obj);
	}
	
	/** Adds an `nb.Scene` instance to the update queue. **/
	public static function addSceneUpdate(s:Scene, pos:Int=-1) sceneUpdateQueue.insert(pos, s);
	
	/** Adds an `nb.Interactive` instance to the update queue. **/
	public static function addInteractiveUpdate(i:Interactive, pos:Int=-1) interUpdateQueue.insert(pos, i);
	
	/** Removes an `nb.Object` instance from the update queue. **/
	public static function removeObjectUpdate(obj:Object) {
		if(updateQueue.remove(obj)) obj.nUpdateQueue--;
	}
	
	/**
	 * Creates a scene.
	 *
	 * @param sceneClass The class of the `nb.Scene` to create.
	 * @param name A unique name the `nb.Scene` instance will be mapped to in `scenes`.
	 * It is different from the `nb.Scene`'s object name which doesn't have to be unique.
	 * @param args Parameters to pass to the `nb.Scene` instance at creation.
	 * @return The created `nb.Scene` instance.
	 **/
	public static function createScene(sceneClass:Class<Scene>, ?name:String = "unnamed", ?args:Array<Dynamic>):Scene {
		var i:Int = 0;
		var newName:Null<String> = null;
		while (scenes.exists(name)) {
			newName = name + (++i);
		}
		if (newName != null) { 
			if (logging) trace("Duplicate scene name '"+name+"' changed to '"+newName+"'.");
			name = newName;
		}

		if (logging) haxe.Log.trace('----- CREATING SCENE : $sceneClass($name) -----', null);
		var s:Scene = Type.createInstance(sceneClass, args == null ? [] : args);
		scenes.set(name, s);
		if (logging) haxe.Log.trace('----- CREATED -----', null);
		return s;
	}
	
	/**
	 * Changes the displayed scene.
	 * 
	 * @param name Unique name of the scene to be displayed, the one given at creation.
	 * @param disposeScene Whether the current scene displayed should be disposed.
	 * @return The newly displayed `nb.Scene` instance. If `null` no scene change was made.
	 **/
	public static function changeScene(name:String, ?disposeScene:Bool = false):Scene {
		var s:Scene = scenes.get(name);
		if (s == null) {
		 	if (logging) trace("There is no " + name + " scene.");
			return null;
		} else if (s == Manager.currentScene) {
			if (logging) trace("You are already on scene " + name + ".");
			return null;
		}
		if (disposeScene) {
			scenes.remove(currentSceneName);
			if (logging) trace("Scene disposed : " + currentSceneName);
		}
		
		var newMainCamera = s.cam;
		for (o in mainCamera.objects.copy()) if (o.persistent) {
			mainCamera.objects.remove(o);
			newMainCamera.reAdd(o.o,o);
		}

		mainCamera = newMainCamera;
		
		currentScene.onUnfocus();
		app.setScene(s, disposeScene);
		currentScene = s;
		currentSceneName = name;
		
		if (!s.firstLoaded) s.onFirstLoad();
		s.onFocus();

		if (logging) trace("Scene loaded : " + name);

		return currentScene;
	}
	
	/** Recreates the current scene and switches to it, disposing the old one. **/
	public static function resetScene() {
		createScene(Type.getClass(currentScene), currentSceneName);
		changeScene(currentSceneName, true);
		scenes.set(currentSceneName, currentScene);
	}
	
	/** The function that updates everything. **/
	public static function update(dt:Float) {
		#if (hlsdl || hldx) if (!eventJustTriggered && currentScene != null) @:privateAccess currentScene.additionalInteractivesCheck(); #end
		Timer.threadUpdate(dt);

		if (!initialised) return;

		if (neroFS != null) neroFS.update(dt);

		if (pause) {
			if (nextFrames <= 0) return;
			nextFrames--;
		}

		dt *= speed;

		Timer.update(dt);
		nb.Tween.update(dt);
		
		for (s in createdScenes) {
			if (s == currentScene) {
				s.visibleAreas = [new h2d.col.Bounds()];
				var ratioX = Manager.app.engine.width/s.cam.size.w;
				var ratioY = Manager.app.engine.height/s.cam.size.h;
				s.visibleAreas[0].set(-s.x*s.cam.zoom/ratioX,-s.y*s.cam.zoom/ratioY,s.width*s.cam.zoom/ratioX,s.height*s.cam.zoom/ratioY);
			} else s.visibleAreas = [];
		}
		var checkedScenes:Array<Scene> = new Array();
		for (ss in currentScene.subScenes) {
			ss.updateSceneVisibleArea();
			if (!checkedScenes.contains(ss.scene)) for (ss in ss.scene.subScenes) ss.updateSceneVisibleArea();
		}

		for (obj in nbObjects) obj.mandatoryUpdate(dt);
		for (obj in updateQueue) obj.update(dt);
		for (s in sceneUpdateQueue) s.update(dt);
		for (s in scenes) s.mandatoryUpdate(dt);
		for (i in interUpdateQueue) i.update(dt);
		
		if (Key.aJustPushed.length != 0) Key.aJustPushed = [];
		if (Key.aReleased.length != 0) Key.aReleased = [];
		if (Key.aKeyJustDown.length != 0) Key.aKeyJustDown = [];
		if (Key.aKeyUp.length != 0) Key.aKeyUp = [];
		if (Key.ignoredKeys.length != 0) Key.ignoredKeys = [];
		eventJustTriggered = false;
	}

	/** Returns the mouse coordinates on the scene. **/
	public static function getMouseCoords(global:Bool=false, ?scene:nb.Scene):Point {
		if (scene == null) scene = currentScene;
		return global ? scene.localToGlobal(new Point(scene.mouseX, scene.mouseY)) : new Point(scene.mouseX, scene.mouseY);
	}

	/**
	 * Initializes the main window event target.
	 *
	 * It's the one used for detecting key inputs and triggering `nb.Interactive`s.
	 **/
	private static function initWindowEventTarget() {
		hxd.Window.getInstance().addEventTarget((e) -> {
			eventJustTriggered = true;

			var eventType:nb.Scene.EType = null;
			switch (e.kind) {
				case EPush | ERelease | EMove | EOver | EOut | EWheel | ECheck | EReleaseOutside : eventType = MOUSE;
				case EKeyDown | EKeyUp | ETextInput : eventType = KEY;
				default: return;
			}
			
			switch (eventType) {
				case MOUSE:
					if (e.kind == EPush) {
						Key.aJustPushed.push(e.button);
						if (!Key.aPushed.contains(e.button)) Key.aPushed.push(e.button);
					} else if (e.kind == ERelease) { // (e.kind == ERelease || !nb.Key.mouseButtonDown()) { ??
						Key.aReleased.push(e.button);
						if (Key.aPushed.remove(e.button)) Key.aClicked.push(e.button);
					}
				case KEY:
					if (e.kind == EKeyDown) {
						var dupe:Bool = false;
						for (kc in Key.aKeyDown) if (kc == e.keyCode) { dupe = true; break; }
						if (!dupe) {
							Key.aKeyJustDown.push(e.keyCode);
							Key.aKeyDown.push(e.keyCode);
						}
					} else if (e.kind == EKeyUp) {
						Key.aKeyUp.push(e.keyCode);
						Key.aKeyDown.remove(e.keyCode);
					}
			}
			currentScene.checkInteractives(e);
		});
	}
}