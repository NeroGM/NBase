package nb;

using nb.ext.PointExt;

/** Event types. **/
enum EType {
	MOUSE;
	KEY;
}

/**
 * Contains information about a global mouse event.
 * 
 * @since 0.1.0
 **/
class GlobalMouseEvent {
	/** A name for this instance. **/
	public var name:String;
	/** The function that gets executed when the event is triggered. **/
	public var f:Void->Void;
	/** The event's priority number. **/
	public var priority:Int;
	
	/**
	 * Creates an `nb.Scene.GlobalMouseEvent` instance.
	 * 
	 * @param name A name for the instance.
	 * @param f The function that gets executed when the event is triggered.
	 * @param priority The event's priority number.
	 **/
	public function new(name:String, f:Void->Void, priority:Int) {
		this.name = name;
		this.f = f;
		this.priority = priority;
	}
}

/**
 * NBase's scene class. You should use this instead of `h2d.Scene`s.
 * 
 * @since 0.1.0
 **/
@:allow(nb.Manager)
@:allow(nb.SubScene)
@:keepSub
class Scene extends h2d.Scene {
	/** Whether this scene is loaded. **/
	public var firstLoaded(default, null):Bool = false;
	/** The background interactive of this scene. **/
	public var inter:Interactive;
	/** Contains all `nb.SubScene` instances in this scene. **/
	public var subScenes:Array<SubScene> = [];
	/** Contains all `nb.SubScene` instances this scene is a parent of. **/
	public var relSubScenes:Array<SubScene> = [];
	/** Contains the `nb.Scene` instances this scene can see through subscenes. **/
	public var canSeeScenes:Array<Scene> = [];
	/** Contains the `nb.Scene` instances this scene can be see from. **/
	public var seenByScenes:Array<Scene> = [];
	/** This scene's current main camera. **/
	public var cam:Camera;
	/** All cameras for this scene. **/
	public final cams:Array<Camera> = []; // not fully implemented
	/**
	 * A container.
	 * 
	 * By default, adding something to the scene will actually add it to this instead.
	 * This is done so that if you want to apply an effect to the scene without affecting
	 * the objects on the camera, you just have to add it to the scene's `content` variable instead.
	 **/
	public final content:Object;
	/** Contains all the currently visible areas of this scene. **/
	public var visibleAreas:Array<h2d.col.Bounds> = [];
	/** The `nb.Graphics` instance used for the grid. **/
	private final grid:Graphics = new Graphics();

	/** All `nb.Interactive` instances on this scene. **/
	public var interactives:Array<Interactive> = [];
	/** All interactives the mouse is currently on. (Ignores interactive's `propagate`.) **/
	private var onInteractives:Array<Interactive> = [];
	/** Contains interactives that were set to have `pushed` set to false this frame. **/
	private var intToDepush:Array<Interactive> = [];
	/** Contains interactives that were set to have `onOut` called this frame. **/
	private var intToOnOut:Array<Interactive> = [];
	/** Contains interactives that were set to have `onOver` called this frame. **/
	private var intToOnOver:Array<Interactive> = [];
	/** Contains interactives that were set to have `onRelease` called this frame. **/
	private var intToOnRelease:Array<Interactive> = [];
	/** Contains interactives that were set to have `focus` set to false this frame. **/
	private var intToUnfocus:Array<Interactive> = [];
	/** Contains the interactive that had `highestZ` set to `true` in the previous frame. **/
	private var prevHighestInter:Interactive = null;

	/** All `nb.Scene.GlobalMouseEvent` instances that gets triggered by pressing a mouse button. **/
	public static final onPushFs:Array<GlobalMouseEvent> = [];
	/** All `nb.Scene.GlobalMouseEvent` instances that gets triggered by relasing a mouse button. **/
	public static final onReleaseFs:Array<GlobalMouseEvent> = [];
	/** All `nb.Scene.GlobalMouseEvent` instances that gets triggered by a mouse click. **/
	public static final onClickFs:Array<GlobalMouseEvent> = []; 

	/**
	 * When this is set to `true`, the added objects becomes a direct children of this scene
	 * instead of being added to `content`.
	 **/
	public var outside:Bool = false;
	
	/** Creates an `nb.Scene` instance. **/
	public function new() {
		super();
		content = new Object(0,0,this);
		cam = new Camera(this);
		cams.push(cam);

		Manager.createdScenes.push(this);
	}

	/** Creates an `nb.Scene.GlobalMouseEvent` that gets triggered by pressing a mouse button. **/
	public static function addOnPushF(f:Void->Void, priority:Int=0, name:String="") {
		onPushFs.push(new GlobalMouseEvent(name,f,priority));
		nb.ext.ArrayExt.quickSort(onPushFs, (a,b) -> a.priority > b.priority);
	}

	/** Creates an `nb.Scene.GlobalMouseEvent` that gets triggered by releasin a mouse button. **/
	public static function addOnReleaseF(f:Void->Void, priority:Int=0, name:String="") {
		onReleaseFs.push(new GlobalMouseEvent(name,f,priority));
		nb.ext.ArrayExt.quickSort(onReleaseFs, (a,b) -> a.priority > b.priority);
	}

	/** Creates an `nb.Scene.GlobalMouseEvent` that gets triggered by a mouse click. **/
	public static function addOnClickF(f:Void->Void, priority:Int=0, name:String="") {
		onClickFs.push(new GlobalMouseEvent(name,f,priority));
		nb.ext.ArrayExt.quickSort(onClickFs, (a,b) -> a.priority > b.priority);
	}
	
	/**
	 * Use this function to add an object to the scene.
	 * 
	 * @param o An `h2d.Object` instance to add.
	 * @param index1 By default, `o` will be added in `content` at this position.
	 * If `outside` is set to `true`, this is the layer index `o` will be added to. (Heaps' default behavior.)
	 * @param index2 This is only taken into account if `outside` is set to true.
	 * The optional index at which the object should be inserted inside the layer.
	 **/
	override public function add(o:h2d.Object, index1:Int = -1, index2:Int = -1) {
		(outside || content == null) ? super.add(o, index1, index2) : content.addChildAt(o, index1 == -1 ? content.children.length : index1);
	}

	/** Same as `add` but the object will be **/
	public function addOutside(o:h2d.Object, layer:Int = -1, index:Int = -1) {
		super.add(o, layer, index);
	}

	/** This function gets called the first time this scene gets displayed. **/
	private function onFirstLoad() firstLoaded = true;

	/** This function gets called the first time this scene gets focused. **/
	private function onFocus() { }

	/** This function gets called the first time this scene gets unfocused. **/
	private function onUnfocus() { }

	/** The update function called by `nb.Manager` every frame. **/
	public function update(dt:Float) { }

	/** Same as the `update` function but called first and used primarily for NBase's core logics. **/
	public function mandatoryUpdate(dt:Float) {
		cam.update(0);
	}

	/** Called when the `hxd.App` instance gets its `onResize` called. **/
	public function onResize() {
		cam.onWindowResize();
	}

	/** Disposes the scene. **/
	override function dispose() {
		super.dispose();
		Manager.createdScenes.remove(this);
	}

	/** Draws a grid. **/
	public function showGrid(?size:Size, layer:Int = 0) {
		if (size == null) size = {w:16,h:16};
		var lineX:Float = 0;
		var lineY:Float = 0;
		var vLines:Int = 0;
		var hLines:Int = 0;
		while (lineX <= width*2) {
			grid.drawLine(lineX,0,lineX,height*2);
			lineX += size.w;
			vLines++;
		}
		while (lineY <= height*2) {
			grid.drawLine(0,lineY,width*2,lineY);
			lineY += size.h;
			hLines++;
		}
		add(grid,layer);
	}

	/**
	 * Called by an `nb.SubScene` instance when a new scene can be seen from this scene.
	 *
	 * @param scene The scene that can be seen.
	 **/
	@:allow(nb.Subscene)
	private function addSeeableScene(scene:Scene) { 
		if (!canSeeScenes.contains(scene)) {
			canSeeScenes.push(scene);
			scene.seenByScenes.push(this);
		}
		for (s in seenByScenes) if (!s.canSeeScenes.contains(scene)) { 
			s.canSeeScenes.push(scene);
			scene.seenByScenes.push(s);
		}
	}

	/**
	 * Called by an `nb.SubScene` instance when a scene can't be seen anymore from this scene.
	 * 
	 * @param scene The scene that can't be seen.
	 **/
	@:allow(nb.SubScene)
	private function removeSeeableScene(scene:Scene) {
		canSeeScenes.remove(scene);
		scene.seenByScenes.remove(this);
		for (s in seenByScenes) {
			s.canSeeScenes.remove(scene);
			scene.seenByScenes.remove(s);
		}
	}

	public function emitP(p:Point, ?toS:Scene):Array<Point> {
		if (relSubScenes.length == 0) return [p];

		var v:Array<Point> = [];
		for (ss in relSubScenes) {
			var p = ss.emitP(p, toS);
			for (pp in p) v.push(pp.clone());
		}
		return v;
	}

	/**
	 * The function that `nb.SubScene` instances use to make an event for its scene.
	 * 
	 * @param e The captured `hxd.Event` instance to generate the new event from.
	 * @param px The X coordinate of the new event to generate.
	 * @param py The Y coordinate of the new event to generate.
	 **/ // ? Maybe this function is in a bad location ?
	private function doEvent(e:hxd.Event, px:Float, py:Float) {
		var newE = new hxd.Event(e.kind,px,py);
		newE.wheelDelta = e.wheelDelta;
		newE.keyCode = e.keyCode;
		newE.button = e.button;
		checkInteractives(newE);
	}

	/** Adds a background interactive to move the scene and zoom. **/
	public function addBgInteractive(z:Int=-50) {
		if (inter != null) return;
		nb.Manager.addObjectUpdate(cam);

		inter = new nb.Interactive(1e40, 1e40);
		inter.setPosition(-1e20,-1e20);
        inter.z = z;
        inter.onDragStart = (e1) -> {
			var startX = -x;
			var startY = -y;
			var startP = new Point(e1.relX,e1.relY);
			inter.onDrag = (e2) -> {
				var diffP = new Point(e2.relX,e2.relY).sub(startP.clone());
				var newX = (startX - diffP.x);
				var newY = (startY - diffP.y);
				cam.moveTo(newX*cam.zoom,newY*cam.zoom);
			}
			inter.onDragEnd = (di) -> { inter.onDragEnd = inter.onDrag = (_) -> {}; cam.floor(); }
		}
		inter.onWheel = (e:hxd.Event) -> {
			if (e.wheelDelta == 0) return;
            var incZoom:Float = nb.Key.isDown(hxd.Key.SHIFT) ? 0.01 : 0.05;
			var anchor = new Point(e.relX, e.relY);
            if (e.wheelDelta > 0) cam.setZoom(cam.zoom+incZoom,anchor);
            else cam.setZoom(cam.zoom-incZoom,anchor);
        }
		cam.add(inter);
	}

	/** Triggers `nb.Interactive` instances on the scene according to a given event. **/
	public function checkInteractives(e:hxd.Event) {
		var eventType:EType = null;
		switch (e.kind) {
			case EPush | ERelease | EMove | EOver | EOut | EWheel | ECheck | EReleaseOutside : eventType = MOUSE;
			case EKeyDown | EKeyUp | ETextInput : eventType = KEY;
			default: return;
		}

		intToDepush = [];
		intToOnOut = [];
		intToOnOver = [];
		intToOnRelease = [];
		intToUnfocus = [];
		onInteractives = [];
		prevHighestInter = null;

		for (i in interactives) {
			if (!i.enabled || i.shapes == null || !i.isVisible()) continue;
			if (prevHighestInter == null && i.isHighestZ) prevHighestInter = i;
			
			var localPos:Point = null;
			switch (eventType) {
				case MOUSE:
					if (e.kind == EMove && i.pushed.length != 0) {
						for (b in i.pushed.copy()) if (!Key.mouseButtonDown(b)) i.pushed.remove(b);
						if (i.pushed.length != 0) {
							i.onMove(e);
							i.onDrag(e);
						}
					}
					localPos = i.globalToLocal(new Point(e.relX,e.relY));

					// Detect interactives to onOver or onOut
					if (i.shapes.containsPoint(localPos)) {
						onInteractives.push(i);
						if (i.isOnSubscene) continue;
						if (e.kind == ERelease) intToOnRelease.push(i);
					} else {
						if (i.over) intToOnOut.push(i);
						if (e.kind == EPush && i.focused && i.autoFocus) intToUnfocus.push(i);
					}
					
					if (e.kind == ERelease) {
						if (i.pushed.remove(e.button)) intToDepush.push(i);
					}
				case KEY:
					@:privateAccess localPos = i.globalToLocal(new Point(Manager.app.sevents.mouseX,Manager.app.sevents.mouseY));
					if (i.shapes.containsPoint(localPos)) onInteractives.push(i);
					continue;
			}
		}

		// Do onOuts and onOvers and onReleases
		onInteractives.sort(zSort);
		var highestInteractives:Array<Interactive> = [];

		if (onInteractives.length > 0) {
			var propagate:Bool = true;
			for (i in onInteractives) if (propagate) {
				highestInteractives.push(i);

				if (i.isOnSubscene) { 
					var ss = cast(i.parent, nb.SubScene);
					ss.inter.onPush(e);
					if (!i.propagate) {
						propagate = false;
						if (eventType != MOUSE) break;
					}
					continue;
				}

				if (eventType == MOUSE && !i.over) intToOnOver.push(i);
				if (!i.propagate) {
					propagate = false;
					if (eventType != MOUSE) break;
				}
			} else {
				if (i.over) intToOnOut.push(i);
			}
		}

		if (eventType == MOUSE) {
			for (i in intToOnOut) { i.over = false; i.onOut(e); }
			for (i in intToOnOver) { i.over = true; i.onOver(e); }
			for (i in intToOnRelease) {
				i.onRelease(e);
				i.onDragEnd(e);
			}
			for (i in intToUnfocus) i.unfocus();
			
			
			if (Key.aJustPushed.length != 0) for (f in onPushFs) f.f();
			if (Key.aReleased.length != 0) for (f in onReleaseFs) f.f();
			if (Key.aClicked.length != 0) for (f in onClickFs) f.f();
			
			// Then handle events for the highest(s) interactive(s)
			var highestInter = highestInteractives[0];
			if (prevHighestInter != null && (!prevHighestInter.over || highestInter != prevHighestInter)) {
				prevHighestInter.isHighestZ = false;
				prevHighestInter.onNotHighestZ(e);
			}
			if (highestInter != null && highestInter != prevHighestInter) { 
				highestInter.isHighestZ = true;
				highestInter.onHighestZ(e);
			}
		}

		switch (eventType) {
			case MOUSE:
				for (i in highestInteractives) if (!i.isOnSubscene) {
					switch (e.kind) {
						case EPush:
							if (!i.over) continue;
							if (i.autoFocus && !i.focused) i.focus();
							i.pushed.push(e.button);
							i.onPush(e);
							i.onDragStart(e);
						case EWheel:
							i.onWheel(e);
						case EMove:
							i.onMove(e);
						case ERelease:
							for (i2 in intToDepush) if (i2 == i) { i.onClick(e); break; } //?
						default:
					}
					if (!i.propagate) break;
				}
			case KEY:
				for (i in highestInteractives) if (!i.isOnSubscene) {
					switch (e.kind) {
						case EKeyDown:
							i.onKeyDown(e);
						case EKeyUp:
							i.onKeyUp(e);
						case ETextInput:
							i.onTextInput(e);
						default:
					}
					if (!i.propagate) break;
				}
		}
	}

	#if (hl || js)
	/**
	 * Checks if there's any `nb.Interactive` instance that needs to get triggered.
	 *
	 * This only gets called if the `checkInteractives` function wasn't called this frame
	 * because there was no event.
	 **/
	 // ! Shouldn't use null events
	private function additionalInteractivesCheck() {
		prevHighestInter = null;
		var onInteractives:Array<Interactive> = [];	
		var intToOnOut:Array<Interactive> = [];
		var intToOnOver:Array<Interactive> = [];
		for (i in interactives) {
			if (!i.enabled || i.shapes == null || !i.isVisible()) continue;
			if (prevHighestInter == null && i.isHighestZ) prevHighestInter = i;
			
			var localPos:Point = null;

			localPos = i.globalToLocal(Cursor.getCursorPosition());

			// Detect interactives to onOver or onOut
			if (i.shapes.containsPoint(localPos)) {
				onInteractives.push(i);
			} else {
				if (i.over) intToOnOut.push(i);
			}
		}

		onInteractives.sort(zSort);
		intToOnOut.sort(zSort);
		intToOnOver.sort(zSort);

		var highestInteractives:Array<Interactive> = [];
		if (onInteractives.length > 0) {
			var propagate:Bool = true;
			for (i in onInteractives) if (propagate) {
				highestInteractives.push(i);

				if (i.isOnSubscene) { 
					var ss = cast(i.parent, nb.SubScene);
					// ss.inter.onPush(null);
					if (!i.propagate) propagate = false;
					continue;
				}

				if (!i.over) intToOnOver.push(i);
				if (!i.propagate) propagate = false;
			} else {
				if (i.over) intToOnOut.push(i);
			}
		}

		for (i in intToOnOut) { i.over = false; i.onOut(null); }
		for (i in intToOnOver) { i.over = true; i.onOver(null); }
		
		highestInteractives.sort(zSort);
		var highestInter = highestInteractives[0];
		if (prevHighestInter != null && (!prevHighestInter.over || highestInter != prevHighestInter)) {
			prevHighestInter.isHighestZ = false;
			// prevHighestInter.onNotHighestZ(null);
		}
		if (highestInter != null && highestInter != prevHighestInter) { 
			highestInter.isHighestZ = true;
			// highestInter.onHighestZ(null);
		}
	}
	#end

	/** A z-sort function for interactives. **/
	private static function zSort(i1:Interactive, i2:Interactive) {
		if (i1.z > i2.z) return -1;
		else if (i1.z < i2.z) return 1;
		else if (i1.z2 > i2.z2) return -1;
		else if (i1.z2 < i2.z2) return 1;
		else if (i1.objId > i2.objId) return -1;
		else if (i1.objId < i2.objId) return 1;
		else return 0;
	};
}