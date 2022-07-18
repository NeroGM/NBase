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
        var savedNodes:haxe.ds.Map<Polygon,Array<nb.Graph.Node>> = [];
        var savedSegments:haxe.ds.Map<Int,Array<Segment>> = new haxe.ds.Map();

        if (shapes.length < 2) return null;

        // Make graph
        var p1:Point = null;
        var p2:Point = null;
        for (shape1 in shapes) {
            if (shape1 is Polygon) {
                var pol1 = cast(shape1,Polygon);
                if (savedSegments[shape1.objId] == null) savedSegments[shape1.objId] = pol1.toSegments();
                var segments1:Array<Segment> = savedSegments[shape1.objId];
                var i1Offset:Int = 0;
                for (i1 in 0...1000) {
                    var v1 = i1 + i1Offset;
                    if (v1 == segments1.length) break;

                    var seg1 = segments1[v1];
                    var nodeP1:Graph.Node = null;
                    var nodeP2:Graph.Node = null;
                    p1 = seg1.getA();
                    p2 = seg1.getB();
                    // trace("tracing1: " + p1 + "   " + p2);
                    
                    if (v1 == 0) {
                        nodeP1 = graph.addNode(p1);
                        savedNodes[pol1] = [nodeP1];
                    } else nodeP1 = savedNodes[pol1][v1];
                    if (v1 != segments1.length-1) {
                        nodeP2 = graph.addNode(p2);
                        savedNodes[pol1].push(nodeP2);
                    } else nodeP2 = savedNodes[pol1].at(v1+1);

                    if (checkedShapes.length == 0) {
                        graph.connect(nodeP1,[nodeP2]);
                        // trace("conn1: " + new Point(nodeP1.x,nodeP1.y) + "    " + new Point(nodeP2.x,nodeP2.y));
                    } else {
                        var b:Bool = false;
                        for (shape2 in checkedShapes) {
                            if (shape2 is Polygon) {
                                var pol2 = cast(shape2,Polygon);
                                if (savedSegments[shape2.objId] == null) savedSegments[shape2.objId] = pol2.toSegments();
                                var segments2:Array<Segment> = savedSegments[shape2.objId];

                                var savedNode:Graph.Node = null;
                                var i2Offset:Int = 0;
                                for (i2 in 0...1000) {
                                    var v1 = i1+i1Offset;
                                    var v2 = i2+i2Offset;
                                    if (v2 == segments2.length) break;

                                    var seg1 = segments1[v1];
                                    var seg2 = segments2[v2];
                                    var p1 = seg1.getA();
                                    var p2 = seg1.getB();
                                    var p3 = seg2.getA();
                                    var p4 = seg2.getB();

                                    var inters:Point = new Point();
                                    var coll = nb.phys.Collision.checkSegments(p1,p2,p3,p4,inters);
                                    // trace("check: "+ p1 + "  " + p2 +"   " +p3+ "   " + p4+ "   "+ coll);
                                    // trace(v1 + "  " + v2);
                                    if (coll > 0) {
                                        segments1.remove(segments1[v1]);
                                        segments1.insert(v1,new Segment(p1,inters));
                                        segments1.insert(v1+1,new Segment(inters,p2));

                                        segments2.remove(segments2[v2]);
                                        segments2.insert(v2,new Segment(p3,inters));
                                        segments2.insert(v2+1,new Segment(inters,p4));

                                        var connTo:Array<nb.Graph.Node> = [savedNode == null ? nodeP1 : savedNode];
                                        
                                        var nodeP3 = savedNodes[pol2][v2];
                                        var nodeP4 = savedNodes[pol2].at(v2+1);

                                        graph.disconnect(nodeP3,[nodeP4]);
                                        connTo.push(nodeP3);
                                        connTo.push(nodeP4);

                                        var nodeInters = graph.addNode(inters);
                                        graph.connect(nodeInters, connTo);
                                        // trace("conn2: " + new Point(nodeInters.x,nodeInters.y) + "    " + [for (n in connTo) new Point(n.x,n.y)]);

                                        savedNodes[pol1].insert(v1+1,nodeInters);
                                        savedNodes[pol2].insert(v2+1,nodeInters);
                                        i1Offset++;
                                        i2Offset++;
                                        savedNode = nodeInters;
                                        b = true;
                                    }
                                }
                                if (savedNode != null) graph.connect(savedNode,[nodeP2]);
                            }
                        }
                        if (!b) {
                            graph.connect(nodeP1, [nodeP2]);
                            // trace("conn3: " + new Point(nodeP1.x,nodeP1.y) + "    " + new Point(nodeP2.x,nodeP2.y));
                        }
                    }
                    
                }
                checkedShapes.push(shape1);
            }
        }
        return graph;
    }
}