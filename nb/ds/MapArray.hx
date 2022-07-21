package nb.ds;

using nb.ext.ArrayExt;

/**
 * A data structure made to have the features of an Array and a Map using an array of `nb.fs.NamedData<T>`.
 *
 * Warning : It is possible to have values with the same key.
 * When that happens, get and set functions will refer to the value at the lowest position in the array. 
 *
 * @since 0.1.0
 **/
@:forward(length,push,pop,iterator,toString,contains,remove,copy)
abstract MapArray<T>(Array<NamedData<T>>) {
	/**
	 * Creates a new `MapArray` instance.
	 * 
	 * @param a Assigns this value at creation instead of an empty array.
	 **/
	public function new(?a:Array<NamedData<T>>) {
		if (a == null) a = [];
		this = a;
	}

	/**
	 * Returns the mapping of `key`.
	 * 
	 * @param key A key, which is also the `name` of a `NamedData<T>`.
	 * @return The `NamedData<T>` mapped to `key` if one is found, `null` otherwise.
	 **/
	@:arrayAccess public inline function get(key:String):Null<NamedData<T>> {
		return this.getOne((nd) -> nd.name == key);
	}

	/** Returns the `NamedData<T>` in this instance at position `i`. **/
	@:arrayAccess public inline function getFromIndex(i:Int):Null<NamedData<T>> {
		return this[i];
	}

	/**
	 * Maps `key` to a `NamedData<T>` containing `value`.
	 * 
	 * Creates a new `NamedData<T>` if there isn't already one associated with the key.
	 * 
	 * @param key A key, which is also the `name` of a `NamedData<T>`.
	 * @param value A value, which will be stored in `data` of a `NamedData<T>`.
	 * @return The `NamedData<T>` mapped to `key`.
	 **/
	@:arrayAccess public function setString(key:String, value:T):T {
		var namedData = this.getOne((o) -> o.name == key);
		if (namedData == null) {
			namedData = new NamedData<T>(key, value);
			this.push(namedData);
		}
		return namedData.data = value;
	}

	/**
	 * Unmaps the `NamedData<T>` mapped to `oldKey` and maps it to `newKey`. `newKey` shouldn't be already mapped.
	 * 
	 * @param oldKey A mapped key that will be unmapped.
	 * @param newKey An unmapped key to map to.
	 * @return The `NamedData<T>` that had its mapping changed, `null` if `oldKey` wasn't mapped.
	 **/
	public function changeKey(oldKey:String, newKey:String):Null<NamedData<T>> {
		if (this.getOne((o) -> o.name == newKey) != null) throw newKey + " is already mapped.";

		var namedData = this.getOne((o) -> o.name == oldKey);
		if (namedData == null) return null;
		namedData.name = newKey;
		return namedData;
	}

    /** Returns `true` if `key` is mapped, `false` otherwise. **/
    public inline function exists(key:String):Bool {
        return this.getOne((o) -> o.name == key) != null;
    }

    /** Returns an iterator over the keys of this instance. **/
    public inline function keys():MapArrayKIterator<T> {
        return new MapArrayKIterator(new MapArray(this));
    }

    /** Returns an iterator over the data contained within the `NamedData<T>`s of this instance. **/
    public inline function values():MapArrayVIterator<T> {
        return new MapArrayVIterator(new MapArray(this));
    }

	/** Returns an iterator over the keys of this instance and the data contained within the `NamedData<T>` mapped to it. **/
	public inline function keyValueIterator():MapArrayKVIterator<T> {
		return new MapArrayKVIterator(new MapArray(this));
	}
}

@:dox(hide)
class MapArrayKIterator<T> {
    var nextIndex:Int = 0;
	var ma:MapArray<T>;

	public inline function new(ma:MapArray<T>) {
		this.ma = ma;
	}

	public inline function hasNext():Bool {
		return nextIndex < ma.length;
	}

	public inline function next():String {
		var address = ma[nextIndex++];
		return address.name;
	}
}

@:dox(hide)
class MapArrayVIterator<T> {
    var nextIndex:Int = 0;
	var aLength:Int = 0;
	var ma:MapArray<T>;

	public inline function new(ma:MapArray<T>) {
		this.ma = ma;
	}

	public inline function hasNext():Bool {
		return nextIndex < ma.length;
	}

	public inline function next():T {
		var address = ma[nextIndex++];
		return address.data;
	}
}

@:dox(hide)
class MapArrayKVIterator<T> {
	var nextIndex:Int = 0;
	var ma:MapArray<T>;

	public inline function new(ma:MapArray<T>) {
		this.ma = ma;
	}

	public inline function hasNext():Bool {
		return nextIndex < ma.length;
	}

	public inline function next():{key:String, value:T} {
		var address = ma[nextIndex++];
		return {key:address.name,value:address.data};
	}
}