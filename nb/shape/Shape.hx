package nb.shape;

enum ShapeType {
    POLYGON;
    CIRCLE;
    COMPLEX;
}

enum ShapeSubType {
    RECTANGLE;
    NONE;
}

abstract class Shape extends Object {
    public var type(default, null):ShapeType;
    public var subType(default, null):ShapeSubType = NONE;
    public var centroid:Point = new Point();
    public var center:Point = new Point();
    // private var debugG:Graphics = null;

    public function new(?parent) {
        super(0,0,parent);
        // debugG = nb.utils.Timer.time(() -> new Graphics(0,0,this), "obj3");
    }

    abstract public function withTransform(offset:Point):Shape;
    abstract public function containsPoint(p:Point):Bool;
    // abstract public function debugDraw(?color:Int):Void;
    abstract public function getSupportPoint(vector:Point):Point;

    override public function onRemove() {
        // debugG.clear();
        // debugG.remove();
        super.onRemove();
    }
}