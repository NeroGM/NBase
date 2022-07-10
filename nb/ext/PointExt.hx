package nb.ext;

/**
 * An extension class for `h2d.col.Point`.
 * 
 * @see https://haxe.org/manual/lf-static-extension.html
 * @since 0.1.0
 **/
class PointExt {
    /**
     * Sorts an array of points depending on their position relative to a point, in a clockwise manner.
     *
     * Example :
     * Imagine an analog clock where `p` is at the center and `array` is an array of points
     * where each point is at one of the 12 numbers on the clock (`[p1,p2,...,p12]`).
     * The result with `dir` being the direction from the center to : <br/>
     *  - p12, which is (0,-1), is `[p12,p1,p2,...,p11]`. <br/>
     *  - p3, which is (1,0), is `[p3,p4,...,p12,p1,p2]`. <br/>
     *  - p6, which is (0,1), is `[p6,p7,...,p12,p1,...,p5]`. <br/>
     *  - p9, which is (-1,0), is `[p9,p10,...,p12,p1,...,p8]`. <br/>
     *  
     * @param array An array of `h2d.col.Point` instances to sort.
     * @param p An `h2d.col.Point` instance to sort `array` with.
     * @param dir An `h2d.col.Point` instance that defines a direction. Default direction is (0,-1), up.
     * @return The now sorted array, `array`.
     **/
    public static function clockwiseSort(array:Array<Point>, p:Point, ?dir:Point):Array<Point> {
        if (dir == null) dir = new Point(0,-1);
        nb.ext.ArrayExt.quickSort(array, (v1,v2) -> {
            var dir = dir.normalized(); 
            var p1 = v1.sub(p).normalized(); 
            var p2 = v2.sub(p).normalized();
            var dp1 = dir.dot(p1);
            var dp2 = dir.dot(p2);
            var v1 = dir.cross(p1) >= 0 ? dp1 : (-dp1)-2;
            var v2 = dir.cross(p2) >= 0 ? dp2 : (-dp2)-2;
            return v1 > v2;
        });
        return array;
    }

    /**
     * Given a point relative to an object's position, returns the associated 
     * point relative to another object's position.
     * 
     * @param p An `h2d.col.Point` instance.
     * @param o The `h2d.Object` instance the new point should be relative to.
     * @param parent The `h2d.Object` instance `p`'s position is relative to.
     * If `null`, `p` is assumed to be a global coordinate.
     * @return A new `h2d.col.Point` instance relative to `o`.
     **/
    public static inline function relativeTo(p:Point, o:h2d.Object, ?parent:h2d.Object):Point {
        return parent != null ? o.globalToLocal(parent.localToGlobal(p.clone())) : o.globalToLocal(p.clone());
    }

    /**
     * Checks equality between two points with a tolerance value.
     *
     * @param p1 The first point.
     * @param p2 The second point.
     * @param epsilon The tolerance value.
     * @return `true` if there is an equality, `false` otherwise.
     **/
    public static inline function equalEps(p1:Point, p2:Point, epsilon:Float=0.00000000001):Bool {
        return (FloatExt.equals(p1.x,p2.x) && FloatExt.equals(p1.y,p2.y));
    }

    /**
     * Returns the copy of a point with each of its coordinate rounded to 
     * the closest integer not greater than the coordinate.
     *
     * @param p An `h2d.col.Point` instance to round.
     * @return A rounded copy of `p`.
     **/
    public static inline function floor(p:Point):Point {
        return new Point(Math.floor(p.x),Math.floor(p.y));
    }

    /**
     * Moves a point towards a direction defined by an angle.
     * 
     * @param p An `h2d.col.Point` instance.
     * @param angle An angle in radians.
     * @param distance The distance to move from.
     * @return The now moved point, `p`.
     **/
    public static inline function moveTowards(p:Point, angle:Float, distance:Float):Point {
        p.set(p.x + Math.cos(angle) * distance, p.y + Math.sin(angle) * distance);
        return p;
    }
}