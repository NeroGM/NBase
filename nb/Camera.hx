package nb;

enum ScaleMode {
	DEFAULT;
	STRETCH(w:Float,h:Float);
}

/**
 * Contains useful data for positioning and scaling of objects added to the camera.
 * 
 * @since 0.1.0
 **/
@:allow(nb.Camera)
@:allow(nb.Manager)
private class ObjData {
	/** The associated `nb.Object`. **/
	var o:Object;
	/** The children position the object was added to. **/
	var addedAtPos:Int;
	/** The saved x position. **/
	var x:Float;
	/** The saved y position. **/
	var y:Float;
	/** If `true`, the object will be the children of to the next main camera on switch. **/
	var persistent:Bool;
	/** Whether the camera is allowed to reposition the object. **/
	var autoReposition:Bool;
	/** Whether the camera is allowed to rescale the object. **/
	var autoRescale:Bool;

	/** Creates an instance of `nb.Camera.ObjData`. **/
	public function new(o:Object, addedAtPos:Int, persistent:Bool, autoReposition:Bool, autoRescale:Bool) {
		this.o = o;
		this.x = o.x;
		this.y = o.y;
		this.addedAtPos = addedAtPos;
		this.persistent = persistent;
		this.autoReposition = autoReposition;
		this.autoRescale = autoRescale;
	}
}

@:dox(hide)
typedef CamF = {f:Float->Void, name:String};

/**
 * The camera class.
 * 
 * It is in charge of repositioning and rescaling its associated `nb.Scene` instance
 * and all the objects that were added to the camera using the `add`(not `addChild`) function.
 *
 * You usually shouldn't manipulate an `nb.Scene`'s properties directly, do it using its
 * associated camera instead.
 * 
 * @since 0.1.0
 **/
class Camera extends Object {
	/** Objects managed by the camera. **/
	public final objects:Array<ObjData> = [];
	/** Zoom value. 1 is 100%, 2 is 50%, 0.5 is 200%... **/
	public var zoom(default, null):Float = 1;
	// public var cumulZoom(default, null):Float = 1; // todo
	/** The object that the camera is following. **/
	public var objToFollow(default, null):h2d.Object = null;
	/** The area the camera can move to is limited by this. **/
	public var bounds(default, null):Bounds;
	/** What the associated scene's position coordinate should be right now. **/
	public var offset:Point = new Point();
	/** How the camera should scale the scene. **/
	public var viewScaleMode:ScaleMode = DEFAULT;
	/** How the camera should scale its managed objects. **/
	public var childrenScaleMode:ScaleMode = DEFAULT;
	/**
	 * What the associated scene's position coordinate should be at the start of the next frame,
	 * before being repositioned by `bounds` or the object the camera is following.
	 **/
	private var nextOffset:Point = new Point();
	/** The associated scene. **/
	public var scene(default, null):h2d.Scene;
	/** Whether rescaling is planned at next update. **/
	private var hasToRescale:Bool = true;
	/** Whether `anchor` should be ignored. **/
	private var ignoreAnchor:Bool = false;
	/** Whether this instance's `onMoveUpdate` will be triggered. **/
	private var moved:Bool = false;
	/** Whether this instance's `onScaleUpdate` will be triggered. **/
	private var rescaled:Bool = false;

	/** An anchor point used when zooming. **/
	public var anchor:Point = null;
	/** See `calcRatio` function for expected value. **/
	private var ratioX:Float = -1;
	/** See `calcRatio` function for expected value. **/
	private var ratioY:Float = -1;
	/** The last frame the `calcRatio` function was executed. **/
	private var lastCalcRatio:Int = -1;
	/** These functions gets called everytime the camera moves the scene. **/
	public var onMoveFs:Array<CamF> = [];
	/** These functions gets called everytime the camera rescales the scene. **/
	public var onScaleFs:Array<CamF> = [];

	/**
	 * Creates an `nb.Camera` instance.
	 * 
	 * Allows an `h2d.Scene` but that's untested. It's only guaranteed to work with an `nb.Scene`.
	 *
	 * The camera will become a children of the scene. It will use an `nb.Scene`'s `addOutside` function.
	 * 
	 * @param scene The scene associated to the camera.
	 **/
	public function new(scene:h2d.Scene) {
		name = "Camera";
		super();
		this.scene = scene;
		if (scene is nb.Scene) cast(scene,nb.Scene).addOutside(this, 10000);
		else scene.add(this,10000);
		size.w = Manager.app.engine.width;
		size.h = Manager.app.engine.height;

		autoTogglableVisibility = false;
	}
	
	/**
	 * Updates it's associated scene's and managed objects' properties. 
	 *
	 * It is called every frame by its associated scene's `mandatoryUpdate` function,
	 * which happens at the end of the game loop.
	 *
	 * Also called by some of this instance's functions when requested.
	 *
	 * @param dt Elapsed time in seconds.
	 **/
	override public function update(dt:Float) {
		for (o in objects) {
			if (o.o.x != o.x-offset.x) o.x = o.o.x+offset.x;
			if (o.o.y != o.y-offset.y) o.y = o.o.y+offset.y;
		}

		if (nextOffset != null) {
			if (objToFollow == null) offset.set(nextOffset.x,nextOffset.y);
			nextOffset = null;
		}
		if (hasToRescale) doRescale();
		
		if (objToFollow != null) {
			var p:Point = Manager.currentScene.globalToLocal(objToFollow.localToGlobal(new Point()));
			offset.x = (-p.x)/zoom;
			offset.y = (-p.y)/zoom;
			if (viewScaleMode.match(STRETCH(_,_))) {
				calcRatio();
				offset.x *= ratioX;
				offset.y *= ratioY;
			}
			offset.x += Manager.app.engine.width/2;
			offset.y += Manager.app.engine.height/2;
		}
		if (bounds != null) {
			var v1 = Manager.app.engine.width;
			var v2 = Manager.app.engine.height;
			if ((-offset.x + size.w)*zoom > bounds.xMax) offset.x = (-bounds.xMax)/zoom + size.w;
			if (-offset.x*zoom < bounds.xMin) offset.x = (-bounds.xMin)/zoom;
			if ((-offset.y + size.h)*zoom > bounds.yMax) offset.y = (-bounds.yMax)/zoom + size.h;
			if (-offset.y*zoom < bounds.yMin) offset.y = (-bounds.yMin)/zoom;
		}
		
		if (scene.x != offset.x || scene.y != offset.y) {
			scene.x = offset.x;
			scene.y = offset.y;
			moved = true;
		}

		for (o in objects) {
			if (o.autoReposition) {
				var vx = o.x-offset.x;
				var vy = o.y-offset.y;
				if (o.o.x != vx) o.o.x = vx;
				if (o.o.y != vy) o.o.y = vy;
			}
			if (o.autoRescale && childrenScaleMode.match(STRETCH(_,_))) {
				calcRatio();
				if (o.o.scaleX != ratioX) o.o.scaleX = ratioX;
				if (o.o.scaleY != ratioY) o.o.scaleY = ratioY;
			}
		}

		if (moved) { for (o in onMoveFs) o.f(dt); moved = false; }
		if (rescaled) { for (o in onScaleFs) o.f(dt); rescaled = false; }
		ratioX = -1;
		ratioY = -1;		
	}
	
	/**
	 * Adds an object on the camera.
	 * 
	 * It adds the tag "OnCam" to it which means the object is managed by the camera.
	 *
	 * @param o An `nb.Object` to add to the camera.
	 * @param pos `o` will be added at this position.
	 * @param persistent If `true`, the object will be the children of to the next main camera on switch.
	 * @param autoReposition Whether the camera is allowed to reposition the object.
	 * @param autoRescale Whether the camera is allowed to rescale the object.
	 * @return An `nb.Camera.ObjData` containing the aforementioned informations.
	 **/
	public function add(o:Object, pos:Int=0, persistent:Bool=false, autoReposition:Bool=true, autoRescale:Bool=true):ObjData {
		addChildAt(o, pos);
		o.move(-offset.x,-offset.y);
		var data = new ObjData(o, pos, persistent, autoReposition, autoRescale);
		objects.push(data);
		o.addTag("OnCam", true);
		return data;
	}
	
	/**
	 * Same as the `add` function but uses saved `nb.Camera.ObjData`.
	 *
	 * Used on camera switch.
	 *
	 * @param o An `nb.Object` to add to the camera.
	 * @param data `o`'s associated `nb.Camera.ObjData`.
	 **/
	public function reAdd(o:Object, data:ObjData) {
		addChildAt(o, data.addedAtPos);
		data.o.x = data.x-offset.x;
		data.o.y = data.y-offset.y;
		objects.push(data);
		o.addTag("OnCam", true);
	}
	
	/** Makes the camera follow an `h2d.Object`. **/
	public function follow(o:h2d.Object, dx:Float=0, dy:Float=0) objToFollow = o;
	
	/** Makes the camera stop following. **/
	public function unfollow() objToFollow = null;
	
	/**
	 * Set the camera zoom value
	 * 
	 * @param zoom Zoom value. 1 is 100%, 2 is 200%, 0.5 is 50%...
	 * @param anchor If not `null`, the camera's anchor point will be set to this.
	 * @param now Whether the rescaling should happen immediately.
	 **/
	public function setZoom(zoom:Float, ?anchor:Point, now:Bool=false) {
		this.zoom = zoom;
		if (anchor != null) this.anchor == null ? this.anchor = anchor.clone() : this.anchor.set(anchor.x,anchor.y);
		planRescale(now);
	}

	/** The area the camera can move to is limited by these values. Sets `bounds`. **/
	public function setBounds(xMin:Float, xMax:Float, yMin:Float, yMax:Float) {
		bounds.xMin = xMin;
		bounds.xMax = xMax;
		bounds.yMin = yMin;
		bounds.yMax = yMax;
	}
	
	/** Gets the `nb.Camera.ObjData` associated with `o`. **/
	public function getObjData(o:Object):ObjData {
		for (objData in objects) if (o == objData.o) return objData;
		return null;
	}

	/** Makes the associated scene move. **/
	override function move(x:Float, y:Float) {
		nextOffset = new Point(offset.x-x/zoom, offset.y-y/zoom);
		update(0);
	}

	/** Makes the associated scene move. **/
	override function moveTo(x:Float, y:Float) {
		nextOffset = new Point(-x/zoom,-y/zoom);
		update(0);
	}

	/** Makes the associated scene rotate. **/
	public function rot(v:Float) {
		scene.rotate(v);
		rotate(-v);
	}

	/** Sets the associated scene's rotation. **/
	public function setRot(v:Float) {
		scene.rotation = v;
		rotation = -v;
	}

	/** Rounds the associated scene's coordinate. **/
	public function round() {
		nextOffset = new Point(Std.int(offset.x),Std.int(offset.y));
		update(0);
	}

	/** Uses `Math.floor` on the associated scene's coordinate. **/
	public function floor() {
		nextOffset = new Point(Math.floor(offset.x),Math.floor(offset.y));
		update(0);
	}

	/**
	 * Zoom at an area.
	 *
	 * @param x Area x position.
	 * @param y Area y position.
	 * @param w Area width.
	 * @param h Area height.
	 * @param twType If not `null`, the camera will tween to the area.
	 * @param duration Tween duration in seconds.
	 **/
	public function zoomAtArea(x:Float, y:Float, w:Float=0, h:Float=0, ?twType:nb.Tween.TweenType, duration:Int=1) {
		if (w == 0 && h == 0) w = 1;

		if (twType != null) {
			var ratioX = nb.Manager.app.engine.width/size.w;
            var ratioY = nb.Manager.app.engine.height/size.h;
			var p = new Point(size.w*zoom,size.h*zoom);
            var p2 = new Point(-scene.x*zoom/ratioX,-scene.y*zoom/ratioY);
			nb.Tween.startMultiple([p2.x,p2.y,p.x,p.y], [x,y,w,h], duration, twType, (vals,realT,t) -> {
				zoomAtArea(vals[0],vals[1],vals[2],vals[3]);
			});
			return;
		}

		var ratioX:Float = size.w/Manager.app.engine.width;
		var ratioY:Float = size.h/Manager.app.engine.height;
		w /= ratioX;
		h /= ratioY;
		var rat = w > h*(Manager.app.engine.width/Manager.app.engine.height) ? w/Manager.app.engine.width : h/Manager.app.engine.height;
		setZoom(rat);
		moveTo(x/ratioX,y/ratioY);
		ignoreAnchor = true;
	}

	/** Stretch's the associated scene. **/
	override public function setSize(w:Float,h:Float) {
		viewScaleMode = STRETCH(w,h);
		planRescale(true,true);
	}

	/** Plans a rescaling. **/
	public function planRescale(now:Bool=false, ignoreAnchor:Bool=false) {
		hasToRescale = true;
		var oIgnoreAnchor = this.ignoreAnchor;
		this.ignoreAnchor = ignoreAnchor;
		if (now) update(0);
		this.ignoreAnchor = oIgnoreAnchor;
	}

	/** Stores a function that gets executed whenever the cam moves the associated scene. **/
	public inline function addOnMoveF(f:Float->Void, name:String="_") {
		onMoveFs.push({f:f,name:name});
	}

	/** Stores a function that gets executed whenever the cam rescales the associated scene. **/
	public inline function addOnScaleF(f:Float->Void, name:String="_") {
		onScaleFs.push({f:f,name:name});
	}

	/** Called by the associated `nb.Scene`'s `onResize` function. **/
	override public dynamic function onWindowResize() {
		planRescale(true,true);
		for (o in objects) if (o.o.onWindowResize != null) o.o.onWindowResize();
	}

	/** Rescales the associated scene and managed objects. **/
	private function doRescale() {
		switch (viewScaleMode) {
			case STRETCH(w, h):
				size.w = w;
				size.h = h;
			case DEFAULT:
				size.w = Manager.app.engine.width;
				size.h = Manager.app.engine.height;
		}

		var or = scene.rotation;
		scene.rotation = 0;

		var anchor:Point = ignoreAnchor ? new Point() :
			this.anchor == null ? new Point(Manager.app.engine.width*0.5,Manager.app.engine.height*0.5) : this.anchor;
		var p = getScene().globalToLocal(anchor.clone());

		var ratioX = Manager.app.engine.width/size.w;
		var ratioY = Manager.app.engine.height/size.h;
		var v = 1/zoom;
		scene.scaleX = v*ratioX;
		scene.scaleY = v*ratioY;
		scaleX = zoom/ratioX;
		scaleY = zoom/ratioY;
		offset.x = (-p.x)*scene.scaleX + anchor.x;
		offset.y = (-p.y)*scene.scaleY + anchor.y;

		scene.rotation = or;
		hasToRescale = ignoreAnchor = false;
		rescaled = true;
	}

	/** Sets `ratioX`, `ratioY` and `lastCalcRatio`. **/
	private inline function calcRatio() {
		if (lastCalcRatio == hxd.Timer.frameCount) return;
		ratioX = Manager.app.engine.width/size.w;
		ratioY = Manager.app.engine.height/size.h;
		lastCalcRatio = hxd.Timer.frameCount;
	}
}