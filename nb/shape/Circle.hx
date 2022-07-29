package nb.shape; 

/**
 * Represents a circle.
 *
 * @since 0.1.0
 **/
class Circle extends Shape {
    /** The associated `h2d.col.Circle` instance of this shape. **/
    public var col(default, null):h2d.col.Circle;
    /** The radius of this circle. **/
    public var radius(get,set):Float;

    /**
     * Creates an `nb.shape.Circle` instance.
     *
     * @param radius The radius of the circle.
     * @param cx The x position of the center of the circle.
     * @param cy The y position of the center of the circle.
     * @param parent The parent object of the instance.
     **/
    public function new(radius:Float, cx:Float=0, cy:Float=0, ?parent:h2d.Object) {
        super(parent);
        defs.push(CIRCLE);

        col = new h2d.col.Circle(cx,cy,radius);
        updateFields();
    }

    /** Returns in an array the farthest point in the direction defined by `vector`. **/
    public function getFarthestPoints(vector:Point):Array<Point> return [vector.normalized().multiply(radius)];
    /** Returns `true` if the shape contains the point `p`. **/
    public function containsPoint(p:Point):Bool return col.contains(p);

    /** Draws the debug visualizations of this instance. **/
    public function debugDraw(?color:Int) {
        debugG.clear();
        debugG.params.lineColor = color == null ? 0x880088 : color;
        debugG.drawCircle(0,0,radius,0);
        debugG.drawLine(0,0,radius,0);
        if (children[children.length-1] != debugG) addChild(debugG);
    }

    /** Removes the debug visualizations of this instance. **/
    public function clearDebugDraw() {
        debugG.clear();
        debugG.remove();
    }

    /**
     * Creates a polygon in the shape of this circle.
     * 
     * @param nSegments The number of segments of the polygon. The minimum is 3 segments. 
     * `0` means it will be decided automatically.
     * @return An `nb.shape.Polygon` instance.
     **/
    public function asPolygon(nSegments:Int=0):Polygon return Polygon.makeCircle(col.x,col.y,radius,nSegments);

    /** Returns a string representation of this instance. **/
    override public function toString():String {
        return "Circle: {x:"+col.x+",y:"+col.y+",r:"+col.ray+"}";
    }

    public function updateFields() {
        center.set(col.x,col.y);
        centroid.set(col.x,col.y);
        setSize(radius*2,radius*2);
    }

    private function get_radius():Float return col.ray;

    private function set_radius(v:Float) {
        col.ray = v;
        setSize(radius*2,radius*2);
        return col.ray;
    }
}