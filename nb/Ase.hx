package nb;

/**
 * An aseprite class.
 * 
 * Primarily made to keep track of an `hxd.fs.FileEntry`.
 * @since 0.1.0
 **/
class Ase extends ase.Ase {
    /** The `hxd.fs.FileEntry` that was used to make this instance. **/
    public var entry(default,null):hxd.fs.FileEntry;

    /**
     * Returns an `nb.Ase` instance using an `hxd.fs.FileEntry`.
     * 
     * @param e The `hxd.fs.FileEntry` to make the instance with. (That you can get using `hxd.Res.[file].entry` for example.)
     * @return An instance of `ase.Ase` made from `e`.
     **/
    public static function fromEntry(e:hxd.fs.FileEntry):nb.Ase {
        var o = new Ase();
        o.entry = e;
        
        var bytes = e.getBytes();
        var bi = new haxe.io.BytesInput(bytes);
        o.header = ase.AseHeader.fromBytes(bi.read(ase.AseHeader.SIZE));
        for (_ in 0...o.header.frames) {
            var frameSize:Int = bytes.getInt32(bi.position);
            var frame = ase.Frame.fromBytes(bi.read(frameSize), o);
            o.frames.push(frame);
        }
        o.createLayers();

        return o;
    }
} 