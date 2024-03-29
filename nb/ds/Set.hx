package nb.ds;

import haxe.ds.Map;
import haxe.ds.StringMap;
import haxe.ds.IntMap;
import haxe.ds.ObjectMap;
import haxe.ds.EnumValueMap;

/**
 * Stores unique values without any particular order.
 *
 * @since 0.2.0
 **/
@:transitive
@:multiType
abstract Set<T>(Map<T,Bool>) {
    /** Creates a new `nb.ds.Set`, which is an abstract defined over an `haxe.ds.Map`. **/
    public function new();

    /**
     * Adds an item to the set.
     *
     * @param item The value to add.
     * @return `true` if it's a new value, `false` otherwise.
     **/
    public inline function add(item:T):Bool {
        if (this.exists(item)) return false;
        return this[item] = true;
	}

    public inline function remove(item:T):Bool {
        return this.remove(item);
    }

    @:arrayAccess public inline function get(key:T):Null<Bool> {
		return this.get(key);
    }

    @:arrayAccess public inline function set(key:T, value:Bool):Bool {
        return value ? add(key) : remove(key);
    }

    /** Returns an iterator over the values of this set. The order is undefined. **/
    public inline function iterator():Iterator<T> {
        return this.keys();
    }

    /** Returns the string representation of this set. **/
    public inline function toString():String {
        var s:String = "{";
        var it = iterator();
        for (v in it) {
            s += v;
            if (it.hasNext()) s += ",";
        }
        s += "}";
        return s;
    }

    /** Returns an array containing the values of this set. The order is undefined. **/
    public inline function toArray() {
        return [for (v in iterator()) v];
    }

    /** Removes all items in this set. **/
    public inline function clear() {
        this.clear();
    }

    @:to static inline function toStringMap<K:String, V>(t:Map<K, Bool>):StringMap<Bool> {
		return new StringMap<Bool>();
	}

	@:to static inline function toIntMap<K:Int, V>(t:Map<K, Bool>):IntMap<Bool> {
		return new IntMap<Bool>();
	}

	@:to static inline function toEnumValueMapMap<K:EnumValue, V>(t:Map<K, Bool>):EnumValueMap<K, Bool> {
		return new EnumValueMap<K, Bool>();
	}

	@:to static inline function toObjectMap<K:{}, V>(t:Map<K, Bool>):ObjectMap<K, Bool> {
		return new ObjectMap<K, Bool>();
	}
}