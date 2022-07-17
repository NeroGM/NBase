package nb;

using nb.ext.FloatExt;
import nb.shape.Polygon;
import haxe.ds.ReadOnlyArray;

/**
 * Represents a node in a `nb.Graph` instance.
 *
 * @since 0.2.0
 **/
@:allow(nb.Graph)
@:access(nb.Graph)
class Node extends Object {
    /** The unique id of this instance. **/
    public var id:Int;
    /** The id of the netword associated with this node. **/
    public var netId(default,set):Int = -1;

    /** Used in pathfinding. A cost associated to this node. **/
    public var cost(default,null):Int = -1;
    /** Used in pathfinding. The distance between this node and another node. **/
    public var dist:Float = -1;
    /** Used in pathfinding. The node the pathfinder came from to get to this node. **/
    private var cameFrom:Node = null;

    /** Contains all the nodes connected to this node. **/
    public var connections(default, null):Array<Node> = [];
    /** The `nb.Interactive` instance associated with this node. **/
    public var interactive:Interactive;
    /** Whether this node is enabled. **/
    public var enabled:Bool = true;
    
    /**
     * Creates an `nb.Graph.Node` instance.
     * 
     * @param x The x coordinate of the instance.
     * @param y The y coordinate of the instance.
     * @param graph A `nb.Graph` instance that will be the parent of this instance.
     **/
    override public function new(x:Float, y:Float, graph:Graph) {
        super(graph);
        this.id = graph.nextNodeId++;
        setPosition(x,y);

        interactive = new Interactive(4,4);
        interactive.setPosition(-2,-2);
        interactive.defaultInit();
        interactive.onDragStart = (e1) -> {
            var p = new Point(this.x,this.y);
            var pStart = new Point(e1.relX,e1.relY);
            interactive.onDrag = (e2) -> {
                var diffP = globalToLocal(new Point(e2.relX,e2.relY)).sub(globalToLocal(pStart.clone()));
                setPosition(p.x+diffP.x,p.y+diffP.y);
                // graph.debugDraw();
                graph.onPointMove();
            }
            interactive.onDragEnd = (_) -> { interactive.onDragEnd = interactive.onDrag = (_) -> {}; }
        }
    }

    /** Adds an interactive to move the node. **/
    public inline function addInteractive() {
        addChild(interactive);
    }

    /** Remove the node's interactive. **/
    public inline function removeInteractive() {
        interactive.remove();
    }

    private function set_netId(v:Int) {
        return netId = v;
    }

    /** The string representation of this instance. **/
    override public function toString():String return "Node:"+id;
}


/**
 * A class that represents a graph. Serves as a container for a group of nodes.
 *
 * @since 0.2.0
 **/
@:allow(nb.Graph.Node)
class Graph extends Object {
    /** All `nb.Node` instances this graph is using. **/
    public var allNodes(default,null):Array<Node> = [];
    /** The id of the next `nb.Node` instance that will be created by this instance. **/
    private var nextNodeId:Int = 0;

    /** Used in pathfinding. The starting node of the pathfinder. **/
    private var start:Node = null;
    /** Used in pathfinding. The destination of the pathfinder. **/
    private var end:Node = null;
    /** Used in pathfinding. The node the pathfinder is currently onto. **/
    private var currentNode:Node = null;
    /** Used in pathfinding. The nodes that have their "pathfinder values" assigned.  **/
    private var calculatedNodes:Array<Node> = [];
    /** Used in pathfinding. The nodes that just had their "pathfinder values" assigned. Resets at the start of the loop. **/
    private var newCalcNodes:Array<Node> = [];
    /** Used in pathfinding. The nodes that the pathfinder had been on.  **/
    private var checkedNodes:Array<Node> = [];
    /** Used in pathfinding. The maximum loop count. **/
    private var defaultMaxStep:Int = 1000;
    /** The last path that the pathfinder made. **/
    public var lastPath:Array<Node> = [];
    private var currISearch:Int = -1; // ! ???

    /**
     * Whether this instance should track networks.
     * Networks are nodes all connected to each other, directly or indirectly.
     **/
    public var trackNetworks(default,null):Bool;
    /** Whether dead networks can be revived to form a new network. **/
    public var takeDeadGroups:Bool = false;
    /**
     * Contains all networks of this instance. A network is an array of `nb.Node` instances
     * that are all connected. A connection betweens two nodes in a network means that there
     * exists a path that connects the two.
     *
     * A network has an associated ID number starting from 1. Doing `networks[5]` accesses
     * the array of nodes pertaining to a network with `5` as the id.
     **/
    public var networks:Array<Array<Node>> = [[]];
    /** Contains network ids that were used but anymore. **/
    public var deadNetworksIds:Array<Int> = [];
    /** Contains network ids that were never used. Those ids are always lower than the highest used netword id. **/
    public var skippedNetworksIds:Array<Int> = [];

    /** The `nb.Graphics` instance to draw this instance's debug visuals. **/
    public var debugG(default, null):Graphics = new Graphics();
    /** The `nb.Graphics` instance to draw this instance's interactives debug visuals. **/
    public var debugInteractives:Array<Interactive> = [];

    /**
     * Creates an `nb.Graph` instance.
     *
     * @param parent The instance's parent object.
     * @param defaultAutoConnect Whether this instance should use assign a default function to `autoConnect`.
     * This function connects a newly added node to the previous node that was added.
     * @param trackNetworks Whether this instance should track networks. (See `networks`.)
     **/
    public function new(?parent:h2d.Object, defaultAutoConnect:Bool=false, trackNetworks:Bool=false) {
        super(parent);
        this.trackNetworks = trackNetworks;
        if (defaultAutoConnect) autoConnect = (allNodes, newNode) -> if (allNodes.length > 0) connect(newNode, [allNodes[allNodes.length-1]]);
    }

    /**
     * Adds a node to this graph.
     * 
     * @param p An `h2d.col.Point` instance containing the coordinates of the node.
     * @param autoConnect If `true` this instance's `autoConnect` function will be called.
     * @return The `nb.Graph.Node` instance representing the node.
     **/
    public function addNode(p:Point, autoConnect:Bool=false):Node {
        var node:Node = new Node(p.x, p.y, this);
        if (trackNetworks) { networks[0].push(node); node.netId = 0; }
        if (autoConnect) this.autoConnect(allNodes, node);
        allNodes.push(node);

        return node;
    }

    /** Returns the node with the coordinates of `p`. (There's a tiny tolerance value.) **/
    public function getNodeAtPoint(p:Point):Node {
        for (node in allNodes) if (node.x.equals(p.x) && node.y.equals(p.y)) return node;
        return null;
    }

    /** Removes a node from this graph. **/
    public function removeNode(node:Node) {
        for (n in allNodes) n.connections.remove(node);
        allNodes.remove(node);
    }

    /**
     * Connects a node to other nodes.
     * 
     * @param node The node that will be connected.
     * @param toNodes The nodes `node` will connects to.
     **/
    public function connect(node:Node, toNodes:Array<Node>) {
        for (toNode in toNodes) if (node != toNode) {
            if (node.connections.indexOf(toNode) == -1) {
                node.connections.push(toNode);
                toNode.connections.push(node);

                if (trackNetworks) {
                    if (toNode.netId == 0) node.netId == 0 ? newNetwork(node,toNode) : { toNode.netId = node.netId; networks[0].remove(toNode); }
                    else if (node.netId == 0) { node.netId = toNode.netId; networks[0].remove(node); networks[toNode.netId].push(node); }
                    else if (toNode.netId > node.netId) convertNetwork(node.netId, toNode.netId);
                    else if (toNode.netId < node.netId) convertNetwork(toNode.netId, node.netId);
                }

                onConnect(node,toNode);
            }
        }
    }

    /**
     * Disconnects a node from other nodes.
     * 
     * @param node The node that will be disconnected.
     * @param fromNodes The nodes `node` will disconnects from.
     **/
    public function disconnect(node:Node, fromNodes:Array<Node>) {
        for (n in fromNodes) if (node != n) {
            if (node.connections.remove(n)) {
                n.connections.remove(node);

                if (trackNetworks) {
                    var path = path(node,n);
                    if (path == null || path[path.length-1] != n) {
                        var oneSingled:Bool = false;
                        if (node.connections.length == 0) {
                            networks[node.netId].remove(node);
                            networks[0].push(node);
                            node.netId = 0;
                            oneSingled = true;
                        }
                        if (n.connections.length == 0) {
                            networks[n.netId].remove(n);
                            networks[0].push(n);
                            n.netId = 0;
                            oneSingled = true;
                        }
                        if (!oneSingled) promoteNetwork(node);
                    }
                }
                
                onDisconnect(node,n);
            }
        }
    }

    /** Declares the formation of a new network. It is called as soon as two solitary nodes are connected. **/
    private function newNetwork(node1:Node, node2:Node):Array<Node> {
        if (takeDeadGroups) {
            var deadId:Null<Int> = deadNetworksIds.shift();
            if (deadId != null) {
                networks[deadId] = [node1,node2];
                networks[0].remove(node1); networks[0].remove(node2);
                node1.netId = node2.netId = deadId;
                return networks[deadId];
            }
        }

        var skippedId:Null<Int> = skippedNetworksIds.shift();
        if (skippedId != null) {
            networks[skippedId] = [node1,node2];
            networks[0].remove(node1); networks[0].remove(node2);
            node1.netId = node2.netId = skippedId;
            return networks[skippedId];
        }

        var newId:Int = networks.length;
        networks.push([node1,node2]);
        networks[0].remove(node1); networks[0].remove(node2);
        node1.netId = node2.netId = newId;
        return networks[newId];
    }

    /**
     * Moves all the nodes of a network to another network.
     * 
     * All the nodes belonging to the network with id `from` now belongs to the network with id `to`.
     * Nothing happens to the nodes that are already in the destination network.
     *
     * @param from The ID of the network to move from.
     * @param to The ID of the network to move to.
     **/
    public function convertNetwork(from:Int, to:Int) {
        if (from == to) return;
        
        var fromNet = networks[from];
        var toNet = networks[to];
        if (toNet == null) {
            toNet = [];
            for (i in networks.length...to) skippedNetworksIds.push(i);
            networks[to] = toNet;
        }

        networks[from] = [];
        for (node in fromNet) { node.netId = to; toNet.push(node); }

        if (from != 0) deadNetworksIds.push(from);
    }

    /**
     * Creates a new network from nodes that needs to be separated from their previous network.
     * 
     * When a disconnection happens in a network that causes it to not have all its nodes
     * connected anymore, the network becomes invalid. One disconnected part of that network
     * must changes its id to define a new network, then the invalid network becomes valid again.
     *
     * An invalid network is a network that doesn't have all its nodes connected. This should always
     * be resolved since it goes against the definition of a network.
     * 
     * @param node The node that will be pertaining to a new network, along with the nodes
     * that it connects to directly or indirectly.
     * @return An array of nodes which is the new network.
     **/
    private function promoteNetwork(node:Node):Array<Node> {
        var node2 = node.connections[0];

        var oldNet:Array<Node> = networks[node.netId];
        oldNet.remove(node);
        oldNet.remove(node2);

        var newNet:Array<Node> = newNetwork(node,node2);
        var onNodes:Array<Node> = [node,node2];
        var nextNodes:Array<Node> = [];
        while (onNodes.length != 0) {
            for (onNode in onNodes) for (conn in onNode.connections) {
                if (!newNet.contains(conn)) {
                    conn.netId = node.netId;
                    newNet.push(conn);
                    oldNet.remove(conn);
                    nextNodes.push(conn);
                }
            }

            onNodes = nextNodes;
            nextNodes = [];
        }

        return newNet;
    }

    /** Empties the graph. **/
    public function clear() {
        allNodes = [];
        calculatedNodes = [];
        newCalcNodes = [];
        checkedNodes = [];
        networks = [];
        deadNetworksIds = [];
        skippedNetworksIds = [];
        start = end = currentNode = null;
        nextNodeId = 0;
    }

    /**
     * Returns a path between a node and another node.
     *
     * @param start The node to start the path from.
     * @param end The node to end the path to.
     * @param maxStep The maximum number of steps/loop count.
     * @return An array of `nb.Graph.Node` instances representing a path.
     **/
    public function path(start:Node, end:Node, ?maxStep:Null<Int>):Null<Array<Node>> {
        if (maxStep == null) maxStep = this.defaultMaxStep;
        if (start == end) return [start];

        this.start = start;
        this.end = end;
        currentNode = start;
        calculatedNodes = [start];
        checkedNodes = [start];
        newCalcNodes = [];
        start.cost = 0;

        onPathStart();

        var c:Int = 1;
        while (1 == 1) {
            for (node in calculatedNodes) onWasCalculated(node);

            newCalcNodes = [];
            for (node in calcSurroundings(currentNode)) {
                newCalcNodes.push(node);
                onJustCalculated(node);
                calculatedNodes.push(node);
                calculatedNodes.sort((a,b)->{
                    if (getDistance(a,end)+a.cost < getDistance(b,end)+b.cost) return -1;
                    else if (getDistance(a,end)+a.cost > getDistance(b,end)+b.cost) return 1;
                    return 0;
                });
            }

            for (i in 0...calculatedNodes.length) if (checkedNodes.indexOf(calculatedNodes[i]) == -1) {
                currentNode = calculatedNodes[i];
                checkedNodes.push(calculatedNodes[i]);
                onCurrentNode(currentNode);
                break;
            }

            if (currentNode == start) return [start];

            if (currentNode == end || c++ >= maxStep) {
                var path:Array<Node> = [currentNode];
                while (path[0] != start) path.insert(0,path[0].cameFrom);
                lastPath = path;
                return path;
            }
        }
        return null;
    }

    // static var c:Int = 0;
    // public function addSegmentInteractive(n1:Node, n2:Node) {
    //     var t = haxe.Timer.stamp();
    //     var interactive:Interactive = null;
    //     if (c >= debugInteractives.length){
    //         interactive = new Interactive(0,0,this);
    //         debugInteractives.push(interactive);
    //         trace("N");
    //     } else {
    //         interactive = debugInteractives[c];
    //     }
    //     c++;

    //     interactive.onMove = (e) -> {
    //         var seg = new Segment(n1.p,n2.p);
    //         var p = globalToLocal(new Point(e.relX, e.relY));
    //         var p2 = seg.project(p);
    //         // trace(localToGlobal(p2));
    //     }
    //     interactive.onClick = (e) -> {
    //         if (e.button == nb.Key.MOUSE_RIGHT) {
    //             var seg = new Segment(n1.p,n2.p);
    //             var p = globalToLocal(new Point(e.relX, e.relY));
    //             var p2 = seg.project(p);

    //             var newNode = addNode(new Point(p2.x,p2.y),false);
    //             disconnect(n1,[n2]);
    //             connect(n1,[newNode]);
    //             connect(newNode,[n2]);
    //             debugDraw(true);
    //             onPointMove();
    //         }
    //     }

    //     var dist = new Point(n2.x-n1.x, n2.y-n1.y);
    //     interactive.setPosition(n1.x,n1.y);
    //     var thickness:Int = 1;
    //     var angle = nb.utils.Math.angleBetweenPoints(n1.p, n2.p);
    //     var cos1 = Math.cos(angle+Math.PI*0.5); var sin1 = Math.sin(angle+Math.PI*0.5);
    //     var thickP = new Point(thickness*cos1,thickness*sin1);
    //     var offsetP = new Point(4*Math.cos(angle), 4*Math.sin(angle));
    //     // cos1 = sin1 = 1;
    //     var a = [
    //         new Point(offsetP.x-thickP.x,offsetP.y-thickP.y),
    //         new Point(-offsetP.x+dist.x-thickP.x,-offsetP.y+dist.y-thickP.y),
    //         new Point(-offsetP.x+dist.x+thickP.x,-offsetP.y+dist.y+thickP.y),
    //         new Point(offsetP.x+thickP.x,offsetP.y+thickP.y)
    //     ];
    //     interactive.loadShape(new nb.shape.Polygon(a));
    //     interactive.shapes.debugDraw();
    //     // trace(n1.p + "   " + n2.p + "    " + a);
    //     // trace(haxe.Timer.stamp()-t + "   "  + Manager.nbObjects.length);
    // }

    // /*
    // * POINT
    // * Green : Connected, in path
    // * Grey : Connected, not in path
    // * Red : No connection
    // * 
    // * SEGMENT
    // * Lighter green : In path
    // * Grey : Anything else
    // */
    // public function debugDraw2(withInteractive:Bool=false) {
    //     debugG2.clear();
        
    //     var params:Array<nb.Graphics2.DrawingParams2> = [for (i in 0...4) nb.Graphics2.getDefaultParams()];
    //     params[0].lineColor = 0xFFFFFF;
    //     params[0].fillColor = 0x00FF00;
    //     params[0].filled = true;
    //     params[1].lineColor = 0xFFFFFF;
    //     params[1].fillColor = 0x888888;
    //     params[1].filled = true;
    //     params[2].lineColor = 0x333333;
    //     params[2].fillColor = 0xFF0000;
    //     params[2].filled = true;
    //     params[3].lineColor = 0x006600;

    //     var checkedNodes:Array<Node> = [];
    //     var onNodes:Array<Node> = [allNodes[0]];
    //     var nextNodes:Array<Node> = [];
    //     currISearch = currISearch > 2000000 ? 0 : currISearch+1;
    //     while (onNodes.length > 0) {
    //         for (onNode in onNodes) {
    //             if (onNode.connections.length > 0) {
    //                 debugG2.drawCircle(onNode.x, onNode.y, 2, 0, lastPath.contains(onNode) ? params[0] : params[1]);

    //                 for (conn in onNode.connections) {
    //                     if (!checkedNodes.contains(conn)) nextNodes.push(conn);
    //                 }
    //             } else debugG2.drawCircle(onNode.x, onNode.y, 2, 0, params[2]);

    //             checkedNodes.push(onNode);
    //         }

    //         onNodes = nextNodes;
    //         nextNodes = [];
    //     }

    //     addChild(debugG2);
    // }

    // public function debugDraw(withInteractive:Bool=true):Graphics {
    //     if (allNodes.length <= 0) return debugG;
    //     c = 0;

    //     debugG.clear();
    //     var gParams = Graphics.getDefaultParams(2);
    //     gParams[0].lineColor = 0x880088;
    //     gParams[1].lineColor = 0xFF0000;

    //     var checkedNodes:Array<Node> = [];
    //     var uncheckedNodes:Array<Node> = allNodes.copy(); // maybe stop being lazy and get rid of it ?
    //     var onNodes:Array<Node> = [allNodes[0]];
    //     var nextNodes:Array<Node> = [];
    //     while (onNodes.length > 0) {
    //         for (onNode in onNodes) {
    //             checkedNodes.push(onNode);
    //             uncheckedNodes.remove(onNode);

    //             if (onNode.connections.length != 0) {
    //                 debugG.drawCircle(onNode.x,onNode.y,2,0,null,gParams[0]);
    //                 for (connectedNode in onNode.connections) if (!checkedNodes.contains(connectedNode)) {
    //                     debugG.drawLine(onNode.x,onNode.y,connectedNode.x,connectedNode.y,null,gParams[0]);
    //                     if (withInteractive) addSegmentInteractive(onNode,connectedNode);
    //                     nextNodes.push(connectedNode);
    //                 }
    //             } else debugG.drawCircle(onNode.x,onNode.y,2,0,null,gParams[1]);
    //             if (withInteractive) onNode.addInteractive();
    //         }

    //         if (nextNodes.length > 0) { onNodes = nextNodes; nextNodes = []; }
    //         else if (uncheckedNodes.length > 0) onNodes = [uncheckedNodes[0]];
    //         else onNodes = [];
    //     }
    //     // addChild(debugG);
        
    //     return debugG;
    // }

    private function calcSurroundings(node:Node):Array<Node> {
        var a:Array<Node> = [];
        for (con in node.connections) {
            if (calculatedNodes.indexOf(con) != -1 || !con.enabled) continue;
            con.cameFrom = node;
            con.cost = node.cost+1;
            con.dist = getDistance(con, end);
            a.push(con);
        }
        return a;
    }

    public dynamic function getDistance(n1:Node, n2:Node):Float return Math.abs(n2.x - n1.x) + Math.abs(n2.y - n1.y);

    public dynamic function autoConnect(allNodes:Array<Node>, newNode:Node) { }

    public dynamic function onConnect(node1:Node, node2:Node) { }

    public dynamic function onDisconnect(node1:Node, node2:Node) { }

    public dynamic function onWasCalculated(node:Node) { }

    public dynamic function onJustCalculated(node:Node) { }

    public dynamic function onCurrentNode(node:Node) { }

    public dynamic function onPathStart() { }

    public dynamic function onPointMove() { }
}