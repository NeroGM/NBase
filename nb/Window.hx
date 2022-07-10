package nb;

@:dox(hide)
typedef HL_Window = #if !macro #if hlsdl hl.Abstract<"sdl_window"> #elseif hldx hl.Abstract<"dx_window"> #else {} #end #else {} #end;

/**
 * Contains functions to manipulate the app's window.
 * 
 * Works with this fork of hashlink : https://github.com/NeroGM/hashlink
 * 
 * @since 0.1.0
 **/
@:allow(nb.Cursor)
class Window {
    private static var win:HL_Window;

    #if !macro
    /** Initializes this class. **/
    public static function init() {
        #if (hlsdl || hldx) win = @:privateAccess hxd.Window.getInstance().window.win; #end
    }

    /** Changes the window size. **/
    public static function changeWindowSize(w:Int, h:Int) {
		#if (hlsdl || hldx)
		var win = @:privateAccess hxd.Window.getInstance().window;
		win.resize(w, h);
		nb.Manager.app.engine.resize(w, h);
		#end
	}

    /** Changes the window title. **/
	public static function changeWindowTitle(s:String) {
		#if (hlsdl || hldx)
		var win = @:privateAccess hxd.Window.getInstance().window;
		win.title = s;
		#end
	}

    /** Returns the window position coordinates. **/
    public static function getWindowPosition():Point {
        #if (hlsdl || hldx)
        var x:Int = 0;
        var y:Int = 0;
        b_getWindowPosition(win,x,y);
        return new Point(x,y);
        #end
        return new Point();
    }

    /** Sets the window position. **/
    public static function setWindowPosition(x:Int, y:Int) {
        #if (hlsdl || hldx) b_setWindowPosition(win,x,y); #end
    }

    /** Converts a client position to a screen position. **/
    public static function clientPosToScreenPos(x:Int, y:Int):Point {
        #if (hlsdl || hldx) b_clientPosToScreenPos(win,x,y); #end
        return new Point(x,y);
    }

    /** Converts a screen position to a client position. **/
    public static function screenPosToClientPos(x:Int, y:Int):Point {
        #if (hlsdl || hldx) b_screenPosToClientPos(win,x,y); #end
        return new Point(x,y);
    }
    #end

    // BINDINGS

    #if neroHL @:hlNative(#if hlsdl "sdl" #elseif hldx "directx" #end,"get_window_position") #end
    private static function b_getWindowPosition(win:HL_Window, x:HL_Int, y:HL_Int) { }

    #if neroHL @:hlNative(#if hlsdl "sdl" #elseif hldx "directx" #end,"set_window_position") #end
    private static function b_setWindowPosition(win:HL_Window, x:Int, y:Int) { }

    #if neroHL @:hlNative(#if hlsdl "sdl" #elseif hldx "directx" #end,"client_pos_to_screen_pos") #end
    private static function b_clientPosToScreenPos(win:HL_Window, x:HL_Int, y:HL_Int) { }

    #if neroHL @:hlNative(#if hlsdl "sdl" #elseif hldx "directx" #end,"screen_pos_to_client_pos") #end
    private static function b_screenPosToClientPos(win:HL_Window, x:HL_Int, y:HL_Int) { }
}