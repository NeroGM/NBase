package nb.utils;

typedef Pos = {x:Float,y:Float};
typedef Size = {w:Float,h:Float};
typedef Area = {x:Float,y:Float,w:Float,h:Float};
typedef PosI = {x:Int,y:Int};
typedef SizeI = {w:Int,h:Int};
typedef AreaI = {x:Int,y:Int,w:Int,h:Int};

typedef HL_Int = #if (!macro && hl) hl.Ref<Int> #else {} #end;