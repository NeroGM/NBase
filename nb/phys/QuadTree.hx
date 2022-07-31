package nb.phys;

import nb.shape.*;
import haxe.ds.Map;
using nb.ext.PointExt;
using nb.ext.ArrayExt;

class QTElement {
    public var o:Object;
    public var quadTree:QuadTree;
    public var quads:Array<Quad> = [];
    public var rect:Rectangle = null;

    public function new(o:Object, quadTree:QuadTree) {
        this.o = o;
        this.quadTree = quadTree;
    }

    public function remove() {
        var parentQuads:Set<Quad> = new Set();
        for (i in 0...quads.length) {
            var quad = quads.pop();
            quad.elements.remove(this);
            parentQuads.add(quad.parentQuad);
        }
        rect = null;
        quadTree = null;

        for (quad in parentQuads) quad.tryUniteChildren();
    }
}

@:allow(nb.phys.QuadTree)
@:allow(nb.phys.QTElement)
class Quad extends Rectangle {
    public var quadId:Int = -1;
    public var elements:Array<QTElement> = [];
    public var quadTree:QuadTree;
    public var parentQuad:Quad = null;
    public var siblings:Array<Quad> = [];
    public var childQuads:Array<Quad> = [];
    public var maxBucketSize:Int = 4;

    override private function new(x:Float, y:Float, w:Float, h:Float, quadTree:QuadTree, ?parentQuad:Quad) {
        super(0,0,w,h,parentQuad);
        setPosition(x,y);
        this.quadTree = quadTree;
        quadId = quadTree.nextQuadId++;

        if (parentQuad == null) return;
        this.parentQuad = parentQuad;
        this.parentQuad.childQuads.push(this);
    }

    public function getQuadAt(p:Point):Quad {
        if (childQuads.length == 0) return this;

        for (quad in childQuads) if (quad.containsPoint(p))
            return quad.getQuadAt(p);

        throw "Shouldn't happen.";
        return null; // Shouldn't happen.
    }

    private function addElement(elem:QTElement, ignoreLimit:Bool=false) {
        if (!ignoreLimit && elements.length >= maxBucketSize) {
            subdivide();
            var cQuad = getQuadAt(new Point(elem.o.x,elem.o.y));
            cQuad.addElement(elem);
            return;
        }

        var relQuad = parentQuad == null ? this : parentQuad; // parentQuad should be null only if 'this' is quadTree
        var o = elem.o;
        var p1 = new Point(o.x,o.y).relativeTo(relQuad,o.parent);
        var p2 = new Point(o.x+o.size.w,o.y+o.size.h).relativeTo(relQuad,o.parent);
        var oRect = new Rectangle(0,0,p2.x-p1.x,p2.y-p1.y,relQuad);
        oRect.setPosition(p1.x,p1.y);
        var sQuads:Array<Quad> = [for (sQuad in siblings) if (Collision.checkAABB(oRect,sQuad)) sQuad];

        if (sQuads.length != 3) {
            elem.rect = oRect;
            elem.quads.push(this);
            elements.push(elem);
            for (q in sQuads) {
                elem.quads.push(q);
                q.elements.push(elem);
            }
        } else relQuad.addElement(elem,true);
    }

    private function tryUniteChildren() {
        for (cQuad in childQuads) if (cQuad.childQuads.length != 0) return false;

        var s:Set<QTElement> = new Set();
        for (e in elements) s.add(e);
        for (cQuad in childQuads) for (e in cQuad.elements) s.add(e);
        var arr = s.toArray();

        if (arr.length > maxBucketSize) return false;

        // Unite children
        for (i in 0...childQuads.length) childQuads.last().dissolve();
        for (e in arr) if (!elements.contains(e)) addElement(e);
        return true;
    }

    private function subdivide() {
        var p:Point = elements[0].rect.center.relativeTo(this,elements[0].rect);
        for (e in elements) p = p.add(e.rect.center.relativeTo(this,e.rect)).multiply(0.5);

        for (e in elements) e.quads.remove(this);
        var elementsCopy = [for (i in 0...elements.length) elements.pop()];

        var v1 = size.w-p.x;
        var v2 = size.h-p.y;
        var quad1 = new Quad(0,0,p.x,p.y,quadTree,this);
        var quad2 = new Quad(p.x,0,v1,p.y,quadTree,this);
        var quad3 = new Quad(0,p.y,p.x,v2,quadTree,this);
        var quad4 = new Quad(p.x,p.y,v1,v2,quadTree,this);
        quad1.siblings = [quad2,quad3,quad4];
        quad2.siblings = [quad1,quad3,quad4];
        quad3.siblings = [quad1,quad2,quad4];
        quad4.siblings = [quad1,quad2,quad3];

        for (e in elementsCopy) {
            var cQuad = getQuadAt(new Point(e.o.x,e.o.y));
            cQuad.addElement(e);
        }
    }

    private function dissolve() {
        for (i in 0...elements.length) elements.pop().quads.remove(this);
        for (i in 0...siblings.length) siblings.pop();
        parentQuad.childQuads.remove(this);
        parentQuad = null;
        quadTree = null;
        quadId = -1;
        return;
    }
}

@:allow(nb.phys.Quad)
class QuadTree extends Quad {
    private var nextQuadId:Int = 0;
    public var allElements:Map<Object,QTElement> = new Map();

    override public function new(x:Float, y:Float, w:Float, h:Float, ?parent:Object) {
        super(x,y,w,h,this,null);
    }

    public function addObject(o:Object) {
        var e = new QTElement(o,this);
        allElements.set(o,e);
        var quad = getQuadAt(new Point(o.x,o.y));
        quad.addElement(e);
    }

    public function removeObject(o:Object):Bool {
        var e = allElements[o];
        if (e == null) return false;
        e.remove();
        allElements.remove(o);
        return true;
    }
}