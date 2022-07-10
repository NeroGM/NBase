package nb.phys;

using nb.ext.FloatExt;
using nb.ext.PointExt;
using nb.ext.SegmentExt;
import nb.shape.*;

/**
 * A class to test collisions.
 *
 * @since 0.1.0
 **/
class Collision {
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
}