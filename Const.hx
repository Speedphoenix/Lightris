import hxd.Key as K;

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

typedef InputConfig = {
	left: Int,
	right: Int,
	softDrop: Int,
	hardDrop: Int,
	rotateRight: Int,
	rotateLeft: Int,
	hold: Int,
}

@:publicFields class Const {
	// Minimum blocks that need to have roads on a piece
    static final MIN_ROADED_PER_PIECE = 3;
	// Sets of road exits on a mino that are on separate blocks and different directions
    static final MIN_SEPARATE_EXITS = 2;
	// Maximum blocks that can have exits on a piece
	static final MAX_EXIT_BLOCKS = 2;
	static final MIN_EXIT_BLOCKS = 2;

	// static final MIN_ROADED_PER_PIECE = 4;
	// static final MAX_EXIT_BLOCKS = 3;

	static final USE_DEFAULT_ROADS = true;

    static final MINO_COUNT = 7;
	static final NEXT_QUEUE_SIZE = 5;
	static final FIRST_TARGET_LINE = 12;
	static final TARGET_LINE_SPACING = 7;
	static final TARGET_COL_MIN = 1;
	static final TARGET_COL_MAX = 3;

    static final SIDE = 32;
    static final BOARD_WIDTH = 10;
	static final BOARD_HEIGHT = 20;
	static final BOARD_TOP_EXTRA = 3;
	static final BOARD_FULL_HEIGHT = BOARD_HEIGHT + BOARD_TOP_EXTRA;

	static final SD_DELAY = 0.05;
	static final ARR = 0.033;
	static final DAS = 0.15;

	static final ROAD_PULSE_FREQUENCY = 1;
	static final ROAD_PULSE_AMOUNT = 0.2;
	static final REGULAR_UPDATE_DT = 0.5;

	static final wasdConfig: InputConfig = {
		left: K.Q,
		right: K.D,
		softDrop: K.S,
		hardDrop: K.W,
		rotateRight: K.RIGHT,
		rotateLeft: K.DOWN,
		hold: K.UP,
	};
	static final zqsdConfig: InputConfig = {
		left: K.Q,
		right: K.D,
		softDrop: K.S,
		hardDrop: K.Z,
		rotateRight: K.RIGHT,
		rotateLeft: K.DOWN,
		hold: K.UP,
	};
	static final baseConfig: InputConfig = {
		left: K.LEFT,
		right: K.RIGHT,
		softDrop: K.DOWN,
		hardDrop: K.SPACE,
		rotateRight: K.UP,
		rotateLeft: K.Z,
		hold: K.C,
	};
	static var config = zqsdConfig; // baseConfig;
}