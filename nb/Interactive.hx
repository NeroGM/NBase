package nb;

import nb.shape.*;

/**
 * An alternative to `h2d.Interactive` that works with `nb.Scene` instances.
 * 
 * @since 0.1.0
 **/
 // ! check size behavior
@:allow(nb.Scene)
class Interactive extends Object {
	/** The z value of the interactive. **/
	public var z:Int = 0;
	/** The second z value of the interactive to sort interactives with the same `z` value. **/
	public var z2:Int = 0;
	/** If `true`, this interactive is currently the topmost interactive targeted by mouse events. **/
	public var isHighestZ(default, null):Bool = false;
	/** Whether this interactive should let the interactives below it to trigger their events. **/
	public var propagate:Bool = false;
	/**
	 * Whether this interactive is currently focused.
	 * It can be prevented from being automatically set with `autoFocus`.
	 **/
	public var focused(default, null):Bool = false;
	/** Which mouse buttons is currently triggering this interactive. **/
	public var pushed(default, null):Array<Int> = [];
	/** Whether the mouse is over this interactive. Can be blocked by `propagate`. **/
	public var over(default, null):Bool = false;
	/** Whether this interactive can be triggered. **/
	public var enabled(default, null):Bool = true;
	/** Whether this interactive gets focused/unfocused automatically on mouse click. **/
	public var autoFocus:Bool = true;

	/** The `nb.shape.Shapes` defining this interactive's hitboxes. You can add shapes to it directly. **/
	public var shapes(default,null):Shapes = null;
	/** Whether this interactive's parent is a `nb.SubScene`. Permits the event to go to the subscene. **/
	public var isOnSubscene(default, null):Bool = false;

	public static var focusedInteractives(default, null):Array<Interactive> = [];

	/** The `nb.Scene` this interactive is on. **/
	private var scene:Scene;

	/**
	 * Creates an `nb.Interactive` instance.
	 *
	 * If `w` or `h` <= 0, a hitbox won't be made.
	 *
	 * @param w Width of the interactive's hitbox.
	 * @param h Height of the interactive's hitbox.
	 * @param parent The interactive's parent object.
	 **/
	public function new(w:Float=0, h:Float=0, ?parent:h2d.Object) {
		name = "Interactive";
		super(parent);
		this.size = {w:w,h:h};
		shapes = new Shapes(this);

		if (w > 0 && h > 0) loadRect(w,h);
	}

	/**
	 * Shortcut function to set the functions `onDragStart`, `onDrag` and `onDragEnd`
	 * for dragging.
	 *
	 * It assumes a simple context, you might have to set these functions yourself
	 * for dragging.
	 **/
	public function initDefaultDrag() {
		onDragStart = (e1) -> {
			var startX:Float = parent.x;
			var startY:Float = parent.y;
			var startP = new Point(e1.relX, e1.relY);
			onDrag = (e2) -> {
				var diffP = globalToLocal(new Point(e2.relX,e2.relY)).sub(globalToLocal(startP.clone()));
				var newX = startX + diffP.x;
				var newY = startY + diffP.y;
				parent.setPosition(newX,newY);
			}
			onDragEnd = (_) -> onDragEnd = onDrag = (_) -> {};
		}
	}

	/** Removes current hitboxes and sets up a single rectangular hitbox. **/
	public function loadRect(w:Float, h:Float) {
		loadShape(new Polygon([new Point(0,0), new Point(w,0), new Point(w,h), new Point(0,h)]));
		size = {w:w,h:h};
	}

	/** Removes current hitboxes and sets up a hitbox from the given `nb.shape.Shape`. **/
	public function loadShape(shape:Shape) {
		clearShapes();
		shapes.addShape(shape);
	}

	/** Removes current hitboxes and sets up hitboxes from the given `nb.shape.Shapes`. **/
	public function loadShapes(shapes:Array<Shape>) {
		clearShapes();
		this.shapes.addShapes(shapes);
		var bounds = this.shapes.getBounds(this);
		// setOffset(bounds.xMin,bounds.yMin);
        setSize(bounds.width,bounds.height);
		// this.shapes.debugDraw();
	//	shapes.visible = false;
	}

	/** Removes hitboxes. **/
	public function clearShapes() shapes.clear();

	/** If `true`, the parent objects of this interactive all have `visible` to true. **/
	public function isVisible() {
		var p:h2d.Object = this;
		while (p != null) {
			if (!p.visible) return false;
			p = p.parent;
		}
		return true;
	}
	
	/** The update function called every frame by `nb.Manager`. **/
	override public function update(dt:Float) {
		onUpdate(dt);
		super.update(dt);
	}
	
	/** Focuses this interactive. You can have multiple interactives focused. **/
	public function focus() {
		focused = true;
		focusedInteractives.push(this);
		onFocus(null);
	}
	
	/** Unfocuses this interactive. **/
	public function unfocus() {
		focused = false;
		focusedInteractives.remove(this);
		onFocusLost(null);
	}
	
	/** Enables this interactive. **/
	public function enable() {
		enabled = true;
		Manager.addObjectUpdate(this);
	}

	/** Disables this interactive. **/
	public function disable() {
		if (over) onOut(null);
		if (focused) onFocusLost(null);
		focused = false;
		pushed = [];
		over = false;
		enabled = false;
		Manager.removeObjectUpdate(this);
	}

	/** Enables the interactive's default behavior by setting `onHighestZ` and `onNotHighestZ`. **/
	public function defaultInit() {
		onHighestZ = (_) -> if (Cursor.cursor != CursorKind.Hand) Cursor.setCursor(CursorKind.Hand);
		onNotHighestZ = (_) -> if (Cursor.cursor != CursorKind.Arrow) Cursor.setCursor(CursorKind.Arrow);
	}
	
	/** Called whenever this interactive is removed from an allocated scene. **/
	override public function onRemove() {
		disable();
		name = "["+objId+"]"+"I_";

		if (isOnSubscene && !Std.isOfType(parent, nb.SubScene)) isOnSubscene = false;

		scene.interactives.remove(this);
		scene = null;
		
		Manager.removeObjectUpdate(this);
		super.onRemove();
	}

	/** Called whenever this interactive is added to an allocated scene. **/
	override public function onAdd() {
		enable();
		name = "["+objId+"]"+"I_"+parent.name;

		if (Std.isOfType(parent,SubScene)) isOnSubscene = true;

		scene = cast(parent.getScene(), nb.Scene);
		scene.interactives.push(this);
		
		Manager.addObjectUpdate(this);
		super.onAdd();
	}
	
	/** Called whenever the mouse comes over this interactive. **/
	public dynamic function onOver(e:hxd.Event) { }
	/** Called whenever the mouse isn't over this interactive anymore. **/
	public dynamic function onOut(e:hxd.Event) { }
	/** Called whenever a mouse button is pushed over this interactive. **/
	public dynamic function onPush(e:hxd.Event) { }
	/** Called whenever a mouse button is released over this interactive. **/
	public dynamic function onRelease(e:hxd.Event) { }
	/** Called whenever a mouse click is done over this interactive. **/
	public dynamic function onClick(e:hxd.Event) { }
	/** Called whenever the mouse moves over this interactive. **/
	public dynamic function onMove(e:hxd.Event) { }
	/** Called whenever the mouse wheel is used over this interactive. **/
	public dynamic function onWheel(e:hxd.Event) { }
	/** Called whenever this interactive gets focused. **/
	public dynamic function onFocus(e:hxd.Event) { }
	/** Called whenever this interactive gets unfocused. **/
	public dynamic function onFocusLost(e:hxd.Event) { }
	/** Called whenever a key gets released over this interactive. **/
	public dynamic function onKeyUp(e:hxd.Event) { }
	/** Called whenever a key gets pressed over this interactive. **/
	public dynamic function onKeyDown(e:hxd.Event) { }
	/** Called whenever a key gets pressed for text input for this interactive. **/
	public dynamic function onTextInput(e:hxd.Event) { }
	/** Called whenever this interactive detects a dragging operation. **/
	public dynamic function onDrag(e:hxd.Event) { }
	/** Called whenever this interactive detects the start of a dragging opeartion. **/
	public dynamic function onDragStart(e:hxd.Event) { }
	/** Called whenever this interactive detects the end of a dragging opeartion. **/
	public dynamic function onDragEnd(e:hxd.Event) { }
	/** Called by this interactive's `update` function. **/
	public dynamic function onUpdate(dt:Float) { }
	/** Called whenever this interactive becomes the topmost interactive triggered by a mouse event. **/
	public dynamic function onHighestZ(e:hxd.Event) { }
	/** Called whenever this interactive isn't anymore the topmost interactive triggered by a mouse event. **/
	public dynamic function onNotHighestZ(e:hxd.Event) { }
}