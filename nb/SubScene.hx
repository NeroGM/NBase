package nb;

using nb.ext.PointExt;

/**
 * A class to show a scene in another scene.
 *
 * @since 0.1.0
 **/
@:allow(nb.Manager)
class SubScene extends Object {
    /** The x coordinate of the view of the scene. **/
    public var sx:Float = 0;
    /** The y coordinate of the view of the scene. **/
    public var sy:Float = 0;
    /** The scene it is displaying. **/
    public var scene(default,null):Scene;
    /** The scene it is showing from. **/
    public var parentScene(default,null):Scene;
    /** The tile of the render target. **/
    private var tile:h2d.Tile;
    /** The render target texture. **/
    private var renderTarget:h3d.mat.Texture;
    /** The `h2d.Bitmap` displaying the tile. **/
    private var bmp:h2d.Bitmap;
    /** This subscene's interactive. **/
    public var inter(default,null):Interactive;
    /** Set to `true` when a subscene is in the process of being a copy. **/
    private static var copying:Bool = false;

    /**
     * Creates an `nb.SubScene` instance.
     * 
     * @param x The subscene's x coordinate on the parent scene.
     * @param y The instance's y coordinate on the parent scene.
     * @param w The width of the subscene.
     * @param h The height of the subscene.
     * @param scene The scene it is displaying.
     * @param parent The parent object of the subscene.
     **/
    override public function new(x:Float, y:Float, w:Int, h:Int, scene:Scene, ?parent:h2d.Object) {
        this.scene = scene;
        super(x,y,parent);

        size.w = w;
        size.h = h;
        scene.relSubScenes.push(this);

        inter = new Interactive(w,h,this);
        inter.onPush = inter.onRelease = inter.onMove = inter.onClick = inter.onWheel = inter.onOver = inter.onOut = inter.onDragStart = inter.onDrag = inter.onDragEnd = (e) -> {
            var relP = inter.globalToLocal(new Point(e.relX,e.relY));
            var p = new Point(sx+relP.x,sy+relP.y);

            scene.doEvent(e, p.x, p.y); // todo need dragInfo per scene
        }
        

        if (!copying) {
            updateRenderTarget();
            tile = h2d.Tile.fromTexture(renderTarget);
            bmp = new h2d.Bitmap(tile,this);
        }        
    }

    /** Converts a local position to a position in the scene this subscene is showing. **/
    public inline function intPosToScenePos(p:Point) {
        return scene.globalToLocal(new Point(sx+p.x,sy+p.y));
    }

    override private function onAdd() {
        var s = cast(getScene(), nb.Scene);
        if (s != null) {
            parentScene = s;
            parentScene.subScenes.push(this);
            parentScene.addSeeableScene(scene);
            if (parentScene == Manager.currentScene || parentScene.seenByScenes.contains(Manager.currentScene)) {
                var tempA:Array<SubScene> = [this];
                while (tempA.length != 0) {
                    var len = tempA.length;
                    for (i in 0...len) for (c in tempA[i].scene.iterator()) if (Std.isOfType(c,SubScene)) { 
                        var ss = cast(c,SubScene);
                        Manager.addObjectUpdate(ss.scene.cam);
                        Manager.addObjectUpdate(ss);
                        tempA.push(ss);
                    }
                    tempA.splice(0,len);
                }
            }
        }
        
        super.onAdd();
    }

    override private function onRemove() {
        if (parentScene != null) {
            parentScene.subScenes.remove(this);
            parentScene.removeSeeableScene(scene);
            if (parentScene == Manager.currentScene || parentScene.seenByScenes.contains(Manager.currentScene)) {
                var tempA:Array<SubScene> = [this];
                while (tempA.length != 0) {
                    var len = tempA.length;
                    for (i in 0...len) for (c in tempA[i].scene.iterator()) if (Std.isOfType(c,SubScene)) {
                        var ss = cast(c,SubScene);
                        Manager.removeObjectUpdate(ss.scene.cam);
                        Manager.removeObjectUpdate(ss);
                        tempA.push(ss);
                    }
                    tempA.splice(0,len);
                }
            }
            parentScene = null;
        }
        super.onRemove();
    }

    /** The update function called every frame by `nb.Manager`. **/
    override public function update(dt:Float) {
        updateRenderTarget();
        super.update(dt);
    }

    /** Clones this subscene. **/
    public inline function clone():SubScene {
        copying = true;
        var ss = new SubScene(x,y,Std.int(size.w),Std.int(size.h),scene);
        ss.renderTarget = renderTarget;
        ss.tile = h2d.Tile.fromTexture(renderTarget);
        ss.bmp = new h2d.Bitmap(tile, ss);
        copying = false;
        return ss;
    }

    public function emitP(p:Point, ?toS:Scene):Array<Point> {
        if (parentScene == null) return [];

        if (toS != null) {
            var vs:Array<Point> = [];
            var paths:Array<Array<SubScene>> = [for (ss in scene.relSubScenes) [ss]];
            var f = (path:Array<SubScene>) -> {
                var p:Point = p.clone();
                for (ss in path) {
                    p = ss.scene.localToGlobal(p.clone());
                    var rat = new Point(p.x/ss.size.w, p.y/ss.size.h);
                    p = new Point(ss.x + ss.size.w*rat.x - sx, ss.y + ss.size.h*rat.y - sy).relativeTo(ss.parentScene,ss.parent);
                }
                return p;
            };

            var depth:Int = 0;
            for (path in paths) do {
                var ss = path[depth];
                if (ss.parentScene == toS) {
                    vs.push(f(path));
                    break;
                }

                for (i in 0...ss.parentScene.relSubScenes.length) {
                    var v = ss.parentScene.relSubScenes[i];
                    if (i == 0) path.push(v);
                    else {
                        var newPath = path.copy();
                        newPath.pop();
                        newPath.push(v);
                        paths.push(newPath);
                    }
                }
                depth++;
            } while (path[depth] != null);
            return vs;
        }

        var p = scene.localToGlobal(p.clone());
        var rat = new Point(p.x/size.w, p.y/size.h);
        return [new Point(x + size.w*rat.x, y + size.h*rat.y)];
    }

    /** Adds the area this subscene is showing to `scene.visibleAreas`. **/
    private function updateSceneVisibleArea() {
        if (!visible) return; // should make outsideScene early        
        
        var bounds = new h2d.col.Bounds();
        bounds.addPoint(intPosToScenePos(new Point(0,0)));
        bounds.addPoint(intPosToScenePos(new Point(size.w,size.h)));
        scene.visibleAreas.push(bounds); 
    }

    /** Creates the render texture if there isn't one, then updates it. **/
    public function updateRenderTarget() {
		var engine = nb.Manager.app.engine;
        var w = Std.int(size.w);
        var h = Std.int(size.h);

		if (renderTarget == null) {
			renderTarget = new h3d.mat.Texture(w, h, [h3d.mat.Data.TextureFlags.Target]);
        	renderTarget.depthBuffer = new h3d.mat.DepthBuffer(w, h);
		}

        @:privateAccess {
            scene.camera.setViewport(0,0,w,h);

            var tex = renderTarget;
            engine.pushTarget(tex);
            var ox = scene.x, oy = scene.y, ow = scene.width, oh = scene.height, ova = scene.viewportA, ovd = scene.viewportD, ovx = scene.viewportX, ovy = scene.viewportY;
            var oPosChanged = scene.posChanged;
            scene.x -= sx;
            scene.y -= sy;
            scene.width = tex.width;
            scene.height = tex.height;
            scene.viewportA = 2 / scene.width;
            scene.viewportD = 2 / scene.height;
            scene.viewportX = -1;
            scene.viewportY = -1;
            scene.posChanged = true;
            scene.syncPos();
            engine.clear(0,1);
            scene.render(engine);
            engine.popTarget();

            scene.x = ox;
            scene.y = oy;
            scene.width = ow;
            scene.height = oh;
            scene.viewportA = ova;
            scene.viewportD = ovd;
            scene.viewportX = ovx;
            scene.viewportY = ovy;
            scene.syncPos();
            scene.posChanged = oPosChanged;
            engine.setRenderZone();
        }
	}
}