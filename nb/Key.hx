package nb;

/**
 * Not much different from `hxd.Key` for now.
 * 
 * @since 0.1.0
 **/
@:dox(hide)
@:allow(nb.Manager)
class Key {
	public static inline var BACKSPACE	= 8;
	public static inline var TAB		= 9;
	public static inline var ENTER		= 13;
	public static inline var SHIFT		= 16;
	public static inline var CTRL		= 17;
	public static inline var ALT		= 18;
	public static inline var ESCAPE		= 27;
	public static inline var SPACE		= 32;
	public static inline var PGUP		= 33;
	public static inline var PGDOWN		= 34;
	public static inline var END		= 35;
	public static inline var HOME		= 36;
	public static inline var LEFT		= 37;
	public static inline var UP			= 38;
	public static inline var RIGHT		= 39;
	public static inline var DOWN		= 40;
	public static inline var INSERT		= 45;
	public static inline var DELETE		= 46;

	public static inline var QWERTY_EQUALS = 187;
	public static inline var QWERTY_MINUS = 189;
	public static inline var QWERTY_TILDE = 192;
	public static inline var QWERTY_BRACKET_LEFT = 219;
	public static inline var QWERTY_BRACKET_RIGHT = 221;
	public static inline var QWERTY_SEMICOLON = 186;
	public static inline var QWERTY_QUOTE = 222;
	public static inline var QWERTY_BACKSLASH = 220;
	public static inline var QWERTY_COMMA = 188;
	public static inline var QWERTY_PERIOD = 190;
	public static inline var QWERTY_SLASH = 191;
	public static inline var INTL_BACKSLASH = 226; // Backslash located next to left shift on some keyboards. Warning: Not available on HLSDL.
	public static inline var LEFT_WINDOW_KEY = 91;
	public static inline var RIGHT_WINDOW_KEY = 92;
	public static inline var CONTEXT_MENU = 93;
	// public static inline var PRINT_SCREEN = // Only available on SDL

	public static inline var PAUSE_BREAK = 19;
	public static inline var CAPS_LOCK = 20;
	public static inline var NUM_LOCK = 144;
	public static inline var SCROLL_LOCK = 145;

	public static inline var NUMBER_0	= 48;
	public static inline var NUMBER_1	= 49;
	public static inline var NUMBER_2	= 50;
	public static inline var NUMBER_3	= 51;
	public static inline var NUMBER_4	= 52;
	public static inline var NUMBER_5	= 53;
	public static inline var NUMBER_6	= 54;
	public static inline var NUMBER_7	= 55;
	public static inline var NUMBER_8	= 56;
	public static inline var NUMBER_9	= 57;

	public static inline var NUMPAD_0	= 96;
	public static inline var NUMPAD_1	= 97;
	public static inline var NUMPAD_2	= 98;
	public static inline var NUMPAD_3	= 99;
	public static inline var NUMPAD_4	= 100;
	public static inline var NUMPAD_5	= 101;
	public static inline var NUMPAD_6	= 102;
	public static inline var NUMPAD_7	= 103;
	public static inline var NUMPAD_8	= 104;
	public static inline var NUMPAD_9	= 105;

	public static inline var A			= 65;
	public static inline var B			= 66;
	public static inline var C			= 67;
	public static inline var D			= 68;
	public static inline var E			= 69;
	public static inline var F			= 70;
	public static inline var G			= 71;
	public static inline var H			= 72;
	public static inline var I			= 73;
	public static inline var J			= 74;
	public static inline var K			= 75;
	public static inline var L			= 76;
	public static inline var M			= 77;
	public static inline var N			= 78;
	public static inline var O			= 79;
	public static inline var P			= 80;
	public static inline var Q			= 81;
	public static inline var R			= 82;
	public static inline var S			= 83;
	public static inline var T			= 84;
	public static inline var U			= 85;
	public static inline var V			= 86;
	public static inline var W			= 87;
	public static inline var X			= 88;
	public static inline var Y			= 89;
	public static inline var Z			= 90;

	public static inline var F1			= 112;
	public static inline var F2			= 113;
	public static inline var F3			= 114;
	public static inline var F4			= 115;
	public static inline var F5			= 116;
	public static inline var F6			= 117;
	public static inline var F7			= 118;
	public static inline var F8			= 119;
	public static inline var F9			= 120;
	public static inline var F10		= 121;
	public static inline var F11		= 122;
	public static inline var F12		= 123;
	// Extended F keys
	public static inline var F13		= 124;
	public static inline var F14		= 125;
	public static inline var F15		= 126;
	public static inline var F16		= 127;
	public static inline var F17		= 128;
	public static inline var F18		= 129;
	public static inline var F19		= 130;
	public static inline var F20		= 131;
	public static inline var F21		= 132;
	public static inline var F22		= 133;
	public static inline var F23		= 134;
	public static inline var F24		= 135;

	public static inline var NUMPAD_MULT = 106;
	public static inline var NUMPAD_ADD	= 107;
	public static inline var NUMPAD_ENTER = 108;
	public static inline var NUMPAD_SUB = 109;
	public static inline var NUMPAD_DOT = 110;
	public static inline var NUMPAD_DIV = 111;

	public static inline var MOUSE_LEFT = 0;
	public static inline var MOUSE_RIGHT = 1;
	public static inline var MOUSE_MIDDLE = 2;
	public static inline var MOUSE_BACK = 3;
	public static inline var MOUSE_FORWARD = 4;

	/** Contains mouse buttons IDs that were just pushed. **/
	public static var aJustPushed(default,null):Array<Int> = new Array();
	/** Contains mouse buttons IDs that are currently pushed. **/
	public static var aPushed(default,null):Array<Int> = new Array();
	/** Contains mouse button IDs that were just released. **/
	public static var aReleased(default,null):Array<Int> = new Array();
	/** Contains mouse button IDs that were just clicked. **/
	public static var aClicked(default,null):Array<Int> = new Array();

	/** Contains key IDs that were just pressed. **/
	public static var aKeyJustDown(default,null):Array<Int> = new Array();
	/** Contains key IDs that are currently pressed. **/
	public static var aKeyDown(default,null):Array<Int> = new Array();
	/** Contains key IDs that were just released. **/
	public static var aKeyUp(default,null):Array<Int> = new Array();

	/**
	 * Contains key IDs that will be ignored until next frame. Ignored keys never returns
	 * `true` from this class's functions, but they are still detected and stored in this class's variables.
	 **/
	public static var ignoredKeys(default, null):Array<Int> = [];
	
	/** Checks whether a key/mouse button was just pressed. Example: `nb.Key.isPressed(nb.Key.MOUSE_LEFT)`. **/
	public static function isPressed(code:Int):Bool
		return (aKeyJustDown.contains(code) || aPushed.contains(code)) && !ignoredKeys.contains(code);

	/** Checks whether a key/mouse button is currently pressed. Example: `nb.Key.isDown(nb.Key.MOUSE_LEFT)`. **/
	public static function isDown(code:Int):Bool
		return (aKeyDown.contains(code) || aPushed.contains(code)) && !ignoredKeys.contains(code);

	/** Checks whether a key/mouse button was just released. Example: `nb.Key.isReleased(nb.Key.MOUSE_LEFT)`. **/
	public static function isReleased(code:Int):Bool
		return (aKeyUp.contains(code) || aReleased.contains(code)) && !ignoredKeys.contains(code);

	/**
	 * Checks whether a mouse button is currently pressed. Example: `nb.Key.mouseButtonDown(nb.Key.MOUSE_LEFT)`.
	 *
	 * @param buttonId The mouse button to check. If `null` all mouse buttons are checked.
	 * @return `true` if currently pressed, `false` otherwise.
	 **/
	public static inline function mouseButtonDown(?buttonId:Int):Bool
		return buttonId == null ? aPushed.length > 0 : aPushed.contains(buttonId);

	/**
	 * Checks whether a mouse button were just released. Example: `nb.Key.mouseButtonReleased(nb.Key.MOUSE_LEFT)`.
	 *
	 * @param buttonId The mouse button to check. If `null` all mouse buttons are checked.
	 * @return `true` if just released, `false` otherwise.
	 **/
	public static inline function mouseButtonReleased(?buttonId:Int):Bool
		return buttonId == null ? aReleased.length > 0 : aReleased.contains(buttonId);
	
	/**
	 * Adds a key code to be ignored until next frame. Ignored keys never returns
	 * `true` from this class's functions, but they are still detected and stored in this class's variables.
	 **/
	public static inline function ignoreKey(code:Int) ignoredKeys.push(code);
}