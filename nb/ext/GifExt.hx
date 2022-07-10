package nb.ext;

import haxe.io.Bytes;

/**
 * Contains data about a gif frame.
 * 
 * @since 0.1.0
 **/
@:allow(nb.ext.GifExt)
class FrameData {
    /** The x position of the image. **/
    public var x(default,null):Int;
    /** The y position of the image. **/
    public var y(default,null):Int;
    /** The width of the image. **/
    public var w(default,null):Int;
    /** The height of the image. **/
    public var h(default,null):Int;
    /** The pixel data of the image as bytes. **/ 
    public var bytes(default,null):Bytes;

    /**
     * Creates a new `FrameData` instance.
     *
     * @param x The x position of the image.
     * @param y The y position of the image.
     * @param w The width of the image.
     * @param h The height of the image.
     * @param bytes The pixel data of the image as bytes.
     **/
    private function new(x:Int, y:Int, w:Int, h:Int, bytes:Bytes) {
        this.x = x;
        this.y = y;
        this.w = w;
        this.h = h;
        this.bytes = bytes;
    }
} 

/**
 * An extension class for `format.gif.Data`.
 * 
 * @see https://haxe.org/manual/lf-static-extension.html
 * @since 0.1.0
 **/
class GifExt {

    /**
     * Returns an array containing datas of the frames in a `format.gif.Data`.
     * 
     * @param data A `format.gif.Data` instance.
     * @return An array containing frames datas, each being contained in an `nb.ext.GifExt.FrameData` instance.
     **/
    public static function getFrameDatas(data:format.gif.Data):Array<FrameData> {
        var res:Array<FrameData> = [];
        var aColorTable:Array<Bytes> = [];
        var t = haxe.Timer.stamp();
        for (block in data.blocks) if (block.getName() == "BFrame") {
            var frame:format.gif.Data.Frame = block.getParameters()[0];
            var colorTable = frame.localColorTable ? frame.colorTable : data.globalColorTable;
            var frameBytes = new haxe.io.BytesBuffer();
            var bi = new haxe.io.BytesInput(frame.pixels);

            var ct = new haxe.io.BytesInput(colorTable);
            var i:Int = 0;
            while (ct.position < ct.length) {
                var color = new haxe.io.BytesBuffer();
                color.add(ct.read(3));
                i++ == data.logicalScreenDescriptor.backgroundColorIndex ? color.addByte(0) : color.addByte(255);
                aColorTable.push(color.getBytes());
            }
            while (bi.position < bi.length) frameBytes.addBytes(aColorTable[bi.readInt8()],0,4);
            res.push(new FrameData(frame.x,frame.y,frame.width,frame.height,frameBytes.getBytes()));
        }

        return res;
    }
}