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
			// looks for a method of WebApi called 'doXxx' where 'xxx' is
			// the requested page name
			Dispatch.run(Web.getURI(), Web.getParams(), new WebApi());
		} catch (e : DispatchError) {
			Web.redirect("game");
			return;
		}
	}

	public static inline var boardSize = 19; // to be abolished once games
	// have a table in the db with individual sizes
	public static inline var dbFilename = "gothing.sqlite";
	
}

class WebApi {

	public function new() { }

	public function doGame(args : {
		playNo : Null<Int>, playAt : Null<String> }) : Void
	{
		initDb();

		tryPlayMove(args.playNo, args.playAt);

		var goban = getGobanForGame(0);
		var gobanHtml = getHtmlForGoban(goban, 0);

		var template = new haxe.Template(haxe.Resource.getString("game"));
		var output = template.execute({ goban: gobanHtml });
		Lib.print(output);
	}

	private static var dbReady = false;
	private static inline function initDb() : Void {
		if (!dbReady) {
			reallyInitDb();
		}
	}
	private static function reallyInitDb() : Void {
		sys.db.Manager.initialize();
		sys.db.Manager.cnx = sys.db.Sqlite.open(Index.dbFilename);
		if (!sys.db.TableCreate.exists(GoMove.manager)) {
			sys.db.TableCreate.create(GoMove.manager);
		}
		dbReady = true;
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

	private static inline function tryPlayMove(
		moveNo : Null<Int>, coordsStr : Null<String>) : Void
	{
		if (moveNo != null && coordsStr != null) {
			playMove(moveNo, coordsStr);
		}
	}
	private static function playMove(moveNo : Int, coordsStr : String) : Void
	{
		var lastMoveList : List<GoMove> =
			GoMove.manager.search($gameId == 0,
				{ orderBy : -moveNo, limit : 1 });
		var lastMoveNo : Int = if (lastMoveList.length == 0) {
			-1;
		} else {
			lastMoveList.first().moveNo;
		}
		if (lastMoveNo != moveNo - 1) {
			return;
		}

		var playAtXC = coordsStr.charCodeAt(0);
		var playAtYC = coordsStr.charCodeAt(1);
		if (playAtXC == null || playAtYC == null) {
			return;
		}
		var playAtX = playAtXC - "a".code;
		var playAtY = playAtYC - "a".code;
		if (playAtX < 0 ||  playAtX >= 19 || playAtY < 0 || playAtY >= 19) {
			return;
		}
		
		try {
			addMove(0, moveNo, moveNo % 2, playAtX, playAtY);
		} catch (e : Dynamic) {
			// sometimes Neko throws an exception because the 'database is busy'
			// but I don't know its type :/
			return;
		}
	}

	/*
	 * builds an array of `null` for empty spaces, numbers for stones (by
	 * default 0 is black, 1 is white)
	 */
	private static function getGobanForGame(gameNo : Int)
		: Array<Array<Null<Int>>>
	{
		// TODO: unit testing should confirm that this returns the
		// correct array size for the game
		var goban = [for (y in 0...Index.boardSize)
				[for (x in 0...Index.boardSize) null]];
		var moves = GoMove.manager.search($gameId == gameNo);
		for (move in moves) {
			goban[move.row][move.col] = move.color;
		}
		return goban;
	}

	private static function getHtmlForGoban(
		goban : Array<Array<Null<Int>>>,
		gameNo : Int)
		: String
	{
		var moveCount = GoMove.manager.count($gameId == gameNo);
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
						gobanBuf.add('&playNo=' + moveCount);
						gobanBuf.add('">');
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

		return gobanBuf.toString();
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
	public var moveNo : SInt;
	public var color : STinyUInt;
	public var col : STinyUInt;
	public var row : STinyUInt;
}
