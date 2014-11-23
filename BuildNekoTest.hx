/*
 * non-compilation build steps for producing Neko test target
 */

import BuildLib;

class BuildNekoTest {

	static private inline var inPath = "server-files";
	static private inline var outPath = "neko-test";

	static public function main() {
		BuildLib.CopyRecursive.copyDirContents(inPath, outPath);
	}

}