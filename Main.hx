using Extensions;

class Main extends hxd.App {
    var board: Board;

    override function init() {
        board = new Board();
        board.init(s2d);
        onResize();
    }
    static function main() {
		hxd.Res.initEmbed();
		new Main();
	}
    override function update(dt:Float) {
        board.update(dt);
	}
    override function onResize() {
		trace("resize", s2d.width, s2d.height);
		board.gridCont.x = Std.int(s2d.width / 2) - ((Const.BOARD_WIDTH / 2) * Const.SIDE);
	}
}
