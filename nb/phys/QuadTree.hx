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

    override public function new(x:Float, y:Float, w:Float, h:Float, quadTree:QuadTree) {
        super(x,y,w,h,quadTree);
        this.quadTree = quadTree;
    }
}

class QuadTree extends Quad {
    override public function new(x:Float, y:Float, w:Float, h:Float, ?parent:Object) {
        super(x,y,w,h,null);
        var firstQuad:Quad = new Quad(x,y,w,h,this);
        childQuads.push(firstQuad);
    }
}