
import hxd.Key as K;
import h2d.col.Point;
using Extensions;
using Const;
using Main;

// TODO TOMORROW
// Menu principal + credits
// 		How to play (controls, objective, clearing a line doesn't do anything)
// 		Make all the texts images?
// garbage
// better generated pieces?
// fix that L rotation on the rotation table
// increase level, display level
// display the current difficulty
// getting locked feedback
// pausing the game
// limit soft drop lock increase when softdropping

// for better generated pieces:
// generate all possibles during startup
// assign weight on number of exits and road types (4-roads should be rarer)
// low exits and high exits should be rare
// maybe allow separate paths if it's 2 and 2 ?


// TOMORROW for generated pieces generate all on init

enum RandomMode {
	FullRandom;
	Bag;
}

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

enum LossReason {
	TopOut;
	ConnectionLost;
	AnimalLost;
}

class ResultUi extends h2d.Flow implements h2d.domkit.Object {
	static var SRC = <result-ui
		background={BoardUi.panelBG}
		position="absolute"
		align="middle middle"
		content-align="middle middle"
		layout="vertical"
		spacing="15"
		padding="20"
	>
		<text class="title" text={title}
			font={Main.font}
			scale="2"
		/>
		<text class="desc" text={desc}/>
		<text class="desc2" text={desc2}/>
		<flow id="buttons"
			spacing="20"
		/>
	</result-ui>

	public function new(isWin: Bool, ?reason: LossReason, ?parent) {
		super(parent);
		var title = isWin ? "VICTORY" : "DEFEAT";
		var desc = "";
		var desc2 = "";
		var score = Board.inst.score;
		if (isWin) {
			if (Board.inst.targetCount <= 0) {
				desc = 'You have delivered $score animals!';
			} else {
				var max = Board.inst.targetCount + Board.inst.finalTargets.length;
				if (max == score)
					desc = 'You have delivered all $score animals!';
				else
					desc = 'You have delivered $score animals out of $max!';
			}
		} else {
			switch (reason) {
				case TopOut:
					title = "VICTORY";
					desc = 'You have delivered $score animals!';
					// desc = "You topped out";
				case ConnectionLost:
					desc = "You lost the road connection";
				case AnimalLost:
					desc = "You left an animal behind";
				case null:
					desc = "You have lost";
			}
			var desc2 = "Animals freed: " + score;
		}
		initComponent();
		var back = new Button("Back", buttons);
		back.onClick = Main.inst.menu.onBack;
		var retry = new Button("Retry", buttons);
		retry.onClick = Main.inst.board.clearBoard;
		background.tileCenter = true;
		background.tileBorders = true;
	}
}

@:uiComp("board-ui")
class BoardUi extends h2d.Flow implements h2d.domkit.Object {
    static var SRC = <board-ui
		fill-width={true}
		content-halign={h2d.Flow.FlowAlign.Middle}
		content-valign={h2d.Flow.FlowAlign.Top}
		spacing={{x: 10, y: 0}}
	>
		<flow class="left-cont"
			margin-top={topMargin}
			fill-height={true}
			layout={h2d.Flow.FlowLayout.Vertical}
			valign={h2d.Flow.FlowAlign.Top}
			spacing={{x: 0, y: pad}}
			height={boardHeight}
		>
			<flow class="hold-cont" id
				valign={h2d.Flow.FlowAlign.Top}
				background={panelBG}
				padding={padding}
				layout={h2d.Flow.FlowLayout.Vertical}
				content-halign={h2d.Flow.FlowAlign.Middle}
				spacing={{x: 0, y: pad}}
			>
				<text text={"HOLD"}
					font={Main.font}
					scale="2"
				/>
				<flow id="currHold" public
					min-width={pieceWidth}
					min-height={pieceHeight}
					offset-x={Const.SIDE}
				/>
			</flow>
			<flow class="score-cont" id
				align="middle right"
				background={panelBG}
				padding={padding}
				layout={h2d.Flow.FlowLayout.Vertical}
				content-halign={h2d.Flow.FlowAlign.Right}
				spacing={{x: 0, y: 15}}
				min-width={168}
				min-height={140}
				margin-left="-600"
			>
				<text id="score"
					font={Main.font}
					scale="2"
				/>
				<flow id="animalsCont"
					spacing={{x: 5, y: 0}}
					valign={h2d.Flow.FlowAlign.Bottom}
					content-align="middle right"
					max-width="280"
					multiline="true"
				/>
			</flow>
		</flow>
		<flow class="center-cont" id public
			width={Const.BOARD_WIDTH * Const.SIDE}
			height={Const.BOARD_FULL_HEIGHT * Const.SIDE}
		>
			<flow class="board-cont" id public
				position="absolute"
			/>
		</flow>
		<flow class="next-cont" id
			valign={h2d.Flow.FlowAlign.Top}
			background={panelBG}
			margin-top={topMargin}
			padding={padding}
			spacing={{x: 0, y: pad}}
			layout={h2d.Flow.FlowLayout.Vertical}
			content-halign={h2d.Flow.FlowAlign.Middle}
		>
			<text text={"NEXT"}
				font={Main.font}
				scale="2"
			/>
			${for (i in 0...Const.NEXT_QUEUE_SIZE) {
				<flow id="nextPieces[]" public
					min-width={pieceWidth}
					min-height={pieceHeight}
					offset-x={Const.SIDE}
				/>
			}}
		</flow>
	</board-ui>
	public static var panelBG = null;

    public function new(?parent) {
		panelBG = {
			tile : hxd.Res.panel_bg.toTile(),
			borderL : 4,
			borderT : 4,
			borderR : 4,
			borderB : 4,
		};
		super(parent);

		var topMargin = Const.BOARD_TOP_EXTRA * Const.SIDE - 3;
		var pieceWidth = 4 * Const.SIDE;
		var pieceHeight = 2 * Const.SIDE;
		var pad = 20;
		var padding = {
			top: pad,
			right: pad,
			bottom: pad - 1, // mod 4
			left: pad,
		};
		var boardHeight = Const.BOARD_HEIGHT * Const.SIDE;

		initComponent();
		holdCont.background.tileCenter = true;
		nextCont.background.tileCenter = true;
		scoreCont.background.tileCenter = true;
		holdCont.background.tileBorders = true;
		nextCont.background.tileBorders = true;
		scoreCont.background.tileBorders = true;

		setScore(0);
	}

	public function setScore(v: Int) {
		if (Board.inst.targetCount <= 0) {
			score.text = 'SCORE: $v';
		} else {
			var max = Board.inst.targetCount;
			max += Board.inst.finalTargets.count(t -> t.on);
			score.text = 'SCORE: $v/$max';
		}
	}
	public function setAnimals(arr: Array<Data.Animal>) {
		animalsCont.removeChildren();
		for (a in arr) {
			new SceneBitmap(a.gfx.toTile(), animalsCont);
		}
	}
}

class RandomProvider {
	var rnd: hxd.Rand;
	var mode: RandomMode;
	var max: Int;
	var all: Array<Int>;
	var currBag: Array<Int> = [];

	public function new(rnd, mode, max) {
		this.rnd = rnd;
		this.mode = mode;
		this.max = max;
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

class Truck {
	public var x: Float; // center of the truck
	public var y: Float;
	public var obj: SceneObject;
	var bmp: SceneBitmap;
	var lightsBmp: SceneBitmap;
	var tile: h2d.Tile;
	var lightTile: h2d.Tile;
	var lightsTime = 0.;
	var rotation(default, set): Direction;
	var isMoving(get, never): Bool;
	function get_isMoving() {
		return !currPath.isEmpty();
	}

	public var tx(get, never): Int;
	function get_tx() {
		return hxd.Math.floor(x / Const.SIDE);
	}
	public var ty(get, never): Int;
	function get_ty() {
		return hxd.Math.floor(y / Const.SIDE);
	}

	function set_rotation(v) {
		tile.setPosition(v * 8, 0);
		lightTile.setPosition(v * 8, 0);
		return rotation = v;
	}

	public function new(start: Block, ?parent) {
		obj = new SceneObject(parent);
		tile = hxd.Res.SpriteSheetCamion.toTile();
		tile.setSize(8, 8);
		lightTile = hxd.Res.TruckLights.toTile();
		lightTile.setSize(8, 8);
		this.rotation = Right;
		bmp = new SceneBitmap(tile, obj);
		lightsBmp = new SceneBitmap(lightTile, obj);
		obj.dom.addClass("truck");
		var p = getPos(start);
		this.x = p.x;
		this.y = p.y;
	}
	inline function getPos(b: Block) {
		var p = new Point((b.x + 0.5) * Const.SIDE, (b.y + 0.5) * Const.SIDE);
		if (b.inf.flags.has(IsCasernL)) {
			p.x += 9;
			p.y -= 1;
		} else if (b.inf.flags.has(IsCasernR)) {
			p.x -= 9;
			p.y -= 1;
		}
		return p;
	}

	var currTarget: Block = null;
	var currPath: Array<Point> = [];
	public function update(dt: Float) {
		var target = Board.inst.highestOnBlock;
		if (
			target != null
			&& target.inf.id != SourceL
			&& target.inf.id != SourceR
			&& target != currTarget
			&& (!isMoving || !currTarget.inf.flags.has(ForceTruck))
		) {
			currTarget = target;
			buildPath();
		}
		var range = Const.TRUCK_SPEED * dt;
		var prevx = x;
		var prevy = y;
		while (range > 0 && !currPath.isEmpty()) {
			var step = currPath.last();
			var pos = new Point(x, y);
			var d = step.distance(pos);
			if (range >= d) {
				x = step.x;
				y = step.y;
				range -= d;
				currPath.pop();
			} else {
				var dir = step.sub(pos);
				dir.normalize();
				dir.scale(range);
				var newPos = pos.add(dir);
				x = newPos.x;
				y = newPos.y;
				range = -1;
			}
		}
		if (prevx < x)
			rotation = Right;
		else if (prevx > x)
			rotation = Left;
		else if (prevy < y)
			rotation = Up;
		else if (prevy > y)
			rotation = Down;
		obj.x = x - 4;
		obj.y = y * -1 - 4;
		if (isMoving) {
			lightsBmp.visible = true;
			var side = Math.round(lightsTime * Const.TRUCK_LIGHTS_FREQUENCY) % 2;
			lightTile.setPosition(rotation * 8, side * 8);
			lightsTime += dt;
		} else {
			lightsBmp.visible = false;
			lightsTime = 0;
		}
	}
	function buildRec(x: Int, y: Int) {
		var board = Board.inst;
		var b = board.board[x][y];
		if (b == currTarget)
			return true;
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
			if (i < 0 || i >= Const.BOARD_WIDTH || j < 0 || j >= board.boardMax())
				continue;
			if (board.blockIsEmpty(i, j))
				continue;
			var curr = board.board[i][j];
			if (!b.hasDir(r) || !curr.on || curr.pathFrom != null || !curr.hasDir(r.rotateBy(2)))
				continue;
			curr.pathFrom = b;
			if (buildRec(i, j))
				return true;
		}
		return false;
	}
	function buildPath() {
		var b = Board.inst;
		currPath.clear();
		var start = b.board[tx][ty];
		if (b.blockIsEmpty(tx, ty) || !start.on)
			return;
		for (i in 0...b.board.length) {
			for (j in 0...b.board[i].length) {
				if (!b.blockIsEmpty(i, j)) {
					b.board[i][j].pathFrom = null;
				}
			}
		}
		start.pathFrom = start;
		buildRec(tx, ty);

		var curr = currTarget;
		while (curr != null && curr != curr.pathFrom && curr.pathFrom != null) {
			currPath.push(getPos(curr));
			curr = curr.pathFrom;
		}
		// possibly uncomment
		// currPath.push(getPos(curr));
	}
}


class Block {
	public var x: Int;
	public var y: Int;
	public var obj: SceneObject;
	var bg: SceneBitmap;
	var roadBmp: SceneBitmap;
	public var inf(default, set): Data.Mino;
	public var rotation: Direction = Up;
	//					top	   right  bottom left
	public var roads = [false, false, false, false];

	public var on(default, set) = false;
	public var phantomOn = false;
	public var isPhantom = false;
	public var isEmpty = false;
	public var phantomAddColor = new h3d.Vector();

	public var pathFrom: Block;

	function set_on(v) {
		if (v && inf.props.activeBlock != null) {
			inf = inf.props.activeBlock;
			updatePos();
		}
		return on = v;
	}

	public function new(x, y, inf: Data.Mino, isPhantom=false, ?parent) {
		this.isPhantom = isPhantom;
		obj = new SceneObject(parent);
		bg = new SceneBitmap(inf.gfx.toTile(), obj);
		bg.dom.addClass("block-bg");
		roadBmp = new SceneBitmap(null, obj);
		roadBmp.colorAdd = phantomAddColor;
		roadBmp.dom.addClass("road");
		this.inf = inf;
		this.on = alwaysOn();
		this.phantomOn = alwaysOn();
		this.isEmpty = inf.flags.has(Empty);

		obj.dom.addClass("block");
		this.x = x;
		this.y = y;
		updatePos();
	}

	function set_inf(v) {
		bg.tile = v.gfx.toTile();
		if (isPhantom)
			bg.tile = v.phantom.toTile();
		roadBmp.tile = null;
		if (v.flags.has(AllRoads))
			roads = [true, true, true, true];
		return inf = v;
	}

	public function updatePos(sides = false, isPiece = false) {
		var offs = (sides && inf.props.sideOffset != null) ? inf.props.sideOffset : 0.;
		obj.x = (x + offs) * Const.SIDE;
		obj.y = (y + 1) * Const.SIDE * -1;
		if (!isPiece && !Board.inst.blockIsVisible(x, y))
			return;

		var roadInf = (inf.flags.has(HideRoads)) ? null : Data.road.all.find(function(r) {
			for (i in 0...roads.length) {
				if (r.match[i].v != hasDir(i))
					return false;
			}
			return true;
		});
		if (roadInf != null)
			roadBmp.tile = (on || phantomOn) ? roadInf.activeGfx.toTile() : roadInf.gfx.toTile();
		roadBmp.visible = roadInf != null;
		if (!phantomOn || on) {
			phantomAddColor.set(0, 0, 0);
			effectElapsed = 0;
		}
		if (inf.props.activeBlock != null) {
			if (phantomOn && !on) {
				roadBmp.tile = inf.props.activeBlock.gfx.toTile();
				roadBmp.visible = true;
			} else {
				roadBmp.visible = false;
			}
		}
		if (isPhantom) {
			roadBmp.alpha = 0.8;
		}
	}

	public function hasDir(i: Direction) {
		i = i.rotateBy(-rotation);
		return roads[i];
	}

	public function alwaysOn() {
		return inf.flags.has(AlwaysOn);
	}

	var effectElapsed = 0.;
	public function update(dt: Float) {
		if (phantomOn && !on) {
			effectElapsed += dt;
			var v = Const.ROAD_PULSE_AMOUNT * ((1 + hxd.Math.sin(effectElapsed * Const.ROAD_PULSE_FREQUENCY * 2 * hxd.Math.PI)) / 2);
			phantomAddColor.set(v, v, v);
		}
	}
}

class Piece {
	public var obj: SceneObject;
	public var blocks: Array<Block> = [];
	public var x: Int;
	public var y: Int;
	public var inf: Data.Mino;
	public var rotation: Direction = Up;
	public var follow: Piece = null;
	public var phantom: Piece = null;

	function fToString(v: Float, prec=5) {
		var p = Math.pow(10, prec);
		var val = Math.round(p * v);
		var fullDec = Std.string(val);
		var outStr = fullDec.substr(0, -prec) + '.' + fullDec.substr(fullDec.length - prec, prec);
		return outStr;
	}

	public function new(?i: Int, ?follow: Piece, ?parent) {
		obj = new SceneObject(parent);
		this.follow = follow;
		if (follow != null) {
			follow.phantom = this;
			inf = follow.inf;
			obj.dom.addClass("phantom");
			blocks = [for (b in inf.blocks) new Block(b.x, b.y, inf, true, obj)];
		} else {
			inf = Data.mino.all[i];
			blocks = [for (b in inf.blocks) new Block(b.x, b.y, inf, obj)];
			var mode = Board.inst.mode.id;
			var useDefaultRoads = inf.blocks.any(b -> b.defaultRoads.any(r -> r.modeId == mode));
			if (useDefaultRoads) {
				for (i in 0...inf.blocks.length) {
					var def = inf.blocks[i].defaultRoads.find(r -> r.modeId == mode);
					if (def != null) {
						var rds = def.roads.match;
						for (j in 0...4) {
							blocks[i].roads[j] = rds[j].v;
						}
					}
				}
			} else {
				var stamp = haxe.Timer.stamp();
				shuffleRoads();
				var tries = 0;
				while (!areRoadsValid()) {
					tries++;
					shuffleRoads();
					if (tries > 2000) {
						iterateRec(0, 0, areRoadsValid);
						break;
					}
				}
				var elapsed = haxe.Timer.stamp() - stamp;
				var elapsedStr = fToString(elapsed);
				if (tries > 2000)
					trace("TOOK ALL TRIES, FALLBACK");
				trace('Block ${inf.id} took $tries tries to find ($elapsedStr, $elapsed s). Valid: ${areRoadsValid()}');
			}
		}
		obj.dom.addClass(inf.id.toString().toLowerCase());

		// tryAll();

	}

	public function reset() {
		phantom = null;
		rotation = 0;
		for (i in 0...blocks.length) {
			var b = blocks[i];
			b.rotation = rotation;
			b.x = inf.blocks[i].x;
			b.y = inf.blocks[i].y;
		}
		x = 4;
		var spawns = Board.inst.getSpawnLines(inf.id);
		for (l in spawns) {
			y = l;
			if (!Board.inst.collides(this))
				break;
			else
				y = spawns[0];
		}
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
	public function updatePos(sides = false) {
		if (follow != null) {
			this.x = follow.x;
			this.inf = follow.inf;
			this.rotation = follow.rotation;
			for (i in 0...blocks.length) {
				var fromb = follow.blocks[i];
				var tob = blocks[i];
				tob.x = fromb.x;
				tob.y = fromb.y;
				tob.rotation = fromb.rotation;
				tob.roads = fromb.roads; // TODO keeping refs could break?
			}
		} else {
			if (phantom != null) {
				for (i in 0...blocks.length) {
					blocks[i].phantomOn = phantom.y == this.y && phantom.blocks[i].phantomOn;
				}
			}
			#if debug
			// if (pivotG == null)
			// 	pivotG = new h2d.Graphics(obj);
			// var px = inf.pivot.x;
			// var py = inf.pivot.y;
			// pivotG.clear();
			// pivotG.lineStyle(2, 0x00FF40);
			// pivotG.drawCircle(Const.SIDE * (px + 0.5), Const.SIDE * (-py - 0.5), 10);
			#end
		}
		for (b in blocks)
			b.updatePos(sides, true);
		obj.x = x * Const.SIDE;
		obj.y = y * Const.SIDE * -1;
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
			return Board.rnd.random(2) == 0;
		}
		for (b in blocks) {
			for (i in 0...4) {
				b.roads[i] = randBool();
			}
		}
	}

	function iterateRec(bi: Int, ri: Int, callb: Void -> Bool) {
		inline function iterNext() {
			return if (ri < 3) {
				iterateRec(bi, ri + 1, callb);
			} else if (bi < 3) {
				iterateRec(bi + 1, 0, callb);
			} else {
				callb();
			}
			// return false;
		}
		blocks[bi].roads[ri] = false;
		if (iterNext())
			return true;
		blocks[bi].roads[ri] = true;
		if (iterNext())
			return true;
		return false;
	}

	function tryAll() {
		var stamp = haxe.Timer.stamp();
		var valids = 0;
		var invalids = 0;
		var tries = 0;
		iterateRec(0, 0, function() {
			if (areRoadsValid())
				valids++;
			else
				invalids++;
			tries++;
			return false;
		});
		var elapsed = haxe.Timer.stamp() - stamp;
		var elapsedStr = fToString(elapsed);
		trace('Block ${inf.id} valid: $valids invalid: $invalids elapsed: ($elapsedStr) $elapsed s (total $tries)');
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
		var conf = Board.inst.mode.minoGeneration;
		if (conf == null)
			return true;
		var roadedBlocks = blocks.filter(b -> b.roads.count(r -> r) > 0);
		if (roadedBlocks.length < conf.minRoaded)
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
		var separateExitSets = 0;
		var exitBlocks = 0;
		for (i in 0...exits.length) {
			var hasExit = false;
			for (j in 0...exits[i].length) {
				if (exits[i][j]) {
					if (!hasExit) {
						exitBlocks++;
						hasExit = true;
					}

					for (i2 in (i + 1)...exits.length) {
						for (j2 in 0...exits[i2].length) {
							if (j2 == j)
								continue;
							if (exits[i2][j2])
								separateExitSets++;
						}
					}
				}
			}
		}
		if (separateExitSets < conf.minSeparateExits)
			return false;
		if (exitBlocks > conf.maxExitBlocks || exitBlocks < conf.minExitBlocks)
			return false;

		return true;
	}

	public function update(dt: Float) {
		for (b in blocks)
			b.update(dt);
	}
}


class Board {
	public static var inst: Board;

	public var gridCont : SceneObject;
	var gridGraphics : h2d.Graphics;
	var boardObj : SceneObject;
	var lockedObj : SceneObject;
	var fogObj : h2d.Flow;
	var phantomCont : SceneObject;
	var tf : h2d.Text;
	public var fullUi : BoardUi;

	// 0, 0 is bottom LEFT
	public var board: Array<Array<Block>> = [];
	var current: Piece = null;
	var phantom: Piece = null;
	var hold: Piece = null;
	var heldOnce = false;
	var nextQueue: Array<Piece> = [];
	public var mode: Data.Mode;
	var level = 1;
	public var targetCount = 1; // -1 for endless
	var currDrop = 0.; // increases per frame depending on gravity
	var currLock = 0.;
	var isLocking = false;
	var currLockReleaseCount = 0;

	var targetScroll = 0;
	var currentScroll = 0.;
	var minScroll(get, never): Int;
	function get_minScroll() {
		return hxd.Math.floor(currentScroll);
	}

	var targets: Array<Block> = [];
	var allTargets: Array<Block> = [];
	public var finalTargets: Array<Block> = [];
	var animals: Array<Data.Animal> = [];
	var animalsBag: RandomProvider;
	public var score(get, never): Int;
	function get_score() return animals.length;

	var resultUi: ResultUi;
	public var gameIsOver(get, never): Bool;
	function get_gameIsOver() {
		return resultUi != null;
	}

	public var truck: Truck;
	public var parkedTruck: Truck;
	public var highestOnBlock = null;

	var seed = Std.random(0x7FFFFFFF);
	public static var rnd: hxd.Rand;
	var bag: RandomProvider;

	public function new() {}

	public function init(mode: Data.Mode, root: h2d.Object) {
		inst = this;
		this.mode = mode;
		this.level = mode.startLevel;
		this.targetCount = mode.targetCount;

		fullUi = new BoardUi(root);

		trace("Seed: " + seed);
		rnd = new hxd.Rand(seed);
		bag = new RandomProvider(rnd, Bag, Const.MINO_COUNT);
		animalsBag = new RandomProvider(rnd, Bag, Data.animal.all.length);
		// creates a new object and put it at the center of the sceen
		gridCont = new SceneObject(fullUi.boardCont);

		gridGraphics = new h2d.Graphics(gridCont);
		drawGrid(gridGraphics);
		boardObj = new SceneObject(gridCont);
		boardObj.dom.addClass("board");
		updateScroll(0);
		lockedObj = new SceneObject(boardObj);
		fogObj = new h2d.Flow(gridCont);
		for (i in 0...Const.BOARD_WIDTH) {
			var tile = Data.mino.get(i % 2 == 0 ? Fog1 : Fog2).gfx.toTile();
			new SceneBitmap(tile, fogObj);
		}
		fogObj.y = Const.BOARD_FULL_HEIGHT * Const.SIDE;
		phantomCont = new SceneObject(boardObj);
		clearBoard();
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

	public function blockIsEmpty(x, y) {
		return board[x][y] == null || board[x][y].isEmpty;
	}
	public function blockIsVisible(x, y) {
		return (y - minScroll) >= -1;
	}

	function fillNext() {
		for (_ in nextQueue.length...Const.NEXT_QUEUE_SIZE) {
			nextQueue.push(new Piece(bag.getNext()));
		}
		for (i in 0...Const.NEXT_QUEUE_SIZE) {
			fullUi.nextPieces[i].removeChildren();
			fullUi.nextPieces[i].addChild(nextQueue[i].obj);
			nextQueue[i].updatePos(true);
		}
	}
	function doSpawnMino(m: Piece) {
		current = m;
		boardObj.addChild(current.obj);
		current.reset();
		fillNext();
		updateConnections();
		checkDefeat();
	}
	function nextMino(?remove = true, ?instant = false) {
		if (current != null && remove)
			current.obj.remove();
		current = null;
		if (instant)
			doSpawnMino(nextQueue.shift());
		heldOnce = false;
		resetBlocking(false);
		nextMinoTimer = 0.;
	}
	var nextMinoTimer = 0.;
	function updateNextMino(dt: Float) {
		if (current != null)
			return;
		nextMinoTimer += dt;
		if (nextMinoTimer > Const.ENTRY_DELAY)
			doSpawnMino(nextQueue.shift());
	}
	public function collides(m: Piece, offsetx = 0, offsety = 0, allowPhase = false) {
		for (b in m.blocks) {
			var x = b.x + m.x + offsetx;
			var y = b.y + m.y + offsety;
			if (x < 0 || x >= board.length || y < 0 || y < targetScroll)
				return true;
			if (!blockIsEmpty(x, y)) {
				if (!allowPhase || !board[x][y].inf.flags.has(PhaseThrough))
					return true;
			}
		}
		return false;
	}
	function lockPiece(m: Piece) {
		for (b in m.blocks) {
			var x = b.x + m.x;
			var y = b.y + m.y;
			if (board[x][y] != null) {
				board[x][y].obj.remove();
			}
			board[x][y] = b;
			lockedObj.addChild(b.obj);
			b.x = x;
			b.y = y;
			b.updatePos();
		}
	}

	public function getSpawnLines(mino: Data.MinoKind) {
		var base = Const.BOARD_HEIGHT - 1 + targetScroll;
		if (mino == J && !finalTargets.isEmpty()) {
			if (targetScroll == finalTargets[0].y - Const.BOARD_HEIGHT)
				return [base - 1, base, base - 2, base + 1, base + 2];
		}
		return [base, base - 1, base - 2, base + 1, base + 2];
	}
	function checkScroll(p: Piece) {
		var maxY = 0;
		for (b in p.blocks) {
			maxY = hxd.Math.imax(b.y, maxY);
		}
		var maxScroll = 1000000000;
		if (!finalTargets.isEmpty()) {
			for (f in finalTargets) {
				maxScroll = hxd.Math.imin(f.y - Const.BOARD_HEIGHT, maxScroll);
			}
		}
		var tgt = hxd.Math.imin(maxY - Const.SCROLL_LINE, maxScroll);
		var amount = tgt - targetScroll;
		if (amount > 0)
			targetScroll += amount;
	}
	function lockCurrent() {
		lockPiece(current);
		checkScroll(current);
		nextMino();
	}
	function checkDefeat() {
		if (gameIsOver || current == null)
			return;
		if (collides(current)) {
			triggerDefeat(TopOut);
		}
		var found = false;
		for (i in 0...Const.BOARD_WIDTH) {
			for (j in 0...Const.BOARD_HEIGHT) {
				var y = j + minScroll;
				if (!blockIsEmpty(i, y) && board[i][y].on) {
					found = true;
					break;
				}
			}
			if (found) break;
		}
		if (!found)
			triggerDefeat(ConnectionLost);
	}
	function triggerDefeat(reason: LossReason) {
		resultUi = new ResultUi(false, reason, fullUi);
	}
	function triggerVictory() {
		resultUi = new ResultUi(true, fullUi);
	}
	function getHardDropDiff() {
		var prev = 0;
		for (i in 1...(current.y + 1)) {
			if (collides(current, 0, -i, true)) {
				break;
			} else if (!collides(current, 0, -i, false)) {
				prev = i;
			}
		}
		return prev;
	}
	function getSoftDropDiff() {
		for (i in 1...(current.y + 1)) {
			if (collides(current, 0, -i, true)) {
				break;
			} else if (!collides(current, 0, -i, false)) {
				return i;
			}
		}
		return 0;
	}
	function hardDrop() {
		current.y -= getHardDropDiff();
		lockCurrent();
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
		if (found) {
			current.updatePos();
			resetBlocking(true);
		} else {
			current.loadPos(initial);
		}
		updateConnections();
	}

	function swapHold() {
		if (heldOnce)
			return false;
		if (hold == null) {
			hold = current;
			nextMino(false);
		} else {
			var a = hold;
			hold = current;
			doSpawnMino(a);
		}
		hold.reset();
		hold.x = 0;
		hold.y = 0;
		hold.updatePos(true);
		fullUi.currHold.addChild(hold.obj);
		updateConnections();
		heldOnce = true;
		resetBlocking(false);
		return true;
	}
	function resetBlocking(softReset = true) {
		currDrop = 0.;
		currLock = 0.;
		if (softReset) {
			if (isLocking)
				currLockReleaseCount++;
		} else {
			isLocking = false;
			currLockReleaseCount = 0;
		}
	}


	function fillBackGround() {
		for (i in 0...Const.BOARD_WIDTH) {
			if (board.length <= i)
				board[i] = [];
			for (j in 0...Const.BOARD_HEIGHT) {
				var y = j + targetScroll;
				if (board[i][y] == null)
					board[i][y] = new Block(i, y, Data.mino.get(Background), lockedObj);
			}
		};
	}

	public function clearBoard() {
		if (resultUi != null) {
			resultUi.remove();
			resultUi = null;
		}
		for (i in 0...board.length) {
			for (j in 0...board[i].length) {
				if (board[i][j] != null)
					board[i][j].obj.remove();
			}
		}
		if (current != null)
			current.obj.remove();

		targetScroll = 0;
		currentScroll = 0.;
		board = [];
		fillBackGround();
		fillNext();
		if (hold != null)
			hold.obj.remove();
		hold = null;

		function makeSource(x, y, k) {
			var source = new Block(x, y, Data.mino.get(k), lockedObj);
			board[x][y].obj.remove();
			board[x][y] = source;
			return source;
		}
		var source1 = makeSource(4, 0, SourceL);
		var source2 = makeSource(5, 0, SourceR);

		animals = [];
		fullUi.setScore(score);
		fullUi.setAnimals(animals);

		targets.clear();
		allTargets.clear();
		finalTargets.clear();
		spawnTargets();
		nextMino(true, true);
		updateConnections();
		highestOnBlock = null;
		if (truck != null)
			truck.obj.remove();
		truck = new Truck(source1, boardObj);
		if (parkedTruck != null)
			parkedTruck.obj.remove();
		parkedTruck = new Truck(source2, boardObj);
		parkedTruck.update(0);
	}

	function spawnTargets() {
		if (targetCount >= 0) {
			while (allTargets.length < targetCount) {
				spawnNextTarget();
			}
			var prev = Const.FIRST_TARGET_LINE;
			if (!allTargets.isEmpty()) {
				prev = allTargets.last().y;
			}
			var y = prev + Const.END_TARGET_SPACING;
			function makeFinal(x, y, k) {
				var t = new Block(x, y, Data.mino.get(k), lockedObj);
				if (board[x][y] != null)
					board[x][y].obj.remove();
				board[x][y] = t;
				targets.push(t);
				allTargets.push(t);
				finalTargets.push(t);
			}
			makeFinal(4, y, EndL);
			makeFinal(5, y, EndR);
		} else {
			spawnNextTarget();
		}
	}
	function spawnNextTarget() {
		var y = Const.FIRST_TARGET_LINE;
		var prevSide = false; // true is left, false is right
		if (!allTargets.isEmpty()) {
			var prev = allTargets.last();
			y = prev.y + Const.TARGET_LINE_SPACING;
			prevSide = prev.x < Const.BOARD_WIDTH / 2;
		} else {
			prevSide = rnd.random(2) == 0;
		}
		var col = rnd.random(Const.TARGET_COL_MAX - Const.TARGET_COL_MIN) + Const.TARGET_COL_MIN;
		var x = prevSide ? Const.BOARD_WIDTH - col - 1 : col;
		var t = new Block(x, y, Data.mino.get(Target), lockedObj);
		if (board[x][y] != null)
			board[x][y].obj.remove();
		board[x][y] = t;
		targets.push(t);
		allTargets.push(t);
	}

	function fillRec(x: Int, y: Int, forPhantom = false) {
		function getAt(x: Int, y: Int) {
			if (!blockIsEmpty(x, y))
				return board[x][y];
			if (!forPhantom)
				return null;
			return phantom.blocks.find(e -> e.x == x && e.y == y);
		}
		var b = getAt(x, y);
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
			if (i < 0 || i >= Const.BOARD_WIDTH || j < 0 || j >= boardMax())
				continue;
			var curr = getAt(i, j);
			if (curr == null)
				continue;
			if (!b.hasDir(r) || curr.on || !curr.hasDir(r.rotateBy(2)) || (forPhantom && curr.phantomOn))
				continue;
			if (forPhantom) {
				curr.phantomOn = true;
			} else {
				curr.on = true;
				if (highestOnBlock == null || j > highestOnBlock.y
					|| (j == highestOnBlock.y && !highestOnBlock.hasDir(Up) && curr.hasDir(Up))
				) {
					highestOnBlock = curr;
				}
			}
			fillRec(i, j, forPhantom);
		}
	}
	public function boardMax() {
		return Const.BOARD_FULL_HEIGHT + currentScroll;
	}
	function fillPhantom() {
		var starts = [];
		for (b in phantom.blocks) {
			b.phantomOn = false;
			b.x += phantom.x;
			b.y += phantom.y;
		}
		for (b in phantom.blocks) {
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
				if (i < 0 || i >= Const.BOARD_WIDTH || j < 0 || j >= boardMax())
					continue;
				if (blockIsEmpty(i, j))
					continue;
				if (!b.hasDir(r) || !board[i][j].on || !board[i][j].hasDir(r.rotateBy(2)))
					continue;
				b.phantomOn = true;
				starts.push(b);
				break;
			}
		}
		for (s in starts) {
			fillRec(s.x, s.y, true);
		}
		for (b in phantom.blocks) {
			b.x -= phantom.x;
			b.y -= phantom.y;
		}
	}
	function updateConnections() {
		var starts = [];
		for (i in 0...board.length) {
			for (j in 0...board[i].length) {
				if (!blockIsEmpty(i, j)) {
					if (board[i][j].alwaysOn()) {
						starts.push(board[i][j]);
					} else {
						board[i][j].on = false;
						board[i][j].phantomOn = false;
					}
				}
			}
		}
		for (s in starts)
			fillRec(s.x, s.y);

		if (phantom != null && (phantom.follow != current || current?.phantom != phantom)) {
			phantom.obj.remove();
			phantom = null;
		}
		if (current != null) {
			if (phantom == null)
				phantom = new Piece(current, phantomCont);
			phantom.y = current.y - getHardDropDiff();
			phantom.updatePos();
			fillPhantom();
			phantom.updatePos();
			current.updatePos();
		}

		for (i in 0...board.length) {
			for (j in 0...board[i].length) {
				if (board[i][j] != null) {
					board[i][j].updatePos();
				}
			}
		}
		targets.reverseFor(function(t) {
			if (t.on) {
				targets.remove(t);
				highestOnBlock = t;
				animals.push(Data.animal.all[animalsBag.getNext()]);
				if (targetCount < 0)
					spawnNextTarget();
			}
		});
		fullUi.setScore(score);
		fullUi.setAnimals(animals);
		if (!finalTargets.isEmpty() && finalTargets.all(t -> t.on)) {
			triggerVictory();
		}
	}

	function move(by: Int) {
		if (!collides(current, by, 0)) {
			current.x += by;
			current.updatePos();
			updateConnections();
			resetBlocking(true);
		}
	}

	function updateMove(dt: Float) {
		static var prevDir = 0;
		static var hasDas = false;
		static var accum = 0.;
		var dir = 0;
		if (K.isDown(Const.config.right))
			dir++;
		if (K.isDown(Const.config.left))
			dir--;

		if (K.isPressed(Const.config.right)) {
			move(1);
			hasDas = false;
			accum = 0;
			prevDir = 1;
		}
		if (K.isPressed(Const.config.left)) {
			move(-1);
			hasDas = false;
			accum = 0;
			prevDir = -1;
		}
		if (dir != 0) {
			accum += dt;
			if ((hasDas && accum >= Const.ARR) || (!hasDas && accum >= Const.DAS)) {
				hasDas = true;
				move(dir);
			}
		}
	}
	function updateGravity(dt: Float) {
		var increment = 1 / 60.;
		var g = Const.GRAVITY_PER_LEVEL[level];
		if (K.isDown(Const.config.softDrop))
			g *= 20;
		currDrop += g * (dt / increment);
		while (currDrop >= 1) {
			if (softDrop()) {
				currDrop -= 1;
				currLock = 0;
			} else {
				currDrop = 0;
				isLocking = true;
				currLockReleaseCount++;
			}
		}
		isLocking = collides(current, 0, -1, true);
		if (isLocking) {
			currLock += dt;
			if (currLockReleaseCount > Const.LOCK_RESET_MAX || currLock >= Const.LOCK_DELAY) {
				lockCurrent();
			}
		}
	}
	function softDrop() {
		var diff = getSoftDropDiff();
		if (diff > 0) {
			current.y -= diff;
			current.updatePos();
			return true;
		}
		return false;
	}
	function updateScroll(dt: Float) {
		currentScroll = targetScroll;
		boardObj.y = boardMax() * Const.SIDE;
		for (i in 0...board.length) {
			for (j in (-5 + minScroll)...(minScroll + 1)) {
				if (j < 0 || j >= board[i].length)
					continue;
				if (board[i][j] == null || blockIsVisible(i, j))
					continue;
				board[i][j].obj.remove();
			}
		}
		fillBackGround();
	}
	public function update(dt:Float) {
		if (K.isPressed(K.R)) {
			clearBoard();
		}
		updateScroll(dt);
		if (!gameIsOver) {
			updateNextMino(dt);
			if (current != null) {
				if (K.isPressed(Const.config.hardDrop)) {
					hardDrop();
				}
			}
			if (current != null) {
				if (K.isPressed(Const.config.rotateRight)) {
					rotate(false);
				}
				if (K.isPressed(Const.config.rotateLeft)) {
					rotate(true);
				}
				if (K.isPressed(Const.config.hold)) {
					swapHold();
				}
			}
			if (current != null) {
				updateMove(dt);
				updateGravity(dt);
			}
			if (current != null)
				current.update(dt);
			if (phantom != null)
				phantom.update(dt);
		}
		for (col in board) {
			for (block in col) {
				// TODO if visible
				if (block != null)
					block.update(dt);
			}
		}
		if (truck != null)
			truck.update(dt);

		#if debug
		if (K.isPressed(K.M)) {
			current.areRoadsValid();
		}
		#end
	}
}