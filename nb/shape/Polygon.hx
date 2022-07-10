package nb.shape;

using h2d.col.Polygon;

class Polygon extends Shape {
    public var points(default, null):h2d.col.Polygon;
    public var rightSideFaceInside:Bool = false;

    public function new(points:h2d.col.Polygon, ?parent:h2d.Object) {
        super(parent);
        type = POLYGON;
        this.points = points;

        if (points.length < 3) throw "??";
        centroid = points.centroid();
        rightSideFaceInside = points.toSegments()[0].side(centroid) >= 0;

        updateSizeAndOffset();        
    }

    override public function toString():String {
        return Std.string(points);
    }

    public function withTransform(offset:Point):Shape {
        return new Polygon([for (p in points) p.add(offset)]);
    }

    public function containsPoint(p:Point):Bool return points.contains(p);

    public function toSegments():h2d.col.Segments return points.toSegments();

    // public function debugDraw(?color:Int) {
    //     debugG.clear();
    //     var gParams = Graphics.getDefaultParams(3);
    //     gParams[0].lineColor = 0x0500ff;
    //     gParams[1].lineColor = 0x00eaff;
    //     gParams[2].lineColor = color == null ? 0x880088 : color;
    //     debugG.drawPolygon(points,"_",gParams[2]);
    //     for (segment in points.toSegments()) {
    //         var dx = segment.dx;
    //         var dy = segment.dy;
    //         var normal:Point = rightSideFaceInside ? new Point(-dy,dx).normalized() : new Point(dy,-dx).normalized();
    //         var midP = new Point(segment.x+segment.dx/2,segment.y+segment.dy/2);
    //         debugG.drawLine(midP.x,midP.y,midP.x+5*normal.x,midP.y+5*normal.y,"_",gParams[0]); // darkblue to inside
    //         debugG.drawLine(midP.x,midP.y,midP.x-5*normal.x,midP.y-5*normal.y,"_",gParams[1]); // cyan to outside
    //     }
    // }

    public function traverse():Array<Point> { // test function, no real utility
        var a:Array<Point> = [];
        var vec:Point = new Point(1,1);
        var startingP:Point = getSupportPoint(vec);
        var startI:Int = 0;
        var i:Int = 0;
        for (i2 in 0...points.length) if (points[i2].equals(startingP)) {
            startI = i = i2; break;
        }
        var onP:Point = startingP;
        for (_ in 0...4) {
            var prevI:Int = i-1 < 0 ? points.length-1 : i-1;
            var nextI:Int = i+1 >= points.length ? 0 : i+1;
            var prevP:Point = points[prevI];
            var nextP:Point = points[nextI];
            var a2 = [prevP,nextP];
            nb.ext.ArrayExt.quickSort(a2, (v1,v2) -> {
                // Todo: add to utils
                var vec = vec.normalized(); 
                var p1 = v1.sub(onP).normalized(); var dp1 = vec.dot(p1);
                var p2 = v2.sub(onP).normalized(); var dp2 = vec.dot(p2);
                var v1 = vec.cross(p1) >= 0 ? dp1 : (dp1*-1)-2;
                var v2 = vec.cross(p2) >= 0 ? dp2 : (dp2*-1)-2;
                return v1 > v2;
            });
            trace(onP + "    " + vec.normalized() +  "   " + a2);
            i = i+1 >= points.length ? 0 : i+1;
            vec = points[i].sub(onP).multiply(-1);
            onP = points[i];
        }

        return a;
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

    public function getEdgePoint(ray:h2d.col.Ray, ?outSeg:Segment):Point {
        var segments = points.toSegments();
        var smallestDist:Float = 1000000;
        var p:Point = null;
        for (seg in segments) {
            var inters = seg.lineIntersection(ray);
            if (inters == null) continue;
            var dist = inters.distance(new Point(ray.px,ray.py));
            if (dist > smallestDist) continue;
            smallestDist = dist;
            p = inters.clone();
            if (outSeg != null) {
                outSeg.x = seg.x; outSeg.y = seg.y;
                outSeg.dx = seg.dx; outSeg.dy = seg.dy;
            }
        }
    //    trace(p + "   " + smallestDist);
        return p;
    }

    public function getSegmentsIntersections(a:Array<Segment>):Array<Segment> {
        var res:Array<Segment> = [];
        for (seg1 in points.toSegments()) for (seg2 in a)
            if (nb.phys.Collision.checkSegments(new Point(seg1.x,seg1.y), new Point(seg1.x+seg1.dx,seg1.y+seg1.dy), new Point(seg2.x,seg2.y), new Point(seg2.x+seg2.dx,seg2.y+seg2.dy)) > 0)
                { res.push(seg1); break; }

        return res;
    }

    public function updateSizeAndOffset() {
        var rightP = getSupportPoint(new Point(1,0));
        var leftP = getSupportPoint(new Point(-1,0));
        var topP = getSupportPoint(new Point(0,-1));
        var botP = getSupportPoint(new Point(0,1));
        setSize(Math.abs(rightP.x-leftP.x),Math.abs(topP.y-botP.y));
        center.set(leftP.x+size.w/2,topP.y+size.h/2);
    //    setOffset(size.w/2,size.h/2); useless?
    }

    public function getFarthestPoints():Array<Point> {
        var highestDist:Float = 0;
        var res:Array<Point> = [];
        for (p in points) {
            var dist = p.distance(centroid);
            if (dist == highestDist) res.push(p);
            else if (dist > highestDist) res = [p];
        }
        return res;
    }

    public static function makeCircle(cx:Float, cy:Float, radius:Float, nSegments:Int = 0):Polygon {
        return new Polygon(h2d.col.Polygon.makeCircle(cx,cy,radius,nSegments));
    }

    public static function getMinkowskiDiff(points1:Array<Point>, points2:Array<Point>) {
    /*    var res = [for (p1 in points1) for (p2 in points2) p1.sub(p2)];
        var pol = new Polygon(res);
        var res2 = [for (p in res) pol.getSupportPoint(p)];
        Manager.currentScene.add(g,0);
        g.clear();
        var gParams = Graphics.getDefaultParams(3);
        gParams[0].lineColor = 0xff0000;
        gParams[2].lineColor = 0x880088;
        g.drawCircle(0,0,1,1,"g1",gParams[0]);
        g.drawPolygon(res,"g2",gParams[1]);
        g.drawPolygon(pol.points.convexHull(),"g2",gParams[2]);
        g.graphics[1].alpha = 0.3; */
    //    trace(res +"     " + res2);
        return [for (p1 in points1) for (p2 in points2) p1.sub(p2)];
    }
}