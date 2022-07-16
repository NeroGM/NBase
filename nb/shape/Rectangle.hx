package nb.shape;

class Rectangle extends Polygon {
    public function new(x:Float, y:Float, w:Float, h:Float, ?parent:h2d.Object) {
        super([new Point(x,y), new Point(x+w,y), new Point(x+w,y+h), new Point(x,y+h)],parent);
        types.push(RECTANGLE);
    }
}