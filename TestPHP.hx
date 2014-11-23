class TestPHP {
	public static function main() {
		trace("Testing on PHP...\n");
		Sys.setCwd("php-test");
		Sys.command("php", ["test.php"]);
	}
}
