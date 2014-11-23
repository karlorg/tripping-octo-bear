class TestNeko {
	public static function main() {
		trace("Testing on neko...\n");
		Sys.setCwd("neko-test");
		Sys.command("neko", ["test.n"]);
	}
}
