package nb.shape;

class Rectangle extends Polygon {
    public function new(x:Float, y:Float, w:Float, h:Float) {
        super([new Point(x,y), new Point(x+w,y), new Point(x+w,y+h), new Point(x,y+h)],parent);
        subType = RECTANGLE;
    }
}