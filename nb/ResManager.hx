package nb;

using nb.ext.ArrayExt;
import haxe.io.Bytes;
import h2d.Tile;
import h3d.mat.Texture;
import ase.Ase;
import nb.ds.MapArray;

@:dox(hide)
typedef FileListener = {name:String, f:hxd.fs.FileEntry->Void};

/**
 * A resource manager.
 *
 * @since 0.1.0
 **/
class ResManager {
    /** Contains stored `nb.Atlas` instances. **/
    public static final savedAtlases:MapArray<Atlas> = new MapArray();
    /** Contains stored `h3d.mat.Texture` instances. **/
    public static final savedTextures:MapArray<Texture> = new MapArray();
    /** Contains `FileListener`s. **/
    public static final fileListeners:Array<FileListener> = [];

    /** A white texture, or `null` if none had to be made by this class. **/
    private static var whiteTex:Texture = null;

    /** Initalizes this class. Should be called once, at the start of the app. **/
    public static function init(onFinished:Void->Void) {
        onFinished();
    }

    /**
     * Stores a texture under a unique name, the instance name is ignored.
     *
     * @param tex The `h3d.mat.Texture` to store.
     * @param name A unique name to give to the stored texture. If `null` the instance name is used.
     * @return The name `tex` is stored under.
     **/
    public static inline function addTexture(tex:Texture, ?name:String):String {
        if (name == null) name = tex.name;
        var n = name;
        var i:Int = 1;
        while (savedTextures[n] != null) { n = name+"_"+(i++); }
        if (i > 1) trace("There's already a texture stored under the name"+name+", changed name to "+n+".");

        savedTextures[n] = tex;
        return n;
    }

    /** Returns a stored texture with the unique name given. **/
    public static inline function getTextureByName(name:String):Texture {
        return savedTextures[name].data;
    }

    /** Returns a stored texture with matching id. **/
    public static inline function getTextureById(id:Int):Texture {
        for (t in savedTextures.values()) if (t.id == id) return t;
        return null;
    }

    /** Returns a part of a texture as a new texture or a cached texture.  **/
    public static inline function getTexturePart(tex:Texture, x:Float, y:Float, w:Float, h:Float):Texture { 
        var subTexName = tex.id+"_"+x+","+y+"_"+w+"x"+h;
        var subTex = ResManager.getTextureByName(subTexName);
        if (subTex == null) {
            var b = new h2d.col.IBounds();
            b.addPoint(new h2d.col.IPoint(Std.int(x),Std.int(y)));
            b.addPoint(new h2d.col.IPoint(Std.int(x+w),Std.int(y+h)));
            var sub = tex.capturePixels(0,0,b);
            subTex = h3d.mat.Texture.fromPixels(sub);
            addTexture(subTex, subTexName);
        }
        return subTex;
    }

    /**
     * Stores an `nb.Atlas` instance under a unique name, the instance name is ignored.
     * 
     * @param atlas The `nb.Atlas` instance to store.
     * @param name A unique name to give to the stored texture. If `null` the instance name is used.
     * @return The name `atlas` is stored under.
     **/
    public static inline function addAtlas(atlas:Atlas,?name:String):String {
        if (name == null) name = atlas.name;
        var n = name;
        var i:Int = 1;
        while (savedAtlases[n] != null) { n = name+"_"+(i++); }
        if (i > 1) trace("There's already an atlas stored under the name "+name+", changed name to "+n+".");

        savedAtlases[n] = atlas;
        return n;
    }

    /** Returns an `nb.Atlas` stored under that name.**/
    public static inline function getAtlasByName(name:String) {
        return savedAtlases[name] != null ? savedAtlases[name].data : null;
    }

    /** Returns a new white texture, or a cached one if one was already made by this class. **/
    public static inline function getWhiteTex():Texture {
        if (whiteTex == null) whiteTex = Texture.fromColor(0xFFFFFF);
        return whiteTex;
    }

    /** Returns a new white tile from this class's white texture. **/
    public static inline function getWhiteTile():h2d.Tile {
        return h2d.Tile.fromTexture(getWhiteTex());
    }

    /** Gets called when any file changes to trigger the file listeners. **/
    public static function onFileChanged(file:hxd.fs.FileEntry) {
        for (o in fileListeners) o.f(file);
    }
}