package nb;

using nb.ext.ArrayExt;

/** Contains tween types. **/
enum TweenType {
    LINEAR;
    POW(v:Float);
    INVPOW(v:Float);
    INSINE;
    OUTSINE;
    INCIRC;
    OUTCIRC;
    INBACK;
    OUTBACK;
    INELASTIC;
    OUTELASTIC;
    INBOUNCE;
    OUTBOUNCE;
    CUSTOM(f:Float->Float);
}

/**
 * Contains information about a tweening process.
 * 
 * @since 0.1.0
 **/
class TweenVar {
    /** The starting value. **/
    public var startV:Float;
    /** The destination value. **/
    public var to:Float;
    /** The total time the tweening operation will take. **/
    public var tMax:Float;
    /** The current value. **/
    public var v:Float;
    /** Time elpased, in seconds. **/
    public var realT:Float = 0;
    /** The t value, between 0 and 1. **/
    public var t:Float = 0;
    /** The difference between the starting value and the destination value, `to-startV`. **/
    private var diff:Float;

    /**
     * Creates an `nb.Tween.TweenVar` instance.
     * 
     * @param startV The starting value.
     * @param to The destination value.
     * @param tMax The tweening duration.
     **/
    public function new(startV:Float, to:Float, tMax:Float) {
        this.startV = this.v = startV;
        this.tMax = tMax;
        this.to = to;
        this.diff = to-startV;
    }

    /**
     * Calculates the next value.
     *
     * @param dt Time elapsed in seconds.
     * @return `true` if the tweening process ended, `false` otherwise.
     **/
    public function step(dt:Float):Bool {
        realT += dt;
        t = formula();
        if (realT > tMax) {
            t = 1;
            realT = tMax;
            v = to;
            onStep(v,realT,t,this);
            return true;
        }

        v = startV + diff*t;
        onStep(v,realT,t,this);
        return false;
    }

    /** Sets the current value to the destination value and ends the tweening process. **/
    public function end() {
        t = 1;
        realT = tMax;
        v = to;
        onStep(v,realT,t,this);
    }

    /** The function that is in charge of returning the t values. **/
    public dynamic function formula():Float return realT;  

    /** A function called at the end of every step. **/
    public dynamic function onStep(v:Float, realT:Float, t:Float, tVar:TweenVar) { };
}

/**
 * A tween class.
 *
 * @since 0.1.0
 **/
class Tween {
    /** Contains all current tween processes. **/
    public static var twVars:Array<TweenVar> = [];
    
    // Constant values
    private static inline var c1:Float = 1.70158;
    private static inline var c3:Float = c1 + 1;
    private static inline var c4:Float = (2 * 3.14151692654) / 3;
    private static inline var n1:Float = 7.5625;
    private static inline var d1:Float = 2.75;

    /**
     * Starts a tweening process.
     * 
     * @param from The value to tween from.
     * @param to The value to tween to.
     * @param duration The duration of the process, in seconds.
     * @param type The `nb.Tween.TweenType` of the process.
     * @param onStep A function that gets called at the end of each step.
     * The first argument is the current value, the second argument the time elapsed, the
     * the third argument the current t value, and the last argument the associated `nb.Tween.TweenVar`.
     * @return An `nb.Tween.TweenVar` instance.
     **/
    public static function start(from:Float, to:Float, duration:Float=1, type:TweenType=LINEAR, ?onStep:(Float,Float,Float,TweenVar)->Void):TweenVar {
        var tVar:TweenVar = new TweenVar(from,to,duration);
        tVar.onStep = onStep != null ? onStep : (_,_,_,_) -> {};
        twVars.push(tVar);
        
        tVar.formula = switch (type) {
            case POW(v): () -> pow(tVar.realT/tVar.tMax,v);
            case INVPOW(v): () -> invPow(tVar.realT/tVar.tMax,v);
            case INSINE: () -> inSine(tVar.realT/tVar.tMax);
            case OUTSINE: () -> outSine(tVar.realT/tVar.tMax);
            case INCIRC: () -> inCirc(tVar.realT/tVar.tMax);
            case OUTCIRC: () -> outCirc(tVar.realT/tVar.tMax);
            case INBACK: () -> inBack(tVar.realT/tVar.tMax);
            case OUTBACK: () -> outBack(tVar.realT/tVar.tMax);
            case INELASTIC: () -> inElastic(tVar.realT/tVar.tMax);
            case OUTELASTIC: () -> outElastic(tVar.realT/tVar.tMax);
            case INBOUNCE: () -> inBounce(tVar.realT/tVar.tMax);
            case OUTBOUNCE: () -> outBounce(tVar.realT/tVar.tMax);
            case CUSTOM(f): () -> f(tVar.realT/tVar.tMax);
            case LINEAR: () -> tVar.realT/tVar.tMax;
        }

        return tVar;
    }

    /**
     * Starts a single process tweening multiple values.
     *
     * Example: `startMultiple([10,50],[0,100,25])` will tween 10 to 0 and 50 to 100.
     * The 25 in the second array has no matching value in the first array so it is discarded. 
     * 
     * @param from The values to tween from.
     * @param to The values to tween to.
     * @param duration The duration of the process, in seconds.
     * @param type The `nb.Tween.TweenType` of the process.
     * @param onStep A function that gets called at the end of each step.
     * The first argument is the current values, the second argument the time elapsed, and
     * the third argument the current t value, and the last argument the associated `nb.Tween.TweenVar`.
     * @return An `nb.Tween.TweenVar` instance.
     **/
    public static function startMultiple(from:Array<Float>, to:Array<Float>, duration:Float=1, type:TweenType=LINEAR, ?onStep:(Array<Float>,Float,Float)->Void):TweenVar {
        var vals:Array<Float> = [];
        for (i in 0...Std.int(Math.min(from.length,to.length))) vals.push(to[i]-from[i]);

        var tw = start(0, 1, duration, type, (_,realT,t,_) -> {
            onStep([ for (i in 0...vals.length) from[i]+vals[i]*t ], realT, t);
        });

        return tw;
    }

    public static function update(dt:Float) {
        var toRemove:Array<TweenVar> = [];
        for (twVar in twVars) {
            if(twVar.step(dt)) toRemove.push(twVar);
        }
        twVars.removeValues(toRemove);
    }

    // Formulas
    @:dox(hide)
    public static function pow(t:Float,v:Float):Float return Math.pow(t,v);

    @:dox(hide)
    public static function invPow(t:Float,v):Float return 1 - Math.pow(1-t*t,v);

    @:dox(hide)
    public static function inSine(t:Float):Float return 1 - Math.cos((t * Math.PI) / 2);

    @:dox(hide)
    public static function outSine(t:Float):Float return Math.sin((t * Math.PI) / 2);

    @:dox(hide)
    public static function inCirc(t:Float):Float return 1 - Math.sqrt(1 - t*t);

    @:dox(hide)
    public static function outCirc(t:Float):Float return Math.sqrt(1-(t-1)*(t-1));

    @:dox(hide)
    public static function inBack(t:Float):Float {
        var tt = t*t;
        return c3*tt*t - c1*tt;
    }

    @:dox(hide)
    public static function outBack(t:Float):Float {
        var v = (t-1);
        var vv = v*v;
        return 1 + c3*v*vv + c1*vv;
    }

    @:dox(hide)
    public static function inElastic(t:Float):Float return t == 0 ? 0 : t == 1 ? 1 : -Math.pow(2, 10 * t - 10) * Math.sin((t * 10 - 10.75) * c4);
    
    @:dox(hide)
    public static function outElastic(t:Float):Float return t == 0 ? 0 : t == 1 ? 1 : Math.pow(2, -10 * t) * Math.sin((t * 10 - 0.75) * c4) + 1;

    @:dox(hide)
    public static function inBounce(t:Float):Float return 1-outBounce(t);

    @:dox(hide)
    public static function outBounce(t:Float):Float {
        if (t < 1 / d1) return n1 * t * t;
        else if (t < 2 / d1) return n1 * (t -= 1.5 / d1) * t + 0.75;
        else if (t < 2.5 / d1) return n1 * (t -= 2.25 / d1) * t + 0.9375;
        return n1 * (t -= 2.625 / d1) * t + 0.984375;
    }
}