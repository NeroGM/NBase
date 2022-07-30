package nb.phys;

import nb.shape.*;

class QTElement {
    public var o:Object;
    public var quadTree:QuadTree;

    public function new(o:Object, quadTree:QuadTree) {
        this.o = o;
        this.quadTree = quadTree;
    }
}

class Quad extends Rectangle {
    public var elements:Array<QTElement> = [];
    public var quadTree:QuadTree;
    public var parentQuad:Quad = null;
    public var siblings:Array<Quad> = [];
    public var childQuads:Array<Quad> = [];
    public var maxBucketSize:Int = 4;

    override private function new(x:Float, y:Float, w:Float, h:Float, quadTree:QuadTree, ?parentQuad:Quad) {
        super(x,y,w,h,quadTree);
        this.quadTree = quadTree;
        this.parentQuad = parentQuad == null ? quadTree : parentQuad;
    }
}

class QuadTree extends Quad {
    override public function new(x:Float, y:Float, w:Float, h:Float, ?parent:Object) {
        super(x,y,w,h,null);
    }
}