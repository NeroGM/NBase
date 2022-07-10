package nb;

using nb.ext.ArrayExt;
using nb.ext.AseExt;
import haxe.io.Bytes;
import hxd.PixelFormat;

/** 
 * Contains useful data of an image that is used by an `nb.Atlas`'s instance.
 * @since 0.1.0
 **/
@:allow(nb.Atlas)
class SubData {
    /** X position of the associated image in `atlas`'s texture. Determined only after a texture is made from `atlas`. **/
    public var x(default, set):Int = -1;
    /** Y position of the associated image in `atlas`'s texture. Determined only after a texture is made from `atlas`. **/
    public var y(default, set):Int = -1;
    /** Width of the associated image in `atlas`'s texture. Determined only after a texture is made from `atlas`. **/
    public var w(default, null):Int = -1;
    /** Height of the associated image in `atlas`'s texture. Determined only after a texture is made from `atlas`. **/
    public var h(default, null):Int = -1;

    /** Original bytes of the associated image. Same as the bytes after conversion from an `Atlas`'s `addX` function. **/
    public var bytes(default, null):Bytes;
    /** Pixel format of `bytes`. **/
    public var format(default, null):PixelFormat;
    /** 
     * The last converted bytes of the associated image needed by the last call of the `make` function of the `Atlas`. 
     * 
     * Resets to `null` if the last call didn't need to convert `bytes`.
     **/
    public var convertedBytes(default, null):Bytes = null;
    /** Pixel format of `convertedBytes`. **/
    public var convertedFormat(default, null):PixelFormat = null;

    /** X Offset of the associated image from the left border of the aseprite canvas. **/
    public var dx(default, null):Int = 0;
    /** Y Offset of the associated image from the left border of the aseprite canvas. **/
    public var dy(default, null):Int = 0;
    /** ID of the layer in aseprite of the associated image. **/
    public var layerId(default, null):Int = 0;
    /** ID of the frame in aseprite of the associated image. **/
    public var frameId(default, null):Int = 0;
    /** `SubData` this instance was cloned from. **/
    public var clonedFrom(default, null):SubData = null;
    public var linked:Array<SubData> = [];

    /** The name of this instance. **/
    public var name(default, null):String;
    /** The associated `Atlas` instance. **/
    public var atlas:Atlas;
    /** FileEntry used to create this instance. **/
    public var entry(default, null):hxd.fs.FileEntry;
    /** Number of the next line to be read for `readLine()`. **/
    private var atLine(default, null):Int = 0;

    /**
     * The private constructor. Accessible from an `Atlas` class.
     * 
     * @param bytes Bytes of the associated image.
     * @param format Pixel format of the associated image.
     * @param w Width of the associated image.
     * @param h Height of the associated image.
     * @param name A name for this instance.
     * @param atlas `Atlas` instance this instance was created from.
     **/
    @:dox(show)
    private function new(bytes:Bytes, format:PixelFormat, w:Int, h:Int, name:String, atlas:Atlas) {
        this.bytes = bytes;
        this.w = w;
        this.h = h;
        this.format = format;
        this.name = name;
        this.atlas = atlas;
    }

    function set_x(v) {
        for (sd in linked) sd.x = v;
        return x = v;
    }

    function set_y(v) {
        for (sd in linked) sd.y = v;
        return y = v;
    }

    /** 
     * Sets `convertedBytes` with the value of `bytes` converted, or `null` if `bytes` doesn't need to be converted.
     * 
     * @param toFormat The format to convert `bytes` to.
     **/
    public function convertTo(toFormat:PixelFormat) {
        if (format == toFormat) {
            convertedBytes = null;
            convertedFormat = null;
        } else if (convertedFormat != format) {
            var px = new hxd.Pixels(w,h,bytes,format);
            px.convert(format);
            convertedBytes = px.bytes;
            convertedFormat = toFormat;
        }
    }

    /** 
     * Returns the bytes of the next line to be read with the right format to make the texture with.
     * 
     * Example : Reading line 0 of a 5x8 image returns the bytes of the 5 pixels in the first line of the image.
     **/
    private function readLine():Bytes {
        var buffer = new haxe.io.BytesBuffer();
        var bytes = getBytes();
        buffer.addBytes(getBytes(),atLine*w*4,w*4);
        if (++atLine >= h) atLine = 0;
        return buffer.getBytes();
    }

    /**
     * Returns a copy of this instance. `clonedFrom` of the new instance is set to this instance.
     * 
     * @param name Name of the new instance.
     **/
    private function clone(name:String):SubData {
        var newSd = new SubData(bytes,format,w,h,name,atlas);
        newSd.x = x;
        newSd.y = y;
        newSd.dx = dx;
        newSd.dy = dy;
        newSd.layerId = layerId;
        newSd.frameId = frameId;
        newSd.entry = entry;
        newSd.bytes = bytes;
        newSd.convertedBytes = convertedBytes;
        newSd.convertedFormat = convertedFormat;
        newSd.clonedFrom = this;
        linked.push(newSd);
        return newSd;
    }

    /** Returns `bytes`, or `convertedBytes` if the latest is not set to `null`. **/
    private inline function getBytes():Bytes return convertedBytes == null ? bytes : convertedBytes;

    /** Returns a string representation containing the name of this instance and the `Atlas` instance's area associated with it. **/
    public function toString():String {
        return name + "("+x+","+y+")("+w+","+h+")";
    }
}

/**
 * Multiple images data container that can be packed into a single texture. Use it to avoid the usage of multiple textures.
 * 
 * Give it datas using the appropriate `addX` functions then use the `make` function to generate the texture.
 * 
 * All the useful datas of an image are contained in `SubData` instances.
 * @since 0.1.0
 **/
class Atlas {
    /** The `SubData`s used to generate the texture. **/
    public var subDatas(default,null):Array<SubData> = [];
    /** Bytes of the generated texture. **/
    public var bytes(default,null):Bytes = null;
    /** Width of the generated texture. **/
    public var width(default,null):Int = 0;
    /** Height of the generated texture. **/
    public var height(default,null):Int = 0;
    /** The `hxd.Pixels` generated to make the texture. **/
    public var pixels(default,null):hxd.Pixels = null;
    /** The generated texture. **/
    public var texture(default,null):h3d.mat.Texture = null;
    /** If `true`, old texture will be disposed when a new one is generated. **/
    public var preventTextureAutoDispose:Bool = false;
    /** If `true`, the next texture generated will have its width and height be a power of two. This is good for GPUs. **/
    public var makePOT:Bool = true;
    /** When `false`, this instance is prevented from doing anything when a file changes. **/
    public var remakeAtlasOnFileChange:Bool = true;
    // ! COMMENT
    public var listeningObjects:Array<{o:h2d.Object,onHotReload:Void->Void}> = [];

    /** The name of this instance. Can be locked when created for internal usage. **/
    public var name(default, set):String = "";
    /** `true` if `name` is locked. **/
    private var nameLocked:Bool = false;
    /** A copy of the last `width` parameter passed to the `make` function. **/
    private var savedMaxW:Int = 2048;
    /** A copy of the last `height` parameter passed to the `make` function. **/
    private var savedMaxH:Int = 2048;

    /** 
     * Creates an `Atlas` instance.
     * 
     * In debug mode, the instance will be aware of any file change.
     * By default, if a file associated with the instance changes, the instance will update itself and call its `onHotReload` function.
     **/
    public function new() {
        #if debug
        ResManager.fileListeners.push({name:"atlas",f:(file)->{
            #if (sys && target.threaded) nb.Timer.addDelayedThread((_) -> { #end
            updateAtlas(file);
            #if (sys && target.threaded) }); #end
        }});
        #end
    }

    /**
     * Retrieve datas from an `hxd.Pixels`'s instance and returns the `SubData` instance made from it.
     * 
     * @param pixels The `hxd.Pixels` instance to make the `SubData` instance from.
     * @param name The name to assign to the `SubData` instance.
     * @param toFormat The pixel format to convert the bytes of `pixels` to before using it to make the `SubData` instance.
     * @return The `SubData` instance made.
     **/
    public function addPixels(pixels:hxd.Pixels, name:String, ?toFormat:PixelFormat):SubData {
        if (toFormat != null && pixels.format != toFormat) pixels.convert(toFormat);
        var sd = new SubData(pixels.bytes,pixels.format,pixels.width,pixels.height,name,this);
        subDatas.push(sd);
        return sd;
    }

    /**
     * Retrieve datas from an `hxd.Res.Image`'s instance and returns the `SubData` instance made from it.
     * 
     * @param image The `hxd.Res.Image` instance to make the `SubData` instance from.
     * @param name A name to assign to the `SubData` instance. Defaults to `image`'s name.
     * @param toFormat The pixel format to convert the bytes of `image` to before using it to make the `SubData` instance.
     * @param flipY Set to `true` if `image` needs to be flipped vertically.
     * @param index Index used to read image data from a Dds file.
     * @return The `SubData` instance made.
     **/
    public function addImage(image:hxd.res.Image, ?name:String, ?toFormat:PixelFormat, ?flipY:Bool, ?index:Int):SubData {
        if (name == null) name = image.name;
        var sd = addPixels(image.getPixels(toFormat,flipY,index),name);
        sd.entry = image.entry;
        return sd;
    }

    /**
     * Retrieve datas from an `nb.Ase`'s instance and returns the `SubData` instance(s) made from it.
     * 
     * @param aseprite The `nb.Ase` instance to make the `SubData` instance(s) from.
     * @param name A `string` used to make the `SubData` instance(s) name from. A `SubData` instance's name will have a name in this format : `[name]_[frame]:[layer]`.
     * @param toFormat The pixel format to convert the bytes of `aseprite` to before using it to make the `SubData` instance(s).
     * @return An array of the `SubData` instance(s) made.
     **/
    public function addAseprite(aseprite:nb.Ase, ?name:String, toFormat:PixelFormat=RGBA):Array<SubData> {
        if (name == null) name = aseprite.entry.name;

        var a:Array<SubData> = [];
        var notLinkedSds:Array<SubData> = [];
        var linkerSds:Array<SubData> = [];
        for (i in 0...aseprite.frames.length) for (cel in aseprite.frames[i].cels) if (aseprite.layers[cel.layerIndex].visible) {
            if (cel.chunk.celType == ase.types.CelType.Linked) {
                var linkedSd = linkerSds.getOne((sd) -> sd.frameId == cel.chunk.linkedFrame && sd.layerId == cel.layerIndex);
                if (linkedSd == null) {
                    linkedSd = notLinkedSds.getOne((sd) -> sd.frameId == cel.chunk.linkedFrame && sd.layerId == cel.layerIndex);
                    if (linkedSd != null) linkerSds.push(linkedSd);
                }
                
                if (linkedSd != null) {
                    var sd:SubData = linkedSd.clone((name+"_"+i+":"+cel.layerIndex));
                    sd.frameId = i;
                    subDatas.push(sd);
                    a.push(sd);
                    continue;
                }
            }

            var celData:CelVisibleData = cel.getVisibleData(aseprite);
            var data = celData.pixelData;
            var sd:SubData = null;
            if (toFormat != RGBA) {
                var pixels = new hxd.Pixels(celData.w,celData.h,data,RGBA);
                pixels.convert(toFormat);
                sd = new SubData(pixels.bytes,pixels.format,pixels.width,pixels.height,(name+"_"+i+":"+cel.layerIndex),this);
                
            } else sd = new SubData(data,RGBA,celData.w,celData.h,(name+"_"+i+":"+cel.layerIndex),this);

            sd.dx = celData.xMin;
            sd.dy = celData.yMin;
            sd.layerId = cel.layerIndex;
            sd.frameId = i;
            sd.entry = aseprite.entry;
            subDatas.push(sd);
            a.push(sd);
            notLinkedSds.push(sd);
        }
        return a;
    }

    /**
     * Makes a `SubData` instance from the parameters and returns it.
     * 
     * @param bytes `haxe.io.Bytes` of the image to make the `SubData` instance with.
     * @param w Width of the image.
     * @param h Height of the image.
     * @param name A name to assign to the `SubData` instance.
     * @param format Pixel format of `bytes`.
     * @param toFormat Pixel format to convert `bytes` to before using it to make the `SubData` instance.
     * @return The `SubData` instance made.
     **/
    public inline function addBytes(bytes:Bytes, w:Int, h:Int, name:String, format:PixelFormat=PixelFormat.RGBA, ?toFormat:PixelFormat):SubData {
        if (toFormat != null && format != toFormat) return addPixels(new hxd.Pixels(w,h,bytes,format),name,toFormat);
        var sd = new SubData(bytes,format,w,h,name,this);
        subDatas.push(sd);
        return sd;
    }

    /** Makes a new `h2d.Tile` instance from the generated texture then returns it. **/
    public inline function toTile():h2d.Tile {
        return texture != null ? h2d.Tile.fromTexture(texture) : null;
    }

    /**
     * Generates a texture using the `SubData` instances.
     * 
     * @param maxW Max width of the generated texture. If not a power of two and `makePOT` is true, the max width will be the power of two just after `maxW`.
     * @param maxH Max height of the generated texture. If not a power of two and `makePOT` is true, the max height will be the power of two just after `maxH`.
     * @param format Desired pixel format of `pixels` and the generated texture.
     **/
    public function make(maxW:Int=2048, maxH:Int=2048, format:PixelFormat=PixelFormat.RGBA) {
        if (subDatas.length == 0) return;
        if (maxW <= 0 || maxH <= 0) throw "Incorrect size.";
        savedMaxW = maxW;
        savedMaxH = maxH;
        
        var notStarted:Array<SubData> = [for (sd in subDatas) if (sd.clonedFrom == null) sd];
        var drawing:Array<SubData> = [];
        var done:Array<SubData> = [];
        for (sd in notStarted) sd.convertTo(format);

        notStarted.quickSort((a,b) -> a.w+a.h > b.w+b.h);
        var x:Int = 0;
        var y:Int = 0;
        var aBytes = new haxe.io.BytesBuffer();
        var bytesToRead:Int = format == RGB8 ? 1 : 4;

        var drawLine = (sd:SubData) -> {
            var b = sd.readLine();
            aBytes.add(b);
            x += sd.w;
            if (x == maxW) { x = 0; y += 1; }
            if (sd.atLine == 0) {
                drawing.remove(sd);
                done.push(sd);
            }
        };
    
        while (1 == 1) {
            var nextSd:SubData = drawing.getOne((o) -> o.x == x);
            if (nextSd != null) {
                drawLine(nextSd);
                continue;
            }
            
            var sdAhead:SubData = drawing.getOne((o) -> o.x > x);
            
            if (notStarted.length > 0) {
                var maxWidth:Int = sdAhead == null ? maxW - x : sdAhead.x - x;
                
                nextSd = notStarted.getOne((o) -> o.w <= maxWidth);
                if (nextSd != null) {
                    notStarted.remove(nextSd);
                    nextSd.x = x;
                    nextSd.y = y;
                    drawing.insertWhere(nextSd, (o) -> nextSd.x < o.x);
                    drawing.quickSort((a,b) -> a.x < b.x);
                    drawLine(nextSd);
                    continue;
                }
            }
            if (sdAhead != null) {
                for (_ in 0...(sdAhead.x - x)*bytesToRead) aBytes.addByte(0xFF);
                x = sdAhead.x;
                drawLine(sdAhead);
                continue;
            }

            if (maxW-x > 0) {
                if (makePOT) {
                    if (y == 0) {
                        maxW = getPowerOf2(x);
                        if (maxW > savedMaxW) maxW = savedMaxW;
                    }
                    for (_ in 0...(maxW-x)*bytesToRead) aBytes.addByte(0xFF);
                } else if (y == 0) maxW = x;
            }
            
            x = 0;
            y += 1;
            if (y <= maxH && (drawing.length > 0 || notStarted.length > 0)) continue;
            if (y > maxH) { trace("[ERROR] Atlas texture maxSize reached. Atlas name:'"+name+"' maxSize:"+maxW+"x"+maxH); y--; break; }
            if (makePOT && !powerOf2s.contains(y)) {
                var lines = getPowerOf2(y)-y;
                for (_ in 0...(maxW*lines)*bytesToRead) aBytes.addByte(0xFF);
                y += lines;
            }

            break;
        }

        if (texture != null && !preventTextureAutoDispose) texture.dispose();

        bytes = aBytes.getBytes();
        width = y > 0 ? maxW : x;
        height = y;
        pixels = new hxd.Pixels(width,height,bytes,format);
        
        texture = h3d.mat.Texture.fromPixels(pixels);
        texture.preventAutoDispose();
    }

    /** Same as `make()` but uses the last parameters that were given to it. **/
    inline public function remake() make(savedMaxW,savedMaxH,texture.format);

    /** If `changedEntry` is associated to a `SubData` in this atlas, hot reloads. **/
    private function updateAtlas(changedEntry:hxd.fs.FileEntry) {
        if (!remakeAtlasOnFileChange) return;

        var toRemove:Array<SubData> = [];
        var toAdd:Array<hxd.fs.FileEntry> = [];
        for (sd in subDatas) if (sd.entry == changedEntry) {
            toRemove.push(sd);
            if (!toAdd.contains(changedEntry)) toAdd.push(changedEntry);
        }
        for (sd in toRemove) subDatas.remove(sd);
        for (e in toAdd) {
            if (e.extension == "aseprite" || e.extension == "ase") {
                addAseprite(nb.Ase.fromEntry(e),e.name,null);
            } else {
                addImage(cast(e, hxd.res.Image));
            }
        }
        if (toAdd.length > 0) { remake(); onHotReload(); }
    }

    /** Returns a `SubData` instance with the same name. **/
    public function getSubData(name:String):SubData {
        return subDatas.getOne((o) -> o.name == name);
    }

    /** Removes a `SubData` instance from the collection with the same name. Returns `true` if one was removed, `false` otherwise. **/
    public function removeSubData(name:String):Bool {
        return subDatas.removeIf((o) -> o.name == name) != null;
    }

    private function set_name(s:String) {
        return name = nameLocked ? name : s;
    }

    /** 
    * Called after a new texture was generated from file change.
    *
    * Calls the `onHotReload` function of all objects in `listeningObjects`.
    **/
    public function onHotReload() {
        for (o in listeningObjects) o.onHotReload();
    }

    private static final powerOf2s = [1,2,4,8,16,32,64,128,256,512,1024,2048,4096,8192,16384,32768];

    /** Gets the next power of two bigger than `v`. **/ 
    private function getPowerOf2(v:Int):Int {
        for (i in powerOf2s) if (i > v) return i;
        return -1;
    }

    /** Returns a string representation of this instance. **/
    private function toString() return "Atlas('"+name+"')";
}