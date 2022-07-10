package nb.ds;

/**
 * Contains a value (`data`) paired with a string (`name`).
 * 
 * @since 0.1.0
 **/
class NamedData<T> {
	/** An arbitrary value. **/
    public var data:T;
	/** A name for this instance. **/
	public var name:String;

	/** 
	 * Creates a new `NamedData<T>` instance. 
	 * 
	 * @param name A name for the instance.
	 * @param data An arbitrary value.
	 **/
	public function new(name:String, data:T) {
		this.data = data;
		this.name = name;
	}

	/** Returns a `String` representation of this instance in this format: `NamedData: [name]`. **/
	@:keep 
	public function toString():String return "NamedData: "+this.name;
}