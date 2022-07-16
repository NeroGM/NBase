package nb;

typedef TiledMap = {
    var backgroundcolor:String;
    var _class:String;
    var compressionlevel:Int;
	var height:Int;
    var hexsidelength:Int;
    var infinite:Bool;
    var layers:Array<TiledLayer>;
    var nextlayerid:Int;
    var nextobjectid:Int;
    var orientation:String;
    var parallaxoriginx:Float;
    var parallaxoriginy:Float;
    var properties:Array<TiledProperty>;
    var renderorder:String;
    var staggeraxis:String;
    var staggerindex:String;
    var tiledversion:String;
    var tileheight:Int;
    var tilesets:Array<TiledTileset>;
    var tilewidth:Int;
    var type:String;
    var version:String;
    var width:Int;
}

typedef TiledLayer = {
    var chunks:Array<TiledChunk>;
    var _class:String;
    var compression:String;
    var data:Dynamic;
    var draworder:String;
    var encoding:String;
    var height:Int;
    var id:Int;
    var image:String;
    var layers:Array<TiledLayer>;
    var locked:Bool;
    var name:String;
    var objects:Array<TiledObject>;
    var offsetx:Float;
    var offsety:Float;
    var opacity:Float;
    var parallaxx:Float;
    var parallaxy:Float;
    var properties:Array<TiledProperty>;
    var repeatx:Bool;
    var repeaty:Bool;
    var startx:Int;
    var starty:Int;
    var tintcolor:String;
    var transparentcolor:String;
    var type:String;
    var visible:Bool;
    var width:Int;
    var x:Int;
    var y:Int;
}

typedef TiledChunk = {
    var data:Array<String>;
    var height:Int;
    var width:Int;
    var x:Int;
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