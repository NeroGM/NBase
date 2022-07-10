package src.scenes;

import h2d.col.Point;

class FirstScene extends nb.Scene {
    var txt:h2d.Text;
    override public function new() {
        super();

        
    }

    override public function onFirstLoad() {
        txt = new h2d.Text(hxd.res.DefaultFont.get());
        var o = new nb.Object(0,0);
        o.addChild(txt);
        cam.add(o);
        
        addBgInteractive();
        nb.Manager.addSceneUpdate(this);
        super.onFirstLoad();
    }

    override public function update(dt:Float) {
        txt.text = nb.Manager.getMouseCoords().toString();

        super.update(dt);
    }
}