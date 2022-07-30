package nb.phys;

using nb.ext.PointExt;
using nb.ext.ArrayExt;
import nb.shape.*;

enum EntityType {
    STATIC;
    DYNAMIC;
}

enum CollisionResolutionMode {
    DEFAULT;
    CCD;
}

class Entity extends Object {
    public var shapes:Shapes;
    public var obj:Object;
    public var type:EntityType = DYNAMIC;

    public var velocity:Point = new Point();
    public var acceleration:Point = new Point();
    public var angle:Float = 0;
    public var angVelocity:Float = 0;
    public var torque:Float = 0;
    public var mass:Float = 1;
    public var elasticity:Float = 0;
    public var resistance:Float = 0;
    public var forces:Array<Force> = [];

    public var collResMode:CollisionResolutionMode = DEFAULT;

    public function new(obj:Object, ?type:EntityType) {
        super(0,0,obj);
        shapes = new Shapes(this);

        if (type != null) this.type = type;
        this.obj = obj;
        obj.entity = this;
        addChild(shapes);
    }

    public inline function addShape(shape:Shape) {
        shapes.addShape(shape);
        size = shapes.size;
    }

    public function addShapes(shapes:Array<Shape>) {
        this.shapes.addShapes(shapes);
        size = this.shapes.size;
    }

    public function addForce(force:Force) forces.push(force);
    
    public function removeForce(force:Force) forces.remove(force);

    public function applyForce(force:Point, ?at:Point, drawDebug:Bool=true) {
        if (force.x == 0 && force.y == 0) return;

        if (at == null) at = new Point();
        var at2 = at.clone();
        at2.rotate(obj.rotation);
        
        var dot = (at.equals(shapes.centroid)) ? 1 : at2.normalized().dot(force.normalized());
        velocity = velocity.add(new Point((force.x/mass)*Math.abs(dot), (force.y/mass)*Math.abs(dot)));
        applyTorque(force,at2);
    }

    public function applyTorque(force:Point, at:Point) {
        var torque:Float = at.cross(force);
        var moi:Float = 0; // Moment of inertia

        var s = shapes.union[0];
        if (shapes.union.length == 1 && s is Rectangle)
            moi = (mass*(s.size.w*s.size.w+s.size.h*s.size.h)) / 12;
        else {
            var a:Float = 0;
            var b:Float = 0;
            var points:Array<Point> = cast(shapes.union[0],Polygon).points;
            for (i in 0...points.length-1) a += Math.abs(points[i+1].cross(points[i])) * (points[i].dot(points[i]) + points[i].dot(points[i+1]) + points[i+1].dot(points[i+1]));
            for (i in 0...points.length-1) b += Math.abs(points[i+1].cross(points[i]));
            moi = mass * (a/(6*b));
        }        

        angVelocity += torque/moi;
    }
}