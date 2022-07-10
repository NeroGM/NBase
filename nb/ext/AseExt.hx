package nb.ext;

import haxe.io.Bytes;
import haxe.io.BytesBuffer;
import haxe.io.BytesInput;
import ase.Cel;

/**
 * The trimmed version of an `ase.Cel`. Contains data about the visible part of a cel of an aseprite.
 *
 * The trimmed version has all pixels that are outside the canvas discarded and an area reduced to visible pixels.
 * 
 * @since 0.1.0
 **/
@:allow(nb.ext.AseExt)
class CelVisibleData {
    /** The width of the visible area of the associated `ase.Cel`. **/
    public var w(default, null):Int;
    /** The trimmed height of `cel`. **/
    public var h(default, null):Int;
    /** The minimum x coordinate of `cel` after the trimming. **/
    public var xMin(default, null):Int;
    /** The maximum x coordinate of `cel` after the trimming. **/
    public var xMax(default, null):Int;
    /** The minimum y coordinate of `cel` after the trimming. **/
    public var yMin(default, null):Int;
    /** The maximum y coordinate of `cel` after the trimming. **/
    public var yMax(default, null):Int;
    /** The pixels data as bytes. **/
    public var pixelData(default, null):Bytes;
    /** The pixel format of `pixelData`. **/
    public var pixelDataFormat(default, null):hxd.PixelFormat;
    /** The associated `ase.Cel`. **/
    public var cel(default, null):Cel;

    /** Creates a new `CelVisibleData` instance. It will contain the same data passed as arguments. **/
    private function new(cel:Cel, w:Int, h:Int, xMin:Int, xMax:Int, yMin:Int, yMax:Int, pixelData:Bytes, pixelDataFormat:hxd.PixelFormat=hxd.PixelFormat.RGBA) {
        this.cel = cel;
        this.w = w;
        this.h = h;
        this.xMin = xMin;
        this.xMax = xMax;
        this.yMin = yMin;
        this.yMax = yMax;
        this.pixelData = pixelData;
        this.pixelDataFormat = pixelDataFormat;
    }
}

/**
 * An extension class for aseprite data.
 * 
 * @see https://haxe.org/manual/lf-static-extension.html
 * @since 0.1.0
 **/
class AseExt {
    /** 
     * Converts pixels data from a 16 bit grayscale color format to a 32 bit RGBA format then returns it.
     *
     * The grayscale format is defined as a format where for each 16 bit pixel 0xCCAA, CC is the grayscale value and AA the alpha value.
     * 
     * @param bytes An `haxe.io.Bytes` instance in a 16 bit grayscale color format.
     * @return A new `haxe.io.Bytes` instance in a 32 bit RGBA format.
     **/
    public static function greyscaleToRGBA(bytes:Bytes):Bytes {
        var input = new BytesInput(bytes);
        var convertedBytes = new BytesBuffer();
        for (_ in 0...Std.int(bytes.length/2)) {
            var color = input.read(1);
            var alpha = input.read(1);
            for (_ in 0...3) convertedBytes.add(color);
            convertedBytes.add(alpha);
        }
        return convertedBytes.getBytes();
    }

    /** 
     * Converts pixels data from an 8 bit indexed color format to a 32 bit RGBA format then returns it.
     *
     * The 8 bit indexed color format is defined as a format where each 8 bit value refers to a color in an aseprite color palette.
     * 
     * @param bytes An `haxe.io.Bytes` instance in an 8 bit indexed color format.
     * @param aseprite An `ase.Ase` instance to get the palette from.
     * @return A new `haxe.io.Bytes` instance in a 32 bit RGBA format.
     **/
    public static function indexedToRGBA(bytes:Bytes, aseprite:ase.Ase) {
        var input = new BytesInput(bytes);
        var convertedBytes = new BytesBuffer();
        var chunk = cast(aseprite.frames[0].chunks[1], ase.chunks.PaletteChunk);
        var palette = chunk.entries;
        for (i in 0...input.length) {
            var index = input.readInt8();
            var b = palette[index].toBytes();
            convertedBytes.addBytes(b,2,3);
            if (index == 0) convertedBytes.addByte(0);
            else convertedBytes.addBytes(b,5,1);
        }
        return convertedBytes.getBytes();
    }

    /** 
     * Converts pixels data from an unknown format to a 32 bit RGBA format then returns it.
     * 
     * The format is assumed to be the same as the pixel format of the `ase.Ase` instance given as a parameter. 
     * If the format is already a 32 bit RGBA format, no conversion is done and the same bytes given as a parameter will be returned.
     *
     * An error is thrown if it is an unknown the format.
     *
     * @param bytes An `haxe.io.Bytes` instance.
     * @param aseprite An `ase.Ase` instance to deduce `bytes` pixel format from.
     * @return A new `haxe.io.Bytes` instance in a 32 bit RGBA format if a conversion is done, `bytes` otherwise.
     **/
    public static function toRGBA(bytes:Bytes, aseprite:ase.Ase):Bytes {
        switch (aseprite.header.colorDepth) {
            case BPP32: return bytes;
            case BPP16: return greyscaleToRGBA(bytes);
            case INDEXED: return indexedToRGBA(bytes, aseprite);
            default:
                throw "Unsupported color depth : " + aseprite.header.colorDepth;
        }
        return bytes;
    }

    /**
     * Returns the trimmed version of an `ase.Cel`.
     * 
     * The trimmed version has all pixels that are outside the canvas discarded and an area reduced to visible pixels.
     * 
     * @param cel The `ase.Cel` for the trimmed version.
     * @param aseprite The `ase.Ase` associated with `cel`.
     * @return A trimmed version of `cel` as a `nb.ext.AseExt.CelVisibleData` instance.
     **/
    public static function getVisibleData(cel:ase.Cel,aseprite:ase.Ase):CelVisibleData {
        var data = toRGBA(cel.pixelData,aseprite);
        var bytesToRead:Int = 4;
        var xMin:Int = cel.xPosition;
        var xMax:Int = cel.xPosition+cel.width;
        var yMin:Int = cel.yPosition;
        var yMax:Int = cel.yPosition+cel.height;
        var dx1:Int = xMin < 0 ? -xMin : 0;
        var dx2:Int = xMax > aseprite.width ? xMax-aseprite.width : 0;
        var dy1:Int = yMin < 0 ? -yMin : 0;
        var dy2:Int = yMax > aseprite.height ? yMax-aseprite.height : 0;
        var w = xMax - xMin;
        var h = yMax - yMin;
        
        var foundFirstPixel:Bool = false;
        var foundPixelInLine:Bool = false;
        var x1:Int = dx1;
        var x2:Int = (w-dx2);
        var x3:Int = -1;
        var x4:Int = x2;
        // var nGets:Int = 0;
        var check = (col:Int, line:Int) -> {
            for (i in 0...bytesToRead) {
                var v = data.get((line*cel.width)*bytesToRead+col*bytesToRead+i);
                // nGets++;
                if (v != 0) {
                    foundPixelInLine = true;
                    if (!foundFirstPixel) {
                        foundFirstPixel = true;
                        yMin = cel.yPosition + line;
                        yMax = yMin+1;
                        xMin = cel.xPosition + col;
                        xMax = xMin+1;
                    }
                    if (cel.xPosition + col < xMin) {
                        xMin = cel.xPosition + col;
                    }
                    if (cel.xPosition + col+1 > xMax) {
                        xMax = cel.xPosition + col+1;
                    }
                    return true;
                }
            }
            return false;
        }
        for (line in dy1...h-dy2) {
            foundPixelInLine = false;
            for (col in x1...x2) {
                if (check(col,line)) {
                    x2 = col;
                    if (x3 == -1) x3 = col+1;
                    break;
                }
            }
            for (col in x3...x4) {
                if (check(col, line)) {
                    x3 = col+1;
                }
            }
            if (!foundPixelInLine) for (col in x2...x3) {
                check(col,line);
                if (foundPixelInLine) break;
            }
            if (foundPixelInLine) yMax = cel.yPosition + line+1;
        }

        w = xMax - xMin;    
        h = yMax - yMin;
        // trace("xMin:" + xMin + "  xMax:" + xMax + "  yMin:" + yMin + "  yMax:" + yMax + " w:" + w + " h:" + h);

        var buffer = new BytesBuffer();
        for (line in yMin-cel.yPosition...yMin-cel.yPosition+h)
            for (col in xMin-cel.xPosition...xMin-cel.xPosition+w)
                for (i in 0...4)
                    buffer.addByte(data.get((line*cel.width)*bytesToRead+col*bytesToRead+i));

        // trace(buffer.getBytes().length + "  " + nGets);
        return new CelVisibleData(cel,w,h,xMin,xMax,yMin,yMax,buffer.getBytes());
    }
}