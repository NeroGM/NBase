package nb;

using Lambda;
import h2d.Bitmap;
import nb.ResManager;
import ase.Ase;

/** Contains tag information. **/
typedef Tag = {
	/** The tag's name. **/
	var name:String;
	/** Whether a similar tag will be made to the object's children onAdd. **/
	var inheritable:Bool;
	/** Whether the tag was inherited. **/
	var inherited:Bool;
}

/**
 * NBase's object class. You should use this instead of `h2d.Object`.
 * 
 * Still, `h2d.Object` was patched via macro to support tags and IDs.
 * See `nb.Macros.extH2dObject`.
 **/
@:allow(nb.Manager)
class Object extends h2d.Object {
	/**
	 * The size of the object. You shouldn't modify it directly,
	 * use the `setSize` function instead.
	 *
	 * This size is independent of the size of the displayed content
	 * that you get from functions like `getBounds()`.
	 *
	 * By default, this value doesn't change and gets its behavior defined
	 * by a children class.
	 **/
	public var size(default, null):Size = {w:0, h:0};
	public var entity:nb.phys.Entity = null;

	/** Whether `visible` was auto-toggled by this instance. **/
	private var autoToggledVisibility:Bool = false;
	/** Whether `visible` can be auto-toggled by this instance. **/
	public var autoTogglableVisibility:Bool = true;
	// public var doSetChildsParentContainerOnAdd:Bool = false;
	/** Whether the `onContentChanged` function should get called in the `onAdd` function. **/
	public var doOnContentChangedOnAdd:Bool = true;

	/** The number of this instance in `nb.Manager.updateQueue`. **/
	private var nUpdateQueue:Int = 0;

	/** Whether the childrens `onRemove` function should be called. **/
	private var removeChildrenOnRemove:Bool = true;
	
	/**
	 * Creates an `nb.Object` instance.
	 * 
	 * @param x The instance's x coordinate.
	 * @param y The instance's y coordinate.
	 * @param parent The instance's parent object.
	 **/
	public function new(?x:Float=0, ?y:Float=0, ?parent:h2d.Object) {
		name = "Object";
		super(parent);
		setPosition(x,y);
	}
	
	/** The update function called every frame by `nb.Manager`. **/
	public function update(dt:Float) { }

	/** Same as the `update` function but called first and used primarily for NBase's core logics. **/
	private function mandatoryUpdate(dt:Float) {
		if (autoTogglableVisibility) if (!autoToggledVisibility && visible && (alpha <= 0 || outsideScene())) {
			visible = false;
			autoToggledVisibility = true;
		} else if (autoToggledVisibility && !visible && (alpha != 0 && !outsideScene())) {
			visible = true;
			autoToggledVisibility = false;
		}
	}
	
	/** Moves this object by the given amount but unlike `h2d.Object`, it doesn't take rotation into account. **/
	override public function move(dx:Float, dy:Float) {
		setPosition(this.x+dx,this.y+dy);
	}

	/** Moves this object to a given position. It is meant to be overriden instead of `setPosition`. **/
	public function moveTo(x:Float, y:Float) {
		setPosition(x,y);
	}
	
	/** Inserts a child object at the specified position of the children list. **/
	override public function addChildAt(s:h2d.Object, pos:Int) {
		if( pos < 0 ) pos = 0;
		if( pos > children.length ) pos = children.length;
		var p:h2d.Object = this;
		while( p != null ) {
			if( p == s ) throw "Recursive addChild";
			p = p.parent;
		}
		if( s.parent != null ) {
			// prevent calling onRemove
			var old = s.allocated;
			s.allocated = false;
			s.parent.removeChild(s);
			s.allocated = old;
		}
		children.insert(pos, s);
		if( !allocated && s.allocated )
			s.onRemove();
		s.parent = this;

		// if (doSetChildsParentContainerOnAdd) { // <--
		// 	s.parentContainer = parentContainer;
		// 	if (s is Object) s.doSetChildsParentContainerOnAdd = true;
		// }

		s.posChanged = true;
		
		inheritParentTags(); // <--

		// ensure that proper alloc/delete is done if we change parent
		if( allocated ) {
			if( !s.allocated )
				s.onAdd();
			else
				s.onHierarchyMoved(true);
		}
		if (doOnContentChangedOnAdd) onContentChanged(); // <--
		#if domkit
		if( s.dom != null ) s.dom.onParentChanged();
		#end
	}

	/** Called when this object is being added to an allocated scene. **/
	override private function onAdd() {
		Manager.nbObjects.push(this);
		super.onAdd();
	}

	/** Called by the children of a container object if they have `parentContainer` defined in them. **/
	@:dox(show)
	override function contentChanged(o:h2d.Object) {
		onContentChanged();
	}
	
	/** Sets `size`. **/
	public function setSize(w:Float, h:Float) { 
		size.w = w;
		size.h = h;
		fOnChildren(null, (o) -> o.onParentResize());
	};

	/** Returns an array of `h2d.Object`s which name matches the regex. **/
	public function searchByName(regex:EReg):Array<h2d.Object> {
		var res:Array<h2d.Object> = regex.match(name) ? [this] : [];
		var tempChildren:Array<h2d.Object> = [this];

		while (tempChildren.length != 0) {
			var len = tempChildren.length;
			for (i in 0...len) for (c in tempChildren[i].iterator()) {
				if (regex.match(name)) res.push(c);
				tempChildren.push(c);
			}
			tempChildren.splice(0,len);
		}

		return res;
	}

	/** Returns an array of all children of the given type. **/
	public function searchByClass<T:h2d.Object>(type:Class<T>) {
		var res:Array<T> = [];
		var tempChildren:Array<h2d.Object> = [this];

		if (Std.isOfType(this,type)) {
			var v:T = cast this;
			res.push(v);
		}

		while (tempChildren.length != 0) {
			var len = tempChildren.length;
			for (i in 0...len) for (c in tempChildren[i].iterator()) {
				if (Std.isOfType(c,type)) { 
					var v:T = cast c;
					res.push(v);
				}
				tempChildren.push(c);
			}
			tempChildren.splice(0,len);
		}

		return res;
	}
	
	/** Called when this object is removed from the allocated scene. **/
	override private function onRemove() {
		Manager.nbObjects.remove(this);
		
		allocated = false;
		if (filter != null) filter.unbind(this);
		if (removeChildrenOnRemove) {
			var i = children.length - 1;
			while( i >= 0 ) {
				var c = children[i--];
				if( c != null ) c.onRemove();
			}
		}
	}

	/** Checks whether this object's content can be seen. **/
	public function outsideScene():Bool {
		if (hasTag("OnCam")) return false;

		var s:nb.Scene;
		try { s = cast(getScene(),nb.Scene); } catch (e) { return false; }
		var b = getBounds(s);
		if (b.width == 0 || b.height == 0) return false;
		for (va in s.visibleAreas) if (b.intersects(va)) return false;
		return true;
	}

	/** Called when a parent object gets resized. **/
	public dynamic function onParentResize() { }

	/** Called when the window gets resized and this object is on a scene. **/
	public dynamic function onWindowResize() { }
}