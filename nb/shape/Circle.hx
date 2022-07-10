package nb.shape; 

// import nb.utils.Timer;

class Circle extends Shape {
    public var col(default, null):h2d.col.Circle;
    public var radius(default,set):Float = 0;

    public function new(radius:Float, ?cx:Float=0, ?cy:Float=0) {
        type = CIRCLE;super(parent);

        // Timer.time( () -> {
        
        col = new h2d.col.Circle(cx,cy,radius);
        this.radius = radius;
        center.set(cx,cy);
        centroid.set(cx,cy);
       
        
    //    debugG = new Graphics(0,0,this);

        setSize(radius*2,radius*2); 
    // }, "obj2");
    }

    public function set_radius(v:Float) {
        col.ray = v;
        setSize(radius*2,radius*2);
        return radius = v;
    }

    public function withTransform(offset:Point):Shape {
        return new Circle(radius, col.x+offset.x, col.y+offset.y);
    }

    public function getSupportPoint(vector:Point):Point return vector.normalized().multiply(radius);

    public function containsPoint(p:Point):Bool return col.contains(p);

    // public function debugDraw(?color:Int) {
    //     var params = Graphics.getDefaultParams()[0];
    //     params.lineColor = color == null ? 0x880088 : color;
    //     debugG.drawCircle(0,0,radius,0,"_",params);
    //     debugG.drawLine(0,0,radius,0,"_",params);
    // }

    public function asPolygon(nSegments:Int=0):Polygon return Polygon.makeCircle(col.x,col.y,radius,nSegments);
}