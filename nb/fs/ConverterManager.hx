package nb.fs;

using nb.ext.ArrayExt;
import haxe.io.Bytes;

/**
 * Utility class to keep track of `nb.fs.Converter`s.
 *
 * Add converters to this class for them to be available globally via this class's
 * `converters`. You can do this in MacroInit.hx for them to be available in macro context.
 *
 * @since 0.1.0
 **/
class ConverterManager {
    /**
     * Contains all stored converters.
     * They are used by this class's convert functions when needed.
     **/
    public static var converters:Array<Converter> = [];

    /** Stores a converter in this class. **/
    public static function addConverter(c:Converter):Converter {
        converters.push(c);
        return c;
    }

    /**
     * Gets all converters from this class that can be used to do a given conversion.
     * 
     * @param fromType The converters should be able to convert from this type.
     * @param toType The converters should be able to convert to this type.
     * @param keywords If not `null`, the converters should have at least one of these keywords.
     * @return An array of converters that satisfies all the aforementioned conditions.
     **/
    public static function getConverters(fromType:String, ?toType:String, ?keywords:Array<String>):Array<Converter> {
        var a = converters.getAll((c) -> {
            var firstCheck = ((c.fromType[0] == "*" || c.fromType.contains(fromType)) && (toType == null || c.toType.contains(toType)));
            if (!firstCheck) return false;

            if (keywords == null) return true;
            if (c.keywords != null) for (k in keywords) if (c.keywords.contains(k)) return true;
            return false;
        });
        a.quickSort((c1,c2) -> c1.priority > c2.priority);

        return a;
    }

    /**
     * Converts data with a stored converter. 
     *
     * Throws an exception if no converter was found.
     *
     * @param bytes The data to convert as bytes.
     * @param fromType `bytes`' type.
     * @param toType The type to convert `bytes` to.
     * @param keywords If not `null`, the converter should have at least one of these keywords.
     * @return `bytes` converted.
     **/
    public static function convert(bytes:Bytes, fromType:String, toType:String, ?keywords:Array<String>):Bytes {
        var a = getConverters(fromType, toType, keywords);
        if (a.length == 0) { throw "Converter '"+fromType+"' to '"+toType+"' not found."; return bytes; }    
        return a[0].convert(bytes);
    }
}