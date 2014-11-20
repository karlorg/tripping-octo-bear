/*
 * non-compilation build steps for producing PHP target
 */

import BuildLib;

class BuildPHP {

	static private inline var inPath = "server-files";
	static private inline var outPath = "php";

	static public function main() {
		BuildLib.CopyRecursive.copyDirContents(inPath, outPath);
	}

}