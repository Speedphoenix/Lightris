
import hxd.Key as K;
using Extensions;
using Const;

// TODO TOMORROW
// force piece to have at least two blocks connected
// piece should have exits on different directions, on at least two blocks
// make target/goal block or checkpoint

class SceneObject extends h2d.Object implements h2d.domkit.Object {
	public function new(?parent) {
		super(parent);
		initComponent();
	}
}
class SceneBitmap extends h2d.Bitmap implements h2d.domkit.Object {
	public function new(?tile : h2d.Tile, ?parent : h2d.Object) {
		super(tile, parent);
		initComponent();
	}
}

enum RandomMode {
	FullRandom;
	Bag;
}

class RandomProvider {
	var rnd: hxd.Rand;
	var mode: RandomMode;
	var max = Const.MINO_COUNT;
	var all: Array<Int>;
	var currBag: Array<Int> = [];

	public function new(rnd, mode) {
		this.rnd = rnd;
		this.mode = mode;
		all = [for (i in 0...max) i];
	}

	public function getNext() {
		switch (mode) {
			case FullRandom:
				return rnd.random(max);
			case Bag:
				if (currBag.isEmpty()) {
					for (i in all)
						currBag.push(i);
				}
				var ret = currBag[rnd.random(currBag.length)];
				currBag.remove(ret);
				return ret;
		}
	}
}

class Block {
	// static public final SIDE = 40;

	public var x: Int;
	public var y: Int;
	public var obj: SceneObject;
	var roadBmp: SceneBitmap;
	var inf: Data.Mino;
	public var rotation: Direction = Up;
	//					top	   right  bottom left
	public var roads = [false, false, false, false];

	public var on = false;

	public function new(x, y, inf: Data.Mino, ?parent) {
		this.inf = inf;
		obj = new SceneObject(parent);
		var bg = new SceneBitmap(inf.gfx.toTile(), obj);
		roadBmp = new SceneBitmap(null, obj);
		this.on = alwaysOn();

		obj.dom.addClass("block");
		this.x = x;
		this.y = y;
		updatePos();
	}

	public function updatePos() {
		obj.x = x * Const.SIDE;
		obj.y = (y + 1) * Const.SIDE * -1;

		var roadInf = Data.road.all.find(function(r) {
			for (i in 0...roads.length) {
				if (r.match[i].v != hasDir(i))
					return false;
			}
			return true;
		});
		if (roadInf != null)
			roadBmp.tile = on ? roadInf.activeGfx.toTile() : roadInf.gfx.toTile();
		roadBmp.visible = roadInf != null;
	}

	public function hasDir(i: Direction) {
		i = i.rotateBy(-rotation);
		return roads[i];
	}

	public function alwaysOn() {
		return inf.flags.has(AlwaysOn);
	}
}

class Piece {
	public var obj: SceneObject;
	public var blocks: Array<Block> = [];
	public var x: Int;
	public var y: Int;
	public var inf: Data.Mino;
	public var rotation: Direction = Up;

	public function new(i: Int, ?parent) {
		obj = new SceneObject(parent);
		inf = Data.mino.all[i];
		obj.dom.addClass(inf.id.toString().toLowerCase());
		blocks = [for (b in inf.blocks) new Block(b.x, b.y, inf, obj)];
		var stamp = haxe.Timer.stamp();
		shuffleRoads();
		var tries = 0;
		while (!areRoadsValid()) {
			tries++;
			shuffleRoads();
			if (tries > 1000)
				break;
		}
		var elapsed = haxe.Timer.stamp() - stamp;
		trace('Block ${inf.id} took $tries tries to find ($elapsed s). Valid: ${areRoadsValid()}');
		x = 4;
		y = Const.BOARD_HEIGHT - 1;
		updatePos();
	}

	public function savePos() {
		return {
			prevBlocks: [for (b in blocks) {x: b.x, y: b.y}],
			prevPos: {x: x, y: y},
			prevRotation: rotation,
		};
	}
	public function loadPos(save) {
		x = save.prevPos.x;
		y = save.prevPos.y;
		for (i in 0...save.prevBlocks.length) {
			blocks[i].x = save.prevBlocks[i].x;
			blocks[i].y = save.prevBlocks[i].y;
			blocks[i].rotation = save.prevRotation;
		}
		rotation = save.prevRotation;
	}

	var pivotG = null;
	public function updatePos() {
		obj.x = x * Const.SIDE;
		obj.y = y * Const.SIDE * -1;
		for (b in blocks)
			b.updatePos();
		#if debug
		if (pivotG == null)
			pivotG = new h2d.Graphics(obj);
		var px = inf.pivot.x;
		var py = inf.pivot.y;
		pivotG.clear();
		pivotG.lineStyle(2, 0x00FF40);
		pivotG.drawCircle(Const.SIDE * (px + 0.5), Const.SIDE * (-py - 0.5), 10);
		#end
	}

	public function rotate(ccw: Bool) {
		var px = inf.pivot.x;
		var py = inf.pivot.y;
		for (b in blocks) {
			var dx = b.x - px;
			var dy = b.y - py;
			var nx;
			var ny;
			if (ccw) {
				nx = Math.round(-dy + px);
				ny = Math.round(dx + py);
			} else {
				nx = Math.round(dy + px);
				ny = Math.round(-dx + py);
			}
			b.x = nx;
			b.y = ny;
		}

		rotation = rotation.rotateBy(ccw ? -1 : 1);
		for (b in blocks) {
			b.rotation = rotation;
		}
	}

	function shuffleRoads() {
		inline function randBool() {
			return Lightris.rnd.random(2) == 0;
		}
		for (b in blocks) {
			for (i in 0...4) {
				b.roads[i] = randBool();
			}
		}
	}

	function checkRec(curr: Block, toCheck: Array<Block>, exits: Array<Array<Bool>>) {
		toCheck.remove(curr);
		var currIdx = blocks.indexOf(curr);
		for (k in 0...4) {
			var r: Direction = k;
			if (!curr.hasDir(r))
				continue;
			var i = curr.x;
			var j = curr.y;
			switch (r) {
				case Up: 	j++;
				case Right:	i++;
				case Down:	j--;
				case Left:	i--;
			}
			var to = blocks.find(b -> b.x == i && b.y == j);
			if (to == null) {
				exits[currIdx][k] = true;
			} else {
				// unterminated road inside
				if (!to.hasDir(r.rotateBy(2)))
					return false;
				if (toCheck.has(to)) {
					var check = checkRec(to, toCheck, exits);
					if (!check)
						return false;
				}
			}
		}
		return true;
	}
	public function areRoadsValid() {
		var roadedBlocks = blocks.filter(b -> b.roads.count(r -> r) > 0);
		if (roadedBlocks.length < Const.MIN_ROADED_PER_PIECE)
			return false;
		if (roadedBlocks.any(b -> b.roads.count(r -> r) == 1))
			return false;
		var toCheck = roadedBlocks.copy();
		var exits = [for (i in 0...blocks.length) [for (i in 0...4) false]];
		var check = checkRec(toCheck[0], toCheck, exits);
		if (!check)
			return false;
		if (toCheck.length > 0) // unconnected block inside
			return false;
		var found = 0;
		for (i in 0...exits.length) {
			for (j in 0...exits[i].length) {
				if (exits[i][j]) {

					for (i2 in (i + 1)...exits.length) {
						for (j2 in 0...exits[i2].length) {
							if (j2 == j)
								continue;
							if (exits[i2][j2])
								found++;
							if (found > Const.MIN_SEPARATE_EXITS) break;
						}
						if (found > Const.MIN_SEPARATE_EXITS) break;
					}
				}
				if (found > Const.MIN_SEPARATE_EXITS) break;
			}
			if (found > Const.MIN_SEPARATE_EXITS) break;
		}
		if (found < Const.MIN_SEPARATE_EXITS)
			return false;

		return true;
	}
}


class Lightris extends hxd.App {

	var gridCont : SceneObject;
	var gridGraphics : h2d.Graphics;
	var boardObj : SceneObject;
	var tf : h2d.Text;

	// 0, 0 is bottom LEFT
	var board: Array<Array<Block>> = [];
	var current: Piece = null;
	// public static final BOARD_WIDTH = 10;
	// public static final BOARD_HEIGHT = 20;
	// public static final BOARD_TOP_EXTRA = 3;
	// public static final BOARD_FULL_HEIGHT = BOARD_HEIGHT + BOARD_TOP_EXTRA;

	var seed = Std.random(0x7FFFFFFF);
	public static var rnd: hxd.Rand;
	var bag: RandomProvider;
	public static var style : h2d.domkit.Style;

	override function init() {
		var cdbData = hxd.Res.data.entry.getText();
		Data.load(cdbData, false);
		hxd.Res.data.watch(function() {
			var cdbData = hxd.Res.data.entry.getText();
			Data.load(cdbData, true);
		});

		trace("Seed: " + seed);
		rnd = new hxd.Rand(seed);
		bag = new RandomProvider(rnd, Bag);
		// creates a new object and put it at the center of the sceen
		gridCont = new SceneObject(s2d);

		style = new h2d.domkit.Style();
		style.allowInspect = #if debug true #else false #end;
		style.addObject(gridCont);
		gridCont.dom.addClass("root");
		// gridCont.dom = domkit.Properties.create("object", gridCont, {"class": "root"});

		gridGraphics = new h2d.Graphics(gridCont);
		drawGrid(gridGraphics);
		boardObj = new SceneObject(gridCont);
		boardObj.dom.addClass("board");
		boardObj.y = Const.BOARD_FULL_HEIGHT * Const.SIDE;
		clearBoard();
		onResize();
	}

	function drawGrid(g: h2d.Graphics) {
		g.clear();

		g.lineStyle(2, 0xF8DCC1);
		g.moveTo(0, Const.BOARD_TOP_EXTRA * Const.SIDE);
		g.lineTo(0, (Const.BOARD_HEIGHT + Const.BOARD_TOP_EXTRA) * Const.SIDE);
		g.lineTo(Const.BOARD_WIDTH * Const.SIDE, (Const.BOARD_HEIGHT + Const.BOARD_TOP_EXTRA) * Const.SIDE);
		g.lineTo(Const.BOARD_WIDTH * Const.SIDE, Const.BOARD_TOP_EXTRA * Const.SIDE);
		g.lineTo(0, Const.BOARD_TOP_EXTRA * Const.SIDE);

		g.lineStyle(1, 0xF8DCC1);
		for (i in 1...Const.BOARD_WIDTH) {
			g.moveTo(i * Const.SIDE, Const.BOARD_TOP_EXTRA * Const.SIDE);
			g.lineTo(i * Const.SIDE, Const.BOARD_FULL_HEIGHT * Const.SIDE);
		}
		for (i in 1...Const.BOARD_HEIGHT) {
			g.moveTo(0, (i + Const.BOARD_TOP_EXTRA) * Const.SIDE);
			g.lineTo(Const.BOARD_WIDTH * Const.SIDE, (i + Const.BOARD_TOP_EXTRA) * Const.SIDE);
		}
		g.lineStyle();
	}

	function nextMino() {
		if (current != null)
			current.obj.remove();
		current = new Piece(bag.getNext(), boardObj);
	}
	function collides(m: Piece, offsetx = 0, offsety = 0) {
		for (b in m.blocks) {
			var x = b.x + m.x + offsetx;
			var y = b.y + m.y + offsety;
			if (x < 0 || x >= board.length || y < 0)
				return true;
			if (board[x][y] != null)
				return true;
		}
		return false;
	}
	function lockCurrent(m: Piece) {
		for (b in m.blocks) {
			var x = b.x + m.x;
			var y = b.y + m.y;
			board[x][y] = b;
			boardObj.addChild(b.obj);
			b.x = x;
			b.y = y;
			b.updatePos();
		}
		updateConnections();
	}
	function hardDrop() {
		var prev = 0;
		for (i in 1...(current.y + 1)) {
			if (collides(current, 0, -i)) {
				break;
			}
			prev = i;
		}
		current.y -= prev;
		lockCurrent(current);
		nextMino();
	}
	function rotate(ccw: Bool) {
		var initial = current.savePos();
		var from = current.rotation;
		current.rotate(ccw);
		var to = current.rotation;
		var r = current.inf.rotation.rotate.find(r -> r.from == from && r.to == to);
		var found = false;
		for (t in r.tests) {
			var inter = current.savePos();
			current.x += t.x;
			current.y += t.y;
			if (collides(current)) {
				current.loadPos(inter);
			} else {
				found = true;
				break;
			}
		}
		if (found)
			current.updatePos();
		else
			current.loadPos(initial);
	}
	function clearBoard() {
		for (i in 0...board.length) {
			for (j in 0...board[i].length) {
				if (board[i][j] != null)
					board[i][j].obj.remove();
			}
		}
		if (current != null)
			current.obj.remove();

		board = [for (i in 0...Const.BOARD_WIDTH) [for (j in 0...Const.BOARD_FULL_HEIGHT) null]];
		nextMino();

		var source = new Block(4, 0, Data.mino.get(Source), boardObj);
		source.roads = [true, true, false, true];
		board[4][0] = source;
		source.updatePos();
		source = new Block(5, 0, Data.mino.get(Source), boardObj);
		source.roads = [true, true, false, true];
		board[5][0] = source;
		source.updatePos();
	}

	function fillRec(x: Int, y: Int) {
		var b = board[x][y];
		for (k in 0...4) {
			var r: Direction = k;
			var i = b.x;
			var j = b.y;
			switch (r) {
				case Up: 	j++;
				case Right:	i++;
				case Down:	j--;
				case Left:	i--;
			}
			if (i < 0 || i > Const.BOARD_WIDTH || j < 0 || j > Const.BOARD_HEIGHT)
				continue;
			if (board[i][j] == null)
				continue;
			if (!b.hasDir(r) || board[i][j].on || !board[i][j].hasDir(r.rotateBy(2)))
				continue;
			board[i][j].on = true;
			fillRec(i, j);
		}
	}
	function updateConnections() {
		var starts = [];
		for (i in 0...board.length) {
			for (j in 0...board[i].length) {
				if (board[i][j] != null) {
					if (board[i][j].alwaysOn())
						starts.push(board[i][j]);
					else
						board[i][j].on = false;
				}
			}
		}
		for (s in starts)
			fillRec(s.x, s.y);
		for (i in 0...board.length) {
			for (j in 0...board[i].length) {
				if (board[i][j] != null) {
					board[i][j].updatePos();
				}
			}
		}
	}

	function move(by: Int) {
		if (!collides(current, by, 0)) {
			current.x += by;
			current.updatePos();
		}
	}

	function updateMove(dt: Float) {
		final REPEAT_DELAY = 0.033;
		final DAS_DELAY = 0.15;
		static var prevDir = 0;
		static var hasDas = false;
		static var accum = 0.;
		var dir = 0;
		if (K.isDown(K.D))
			dir++;
		if (K.isDown(K.Q))
			dir--;

		if (K.isPressed(K.D)) {
			move(1);
			hasDas = false;
			accum = 0;
			prevDir = 1;
		}
		if (K.isPressed(K.Q)) {
			move(-1);
			hasDas = false;
			accum = 0;
			prevDir = -1;
		}
		if (dir != 0) {
			accum += dt;
			if ((hasDas && accum >= REPEAT_DELAY) || (!hasDas && accum >= DAS_DELAY)) {
				hasDas = true;
				move(dir);
			}
		}
	}
	function updateSoftDrop(dt: Float) {
		final REPEAT_DELAY = 0.05;
		static var accum = 0.;
		if (K.isDown(K.S)) {
			if (accum == 0 || accum > REPEAT_DELAY)
				softDrop();
			accum += dt;
		}
		else
			accum = 0;
	}
	function softDrop() {
		if (!collides(current, 0, -1)) {
			current.y -= 1;
			current.updatePos();
		}
	}
	override function update(dt:Float) {
		if (current == null)
			nextMino();
		if (K.isPressed(K.R)) {
			clearBoard();
		}
		if (K.isPressed(K.Z)) {
			hardDrop();
		}
		if (K.isPressed(K.RIGHT)) {
			rotate(false);
		}
		if (K.isPressed(K.DOWN)) {
			rotate(true);
		}
		updateSoftDrop(dt);
		updateMove(dt);
	}

	override function onResize() {
		trace("resize", s2d.width, s2d.height);
		gridCont.x = Std.int(s2d.width / 2) - ((Const.BOARD_WIDTH / 2) * Const.SIDE);
	}
	static function main() {
		hxd.Res.initEmbed();
		new Lightris();
	}

}