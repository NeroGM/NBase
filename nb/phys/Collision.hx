package nb.phys;

using nb.ext.FloatExt;
using nb.ext.PointExt;
using nb.ext.SegmentExt;
using nb.ext.ArrayExt;
import nb.shape.*;

/**
 * A class to test collisions.
 *
 * @since 0.1.0
 **/
class Collision {

	/** Returns `true` if two shapes bounding boxes collides. **/
	public static function checkAABB(shape1:Shape, shape2:Shape):Bool {
		var b1 = shape1.aabbBounds;
		var b2 = shape2.aabbBounds;
		var min1 = shape1.localToGlobal(b1.getMin());
		var min2 = shape2.localToGlobal(b2.getMin());
		var max1 = shape1.localToGlobal(b1.getMax());
		var max2 = shape2.localToGlobal(b2.getMax());
		var d1x = min2.x - max1.x;
		var d1y = min2.y - max1.y;
		var d2x = min1.x - max2.x;
		var d2y = min1.y - max2.y;
		if (d1x > 0 || d1y > 0 || d2x > 0 || d2y > 0) return false;
		return true;
	}

	/**
	 * Checks if two rays intersects, and where.
	 *
	 * If it returns a number >= 0, they intersects.
	 *
	 * @param p1 Point A of a segment on the first ray.
	 * @param p2 Point B of a segment on the first ray.
	 * @param p3 Point A of a segment on the second ray.
	 * @param p4 Point B of a segment on the second ray.
	 * @param outIntersection If set, this point will be set to the intersection coordinate.
	 * @return `3` if  the two rays intersects on both segments, `2` if the two rays intersects on the
	 * segment of the second ray, `1` if they intersects on the segment of the first ray, `0` if they
	 * intersects but not on any of the two segments, `-1` if they don't intersect.
	 **/
	public static function checkRays(p1:Point, p2:Point, p3:Point, p4:Point, ?outIntersection:Point):Int {
		var denominator = ((p4.y-p3.y)*(p2.x-p1.x)) - ((p4.x-p3.x)*(p2.y-p1.y));
		if (denominator == 0) return -1;

		var v1 = p1.y-p3.y;
		var v2 = p1.x-p3.x;
		var num1 = ((p4.x-p3.x)*v1) - ((p4.y-p3.y)*v2);
		var num2 = ((p2.x-p1.x)*v1) - ((p2.y-p1.y)*v2);
		v1 = num1 / denominator;
		v2 = num2 / denominator;

		if (outIntersection != null) {
			outIntersection.x = p1.x + (v1 * (p2.x-p1.x));
			outIntersection.y = p1.y + (v1 * (p2.y-p1.y));
		}

		var onLine1:Bool = v1 > 0 && v1 < 1;
		var onLine2:Bool = v2 > 0 && v2 < 1;
		if (onLine1 && onLine2) return 3;
		if (!onLine1 && onLine2) return 2;
		if (onLine1 && !onLine2) return 1;
		return 0;
	}

	/**
	 * Checks if two segments intersects, and where.
	 *
	 * If it returns a number > 0, they intersects.
	 *
	 * @param p1 Point A of the first segment.
	 * @param p2 Point B of the first segment.
	 * @param p3 Point A of the seocnd segment.
	 * @param p4 Point B of the seocnd segment.
	 * @param outIntersection If set, this point will be set to contain the intersection coordinate.
	 * @param outOverlap If set, this segment will be set to contain the overlapping part of the two segments.
	 * @return `2` if the segments are colinear and overlaps, `1` if they intersects on a point, `0` if they are colinear but disjoint,
	 * `-1` if they are parallel and don't intersect, `-2` if they are not parallel and don't intersect.
	 **/
	public static function checkSegments(p1:Point, p2:Point, p3:Point, p4:Point, ?outIntersection:Point, ?outOverlap:Segment):Int {
		if (p1.equals(p2) || p3.equals(p4)) return 0;

		var p = p1;
		var q = p3;
		var r = new Point(p2.x-p1.x,p2.y-p1.y);
		var s = new Point(p4.x-p3.x,p4.y-p3.y);
		var q_minus_p = q.sub(p);
		var rs = r.cross(s);
		var qpr = q_minus_p.cross(r);

		if (rs == 0) {
			if (qpr == 0) { // Colinear
				var rr = r.dot(r);
				var t0 = q_minus_p.dot(r) / rr;
				var t1 = q_minus_p.add(s).dot(r) / rr;
				if ((t0 >= 0 && t0 <= 1) || (t1 >= 0 && t1 <= 1) || (t0 < 0 && t1 >= 0) || (t0 > 1 && t1 <= 1)) { // Colinear + Overlap = 2
					if (outOverlap != null || outIntersection != null) {
						var a = [p1,p2,p3,p4];
						if (r.x > 0) nb.ext.ArrayExt.quickSort(a,(p1,p2) -> p1.x <= p2.x);
						else if (r.x < 0) nb.ext.ArrayExt.quickSort(a,(p1,p2) -> p1.x >= p2.x);
						else if (r.y > 0) nb.ext.ArrayExt.quickSort(a,(p1,p2) -> p1.y <= p2.y);
						else nb.ext.ArrayExt.quickSort(a,(p1,p2) -> p1.y >= p2.y);
						if (outOverlap != null) outOverlap.setPoints(a[1],a[2]);
						if (outIntersection != null) outIntersection.set(a[1].x,a[1].y);
					}
					return 2;
				}
				return 0; // Colinear + Disjoint = 0
			}
			return -1; // Parallel = -1
		}

		var t = q_minus_p.cross(s) / rs;
		var u = qpr / rs;
		if (t >= 0 && t <= 1 && u >= 0 && u <= 1) { // Intersection = 1
			if (outIntersection != null || outOverlap != null) {
				var intersection = p.add(r.multiply(t));
				if (outIntersection != null) outIntersection.set(intersection.x,intersection.y);
				if (outOverlap != null) outOverlap.setPoints(intersection,intersection);
			}
			return 1;
		}

		return -2; // Not parallel + Not intersecting = -2
	}

	/**
	 * Returns the intersection points between two shapes.
	 *
	 * Those two shapes should be in the same scene, otherwise the result is undefined.
	 *
	 * @param shape1 The first `nb.shape.Shape` instance.
	 * @param shape2 The second `nb.shape.Shape` instance.
	 * @param relativeTo The intersection points be will be in this object's coordinate space.
	 * If `null`, the intersection points will be in the coordinate space of `shape1`'s scene.
	 * @return An array containing the intersection points.
	 * `null` if there's no function implemented for these two shape types.
	 **/
	public static function getIntersections(shape1:Shape, shape2:Shape, ?relativeTo:h2d.Object):Array<Point> {
		if (shape1 is Polygon && shape2 is Circle)
			return getIntersectionsPolCir(cast(shape1,Polygon),cast(shape2,Circle),relativeTo);
		else if (shape1 is Circle && shape2 is Polygon)
			return getIntersectionsPolCir(cast(shape2,Polygon),cast(shape1,Circle),relativeTo);
		else if (shape1 is Polygon && shape2 is Polygon)
			return getIntersectionsPolPol(cast(shape1,Polygon),cast(shape2,Polygon),relativeTo);
		else if (shape1 is Circle && shape2 is Circle)
			return getIntersectionsCirCir(cast(shape1,Circle),cast(shape2,Circle),relativeTo);

		return null;
	}

	/**
	 * Returns the intersection points between a polygon and a circle.
	 *
	 * Those two shapes should be in the same scene, otherwise the result is undefined.
	 *
	 * @param pol An `nb.shape.Polygon` instance.
	 * @param cir An `nb.shape.Circle` instance.
	 * @param relativeTo The intersection points be will be in this object's coordinate space.
	 * If `null`, the intersection points will be in the coordinate space of `pol`'s scene.
	 * @return An array containing the intersection points.
	 **/
	public static function getIntersectionsPolCir(pol:Polygon, cir:Circle, ?relativeTo:h2d.Object):Array<Point> {
		var p = cir.localToGlobal();
		var circle = new h2d.col.Circle(p.x,p.y,cir.radius);
		var points:Set<Point> = new Set();
		for (s in pol.toSegments()) {
			var seg = new Segment(pol.localToGlobal(new Point(s.x,s.y)),pol.localToGlobal(new Point(s.x+s.dx,s.y+s.dy)));
			var a = getIntersectionsSegCir(seg,circle);
			if (a != null) for (p in a) points.add(p.relativeTo(relativeTo == null ? pol.getScene() : relativeTo));
		}

		return points.toArray();
	}

	/**
	 * Returns the intersection points between two polygons.
	 *
	 * Those two shapes should be in the same scene, otherwise the result is undefined.
	 *
	 * @param pol1 A first `nb.shape.Polygon` instance.
	 * @param pol2 A second `nb.shape.Polygon` instance.
	 * @param relativeTo The intersection points be will be in this object's coordinate space.
	 * If `null`, the intersection points will be in the coordinate space of `pol1`'s scene.
	 * @return An array containing the intersection points.
	 **/
	public static function getIntersectionsPolPol(pol1:Polygon, pol2:Polygon, ?relativeTo:h2d.Object):Array<Point> {		
		var a = [pol1,pol2];
		for (i in 0...2) {
			var polygon1 = a[i];
			var polygon2 = a[(i+1)%2];
			var segments = polygon1.points.toSegments();
			for (segment in segments) {
				var allInFront:Bool = true;
				var rsfi = polygon1.rightSideFaceInside;
				for (p in polygon2.points) {
					var p2 = polygon1.globalToLocal(polygon2.localToGlobal(p.clone()));
					var side = segment.side(p2);
					if ((rsfi && side >= 0) || (!rsfi && side < 0)) { allInFront = false; break; }
				}
				if (allInFront) return [];
			}
		}

		var intersections:Set<Point> = new Set();
		for (seg1 in pol1.toSegments()) for (seg2 in pol2.toSegments()) {
			var p1 = pol1.localToGlobal(seg1.getA());
			var p2 = pol1.localToGlobal(seg1.getB());
			var p3 = pol2.localToGlobal(seg2.getA());
			var p4 = pol2.localToGlobal(seg2.getB());
			var inters:Point = new Point();
			if (checkSegments(p1,p2,p3,p4,inters) > 0) {
				intersections.add(inters.relativeTo(relativeTo == null ? pol1.getScene() : relativeTo));
			}
		}
		return intersections.toArray();
	}

	/**
	 * Returns the intersection points between two circles.
	 *
	 * Those two shapes should be in the same scene, otherwise the result is undefined.
	 *
	 * @param cir1 A first `nb.shape.Circle` instance.
	 * @param cir2 A second `nb.shape.Circle` instance.
	 * @param relativeTo The intersection points be will be in this object's coordinate space.
	 * If `null`, the intersection points will be in the coordinate space of `cir1`'s scene.
	 * @return An array containing the intersection points.
	 **/
	public static function getIntersectionsCirCir(cir1:Circle, cir2:Circle, ?relativeTo:h2d.Object):Array<Point> {
		var rel = relativeTo == null ? cir1.getScene() : relativeTo;

		var p1 = cir1.localToGlobal(new Point(cir1.col.x,cir1.col.y));
		var p2 = cir2.localToGlobal(new Point(cir2.col.x,cir2.col.y));
		var r1 = cir1.radius;
		var r2 = cir2.radius;
		var d = p1.distance(p2);

		if (d > r1+r2 || d < Math.abs(r1-r2)) return [];
		else if (d == 0 && r1 == r2) return [p1.relativeTo(rel)];

		var a = (r1*r1-r2*r2+d*d) / (2*d);
		var h = Math.sqrt(r1*r1-a*a);
		var ray = h2d.col.Ray.fromPoints(p1, p2);
		var p3 = ray.getPoint(a);

		var p4 = new Point(p3.x + h*(p2.y-p1.y)/d, p3.y - h*(p2.x-p1.x)/d).relativeTo(rel);
		var p5 = new Point(p3.x - h*(p2.y-p1.y)/d, p3.y + h*(p2.x-p1.x)/d).relativeTo(rel);
		return [p4,p5];
	}

	/**
	 * Returns the intersection points between a segment and a circle.
	 *
	 * The segment and circle should be in the same coordinate space.
	 *
	 * @param seg An `h2d.col.Segment` instance.
	 * @param circle An `h2d.col.Circle` instance.
	 * @return An array containing the intersection points.
	 **/
	// https://stackoverflow.com/questions/1073336/circle-line-segment-collision-detection-algorithm
	public static function getIntersectionsSegCir(seg:Segment,circle:h2d.col.Circle):Array<Point> {
		var d = new Point(seg.dx,seg.dy);
		var f = seg.getA().sub(new Point(circle.x,circle.y));
		var r = circle.ray;

		var a = d.dot(d);
		var b = 2*f.dot(d);
		var c = f.dot(f) - r*r;

		var discriminant = b*b-4*a*c;
		if( discriminant < 0 ) return []; // No intersection

		discriminant = Math.sqrt( discriminant );
		// either solution may be on or off the ray so need to test both
		// t1 is always the smaller value, because BOTH discriminant and
		// a are nonnegative.
		var t1 = (-b - discriminant)/(2*a);
		var t2 = (-b + discriminant)/(2*a);

		// 3x HIT cases:
		//          -o->             --|-->  |            |  --|->
		// Impale(t1 hit,t2 hit), Poke(t1 hit,t2>1), ExitWound(t1<0, t2 hit), 
		
		// 3x MISS cases:
		//       ->  o                     o ->              | -> |
		// FallShort (t1>1,t2>1), Past (t1<0,t2<0), CompletelyInside(t1<0, t2>1)
		
		if (t1 >= 0 && t1 <= 1) { // Poke
			var res = [new Point(seg.x+t1*d.x,seg.y+t1*d.y)];

			if (t2 >= 0 && t2 <= 1) { // Impale
				var p = new Point(seg.x+t2*d.x,seg.y+t2*d.y);
				if (!p.x.equals(res[0].x) || !p.y.equals(res[0].y)) res.push(p);
			}

			return res;
		}

		if (t2 >= 0 && t2 <= 1) return [new Point(seg.x+t2*d.x,seg.y+t2*d.y)]; // ExitWound

		// No intersection : FallShort || Past || CompletelyInside
		return [];
	}

	/**
	 * Returns a minimum translation vector needed for two polygons to collide or separate.
	 *
	 * Make sure that the two polygons are in the same scene.
	 *
	 * @param pol1 The first polygon.
	 * @param pol2 The second polygon.
	 * @return If they don't intersects, the minimum translation vector needed to separate `pol2` from
	 * `pol1`. Otherwise, returns the minimum translation vector needed for `pol2` to collide with `pol1`.
	 **/
	public static function checkDistance(pol1:Polygon, pol2:Polygon):Point {
		var rel = pol1.getScene();
		if (rel == null) { trace("checkDistance: pol1 doesn't have a scene."); return new Point(); }
		var rel2 = pol2.getScene();
		if (rel2 == null) { trace("checkDistance: pol2 doesn't have a scene."); return new Point(); }
		else if (rel != rel2) { trace("checkDistance: pol2 isn't in the same scene as pol1."); return new Point(); }

		var a1 = [for (p in pol1.points) p.relativeTo(rel,pol1)];
		var a2 = [for (p in pol2.points) p.relativeTo(rel,pol2)];
		var diff:h2d.col.Polygon = Polygon.getMinkowskiDiff(a1,a2);
		var minskDiff:Polygon = new Polygon(diff.convexHull());

		var newTarget:Point = null;
		var simplex:h2d.col.Polygon = [];
		var origin:Point = new Point();

		var newValue:Point = null;
		function isConverging():Bool {
			for (p in simplex) if (p != newValue) {
				var posDiff = new Point(Math.abs(p.x-newValue.x),Math.abs(p.y-newValue.y));
				var oAngle = Math.atan2(p.y,p.x);
				var newAngle = Math.atan2(newValue.y,newValue.x);
				var angleDiff = Math.abs(oAngle - newAngle);
				if (posDiff.x+posDiff.y+angleDiff <= 0.0001) return true;
			}
			return false;
		}

		function addPointToSimplex(vec:Point):Point {
			newValue = minskDiff.getFarthestPoints(vec)[0];
			simplex.push(newValue);
			return newValue;
		}

		var justRemovedP:Point = null;
		for (i in 0...1000) {			
			switch (simplex.length) {
				case 0: newTarget = minskDiff.points[0];
				case 1: newTarget = simplex[0];
				case 2:
					newTarget = simplex.toSegments()[0].project(origin);

					if (minskDiff.containsPoint(origin) && newTarget.equalEps(origin)) { // Fix for when simplex segment traverses origin
						var segs = minskDiff.toSegments();

						// If origin is on minskDiff edge, no need to go further, return (0,0).
						var p1 = simplex[0];
						var p2 = simplex[1];
						for (seg in segs) {
							var p3 = seg.getA();
							var p4 = seg.getB();
							if (checkSegments(p1,p2,p3,p4) == 2) {
								return origin;
							}
						}

						// Translate one of the simplex's points so that the segment doesn't intersect with the origin
						var onSeg:Segment = null;
						var segIndex:Int = -1;
						for (seg in segs) {
							segIndex++;
							if (seg.getA().equals(simplex[0])) { onSeg = seg; break; }
						}
						var perc:Float = 0;
						var segIndexInc:Int = 0;
						var p:Point = null;
						do {
							perc += 0.05;
							p = simplex[0].add(new Point(onSeg.dx*perc,onSeg.dy*perc));
							newTarget = new Segment(p,simplex[1]).project(origin);

							// Should happen only if using polygon with very close points
							// Should very rarely happen, also `diff.convexHull()` doesn't return points at the same coords
							if (perc == 1) {
								perc = 0.05;
								segIndexInc++;
								onSeg = segs.at(segIndex+segIndexInc);
								if (segIndexInc >= segs.length) throw "EPA max displacement reached.";
							}
						} while (newTarget.equalEps(origin));
						simplex[0] = p;
					}
				case 3:
					var segments = simplex.toSegments();
					var onSeg:Segment = null;
					function getClosestProjection():Point {
						var smallestDist:Float = Math.POSITIVE_INFINITY;
						var p:Point = null;
						for (seg in segments) {
							var v = seg.project(origin);
							var dist = v.distance(origin);
							if (p == null || dist < smallestDist) {
								smallestDist = dist;
								p = v;
								onSeg = seg;
							}
						}
						return p;
					}

					// EPA if true
					if (simplex.contains(origin)) {
						var oValue:Point = null;
						for (i in 0...1000) {
							var p = getClosestProjection();
							var v = addPointToSimplex(p);

							for (i in 0...segments.length) if (segments[i] == onSeg) {
								var seg = segments[i];
								var a = seg.getA();
								var b = seg.getB();
								if (a.equals(v) || b.equals(v)) { return p; }

								var newSeg1 = new Segment(seg.getA(),v);
								var newSeg2 = new Segment(v,seg.getB());
								segments[i] = newSeg1;
								segments.segments.insert(i+1,newSeg2);
								break;
							}

							if (oValue != null && p.equalEps(oValue)) return p;
							else oValue = p;
						}
						throw "checkDistance: max EPA loop count reached.";
						return null;
					}

					// Else continue GJK
					newTarget = getClosestProjection();
					if (newTarget.equalEps(origin)) return newTarget; // Fix for when newTarget == origin

					// Remove point from simplex
					function pCheck(p:Point):Bool {
						if (!p.equals(newTarget)) {
							for (v in simplex) if (v.equals(p)) {
								simplex.remove(v);
								justRemovedP = v;
								return true;
							}
							throw "Shouldn't happen.";
						}
						return false;
					}
					for (seg in segments) if (onSeg != seg) {
						if (pCheck(seg.getA())) break;
						if (pCheck(seg.getB())) break;
					}
				default: throw "Shouldn't happen.";
			}

			var justAdded = addPointToSimplex(newTarget.multiply(-1));
			if (isConverging() || (justRemovedP != null && justAdded.equalEps(justRemovedP))) return newTarget;
			justRemovedP = null;
		}
		throw "checkDistance: max GJK loop count reached.";
		return null;
	}
}