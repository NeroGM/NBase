package nb.shape;

using nb.ext.PointExt;
using nb.ext.SegmentExt;
using nb.ext.MathExt;
using nb.ext.ArrayExt;
import nb.Graph;

class Shapes extends Object {
    public var shapes:Array<Shape> = [];
    public var union:Array<Shape> = [];
    public var centroid:Point = null;
    public var defs:Array<Shape.ShapeDef>;
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

        defs = shapes.length == 1 ? shapes[0].defs.copy() : [COMPLEX];
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

    public function makeUnion():Array<Polygon> {
        var graph:Graph = new Graph(null,false,true);
        var segments:haxe.ds.Map<Polygon, Array<Segment>> = new haxe.ds.Map();
        var checkedSegs:Array<Array<Segment>> = [];
        
        if (shapes.length < 2) return null;

        // Make graph
        for (shape in shapes) if (shape is Polygon) {
            var pol = cast(shape,Polygon);
            segments[pol] = pol.toSegments();
        }
        for (segs1 in segments.iterator()) {
            for (seg1 in segs1) {
                var startP = seg1.getA();
                var endP = seg1.getB();

                var seg1Inters:Array<Point> = [];
                var recycNodes:haxe.ds.Map<Int,Node> = [];
                for (segs2 in segments.iterator()) if (segs1 != segs2) {
                    for (seg2 in segs2) {
                        var res = seg1.checkSeg(seg2);
                        if (res != null) {
                            var intersP = cast(res[0], Point);
                            if (intersP.equals(startP) || intersP.equals(endP)) continue;
                            seg1Inters.push(intersP);
                            if (checkedSegs.contains(segs2)) {
                                var node = graph.getNodeAtPoint(intersP);
                                if (node != null) recycNodes[seg1Inters.length-1] = node;
                            }
                        }
                    }
                }
                seg1Inters.quickSort((a,b) -> startP.distance(a) < startP.distance(b));

                var startNode = graph.getNodeAtPoint(startP);
                if (startNode == null) startNode = graph.addNode(startP);

                var prevNode:Graph.Node = startNode;
                for (i in 0...seg1Inters.length) {
                    var p = seg1Inters[i];
                    var node:Graph.Node = null;
                    for (n in recycNodes) if (new Point(n.x,n.y).equals(p)) { node = n; break; }
                    if (node == null) node = graph.addNode(p);
                    graph.connect(prevNode,[node]);
                    prevNode = node;
                }

                var endNode = graph.getNodeAtPoint(endP);
                if (endNode == null) endNode = graph.addNode(endP);
                graph.connect(prevNode,[endNode]);
            }
            checkedSegs.push(segs1);
        }

        // Get graph perimeter then return it
        var networks:Array<Array<Node>> = [];
        for (i in 1...graph.networks.length) {
            var net = graph.networks[i];
            if (net[0] != null) networks.push(net);
        } 

        var points:Array<Point> = [for (node in networks[0]) new Point(node.x,node.y)];
        var fp = points.getFarthestPoint(new Point(1,1));
        var onNode = graph.getNodeAtPoint(fp);
        var startNode = onNode;
        var dir = new Point(1,1);
        var res:Array<Array<Point>> = [[fp]];
        var c:Int = 0;
        while (onNode != null) {
            var pp = new Point(onNode.x,onNode.y);
            var a = [for (n in onNode.connections) new Point(n.x,n.y)];
            a.clockwiseSort(pp, dir);
            for (i in 0...a.length) {
                var dir2 = a[0].sub(pp).normalized();
                if (dir.equals(dir2) || pp.equals(a[0])) a.shift();
                else break;
            }
            res[c].push(a[0]);
            dir = res[c][res[c].length-2].sub(a[0]).normalized();

            for (n in onNode.connections) if (n.x == a[0].x && n.y == a[0].y) { onNode = n; break; }
            if (onNode.x == startNode.x && onNode.y == startNode.y) {
                res[c].pop();
                if (networks.length-1 == c) break;

                c++;
                var points = [for (node in networks[c]) new Point(node.x,node.y)];
                var fp = points.getFarthestPoint(new Point(1,1));
                onNode = graph.getNodeAtPoint(fp);
                startNode = onNode;
                dir = new Point(1,1);
                res[c] = [fp];
            }
        }
        
        return [for (a in res) new Polygon(a)];
    }
}