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

    public function makeUnion() {
        var graph = new Graph(null,false,true);
        var checkedShapes:Array<Shape> = [];
        var pols:Array<Polygon> = [];
        var segments:haxe.ds.Map<Polygon, Array<Segment>> = new haxe.ds.Map();
        var checkedSegs:Array<Array<Segment>> = [];
        
        if (shapes.length < 2) return null;

        for (shape in shapes) if (shape is Polygon) {
            var pol = cast(shape,Polygon);
            pols.push(pol);
            segments[pol] = pol.toSegments();
        }

        var segmentsIt = segments.iterator();
        for (segs1 in segments.iterator()) {
            for (iSeg1 in 0...segs1.length) {
                var seg1 = segs1[iSeg1];
                var startP = seg1.getA();
                var endP = seg1.getB();

                var seg1Inters:Array<Point> = [];
                var recycNodes:haxe.ds.Map<Int,Node> = [];
                for (segs2 in segments.iterator()) if (segs1 != segs2) {
                    for (seg2 in segs2) {
                        var res = seg1.checkSeg(seg2);
                        
                        if (res != null) {
                            var resP = cast(res[0], Point);
                            if (resP.equals(startP) || resP.equals(endP)) continue;
                            var intersP = resP;
                            seg1Inters.push(resP);
                            if (checkedSegs.contains(segs2)) {
                                var node = graph.getNodeAtPoint(intersP);
                                if (node != null) recycNodes[seg1Inters.length-1] = node;
                            }
                        }
                    }
                }
                
                
                seg1Inters.quickSort((a,b) -> startP.distance(a) < startP.distance(b));

                var startNode = graph.getNodeAtPoint(startP);
                if (startNode == null) { startNode = graph.addNode(startP); trace("new start node: " + startP); }
                else trace("recup startnode: " + startP);

                var prevNode:Graph.Node = startNode;
                trace("inters:"+seg1Inters);
                for (i in 0...seg1Inters.length) {
                    var p = seg1Inters[i];
                    var node:Graph.Node = null;
                    for (n in recycNodes) if (new Point(n.x,n.y).equals(p)) { node = n; break; }
                    if (node == null) node = graph.addNode(p);
                    if (recycNodes[i] != null) trace("recyc: " + new Point(recycNodes[i].x, recycNodes[i].y));
                    graph.connect(prevNode,[node]);
                    trace("connect: "+new Point(prevNode.x,prevNode.y) + "   " + new Point(node.x,node.y));
                    prevNode = node;
                }

                var endNode = graph.getNodeAtPoint(endP);
                if (endNode == null) { endNode = graph.addNode(endP); trace("new end node: " + endP); }
                else trace("recup endnode: " + endP);
                graph.connect(prevNode,[endNode]);
                trace("connect2:" + new Point(prevNode.x,prevNode.y) + "   " + new Point(endNode.x,endNode.y));
            }
            checkedSegs.push(segs1);
        }

        

        // Get graph perimeter then return it

        var allNodes = graph.allNodes;
        var points:Array<Point> = [for (node in graph.allNodes) new Point(node.x,node.y)];
        var fp = points.getFarthestPoint(new Point(1,1));
        var onNode = graph.getNodeAtPoint(fp);
        var startNode = onNode;
        var dir = new Point(1,1);
        var res:Array<Point> = [fp];
        while (onNode != null) {
            var pp = new Point(onNode.x,onNode.y);
            trace("on:" + pp.toString() + "  dir:" + dir);
            var a = [for (n in onNode.connections) new Point(n.x,n.y)];
            trace(a);
            a.clockwiseSort(pp, dir);
            trace(a);
            for (i in 0...a.length) {
                var dir2 = a[0].sub(pp).normalized();
                trace("f"+dir2);
                if (dir.equals(dir2) || pp.equals(a[0])) a.shift();
                else break;
            }
            // var v = onNode == startNode ? 0 : 1;
            res.push(a[0]);
            // if (a.length == 1) break;
            dir = res[res.length-2].sub(a[0]).normalized();

            for (n in onNode.connections) if (n.x == a[0].x && n.y == a[0].y) { onNode = n; break; }
            if (onNode.x == startNode.x && onNode.y == startNode.y) break;
        }

        res.pop();
        // return graph;
        return new Polygon(res);
    }
}