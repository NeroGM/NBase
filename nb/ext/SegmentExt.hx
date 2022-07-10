package nb.ext;

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
}