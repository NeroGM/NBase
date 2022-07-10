package nb;

/**
 * A tiny Bresenham class.
 *
 * @since 0.1.0
 **/
class Bresenham {
    /** Bresenham algorithm, order not guaranteed. **/
    public static function plotLine(x1:Float, y1:Float, x2:Float, y2:Float):Array<Point> {
        var x1:Int = Math.floor(x1);
        var y1:Int = Math.floor(y1);
        var x2:Int = Math.floor(x2);
        var y2:Int = Math.floor(y2);
        
        var dx = Math.abs(x2-x1);
        var sx = x1 < x2 ? 1 : -1;
        var dy = -Math.abs(y2-y1);
        var sy = y1 < y2 ? 1 : -1;
        var error = dx+dy;

        var res:Array<Point> = [];
        while (true) {
            res.push(new Point(x1,y1));
            if (x1 == x2 && y1 == y2) break;
            var e2 = 2*error;
            if (e2 >= dy) {
                if (x1 == x2) break;
                error += dy;
                x1 += sx;
            }
            if (e2 <= dx) {
                if (y1 == y2) break;
                error += dx;
                y1 += sy;
            }
        }

        return res;
    }
}