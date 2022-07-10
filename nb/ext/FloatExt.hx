package nb.ext;

/**
 * An extension class for `Float`.
 * 
 * @see https://haxe.org/manual/lf-static-extension.html
 * @since 0.1.0
 **/
class FloatExt {
    /**
     * Checks equality between two numbers with a tolerance value.
     *
     * @param i1 First value.
     * @param i2 Second value.
     * @param epsilon Tolerance value.
     * @return `true` if there's an equality, `false` otherwise.
     **/
    public static inline function equals(i1:Float, i2:Float, epsilon:Float=0.00000000001):Bool {
        return (i1 >= (i2-epsilon) && i1 <= (i2+epsilon));
    }
}