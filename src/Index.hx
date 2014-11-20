#if neko
import neko.Lib;
import neko.Web;
#elseif php
import php.Lib;
import php.Web;
#end

import haxe.web.Dispatch;
import sys.db.Types;

class Index {

	public static function main() {
		try {
			Dispatch.run(Web.getURI(), Web.getParams(), new WebApi());
		} catch (e : DispatchError) {
			Web.redirect("game");
			return;
		}
	}

}

class WebApi {

	private static inline var dbFilename = "gothing.sqlite";
	
	public function new() { }

	public function doGame(
		args : { playAt : Null<String>, playNo : Null<Int> }) : Void {
		initDb();

		if (args.playAt != null && args.playNo != null) {
			var playAtXC = args.playAt.charCodeAt(0);
			var playAtYC = args.playAt.charCodeAt(1);
			if (playAtXC != null && playAtYC != null) {
				var playAtX = playAtXC - "a".code;
				var playAtY = playAtYC - "a".code;
				if (
					playAtX >= 0 && playAtX < 19 &&
					playAtY >= 0 && playAtY < 19) {
					addMove(0, args.playNo, args.playNo % 2, playAtX, playAtY);
				}
			}
		}

		var goban = new haxe.ds.Vector<haxe.ds.Vector<Null<Int>>>(19);
		for (y in 0...19) {
			goban[y] = new haxe.ds.Vector<Null<Int>>(19);
			for (x in 0...19) {
				goban[y][x] = null;
			}
		}

		var moves = GoMove.manager.search(true);
		for (move in moves) {
			goban[move.row][move.col] = move.color;
		}

		var moveCount = GoMove.manager.count(true);
		var gobanBuf = new StringBuf();
		gobanBuf.add("<table id='goban' class='goban'>");
		for (y in 0...19) {
			gobanBuf.add("<tr>");
			for (x in 0...19) {
				gobanBuf.add("<td>");
				switch (goban[y][x]) {
					case null:
						gobanBuf.add('<a href="game?playAt=');
						gobanBuf.add(String.fromCharCode("a".code + x));
						gobanBuf.add(String.fromCharCode("a".code + y));
						gobanBuf.add('&playNo=' + moveCount + '">');
						gobanBuf.add('<img src="images/goban/e.gif" />');
						gobanBuf.add('</a>');
					case 0:
						gobanBuf.add('<img src="images/goban/b.gif" />');
					case 1:
						gobanBuf.add('<img src="images/goban/w.gif" />');
					default:
				}
				gobanBuf.add("</td");
			}
			gobanBuf.add("</tr>");
		}
		gobanBuf.add("</table>");

		var template = new haxe.Template(haxe.Resource.getString("game"));
		var output = template.execute({ goban: gobanBuf.toString() });
		Lib.print(output);
	}

	private static var dbReady = false;
	private static function initDb() : Void {
		if (!dbReady) {
			sys.db.Manager.initialize();
			sys.db.Manager.cnx = sys.db.Sqlite.open(dbFilename);
			if (!sys.db.TableCreate.exists(GoMove.manager)) {
				sys.db.TableCreate.create(GoMove.manager);
				addMove(0, 0, 0, 15, 3);
				addMove(0, 1, 1, 3, 15);
				addMove(0, 2, 0, 3, 3);
			}
			dbReady = true;
		}
	}

	private static function addMove(
		game: Int, moveNo: Int, color: Int, col: Int, row: Int) : Void {
		var move = new GoMove();
		move.gameId = game;
		move.moveNo = moveNo;
		move.color = color;
		move.col = col;
		move.row = row;
		move.insert();
	}

}

@:index(gameId) class GoMove extends sys.db.Object {
	// nasty workaround for Sqlite's atypical handling of ids
	// see https://github.com/HaxeFoundation/haxe/issues/2029#issuecomment-57548588
	// in production will use MySQL anyway
	#if php
	public var id : SNull<SInt>;
	#else
	public var id : SId;
	#end
	public var gameId : SInt;
	public var moveNo : SUInt;
	public var color : STinyUInt;
	public var col : STinyUInt;
	public var row : STinyUInt;
}
