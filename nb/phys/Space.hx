package nb.phys;

using nb.ext.PointExt;
using nb.ext.ArrayExt;
using nb.phys.Space;

typedef State = {
    var t:Float;
    var pos:Point;
    var rotation:Float;
    var velocity:Point;
    var acceleration:Point;
    var angVelocity:Float;
    var forces:Array<Force>;
}

typedef SpaceData = {
    var e:Entity;
    var space:Space;
    var states:Array<State>;
}

class Space extends Object {
    public var entities:Array<Entity> = [];
    public var spaceDatas:Array<SpaceData> = [];

    public function new(?parent:h2d.Object) {
        super(0,0,parent);
        Manager.spaces.push(this);
    }

    override public function update(dt:Float) {
        for (sd in spaceDatas) {
            sd.states = [{
                t:0,
                pos:sd.e.localToGlobal(),
                rotation:sd.e.rotation,
                velocity:sd.e.velocity.clone(),
                acceleration:sd.e.acceleration,
                angVelocity:sd.e.angVelocity,
                forces:[for (f in sd.e.forces) {value:f.value, at:f.at}]
            }];
         
            sd.moveSpaceData(dt);
        }
    }

    public function addEntity(e:Entity):Bool {
        if (e.spaces.contains(this)) return false;

        e.spaces.push(this);
        entities.push(e);

        var sd:SpaceData = { space:this, e:e, states:[] };
        spaceDatas.push(sd);
        e.spaceDatas.push(sd);

        return true;
    }

    public function removeEntity(e:Entity):Bool {
        if (!entities.remove(e)) return false;

        for (sd in e.spaceDatas) if (sd.space == this) {
            spaceDatas.remove(sd);
            e.spaceDatas.remove(sd);
            return true;
        }
        
        throw "Entity doesn't have an associated spaceData."; // Shouldn't happen.
    }

    public static function moveSpaceData(sd:SpaceData, dt:Float, ?tt:Float, addToStates:Bool=true):State {
        var lastSd = sd.states[sd.states.length-1];
        if (tt == null) tt = 1-lastSd.t%1;

        var time = dt*tt;
        for (force in sd.e.forces) sd.e.applyForce(force.value, force.at);
        sd.e.move(sd.e.velocity.x*time, sd.e.velocity.y*time);
        sd.e.rotate(sd.e.angVelocity*time);
        sd.e.acceleration = sd.e.velocity.sub(sd.states[0].velocity);
        sd.e.t = lastSd.t + tt;

        var state = sd.e.getState();
        if (addToStates) sd.states.push(state);
        return state;
    }
}