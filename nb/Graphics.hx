package nb;

using nb.ext.MathExt;
using nb.ext.ArrayExt;
using nb.ext.FloatExt;
using nb.ext.RayExt;
using nb.ext.PointExt;
using nb.Graphics;

/**
 * Contains data about a border drawing.
 *
 * @since 0.1.0
 **/
@:allow(nb.Graphics)
class BorderData {
    /** All the parts of the drawing. **/
    public var parts(default,null):Array<Array<Vertex>>;
    /** All the parts of the drawing minus the parts used to draw corners. **/
    public var borderParts(default,null):Array<Array<Vertex>>;
    /** Indexes of the parts that are used to draw corners.  **/
    public var cornerI(default,null):Array<Int>;
    /** The thickness of the border drawn. **/
    public var thickness(default,null):Float;
    /** The roundAngle value used for the drawing. **/
    public var roundAngle(default,null):Float;
    /** A reference to the polygon used for the drawing. **/
    public var col:h2d.col.Polygon;

    // Internal usage
    /** The previous point used as p1 in the loop. **/
    private var fromP:Point;
    /** The current point used as p1 in the loop. Also `fromP`'s next value. **/
    private var onP:Point;
    /** The current point used as p2 in the loop. Also the next point used as p1. **/
    private var toP:Point;
    /** The loop `i` value. **/
    private var i:Int;

    /** Creates an `nb.Graphics.BorderData` instance. **/
    private function new() {}
}

/**
 * Contains vertex data.
 *
 * @since 0.1.0
 **/
class Vertex {
    /** The x coordinate. **/
	public var x(default, set):Float;
    /** The y coordinate. **/
	public var y(default, set):Float;
    /** The red tint value. **/
	public var r:Float;
    /** The green tint value. **/
	public var g:Float;
    /** The blue tint value. **/
	public var b:Float;
    /** The alpha value. **/
	public var a:Float;
    /** The normalized horizontal texture position. **/
    public var u:Float;
    /** The normalized vertical texture position. **/
    public var v:Float;
    /** A point that sets itself to (`x`,`y`), the vertex's coordinates. **/
    public var p:Point = new Point();

    /** Creates an `nb.Graphics.Vertex` instance. **/
	public function new(x:Float=0, y:Float=0, r:Float=1, g:Float=1, b:Float=1, a:Float=1, u:Float=0, v:Float=0) {
        this.x = x; this.y = y;
		this.r = r; this.g = g; this.b = b; this.a = a;
        this.u = u; this.v = v;
    }

    /** Adds given values to this instance's current values. **/
    public function add(x:Float=0, y:Float=0, r:Float=0, g:Float=0, b:Float=0, a:Float=0, u:Float=0, v:Float=0):Vertex {
		this.x += x; this.y += y;
		this.r += r; this.g += g; this.b += b; this.a += a;
        this.u += u; this.v += v;
        return this;
	}

    /** Sets the vertex's coordinates. **/
    public function setPosition(x:Float, y:Float) {
        this.x = x;
        this.y = y;
    }

    /** Returns a new `nb.Graphics.Vertex`'s instance with the same properties. **/
    public function clone():Vertex {
        return new Vertex(x,y,r,g,b,a,u,v);
    }

    /** Sets this instance's values. **/
	public function load(x:Float, y:Float, r:Float, g:Float, b:Float, a:Float, u:Float, v:Float) {
		this.x = x; this.y = y;
        this.r = r; this.g = g; this.b = b; this.a = a;
        this.u = u; this.v = v;
	}

    private function set_x(v:Float) {
        p.x = v;
        return x = v;
    }

    private function set_y(v:Float) {
        p.y = v;
        return y = v;
    }
}

/** Contains drawing parameters. **/
typedef DrawingParams = {
    /** The line width. **/
    var lineWidth:Float;
    /** The line color. **/
    var lineColor:Int;
    /** The line's alpha value. **/
    var lineAlpha:Float;
    /** The line's drawing method. **/
    var lineDrawMethod:LineDrawMethod;
    /** The fill operation's alpha value. **/
    var fillAlpha:Float;
    /** The drawing's alpha value. **/
    var alpha:Float;
    /** Whether the drawing should be filled. **/
    var filled:Bool;
    /** The fill operation's color. **/
    var fillColor:Int;
    /** The type of the border. **/
    var borderType:BorderType;
}

@:dox(hide)
enum abstract LineDrawMethod(Int) {
    var DEFAULT = 0;
    var EDGE = 1;
    var BRESENHAM = 2;
}

@:dox(hide)
enum BorderType {
    INNER;
    OUTER;
    INNEROUTER;
}

/**
 * A drawing interface built on top of `h2d.Graphics`.
 *
 * The `h2d.Graphics` class used and its functions are still accessible via the `g` parameter.
 *
 * @since 0.1.0
 **/
class Graphics extends Object {
    /** The `h2d.Graphics` used for drawing. **/
    public var g(default, null):h2d.Graphics;
    /** This instance's default drawing parameters. **/
    public var params:DrawingParams;

    /** Creates an `nb.Graphics` instance. **/
    public function new(x:Float=0, y:Float=0, ?parent:h2d.Object) {
        name = "Graphics";
        super(x,y,parent);
        params = getDefaultParams();
        g = new h2d.Graphics(this);
        removeChildrenOnRemove = false;
    }

    /** Draws an `h2d.Tile`. **/
    public function drawTile(x:Float, y:Float, tile:h2d.Tile) {
        g.drawTile(x,y,tile);
    }

    /**
     * Draws a line.
     *
     * `params.lineDrawMethod` influences the kind of line that will be drawn.
     * 
     * @param x1 Starting x coordinate.
     * @param y1 Starting y coordinate.
     * @param x2 Ending x coordinate.
     * @param y2 Ending y coordinate.
     * @param params The drawing parameters. If `null`, this instance's `params` is used.
     **/
    public function drawLine(x1:Float, y1:Float, x2:Float, y2:Float, ?params:DrawingParams):h2d.Graphics {
        if (params == null) params = this.params;
        
        switch (params.lineDrawMethod) {
            case DEFAULT:
                applyLineStyle(params);
                g.moveTo(x1,y1);
                g.lineTo(x2,y2);
                g.lineStyle();
            case EDGE:
                var angle = Math.angleFromPoints(new Point(x1,y1),new Point(x2,y2)) + Math.PI/2;
                var cos = params.lineWidth*Math.cos(angle); var sin = params.lineWidth*Math.sin(angle);
                applyFillStyle(params);
                g.addV(new Vertex(x1,y1,1,1,1,1,0,0));
                g.addV(new Vertex(x2,y2,1,1,1,1,1,0));
                g.addV(new Vertex(x2+cos,y2+sin,1,1,1,1,1,1));
                g.addV(new Vertex(x1+cos,y1+sin,1,1,1,1,0,1));
                g.endFill();
            case BRESENHAM:
                applyFillStyle(params);
                var pw = params.lineWidth;
                var a = Bresenham.plotLine(x1/pw,y1/pw,x2/pw,y2/pw);
                var diff = a[a.length-1].sub(a[0]);
                if (diff.x == 0) g.drawRect(a[0].x*pw,a[0].y*pw,pw,a[a.length-1].y*pw);
                else if (diff.y == 0) g.drawRect(a[0].x*pw,a[0].y*pw,a[a.length-1].x*pw,pw);
                else for (p in a) g.drawRect(p.x*pw,p.y*pw,pw,pw);
                g.endFill();
        }
        
        updateSize();
        return g;
    }

    /** Draws multiple lines from an array of points. **/
    public function drawLines(points:Array<Point>, ?params:DrawingParams):h2d.Graphics {
        if (points.length < 2) return g;
        if (params == null) params = this.params;

        applyLineStyle(params);
        g.moveTo(points[0].x, points[0].y);
        for (i in 1...points.length) g.lineTo(points[i].x, points[i].y);
        g.lineStyle(); 

        updateSize();
        return g;
    }

    /** Draws a circle. **/
    public function drawCircle(cx:Float, cy:Float, radius:Float, nSegments:Int=0, ?params:DrawingParams):h2d.Graphics {
        if (params == null) params = this.params;
        
        if (params.filled) applyFillStyle(params);
        applyLineStyle(params);

        if( nSegments == 0 )
			nSegments = Math.ceil(Math.abs(radius * 3.14 * 2 / 4));
		if( nSegments < 3 ) nSegments = 3;
		var angle = Math.PI * 2 / nSegments;
		for( i in 0...nSegments + 1 ) {
			var a = i * angle;
            var x = cx + Math.cos(a) * radius;
            var y = cy + Math.sin(a) * radius;
			g.lineTo(x.equals(0) ? 0 : x, y.equals(0) ? 0 : y); // cuz drawn wrong when (cx,cy) close to (0,0) with h2d.Graphics' method. // ! still happens but not at (0,0)
		}

        g.lineStyle();
        if (params.filled) g.endFill();

        updateSize();
        return g;
    }

    /** Draws a rectangle. **/
    public function drawRect(x:Float, y:Float, w:Float, h:Float, ?params:DrawingParams):h2d.Graphics {
        if (params == null) params = this.params;

        if (params.filled) {
            applyFillStyle(params);
            g.drawRect(x,y,w,h);
            g.endFill();
        }
        if (params.lineWidth > 0) {
            var col:Array<Point> = [new Point(x,y),new Point(x+w,y),new Point(x+w,y+h),new Point(x,y+h)];
            drawBorder(col,nb.ResManager.getWhiteTile(),params.lineWidth,params.lineColor,params.lineAlpha*params.alpha,params.borderType);
        }
        
        updateSize();
        return g;
    }

    /** Draws a polygon. **/
    public function drawPolygon(points:h2d.col.Polygon, ?params:DrawingParams) {
        if (points.length == 0) return;
        if (params == null) params = this.params;
        
        applyLineStyle(params);
        if (params.filled) applyFillStyle(params);
        
        g.moveTo(points[0].x,points[0].y);
        for (i in 1...points.length) g.lineTo(points[i].x,points[i].y);
        g.lineTo(points[0].x,points[0].y);

        g.lineStyle();
        if (params.filled) g.endFill();

        updateSize(); 
    }

    /** Returns a new `nb.Graphics.DrawingParams` instance with its default values. **/
    public static function getDefaultParams():DrawingParams
        return {lineWidth:1,lineColor:0xffffff,fillColor:0x00ff00,lineAlpha:1,lineDrawMethod:DEFAULT,borderType:INNER,fillAlpha:1,alpha:1,filled:false};

    /** Replace this instance's `params` by a new one with its default values. **/
    public function resetParams() this.params = getDefaultParams();

    /** Updates this instance's size. **/
    private function updateSize() {
        var bounds = getBounds(this);
        setSize(bounds.width,bounds.height);
    }

    /** Clears the drawn content. **/
    public function clear() g.clear();

    /**
     * Draws a border using a given polygon.
     * 
     * @param col An array of `h2d.col.Point`s.
     * @param tile An `h2d.Tile` to draw the border with.
     * @param thickness The thickness of the border.
     * @param tint The tint of the border in the format: `0xRRGGBB`.
     * @param alpha The border's alpha value.
     * @param borderType The type of border to draw.
     * @param roundAngle An angle in radians for deciding when the corners should be rounded, a threshold.
     * A negative number means it's always rounded, `0` means it's rounded only on right angles.
     * @return The `nb.Graphics.BorderData` associated to the border drawn.
     **/
    public function drawBorder(col:h2d.col.Polygon, tile:h2d.Tile, ?thickness:Float, ?tint:Int=0xFFFFFF, ?alpha:Float=1, ?borderType:BorderType=OUTER, ?roundAngle:Float=0.025):BorderData {
        if (thickness == null) thickness = tile.height;
        
        var parts:Array<Array<Vertex>> = [];
        var bd:BorderData = new BorderData();
        bd.parts = parts;
        bd.borderParts = [];
        bd.thickness = thickness;
        bd.cornerI = [];
        bd.roundAngle = roundAngle;
        bd.col = col;
        for (i in 0...col.points.length+1) {
            bd.i = i;
            var p1 = bd.onP = col.points.at(i);
            var p2 = bd.toP = col.points.at(i+1);
            var angle1 = Math.angleFromPoints(p1,p2);
            var angle2 = (angle1+Math.PI/2) % (Math.PI*2);
            var part:Array<Vertex> = [];
            bd.fromP = col.points[i-1];

            switch (borderType) {
                case INNER:
                    var cos2 = Math.cos(angle2); var sin2 = Math.sin(angle2);
                    part[0] = new Vertex(p1.x, p1.y);
                    part[1] = new Vertex(p2.x, p2.y);
                    part[2] = new Vertex(p2.x + cos2 * thickness, p2.y + sin2 * thickness);
                    part[3] = new Vertex(p1.x + cos2 * thickness, p1.y + sin2 * thickness);
                case OUTER:
                    var cos2 = Math.cos(angle2); var sin2 = Math.sin(angle2);
                    part[0] = new Vertex(p1.x - cos2 * thickness, p1.y - sin2 * thickness);
                    part[1] = new Vertex(p2.x - cos2 * thickness, p2.y - sin2 * thickness);
                    part[2] = new Vertex(p2.x, p2.y);
                    part[3] = new Vertex(p1.x, p1.y);
                case INNEROUTER:
                    var v = thickness * 0.5;
                    var cos1 = Math.cos(angle1); var sin1 = Math.sin(angle1);
                    var cos2 = Math.cos(angle2); var sin2 = Math.sin(angle2);
                    part[0] = new Vertex(p1.x + (- cos1 - cos2) * v, p1.y + (- sin1 - sin2) * v);
                    part[1] = new Vertex(p2.x + (cos1 - cos2) * v, p2.y + (sin1 - sin2) * v);
                    part[2] = new Vertex(p2.x + (cos1 + cos2) * v, p2.y + (sin1 + sin2) * v);
                    part[3] = new Vertex(p1.x + (- cos1 + cos2) * v, p1.y + (- sin1 + sin2) * v);
            }

            if (tint != 0xFFFFFF) for (v in part) {
                v.r = (tint >> 16) / 255;
                v.g = ((tint >> 8) & 0x00FF) / 255;
                v.b = (tint & 0x0000FF) / 255;
                if (alpha != 1) v.a = alpha;
            } else if (alpha != 1) for (v in part) v.a = alpha;
            

            if (i == 0) { parts.push(part); bd.borderParts.push(part); continue; }
            defDraw1(part,parts[parts.length-1],bd);
        }

        for (i in 0...parts.length) {
            if (bd.cornerI.contains(i) && parts[i].length >= 4) vPerimeterFill(parts[i],tile);
            else vFill(parts[i],tile,parts[i][0].p,parts[i][1].p);
        }

        return bd;
    }

    /** The first border drawing method. **/
    private function defDraw1(part:Array<Vertex>, prevPart:Array<Vertex>, bd:BorderData) {
        var angle = Math.angleFrom3Points(bd.onP, bd.fromP, bd.toP);
        var reflexAngle = angle > Math.PI;
        var h:Float = bd.thickness;
        var ra = bd.roundAngle;
        var v1:Float, v2:Float; v1 = v2 = 0;
        var v3:Float, v4:Float; v3 = v4 = Math.PI/2;
        var v5:Float, v6:Float; v5 = v6 = Math.PI;
        var v7:Float, v8:Float; v7 = v8 = Math.PI+Math.PI/2;
        v1 -= ra; v2 += ra; if (v1 < 0) Math.PI*2;
        v3 -= ra; v4 += ra;
        v5 -= ra; v6 += ra;
        v7 -= ra; v8 += ra;
        var check = ((angle >= v1 && angle <= v2) || (angle >= v3 && angle <= v4) || (angle >= v5 && angle <= v6) || (angle >= v7 && angle <= v8));
        if (!check) {
            var cornerA:Array<Vertex> = [];
            bd.cornerI.push(bd.parts.length);

            var sAngle:Float = 0;
            var eAngle:Float = 0;
            // Make space for rounded corner
            if (reflexAngle) {
                var ray1 = h2d.col.Ray.fromPoints(prevPart[3].p,prevPart[2].p);
                var ray2 = h2d.col.Ray.fromPoints(part[2].p,part[3].p);
                var inters = ray1.checkRay(ray2);
                sAngle = Math.angleFromPoints(prevPart[2].p,prevPart[1].p);
                var tempP = new Point(inters.x, inters.y).moveTowards(sAngle,bd.thickness);
                prevPart[1].setPosition(tempP.x,tempP.y);
                prevPart[2].setPosition(inters.x,inters.y);
                eAngle = Math.angleFromPoints(part[3].p,part[0].p);
                tempP = new Point(inters.x, inters.y).moveTowards(eAngle,bd.thickness);
                part[0].setPosition(tempP.x,tempP.y);
                part[3].setPosition(inters.x,inters.y);
            } else {
                var ray1 = h2d.col.Ray.fromPoints(prevPart[0].p,prevPart[1].p);
                var ray2 = h2d.col.Ray.fromPoints(part[1].p,part[0].p);
                var inters = ray1.checkRay(ray2);
                sAngle = Math.angleFromPoints(prevPart[1].p,prevPart[2].p);
                var tempP = new Point(inters.x, inters.y).moveTowards(sAngle,bd.thickness);
                prevPart[2].setPosition(tempP.x,tempP.y);
                prevPart[1].setPosition(inters.x,inters.y);
                eAngle = Math.angleFromPoints(part[0].p,part[3].p);
                tempP = new Point(inters.x, inters.y).moveTowards(eAngle,bd.thickness);
                part[3].setPosition(tempP.x,tempP.y);
                part[0].setPosition(inters.x,inters.y);
            }
            
            // Make rounded corner
            var inc = Math.PI / 24;
            var stepAngle = sAngle;
            if (reflexAngle && eAngle < sAngle) eAngle += Math.PI*2;
            else if (!reflexAngle && eAngle > sAngle) eAngle -= Math.PI*2;
            var last:Bool = false;
            var a:Array<Vertex> = [];
            for (i in 0...1000) {
                var cos = Math.cos(stepAngle);
                var sin = Math.sin(stepAngle);
                var p = reflexAngle ? prevPart[2] : prevPart[1];
                cornerA.push(p.clone().add(h*cos,h*sin));
                a.unshift(p.clone());
                stepAngle += reflexAngle ? inc : -inc;
                if (last) break;
                if (reflexAngle && stepAngle >= eAngle || !reflexAngle && stepAngle <= eAngle) {
                    stepAngle = eAngle;
                    last = true;
                }
                if (i == 999) throw "def draw 1 loop error";
            }

            var vv = cornerA[cornerA.length-1];
            for (v in a) cornerA.push(v);
            bd.parts.push(cornerA);
            if (bd.col.length == bd.i) {
                if (reflexAngle) {
                    bd.borderParts[0][0].setPosition(vv.x,vv.y);
                    bd.borderParts[0][3].setPosition(cornerA[cornerA.length-1].x,cornerA[cornerA.length-1].y);
                } else {
                    bd.borderParts[0][0].setPosition(cornerA[cornerA.length-1].x,cornerA[cornerA.length-1].y);
                    bd.borderParts[0][3].setPosition(vv.x,vv.y);
                }
                return;
            }
        } else {
            var i1:Int = 3;
            var i2:Int = 2;
            var partA = bd.i == bd.col.length ? bd.borderParts[bd.borderParts.length-1] : prevPart;
            var partB = bd.i == bd.col.length ? bd.borderParts[0] : part;
            var ray1 = h2d.col.Ray.fromPoints(partA[i1].p,partA[i2].p);
            var ray2 = h2d.col.Ray.fromPoints(partB[i2].p,partB[i1].p);
            var inters:Point = ray1.checkRay(ray2);
            if (inters != null) {
                partA[i2].x = partB[i1].x = inters.x;
                partA[i2].y = partB[i1].y = inters.y;
            }

            i1 = 0; i2 = 1;
            var ray1 = h2d.col.Ray.fromPoints(partA[i1].p,partA[i2].p);
            var ray2 = h2d.col.Ray.fromPoints(partB[i2].p,partB[i1].p);
            var inters:Point = ray1.checkRay(ray2);
            if (inters != null) {
                partA[i2].x = partB[i1].x = inters.x;
                partA[i2].y = partB[i1].y = inters.y;
            }
            if (bd.i == bd.col.length) return;
        }

        bd.parts.push(part);
        bd.borderParts.push(part);
    }

    /** 
     * Sets the uv parameters of an array of vertexes for a fill operation.
     *
     * @param aVertexes An array of `nb.Graphics.Vertex`.
     * @param tile A tile for defining the fill texture.
     * @param draw Whether this instance's should draw the result.
     * @param xRepeat Whether the fill texture should repeat on the horizontal axis.
     * @param yRepeat Whether the fill texture should repeat on the vertical axis.
     * @param xRepeatOnce Whether the fill texture should repeat on the horizontal axis only once.
     * @param yRepeatOnce Whether the fill texture should repeat on the vertical axis only once.
     **/
    public function vPerimeterFill(aVertexes:Array<Vertex>, tile:h2d.Tile, draw:Bool=true, xRepeat:Bool=true, yRepeat:Bool=true, xRepeatOnce:Bool=false, yRepeatOnce:Bool=false) {
        if (aVertexes.length < 4 || aVertexes.length % 2 != 0) throw "Vertexes count must be pair and greater than 3.";

        if (tile.x != 0 || tile.y != 0)
            tile = h2d.Tile.fromTexture(ResManager.getTexturePart(tile.getTexture(),tile.x,tile.y,tile.width,tile.height));

        if (draw) {
            g.beginTileFill(null,null,null,null,tile);
            g.tileWrap = true;
        }

        var pixWidth = 1/tile.getTexture().width;
        var pixHeight = 1/tile.getTexture().height;
        var iLast:Int = aVertexes.length-1;
        var iLast2:Int = aVertexes.length-2;
        var e = 0.01;
        var w:Float = (xRepeat ? aVertexes[0].p.distance(aVertexes[1].p) : tile.width) * pixWidth - e;
        var h:Float = (yRepeat ? aVertexes[1].p.distance(aVertexes[iLast2].p) : tile.height) * pixHeight - e;
        for (i in 0...Std.int(iLast/2)) {
            if (i == 0) {
                aVertexes[i].u = aVertexes[i].v = 0;
                aVertexes[i+1].u = w;
                aVertexes[i+1].v = 0;
                aVertexes[iLast2-i].u = w;
                aVertexes[iLast2-i].v = h;
                aVertexes[iLast-i].u = 0;
                aVertexes[iLast-i].v = (yRepeat ? aVertexes[0].p.distance(aVertexes[aVertexes.length-1].p) : tile.height) * pixHeight - e;
            } else {
                if (!xRepeatOnce && xRepeat) w = aVertexes[i].p.distance(aVertexes[i+1].p) * pixWidth - e;
                if (!yRepeatOnce && yRepeat) h = aVertexes[i+1].p.distance(aVertexes[iLast2-i].p) * pixHeight - e;
                aVertexes[i+1].u = aVertexes[i].u + w;
                aVertexes[i+1].v = aVertexes[i].v;
                aVertexes[iLast2-i].u = aVertexes[iLast-i].u + w;
                aVertexes[iLast2-i].v = h; 
            }
            if (draw) {
                g.addV(aVertexes[i]);
                g.addV(aVertexes[i+1]);
                g.addV(aVertexes[iLast2-i]);
                g.addV(aVertexes[iLast-i]);
                @:privateAccess g.flush();
            }
        }
    }

    /** 
     * Sets the uv parameters of an array of vertexes for a fill operation.
     *
     * @param aVertexes An array of `nb.Graphics.Vertex`.
     * @param tile A tile for defining the fill texture.
     * @param pos A position where the filling will start.
     * @param dir A point defining the filling direction.
     * @param draw Whether this instance's should draw the result.
     **/
    public function vFill(aVertexes:Array<Vertex>, tile:h2d.Tile, ?pos:Point, ?dir:Point, draw:Bool=true) {
        if (pos == null) pos = new Point();
        if (dir == null || dir.equals(pos)) dir = pos.add(new Point(1,0));

        if (tile.x != 0 || tile.y != 0)
            tile = h2d.Tile.fromTexture(ResManager.getTexturePart(tile.getTexture(),tile.x,tile.y,tile.width,tile.height));

        if (draw) {
            g.beginTileFill(null,null,null,null,tile);
            g.tileWrap = true;
        }

        var pixWidth = 1/tile.getTexture().width;
        var pixHeight = 1/tile.getTexture().height;
        var oRay = h2d.col.Ray.fromPoints(pos,dir);
        for (v in aVertexes) {
            var projP:Point = oRay.project(v.p);
            var angle = Math.angleFrom3Points(pos,oRay.getPoint(1),v.p,true);
            var xDist = (angle <= 90 || angle >= 270) ? pos.distance(projP) : -pos.distance(projP);
            var yDist = (angle <= 180 ) ? projP.distance(v.p) : -projP.distance(v.p);
            v.u = xDist*pixWidth;
            v.v = yDist*pixHeight;
            if (draw) g.addVertex(v.x,v.y,v.r,v.g,v.b,v.a,v.u,v.v);
        }
        if (draw) @:privateAccess g.flush();
    }

    /** Applies `params`' filling parameters. **/
    private inline function applyFillStyle(params:DrawingParams) {
        g.beginFill(params.fillColor,params.fillAlpha*params.alpha);
    }

    /** Applies `params`' line parameters. **/
    private inline function applyLineStyle(params:DrawingParams) {
        g.lineStyle(params.lineWidth,params.lineColor,params.lineAlpha*params.alpha);
    }

    /** Adds a vertex to the drawn content. **/
    private static inline function addV(g:h2d.Graphics, v:Vertex) {
        g.addVertex(v.x,v.y,v.r,v.g,v.b,v.a,v.u,v.v);
    }
}