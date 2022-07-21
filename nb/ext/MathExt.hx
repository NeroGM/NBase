package nb.ext;

/**
 * An extension class for `Math`.
 * 
 * @see https://haxe.org/manual/lf-static-extension.html
 * @since 0.1.0
 **/
class MathExt {
    /**
     * Returns an angle from 2 points.
     * 
     * For example, the result returned in degrees if `p1` is at (0,0) and : <br/>
     *  - `p2` is at (1,0) is 0. <br/>
     *  - `p2` is at (0,1) is 90. <br/>
     *  - `p2` is at (-1,0) is 180. <br/>
     *  - `p2` is at (0,-1) is 270. <br/>
     * 
     * @param math A `Math` class.
     * @param p1 A first point.
     * @param p2 A second point.
     * @param inDeg `true` to return the value in degrees, `false` to return the value in radians.
     * @return An angle.
     **/
    public inline static function angleFromPoints(math:Class<Math>, p1:Point, p2:Point, inDeg:Bool=false):Float
        return !inDeg ? (Math.atan2(p1.y-p2.y,p1.x-p2.x)+Math.PI) % (Math.PI*2) : ((Math.atan2(p1.y-p2.y,p1.x-p2.x)*180/Math.PI)+180) % 360;

    /**
     * Returns an angle from 3 points.
     * 
     * @param math A `Math` class.
     * @param p0 A first point.
     * @param p1 A second point.
     * @param p2 A third point.
     * @param inDeg `true` to return the value in degrees, `false` to return the value in radians.
     * @return The angle between the ray (`p0`,`p1`) and the ray (`p0`,`p2`).
     **/
    public inline static function angleFrom3Points(math:Class<Math>, p0:Point, p1:Point, p2:Point, inDeg:Bool=false):Float {
        var v1 = angleFromPoints(null,p0,p1,inDeg);
        var v2 = angleFromPoints(null,p0,p2,inDeg);
        return v1 > v2 ? ((inDeg ? 360 : Math.PI*2) -v1)+v2 : v2-v1;
    }

    /**
     * Returns the farthest points in a given direction.
     * 
     * @param math A `Math` class.
     * @param points An array of `h2d.col.Point`.
     * @param direction Defines a direction where (1,0) is right and (0,1) is down.
     * @return An array of `h2d.col.Point`. Only the points that are the farthest are returned,
     * NOT all the points from the farthest to the closest.
     **/
    public static function getFarthestPoints(math:Class<Math>, points:Array<Point>, direction:Point):Array<Point> {
		var highest:Float = Math.NEGATIVE_INFINITY;
		var res:Array<Point> = [];
		for (p in points) {
            var p = p.clone();
			var v = p.dot(direction);
			if (v > highest) {
				highest = v;
				res = [p];
			} if (v == highest) res.push(p);
		}
		return res;
	}
}