import hxd.Key as K;
using Extensions;

@:uiComp("button")
class Button extends h2d.Flow implements h2d.domkit.Object {
	static var SRC = <button>
		<text id="labelTxt"
			text={text}
			font={Main.font}
			scale="2"
		/>
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
		>
			<flow class="back-cont" id
				margin-right="540"
				margin-top="20"
				align="top middle"
			/>
		</flow>
		<flow class="menu-cont" id
			fill-width={true}
			fill-height={true}
			content-align="middle middle"
			scale="1"
		>
			<flow class="title-cont"
				layout="vertical"
			>
				<text text={Const.TITLE}
					scale="3"
				/>
			</flow>
			<flow class="middle-cont">
				<flow class="how-to-play"
					layout={h2d.Flow.FlowLayout.Vertical}
					spacing="5"
				>
					<text text={"How to play"}
						font={Main.font}
						color="#F8DCC1"
						scale="2"
					/>
					<text text={'Connect the roads to the top'}/>
					<text text={'Save animals on the way to gain points!'}
						max-width="180"
						margin-bottom="20"
					/>
					<text text={'Move left: ${K.getKeyName(Const.config.left)}'}/>
					<text text={'Move right: ${K.getKeyName(Const.config.right)}'}/>
					<text text={'Soft drop: ${K.getKeyName(Const.config.softDrop)}'}/>
					<text text={'Hard drop: ${K.getKeyName(Const.config.hardDrop)}'}/>
					<text text={'Rotate right: ${K.getKeyName(Const.config.rotateRight)}'}/>
					<text text={'Rotate left: ${K.getKeyName(Const.config.rotateLeft)}'}/>
					<text text={'Hold: ${K.getKeyName(Const.config.hold)}'}/>
				</flow>
				<flow id="buttons"
					layout={h2d.Flow.FlowLayout.Vertical}
					spacing="10"
				/>
				<flow class="credits"
					layout={h2d.Flow.FlowLayout.Vertical}
					spacing="10"
				>
					<text text={"CREATED BY:"}
						font={Main.font}
						color="#F8DCC1"
					/>
					<text text={"Speedphoenix"}/>
					<text text={"Jean-Phénix De"}/>
					<text text={"PloucPhoenix"}/>
				</flow>
			</flow>
		</flow>
	</main-menu>

	public static var style : h2d.domkit.Style;

	public function new(?parent) {
		super(parent);
		initComponent();
		// tf.dropShadow = { dx : 0.5, dy : 0.5, color : 0xFF0000, alpha : 0.8 };

		for (mode in Data.mode.all) {
			#if release
			if (mode.props.noRelease)
				continue;
			#end
			var button = new Button(mode.name, buttons);
			button.onClick = function() {
				menuCont.visible = false;
				boardCont.visible = true;
				Main.inst.board = new Board();
				Main.inst.board.init(mode, boardCont);
			}
		}

		var back = new Button("Back", backCont);
		back.onClick = onBack;

		style = new h2d.domkit.Style();
		style.allowInspect = #if debug true #else false #end;
		style.load(hxd.Res.style, true);
		style.addObject(this);
		dom.addClass("root");
		boardCont.visible = false;
		#if debug
		// newGame.onClick();
		#end
	}

	public function onBack() {
		menuCont.visible = true;
		boardCont.visible = false;
		if (Main.inst.board != null) {
			Main.inst.board.fullUi.remove();
			Main.inst.board = null;
		}
	}
}

class Main extends hxd.App {
	public var board: Board;
	public var menu: MainMenu;
	public static var inst: Main;

	public static var font: h2d.Font;

	override function init() {
		inst = this;
		var cdbData = hxd.Res.data.entry.getText();
		Data.load(cdbData, false);
		hxd.Res.data.watch(function() {
			var cdbData = hxd.Res.data.entry.getText();
			Data.load(cdbData, true);
		});
		font = hxd.Res.customFont.toFont();
		menu = new MainMenu(s2d);
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
