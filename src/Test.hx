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
		// testing WebApi methods prints out the whole response, can we
		// avoid that?
		// r.add(new TestWebApi());

		r.run();
	}
}

class TestDb extends TestCase {
	override public function setup() {
		Db.close();
		if (sys.FileSystem.exists("test.sqlite")) {
			sys.FileSystem.deleteFile("test.sqlite");
		}
		Db.init("test.sqlite");
	}

	override public function tearDown() {
		Db.close();
		if (sys.FileSystem.exists("test.sqlite")) {
			sys.FileSystem.deleteFile("test.sqlite");
		}
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

class TestWebApi extends TestCase {
	private var w = new WebApi();

	override public function setup() {
		Db.close();
		if (sys.FileSystem.exists("gothing.sqlite")) {
			sys.FileSystem.deleteFile("gothing.sqlite");
		}
	}

	override public function tearDown() {
		Db.close();
		if (sys.FileSystem.exists("gothing.sqlite")) {
			sys.FileSystem.deleteFile("gothing.sqlite");
		}
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

}
