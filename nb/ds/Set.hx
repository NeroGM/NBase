package nb.ds;

import haxe.ds.Map;
import haxe.ds.StringMap;
import haxe.ds.IntMap;
import haxe.ds.ObjectMap;
import haxe.ds.EnumValueMap;

@:transitive
@:multiType
abstract Set<T>(Map<T,Bool>) {
    public function new();

    public inline function add(item:T):Bool {
        if (this.exists(item)) return false;
        return this[item] = true;
	}

    public inline function iterator():Iterator<T> {
        return this.keys();
    }

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

    public inline function toArray() {
        return [for (v in iterator()) v];
    }

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