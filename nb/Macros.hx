package nb;

import haxe.macro.Context;
import haxe.macro.Expr;
#if sys
import sys.FileSystem as FS;
#end

/**
 * Contains some macro functions.
 *
 * @since 0.1.0
 **/
class Macros {
	/**
	 * Generates a variable containing all scene classes found in this project's "src/scenes" folder.
	 * Used for `nb.Manager.sceneClasses`.
	 **/
	public static macro function makeScenes() {
		var paths:Array<String> = ["src/scenes/"];
		
		var e:String = '{';
		for (path in paths) {
			var pathC:String = StringTools.replace(path, "/", ".");
			for (s in FS.readDirectory(path)) {
				if (s.substr(s.length - 3, 3) == ".hx") {
					s = s.substr(0, s.length - 3);
					var s2 = s.toLowerCase();
					e += e.length == 1 ? '$s2:$pathC$s' : ',$s2:$pathC$s';
					
				} else if (FS.exists(path+s+"/") == true) {
					paths.push(path+s+"/");
				}
			}
		}
		e += '}';
		
		return Context.parse(e, Context.currentPos());
	}

	/**
	 * Extends `h2d.Object`.
	 *
	 * Adds IDs and tags support.
	 **/
	public static macro function extH2dObject():Array<Field> {
		var fields = Context.getBuildFields();

		var newField:Field = {access:[APrivate,AStatic],name:"nextId",pos:Context.currentPos(),
			kind:FVar(macro:Int,macro 0)
		};
		fields.push(newField);

		var newField:Field = {access:[APublic,AFinal],name:"objId",pos:Context.currentPos(),
			kind:FVar(macro:Int,macro nextId++)
		}
		fields.push(newField);

		var newField:Field = {access:[APublic],name:"tags",pos:Context.currentPos(),
			kind:FProp("default","never",macro:Array<{name:String, inheritable:Bool, inherited:Bool}>, macro [])
		};
		fields.push(newField);
		
		var newField:Field = {access:[APublic],name:"fOnChildren",pos:Context.currentPos(),
			kind:FFun({
				args:[
					{opt:true,name:"fAll",type:macro:h2d.Object->Void},
					{opt:true,name:"fNb",type:macro:nb.Object->Void}
				],
				expr:macro {
					for (c in iterator()) {
						var nbObject:nb.Object = null;
			
						if (fNb != null && c is nb.Object) {
							var nbObj = cast(c,nb.Object);
							fNb(nbObj);
							nbObj.fOnChildren(fAll,fNb);
						} else {
							if (fAll != null) fAll(c);
							c.fOnChildren(fAll,fNb);
						}
					}
				}
			})
		};
		fields.push(newField);

		var newField:Field = {access:[APublic],name:"addTag",pos:Context.currentPos(),
			kind:FFun({
				args:[
					{name:"tagName",type:macro:String},
					{name:"inheritable",type:macro:Bool,value:macro false},
					{name:"inherited",type:macro:Bool,value:macro false}
				],
				expr:macro {
					var tag:nb.Object.Tag = {name:tagName,inheritable:inheritable,inherited:inherited};
					for (t in tags) if (t.name == tagName) return;
					tags.push(tag);

					if (inheritable) fOnChildren((o) -> {
						o.addTag(tagName,inheritable,true);
					});					
				}
			})
		}
		fields.push(newField);

		var newField:Field = {access:[APublic],name:"removeTag",pos:Context.currentPos(),
			kind:FFun({
				args:[{name:"tagName",type:macro:String}],
				expr:macro {
					var tag:nb.Object.Tag = null;
					for (t in tags) if (t.name == tagName) { 
						tag = t;
						tags.remove(tag);
						break;
					}
					if (tag == null) return;

					if (tag.inheritable) fOnChildren((o) -> o.removeTag(tagName));				
				}
			})
		}
		fields.push(newField);

		var newField:Field = {access:[APrivate],name:"inheritParentTags",pos:Context.currentPos(),
			kind:FFun({
				args:[],
				expr:macro {
					for (tag in tags) if (tag.inheritable) addTag(tag.name, tag.inheritable, true);				
				}
			})
		}
		fields.push(newField);

		var newField:Field = {access:[APublic],name:"hasTag",pos:Context.currentPos(),
			kind:FFun({
				args:[{name:"tagName",type:macro:String}],
				ret:macro:Bool,
				expr:macro { for (tag in tags) if(tag.name == tagName) return true; return false; }
			})
		};
		fields.push(newField);

		var field:Field = nb.ext.ArrayExt.getOne(fields, (o) -> o.name == "removeChild");
		field.kind.getParameters()[0].expr = macro {
			if( children.remove(s) ) {
				if( s.allocated ) s.onRemove();
				s.parent = null;
				if( s.parentContainer != null ) s.setParentContainer(null);
				s.posChanged = true;
				#if domkit
				if( s.dom != null ) s.dom.onParentChanged();
				#end
				onContentChanged();

				var i = s.tags.length-1;
				while (i >= 0) {
					var tag = tags[i--];
					if (tag.inherited) s.removeTag(tag.name);
				}
			}
		}

		var field:Field = nb.ext.ArrayExt.getOne(fields, (o) -> o.name == "addChildAt");
		field.kind.getParameters()[0].expr = macro {
			if( pos < 0 ) pos = 0;
			if( pos > children.length ) pos = children.length;
			var p:h2d.Object = this;
			while( p != null ) {
				if( p == s ) throw "Recursive addChild";
				p = p.parent;
			}
			if( s.parent != null ) {
				// prevent calling onRemove
				var old = s.allocated;
				s.allocated = false;
				s.parent.removeChild(s);
				s.allocated = old;
			}
			children.insert(pos, s);
			if( !allocated && s.allocated )
				s.onRemove();
			s.parent = this;

			s.posChanged = true;
			
			inheritParentTags(); // <--

			// ensure that proper alloc/delete is done if we change parent
			if( allocated ) {
				if( !s.allocated )
					s.onAdd();
				else
					s.onHierarchyMoved(true);
			}
			#if domkit
			if( s.dom != null ) s.dom.onParentChanged();
			#end
		};



		var newField:Field = {access:[APublic],name:"posChangedThisFrame",pos:Context.currentPos(),
			kind:FProp('default','null',macro:Bool,macro false)
		};
		fields.push(newField);

		var field:Field = nb.ext.ArrayExt.getOne(fields, (o) -> o.name == "set_x");
		field.kind.getParameters()[0].expr = macro {
			posChanged = true;
			if (!posChangedThisFrame) {
				posChangedThisFrame = true;
				nb.Manager.objPosChanged.push(this);
			}
			return x = v;
		}

		var field:Field = nb.ext.ArrayExt.getOne(fields, (o) -> o.name == "set_y");
		field.kind.getParameters()[0].expr = macro {
			posChanged = true;
			if (!posChangedThisFrame) {
				posChangedThisFrame = true;
				nb.Manager.objPosChanged.push(this);
			}
			return y = v;
		}
		
		return fields;
	}
}