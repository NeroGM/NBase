package nb.fs;

import haxe.io.Bytes;



/**
 * A converter.
 *
 * If you want to use it globally, you can use `nb.fs.ConverterManager`.
 *
 * @since 0.1.0
 **/
class Converter {
    /** Types that can be converted from. Setting `"*"` at index 0 means it can deal with any type. **/
    public var fromType:Array<String>;
    /** Types that can be converted to. **/
    public var toType:Array<String>;
    /** Strings used as parameters when doing conversion. **/
    public var keywords:Array<String>;
    /** The function that does the conversion. Has the bytes to be converted then `keywords` as arguments. **/
    public var f:(Bytes,Array<String>)->Bytes;
    /** It's priority level. Default is 0. **/
    public var priority:Int;

    /**
     * Creates a new `nb.fs.Converter` instance.
     * 
     * @param fromType Type to convert from.
     * @param toType Type to convert to.
     * @param f The function that does the conversion. Has the bytes to be converted then `keywords` as arguments.
     * @param keywords Strings used as parameters when doing conversion.
     * @param priority It's priority level. Default is 0.
     **/
    public function new(fromType:Array<String>, toType:Array<String>, f:(Bytes,Array<String>)->Bytes, ?keywords:Array<String>, priority:Int=0) {
        this.fromType = fromType;
        this.toType = toType;
        this.f = f;
        this.keywords = keywords;
        this.priority = priority;
    }

    /** Converts data without defining its type nor the resulting type. **/
    public function convert(bytes:Bytes):Bytes {
        return f(bytes,keywords);
    }
}