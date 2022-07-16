package nb.shape;

using nb.ext.PointExt;

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

    private function makeUnion() {
    //     var shapes = a;
    //     var graph = new Graph();
    //     var startingP:Point = null;
    // //    graph.onConnect = (node1, node2) -> trace("connect : " + node1.p + "  ->  " + node2.p);
    // //    trace(" ---------------- " + a);
    //     if (shapes.length > 1) {
    //         for (shape1 in shapes) {
    //             if (shape1.type == POLYGON || shape1.type == CIRCLE) {
    //                 var pol1:Polygon = null;
    //                 if (shape1.type == POLYGON) pol1 = cast(shape1,Polygon);
    //                 else {
    //                     var c = cast(shape1,Circle);
    //                     pol1 = Polygon.makeCircle(c.col.x,c.col.y,c.radius,0);
    //                 }
    //                 var segments1 = pol1.toSegments();
    //                 var startingNode:nb.Graph.Node = null;
    //                 var onNode:nb.Graph.Node = null;
    //                 for (seg1 in segments1) {
    //                     var p1 = new Point(seg1.x,seg1.y);
    //                     var p2 = new Point(seg1.x+seg1.dx,seg1.y+seg1.dy);
    //                     var sIntersections:Array<Point> = [];
    //                     for (shape2 in shapes) if (shape2 != shape1) {
    //                         if (shape2.type == POLYGON) {
    //                             var pol2 = cast(shape2,Polygon);
    //                             var segments2 = pol2.points.toSegments();
    //                             for (seg2 in segments2) {
    //                                 var p3 = new Point(seg2.x,seg2.y);
    //                                 var p4 = new Point(seg2.x+seg2.dx,seg2.y+seg2.dy);
    //                                 var intersection:Point = new Point();
    //                                 var v = nb.phys.Collision.checkSegments(p1,p2,p3,p4,intersection);
    //                                 //trace("(" + p1+","+p2+")     ("+p3+","+p4+")");
    //                             //    trace(v);
    //                                 if (v > 0) {
    //                                     sIntersections.push(intersection);
    //                                     //trace("inters:    (" + p1+","+p2+")     ("+p3+","+p4+")    " + intersection);
    //                                 }
    //                             }
    //                         } else if (shape2.type == CIRCLE) {
    //                             var cir2 = cast(shape2,Circle);
    //                             var v = nb.phys.Collision.checkCircleSegment(seg1,cir2.col);
    //                             // trace(v);
    //                             if (v != null) for (inters in v) sIntersections.push(inters);
    //                         } else throw "nah";
    //                     }

    //                     if (seg1 == segments1[0]) {
    //                         var node = graph.getNodeAtPoint(new Point(p1.x,p1.y));
    //                         startingNode = onNode = node == null ? graph.addNode(new Point(p1.x,p1.y)) : node;
    //                     }
                        
    //                     nb.ext.ArrayExt.quickSort(sIntersections,(a,b) -> {
    //                         return a.sub(p1).length() < b.sub(p1).length();
    //                     });

    //                     for (inters in sIntersections) {
    //                         var node2 = graph.getNodeAtPoint(inters);
    //                         // trace(inters + "   " + (node2 == null ? "null" : Std.string(node2.p)));
    //                         if (node2 == null) node2 = graph.addNode(inters.clone());
    //                         graph.connect(node2, [onNode]);
    //                         onNode = node2;
    //                     }

    //                     var p = new Point(seg1.x+seg1.dx,seg1.y+seg1.dy);
    //                     var toNode:nb.Graph.Node = graph.getNodeAtPoint(p);
    //                     if (toNode == null) toNode = graph.addNode(p);
    //                     graph.connect(toNode, [onNode]);
    //                     onNode = toNode;

    //                     var farthestP = pol1.getSupportPoint(new Point(1,1));
    //                     if (startingP == null || startingP.length() < farthestP.length()) startingP = farthestP;
    //                     //  trace("e      " + pol1.type +"     " + pol1.subType);
    //                 }
    //             } else throw "??";
    //         }
    //         // trace(startingP);

    //         // Connect nodes
    //         var unvisitedNodes:Array<nb.Graph.Node> = graph.allNodes.copy();
    //         var visitedNodes:Array<nb.Graph.Node> = [];
    //         var lastNode:nb.Graph.Node = null;
    //         var onNode:nb.Graph.Node = null;  for (n in graph.allNodes) if (n.p.equalEps(startingP)) { onNode = n; break; }
    //         var startingNode:nb.Graph.Node = onNode;
    //         var res:Array<Array<Point>> = [[onNode.p]];
    //         var shapeC:Int = 0;
    //         var vec = new Point(1,1);
    //         var maxC:Int = 500;
    //         while (1 == 1) {
    //             unvisitedNodes.remove(onNode);
    //             visitedNodes.push(onNode);
    //             //trace(onNode.p);
    //             var connectedNodes:Array<nb.Graph.Node> = [for (n in onNode.connections) n];
    //             nb.ext.ArrayExt.quickSort(connectedNodes, (n1,n2) -> {
    //                 // Todo: add to utils
    //                 var vec = vec.normalized(); 
    //                 var p1 = n1.p.sub(onNode.p).normalized(); var dp1 = vec.dot(p1);
    //                 var p2 = n2.p.sub(onNode.p).normalized(); var dp2 = vec.dot(p2);
    //                 var v1 = vec.cross(p1) >= 0 ? dp1 : (dp1*-1)-2;
    //                 var v2 = vec.cross(p2) >= 0 ? dp2 : (dp2*-1)-2;
    //                 return v1 > v2;
    //             });
    //             var a:Array<Point> = [];
    //             for (node in connectedNodes) a.push(node.p.sub(onNode.p));
    //             var s = "v:" + vec.normalized() + "  a:";
    //             for (node in connectedNodes) s += "cross "+vec.normalized().cross(node.p.sub(onNode.p).normalized())+ "    dot " + vec.normalized().dot(node.p.sub(onNode.p).normalized()) + "    ";
    //             //trace(a);
    //             //trace(s);

    //             var toNode = null;
    //             for (node in connectedNodes) if (lastNode != node) { toNode = node; break; }

    //             if (toNode != null) {
    //                 vec = toNode.p.sub(onNode.p).multiply(-1);
    //                 lastNode = onNode;
    //                 onNode = toNode;
    //                 res[shapeC].push(toNode.p);
    //             }
                
    //             if (toNode == startingNode && res[shapeC].length > 2) {
    //                 res[shapeC].pop();

    //                 if (unvisitedNodes.length > 0) {
    //                     nb.ext.ArrayExt.quickSort(unvisitedNodes, (n1,n2) -> {
    //                         return n1.p.length() > n2.p.length();
    //                     });

    //                     var lastPol = new Polygon(res[shapeC]);
    //                     var toRemove:Array<nb.Graph.Node> = [];
    //                     for (node in unvisitedNodes) if (lastPol.containsPoint(node.p)) toRemove.push(node);
    //                     for (node in toRemove) unvisitedNodes.remove(node);

    //                     if (unvisitedNodes.length < 3) break;
    //                     lastNode = null;
    //                     startingNode = onNode = unvisitedNodes[0];
    //                     vec = onNode.p.clone();
    //                     shapeC++;
    //                     res.push([onNode.p]);
    //                 } else break;
    //             }

    //             if (--maxC <= 0) throw "union : max loop count reached";
    //         }

    //         // trace(res);
    //         union = [for (a in res) if (a.length>=3) {
    //             var pol = new h2d.col.Polygon(a.concat([a[0]])).optimize(0.15);
    //             pol.points.pop();
    //             new Polygon(pol.points,this);
    //         }];
    //         // trace(union);
    //     } else {
    //         union = shapes.copy();
    //     }

    // //    addChild(graph.debugDraw());
    }
}