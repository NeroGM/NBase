package;

import nb.Manager;
import h2d.col.Point;
using nb.ext.PointExt;

class Main extends hxd.App {
    override function init() {
		nbInit();

		Manager.neroFS = nb.fs.NFileSystem.init("",1000000);

		Manager.neroFS.loadDataFiles(null,true,null,(_) -> {
			trace("All files loaded.");
			Manager.init(this,800,600,() -> {
				trace("Manager initialised.");
				Manager.createScene(src.scenes.FirstScene, "fs");
				Manager.changeScene("fs",true);
			});
		});
    }
	
	override public function update(dt:Float) {
	    Manager.update(dt);
		super.update(dt);
	}
	
    static function main() new Main();

	override public function onResize() {
		for (scene in Manager.createdScenes) scene.onResize();
	}

	/** Changes trace function. **/
	private function nbInit() {
		#if (sys && target.threaded)
		var mutex = new sys.thread.Mutex();
		haxe.Log.trace = function(v:Dynamic, ?infos:haxe.PosInfos) {
			var s = "";
			if (infos != null) s += infos.fileName +":"+infos.lineNumber+": ";
			s += v;

			mutex.acquire();
			Sys.println(s);
			mutex.release();
		}
		#end
	}
}