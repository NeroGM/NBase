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
        super(0,0,w,h,parentQuad);
        setPosition(x,y);
        this.quadTree = quadTree;

        if (parentQuad == null) return;
        this.parentQuad = parentQuad;
        this.parentQuad.childQuads.push(this);
    }
}

class QuadTree extends Quad {
    override public function new(x:Float, y:Float, w:Float, h:Float, ?parent:Object) {
        super(x,y,w,h,this,null);
    }
}