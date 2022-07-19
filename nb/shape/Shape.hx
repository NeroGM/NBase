package nb.shape;

import nb.Graphics;

/** Values used to categorize a shape. **/
enum ShapeDef {
    CIRCLE;
    POLYGON;
    RECTANGLE;
    COMPLEX;
}

/**
 * Represents a shape.
 *
 * @since 0.1.0
 **/
abstract class Shape extends Object {
    /** The definers of the shape. **/
    public var defs(default, null):Array<ShapeDef> = [];
    /** The centroid of the shape. **/
    public var centroid:Point = new Point();
    /** The center of the shape. **/
    public var center:Point = new Point();
    /** An `nb.Graphics` instance used to draw debug visualizations. **/
    private var debugG:Graphics = null;

    /**
     * Creates an `nb.shape.Shape` instance.
     * 
     * @param parent The parent object of the instance. 
     **/
    public function new(?parent) {
        super(0,0,parent);
        debugG = new Graphics(0,0,this);
    }

    /** Returns `true` if the shape contains the point `p`. **/
    abstract public function containsPoint(p:Point):Bool;
    /** Draws the debug visualizations of this instance. **/
    abstract public function debugDraw(?color:Int):Void;
    /** Returns the farthest point in the direction defined by `vector`. **/
    abstract public function getFarthestPoint(vector:Point):Point;
}