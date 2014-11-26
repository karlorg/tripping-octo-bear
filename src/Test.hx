import haxe.unit.TestCase;
import haxe.unit.TestRunner;

import Index.Db;
import Index.GoGame;
import Index.GoMove;
import Index.WebApi;

class Test {
	public static function main() {
		var r = new TestRunner();
		r.add(new TestDb());
		r.add(new TestWebApi());

		r.run();
	}
}

class TestWithDatabase extends TestCase {
	private var databaseFile : String;
	private function deletePhysicalDatabase(){
		if (sys.FileSystem.exists(this.databaseFile)) {
			sys.FileSystem.deleteFile(this.databaseFile);
		}
	}

	override public function setup() {
		Db.close();
		this.deletePhysicalDatabase();
		Db.init(this.databaseFile);
	}

	override public function tearDown() {
		Db.close();
		this.deletePhysicalDatabase();
	}
}

class TestDb extends TestWithDatabase {
	public function new() {
		super();
		this.databaseFile = "test.sqlite";
	}

	public function testInit() {
		var games = GoGame.manager.search(true);
		var moves = GoMove.manager.search(true);
		assertEquals(games.length, 0);
		assertEquals(moves.length, 0);
	}

	public function testAddGame() {
		Db.addGame(19);
		Db.addGame(10);
		var games = GoGame.manager.search(true);
		assertEquals(games.length, 2);
		var game1 = games.first();
		assertEquals(game1.size, 19);
		var game2 = games.last();
		assertTrue(game1.id != game2.id);
	}

	public function testAddMove() {
		Db.addGame(19);
		var game = GoGame.manager.select(true);
		Db.addMove(game, 0, 0, 10, 10);
		var moves = GoMove.manager.search($game == game);
		assertEquals(moves.length, 1);
		var move = moves.first();
		assertEquals(move.moveNo, 0);
		assertEquals(move.color, 0);
		assertEquals(move.col, 10);
		assertEquals(move.row, 10);
		var nonMoves = GoMove.manager.search($game != game);
		assertEquals(nonMoves.length, 0);
	}
}

class MockServerOps implements Index.ServerOps {
	public var api: WebApi;
	public function new() {}
	public function print(str: String) : Void { }
	public function redirect(dest: String) : Void {
		var re1 = ~/([^\?]+)([\?&]([^=]+)=([^&$]+))*/;
		re1.match(dest);
		var url = re1.matched(1);
		var params = new Map<String,String>();
		var i = 4;
		while (re1.matched(i) != null) {
			params.set(re1.matched(i-1), re1.matched(i));
			i += 3;
		}
		haxe.web.Dispatch.run(url, params, api);
	}
}

class TestWebApi extends TestWithDatabase {
	private var ops: MockServerOps;
	private var w: WebApi;

	public function new() {
		super();
		ops = new MockServerOps();
		w = new WebApi(ops);
		ops.api = w;
		this.databaseFile = "gothing.sqlite";
	}

	public function testNewGame() {
		w.doNewgame();
		w.doNewgame();
		var games = GoGame.manager.search(true);
		assertEquals(games.length, 2);
		var game1 = games.first();
		assertEquals(game1.size, 19);
		var game2 = games.last();
		assertTrue(game1.id != game2.id);
	}

	public function testPlayMoves() {
		w.doNewgame();
		var game = GoGame.manager.select(true);
		var gameId = game.id;
		var moves = GoMove.manager.search(true);
		assertEquals(moves.length, 0);
		// no playNo/At => no move added
		w.doGame({ gameId : gameId, playNo : null, playAt : null });
		var moves = GoMove.manager.search(true);
		assertEquals(moves.length, 0);
		// playNo not next due => no move
		w.doGame({ gameId : gameId, playNo : 1, playAt : "aa" });
		var moves = GoMove.manager.search(true);
		assertEquals(moves.length, 0);
		// no playNo/At => no move added
		w.doGame({ gameId : gameId, playNo : 0, playAt : null });
		var moves = GoMove.manager.search(true);
		assertEquals(moves.length, 0);
		// move coords out of bounds => no move added
		w.doGame({ gameId : gameId, playNo : 0, playAt : "zz" });
		var moves = GoMove.manager.search(true);
		assertEquals(moves.length, 0);
		// first valid move
		w.doGame({ gameId : gameId, playNo : 0, playAt : "cd" });
		var moves = GoMove.manager.search(true);
		assertEquals(moves.length, 1);
		var move = moves.first();
		assertEquals(move.moveNo, 0);
		assertEquals(move.color, 0);
		assertEquals(move.col, 2);
		assertEquals(move.row, 3);
		// playNo not next due => no move
		w.doGame({ gameId : gameId, playNo : 0, playAt : "cc" });
		var moves = GoMove.manager.search(true);
		assertEquals(moves.length, 1);
		// // same coords as existing stone => no move
		/* removed until validation is added */
		// w.doGame({ gameId : gameId, playNo : 1, playAt : "cd" });
		// var moves = GoMove.manager.search(true);
		// assertEquals(moves.length, 1);
		// second valid move
		w.doGame({ gameId : gameId, playNo : 1, playAt : "cc" });
		var moves = GoMove.manager.search(true);
		assertEquals(moves.length, 2);
		var move = GoMove.manager.select($game == game && $moveNo == 1);
		assertEquals(move.color, 1);
		assertEquals(move.col, 2);
		assertEquals(move.row, 2);
	}

}
