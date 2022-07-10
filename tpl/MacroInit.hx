package;

import nb.fs.*;

class MacroInit {
	/**
	 * This function is called in config.hxml via initialization macro. That means
	 * this function will be executed very early in compilation, which is useful if
	 * you need to set some variables that are used in a shared context.
	 *
	 * @see https://haxe.org/manual/macro-initialization.html
	 **/
    static function init() {
		initConverter();
	}

	/**
	 * Converters added to `nb.fs.ConvertManager` in this function will be accessible
	 * when an `nb.fs.FileSystem` instance is making data files.
	 **/
	static function initConverter() {
		ConverterManager.addConverter(new Converter(["png"],["png2"],(bytes,_)->bytes));
	}
}