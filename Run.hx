package;

import sys.FileSystem as FS;
import sys.io.File;

class Run {
    static function main() {
        var args:Array<String> = Sys.args();
        if (args.length < 2) { Sys.println("Do : haxelib run nbase [newFolderName]"); return; }

        var dir:String = args[args.length-1]+args[0]+"/";

        if (FS.exists(dir)) {
            var char:Int = -1;
            do {
                Sys.println("Folder '"+args[1]+"' already exists. Continue anyway ? (y/n)");
                char = Sys.getChar(true);
                switch (char) {
                    case 89 | 121 : break; // Y or y 
                    case 78 | 110 : // N or n
                        Sys.println("Aborted.");
                        return;
                }
            } while (true);
        }

        try FS.createDirectory(dir) catch(e) {
            Sys.println("Couldn't create directory '"+dir+"'");
            return;
        }

        var tplDir = "tpl/";
        var paths:Array<String> = [""];
        var ignorePaths:Array<String> = ["documentation","docs","dump","doc.hxml","docHtml.bat"];
        for (path in paths) for (file in FS.readDirectory(tplDir+path)) {
            var filePath = tplDir+path+file;

            var skip:Bool = false;
            for (path in ignorePaths) if (filePath.indexOf(tplDir+path) == 0) skip = true;
            if (skip) continue;
            haxe.Log.trace(filePath,null);

            if (FS.isDirectory(filePath)) {
                paths.push(path+file+"/");
                FS.createDirectory(dir+path+file+"/");
                continue;
            }

            File.saveContent(dir+path+file, File.getContent(filePath));
        }
    }
}