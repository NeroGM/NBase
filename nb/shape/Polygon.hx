package nb.shape;

using h2d.col.Polygon;
using nb.ext.SegmentExt;

class Polygon extends Shape {
    public var points(default, null):h2d.col.Polygon;
    public var rightSideFaceInside:Bool = false;

    public function new(points:h2d.col.Polygon, ?parent:h2d.Object) {
        if (points.length < 3) throw "You need at least 3 points for the polygon.";
        super(parent);

        types.push(POLYGON);
        this.points = points;
        centroid = points.centroid();
        rightSideFaceInside = points.toSegments()[0].side(centroid) >= 0;

        updateFields();
    }

    override public function toString():String {
        return "Polygon: "+Std.string(points);
    }

    public function containsPoint(p:Point):Bool return points.contains(p);

    public function toSegments():h2d.col.Segments return points.toSegments();

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

    public function getSupportPoint(vector:Point):Point {
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

    public function getSegmentsIntersections(a:Array<Segment>):Array<Segment> {
        var res:Array<Segment> = [];
        for (seg1 in points.toSegments()) for (seg2 in a)
            if (nb.phys.Collision.checkSegments(seg1.getA(), seg1.getB(), seg2.getA(), seg2.getB()) > 0)
                { res.push(seg1); break; }

        return res;
    }

    public function updateFields() {
        var rightP = getSupportPoint(new Point(1,0));
        var leftP = getSupportPoint(new Point(-1,0));
        var topP = getSupportPoint(new Point(0,-1));
        var botP = getSupportPoint(new Point(0,1));
        setSize(Math.abs(rightP.x-leftP.x),Math.abs(topP.y-botP.y));
        center.set(leftP.x+size.w/2,topP.y+size.h/2);
    }

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

    public static inline function makeCircle(cx:Float, cy:Float, radius:Float, nSegments:Int = 0):Polygon {
        return new Polygon(h2d.col.Polygon.makeCircle(cx,cy,radius,nSegments));
    }

    public static function getMinkowskiDiff(points1:Array<Point>, points2:Array<Point>) {
        return [for (p1 in points1) for (p2 in points2) p1.sub(p2)];
    }
}