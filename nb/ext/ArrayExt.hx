package nb.ext;

/**
 * An extension class for `Array`.
 * 
 * @see https://haxe.org/manual/lf-static-extension.html
 * @since 0.1.0
 **/
class ArrayExt {
    /**
     * An insertion sort algorithm, which is a fast algorithm for nearly sorted arrays.
     * 
     * Example: `[4,6,2,3,1].quicksort((a,b) -> a < b)` results in `[1,2,3,4,6]`.
     * 
     * @param a An array to be sorted.
     * @param condition A function where `condition(a,b)` returns `true` if `a < b`, `false` otherwise.
     **/
    public static function quickSort<T>(a:Array<T>, condition:(T,T)->Bool) {
        for (i in 1...a.length) {
            var e1 = a[i];
            var backBy:Int = 0;
            var index = i-(backBy+1);
            var e2 = a[index];
            while (condition(e1,e2)) {
                backBy++;
                index = i-(backBy+1); if (index < 0) break;
                e2 = a[index];
            }
            if (backBy > 0) {
                a.splice(i,1);
                a.insert(i-backBy, e1);
            }
        }
    }

    /** Returns the last value in an array. **/
    public static inline function last<T>(a:Array<T>):T {
        return a[a.length-1];
    }

    /**
     * Returns a value from an array at some position.
     * 
     * @param a An array.
     * @param i A position in the array. If `i` is negative or `i > a.length-1`, `i` will be wrapped.
     * @return A value in `a` at position `i`.
     **/
    public static function at<T>(a:Array<T>, i:Int):Null<T> {
        return a[i >= 0 ? i%a.length : a.length + i%a.length];
    }

    /**
     * Iterates through an array and returns the first value in the array where `f(value) == true`.
     * 
     * @param a The array to iterate through.
     * @param f A function which will take a value in the array as parameter.
     * @param asc `true` for ascendent iteration, `false` for descendent iteration.
     * @return A value where `f(value) == true`. You get `null` if there is no such value, or
     * if it is an actual value in the array.
     **/
    public static function getOne<T>(a:Array<T>, f:T->Bool, asc:Bool=true):Null<T> {
        if (asc) { for (o in a) if (f(o)) return o; }
        else for (i in 1...a.length+1) if (f(a[a.length-i])) return a[a.length-i];
        return null;
    }

    /**
     * Inserts a value in an array at a position where a condition is satisfied.
     * 
     * The value will be inserted at a position where for `x` being a value at that position, `f(x) == true`.
     * 
     * @param a The array to iterate through.
     * @param v A value to insert.
     * @param f A function which will take a value in the array as parameter.
     * @param asc `true` for ascendent iteration, `false` for descendent iteration.
     * @param force If `true` and there is no value in the array where `f(x) == true`, `v` is added to the array anyway.
     * The value will be added at the end if `asc == true`, otherwise it is added at the start.
     * @return `true` if the value was inserted, `false` otherwise.  
     **/
    public static function insertWhere<T>(a:Array<T>, v:T, f:T->Bool, asc:Bool=true, force:Bool=true):Bool {
        if (asc) for (i in 0...a.length) if (f(a[i])) { a.insert(i,v); return true; }
        else for (i in 1...a.length+1) if (f(a[a.length-i])) { a.insert(a.length-i,v); return true; }
        if (force) asc ? a.push(v) : a.insert(0,v);
        return false;
    }

    /**
     * Iterates through an array and returns all values in the array where `f(value) == true`.
     * 
     * @param a The array to iterate through.
     * @param f A function which will take a value in the array as parameter.
     * @return An array containing the values in `a` where `f(value) == true`.
     **/
    public static inline function getAll<T>(a:Array<T>, f:T->Bool):Array<T> {
        return [for (o in a) if (f(o)) o];
    }

    /**
     * Iterates through an array and removes the first value in the array where `f(value) == true`.
     * 
     * @param a The array to iterate through.
     * @param f A function which will take a value in the array as parameter.
     * @param asc `true` for ascendent iteration, `false` for descendent iteration.
     * @return The value that was removed, `null` if nothing was removed.
     **/
    public static function removeIf<T>(a:Array<T>, f:T->Bool, asc:Bool=true):T {
        if (asc) for (o in a) if (f(o)) { a.remove(o); return o; }
        else for (i in 1...a.length+1) if (f(a[a.length-i])) { var o = a[a.length-i]; a.remove(o); return o; }
        return null;
    }

    /**
     * Removes multiple values from an array.
     * 
     * Ex: `removeValues([a,b,a,b,a],[a,a]))` removes the value `a` twice from the first array, resulting to `[b,b,a]`.
     * 
     * @param a1 The array to remove values from.
     * @param a2 An array containing values to remove from `a1`.
     * @return `a1`.
     **/
    public static inline function removeValues<T>(a1:Array<T>, a2:Array<T>):Array<T> {
        for (v in a2) a1.remove(v);
        return a1;
    }
}