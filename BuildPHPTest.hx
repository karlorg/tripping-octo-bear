/*
 * non-compilation build steps for producing PHP test target
 */

import BuildLib;

class BuildPHPTest {

	static private inline var inPath = "server-files";
	static private inline var outPath = "php-test";

	static public function main() {
		BuildLib.CopyRecursive.copyDirContents(inPath, outPath);
	}

}