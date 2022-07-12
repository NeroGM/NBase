package nb;

/**
 * Contains a function that is scheduled to be executed after some time.
 * 
 * @since 0.1.0
 **/
class DelayedF {
    /** A name to identify this instance. **/
	public var name:String;
    /** The scheduled function. Will have this instance as argument. **/
	public var f:DelayedF->Void;
    /** The time, in seconds, before the associated function gets executed. **/
	public var t(default,null):Float;
    /**
     * The amount of time in seconds, or number of frames if `frames` is set to `true`,
     * after which the function was set to be executed.
     **/
	public var tStart:Float;
    /**
     * Whether the associated function is set to be executed only once.
     * If `false`, the function gets executed every `tStart` seconds.
     **/
	public var once:Bool;
    /** If `true`, `t` is a number or frames, otherwise it's a time in seconds. **/
	public var frames(default,null):Bool;

    /**
     * Creates an `nb.Timer.DelayedF` instance.
     *
     * @param name A name to identify this instance.
     * @param f The scheduled function. Will have this instance as argument.
     * @param t The time, in seconds, before the associated function gets executed.
     * @param once Whether the associated function is set to be executed only once.
     * If `false`, the function gets executed every `tStart` seconds.
     * @param frames If `true`, `t` is a number or frames, otherwise it's a time in seconds.
     **/
	public function new(name:String, f:DelayedF->Void, t:Float, once:Bool, frames:Bool) {
		this.name = name;
		this.f = f;
		this.t = t;
		this.tStart = t;
		this.once = once;
		this.frames = frames;
	}

    /**
     * Updates variables and executes the associated function if `t <= 0`.
     *
     * @param dt The amount of time in seconds elapsed. Ignored if `frames` is set to `true`.
     * @return `true` if this instance should cease to be executed, `false` otherwise.
     **/
    public function tick(dt:Float):Bool {
        if (!frames) t -= dt;
        else t -= 1;
        if (t <= 0) {
            f(this);
            if (once) return true;
            t = tStart;
        }
        return false;
    }
}

/**
 * Contains a function that is scheduled to be executed when a condition is met.
 * 
 * @since 0.1.0
 **/
class ConditionalF {
    /** A name to identify this instance. **/
	public var name:String;
    /** The scheduled function. Will have this instance as argument. **/
	public var f:ConditionalF->Void;
    /** When this function returns `true`, `f` gets executed. **/
	public var condition:Void->Bool;
    /**
     * Whether the associated function is set to be executed only once.
     * If `false`, the function is executed every frame as long as `condition` returns `true`.
     **/
	public var once:Bool;

    /**
     * Creates an `nb.Timer.ConditionalF` instance.
     * 
     * @param name A name to identify the instance.
     * @param f The scheduled function. Will have the instance as argument.
     * @param condition When this function returns `true`, `f` gets executed.
     * @param once Whether the associated function is set to be executed only once.
     * If `false`, the function is executed every frame as long as `condition` returns `true`.
     **/
	public function new(name:String, f:ConditionalF->Void, condition:Void->Bool, once:Bool) {
		this.name = name;
		this.f = f;
		this.condition = condition;
		this.once = once;
	}

    /**
     * Updates variables and executes the associated function if the condition is met.
     *
     * @param dt An amount of time elapsed, in seconds.
     * @return `true` if this instance should cease to be executed, `false` otherwise.
     **/
     public function tick(dt:Float):Bool {
        if (condition()) {
            f(this);
            return once;
        }
        return false;
    }
}

/**
 * Contains a function that is to be executed every frame.
 * 
 * @since 0.1.0
 **/
@:allow(nb.Timer)
class UpdateF {
    /** A name to identify this instance. **/
	public var name:String;
    /** The function to be executed every frame. Will have this instance as argument. **/
	public var f:UpdateF->Void;
    /** The amount of time elapsed, in seconds. **/
	public var tElapsed(default,null):Float;
    /** When this function returns `true`, `f` stops being executed. **/
	public var endCondition:Void->Bool;
    /** The amount of frames elapsed. **/
	public var tFrames(default,null):Int;

    /**
     * Creates an `nb.Timer.UpdateF` instance.
     *
     * @param name A name to identify the instance.
     * @param f The function to be executed every frame. Will have the instance as argument.
     * @param endCondition When this function returns `true`, `f` stops being executed.
     **/
	public function new(name:String, f:UpdateF->Void, endCondition:Void->Bool) {
		this.name = name;
		this.f = f;
		this.tElapsed = 0;
		this.endCondition = endCondition;
		this.tFrames = 0;
	}

    /**
     * Updates variables and executes the associated function.
     *
     * @param dt An amount of time in seconds elapsed.
     * @return `true` if this instance should cease to be executed, `false` otherwise.
     **/
    public function tick(dt:Float):Bool {
        tElapsed += dt;
        f(this);
        if (endCondition()) return true;
        return false;
    }
}

/**
 * A class to schedule tasks.
 * 
 * @since 0.1.0
 **/
class Timer {
    /** All active `nb.Timer.DelayedF` instances. **/
    public static final delayedFs:Array<DelayedF> = [];
    /** All active `nb.Timer.DelayedF` instances. **/
	public static final delayedThreads:Array<DelayedF> = [];
    /** All active `nb.Timer.ConditionalF` instances. **/
	public static final conditionalFs:Array<ConditionalF> = [];
    /** All active `nb.Timer.UpdateF` instances. **/
	public static final updateFs:Array<UpdateF> = [];

    /**
     * The update function that gets called by `nb.Manager`.
     *
     * All active functions gets updated here, except for `delayedThreads`, which gets
     * updated in the `threadUpdate` function.
     **/
    public static function update(dt:Float) {
        var toDel:Array<DelayedF> = [];
		var toDel2:Array<ConditionalF> = [];
		var toDel3:Array<UpdateF> = [];
		for (delayedF in delayedFs) if (delayedF.tick(dt)) toDel.push(delayedF);
		for (condF in conditionalFs) if (condF.tick(dt)) toDel2.push(condF);
		for (updF in updateFs) if (updF.tick(dt)) toDel3.push(updF);
		for (f in toDel) delayedFs.remove(f);
		for (f in toDel2) conditionalFs.remove(f);
		for (f in toDel3) updateFs.remove(f);
    }

    /** `delayedThreads` functions gets updated here. **/
    public static function threadUpdate(dt:Float) {
        var toDel:Array<DelayedF> = [];
		for (v in delayedThreads) if (v.tick(dt)) toDel.push(v);
		for (v in toDel) delayedThreads.remove(v);
    }

    /**
     * Creates and adds a new `nb.Timer.DelayedF` instance.
     *
     * @param f The scheduled function. Will have this instance as argument.
     * @param t The time, in seconds, before the associated function gets executed.
     * @param once Whether the associated function is set to be executed only once.
     * If `false`, the function gets executed every `tStart` seconds.
     * @param frames If `true`, `t` is a number or frames, otherwise it's a time in seconds.
     * @return The `nb.Timer.DelayedF` instance created.
     **/
    public static function addDelayedF(f:DelayedF->Void, t:Float, once:Bool=true, frames:Bool=false, name:String=""):DelayedF {
        var v = new DelayedF(name,f,t,once,frames);
        delayedFs.push(v);
        return v;
    }
		
    /**
     * Creates and adds a new `nb.Timer.DelayedF` instance that is delayed by
     * enough time to ensure that it gets executed when the driver is ready.
     * 
     * @param f The scheduled function.
     * @param t The time, in seconds, before the associated function gets executed.
     * @param once Whether the associated function is set to be executed only once.
     * If `false`, the function gets executed every `tStart` seconds.
     * @param frames If `true`, `t` is a number or frames, otherwise it's a time in seconds.
     * @return The `nb.Timer.DelayedF` instance created.
     **/
	public static function addDelayedThread(f:DelayedF->Void, t:Float=1, once:Bool=true, frames:Bool=true, name:String=""):DelayedF {
        var v = new DelayedF(name,f,t,once,frames);
		delayedThreads.push(v);
        return v;
    }

    /**
     * Creates and adds a new `nb.Timer.ConditionalF` instance.
     *
     * @param f The scheduled function. Will have this instance as argument.
     * @param condition When this function returns `true`, `f` gets executed.
     * @param once Whether the associated function is set to be executed only once.
     * If `false`, the function gets executed every `tStart` seconds.
     * @param name A name to identify the instance.
     * @return The `nb.Timer.ConditionalF` instance created.
     **/
	public static function addConditionalF(f:ConditionalF->Void, condition:Void->Bool, once:Bool = true, name:String=""):ConditionalF {
        var v = new ConditionalF(name,f,condition,once);
		conditionalFs.push(v);
        return v;
    }

    /**
     * Creates and adds a new `nb.Timer.UpdateF` instance.
     *
     * @param f The scheduled function. Will have the instance as argument.
     * @param endCondition When this function returns `true`, `f` stops being executed.
     * @param name A name to identify the instance.
     * @return The `nb.Timer.UpdateF` instance created.
     **/
	public static function addUpdateF(f:UpdateF->Void, ?endCondition:Void->Bool, name:String=""):UpdateF {
		if (endCondition == null) endCondition = ()->false;
        var v = new UpdateF(name,f,endCondition);
		updateFs.push(v);
        return v;
	}
}