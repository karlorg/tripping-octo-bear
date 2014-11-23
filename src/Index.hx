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
		haxe.Log.trace = function(v : Dynamic, infos : haxe.PosInfos = null)
			: Void
			{
				Sys.stderr().writeString(v + "\n");
			}
		try {
			// looks for a method of WebApi called 'doXxx' where 'xxx' is
			// the requested page
			Dispatch.run(Web.getURI(), Web.getParams(), new WebApi());
		} catch (e : DispatchError) {
			Web.redirect("listgames");
			return;
		}
	}

	public static inline var boardSize = 19; // to be abolished once games
	// have a table in the db with individual sizes
	
}

class WebApi {

	private var ops: ServerOps;

	public function new(?ops: ServerOps) {
		if (ops == null) {
			ops = new DefaultServerOps();
		}
		this.ops = ops;
	}

	public function doListgames() : Void {
		Db.init();

		var games = GoGame.manager.search(true, { orderBy : id });

		/* build html for game list */
		var gamelistHtml : String;
		{
			var gamelistBuf = new StringBuf();
			for (game in games) {
				var idStr = Std.string(game.id);
				gamelistBuf.add('<a href="game?gameId=' + idStr + '">'
				+ idStr + '</a> ');
			}
			gamelistHtml = gamelistBuf.toString();
		}
	
		/* write the page */
		var template = new haxe.Template(haxe.Resource.getString("listgames"));
		var output = template.execute({ gamelist: gamelistHtml });
		ops.print(output);
	}

	public function doGame(args : {
		gameId : Null<Int>,
		playNo : Null<Int>, playAt : Null<String> }) : Void
	{
		Db.init();

		if (args.gameId == null) {
			trace("no game id provided with game request");
			ops.redirect("listgames");
			return;
		}

		var gameList = GoGame.manager.search($id == args.gameId);
		if (gameList.length == 0) {
			trace("no such game " + args.gameId);
			ops.redirect("gamelist");
			return;
		} else if (gameList.length > 1) {
			trace("eek! Multiple games with id " + args.gameId);
		}
		var game = gameList.first();

		playMove(game, args.playNo, args.playAt);

		var moves = GoMove.manager.search($game == game);

		/* build a 2d array of `null` for empty spaces, numbers for stones (by
		 * default 0 is black, 1 is white)
		 */
		var goban : Array<Array<Null<Int>>>;
		{
			goban = [for (y in 0...Index.boardSize)
					[for (x in 0...Index.boardSize) null]];
			for (move in moves) {
				goban[move.row][move.col] = move.color;
			}
		}

		/* build the html for this goban */
		var gobanHtml : String;
		{
			var moveCount = moves.length;
			var gobanBuf = new StringBuf();
			gobanBuf.add("<table id='goban' class='goban'>");
			for (y in 0...Index.boardSize) {
				gobanBuf.add("<tr>");
				for (x in 0...Index.boardSize) {
					gobanBuf.add("<td>");
					switch (goban[y][x]) {
						case null:
							gobanBuf.add('<a href="game?gameId=');
							gobanBuf.add(Std.string(args.gameId));
							gobanBuf.add('&playAt=');
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
			gobanHtml = gobanBuf.toString();
		}

		/* write the page */
		var template = new haxe.Template(haxe.Resource.getString("game"));
		var output = template.execute({ goban: gobanHtml });
		ops.print(output);
	}

	public function doNewgame() : Void {
		Db.init();
		Db.addGame(19);
		ops.redirect("listgames");
	}

	/*
	 * Check and play a move specified as request parameters.
	 */
	private static function playMove(
		game : GoGame, moveNo : Null<Int>, coordsStr : Null<String>) : Void
	{
		if (moveNo == null || coordsStr == null) {
			return;
		}

		// get the number of the last move played
		var lastMoveNo : Int;
		{
			var lastMoveList : List<GoMove> =
				GoMove.manager.search($game == game,
					{ orderBy : -moveNo, limit : 1 });
			if (lastMoveList.length == 0) {
				lastMoveNo = -1;
			} else {
				lastMoveNo = lastMoveList.first().moveNo;
			}
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
		if (playAtX < 0 || playAtX >= Index.boardSize
		 || playAtY < 0 || playAtY >= Index.boardSize) {
			return;
		}
		
		try {
			Db.addMove(game, moveNo, moveNo % 2, playAtX, playAtY);
		} catch (e : Dynamic) {
			// sometimes Neko throws an exception because the 'database is busy'
			// but I don't know its type :/
			return;
		}
	}

}

/*
 * Abstracts out server operations that are inconvenient or impossible during
 * testing, so as to allow replacement with mocks etc.
 */
interface ServerOps {
	public function print(str: String) : Void;
	public function redirect(dest: String) : Void;
}

class DefaultServerOps implements ServerOps {
	public function new() { }
	public function print(str: String) : Void {
		Lib.print(str);
	}
	public function redirect(dest: String) : Void {
		Web.redirect(dest);
	}
}

class Db {

	public static inline var defaultFilename = "gothing.sqlite";

	public static var ready(default,null) = false;
	public static function init(?filename: String) : Void {
		if (ready) { return; }
		if (filename == null) {
			filename = defaultFilename;
		}
		sys.db.Manager.initialize();
		sys.db.Manager.cnx = sys.db.Sqlite.open(filename);
		if (!sys.db.TableCreate.exists(GoGame.manager)) {
			sys.db.TableCreate.create(GoGame.manager);
		}
		if (!sys.db.TableCreate.exists(GoMove.manager)) {
			sys.db.TableCreate.create(GoMove.manager);
		}
		ready = true;
	}

	public static function close() : Void {
		ready = false;
		if (sys.db.Manager.cnx != null) {
			sys.db.Manager.cnx.close();
			sys.db.Manager.cnx = null;
		}
		sys.db.Manager.cleanup();
	}

	/* Add a game into the GoGame db table.
	 */
	public static function addGame(
		size: Int) : Void
	{
		if (!ready) {
			trace("Database not initialised in addGame");
			return;
		}
		var game = new GoGame();
		game.size = size;
		game.insert();
	}

	/*
	 * Add a move into the GoMove db table.
	 */
	public static function addMove(
		game: GoGame, moveNo: Int, color: Int, col: Int, row: Int) : Void
	{
		if (!ready) {
			trace("Database not initialised in addMove");
			return;
		}
		var move = new GoMove();
		move.game = game;
		move.moveNo = moveNo;
		move.color = color;
		move.col = col;
		move.row = row;
		move.insert();
	}

}

class GoGame extends sys.db.Object {
	// nasty workaround for Sqlite's atypical handling of ids
	// see https://github.com/HaxeFoundation/haxe/issues/2029#issuecomment-57548588
	// in production will use MySQL anyway
	#if php
	public var id : SNull<SInt>;
	#else
	public var id : SId;
	#end
	public var size : SInt;
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
	@:relation(gameId) public var game : GoGame;
	public var moveNo : SInt; // SUInt causes problems with comparison in
	// PHP, when comparing against standard Ints
	public var color : STinyUInt;
	public var col : STinyUInt;
	public var row : STinyUInt;
}
