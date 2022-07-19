package nb.shape;

using nb.ext.SegmentExt;

/**
 * Represents a polygon.
 *
 * @since 0.1.0
 **/
class Polygon extends Shape {
    /**
     * The associated `h2d.col.Polygon` instance, which is an abstract type defined over an `Array<h2d.col.Point>`.
     * @see https://haxe.org/manual/types-abstract.html
     **/
    public var points(default, null):h2d.col.Polygon;
    /** Whether the right side of the segments of the polygon face inwards. **/
    public var rightSideFaceInside(default,null):Bool = false;

    /**
     * Creates an `nb.shape.Polygon` instance.
     * 
     * @param points An array of `h2d.col.Point` defining the polygon.
     * @param parent The parent object of this instance.
     **/
    public function new(points:h2d.col.Polygon, ?parent:h2d.Object) {
        if (points.length < 3) throw "You need at least 3 points for the polygon.";
        super(parent);

        defs.push(POLYGON);
        this.points = points;
        centroid = points.centroid();
        rightSideFaceInside = points.toSegments()[0].side(centroid) >= 0;

        updateFields();
    }

    /** The string representation of this instance. **/
    override public function toString():String {
        return "Polygon: "+Std.string(points);
    }

    /** Returns `true` if the shape contains the point `p`. **/
    public function containsPoint(p:Point):Bool return points.contains(p);

    /**
     * Returns the segments of this instance.
     *
     * `h2d.col.Segments` is an [abstract type](https://haxe.org/manual/types-abstract.html)
     * defined over `Array<h2d.col.Segment>`.
     **/
    public function toSegments():h2d.col.Segments return points.toSegments();

    /** Draws the debug visualizations of this instance. **/
    public function debugDraw(?color:Int) {
        debugG.clear();
        debugG.params.lineColor = color == null ? 0x880088 : color;
        debugG.drawPolygon(points);
        for (segment in points.toSegments()) {
            var dx = segment.dx;
            var dy = segment.dy;
            var normal:Point = rightSideFaceInside ? new Point(-dy,dx).normalized() : new Point(dy,-dx).normalized();
            var midP = new Point(segment.x+dx/2,segment.y+dy/2);
            debugG.params.lineColor = 0x0500ff;
            debugG.drawLine(midP.x,midP.y,midP.x+5*normal.x,midP.y+5*normal.y); // darkblue to inside
            debugG.params.lineColor = 0x00eaff;
            debugG.drawLine(midP.x,midP.y,midP.x-5*normal.x,midP.y-5*normal.y); // cyan to outside
        }
    }

    /** Returns the farthest point in the direction defined by `vector`. **/
    public function getFarthestPoint(vector:Point):Point {
		var highest:Null<Float> = null;
		var result:Point = new Point();
		for (p in points) {
            var p = p.clone();
            // if (entity != null && entity.parent != null) p.rotate(entity.parent.rotation); // use toGlobatPos ?
			var v = p.dot(vector);
			if (highest == null || v > highest) {
				highest = v;
				result = p;
			}
		}
		return result;
	}


    /**
     * Gets a point on the edge of this polygon.
     *
     * @param ray An `h2d.col.Ray` instance used to get the point.
     * @param outSeg An `h2d.col.Segment` instance where the intersecting point resides.
     * @return An `h2d.col.Point` instance. The first point on a segment of this polygon intersecting with `ray`. 
     **/
    public function getEdgePoint(ray:h2d.col.Ray, ?outSeg:Segment):Null<Point> {
        var smallestDist:Float = 1000000;
        var p:Point = null;
        var dir = ray.getDir();
        for (seg in points.toSegments()) {
            var inters = seg.lineIntersection(ray);
            if (inters == null || ((inters.x >= 0) != (dir.x >= 0) || (inters.y >= 0) != (dir.y >= 0))) continue;

            var dist = inters.distance(new Point(ray.px,ray.py));
            if (dist > smallestDist) continue;

            smallestDist = dist;
            p = inters.clone();
            if (outSeg != null) {
                outSeg.x = seg.x; outSeg.y = seg.y;
                outSeg.dx = seg.dx; outSeg.dy = seg.dy;
            }
        }
        return p;
    }

    /** Returns the segments of this polygon intersecting with the given segments `a`. **/
    public function getSegmentsIntersections(a:Array<Segment>):Array<Segment> {
        var res:Array<Segment> = [];
        for (seg1 in points.toSegments()) for (seg2 in a)
            if (nb.phys.Collision.checkSegments(seg1.getA(), seg1.getB(), seg2.getA(), seg2.getB()) > 0)
                { res.push(seg1); break; }

        return res;
    }

    /** Updates fields related to this polygon current attributes, as deduced from `points`. **/
    public function updateFields() {
        var rightP = getFarthestPoint(new Point(1,0));
        var leftP = getFarthestPoint(new Point(-1,0));
        var topP = getFarthestPoint(new Point(0,-1));
        var botP = getFarthestPoint(new Point(0,1));
        setSize(Math.abs(rightP.x-leftP.x),Math.abs(topP.y-botP.y));
        center.set(leftP.x+size.w/2,topP.y+size.h/2);
    }

    /**
     * Returns the farthest points of this polygon from its center or centroid.
     *
     * @param fromCentroid If `true`, the points must be the farthest from the centroid.
     * Otherwise they are the farthest from the center.
     * @return An array of `h2d.col.Point`. Only the points that are the farthest are returned,
     * not all the points of this polygon from the farthest to the closest.
     **/
    public function getFarthestPoints(fromCentroid:Bool=true):Array<Point> {
        var highestDist:Float = 0;
        var res:Array<Point> = [];
        for (p in points) {
            var dist = p.distance(fromCentroid ? centroid : center);
            if (dist == highestDist) res.push(p);
            else if (dist > highestDist) { highestDist = dist; res = [p]; }
        }
        return res;
    }

     /**
     * Creates a polygon in the shape of a circle.
     * 
     * @param radius The radius of the circle.
     * @param cx The x position of the center of the circle.
     * @param cy The y position of the center of the circle.
     * @param nSegments The number of segments of the circle. The minimum is `3`. 
     * `0` means it will be decided automatically.
     * @return An `nb.shape.Polygon` instance.
     **/
    public static inline function makeCircle(radius:Float, cx:Float=0, cy:Float=0, nSegments:Int=0):Polygon {
        return new Polygon(h2d.col.Polygon.makeCircle(cx,cy,radius,nSegments));
    }

    /**
     * Returns the minkowski difference between two polygons.
     * 
     * Here are some nice properties of the minkowski difference:
     * - If it contains the origin, that means the two shapes intersects.
     * - The minimum distance between the origin and the points of the minkowski difference
     * is the distance between the two shapes.
     * 
     * @param points1 An array of `h2d.col.Point` defining the shape of the first polygon.
     * @param points2 An array of `h2d.col.Point` defining the shape of the second polygon.
     * @return An array of `h2d.col.Point` defining the shape of the minkowski difference.
     **/
    public static inline function getMinkowskiDiff(points1:Array<Point>, points2:Array<Point>):Array<Point> {
        return [for (p1 in points1) for (p2 in points2) p1.sub(p2)];
    }
}