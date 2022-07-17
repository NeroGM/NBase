package nb.shape;

using nb.ext.PointExt;
using nb.ext.SegmentExt;

class Shapes extends Object {
    public var shapes:Array<Shape> = [];
    public var union:Array<Shape> = [];
    public var centroid:Point = null;
    public var types:Array<Shape.ShapeType>;
    public var center:Point = new Point();

    public var debugG(default,null):Graphics;
    public function new(?parent:h2d.Object) {
        super(parent);
        debugG = new Graphics(0,0,this);
    }

    // For now, should be used only for set of polygons
    public function addShape(shape:Shape) {
        shapes.push(shape);
        addChild(shape);
        makeUnion();
        updateFields();
    }

    public function addShapes(shapes:Array<Shape>) {
        for (shape in shapes) { this.shapes.push(shape); addChild(shape); }
        makeUnion();
        updateFields();
    }

    public function updateFields() {
        if (union.length == 0) return;

        centroid = null;
        var rightP:Point = null;
        var leftP:Point = null;
        var topP:Point = null;
        var botP:Point = null;
        for (shape in union) {
            var rP = shape.getSupportPoint(new Point(1,0));
            var lP = shape.getSupportPoint(new Point(-1,0));
            var tP = shape.getSupportPoint(new Point(0,-1));
            var bP = shape.getSupportPoint(new Point(0,1));
            if (rightP == null || rightP.x < rP.x) rightP = rP;
            if (leftP == null || leftP.x > lP.x) leftP = lP;
            if (topP == null || topP.y > tP.y) topP = tP;
            if (botP == null || botP.y < bP.y) botP = bP;

            if (centroid == null) centroid = shape.centroid.clone();
            else centroid = centroid.add(shape.centroid).multiply(0.5);
        }
        
        setSize(Math.abs(rightP.x-leftP.x),Math.abs(topP.y-botP.y));
        center.set(leftP.x+size.w/2,topP.y+size.h/2);
    //    setOffset(-centroid.x,-centroid.y); How to deal with it
    //    centroidToOrigin();
    //    trace(size);

        types = shapes.length == 1 ? shapes[0].types.copy() : [COMPLEX];
    }

    public function containsPoint(p:Point):Bool {
        for (shape in shapes) if (shape.containsPoint(p)) return true;
        return false;
    }

    // Moves all shapes so that centroid is 0,0
    public function centroidToOrigin() {
        for (s in shapes) {
            if (s is Polygon) {
                var pol = cast(s,Polygon);
                for (i in 0...pol.points.length) {
                    pol.points[i].sub(centroid);
                }
            } else if (s is Circle) {
                var circ = cast(s,Circle);
                circ.x -= centroid.x;
                circ.y -= centroid.y;
            } else throw "Unknown shape '" + s.toString() + "'"; 
        }
        centroid.set(0,0);
    }

    public function clear() {
        for (s in shapes) s.remove();
        for (s in union) s.remove();
        shapes = []; union = [];
    }

    public function getFarthestPoints(fromCentroid:Bool=true):Array<Point> {
        var highestDist:Float = 0;
        var res:Array<Point> = [];
        var fromP:Point = fromCentroid ? centroid : center;
        for (s in union) {
            if (s is Polygon) {
                for (p in cast(s,Polygon).points) {
                    var dist = p.distance(fromP);
                    if (dist == highestDist) res.push(p.sub(fromP));
                    else if (dist > highestDist) { highestDist = dist; res = [p.sub(fromP)]; }
                } 
            } else if (s is Circle) {
                var p = cast(s,Circle).getSupportPoint(new Point(1,0));
                var dist = p.distance(fromP);
                if (dist == highestDist) res.push(p.sub(fromP));
                else if (dist > highestDist) { highestDist = dist; res = [p.sub(fromP)]; }
            }
        }
        return res;
    }

    public function makeUnion():Graph {
        var graph = new Graph();
        var checkedShapes:Array<Shape> = [];
        var savedSegments:haxe.ds.Map<Int,Array<Segment>> = new haxe.ds.Map();

        if (shapes.length < 2) return null;

        for (shape1 in shapes) {
            if (shape1 is Polygon) {
                var pol1 = cast(shape1,Polygon);
                if (savedSegments[shape1.objId] == null) savedSegments[shape1.objId] = pol1.toSegments();
                var segments1:Array<Segment> = savedSegments[shape1.objId];
                for (i in 0...segments1.length) {
                    var seg1 = segments1[i];
                    var p1 = seg1.getA();
                    var p2 = seg1.getB();
                    var nodeP1 = i == 0 ? graph.addNode(p1) : graph.getNodeAtPoint(p1);
                    var nodeP2 = i == segments1.length-1 ? graph.getNodeAtPoint(p2) : graph.addNode(p2);
                    if (checkedShapes.length == 0) graph.connect(nodeP1,[nodeP2]);
                    else for (shape2 in checkedShapes) {
                        if (shape2 is Polygon) {
                            var pol2 = cast(shape2,Polygon);
                            if (savedSegments[shape2.objId] == null) savedSegments[shape2.objId] = pol2.toSegments();
                            var segments2:Array<Segment> = savedSegments[shape2.objId];

                            for (seg2 in segments2) {
                                var cInfo = seg1.checkSeg(seg2);
                                if (cInfo != null) {
                                    var p3 = seg2.getA();
                                    var p4 = seg2.getB();
                                    var nodeP3 = graph.getNodeAtPoint(p3);
                                    var nodeP4 = graph.getNodeAtPoint(p4);
                                    var nodeInters = graph.addNode(cInfo[0]);
                                    graph.disconnect(nodeP3,[nodeP4]);
                                    graph.connect(nodeInters,[nodeP1,nodeP2,nodeP3,nodeP4]);
                                } else {
                                    graph.connect(nodeP1,[nodeP2]);
                                }
                            }
                        }
                    }
                }
                checkedShapes.push(shape1);
            }
        }
        return graph;
    }
}