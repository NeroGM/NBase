package nb.fs;

using nb.ext.ArrayExt;
import haxe.io.BytesBuffer;
import haxe.io.Bytes;
import haxe.io.Path;
import haxe.macro.Context;
import hxd.fs.FileSystem;
import hxd.fs.FileEntry;
import nb.ds.MapArray;
import nb.editor.*;
#if (sys)
import sys.FileSystem as FS;
import sys.io.File;
import sys.thread.*;
#end

/**
 * A class containing informations about a loading process.
 * Made specifically for `nb.fs.FileSystem`.
 * 
 * @since 0.1.0
 **/
@:allow(nb.fs.NFileSystem)
class Progress {
	/** A string representing a resource that was just loaded. **/
	public var justLoaded(default,null):String = "";
	/** A string representing a resource that is loading. **/
	public var loading(default,null):String = "";
	/** From 0 to 1, how much of a resource is loaded. **/
	public var loadingPct(default,null):Float = 0;
	/** Total number of resources that are to be loaded. **/
	public var nTotal(default,null):Int = 0;
	/** From 0 to 1, how much of all resources are loaded. **/
	public var totalPct(default,null):Float = 0;
	/** Total number of resources loaded. **/
	public var nLoaded(default,null):Int = 0;

	/**
	 * Creates a `nb.fs.NFileSystem.Progress` instance.
	 * 
	 * @param nTotal Total number of resources that are to be loaded.
	 **/
	public function new(nTotal:Int=0) {
		this.nTotal = nTotal;
	}

	/**
	 * Specify that a resource was just loaded.
	 *
	 * @param name A string representing the resource.
	 **/
	public function loaded(name:String) {
		justLoaded = name;
		loadingPct = 1;
		nLoaded++;
		if (nTotal != 0) totalPct = nLoaded/nTotal;
	}
}

/**
 * Represents an entry, which is a file or a directory in an `nb.fs.NFileSystem`.
 * 
 * @since 0.1.0
 **/
@:allow(nb.fs.NFileSystem)
class NFileEntry extends FileEntry {
	/** The associated `nb.fs.NFileSystem`. **/
	private var fs:NFileSystem;
	/** The path of the entry relative to the resource directory. **/
	private var relPath:String;
	/** The resource data in memory as bytes. **/
	private var bytes:haxe.io.Bytes;
	/** The resource's `nb.fs.NFileSystem.Address`. **/
	private var address:Address;
	/** The cursor position for byte reading. **/
	private var pos:Int = 0;
	/** A function called whenever the file gets hot-reloaded. **/
	private var onFileChanged:Void->Void;
	/** `true` if this instance represents a directory, `false` otherwise. **/
	private var isDir:Bool = false;
	/** The last time the entry was modified on storage. **/
	public var mTime(default,null):Float = -1;
	
	#if target.threaded
	private var fileEntriesMutex:Mutex = new Mutex();
	#end

	/**
	 * Creates an `nb.fs.NFileSystem.NFileEntry` instance.
	 *
	 * @param relPath The path of the entry relative to the project's resource directory.
	 * @param fs The associated `nb.fs.NFileSystem`.
	 **/
    private function new(relPath:String, fs:NFileSystem) {
		var address = fs.resInfos.addresses[relPath];
		if (address == null) throw "Path '"+relPath+"' not in NFileSystem addresses.";
		this.address = address;
		this.name = Path.withoutDirectory(relPath);
		this.relPath = relPath;
		this.fs = fs;

		#if target.threaded fileEntriesMutex.acquire(); #end
		fs.fileEntries.push(this);
		#if target.threaded fileEntriesMutex.release(); #end

		if (this.address.data[0] == -1) {
			isDir = true;
			if (relPath == "") this.name = "<root>";
		}
	}

	/**
	 * Loads a file into memory.
	 * The file is loaded asynchronously if the target is javascript or supports threads.
	 * 
	 * The associated data file will be loaded if it wasn't already loaded.
	 *
	 * Throws an error if the entry is not a file.
	 * 
	 * @param onReady Called when the file finishes loading.
	 **/
	override public function load(?onReady:Void->Void) {
		#if !macro
		if (isDir) throw "Can't load a directory.";
		if (fs.embedMode) { bytes = haxe.Resource.getBytes(relPath); return; }

		var loadFromDataFile = (dataFileBytes) -> {
			if (dataFileBytes == null) throw "Datafile not found."; 
			#if target.threaded sys.thread.Thread.create(() -> { #end
				mTime = address.data[3];
				bytes = Bytes.alloc(Std.int(address.data[2]));
				bytes.blit(0,dataFileBytes,Std.int(address.data[1]),Std.int(address.data[2]));
				if (fs.autoWatchFiles && !fs.watchedFiles.contains(this)) fs.addFileToWatch(this);
				if (onReady != null) onReady();
			#if target.threaded }); #end
		}

		address = fs.resInfos.addresses[relPath];
		var dfName = "data"+address.data[0]+".dat";
		var dataFile = fs.loadedDataFiles.getOne((df) -> df.name == dfName);
		if (dataFile != null) loadFromDataFile(dataFile.bytes);
		else fs.loadDataFiles([dfName], false, (dataFile) -> loadFromDataFile(dataFile.bytes),null);
		#end
	}

	/** 
	 * Unloads a file.
	 * 
	 * Keep in mind that as long as the file's bytes is still referenced somewhere, then it's still in memory.
	 * This function only stops the file system from referencing it so that it gets garbage collected.
	 * 
	 * @return `true` if a loaded file was unloaded, `false` otherwise.
	 **/
	public function unload():Bool {
		if (bytes == null) return false;
		bytes = null;
		return true;
	}

	/**
	 * Copies the entry's bytes and stores it into a given `haxe.io.Bytes`.
	 * If the entry is a directory, nothing is copied.
	 *
	 * @param out An `haxe.io.Bytes` instance to store the bytes read.
	 * @param outPos The position in `out` from where to start writing bytes.
	 * @param pos The position in this instance's `bytes` from where to start copying.
	 * @param len Number of bytes to be copied.
	 * @return `len`, or 0 if the entry is a directory.
	 **/
	override public function readBytes(out:haxe.io.Bytes, outPos:Int, pos:Int, len:Int):Int {
		if (isDir) return 0;
		if (bytes == null) fs.autoLoadFiles ? load() : throw "FileEntry not loaded.";
		
		if( pos + len > bytes.length )
			len = bytes.length - pos;
		if( len < 0 ) len = 0;
		out.blit(outPos, bytes, pos, len);
		return len;
	}

	/** Loads the entry if it is a file, then returns `bytes`. **/
	override public function getBytes():haxe.io.Bytes {
		if (isDir) return null;

		if (fs.embedMode) {
			if (bytes == null) load();
			return haxe.Resource.getBytes(relPath);
		}

		if (bytes == null) {
			var s = relPath + " wasn't loaded.";
			if (fs.autoLoadFiles) { load(); s += " (Now loading...)"; }
			trace(s);
		}
		return bytes;
	}

	/**
	 * Checks whether an entry exists.
	 *
	 * Warning : Doesn't understand "../" in `path` yet. // todo
	 *
	 * @param path The entry's path relative to this instance's `path`.
	 * @return `true` if it exists, `false` otherwise.
	 **/
	override function exists(path:String):Bool {
		var fromDir = Path.directory(this.path);
		if (fromDir != "") fromDir += "/";
		for (address in fs.resInfos.addresses) if (fromDir + path == address.name) return true;
		return false;
	}
	
	/** Returns an iterator of all the entries in this entry's associated directory. **/
	override public function iterator():hxd.impl.ArrayIterator<FileEntry> {
		var a:Array<FileEntry> = [];
		for (address in fs.resInfos.addresses) if (Path.directory(relPath) == Path.directory(address.name)) a.push(fs.get(address.name));
		return new hxd.impl.ArrayIterator(a);
	}

	/**
	 * Sets a callback for whenever the file changes.
	 * 
	 * It must also be added to the associated `NFileSystem`'s `watchedFiles` to trigger,
	 * which by default is done automatically when the file is loaded into memory. 
	 **/
	override public function watch(onChanged:Null<Void -> Void>) {
		this.onFileChanged = () -> {
			// trace("FILE CHANGED : " + relPath);
			if (onChanged != null) onChanged();
		}
	}

	override function get_size() return bytes == null ? 0 : bytes.length;
	override function get_path() return relPath;
	override function get_extension() return haxe.io.Path.extension(name);
	override function get_isDirectory() return isDir;
}

/**
 * An `nb.ds.NamedData` containing an array of floats storing
 * a resource's data location in a data file and other useful informations.
 * Its name is the resource's path relative to the project's resource directory.
 *
 * In the array is stored at pos : <br/>
 *  - 0 : The associated data file's number (dataX.dat). A negative number means no data file is associated with the resource. <br/>
 *  - 1 : The position of the first byte of the resource in the data file. <br/>
 *  - 2 : The resource's size in bytes. <br/>
 *  - 3 : The last time the resource was modified on storage. <br/>
 * 
 * A free `Address` refers to data in the data file that is allowed to be overwritten.
 **/
typedef Address = nb.ds.NamedData<Array<Float>>;
/** 
 * An `nb.ds.NamedData` containing an array of floats describing a data file.
 * Its name is the data file's path relative to the project's executable.
 *
 * In the array is stored at pos : <br/>
 *  - 0 : The data file's number (dataX.dat). <br/>
 *  - 1 : The data file's size in bytes. <br/>
 **/
typedef DataFileInfo = nb.ds.NamedData<Array<Int>>;
/** Contains a data file's data. **/
typedef DataFile = {
	/** The data file's name. **/
	var name:String;
	/** The data file's data as bytes. **/
	var bytes:haxe.io.Bytes;
};
/** Contains all `Address`es and `DataFileInfo`s. **/
typedef ResInfos = {addresses:MapArray<Array<Float>>, dataFilesMA:MapArray<Array<Int>>};

/** Defines a converter. **/
typedef ConvDefinition = {
	/** A converter that can converts from this type. **/
    var fromType:String;
	/** A converter that can converts to this type. **/
    var toType:String;
	/** If not `null`, a converter that has one of these keywords. **/
    var ?keywords:Array<String>;
}

/**
 * A file system.
 *
 * Call `init` to generate data files and get an instance of this class.
 *
 * When the target is javascript or has threads, and the file system isn't in embed mode,
 * make sure you load the resources before trying to access them because resources will load
 * asynchronously.
 *
 * If you don't want to micromanage, use the filesystem in embed mode by using the `init`
 * function, or load every resources from the start by calling `loadDataFiles` with no arguments
 * then unload the data files used to load the resource by calling `unloadDataFiles`.
 *
 * Hot-reloading will automatically load files that it needs to load but won't automatically
 * unload them.
 * 
 * @since 0.1.0
 **/
class NFileSystem implements FileSystem {
	#if macro
	private static var _embed:Bool = false;
	#end

	/** Contains all the `Address`es and `DataFileInfo`s. **/
	public var resInfos:ResInfos;
	/** Contains all loaded data files. **/
	public var loadedDataFiles:Array<DataFile> = [];
	/** Contains all created `NFileEntry`s. **/
	public var fileEntries:Array<NFileEntry> = [];
	/** Paths relative to the project's resource directory that will be ignored when looking for new or updated resources. **/
	public var resPathsToSkip:Array<String> = [];

	/** Contains freed addresses. A free `Address` refers to data in the data file that is allowed to be overwritten. **/
	public var freeAddresses:MapArray<Array<Float>> = new MapArray();
	/** Next id to assign to a free data. **/
	private var nextFreeId:Int = 0;
	/** If `true`, files will be loaded automatically in memory when their data are being accessed. **/
	public var autoLoadFiles:Bool = true;
	/** Adds files to `watchedFiles` automatically when they are loaded. **/
	public var autoWatchFiles:Bool = true;
	/** Files to check for hot-reloading. **/
	public var watchedFiles:Array<NFileEntry> = [];
	/** Maximum size of a data file. A number <= 0 means there's no limit. **/
	public var maxSizePerFile:Int = -1;
	/** Check watched files every X seconds. **/
	private var watchFileCd:Float = 1;
	/** Whether this instance's is currently checking watched files. **/
	private var checkingWatchedFiles:Bool = false;
	/** If `true`, the file system assumes the resources data are embedded in the executable. **/
	public var embedMode(default,null):Bool = false;

	/** Resources directory path, relative to the project's directory. **/
	public var resPath(default,null):String = "";
	/** Data files directory path, relative to the executable. **/
	public var dataPath(default,null):String = "";
	/**
	 * String added at the beginning of requests sent to the server. 
	 * The true server's root will always be at the project's directory path.
	 **/
	public var rootPath(default,null):String = "";
	/** Executable path relative to the project's directory. **/
	public var buildPath(default,null):String = "";
	/** Contains instructions about which file type should be converted. **/
	public var convInsts:Array<ConvDefinition> = null;

	/** 
	 * Contains indexes of `resInfos.addresses` corresponding to the first resource in a data file.
	 *
	 * Example: `startPoses[2]` is the index of the first resource of "data2.dat" in `resInfos.addresses`.
	 **/
	private var startPoses:Array<Int> = [];
	#if (target.threaded) private var fileWatchMutex:sys.thread.Mutex = new sys.thread.Mutex(); #end

	/**
	 * Creates a new `NFileSystem` instance.
	 *
	 * Could be useful if you are trying to use multiple file systems, otherwise
	 * you shouldn't be calling it and you're propably looking for the `init` function.
	 *
	 * Also, this file system wasn't made with other file systems in mind at all.
	 * 
	 * @param resPath Resources directory path, relative to the project's directory.
	 * @param resPathsToSkip Paths relative to the project's resource directory that
	 * will be ignored when looking for new or updated resources.
	 **/
	public function new(resPath:String, ?resPathsToSkip:Array<String>) {
		#if !macro
		this.resPath = resPath;
		resInfos = {dataFilesMA:new MapArray(), addresses:new MapArray() };
		Manager.neroFS = this;
		if (resPathsToSkip != null) this.resPathsToSkip = resPathsToSkip;
		#end
	}

	/**
	 * Builds the data files then returns a new `nb.fs.NFileSystem` instance all set up.
	 * 
	 * Set `dataPath` to `"EMBED"` to enable embed mode.
	 *
	 * @param dataPath Data files directory path, relative to the executable.
	 * @param resPath Resources directory path, relative to the project's directory.
	 * @param buildPath Executable path relative to the project's directory.
	 * @param resPathsToSkip Paths relative to the project's resource directory that
	 * will be ignored when looking for new or updated resources.
	 * @param maxSizePerFile Maximum size of a data file. A number <= 0 means there's no limit.
	 **/
	public static macro function init(dataPath:String="", maxSizePerFile:Int=-1, ?convInsts:Array<ConvDefinition>, resPath:String="res/", ?buildPath:String, ?resPathsToSkip:Array<String>) {
		// _convInsts = convInsts;
		if (dataPath == "EMBED") _embed = true;

		if (buildPath == null) {
			if (Context.defined("hlsdl")) buildPath = "build/sdl/";
			else if (Context.defined("hldx")) buildPath = "build/dx/";
			else if (Context.defined("js")) {
				if (!Context.defined("serv")) { buildPath = "build/js/"; _embed = true; }
				else buildPath = "build/js_php/";
			}
		}
		var rootPath:String = "";
		for (_ in 0...buildPath.split("/").length-1) rootPath += "../";

		var resInfos = makeDataFiles(dataPath,maxSizePerFile,convInsts,resPath,buildPath,resPathsToSkip);
		ArrayExt.quickSort(cast(resInfos.addresses, Array<Dynamic>), (a,b) -> {
			var a = cast(a, nb.ds.NamedData<Dynamic>);
			var b = cast(b, nb.ds.NamedData<Dynamic>);
			if (a.data[0] != b.data[0]) return a.data[0] < b.data[0];
			else return a.data[1] < b.data[1];
		});

		var lastI:Int = -1;
		var startPoses:Array<Int> = [];
		var c:Int = 0;
		for (address in resInfos.addresses) {
			if (address.data[0] != lastI) {
				lastI = Std.int(address.data[0]);
				startPoses.push(c);
			}
			c++;
		}

		var s = haxe.Serializer.run(resInfos.addresses);
		var s2 = haxe.Serializer.run(resInfos.dataFilesMA);
		return macro {
			var neroFS = new nb.fs.NFileSystem($v{resPath},$v{resPathsToSkip});
			hxd.Res.loader = new hxd.res.Loader(neroFS);
			@:privateAccess {
				neroFS.embedMode = $v{_embed};
				neroFS.maxSizePerFile = $v{maxSizePerFile};
				neroFS.dataPath = $v{dataPath};
				neroFS.rootPath = $v{rootPath};
				neroFS.buildPath = $v{buildPath};
				neroFS.convInsts = $v{convInsts};
				neroFS.resInfos = { dataFilesMA:haxe.Unserializer.run($v{s2}), addresses:haxe.Unserializer.run($v{s}) };
				neroFS.startPoses = $v{startPoses};
				neroFS.log();
			}
			neroFS;
		}
	}

	#if macro
	/** Makes data files then returns an object containing all the associated `Address`es and `DataFileInfo`s. **/
	public static function makeDataFiles(dataPath:String="", maxSizePerFile:Int=-1, ?convInsts:Array<ConvDefinition>, resPath:String="res/", ?buildPath:String, ?resPathsToSkip:Array<String>):ResInfos {
		if (!FS.isDirectory(resPath)) throw "Invalid res path : '"+resPath+"'.";
		if (resPathsToSkip == null) resPathsToSkip = [];
		
		var paths:Array<String> =  [""];
		var addresses:MapArray<Array<Float>> = new MapArray();
		addresses[""] = [-1.,0,0,0];

		if (_embed) {
			for (path in paths) for (file in FS.readDirectory(resPath+path)) {
				var fullFilePath = resPath+path+file;
				var relFilePath = fullFilePath.substr(resPath.length);
				
				if (resPathsToSkip.contains(relFilePath)) continue;
				if (FS.isDirectory(fullFilePath)) {
					paths.push(relFilePath+"/");
					addresses[relFilePath+"/"] = [-1.,0,0,0];
					continue;
				}
				
				var fileBytes:haxe.io.Bytes = File.getBytes(fullFilePath);
				if (convInsts != null) fileBytes = s_convert(relFilePath, fileBytes, convInsts);

				Context.addResource(relFilePath, fileBytes);
				var v:Array<Float> = [fileBytes.length];
				addresses[relFilePath] = v;
			}
			return { dataFilesMA:new MapArray(), addresses:addresses };
		} else {
			var dfDesc:MapArray<Array<Int>> = new MapArray();
			var bBuffer:haxe.io.BytesBuffer = new haxe.io.BytesBuffer();
			var pos:Int = 0;
			var iRB:Int = 0;
			var relFilePath:String = "";
			var flush:Void->Void = () -> {
				var relPath = dataPath+"data"+iRB+".dat";
				var bytes = bBuffer.getBytes();
				File.saveBytes(buildPath+relPath, bytes);
				dfDesc[relPath] = [iRB, bytes.length];
				iRB++;
				pos = 0;
				bBuffer = new haxe.io.BytesBuffer();
			}
			for (path in paths) for (file in FS.readDirectory(resPath+path)) {
				var fullFilePath = resPath+path+file;
				relFilePath = fullFilePath.substr(resPath.length);
				
				if (resPathsToSkip.contains(resPath+relFilePath)) continue;

				if (FS.isDirectory(fullFilePath)) {
					paths.push(relFilePath+"/");
					addresses[relFilePath+"/"] = [-1.,0,0,0];
					continue;
				}
				var fileBytes = File.getBytes(fullFilePath);
				if (convInsts != null) fileBytes = s_convert(relFilePath, fileBytes, convInsts);
				
				if (maxSizePerFile > 0 && bBuffer.length + fileBytes.length > maxSizePerFile && bBuffer.length != 0) flush();
				bBuffer.addBytes(fileBytes,0,fileBytes.length);
				var address:Array<Float> = new Array();
				address[0] = iRB;
				address[1] = pos;
				address[2] = fileBytes.length;
				address[3] = Std.int(FS.stat(fullFilePath).mtime.getTime() / 1000);
				pos += fileBytes.length;
				addresses[relFilePath] = address;
			}
			flush();
			File.saveBytes(buildPath+"map.dat", haxe.io.Bytes.ofString(haxe.Serializer.run(addresses)));
			File.saveContent(buildPath+"log.txt", "NFILESYSTEM LOGS\n\n");
			return { dataFilesMA:dfDesc, addresses:addresses };
		}
	}
	#end

	/**
	 * Converts a file data to another type if it has a converter for it.
	 * 
	 * @param path The path of the resource, relative to the project's resource folder.
	 * @param bytes The resource's data as bytes.
	 * @param convDefs An array of `nb.fs.NFileSystem.ConvDefinition` defining the converters that could be used.
	 * @return The possibly converted `bytes`.
	 **/
	public static function s_convert(path:String, bytes:Bytes, convDefs:Array<ConvDefinition>):Bytes {
		var ext = Path.extension(path);

		var inst:ConvDefinition = null;
		for (v in convDefs) if (v.fromType == ext) { inst = v; break; }
		if (inst == null) return bytes;

		var oLen = bytes.length;
		ConverterManager.convert(bytes,ext,inst.toType,inst.keywords);
		return bytes;
	}

	/**
	 * Converts a file data to another type.
	 *
	 * It checks if there's any instruction in `convInsts` that says if the data should be converted.
	 * 
	 * @param path The path of the resource, relative to the project's resource folder.
	 * @param bytes The resource data as bytes.
	 * @return `bytes` converted.
	 **/
	public function convert(path:String, bytes:Bytes):Bytes {
		return s_convert(path,bytes,convInsts);
	}

	#if !macro
	/**
	 * The function called every frame by `nb.Manager`.
	 *
	 * @param dt Elapsed time in seconds.
	 **/
	public function update(dt:Float) {
		if (checkingWatchedFiles) return;

		watchFileCd -= dt;
		if (watchFileCd <= 0) {
			checkWatchedFiles();
			watchFileCd = #if js 3 #else 1 #end;
		}
	}
	
	/**
	 * Hot-reloads resources.
	 *
	 * Checks for any file that was modified recently by looking at their metadata
	 * and updates their associated data file and `Address`.
	 *
	 * This is done asynchronously if the target is javascript or supports threads.
	 **/
	public function checkWatchedFiles() {
		checkingWatchedFiles = true;
		var toRemove:Array<NFileEntry> = [];

		#if sys
		#if target.threaded sys.thread.Thread.create(() -> { #end
			var nChecking:Int = 0;
			var filesToSave:Array<String> = ["map.dat"];
			for (file in watchedFiles) {
				var path = rootPath+resPath+file.relPath;
				var currMTime:Float = 0;
				try currMTime = Std.int(FS.stat(path).mtime.getTime() / 1000)
				catch (e) { trace("Couldn't stat '"+path+"', removed from watch."); toRemove.push(file); }

				if (file.mTime < currMTime) {
					nChecking++;
					var freeA = freeSection(file.relPath);
					var newBytes:Bytes = null;
					try File.getBytes(path)
					catch (e) { trace("Couldn't get bytes at '"+path+"', removed from watch."); toRemove.push(file); }
					sectionInsert(file.relPath, newBytes, (info) -> {
						var oTime = file.mTime;
						file.mTime = currMTime;
						file.bytes = newBytes;
						freeA.data[3] = currMTime;
						info.address.data[3] = currMTime;
						if (file.onFileChanged != null) file.onFileChanged();
						ResManager.onFileChanged(file);
						nChecking--;
						if (!filesToSave.contains(info.dataFileInfo.name)) filesToSave.push(info.dataFileInfo.name);
						if (nChecking == 0) {
							saveResData(filesToSave);
							checkingWatchedFiles = false;
							log();
						}
					});
				}
				if (nChecking == 0) checkingWatchedFiles = false;
			}
			for (file in toRemove) watchedFiles.remove(file);
		#if target.threaded }); #end
		#end

		#if js
		var a:Array<{path:String,mTime:Float}> = [for (file in watchedFiles) { path:file.path, mTime:file.mTime } ];
		var headers = new js.html.Headers();
		headers.append("Accept",'application/json, text/plain, */*');
		headers.append('Content-Type','application/json');
		var reqInit:js.html.RequestInit = {
			method: "POST",
			headers: headers,
			body: haxe.Json.stringify({files:a})
		};
		js.Browser.window.fetch(rootPath+"serv/php/checkFiles.php",reqInit).then((res) -> res.ok ? res.text() : null).then((txt) -> {
			var json:haxe.DynamicAccess<Dynamic> = haxe.Json.parse(txt); // { filepath(String):mTime(Float) }

			var nChecking:Int = 0;
			var filesToSave:Array<String> = ["map.dat"];
			for (path => mTime in json) {
				nChecking++;
				js.Browser.window.fetch(rootPath+resPath+path).then((res) -> res.ok ? res.arrayBuffer() : null).then((aBuf) -> {
					if (aBuf == null) { nChecking--; trace("'"+rootPath+resPath+path+"' returned NULL."); return; }
					var freeA = freeSection(path);
					var newBytes = Bytes.ofData(aBuf);
					sectionInsert(path,newBytes, (info) -> {
						var file = watchedFiles.getOne((o) -> o.relPath == path);
						var oTime = file.mTime;
						file.mTime = mTime;
						file.bytes = newBytes;
						freeA.data[3] = mTime;
						info.address.data[3] = mTime;
						if (file.onFileChanged != null) file.onFileChanged();
						ResManager.onFileChanged(file);
						nChecking--;
						if (!filesToSave.contains(info.dataFileInfo.name)) filesToSave.push(info.dataFileInfo.name);
						if (nChecking == 0) {
							saveResData(filesToSave);
							checkingWatchedFiles = false;
							log();
						}
					});
				});
			}
			if (nChecking == 0) checkingWatchedFiles = false;
		});
		#end
	}

	/**
	 * Watches a file for any change.
	 * 
	 * By default, this is done automatically when a resource gets loaded.
	 **/
	public function addFileToWatch(entry:nb.fs.NFileSystem.NFileEntry) {
		#if (target.threaded) fileWatchMutex.acquire(); #end
		watchedFiles.push(entry);
		#if (target.threaded) fileWatchMutex.release(); #end
	}

	/**
	 * Loads data files.
	 * 
	 * This is done asynchronously if the target is javascript or supports threads.
	 *
	 * @param paths Paths of data files that are to be loaded, relative to the executable.
	 * @param loadResources If `true`, when a data file finishes loading, loads all its associated resources.
	 * @param onLoaded Called whenever a data file finishes loading.
	 * @param onAllLoaded Called when all the data files finished loading.
	 * @return An `nb.fs.NFileSystem.Progress` for each data file to check the loading progresses.
	 **/
	public function loadDataFiles(?paths:Array<String>, loadResources:Bool=true, ?onLoaded:DataFile->Void, ?onAllLoaded:Array<DataFile>->Void) {
		if (embedMode) { onAllLoaded([]); return []; }

		// Get valid data file paths
		var dfPaths:Array<String> = [];
		if (paths != null) {
			for (key in resInfos.dataFilesMA.keys()) for (path in paths) if (key.indexOf(path) == 0) dfPaths.push(path);
		} else dfPaths = [for (o in resInfos.dataFilesMA) o.name];
		if (dfPaths.length == 0) { onAllLoaded([]); return []; }

		// Threads and Progresses init
		var maxNFetches:Int = Std.int(Math.min(4, dfPaths.length));
		var aProgress = [for (_ in 0...maxNFetches + 1) new Progress(dfPaths.length)];
		var mainProgress = aProgress[0];

		// Start loading
		var dfPathsIt = dfPaths.iterator();
		var nFinishedFetch:Int = 0;
		var nStartedFetch:Int = 0;

		#if target.threaded
			var mutex = new sys.thread.Mutex();
			#end
		function fetch(name:String, progress:Progress) {
			progress.loading = name;
			var dataFile = loadedDataFiles.getOne((df) -> df.name == name);

			function fetchNext() {
				dfPathsIt.hasNext() ? fetch(dfPathsIt.next(), progress) : {
					if (++nFinishedFetch == nStartedFetch && onAllLoaded != null) onAllLoaded(loadedDataFiles) ;
				}
			}

			function finalCheck() {
				function done() {
					progress.loaded(name);
					mainProgress.loaded(name);
					if (onLoaded != null) onLoaded(dataFile);
				}
				loadResources ? loadResFromDataFile(dataFile.name, done) : done();
			}
			
			if (dataFile != null) { finalCheck(); fetchNext(); return; }

			#if sys #if target.threaded sys.thread.Thread.create(() -> { #end
				 var bytes = File.getBytes(name);
			#elseif js
			js.Browser.window.fetch(name).then((res) -> return res.ok ? res.arrayBuffer() : null).then((aBuf) -> {
				if (aBuf == null) return;
				var bytes = haxe.io.Bytes.ofData(aBuf);
			#end
				dataFile = {name:name, bytes:bytes};
				#if target.threaded mutex.acquire(); #end
				loadedDataFiles.push(dataFile);
				#if target.threaded mutex.release(); #end
				finalCheck();
				fetchNext();
			#if js }); #elseif target.threaded }); #end
		};
		for (i in 0...maxNFetches) if (dfPathsIt.hasNext()) {
			nStartedFetch++;
			fetch(dfPathsIt.next(), aProgress[i+1]);
		} else break;

		return aProgress;
	}

	/**
	 * Loads all resources associated with a datafile.
	 *
	 * @param dfRelPath Path of a data file, relative to the executable.
	 * @param onAllLoaded Called when all data files finishes loading.
	 * @return An `nb.fs.NFileSystem.Progress` to check the loading progress.
	 **/
	public function loadResFromDataFile(dfRelPath:String, ?onAllLoaded:Void->Void):Progress {
		if (embedMode) { onAllLoaded(); return null; }

		var dataFile = loadedDataFiles.getOne((o) -> o.name == dfRelPath);
		if (dataFile == null) throw "Data file not loaded. " + loadedDataFiles.toString();

		var v = resInfos.dataFilesMA[dataFile.name].data[0];
		var startPos:Int = startPoses[v];

		var p = new Progress();
		#if (sys && target.threaded) var lock = new sys.thread.Lock(); var mutex = new sys.thread.Mutex(); #end
		for (i in startPos...resInfos.addresses.length) {
			var address = resInfos.addresses[i];
			var resPath = address.name;
			var aAddress = address.data;

			var dataFilePath:String = "data"+aAddress[0]+".dat";
			if (dataFilePath != dfRelPath) break;
			p.nTotal++;
			
			var e = fileEntries.getOne((e) -> return e.relPath == resPath);
			if (e == null) {
				#if target.threaded mutex.acquire(); #end
				e = new NFileEntry(resPath,this);
				#if target.threaded mutex.release(); #end
			}

			if (e.bytes == null) e.load(() -> {
				p.loaded(resPath);
				#if target.threaded lock.release(); #end
			});
			else {
				p.loaded(resPath);
				#if target.threaded lock.release(); #end
			}
		}

		#if (sys && target.threaded) sys.thread.Thread.create(() -> { for (_ in 0...p.nTotal) lock.wait(); #end
			onAllLoaded();
		#if (sys && target.threaded) }); #end
		
		return p;
	}

	/**
	 * Loads resources from given paths.
	 *
	 * Loads their associated data file if they are not loaded.
	 * 
	 * @param relPaths Paths of resources to load.
	 * @param onLoaded Called when a resource finishes loading.
	 * @param onAllLoaded Called when all resources finished loading.
	 * @return An `nb.fs.NFileSystem.Progress` to check the loading progress.
	 **/
	public function loadResFromPaths(relPaths:Array<String>, ?onLoaded:NFileEntry->Void, ?onAllLoaded:Array<NFileEntry>->Void):Progress {
		if (embedMode) { onAllLoaded([]); return null; }
		
		var p = new Progress();

		// Find data files to load
		var dfToLoad:Array<String> = [];
		var resToLoadAddresses:Array<Address> = [];
		for (address in resInfos.addresses) for (relPath in relPaths) {
			if (address.data[0] < 0) continue;
			if (address.name.indexOf(relPath.indexOf("*") == -1 ? relPath : relPath.substr(0,relPath.length-1)) != 0) continue;
			if (relPath.charAt(relPath.length-1) != "*" && address.name.indexOf("/",relPath.length) != -1) continue;
			
			var resDataFile:nb.ds.NamedData<Array<Int>> = null;
			for (df in resInfos.dataFilesMA) if (df.data[0] == address.data[0]) {
				resDataFile = df;
				break;
			}
			if (resDataFile == null) { // Should never happen
				trace("Resource '" + address.name + "' associated with unknown data file.");
				continue;
			}

			resToLoadAddresses.push(address);
			if (!dfToLoad.contains(resDataFile.name) && loadedDataFiles.getOne((df) -> df.name == resDataFile.name) == null) dfToLoad.push(resDataFile.name);
		}

		// Load resources after all the data files they are in are loaded
		var entries:Array<NFileEntry> = [];
		p.nTotal = resToLoadAddresses.length;
		loadDataFiles(dfToLoad,false,null,(_) -> {
			function loaded(entry:NFileEntry) {
				p.loaded(resPath);
				if (onLoaded != null) onLoaded(entry);
				if (p.nTotal == p.nLoaded && onAllLoaded != null) onAllLoaded(entries);
			}

			for (address in resToLoadAddresses) {
				var entry:NFileEntry = cast(get(address.name), NFileEntry);
				entries.push(entry);
				if (entry.bytes == null) entry.load(() -> loaded(entry));
				else loaded(entry);
			}

		});

		if (p.nTotal == 0) onAllLoaded([]);

		return p;
	}

	/** Logs the content of `addresses` in a "log.txt" file in the same directory as the executable. **/
	private function log() {
		#if !debug return; #end
		if (embedMode) return;

		var s:String = "{ ";
		var addresses = resInfos.addresses;
		for (address in addresses) {
			s += address.name + " => [" + address.data[0] + "," + address.data[1] + "," + address.data[2] + "," + address.data[3] + "]";
			if (addresses[addresses.length-1] == address) s += " }\n\n";
			else s += ", ";
		}

		#if sys
		#if target.threaded sys.thread.Thread.create(() -> { #end
			File.append("log.txt", false).writeString(s);
		#if target.threaded }); #end
		#end

		#if js
		var headers = new js.html.Headers();
		headers.append("Accept",'application/json, text/plain, */*');
		headers.append('Content-Type','application/json');
		var reqInit:js.html.RequestInit = {
			method: "POST",
			headers: headers,
			body: haxe.Json.stringify({data:s})
		};
		js.Browser.window.fetch(buildPath+"log.txt",reqInit).then((res) -> res.ok ? res.text() : null).then((txt) -> {
			if (txt == null) trace("LOGGING FAILED.");
		});
		#end
	}

	/**
	 * Unloads a data file.
	 *
	 * Keep in mind that as long as the datafile is referenced somewhere, it's still in memory. This 
	 * function only tells the file system to stop referencing it so that it gets garbage collected.
	 * 
	 * @param path Path of the data file, relative to the executable.
	 * @return `true` if a loaded data file was just unloaded, `false` otherwise.
	 **/
	public inline function unloadDataFile(path:String):Bool {
		return loadedDataFiles.removeIf((df) -> df.name == path) != null;
	}

	/**
	 * Frees the `Address` associated to the path given, which marks
	 * a resource's data in a data file as overwrittable.
	 * 
	 * When an `Address` is freed, it will merge its data with other freed `Address`es
	 * that have adjacent resource data location in the data file.
	 * 
	 * @param relPath A path associated to an `Address`.
	 * @return The freed `Address` after merging.
	 **/
	private function freeSection(relPath:String):Address {
		var addressToAdd = resInfos.addresses[relPath];
		var beforeEdit = addressToAdd.data.copy();
		var lAddress:Address = null;
		var rAddress:Address = null;

		for (address in freeAddresses) {
			if (lAddress == null && address.data[1]+address.data[2] == addressToAdd.data[1]) {
				lAddress = address;
				if (rAddress != null) break;
			}
			if (rAddress == null && address.data[1] == addressToAdd.data[1]+addressToAdd.data[2]) {
				rAddress = address;
				if (lAddress != null) break;
			}
		}

		if (lAddress != null) {
			addressToAdd.data[1] -= lAddress.data[2];
			addressToAdd.data[2] += lAddress.data[2];
			freeAddresses.remove(lAddress);
			resInfos.addresses.remove(lAddress);
		}
		if (rAddress != null) {
			addressToAdd.data[2] += rAddress.data[2];
			freeAddresses.remove(rAddress);
			resInfos.addresses.remove(rAddress);
		}
		resInfos.addresses.changeKey(relPath, "[FREE]["+(nextFreeId++)+"]");
		freeAddresses.push(addressToAdd);
		addressToAdd.data[3] = getTime();
		return addressToAdd;
	}

	/**
	 * Inserts a resource's data in a data file and assign it an `Address`.
	 *
	 * @param relPath The path of the resource, relative to the project's resource directory.
	 * @param resBytes The resource's data.
	 * @param onInserted Called when the resource's data finishes being inserted and has its associated `Address`.
	 **/
	private function sectionInsert(relPath:String, resBytes:haxe.io.Bytes, onInserted:{dataFileInfo:DataFileInfo,address:Address}->Void) {
		for (address in freeAddresses) {
			if (address.data[2] < resBytes.length) continue;
			
			var dataFileInfo:DataFileInfo = null;
			for (dfInfo in resInfos.dataFilesMA) if (dfInfo.data[0] == address.data[0]) { dataFileInfo = dfInfo; break; }
			if (dataFileInfo == null) throw "???"; // Should never happen
			
			loadDataFiles([dataFileInfo.name],false,(df) -> {
				var mTime = getTime();
				var resAddress:Address = new Address(relPath, [dataFileInfo.data[0],address.data[1],resBytes.length,mTime]);

				var newDfBytes:BytesBuffer = new BytesBuffer();
				newDfBytes.addBytes(df.bytes,0,Std.int(resAddress.data[1]));
				newDfBytes.addBytes(resBytes,0,resBytes.length);
				var freeBytesStartPos:Int = newDfBytes.length;
				newDfBytes.addBytes(df.bytes,newDfBytes.length,df.bytes.length-newDfBytes.length);
				df.bytes = newDfBytes.getBytes();
				resInfos.addresses.remove(address);
				freeAddresses.remove(address);
				resInfos.addresses.push(resAddress);

				var freeBytesLength:Float = (address.data[1]+address.data[2])-freeBytesStartPos;
				var newFreeAddress:Address = null;
				if (freeBytesLength > 0) {
					newFreeAddress = new Address("[FREE][" + (nextFreeId++) + "]",[dataFileInfo.data[0],freeBytesStartPos,freeBytesLength,mTime]);
					freeAddresses.push(newFreeAddress);
					resInfos.addresses.push(newFreeAddress);
				}

				onInserted({dataFileInfo:dataFileInfo, address:resAddress});
			}, null);
			return;
		}

		var dataFileInfo:DataFileInfo = null;
		for (dfInfo in resInfos.dataFilesMA) if (maxSizePerFile > 0 && dfInfo.data[1] + resBytes.length <= maxSizePerFile) { dataFileInfo = dfInfo; break; }
		if (dataFileInfo == null) dataFileInfo = resInfos.dataFilesMA[0]; // If all files would exceed max size, use data0.dat anyway
		
		loadDataFiles([dataFileInfo.name],false,(df) -> {
			var mTime = getTime();

			var newDfBytes = new BytesBuffer();
			newDfBytes.addBytes(df.bytes,0,df.bytes.length);
			newDfBytes.addBytes(resBytes,0,resBytes.length);
			var resAddress:Address = new Address(relPath, [dataFileInfo.data[0],dataFileInfo.data[1],newDfBytes.length-df.bytes.length,mTime]);
			df.bytes = newDfBytes.getBytes();
			dataFileInfo.data[1] = df.bytes.length;
			resInfos.addresses.push(resAddress);
			onInserted({dataFileInfo:dataFileInfo, address:resAddress});
		}, null);
	}

	/**
	 * Saves currently loaded data files data to their associated file on storage.
	 *
	 * @param dataPaths Paths associated to a data file, relative to the executable.
	 **/
	private function saveResData(?dataPaths:Array<String>) {
		if (embedMode) return;

		if (dataPaths == null) dataPaths = ["map.dat"];

		#if sys
		for (path in dataPaths) {
			if (path.substr(path.lastIndexOf("/")+1) == "map.dat") {
				File.saveBytes(path, Bytes.ofString(haxe.Serializer.run(resInfos.addresses)));
				continue;
			}
			var df = loadedDataFiles.getOne((o) -> o.name == path);
			if (df != null) File.saveBytes(path, df.bytes);
		}
		#end

		#if js
		var v:Array<{path:String,data:String}> = [];
		for (path in dataPaths) {
			if (path.substr(path.lastIndexOf("/")+1) == "map.dat") {
				v.push({path:buildPath+"map.dat",data:haxe.crypto.Base64.encode(Bytes.ofString(haxe.Serializer.run(resInfos.addresses)))});
				continue;
			}
			var df = loadedDataFiles.getOne((o) -> o.name == path);
			if (df != null) v.push({path:buildPath+df.name,data:haxe.crypto.Base64.encode(df.bytes)});
		}

		var headers = new js.html.Headers();
		headers.append("Accept",'application/json, text/plain, */*');
		headers.append('Content-Type','application/json');
		var reqInit:js.html.RequestInit = {
			method: "POST",
			headers: headers,
			body: haxe.Json.stringify({data:v})
		};
		js.Browser.window.fetch(rootPath+"serv/php/saveDataFiles.php",reqInit).then((res) -> res.ok ? res.text() : null).then((txt) -> {
			trace(txt);
		});
		#end
	}

	/** Gives a timestamp in seconds. **/
	private function getTime():Float {
		#if js return Std.int(js.lib.Date.now() / 1000);
		#elseif sys return Std.int(Sys.time());
		#else return throw "Not implemented.";
		#end
	}
	#end

	/** Returns the resource directory's associated `nb.fs.NFileSystem.NFileEntry` downcasted to `hxd.fs.FileEntry`. **/
    public function getRoot():FileEntry {
		return get("");
	}

	/**
	 * Returns an entry associated to a given resource path.
	 * If it doesn't have its entry cached and its a valid resource path, it creates the entry.
	 *
	 * Throws an error if it's not a valid resource path. (It doesn't have an associated `Address`.)
	 * 
	 * @param resPath A resource path, relative to the resource directory.
	 * @return The associated `nb.fs.NFileSystem.NFileEntry` downcasted to `hxd.fs.FileEntry`.
	 **/
	public function get(resPath:String):FileEntry {
		var e = fileEntries.getOne((e) -> e.relPath == resPath);
		if (e == null) e = new NFileEntry(resPath,this);
		return e;
    }

	/** Returns `true` if an `Address` is associated to the path given, `false` otherwise. **/
	public function exists(resPath:String):Bool {
		return resInfos.addresses.exists(resPath);
	}

	/** Does nothing yet. **/
	public function dispose():Void { }; // todo
	
	/**
	 * Returns a list of entries that are in a directory.
	 *
	 * @param path A path relative to the project's resource directory to deduce the directory.
	 * @return Entries with their associated resources being in `path`'s directory.
	 **/
	public function dir(path:String):Array<FileEntry> {
		return [for (address in resInfos.addresses) if (Path.directory(path) == Path.directory(address.name)) get(address.name)];
	}
}