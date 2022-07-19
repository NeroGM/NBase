package nb.shape;

import nb.Graphics;

enum ShapeDef {
    CIRCLE;
    POLYGON;
    RECTANGLE;
    COMPLEX;
}

abstract class Shape extends Object {
    public var defs(default, null):Array<ShapeDef> = [];
    public var centroid:Point = new Point();
    public var center:Point = new Point();
    private var debugG:Graphics = null;

    public function new(?parent) {
        super(0,0,parent);
        debugG = new Graphics(0,0,this);
    }

    abstract public function containsPoint(p:Point):Bool;
    abstract public function debugDraw(?color:Int):Void;
    abstract public function getSupportPoint(vector:Point):Point;
}