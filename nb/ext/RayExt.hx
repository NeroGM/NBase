package nb.ext;

import h2d.col.Ray;

/**
 * An extension class for `h2d.col.Ray`.
 * 
 * @see https://haxe.org/manual/lf-static-extension.html
 * @since 0.1.0
 **/
class RayExt {
	/** Returns a point where `ray1` and `ray2` intersects. **/
	public static inline function checkRay(ray1:Ray, ray2:Ray):Null<Point> {
		var p = new Point();
		if (nb.phys.Collision.checkRays(ray1.getPoint(0),ray1.getPoint(1),ray2.getPoint(0),ray2.getPoint(1),p) >= 0)
			return p;
		return null;
	}

	/**
	 * Returns the projection of a point onto a ray.
	 *
	 * @param ray An `h2d.col.Ray` to project onto.
	 * @param p An `h2d.col.Point` to project.
	 * @return A new `h2d.col.Point` instance being the projection of `p` onto `ray`.
	 **/
    public static inline function project(ray:Ray, p:Point):Point {
		var px = p.x - ray.px;
		var py = p.y - ray.py;
		var t = px * ray.lx + py * ray.ly;
		var tl2 = t / (ray.lx * ray.lx + ray.ly * ray.ly);
		return new Point(ray.px + tl2 * ray.lx, ray.py + tl2 * ray.ly);
	}

    /**
	 * Returns a number depending on which side a point is on a ray axis.
	 *
	 * @param ray An `h2d.col.Ray` instance.
	 * @param p An `h2d.col.Point` instance.
	 * @return A positive number if `p` is on the right side of `ray` and negative if it's on the left.
	 **/
    public static inline function side(ray:Ray, p:Point):Float {
		return ray.lx * (p.y - ray.py) - ray.ly * (p.x - ray.px);
	}

	/** Returns the string representation of a ray in the format: `[{[ray.x],[ray.y]};{[ray.xDir],[ray.yDir]}]`. **/
    public static inline function toString(ray:Ray):String return "[{"+ray.px+","+ray.py+"};{"+ray.lx+","+ray.ly+"}]";
}