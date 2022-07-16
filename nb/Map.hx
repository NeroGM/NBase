package nb;

typedef TiledMap = {
    /** Hex-formatted color (#RRGGBB or #AARRGGBB) (optional) **/
    var backgroundcolor:String;
    /** The class of the map (since 1.9, optional) **/
    var _class:String;
    /** The compression level to use for tile layer data (defaults to -1, which means to use the algorithm default) **/
    var compressionlevel:Int;
    /** Number of tile rows **/
	var height:Int;
    /** Length of the side of a hex tile in pixels (hexagonal maps only) **/
    var hexsidelength:Int;
    /** Whether the map has infinite dimensions **/
    var infinite:Bool;
    /** Array of `TiledLayer`s **/
    var layers:Array<TiledLayer>;
    /** Auto-increments for each layer **/
    var nextlayerid:Int;
    /** Auto-increments for each placed object **/
    var nextobjectid:Int;
    /** `"orthogonal"`, `"isometric"`, `"staggered"` or `"hexagonal"` **/
    var orientation:String;
    /** X coordinate of the parallax origin in pixels (since 1.8, default: 0) **/
    var parallaxoriginx:Float;
    /** Y coordinate of the parallax origin in pixels (since 1.8, default: 0) **/
    var parallaxoriginy:Float;
    /** Array of `TiledProperty` **/
    var properties:Array<TiledProperty>;
    /** `"right-down"` (the default), `"right-up"`, `"left-down"` or `"left-up"` (currently only supported for orthogonal maps) **/
    var renderorder:String;
    /** `"x"` or `"y"` (staggered / hexagonal maps only) **/
    var staggeraxis:String;
    /** `"odd"` or `"even"` (staggered / hexagonal maps only) **/
    var staggerindex:String;
    /** The Tiled version used to save the file **/
    var tiledversion:String;
    /** Map grid height **/
    var tileheight:Int;
    /** Array of `TiledTileset` **/
    var tilesets:Array<TiledTileset>;
    /** Map grid width **/
    var tilewidth:Int;
    /** `map` (since 1.0) **/
    var type:String;
    /** The JSON format version (previously a number, saved as string since 1.6) **/
    var version:String;
    /** Number of tile columns **/
    var width:Int;
}

typedef TiledLayer = {
    /** Array of chunks (optional). `type == "tilelayer"` only. **/
    var chunks:Array<TiledChunk>;
    /** The class of the layer (since 1.9, optional) **/
    var _class:String;
    /** `"zlib"`, `"gzip"`, `"zstd"` (since Tiled 1.3) or empty (default). `type == "tilelayer"` only. **/
    var compression:String;
    /** Array of unsigned int (GIDs) or base64-encoded data(string). `type == "tilelayer"` only. **/
    var data:Dynamic;
    /** `"topdown"` (default) or `"index"`. `type == "objectgroup"` only. **/
    var draworder:String;
    /** `"csv"` (default) or `"base64"`. `type == "tilelayer"` only. **/
    var encoding:String;
    /** Row count. Same as map height for fixed-size maps. **/
    var height:Int;
    /** Incremental ID - unique across all layers **/
    var id:Int;
    /** Image used by this layer. `type == "imagelayer"` only. **/
    var image:String;
    /** Array of `TiledLayer`. `type == "group"` only. **/
    var layers:Array<TiledLayer>;
    /** Whether layer is locked in the editor (default: false). (since Tiled 1.8.2) **/
    var locked:Bool;
    /** Name assigned to this layer **/
    var name:String;
    /** Array of `TiledObject`. `type == "objectgroup"` only. **/
    var objects:Array<TiledObject>;
    /** Horizontal layer offset in pixels (default: 0) **/
    var offsetx:Float;
    /** Vertical layer offset in pixels (default: 0) **/
    var offsety:Float;
    /** Value between 0 and 1 **/
    var opacity:Float;
    /** Horizontal [parallax factor](https://doc.mapeditor.org/en/stable/manual/layers/#parallax-factor) for this layer (default: 1). (since Tiled 1.5) **/
    var parallaxx:Float;
    /** Vertical [parallax factor](https://doc.mapeditor.org/en/stable/manual/layers/#parallax-factor) for this layer (default: 1). (since Tiled 1.5) **/
    var parallaxy:Float;
    /** Array of Properties **/
    var properties:Array<TiledProperty>;
    /** Whether the image drawn by this layer is repeated along the X axis. `type == "imagelayer"` only. (since Tiled 1.8) **/
    var repeatx:Bool;
    /** Whether the image drawn by this layer is repeated along the Y axis. `type == "imagelayer"` only. (since Tiled 1.8) **/
    var repeaty:Bool;
    /** X coordinate where layer content starts (for infinite maps) **/
    var startx:Int;
    /** Y coordinate where layer content starts (for infinite maps) **/
    var starty:Int;
    /**
     * Hex-formatted tint color (#RRGGBB or #AARRGGBB) that is multiplied with any graphics
     * drawn by this layer or any child layers (optional).
     **/
    var tintcolor:String;
    /** Hex-formatted color (#RRGGBB) (optional). imagelayer only. **/
    var transparentcolor:String;
    /** `"tilelayer"`, `"objectgroup"`, `"imagelayer"` or `"group"` **/
    var type:String;
    /** Whether layer is shown or hidden in editor **/
    var visible:Bool;
    /** Column count. Same as map width for fixed-size maps. **/
    var width:Int;
    /** Horizontal layer offset in tiles. Always 0. **/
    var x:Int;
    /** Vertical layer offset in tiles. Always 0. **/
    var y:Int;
}

typedef TiledChunk = {
    /** Array of unsigned int (GIDs) or base64-encoded data **/
    var data:Array<String>;
    /** Height in tiles **/
    var height:Int;
    /** Width in tiles **/
    var width:Int;
    /** X coordinate in tiles **/
    var x:Int;
    /** Y coordinate in tiles **/
    var y:Int;
}

typedef TiledObject = {
    var _class:String;
    var ellipse:Bool;
    var gid:Int;
    var height:Float;
    var id:Int;
    var name:String;
    var point:Bool;
    var polygon:Array<TiledPoint>;
    var polyline:Array<TiledPoint>;
    var properties:Array<TiledProperty>;
    var rotation:Float;
    var template:String;
    var text:TiledText;
    var visible:Bool;
    var width:Float;
    var x:Float;
    var y:Float;
}

typedef TiledText = {
    var bold:Bool;
    var color:String;
    var fontfamily:String;
    var halign:String;
    var italic:Bool;
    var kerning:Bool;
    var pixelsize:Int;
    var strikeout:Bool;
    var text:String;
    var underline:Bool;
    var valign:String;
    var wrap:Bool;
}

typedef TiledTileset = {
    var backgroundcolor:String;
    var _class:String;
    var columns:Int;
    var fillmode:String;
    var firstgid:Int;
    var grid:TiledGrid;
    var image:String;
    var imageheight:Int;
    var imagewidth:Int;
    var margin:Int;
    var name:String;
    var objectalignment:String;
    var properties:Array<TiledProperty>;
    var source:String;
    var spacing:Int;
    var terrains:Array<TiledTerrain>;
    var tilecount:Int;
    var tiledversion:String;
    var tileheight:Int;
    var tileoffset:TiledTileOffset;
    var tilerendersize:String;
    var tiles:Array<TiledTile>;
    var tilewidth:Int;
    var transformations:TiledTransformations;
    var transparentcolor:String;
    var type:String;
    var version:String;
    var wangsets:Array<TiledWangSet>;
}

typedef TiledGrid = {
    var height:Int;
    var orientation:String;
    var width:Int;
}

typedef TiledTileOffset = {
    var x:Int;
    var y:Int;
}

typedef TiledTransformations = {
    var hflip:Bool;
    var vflip:Bool;
    var rotate:Bool;
    var preferuntransformed:Bool;
}

typedef TiledTile = {
    var animation:Array<TiledFrame>;
    var _class:String;
    var id:Int;
    var image:String;
    var imageheight:Int;
    var imagewidth:Int;
    var x:Int;
    var y:Int;
    var width:Int;
    var height:Int;
    var objectgroup:TiledLayer;
    var probability:Float;
    var properties:Array<TiledProperty>;
    var terrain:Array<TiledTerrain>;
}

typedef TiledFrame = {
    var duration:Int;
    var tileid:Int;
}

typedef TiledTerrain = {
    var name:String;
    var properties:Array<TiledProperty>;
    var tile:Array<Int>;
}

typedef TiledWangSet = {
    var _class:String;
    var colors:Array<TiledWangColor>;
    var name:String;
    var properties:Array<TiledProperty>;
    var tile:Int;
    var type:String;
    var wangtiles:Array<TiledWangTile>;
}

typedef TiledWangColor = {
    var _class:String;
    var color:String;
    var name:String;
    var probability:Float;
    var properties:Array<TiledProperty>;
    var tile:Int;
}

typedef TiledWangTile = {
    var tileid:Int;
    var wangid:Array<TiledWangColor>;
}

typedef TiledObjectTemplate = {
    var type:String;
    var tileset:TiledTileset;
    var object:TiledObject;
}

typedef TiledProperty = {
    var name:String;
    var type:String;
    var propertytype:String;
    var value:Dynamic;
}

typedef TiledPoint = {
    var x:Float;
    var y:Float;
}

class Map extends Object {
    public var tiledMap:TiledMap;
    public var tileGroups:Array<h2d.TileGroup> = [];
    public var atlas:Atlas = null;
    public var atlasTile:h2d.Tile = null;
	public function new(x:Float=0, y:Float=0, ?parent:nb.Object) {
        super(x,y,parent);

    }

    public function loadTiledMap(resource:hxd.res.Resource, singleTileGroup:Bool=true) {
		tiledMap = haxe.Json.parse(resource.entry.getText());
        var directory = resource.entry.directory+"/";
        var tilesets:Array<TiledTileset> = [for (tileset in tiledMap.tilesets) {
            if (tileset.source != null) {
                if (tileset.source.charAt(0) == ":") continue;
                var ts:TiledTileset = haxe.Json.parse(hxd.Res.load(directory+tileset.source).entry.getText());
                ts.firstgid = tileset.firstgid;
                ts;
            } else tileset;
        }];

        atlas = new Atlas();
        for (tileset in tilesets) atlas.addImage(hxd.Res.load(directory+tileset.image).toImage(),tileset.name,RGBA);
        atlas.make();
        atlasTile = atlas.toTile();

        var tg:h2d.TileGroup = null;
        if (singleTileGroup) {
            tg = new h2d.TileGroup(atlasTile);
            tileGroups.push(tg);
            addChild(tg);
        }
        
        for (layer in tiledMap.layers) {
            switch (layer.type) {
                case "tilelayer":
                    if (layer.data is Array == false) throw "Layer data isn't an Array.";

                    var layerData = cast(layer.data,Array<Dynamic>);
                    if (!singleTileGroup) {
                        tg = new h2d.TileGroup(atlasTile);
                        tileGroups.push(tg);
                        if (layer.visible) addChild(tg);
                    }

                    for (y in 0...tiledMap.height) for (x in 0...tiledMap.width) {
                        var data:Int = layerData[x + y * tiledMap.width];
                        if (data == 0) continue;

                        var fromTileset:TiledTileset = null;
                        for (tileset in tilesets) {
                            if (data >= tileset.firstgid && data < tileset.firstgid + tileset.tilecount) {
                                fromTileset = tileset;
                                break;
                            }
                        }
                        if (fromTileset == null) throw "Couldn't find associated tileset.";

                        var sd = atlas.getSubData(fromTileset.name);
                        var id:Int = (data-fromTileset.firstgid);
                        var cx:Int = Std.int(id%fromTileset.columns);
                        var cy:Int = Std.int(id/fromTileset.columns);
                        var xPos:Int = cx * fromTileset.tilewidth;
                        var yPos:Int = cy * fromTileset.tileheight;
                        var tile = atlasTile.sub(sd.x+xPos,sd.y+yPos,fromTileset.tilewidth,fromTileset.tileheight);
                        tg.add(x*tiledMap.tilewidth,y*tiledMap.tileheight,tile);
                    }
            }
        }
    }
}