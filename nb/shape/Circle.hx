package nb.shape; 

class Circle extends Shape {
    public var col(default, null):h2d.col.Circle;
    public var radius(get,set):Float;

    public function new(radius:Float, ?cx:Float=0, ?cy:Float=0, ?parent:h2d.Object) {
        super(parent);
        defs.push(CIRCLE);

        col = new h2d.col.Circle(cx,cy,radius);
        center.set(cx,cy);
        centroid.set(cx,cy);
        setSize(radius*2,radius*2);
    }

    public function set_radius(v:Float) {
        col.ray = v;
        setSize(radius*2,radius*2);
        return col.ray;
    }

    public function getFarthestPoint(vector:Point):Point return vector.normalized().multiply(radius);

    public function containsPoint(p:Point):Bool return col.contains(p);

    private function get_radius():Float return col.ray;

    public function debugDraw(?color:Int) {
        debugG.clear();
        debugG.params.lineColor = color == null ? 0x880088 : color;
        debugG.drawCircle(0,0,radius,0);
        debugG.drawLine(0,0,radius,0);
    }

    public function asPolygon(nSegments:Int=0):Polygon return Polygon.makeCircle(col.x,col.y,radius,nSegments);
}