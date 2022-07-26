package nb.shape;

/**
 * Represents a rectangle.
 *
 * @since 0.1.0
 **/
class Rectangle extends Polygon {
    /**
     * Creates an `nb.shape.Rectangle` instance.
     *
     * @param x The x position of the rectangle.
     * @param y The y position of the rectangle.
     * @param w The width of the rectangle.
     * @param h The height of the rectangle.
     * @param parent The parent object of this instance.
     **/
    public function new(x:Float, y:Float, w:Float, h:Float, ?parent:h2d.Object) {
        super([new Point(x,y), new Point(x+w,y), new Point(x+w,y+h), new Point(x,y+h)],parent);
        defs.push(RECTANGLE);
    }

    /** Returns a string representation of this instance. **/
    override public function toString():String {
        return "Rectangle: "+Std.string(points);
    }
}