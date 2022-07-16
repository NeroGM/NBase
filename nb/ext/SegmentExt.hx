package nb.ext;

using nb.ext.SegmentExt;

/**
 * An extension class for `h2d.col.Segment`.
 * 
 * @see https://haxe.org/manual/lf-static-extension.html
 * @since 0.1.0
 **/
class SegmentExt {
    /** Returns the point A of an `h2d.col.Segment` instance. **/
    public static inline function getA(seg:Segment):Point { return new Point(seg.x,seg.y); }
    /** Returns the point B of an `h2d.col.Segment` instance. **/
    public static inline function getB(seg:Segment):Point { return new Point(seg.x+seg.dx,seg.y+seg.dy); }

    /**
     * Checks if two segments intersects.
     *
     * This function is a shortcut to the `nb.phys.Collision.checkSegments` function.
     * 
     * @param seg1 The first segment.
     * @param seg2 The second segment.
     * @return If there's an intersection, an array with at index 0 the point of the intersection, 
     * and at index 1 the overlapping part of the two segments. Returns `null` if there is no intersection.
     **/
    public static inline function checkSeg(seg1:Segment, seg2:Segment):Null<Array<Dynamic>> {
        var p:Point = new Point();
        var seg:Segment = new Segment(new Point(), new Point(1,0));
        if (nb.phys.Collision.checkSegments(seg1.getA(),seg1.getB(),seg2.getA(),seg2.getB(),p,seg) > 0)
            return [p,seg];
        return null;
    }
}