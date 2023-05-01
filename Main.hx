using Extensions;

@:uiComp("button")
class Button extends h2d.Flow implements h2d.domkit.Object {
	static var SRC = <button
		background={bg}
		padding="15"
		padding-top="11"
		content-halign={h2d.Flow.FlowAlign.Middle}
		min-width="100"
	>
		<text id="labelTxt" text={text} />
	</button>

	public function new(text="", ?parent) {
		super(parent);
		var tile = hxd.Res.button_bg.toTile();
		tile.setSize(16, 16);
		tile.setPosition(0, 0);
		var bg = {
			tile: tile,
			borderL: 4,
			borderT: 4,
			borderR: 4,
			borderB: 4,
		};
		initComponent();
		enableInteractive = true;
		interactive.onClick = function(_) onClick();
		interactive.onOver = function(_) {
			dom.hover = true;
			tile.setPosition(1, 0);
			background.tile = tile;
		};
		interactive.onPush = function(_) {
			dom.active = true;
			tile.setPosition(2, 0);
			background.tile = tile;
		};
		interactive.onRelease = function(_) {
			dom.active = false;
			tile.setPosition(0, 0);
			background.tile = tile;
		};
		interactive.onOut = function(_) {
			dom.hover = false;
			tile.setPosition(0, 0);
			background.tile = tile;
		};
	}

	public dynamic function onClick() {
	}
}


class MainMenu extends h2d.Flow implements h2d.domkit.Object {
	static var SRC = <main-menu
		fill-width={true}
		fill-height={true}
		background="#111"
		layout={h2d.Flow.FlowLayout.Stack}
	>
		<flow class="board-cont" id
			fill-width={true}
			fill-height={true}
			layout={h2d.Flow.FlowLayout.Stack}
			padding-left="20"
		/>
		<flow class="menu-cont" id
			fill-width={true}
			fill-height={true}
			layout={h2d.Flow.FlowLayout.Stack}
			content-align="middle middle"
		>
			<flow class="credits"
				layout={h2d.Flow.FlowLayout.Vertical}
				spacing="10"
				margin-left="250"
			>
				<text text={"Created By:"}/>
				<text text={"Leonardo Jeanteur"}/>
				<text text={"Sylvain Legay"}/>
				<text text={"Margaux Berard"}/>
			</flow>
			<flow id="buttons"
				layout={h2d.Flow.FlowLayout.Vertical}
				spacing="10"
			/>
		</flow>
	</main-menu>

	public static var style : h2d.domkit.Style;

	public function new(?parent) {
		super(parent);
		initComponent();
		function startGame() {
			menuCont.visible = false;
			boardCont.visible = true;
			Main.inst.board = new Board();
			Main.inst.board.init(boardCont);
		}
		var medium = new Button("Medium", buttons);
		var hard = new Button("Hard", buttons);
		medium.onClick = function() {
			Const.USE_DEFAULT_ROADS = false;
			startGame();
		}
		hard.onClick = function() {
			Const.USE_DEFAULT_ROADS = true;
			startGame();
		}

		var back = new Button("Back", boardCont);
		back.onClick = function() {
			menuCont.visible = true;
			boardCont.visible = false;
			if (Main.inst.board != null) {
				Main.inst.board.fullUi.remove();
				Main.inst.board = null;
			}
		}

		style = new h2d.domkit.Style();
		style.allowInspect = #if debug true #else false #end;
		style.addObject(this);
		dom.addClass("root");
		boardCont.visible = false;
		#if debug
		// newGame.onClick();
		#end
	}
}

class Main extends hxd.App {
	public var board: Board;
	public static var inst: Main;

	override function init() {
		inst = this;
		new MainMenu(s2d);
		onResize();
	}
	static function main() {
		hxd.Res.initEmbed();
		new Main();
	}
	override function update(dt:Float) {
		if (board != null)
			board.update(dt);
	}
	override function onResize() {
		trace("resize", s2d.width, s2d.height);
		if (board != null)
			board.gridCont.x = Std.int(s2d.width / 2) - ((Const.BOARD_WIDTH / 2) * Const.SIDE);
	}
}
