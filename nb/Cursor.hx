package nb;

import nb.Window;
import nb.Tween;

@dox(hide)
typedef HL_Cursor = #if !macro #if hlsdl hl.Abstract<"sdl_cursor"> #elseif hldx hl.Abstract<"dx_cursor"> #else {} #end #else {} #end;

enum abstract CursorKind(Int) {
    var Arrow = #if hldx 32512 #else 0 #end;
    var IBeam = #if hldx 32513 #else 1 #end;
    var Wait = #if hldx 32514 #else 2 #end;
    var Crosshair = #if hldx 32515 #else 3 #end;
    var UpArrow = #if hldx 32516 #elseif hlsdl 0 #else 12 #end;
    var SizeNWSE = #if hldx 32642 #else 5 #end;
    var SizeNESW = #if hldx 32643 #else 6 #end;
    var SizeWE = #if hldx 32644 #else 7 #end;
    var SizeNS = #if hldx 32645 #else 8 #end;
    var SizeALL = #if hldx 32646 #else 9 #end;
    var No = #if hldx 32648 #else 10 #end;
    var Hand = #if hldx 32649 #else 11 #end;
    var WaitArrow = #if hldx 32650 #else 4 #end;
    var Help = #if hldx 32651 #elseif hlsdl 0 #else 13 #end;
}

/**
 * Controls the cursor.
 *
 * Works with this fork of hashlink : https://github.com/NeroGM/hashlink
 * 
 * @since 0.1.0
 **/
class Cursor {
    /** The `nb.Tween.TweenVar` in charge of moving the cursor. **/
    private static var moveTw:TweenVar = null ;
    /** The default `nb.Tween.TweenType` used by the `moveTo` function. **/
    public static var defaultMoveTween:TweenType = null;
    /**
     * The last cursor set by this class.
     * (Which is the current mouse cursor if you're not changing the cursor by other means.)
     **/
    public static var cursor:CursorKind = CursorKind.Arrow;
    
    /** Sets the cursor. **/
    public static function setCursor(c:CursorKind) {
        #if hl
        b_hl_setCursor(b_createSystem(c));
        cursor = c;
        #elseif js
        var canvas = @:privateAccess hxd.Window.getInstance().canvas;
        if( canvas != null ) canvas.style.cursor = switch(c) {
			case Arrow: "default";
            case IBeam: "text";
            case Wait: "wait";
            case Crosshair: "crosshair";
            case UpArrow: "default";
            case SizeNWSE: "nwse-resize";
            case SizeNESW: "nesw-resize";
            case SizeWE: "ew-resize";
            case SizeNS: "ns-resize";
            case SizeALL: "move";
            case No: "not-allowed";
            case Hand: "pointer";
            case WaitArrow: "progress";
            case Help: "help";
        };
        cursor = c;
        #end
    }

    #if !macro
    /** 
     * Tweens the cursor to a given position.
     * 
     * @param x The x position.
     * @param y The y position.
     * @param relative If `true` the position is relative to the window, otherwise it's a screen position.
     * @param twType The `nb.Tween.TweenType` that will be used to move the mouse to the given position.
     * `null`, `defaultMoveTween` is used. If both are `null`, the default tween type of the tween function is used.
     **/
    public static function moveTo(x:Int, y:Int, relative:Bool=true, ?twType:TweenType) {
        if (moveTw != null && moveTw.t < 1 && moveTw.t > 0) {
            moveTw.end();
        }
        
        if (twType == null) if (defaultMoveTween != null) twType = defaultMoveTween;
        else { setCursorPosition(x,y,relative); return; }

        var m = getCursorPosition(relative);
        moveTw = nb.Tween.startMultiple([m.x,m.y], [x,y], 0.3, twType, (v,_,_) -> {
            setCursorPosition(Std.int(v[0]),Std.int(v[1]),relative);
        });
    }

    /**
     * Returns the cursor position.
     *
     * @param relative If `true` the position will be relative to the window, otherwise it's a screen position.
     * @return An `h2d.col.Point` containing the cursor position.
     **/
    public static function getCursorPosition(relative:Bool=true):Point {
        #if (neroHL && (hlsdl || hldx))
        var x:Int = 0;
        var y:Int = 0;
        b_getCursorPositionG(x,y);
        if (relative) return Window.screenPosToClientPos(x,y);
        return new Point(x,y);
        #end
        return Manager.getMouseCoords(true);
    }
    
    /**
     * Sets the cursor position.
     *
     * Use the `moveTo` function for tweening.
     *
     * @param x The X coordinate.
     * @param y The Y coordinate.
     * @param relative If `true` the position is relative to the window, otherwise it's a screen position.
     **/
    public static function setCursorPosition(x:Int, y:Int, relative:Bool=true) {
        #if (hlsdl || hldx) relative ? b_setCursorPosition(Window.win,x,y) : b_setCursorPositionG(x,y); #end
    }
    #end
    

    // BINDINGS

    #if neroHL @:hlNative(#if hlsdl "sdl" #elseif hldx "directx" #end,"set_cursor_position") #end
    private static function b_setCursorPosition(win:HL_Window, x:Int, y:Int) { }

    // SDL/DX Inconsistent
    #if neroHL @:hlNative(#if hlsdl "sdl" #elseif hldx "directx" #end,"get_cursor_position") #end
    private static function b_getCursorPosition(win:HL_Window, x:HL_Int, y:HL_Int) { }

    #if neroHL @:hlNative(#if hlsdl "sdl" #elseif hldx "directx" #end,"set_cursor_position_g") #end
    private static function b_setCursorPositionG(x:Int, y:Int) { }

    #if neroHL @:hlNative(#if hlsdl "sdl" #elseif hldx "directx" #end,"get_cursor_position_g") #end
    private static function b_getCursorPositionG(x:HL_Int, y:HL_Int) { }
    
    #if hlsdl @:hlNative("sdl", "cursor_create_system") #elseif hldx @:hlNative("directx","load_cursor") #end
	private static function b_createSystem(kind:CursorKind):HL_Cursor return null;

    #if hlsdl @:hlNative("sdl", "set_cursor") #elseif hldx @:hlNative("directx","set_cursor") #end
	private static function b_hl_setCursor(k:HL_Cursor) { }
}
