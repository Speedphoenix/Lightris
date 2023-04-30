using Extensions;

@:uiComp("button")
class Button extends h2d.Flow implements h2d.domkit.Object {
	static var SRC = <button
		background={bg}
		padding="15"
		padding-top="11"
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
	>
		<flow class="board-cont" id/>
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
		</flow>
	</main-menu>

	public static var style : h2d.domkit.Style;

	public function new(?parent) {
		super(parent);
		initComponent();
		var newGame = new Button("New Game", menuCont);
		newGame.onClick = function() {
			menuCont.visible = false;
			boardCont.visible = true;
			Main.inst.board = new Board();
			Main.inst.board.init(this);
		}
		style = new h2d.domkit.Style();
		style.allowInspect = #if debug true #else false #end;
		style.addObject(this);
		this.dom.addClass("root");
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
