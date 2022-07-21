package nb;

typedef TiledMap = {
    /** Hex-formatted color (`"#RRGGBB"` or `"#AARRGGBB"`) (optional) **/
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
     * Hex-formatted tint color (`"#RRGGBB"` or `"#AARRGGBB"`) that is multiplied with any graphics
     * drawn by this layer or any child layers (optional).
     **/
    var tintcolor:String;
    /** Hex-formatted color (`"#RRGGBB"`) (optional). imagelayer only. **/
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
    var data:Dynamic;
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
    /** The class of the object (renamed from `type` since 1.9, optional) **/
    var _class:String;
    /** Used to mark an object as an ellipse **/
    var ellipse:Bool;
    /** Global tile ID, only if object represents a tile **/
    var gid:Int;
    /** Height in pixels. **/
    var height:Float;
    /** Incremental ID, unique across all objects **/
    var id:Int;
    /** String assigned to name field in editor **/
    var name:String;
    /** Used to mark an object as a point **/
    var point:Bool;
    /** Array of `TiledPoint`, in case the object is a polygon **/
    var polygon:Array<TiledPoint>;
    /** Array of `TiledPoint`, in case the object is a polyline **/
    var polyline:Array<TiledPoint>;
    /** Array of `TiledProperty` **/
    var properties:Array<TiledProperty>;
    /** Angle in degrees clockwise **/
    var rotation:Float;
    /**
     * Reference to a template file, in case object is a
     * [template instance](https://doc.mapeditor.org/en/stable/manual/using-templates/)
     **/
    var template:String;
    /** Only used for text objects **/
    var text:TiledText;
    /** Whether object is shown in editor. **/
    var visible:Bool;
    /** Width in pixels. **/
    var width:Float;
    /** X coordinate in pixels **/
    var x:Float;
    /** Y coordinate in pixels **/
    var y:Float;
}

typedef TiledText = {
    /** Whether to use a bold font (default: `false`) **/
    var bold:Bool;
    /** Hex-formatted color (`"#RRGGBB"` or `"#AARRGGBB"`) (default: `"#000000"`) **/
    var color:String;
    /** Font family (default: `sans-serif`) **/
    var fontfamily:String;
    /** Horizontal alignment (`"center"`, `"right"`, `"justify"` or `"left"` (default)) **/
    var halign:String;
    /** Whether to use an italic font (default: `false`) **/
    var italic:Bool;
    /** Whether to use kerning when placing characters (default: `true`) **/
    var kerning:Bool;
    /** Pixel size of font (default: `16`) **/
    var pixelsize:Int;
    /** Whether to strike out the text (default: `false`) **/
    var strikeout:Bool;
    /** Text **/
    var text:String;
    /** Whether to underline the text (default: `false`) **/
    var underline:Bool;
    /** Vertical alignment (`"center"`, `"bottom"` or `"top"` (default)) **/
    var valign:String;
    /** Whether the text is wrapped within the object bounds (default: `false`) **/
    var wrap:Bool;
}

typedef TiledTileset = {
    /** Hex-formatted color (`"#RRGGBB"` or `"#AARRGGBB"`) (optional) **/
    var backgroundcolor:String;
    /** The class of the tileset (since 1.9, optional) **/
    var _class:String;
    /** The number of tile columns in the tileset **/
    var columns:Int;
    /**
     * The fill mode to use when rendering tiles from this tileset
     * (`"stretch"` (default) or `"preserve-aspect-fit"`) (since 1.9)
     **/
    var fillmode:String;
    /** GID corresponding to the first tile in the set **/
    var firstgid:Int;
    /** (optional) **/
    var grid:TiledGrid;
    /** Image used for tiles in this set **/
    var image:String;
    /** Height of source image in pixels **/
    var imageheight:Int;
    /** Width of source image in pixels **/
    var imagewidth:Int;
    /** Buffer between image edge and first tile (pixels) **/
    var margin:Int;
    /** Name given to this tileset **/
    var name:String;
    /**
     * Alignment to use for tile objects (`"unspecified"` (default), `"topleft"`, `"top"`, 
     * `"topright"`, `"left"`, `"center"`, `"right"`, `"bottomleft"`, `"bottom"` or `"bottomright"`) (since 1.4)
     **/
    var objectalignment:String;
    /** Array of `TiledProperty` **/
    var properties:Array<TiledProperty>;
    /** The external file that contains this tilesets data **/
    var source:String;
    /** Spacing between adjacent tiles in image (pixels) **/
    var spacing:Int;
    /** Array of `TiledTerrain` (optional) **/
    var terrains:Array<TiledTerrain>;
    /** The number of tiles in this tileset **/
    var tilecount:Int;
    /** The Tiled version used to save the file **/
    var tiledversion:String;
    /** Maximum height of tiles in this set **/
    var tileheight:Int;
    /** (optional) **/
    var tileoffset:TiledTileOffset;
    /**
     * The size to use when rendering tiles from this tileset on a
     * tile layer (`"tile"` (default) or `"grid"`) (since 1.9)
     **/
    var tilerendersize:String;
    /** Array of `TiledTile` (optional) **/
    var tiles:Array<TiledTile>;
    /** Maximum width of tiles in this set **/
    var tilewidth:Int;
    /** Allowed transformations (optional) **/
    var transformations:TiledTransformations;
    /** Hex-formatted color (`"#RRGGBB"`) (optional) **/
    var transparentcolor:String;
    /** `"tileset"` (for tileset files, since 1.0) **/
    var type:String;
    /** The JSON format version (previously a number, saved as string since 1.6) **/
    var version:String;
    /** Array of `TiledWangSet`s (since 1.1.5) **/
    var wangsets:Array<TiledWangSet>;
}

typedef TiledGrid = {
    /** Cell height of tile grid **/
    var height:Int;
    /** `"orthogonal"` (default) or `"isometric"` **/
    var orientation:String;
    /** Cell width of tile grid **/
    var width:Int;
}

typedef TiledTileOffset = {
    /** Horizontal offset in pixels **/
    var x:Int;
    /** Vertical offset in pixels (positive is down) **/
    var y:Int;
}

typedef TiledTransformations = {
    /** Tiles can be flipped horizontally **/
    var hflip:Bool;
    /** Tiles can be flipped vertically **/
    var vflip:Bool;
    /** Tiles can be rotated in 90-degree increments **/
    var rotate:Bool;
    /** Whether untransformed tiles remain preferred, otherwise transformed tiles are used to produce more variations **/
    var preferuntransformed:Bool;
}

typedef TiledTile = {
    /** Array of `TiledFrame`s **/
    var animation:Array<TiledFrame>;
    /** The class of the tile (renamed from `type` since 1.9, optional) **/
    var _class:String;
    /** Local ID of the tile **/
    var id:Int;
    /** Image representing this tile (optional, used for image collection tilesets) **/
    var image:String;
    /** Height of the tile image in pixels **/
    var imageheight:Int;
    /** Width of the tile image in pixels **/
    var imagewidth:Int;
    /** The X position of the sub-rectangle representing this tile (default: `0`) **/
    var x:Int;
    /** The Y position of the sub-rectangle representing this tile (default: `0`) **/
    var y:Int;
    /** The width of the sub-rectangle representing this tile (defaults to the image width) **/
    var width:Int;
    /** The height of the sub-rectangle representing this tile (defaults to the image height) **/
    var height:Int;
    /** Layer with `type == "objectgroup"`, when collision shapes are specified (optional) **/
    var objectgroup:TiledLayer;
    /** Percentage chance this tile is chosen when competing with others in the editor (optional) **/
    var probability:Float;
    /** Array of `TiledProperty` **/
    var properties:Array<TiledProperty>;
    /** Index of terrain for each corner of tile (optional) **/
    var terrain:Array<TiledTerrain>;
}

typedef TiledFrame = {
    /** Frame duration in milliseconds **/
    var duration:Int;
    /** Local tile ID representing this frame **/
    var tileid:Int;
}

typedef TiledTerrain = {
    /** Name of terrain **/
    var name:String;
    /** Array of `TiledProperty` **/
    var properties:Array<TiledProperty>;
    /** Local ID of tile representing terrain **/
    var tile:Array<Int>;
}

typedef TiledWangSet = {
    /** The class of the Wang set (since 1.9, optional) **/
    var _class:String;
    /** Array of `TiledWangColor`s (since 1.5) **/
    var colors:Array<TiledWangColor>;
    /** Name of the Wang set **/
    var name:String;
    /** Array of `TiledProperty` **/
    var properties:Array<TiledProperty>;
    /** Local ID of tile representing the Wang set **/
    var tile:Int;
    /** `"corner"`, `"edge"` or `"mixed"` (since 1.5) **/
    var type:String;
    /** Array of `TiledWangTile`s **/
    var wangtiles:Array<TiledWangTile>;
}

typedef TiledWangColor = {
    /** The class of the Wang color (since 1.9, optional) **/
    var _class:String;
    /** Hex-formatted color (`"#RRGGBB"` or `"#AARRGGBB"`) **/
    var color:String;
    /** Name of the Wang color **/
    var name:String;
    /** Probability used when randomizing **/
    var probability:Float;
    /** Array of `TiledProperty`s (since 1.5) **/
    var properties:Array<TiledProperty>;
    /** Local ID of tile representing the Wang color **/
    var tile:Int;
}

typedef TiledWangTile = {
    /** Local ID of tile **/
    var tileid:Int;
    /** Array of Wang color indexes (uchar[8]) **/
    var wangid:Array<TiledWangColor>;
}

typedef TiledObjectTemplate = {
    /** `"template"` **/
    var type:String;
    /** External tileset used by the template (optional) **/
    var tileset:TiledTileset;
    /** The object instantiated by this template **/
    var object:TiledObject;
}

typedef TiledProperty = {
    /** Name of the property **/
    var name:String;
    /**
     * Type of the property ("string" (default), `"int"`, `"float"`, `"bool"`, `"color"`, 
     * `"file"`, `"object"` or `"class"` (since 0.16, with `"color"` and `"file"` added in 0.17, 
     * `"object"` added in 1.4 and class `"added"` in 1.8))
     **/
    var type:String;
    /**
     * Name of the [custom property type](https://doc.mapeditor.org/en/stable/manual/custom-properties/#custom-property-types),
     * when applicable (since 1.8)
     **/
    var propertytype:String;
    /** Value of the property **/
    var value:Dynamic;
}

typedef TiledPoint = {
    /** X coordinate in pixels **/
    var x:Float;
    /** Y coordinate in pixels **/
    var y:Float;
}

/**
 * Displays a stage from a resource.
 * 
 * @since 0.2.0
 **/
class Map extends Object {
    /** The associated `TiledMap`. **/
    public var tiledMap:TiledMap;
    /**
     * An array of `h2d.TileGroup` instances.
     *
     * By default, it contains a single instance containing all the tiles.
     * Otherwise it contains an instance for each `TiledLayer` with `type` set to `"tilelayer"`.
     **/
    public var tileGroups:Array<h2d.TileGroup> = [];
    /** The associated `nb.Atlas` instance. **/
    public var atlas:Atlas = null;
    /** A saved tile from `atlas`. **/
    public var atlasTile:h2d.Tile = null;

    /** Creates an `nb.Map` instance. **/
	public function new(x:Float=0, y:Float=0, ?parent:nb.Object) {
        super(x,y,parent);
    }

    /** 
     * Loads a Tiled map from a json resource.
     *
     * @param resource The json resource to load the Tiled map from.
     * @param singleTileGroup If `true` a single instance will contains all the tiles, otherwise,
     * an instance of `h2d.TileGroup` will be made for each `TiledLayer` with `type` set to `"tilelayer"`. 
     **/
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