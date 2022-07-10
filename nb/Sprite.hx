package nb;

using nb.ext.ArrayExt;
using nb.ext.AseExt;
import h3d.mat.Texture;

/**
 * Contains data about a sprite animation.
 *
 * @since 0.1.0
 **/
class AnimData {
    /** The animation's name. **/
    public var name:String;
    /** Contains the animation's frame index for each frame. **/
    public var frames:Array<Int>;
    /** Contains the frame duration for each frame. `frameDuration[4]` is the frame duration of the 4th frame. **/
    public var framesDuration:Array<Int>;
    /** The animation's default frame duration. **/
    public var defaultDuration:Int;
    /** Whether the animation should play in reverse. **/
    public var reverse:Bool;
    /** Whether the animation stop playing at the last frame. **/
    public var once:Bool = false;
    /**
     * A function that gets called at the start of every frame.
     *
     * The first argument is the associated animation data, and the second argument the
     * frame that is just starting to get displayed. Returns the index of the next frame set to be displayed.
     *
     * `onFrameEnd` gets called before `onFrameStart`.
     **/
	public var onFrameStart:(AnimData,Int)->Int = null;
    /**
     * A function that gets called at the end of every frame.
     *
     * The first argument is the associated animation data, and the second argument the
     * frame that is just stopping to get displayed. Returns the index of the next frame set to be displayed.
     *
     * `onFrameEnd` gets called before `onFrameStart`.
     **/
    public var onFrameEnd:(AnimData,Int)->Int = null;

    /**
     * Creates an `nb.Sprite.AnimData` instance.
     *
     * @param name A name to identify the animation.
     * @param frames The animation's frame indexes.
     * @param reverse Whether the animation should be played in reverse.
     * @param defaultDuration The default duration of the frames.
     **/
    public function new(name:String, frames:Array<Int>, reverse:Bool = false, defaultDuration:Int = 100) {
        this.name = name;
        this.frames = frames;
        this.reverse = reverse;
        this.defaultDuration = defaultDuration;
        this.framesDuration = [for (_ in 0...frames.length) defaultDuration];
    }
}

/**
 * A sprite class.
 *
 * @since 0.1.0
 **/
class Sprite extends Object {
    /** This sprite's associated `h3d.mat.Texture`. **/
    public var tex:Texture;
    /** This sprite's associated `h2d.SpriteBatch`. **/
    public var sb:h2d.SpriteBatch;
    /**
     * The tiles associated with this sprite.
     * 
     * Example: `tiles[1][3]` returns the tile used for displaying the 3rd layer of the 1st frame.
     **/
    public var tiles:Array<Array<h2d.Tile>> = [];
    /**
     * The `h2d.SpriteBatch.BatchElement` associated with this sprite.
     * 
     * Example: `elements[2][1]` returns the element used for displaying the 1st layer of the 2nd frame.
     **/
    public var elements:Array<Array<h2d.SpriteBatch.BatchElement>> = [];
    /** The `nb.Atlas` associated with this sprite. **/
    public var atlas:Atlas;
    /** Contains all animations used for this sprite. **/
    public var animations:Array<AnimData> = [];

    /** The current animation data this sprite is using. **/
    public var currentAnimation:AnimData;
    /** The frame index of the frame being displayed. **/
	public var frame(default, null):Int = 0;
    /** A time in seconds before going to the next frame. **/
	public var animC(default,null):Float = 0;
    /** The current animation frame index. **/
	public var animFrameIndex(default,null):Int = 0;
    /** Whether the animation is paused/stopped. **/
	public var animPaused(default,null):Bool = false;

    /** Whether the sprite is flipped on its horizontal axis. **/
    public var xFlipped:Bool = false;
    /** Whether the sprite is flipped on its vertical axis. **/
    public var yFlipped:Bool = false;

    /**
     * Creates an `nb.Sprite` instance.
     * 
     * @param x The instance's x coordinate.
	 * @param y The instance's y coordinate.
	 * @param parent The instance's parent object.
     **/
    override public function new(x:Float=0, y:Float=0, ?parent:h2d.Object) {
        super(x,y,parent);
        sb = new h2d.SpriteBatch(null,this);
        sb.hasRotationScale = true; // Use to not get +0.1 offsets in rendering from SpriteBatch
    }

    /**
     * The update function that gets called every frame by `nb.Manager`.
     * When overriding, you should call `super.update` for animations to work. 
     **/
    override public function update(dt:Float) {
        if (currentAnimation != null && !animPaused) {
			var frameDuration = currentAnimation.framesDuration[animFrameIndex];
			animC += dt * 1000;
			if (animC > frameDuration) {
				animC -= frameDuration;
				
				var nextAnimFrame:Int = animFrameIndex;
				if (currentAnimation.onFrameEnd != null) nextAnimFrame = currentAnimation.onFrameEnd(currentAnimation, nextAnimFrame);
				if (currentAnimation.onFrameEnd == null || nextAnimFrame == -100) {
					if (animFrameIndex + 1 < currentAnimation.frames.length) nextAnimFrame = animFrameIndex + 1;
					else if (currentAnimation.frames[animFrameIndex] == currentAnimation.frames[currentAnimation.frames.length-1] && currentAnimation.once) {
						pauseAnimation();
					} else nextAnimFrame = 0;
				}
				if (currentAnimation.onFrameStart != null && !animPaused) nextAnimFrame = currentAnimation.onFrameStart(currentAnimation, nextAnimFrame);
				
				animFrameIndex = nextAnimFrame;
				toFrame(currentAnimation.frames[animFrameIndex], false);
			}
		}
    }

    /** Loads a tile. **/
    public function loadTile(tile:h2d.Tile) {
        sb.clear();
        sb.tile = tile;
        tiles = [[tile]];
        elements = [[sb.alloc(tile)]];
        finishLoading();
        setSize(tile.width,tile.height);
    }

    /** 
     * Loads an image resource.
     * 
     * @param image The image resource to display.
     * @param w Width of the image to display. If it is lower than the resource
     * image size, the image is understood as a spritesheet.
     * @param h Height of the image to display. If it is lower than the resource
     * image size, the image is understood as a spritesheet.
     * @param toFormat The pixel format to convert the bytes to, if not a gif image.
     * @param flipY Set to `true` if `image` needs to be flipped vertically.
     * @param index Index used to read image data from a Dds file.
     **/
    // ! Make gif properly
    public function loadImage(image:hxd.res.Image, ?w:Int, ?h:Int, toFormat:hxd.PixelFormat=hxd.PixelFormat.RGBA, ?flipY:Bool, ?index:Int) {
        var imgSize = image.getSize();
        var imgFormat = image.getFormat();
        if(w == null || imgFormat == Gif) w = imgSize.width;
        if(h == null || imgFormat == Gif) h = imgSize.height;

        var texName:String = image.name+"_"+imgSize.width+"x"+imgSize.height+"_"+toFormat.getName();
        tex = ResManager.getTextureByName(texName);
        var frameCount:Int = -1; // used for gif
        var offsets:Array<Array<Int>> = null; // should upgrade atlas for gif offsets
        if (tex == null) {
            if (imgFormat == Gif) {
                offsets = [];
                var sds:Array<Atlas.SubData> = [];
                var data = new format.gif.Reader(new haxe.io.BytesInput(image.entry.getBytes())).read();
                var atlas = new Atlas();
                frameCount = 0;
                for (fd in nb.ext.GifExt.getFrameDatas(data)) {
                    var sd = atlas.addBytes(fd.bytes, fd.w, fd.h, "[GIF]"+image.name+":"+frameCount);
                    @:privateAccess sd.dx = fd.x;
                    @:privateAccess sd.dy = fd.y;
                    frameCount++;
                    sds.push(sd);
                }
                atlas.make(2048,2048,RGBA);
                tex = atlas.texture;

                sb.clear();
                sb.tile = h2d.Tile.fromTexture(tex);
                tiles = [];
                elements = [];
                for (sd in sds) {
                    var subTile = sb.tile.sub(sd.x,sd.y,sd.w,sd.h);
                    var e = sb.alloc(subTile);
                    e.x = sd.dx; e.y = sd.dy;
                    tiles.push([subTile]);
                    elements.push([e]);
                    e.visible = false;
                }
                finishLoading();
                currentAnimation = addAnimation("_",[for (i in 0...elements.length) i]);
                setSize(w,h);
                return;
            } else tex = Texture.fromPixels(image.getPixels(toFormat,flipY,index));

            tex.setName(texName);
            ResManager.addTexture(tex);
        }

        var tile = h2d.Tile.fromTexture(tex);

        if (w == tile.width && h == tile.height) { loadTile(tile); return; }

        sb.clear();
        sb.tile = tile;
        var cx = frameCount == -1 ? Std.int(tile.width/w) : Std.int(Math.min(tile.width/w,frameCount));
        var cy = frameCount == -1 ? Std.int(tile.height/h) : Math.ceil(frameCount/cx);
        tiles = [];
        elements = [];
        for (iY in 0...cy) for (iX in 0...cx) {
            var subTile = offsets != null ? tile.sub(iX*w+offsets[iX+iY][0],iY*h+offsets[iX+iY][1],w,h) : tile.sub(iX*w,iY*h,w,h);
            var e = sb.alloc(subTile);
            tiles.push([subTile]);
            elements.push([e]);
            e.visible = false;
        }
        finishLoading();
        currentAnimation = addAnimation("_",[for (i in 0...elements.length) i]);
        setSize(w,h);
    }

    /** Loads an aseprite. **/
    public function loadAseprite(aseprite:nb.Ase, toFormat:hxd.PixelFormat=RGBA) {
        var atlasName:String = aseprite.entry.name+"_"+aseprite.width+"x"+aseprite.height+"_"+toFormat.getName();
        atlas = ResManager.getAtlasByName(atlasName);
        var subDs:Array<Atlas.SubData>;
        if (atlas == null) {
            atlas = new Atlas();
            subDs = atlas.addAseprite(aseprite, null, toFormat);
            atlas.make();
            atlas.name = atlasName;
            @:privateAccess atlas.nameLocked = true;
            ResManager.addAtlas(atlas);

            atlas.listeningObjects.push({o:this, onHotReload:() -> {
                var aseprite = nb.Ase.fromEntry(aseprite.entry);
                var oFrame = frame;
                frame = 0;
                loadAseprite(aseprite,toFormat);
                toFrame(oFrame,false);
            }});
        } else subDs = atlas.subDatas;
        
        sb.clear();
        sb.tile = h2d.Tile.fromTexture(atlas.texture);

        tiles = [];
        elements = [];
        var durFrames:Array<Int> = [];
        for (sd in subDs) {
            if (tiles[sd.frameId] == null) {
                tiles[sd.frameId] = [];
                elements[sd.frameId] = [];
            }
            var subTile = sb.tile.sub(sd.x,sd.y,sd.w,sd.h);
            var e = sb.alloc(subTile);
            tiles[sd.frameId][sd.layerId] = subTile;
            e.x = sd.dx; e.y = sd.dy;
            elements[sd.frameId][sd.layerId] = e;
            e.visible = false;

            durFrames[sd.frameId] = aseprite.frames[sd.frameId].duration;
        }
        
        finishLoading();
        currentAnimation = addAnimation("_",[for (i in 0...elements.length) i]);
        currentAnimation.framesDuration = durFrames;
        setSize(aseprite.width,aseprite.height);
    }

    /** Flips the sprite on the horizontal axis. **/
    public function flipX() {
        for (e in sb.getElements()) {
            e.x = size.w-(e.x+e.t.width);
			e.t.flipX();
            e.t.dx = 0;
        }
		xFlipped = !xFlipped;
	}

    /** Flips the sprite on the vertical axis. **/
	public function flipY() {
		for (e in sb.getElements()) {
            e.y = size.h-(e.y+e.t.height);
			e.t.flipY();
            e.t.dy = 0;
		}
		yFlipped = !yFlipped;
	}

    /** Displays a frame. **/
    public function toFrame(frame:Int, pauseAnimation:Bool=true) {
        if (elements[frame] == null) return;
        for (e in elements[this.frame]) if (e != null) e.visible = false;
        this.frame = frame;
        for (e in elements[frame]) if (e != null) e.visible = true;
    }

    /**
     * Adds an animation data.
     *
     * @param name A name for the animation.
     * @param frames The frame indexes to display, in order.
     * @param reverse Whether the animation should play reversed.
     * @param defaultDuration The default frame duration.
     **/
    public function addAnimation(name:String, frames:Array<Int>, reverse:Bool = false, defaultDuration:Int = 100):AnimData {
        var ad = new AnimData(name,frames,reverse,defaultDuration);
        animations.push(ad);
        return ad;
    }

    /** Plays an animation. **/
    public function playAnimation(name:String):AnimData {
        currentAnimation = animations.getOne((anim) -> anim.name == name);
        if (currentAnimation != null) animPaused = false;
        return currentAnimation;
    }

    /** Toggles the current animation's paused status, then returns `true if it's paused, `false` otherwise. **/
    public inline function pauseAnimation():Bool return animPaused = !animPaused;

    private inline function finishLoading() {
        this.frame = 0;
        for (e in elements[0]) if (e != null) e.visible = true;
    }
}