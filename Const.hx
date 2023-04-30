enum abstract Direction(Int) from Int to Int{
	var Up = 0;
	var Right = 1;
	var Down = 2;
	var Left = 3;

	public inline function rotateBy(i: Int): Direction {
		var a = this + i;
		if (a < 0)
			a += 4;
		a %= 4;
		return a;
	}
}

@:publicFields class Const {
    static var MIN_ROADED_PER_PIECE = 2;
    static var MIN_SEPARATE_EXITS = 1;

    static var MINO_COUNT = 7;

    static var SIDE = 40;
    static var BOARD_WIDTH = 10;
	static var BOARD_HEIGHT = 20;
	static var BOARD_TOP_EXTRA = 3;
	static var BOARD_FULL_HEIGHT = BOARD_HEIGHT + BOARD_TOP_EXTRA;
}